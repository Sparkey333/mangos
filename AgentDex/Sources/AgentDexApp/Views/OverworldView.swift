import SwiftUI
import SpriteKit
import AgentDexCore

/// Hosts the SpriteKit overworld and overlays the in-world battle HUD + catch
/// mini-game. No screen switch: the fight controls appear over the live scene.
public struct OverworldView: View {
    @EnvironmentObject var game: GameState
    @State private var showCatch = false
    // Hold the scene so it isn't rebuilt (and reset) on every SwiftUI render.
    @State private var scene = OverworldScene()

    public init() {}

    public var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    scene.onEncounter = {
                        guard game.wild == nil else { return }
                        game.roamEncounter()
                    }
                }

            VStack {
                topBar
                Spacer()
                // In-world battle panel (overworld / no-screen-switch mode only).
                if let wild = game.wild, !game.useClassicBattle {
                    battlePanel(wild: wild)
                } else if game.wild == nil {
                    Text("Walk into a roaming daemon to start a fight.")
                        .font(.caption).padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 8)
                }
            }
            .padding()

            if showCatch, let wild = game.wild, !game.useClassicBattle {
                CatchOverlayView(
                    wild: wild,
                    spheres: availableSpheres(),
                    onThrow: { sphere, quality in
                        game.throwSphere(sphere, throwQuality: quality)
                        showCatch = false
                    },
                    onCancel: { showCatch = false }
                )
            }
        }
        // Classic screen-switch battle: presented over the world when enabled.
        .sheet(isPresented: classicBattlePresented) {
            if let wild = game.wild {
                ClassicBattleView(wild: wild)
                    .environmentObject(game)
            }
        }
    }

    private var classicBattlePresented: Binding<Bool> {
        Binding(
            get: { game.useClassicBattle && game.wild != nil },
            set: { presented in if !presented { game.wild = nil } }
        )
    }

    private var topBar: some View {
        HStack {
            if let active = game.save.activeDaemon {
                hpBadge(for: active, label: "You")
            }
            Spacer()
            Toggle("Classic", isOn: $game.useClassicBattle)
                .labelsHidden()
                .toggleStyle(.switch)
            Text(game.useClassicBattle ? "Classic" : "Overworld").font(.caption2)
        }
    }

    private func battlePanel(wild: Daemon) -> some View {
        VStack(spacing: 8) {
            hpBadge(for: wild, label: "Wild")
            // Battle log (last few lines)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(game.log.suffix(3).enumerated()), id: \.offset) { _, line in
                    Text(line).font(.caption2).lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

            // Move buttons
            if let active = game.save.activeDaemon {
                let moves = active.species.moves.isEmpty ? [MovePool.basicStrike] : active.species.moves
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(moves) { move in
                        Button {
                            game.playerAttack(with: move)
                        } label: {
                            VStack(spacing: 2) {
                                Text(move.name).font(.caption).bold()
                                Text("\(move.aspect.rawValue) · \(move.power > 0 ? "\(move.power)" : "status")")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            HStack {
                Button("Throw Sphere") { showCatch = true }
                    .buttonStyle(.borderedProminent)
                Button("Flee") { game.wild = nil }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func hpBadge(for daemon: Daemon, label: String) -> some View {
        HStack(spacing: 8) {
            DaemonSprite(recipe: daemon.species.sprite, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(label): \(daemon.species.name) Lv\(daemon.level)").font(.caption).bold()
                ProgressView(value: daemon.hpFraction)
                    .frame(width: 120)
                    .tint(daemon.hpFraction > 0.3 ? .green : .red)
                if daemon.status != .none {
                    Text(daemon.status.rawValue.uppercased())
                        .font(.caption2).foregroundStyle(.orange)
                }
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func availableSpheres() -> [(sphere: Sphere, count: Int)] {
        let all: [Sphere] = [.orb, .bindOrb, .resonantOrb, .primeSigil]
        return all.compactMap { s in
            let c = game.save.sphereCount(s)
            return c > 0 ? (s, c) : nil
        }
    }
}
