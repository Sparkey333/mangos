import Foundation
import SwiftUI
import AgentDexCore
import AgentDexImport

/// The app-side game brain. Owns the SaveState + Bestiary, drives encounters, and
/// delegates ALL rules to `AgentDexCore` so behavior matches the unit tests.
@MainActor
public final class GameState: ObservableObject {
    @Published public private(set) var save: SaveState
    @Published public private(set) var bestiary: Bestiary
    @Published public var npcs: [NPC]

    /// The current wild Daemon you're facing in the overworld (nil = none).
    @Published public var wild: Daemon?
    /// Rolling battle log shown in the HUD.
    @Published public var log: [String] = []
    /// Whether the player prefers the classic screen-switch battle presentation.
    @Published public var useClassicBattle = false

    /// True when the roster came from the user's own imported agents.json.
    @Published public private(set) var usingImportedRoster = false

    public init() {
        // Prefer the user's imported roster (written by `agentdex-import` into the
        // shared AgentDex config dir); fall back to the bundled example roster.
        let (bundledAgents, bundledPlayer) = ConfigLoader.loadBundledExamples()
        let importedAgents = AgentConfigStore.readAgents()
        let agents = (importedAgents?.isEmpty == false) ? importedAgents! : bundledAgents
        let player = AgentConfigStore.readPlayer() ?? bundledPlayer
        self.usingImportedRoster = (importedAgents?.isEmpty == false)
        let bestiary = Bestiary(profiles: agents)
        self.bestiary = bestiary

        var state = SharedStore.load() ?? SaveState.newGame(player: player)
        // Give the player a starter on a brand-new game.
        if state.party.isEmpty, let starter = GameState.makeStarter(bestiary: bestiary, player: player) {
            state.capture(starter)
        }
        self.save = state
        self.npcs = Scripts.hubNPCs(player: player)
        persist()
    }

    // MARK: - Encounters

    public func roamEncounter() {
        var rng = SeededRandom("encounter-\(Date().timeIntervalSince1970)")
        guard let species = bestiary.rollEncounter(inRegion: save.currentRegion, rng: &rng)
                ?? bestiary.species.first else { return }
        let lvl = bestiary.wildLevel(for: species.id)
        let w = Daemon(species: species, level: lvl)
        wild = w
        save.markSeen(species.id)
        persist()
        appendLog("A wild \(species.name) (Lv\(lvl)) appeared!")
        appendLog(species.flavor)
    }

    // MARK: - Combat

    public func playerAttack(with move: Move) {
        guard var wild, var active = save.activeDaemon else { return }
        var attacker = active
        var rng = SeededRandom("atk-\(UUID().uuidString)")
        let out = BattleEngine.resolveMove(attacker: &attacker, defender: &wild, move: move, rng: &rng)
        appendLog(out.message)
        active = attacker
        updateActive(active)
        self.wild = wild

        if wild.isFainted {
            appendLog("\(wild.species.name) fled into the logs.")
            self.wild = nil
            return
        }
        wildAttackBack()
    }

    private func wildAttackBack() {
        guard let wild, var active = save.activeDaemon else { return }
        // Looped daemons sometimes lose their turn (flavor + mechanical payoff).
        var rng = SeededRandom("wild-\(UUID().uuidString)")
        if wild.status == .looped, rng.unit() < 0.4 {
            appendLog("\(wild.species.name) is stuck in a loop and skipped its turn!")
            return
        }
        let move = BattleEngine.chooseMove(for: wild, against: active)
        var defender = active
        var mutableWild = wild
        let out = BattleEngine.resolveMove(attacker: &mutableWild, defender: &defender, move: move, rng: &rng)
        appendLog(out.message)
        self.wild = mutableWild
        active = defender
        updateActive(active)
        if active.isFainted {
            appendLog("\(active.species.name) fainted! Send out another daemon.")
        }
    }

    // MARK: - Catching

    /// Throw a sphere. `throwQuality` is 0...1 from the resonance-ring mini-game.
    @discardableResult
    public func throwSphere(_ sphere: Sphere, throwQuality: Double) -> CatchCalculator.Attempt? {
        guard let wild else { return nil }
        guard save.sphereCount(sphere) > 0 else {
            appendLog("Out of \(sphere.name)s!"); return nil
        }
        save.consumeSphere(sphere)
        var rng = SeededRandom("catch-\(UUID().uuidString)")
        let attempt = CatchCalculator.attempt(target: wild, sphere: sphere,
                                              throwQuality: throwQuality, rng: &rng)
        if attempt.captured {
            appendLog("Gotcha! \(wild.species.name) was bound! (\(Int(attempt.probability * 100))% chance)")
            save.capture(wild)
            self.wild = nil
        } else {
            appendLog("So close — \(attempt.shakes) shake(s) — \(wild.species.name) broke free!")
            wildAttackBack()
        }
        persist()
        return attempt
    }

    // MARK: - Party helpers

    private func updateActive(_ daemon: Daemon) {
        guard let idx = save.party.firstIndex(where: { $0.id == daemon.id }) else { return }
        var party = save.party
        party[idx] = daemon
        save.party = party
        persist()
    }

    public func healParty() {
        var party = save.party
        for i in party.indices {
            party[i].currentHP = party[i].maxHP
            party[i].status = .none
        }
        save.party = party
        persist()
        appendLog("Your party was restored.")
    }

    // MARK: - Infra

    private func appendLog(_ s: String) {
        log.append(s)
        if log.count > 60 { log.removeFirst(log.count - 60) }
    }

    public func persist() { SharedStore.save(save) }

    static func makeStarter(bestiary: Bestiary, player: PlayerProfile) -> Daemon? {
        // Prefer a low-tier species matching the player's starting aspect.
        let candidates = bestiary.species
            .filter { $0.tier <= .task }
            .sorted { $0.tier.rawValue < $1.tier.rawValue }
        let match = candidates.first { $0.primaryAspect == player.startingAspect }
        let pick = match ?? candidates.first ?? bestiary.species.first
        guard let species = pick else { return nil }
        return Daemon(species: species, level: 5)
    }
}
