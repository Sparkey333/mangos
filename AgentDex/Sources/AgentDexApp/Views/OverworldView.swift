import SwiftUI
import SpriteKit
import Combine
import AgentDexCore

/// Hosts the SpriteKit overworld with the battle HUD layered on top. Battles
/// play out IN the world (choreographed by `OverworldScene`) unless the player
/// opts into classic screen-switch battles in Settings, in which case a sheet
/// presents `ClassicBattleView` over the live world.
@MainActor
public struct OverworldView: View {
    @EnvironmentObject var game: GameState

    // Held in @State so the scene isn't rebuilt (and reset) on every render.
    @State private var scene = OverworldScene()
    @State private var showCatch = false
    /// True while the scene is choreographing a batch of battle events;
    /// the action panel hides so inputs can't pile up mid-animation.
    @State private var animating = false

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            hud

            if showCatch, game.inBattle, !game.settings.classicBattles,
               let wild = game.wildEnemy {
                CatchOverlayView(
                    wild: wild,
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
        }
        .onAppear {
            scene.onEncounter = {
                Task { @MainActor in
                    game.startWildEncounter()
                }
            }
            scene.configure(region: game.region, cycle: game.loadCycle)
        }
        .onChange(of: game.region.project) { _ in
            scene.configure(region: game.region, cycle: game.loadCycle)
        }
        .onReceive(clock) { _ in
            scene.updateCycle(game.loadCycle)
        }
        .onReceive(game.$eventQueue) { queue in
            handleEvents(queue)
        }
        .onChange(of: game.inBattle) { inBattle in
            if !inBattle { showCatch = false }
        }
        .sheet(isPresented: classicPresented) {
            ClassicBattleView()
                .environmentObject(game)
        }
    }

    // MARK: - Battle event routing

    /// Drains the event queue and hands the batch to the scene to animate.
    /// In classic mode the events are drained but not choreographed — the
    /// classic screen renders from state + the narrated log instead.
    private func handleEvents(_ queue: [BattleEvent]) {
        guard !queue.isEmpty else { return }
        let events = game.consumeEvents()
        guard !events.isEmpty else { return }
        if game.settings.classicBattles { return }

        if let first = events.first, case .battleStarted = first {
            if let enemy = game.wildEnemy {
                scene.battleBegan(
                    enemyRecipe: enemy.species.sprite,
                    enemyAnomalous: enemy.isAnomalous,
                    playerRecipe: game.activeDaemon?.species.sprite
                )
            }
            Cues.play(.encounter)
        }

        animating = true
        scene.choreograph(events) {
            Task { @MainActor in
                animating = false
                if game.session?.isOver == true {
                    scene.battleEnded()
                    game.dismissBattle()
                }
            }
        }
    }

    private var classicPresented: Binding<Bool> {
        Binding(
            get: { game.session != nil && game.settings.classicBattles },
            set: { presented in
                if !presented { game.dismissBattle() }
            }
        )
    }

    // MARK: - HUD

    private var hud: some View {
        VStack(spacing: 10) {
            topBar
            Spacer()
            if game.inBattle && !game.settings.classicBattles {
                battleLogBox
                if !animating, let session = game.session {
                    battlePanel(session)
                }
            } else if !game.inBattle {
                idleFooter
            }
        }
        .padding()
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(game.region.displayName)
                    .font(.caption.weight(.bold))
                Text(game.loadCycle.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

            Spacer()

            Text("\(game.save.cycles)¢")
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())

            if let lead = game.activeDaemon {
                leadBadge(lead)
            }
        }
    }

    private func leadBadge(_ lead: Daemon) -> some View {
        HStack(spacing: 6) {
            DaemonSprite(recipe: lead.species.sprite, size: 36, anomalous: lead.isAnomalous)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(lead.species.name) Lv\(lead.level)")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
                    .lineLimit(1)
                ProgressView(value: max(0, min(1, lead.hpFraction)))
                    .frame(width: 76)
                    .tint(lead.hpFraction > 0.5 ? .green : (lead.hpFraction > 0.25 ? .yellow : .red))
                if lead.status != .none {
                    WorldStatusTag(status: lead.status)
                }
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private var battleLogBox: some View {
        let lines = Array(game.battleLog.suffix(3))
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(lines.indices, id: \.self) { i in
                Text(lines[i])
                    .font(.caption2)
                    .monospacedDigit()
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Battle panel

    private func battlePanel(_ session: BattleSession) -> some View {
        let moves = session.activeDaemon.moves.isEmpty
            ? [MovePool.basicStrike]
            : session.activeDaemon.moves
        return VStack(spacing: 8) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(moves) { move in
                    Button {
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

            HStack(spacing: 8) {
                if !session.isTrainerBattle {
                    Button("Throw Sphere") { showCatch = true }
                        .buttonStyle(.borderedProminent)
                }
                itemsMenu
                switchMenu(session)
                Button("Flee") { game.act(.flee) }
                    .buttonStyle(.bordered)
            }
            .font(.caption)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .disabled(session.isOver)
    }

    private var itemsMenu: some View {
        Menu {
            ForEach(Item.all) { item in
                let count = game.save.itemCount(item)
                if count > 0 {
                    Button("\(item.name) ×\(count)") {
                        game.act(.useItem(item))
                    }
                }
            }
        } label: {
            Text("Items")
        }
    }

    private func switchMenu(_ session: BattleSession) -> some View {
        Menu {
            ForEach(session.party.indices, id: \.self) { i in
                if i != session.activeIndex && !session.party[i].isFainted {
                    Button("\(session.party[i].species.name) Lv\(session.party[i].level)") {
                        game.act(.switchTo(i))
                    }
                }
            }
        } label: {
            Text("Switch")
        }
    }

    private var idleFooter: some View {
        VStack(spacing: 8) {
            if game.currentQuest?.giverNPC == "rival_rune" {
                Button {
                    game.startRivalBattle()
                } label: {
                    Label("Duel Rune", systemImage: "bolt.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            Text("Wander near the tall code — wild daemons find you.")
                .font(.caption2)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
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

/// Tiny status pill tinted with the condition's signature color.
private struct WorldStatusTag: View {
    let status: DaemonStatus

    var body: some View {
        Text(status.displayName)
            .font(.system(size: 8, weight: .heavy))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .foregroundStyle(Color(hex: status.colorHex))
            .background(Color(hex: status.colorHex).opacity(0.22), in: Capsule())
    }
}
