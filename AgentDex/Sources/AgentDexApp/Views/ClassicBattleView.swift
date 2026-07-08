import SwiftUI
import AgentDexCore

/// The opt-in classic, turn-based, screen-switch battle (DESIGN §5.1). It uses
/// the EXACT same `GameState` actions as the overworld fight, so balance is
/// identical — only the presentation changes. Toggle "Classic" in the world HUD.
public struct ClassicBattleView: View {
    @EnvironmentObject var game: GameState
    let wild: Daemon

    enum Menu { case root, fight, bag }
    @State private var menu: Menu = .root
    @State private var showThrow = false

    public init(wild: Daemon) { self.wild = wild }

    public var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: wild.species.sprite.secondaryColorHex).opacity(0.4),
                                    Color.black.opacity(0.8)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                // Enemy (top)
                HStack {
                    combatant(wild, label: "Wild")
                    Spacer()
                    DaemonSprite(recipe: wild.species.sprite, size: 130)
                }
                .padding(.horizontal)

                Spacer()

                // Player (bottom)
                if let active = game.save.activeDaemon {
                    HStack {
                        DaemonSprite(recipe: active.species.sprite, size: 130)
                        Spacer()
                        combatant(active, label: active.species.name)
                    }
                    .padding(.horizontal)
                }

                logBox
                menuBox
            }
            .padding(.vertical)

            if showThrow {
                CatchOverlayView(
                    wild: wild,
                    spheres: availableSpheres(),
                    onThrow: { sphere, q in game.throwSphere(sphere, throwQuality: q); showThrow = false },
                    onCancel: { showThrow = false }
                )
            }
        }
    }

    private func combatant(_ d: Daemon, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(d.species.name)  Lv\(d.level)").font(.headline)
            ProgressView(value: d.hpFraction)
                .frame(width: 160)
                .tint(d.hpFraction > 0.3 ? .green : .red)
            Text("\(max(0, d.currentHP))/\(d.maxHP)").font(.caption2).monospacedDigit()
            if d.status != .none {
                Text(d.status.rawValue.uppercased()).font(.caption2).foregroundStyle(.orange)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var logBox: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(game.log.suffix(3).enumerated()), id: \.offset) { _, line in
                Text(line).font(.caption).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    @ViewBuilder private var menuBox: some View {
        switch menu {
        case .root:
            HStack(spacing: 12) {
                bigButton("Fight") { menu = .fight }
                bigButton("Catch") { showThrow = true }
                bigButton("Run", role: .cancel) { game.wild = nil }
            }
            .padding(.horizontal)
        case .fight:
            let moves = (game.save.activeDaemon?.species.moves).flatMap { $0.isEmpty ? nil : $0 } ?? [MovePool.basicStrike]
            VStack(spacing: 8) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(moves) { move in
                        Button {
                            game.playerAttack(with: move)
                            menu = .root
                        } label: {
                            VStack(spacing: 2) {
                                Text(move.name).bold()
                                Text("\(move.aspect.rawValue) · \(move.power > 0 ? "PWR \(move.power)" : "status")")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                Button("Back") { menu = .root }.buttonStyle(.bordered)
            }
            .padding(.horizontal)
        case .bag:
            EmptyView()
        }
    }

    private func bigButton(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
    }

    private func availableSpheres() -> [(sphere: Sphere, count: Int)] {
        [Sphere.orb, .bindOrb, .resonantOrb, .primeSigil].compactMap {
            let c = game.save.sphereCount($0); return c > 0 ? ($0, c) : nil
        }
    }
}
