import SwiftUI
import AgentDexCore

/// The throw-to-catch mini-game (DESIGN §5.4). A resonance ring shrinks; tap when
/// it's tight for a "true throw" bonus. The closer to the inner circle, the
/// higher the `throwQuality` (0...1) passed to `GameState.throwSphere`.
public struct CatchOverlayView: View {
    let wild: Daemon
    let spheres: [(sphere: Sphere, count: Int)]
    let onThrow: (Sphere, Double) -> Void
    let onCancel: () -> Void

    @State private var ringScale: CGFloat = 1.6
    @State private var shrinking = true
    @State private var selected: Sphere = .orb

    // The ring oscillates; quality peaks when scale ≈ target.
    private let targetScale: CGFloat = 0.55
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    public init(wild: Daemon, spheres: [(sphere: Sphere, count: Int)],
                onThrow: @escaping (Sphere, Double) -> Void, onCancel: @escaping () -> Void) {
        self.wild = wild; self.spheres = spheres
        self.onThrow = onThrow; self.onCancel = onCancel
        _selected = State(initialValue: spheres.first?.sphere ?? .orb)
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Throw to bind \(wild.species.name)!")
                    .font(.headline).foregroundStyle(.white)

                ZStack {
                    DaemonSprite(recipe: wild.species.sprite, size: 110)
                    Circle()
                        .stroke(Color(hex: wild.species.sprite.primaryColorHex), lineWidth: 3)
                        .frame(width: 130, height: 130)
                        .scaleEffect(ringScale)
                        .opacity(0.9)
                }
                .frame(width: 240, height: 240)

                Text("Tap THROW when the ring is tight for a true throw.")
                    .font(.caption).foregroundStyle(.white.opacity(0.8))

                // Sphere picker
                Picker("Sphere", selection: $selected) {
                    ForEach(spheres, id: \.sphere.id) { item in
                        Text("\(item.sphere.name) ×\(item.count)").tag(item.sphere)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                HStack(spacing: 16) {
                    Button("Run", role: .cancel, action: onCancel)
                        .buttonStyle(.bordered)
                    Button("THROW") {
                        onThrow(selected, quality(for: ringScale))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .onReceive(timer) { _ in animateRing() }
    }

    private func animateRing() {
        let speed: CGFloat = 0.025
        if shrinking { ringScale -= speed; if ringScale <= targetScale - 0.25 { shrinking = false } }
        else { ringScale += speed; if ringScale >= 1.6 { shrinking = true } }
    }

    /// 1.0 when the ring is exactly on target, falling off with distance.
    private func quality(for scale: CGFloat) -> Double {
        let dist = abs(scale - targetScale)
        return Double(max(0, 1 - dist / 0.6))
    }
}
