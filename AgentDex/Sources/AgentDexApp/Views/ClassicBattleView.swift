import SwiftUI
import Combine
import AgentDexCore

/// The opt-in classic, turn-based, screen-switch battle. It reads the SAME
/// `BattleSession` the overworld uses and submits the same `PlayerAction`s,
/// so balance is identical — only the presentation changes. This screen
/// renders from session state + the narrated `battleLog`; the raw event
/// queue is drained (not choreographed) so it never goes stale.
@MainActor
public struct ClassicBattleView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.dismiss) private var dismiss

    private enum Pane { case root, fight, bag, party }
    @State private var pane: Pane = .root
    @State private var showCatch = false
    /// Ensures the victory/defeat cue plays exactly once per battle.
    @State private var outcomeCued = false

    public init() {}

    public var body: some View {
        ZStack {
            if let session = game.session {
                content(session)

                if showCatch, !session.isTrainerBattle {
                    CatchOverlayView(
                        wild: session.enemy,
                        spheres: availableSpheres(),
                        onThrow: { sphere, quality in
                            Cues.play(.throwStart)
                            game.act(.throwSphere(sphere, quality: quality))
                            showCatch = false
                        },
                        onCancel: { showCatch = false }
                    )
                    .zIndex(10)
                }
            } else {
                Color.clear
            }
        }
        .interactiveDismissDisabled(game.session?.isOver == false)
        .onReceive(game.$eventQueue) { queue in
            // Classic mode renders from state + log; just drain the queue.
            if !queue.isEmpty {
                _ = game.consumeEvents()
            }
            checkOutcomeCue()
        }
    }

    // MARK: - Layout

    private func content(_ session: BattleSession) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: session.enemy.species.sprite.primaryColorHex).opacity(0.35),
                    Color.black.opacity(0.85)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Enemy: info left, sprite top-right.
                HStack(alignment: .center) {
                    infoCard(session.enemy)
                    Spacer()
                    DaemonSprite(recipe: session.enemy.species.sprite,
                                 size: 120,
                                 anomalous: session.enemy.isAnomalous,
                                 animating: !session.isOver)
                }
                .padding(.horizontal)

                Spacer(minLength: 8)

                // Player: sprite bottom-left, info right.
                HStack(alignment: .center) {
                    DaemonSprite(recipe: session.activeDaemon.species.sprite,
                                 size: 120,
                                 anomalous: session.activeDaemon.isAnomalous,
                                 animating: !session.isOver)
                    Spacer()
                    infoCard(session.activeDaemon)
                }
                .padding(.horizontal)

                logBox

                if session.isOver {
                    outcomeBanner(session)
                } else {
                    menuBox(session)
                }
            }
            .padding(.vertical)
        }
    }

    private func infoCard(_ d: Daemon) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(d.species.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("Lv\(d.level)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ClassicHPBar(fraction: d.hpFraction)
                .frame(width: 170)
            Text("\(max(0, d.currentHP))/\(d.maxHP) HP")
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            if d.status != .none {
                ClassicStatusTag(status: d.status)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var logBox: some View {
        let lines = Array(game.battleLog.suffix(6))
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(lines.indices, id: \.self) { i in
                Text(lines[i])
                    .font(.caption)
                    .monospacedDigit()
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .bottomLeading)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Menus

    @ViewBuilder
    private func menuBox(_ session: BattleSession) -> some View {
        VStack(spacing: 8) {
            switch pane {
            case .root:  rootMenu(session)
            case .fight: fightMenu(session)
            case .bag:   bagMenu
            case .party: switchMenu(session)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .disabled(session.isOver)
    }

    private func rootMenu(_ session: BattleSession) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            Button {
                pane = .fight
            } label: {
                Text("Fight").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            if !session.isTrainerBattle {
                actionButton("Catch") { showCatch = true }
            }
            actionButton("Bag") { pane = .bag }
            actionButton("Switch") { pane = .party }
            actionButton("Run") { game.act(.flee) }
        }
    }

    private func fightMenu(_ session: BattleSession) -> some View {
        let moves = session.activeDaemon.moves.isEmpty
            ? [MovePool.basicStrike]
            : session.activeDaemon.moves
        return VStack(spacing: 8) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(moves) { move in
                    Button {
                        pane = .root
                        game.act(.move(move))
                    } label: {
                        VStack(spacing: 2) {
                            Text(move.name)
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                            Text("\(move.aspect.rawValue.capitalized) · \(move.power > 0 ? "\(move.power)" : "status")")
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            backButton
        }
    }

    private var bagMenu: some View {
        let stocked = Item.all.filter { game.save.itemCount($0) > 0 }
        return VStack(spacing: 6) {
            if stocked.isEmpty {
                Text("The bag is empty.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(stocked) { item in
                Button {
                    pane = .root
                    game.act(.useItem(item))
                } label: {
                    HStack {
                        Text(item.name).font(.caption.weight(.semibold))
                        Spacer()
                        Text("×\(game.save.itemCount(item))")
                            .font(.caption)
                            .monospacedDigit()
                    }
                }
                .buttonStyle(.bordered)
            }
            backButton
        }
    }

    private func switchMenu(_ session: BattleSession) -> some View {
        let healthy = session.party.indices.filter {
            $0 != session.activeIndex && !session.party[$0].isFainted
        }
        return VStack(spacing: 6) {
            if healthy.isEmpty {
                Text("No one else can fight.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(healthy, id: \.self) { i in
                Button {
                    pane = .root
                    game.act(.switchTo(i))
                } label: {
                    HStack {
                        Text(session.party[i].species.name)
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text("Lv\(session.party[i].level) · \(max(0, session.party[i].currentHP))/\(session.party[i].maxHP)")
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.bordered)
            }
            backButton
        }
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private var backButton: some View {
        Button("Back") { pane = .root }
            .buttonStyle(.plain)
            .font(.caption)
    }

    // MARK: - Outcome

    private func outcomeBanner(_ session: BattleSession) -> some View {
        VStack(spacing: 10) {
            Text(outcomeTitle(session.outcome))
                .font(.title2.weight(.heavy))
            Button("Continue") {
                game.dismissBattle()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private func outcomeTitle(_ outcome: BattleOutcome?) -> String {
        switch outcome {
        case .victory:  return "Victory!"
        case .defeat:   return "Defeat"
        case .captured: return "Caught!"
        case .fled:     return "Fled"
        case nil:       return ""
        }
    }

    private func checkOutcomeCue() {
        guard !outcomeCued, let outcome = game.session?.outcome else { return }
        outcomeCued = true
        switch outcome {
        case .victory:  Cues.play(.victory)
        case .defeat:   Cues.play(.defeat)
        case .captured: Cues.play(.catchSuccess)
        case .fled:     break
        }
    }

    // MARK: - Helpers

    private func availableSpheres() -> [(sphere: Sphere, count: Int)] {
        Sphere.shopCatalog.compactMap { s -> (sphere: Sphere, count: Int)? in
            let c = game.save.sphereCount(s)
            return c > 0 ? (sphere: s, count: c) : nil
        }
    }
}

/// An HP bar that animates smoothly toward the new fraction on every hit.
private struct ClassicHPBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.15))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(max(0, min(1, fraction))))
            }
        }
        .frame(height: 8)
        .animation(.easeOut(duration: 0.5), value: fraction)
    }

    private var color: Color {
        if fraction > 0.5 { return .green }
        if fraction > 0.25 { return .yellow }
        return .red
    }
}

/// Status pill tinted with the condition's signature color.
private struct ClassicStatusTag: View {
    let status: DaemonStatus

    var body: some View {
        Text(status.displayName)
            .font(.system(size: 9, weight: .heavy))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(Color(hex: status.colorHex))
            .background(Color(hex: status.colorHex).opacity(0.22), in: Capsule())
    }
}
