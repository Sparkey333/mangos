import Foundation

/// Game-feel cues: sound + haptics, routed through one funnel so views and the
/// scene never talk to AVFoundation/CoreHaptics directly. The audio engine
/// registers itself as the player at app launch; if none is registered, cues
/// are silently dropped (e.g. in previews).
public enum GameCue: String, CaseIterable, Sendable {
    case uiTap, deny
    case encounter, flee
    case hit, superHit, weakHit, miss, statusApply
    case faint, victory, defeat
    case throwStart, shake, catchSuccess, catchFail
    case levelUp, ascend
    case questDone, achievement
    case heal, buy
}

public protocol CuePlayer: AnyObject {
    func play(_ cue: GameCue)
    func setEnabled(sound: Bool, haptics: Bool)
}

public enum Cues {
    public static var player: CuePlayer?

    public static func play(_ cue: GameCue) {
        player?.play(cue)
    }

    public static func configure(sound: Bool, haptics: Bool) {
        player?.setEnabled(sound: sound, haptics: haptics)
    }
}
