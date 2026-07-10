import Foundation
import AVFoundation
#if os(iOS)
import UIKit
#endif

/// Installs the procedural chiptune audio + haptics player as the global
/// `Cues.player`. No asset files: every sound is synthesized on the fly by an
/// `AVAudioSourceNode` render callback (square / triangle voices with a short
/// attack and a linear decay envelope).
public enum AudioBootstrap {
    /// Strong reference so the player outlives the call site. `Cues.player`
    /// alone would not retain it (plain optional, and we don't want views to
    /// own audio infrastructure).
    private static var player: ChiptunePlayer?

    @MainActor
    public static func install() {
        if player != nil { return }
        let p = ChiptunePlayer()
        player = p
        Cues.player = p
    }
}

// MARK: - Voice model

/// One scheduled tone. Times are expressed in output frames so the render
/// callback never does time-base math beyond simple subtraction.
private struct Note {
    var startFrame: Double
    var durFrames: Double
    var freq: Double
    var square: Bool
    var amp: Double
}

/// Mutable synth state shared between the main thread (scheduling) and the
/// audio render thread. Captured by the source-node render closure instead of
/// `self` so the engine graph never retains the player (no retain cycle).
private final class SynthState {
    let lock = NSLock()
    var notes: [Note] = []
    var frame: Double = 0
}

// MARK: - Player

final class ChiptunePlayer: CuePlayer {

    private var soundEnabled = true
    private var hapticsEnabled = true

    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var sampleRate: Double = 44100
    private var setupAttempted = false

    private let state = SynthState()

    // MARK: CuePlayer

    func play(_ cue: GameCue) {
        if hapticsEnabled {
            haptic(for: cue)
        }
        guard soundEnabled else { return }
        ensureEngine()
        guard engine != nil else { return }

        // Frequencies in Hz (C5 ~ 523, E5 ~ 659, G5 ~ 784, C6 ~ 1047, ...).
        switch cue {
        case .uiTap:
            seq([(880, 40, 0)])
        case .deny:
            seq([(110, 150, 0)], square: false)
        case .encounter:
            seq([(523, 70, 0), (659, 70, 0), (784, 70, 0)])
        case .flee:
            seq([(400, 50, 0), (300, 50, 0), (200, 50, 0)])
        case .hit:
            seq([(220, 60, 0)])
        case .superHit:
            seq([(330, 50, 0), (220, 80, 0)])
        case .weakHit:
            seq([(440, 50, 0)], square: false, amp: 0.3)
        case .miss:
            seq([(500, 40, 0), (350, 60, 0)], square: false)
        case .statusApply:
            seq([(300, 60, 0), (320, 60, 0), (300, 60, 0)])
        case .faint:
            seq([(392, 90, 0), (330, 90, 0), (262, 90, 0), (196, 90, 0)])
        case .victory:
            seq([(523, 70, 0), (523, 70, 0), (659, 70, 0), (784, 70, 0), (1047, 160, 0)])
        case .defeat:
            seq([(330, 150, 0), (262, 150, 0), (196, 150, 0)], square: false)
        case .throwStart:
            seq([(400, 30, 0), (600, 30, 0), (800, 40, 0)])
        case .shake:
            seq([(160, 50, 0)])
        case .catchSuccess:
            seq([(523, 60, 0), (587, 60, 0), (659, 60, 0), (784, 60, 0), (880, 60, 0), (1047, 60, 0)])
        case .catchFail:
            seq([(200, 80, 0), (150, 120, 0)])
        case .levelUp:
            seq([(659, 70, 0), (784, 70, 0), (880, 70, 0), (1319, 70, 0)])
        case .ascend:
            seq([(523, 90, 0), (659, 90, 0), (784, 90, 0), (1047, 90, 0), (1319, 90, 0), (1568, 90, 0)])
        case .questDone:
            seq([(784, 80, 0), (1047, 160, 0)])
        case .achievement:
            seq([(880, 70, 0), (1109, 140, 0)])
        case .heal:
            seq([(523, 80, 0), (659, 160, 0)], square: false)
        case .buy:
            seq([(988, 50, 0), (1319, 70, 0)])
        }
    }

