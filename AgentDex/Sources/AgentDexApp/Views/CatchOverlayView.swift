import SwiftUI
import Combine
import AgentDexCore

/// The throw-to-bind mini-game. A resonance ring oscillates around the wild
/// daemon; tap THROW when the ring is tight (near the dashed target) for a
/// "true throw". Throw quality (0...1) feeds `CatchCalculator`, and the live
/// bind-chance readout uses the exact same math as the resolution — so what
/// the player sees is what the engine rolls.
@MainActor
public struct CatchOverlayView: View {
    let wild: Daemon
    let spheres: [(sphere: Sphere, count: Int)]
    let onThrow: (Sphere, Double) -> Void
    let onCancel: () -> Void

    @State private var ringScale: Double = 1.6
    @State private var shrinking = true
    @State private var selected: Sphere

    /// Quality peaks when the ring scale hits this target.
    private let targetScale: Double = 0.55
    private let minScale: Double = 0.3
    private let maxScale: Double = 1.6
    /// Per-frame scale step at 60fps (~1.1s per sweep).
    private let step: Double = 0.02

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    public init(wild: Daemon,
                spheres: [(sphere: Sphere, count: Int)],
                onThrow: @escaping (Sphere, Double) -> Void,
                onCancel: @escaping () -> Void) {
        self.wild = wild
        self.spheres = spheres
        self.onThrow = onThrow
        self.onCancel = onCancel
        _selected = State(initialValue: spheres.first?.sphere ?? .orb)
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Bind \(wild.species.name)!")
                    .font(.headline)

                ZStack {
                    DaemonSprite(recipe: wild.species.sprite, size: 110, anomalous: wild.isAnomalous)

                    // The fixed target ring...
                    Circle()
                        .stroke(Color.white.opacity(0.35),
                                style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(width: 130 * targetScale, height: 130 * targetScale)

                    // ...and the live resonance ring.
                    Circle()
                        .stroke(ringColor, lineWidth: 3)
                        .frame(width: 130, height: 130)
                        .scaleEffect(ringScale)
                        .opacity(0.9)
                }
                .frame(width: 230, height: 230)

                Text("Tap THROW when the ring meets the dashed target.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("bind chance ~\(bindChancePercent)%")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()

                if spheres.isEmpty {
                    Text("Out of spheres — visit the shop!")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Picker("Sphere", selection: $selected) {
                        ForEach(0..<spheres.count, id: \.self) { i in
                            Text("\(spheres[i].sphere.name) ×\(spheres[i].count)")
                                .monospacedDigit()
                                .tag(spheres[i].sphere)
                        }
                    }
                    .pickerStyle(.menu)
                }

                HStack(spacing: 16) {
                    Button("Run", role: .cancel, action: onCancel)
                        .buttonStyle(.bordered)

                    Button {
                        Cues.play(.shake)
                        onThrow(selected, quality(ringScale))
                    } label: {
                        Text("THROW")
                            .font(.headline)
                            .frame(minWidth: 110)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(spheres.isEmpty)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding()
        }
        .onReceive(timer) { _ in
            tick()
        }
    }

    // MARK: - Ring mechanics

    private func tick() {
        if shrinking {
            ringScale -= step
            if ringScale <= minScale {
                ringScale = minScale
                shrinking = false
            }
        } else {
            ringScale += step
            if ringScale >= maxScale {
                ringScale = maxScale
                shrinking = true
            }
        }
    }

    /// 1.0 exactly on target, fading linearly to 0 as the ring drifts away.
    private func quality(_ scale: Double) -> Double {
        let distance = abs(scale - targetScale)
        return max(0, min(1, 1 - distance / 0.6))
    }

    private var bindChancePercent: Int {
        let p = CatchCalculator.probability(
            target: wild, sphere: selected, throwQuality: quality(ringScale))
        return Int((p * 100).rounded())
    }

    private var ringColor: Color {
        quality(ringScale) > 0.75
            ? .green
            : Color(hex: wild.species.sprite.primaryColorHex)
    }
}