    func setEnabled(sound: Bool, haptics: Bool) {
        soundEnabled = sound
        hapticsEnabled = haptics
        if !sound {
            // Cut anything still queued so muting is immediate.
            state.lock.lock()
            state.notes.removeAll()
            state.lock.unlock()
        }
    }

    // MARK: Engine setup (lazy, on first play)

    private func ensureEngine() {
        if engine != nil || setupAttempted { return }
        setupAttempted = true

        let eng = AVAudioEngine()
        var sr = eng.outputNode.inputFormat(forBus: 0).sampleRate
        if sr <= 0 { sr = 44100 }

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 2) else {
            return
        }

        let state = self.state
        let node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            // Keep the locked section tiny: prune finished notes, snapshot the
            // active list, advance the timeline.
            state.lock.lock()
            let base = state.frame
            state.frame = base + Double(frameCount)
            state.notes.removeAll { $0.startFrame + $0.durFrames <= base }
            let active = state.notes
            state.lock.unlock()

            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let attackFrames = 0.005 * sr

            for i in 0..<Int(frameCount) {
                let f = base + Double(i)
                var sample = 0.0
                for note in active {
                    let elapsed = f - note.startFrame
                    if elapsed < 0 || elapsed >= note.durFrames { continue }
                    let phase = elapsed * note.freq / sr
                    let p = fmod(phase, 1.0)
                    let wave: Double
                    if note.square {
                        wave = p < 0.5 ? 1.0 : -1.0
                    } else {
                        wave = abs(p * 4.0 - 2.0) - 1.0 // triangle
                    }
                    // Envelope: 5 ms linear attack, linear decay to 0 across
                    // the note's full duration.
                    var env = 1.0 - elapsed / note.durFrames
                    if elapsed < attackFrames {
                        env *= elapsed / attackFrames
                    }
                    sample += wave * note.amp * env
                }
                let value = Float(sample * 0.5)
                for buffer in buffers {
                    if let data = buffer.mData {
                        data.assumingMemoryBound(to: Float.self)[i] = value
                    }
                }
            }
            return noErr
        }

        eng.attach(node)
        eng.connect(node, to: eng.mainMixerNode, format: format)
        eng.mainMixerNode.outputVolume = 0.25

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        do {
            try eng.start()
            engine = eng
            sourceNode = node
            sampleRate = sr
        } catch {
            // Remain a silent no-op; haptics still work.
        }
    }

    // MARK: Scheduling

    /// Appends a monophonic sequence starting at the render head. `ms` is the
    /// note duration and `gap` the extra silence after it, both in
    /// milliseconds.
    private func seq(_ items: [(f: Double, ms: Double, gap: Double)],
                     square: Bool = true,
                     amp: Double = 0.5) {
        let sr = sampleRate
        state.lock.lock()
        var start = state.frame
        for item in items {
            let durFrames = item.ms * sr / 1000.0
            state.notes.append(Note(startFrame: start,
                                    durFrames: durFrames,
                                    freq: item.f,
                                    square: square,
                                    amp: amp))
            start += durFrames + item.gap * sr / 1000.0
        }
        state.lock.unlock()
    }

    // MARK: Haptics

    private func haptic(for cue: GameCue) {
        #if os(iOS)
        DispatchQueue.main.async {
            switch cue {
            case .hit, .statusApply:
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case .superHit, .faint:
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            case .shake, .uiTap, .throwStart:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .catchSuccess, .levelUp, .ascend, .victory, .achievement, .questDone:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .deny, .defeat:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            case .catchFail:
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case .encounter, .flee, .weakHit, .miss, .heal, .buy:
                break
            }
        }
        #endif
    }
}
