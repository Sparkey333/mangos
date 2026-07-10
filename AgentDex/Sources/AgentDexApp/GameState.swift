import Foundation
import SwiftUI
import AgentDexCore
import AgentDexImport

/// The app-side game brain. Owns the SaveState + Bestiary + battle session and
/// delegates ALL rules to `AgentDexCore`, so behavior matches the unit tests.
///
/// Battle flow: `startWildEncounter()`/`startRivalBattle()` create a
/// `BattleSession`; `act(_:)` submits player actions; every resulting
/// `BattleEvent` lands in `eventQueue` (for choreography) AND `battleLog`
/// (for text). When the session ends the results are committed to the save
/// immediately; the UI calls `dismissBattle()` when its outro finishes.
@MainActor
public final class GameState: ObservableObject {

    // MARK: - Published state

    @Published public private(set) var save: SaveState
    @Published public private(set) var bestiary: Bestiary
    @Published public private(set) var region: Region
    @Published public private(set) var npcs: [NPC]
    @Published public private(set) var session: BattleSession?
    /// Events not yet consumed by the choreography layer.
    @Published public private(set) var eventQueue: [BattleEvent] = []
    /// Rolling human-readable battle log.
    @Published public private(set) var battleLog: [String] = []
    /// Popup notifications (achievements, quest completions).
    @Published public var toasts: [String] = []
    @Published public private(set) var usingImportedRoster: Bool
    /// True until the player picks a starter — drives the onboarding flow.
    @Published public var needsOnboarding: Bool

    private var battleFinalized = false
    private var encounterCounter = 0
    private var playtimeSinceSave: Double = 0

    // MARK: - Init

    public init() {
        let (bundledAgents, bundledPlayer) = ConfigLoader.loadBundledExamples()
        let importedAgents = AgentConfigStore.readAgents()
        let agents = (importedAgents?.isEmpty == false) ? importedAgents! : bundledAgents
        let player = AgentConfigStore.readPlayer() ?? bundledPlayer
        self.usingImportedRoster = (importedAgents?.isEmpty == false)

        let bestiary = Bestiary(profiles: agents)
        self.bestiary = bestiary

        var state = SharedStore.load() ?? SaveState.newGame(player: player)
        if state.currentRegion.isEmpty || !bestiary.regions.contains(state.currentRegion) {
            state.currentRegion = bestiary.regions.first ?? "mangos"
        }
        self.save = state
        self.region = WorldGen.region(for: state.currentRegion)
        self.npcs = Scripts.hubNPCs(player: player)
        self.needsOnboarding = !state.starterChosen
        persist()
    }

    // MARK: - Derived

    public var inBattle: Bool { session != nil }
    public var loadCycle: LoadCycle { save.loadCycle }
    public var currentQuest: Quest? { QuestEngine.currentQuest(save: save) }
    public var currentQuestReady: Bool { QuestEngine.isCurrentQuestReady(save: save) }
    public var dexTotal: Int { bestiary.species.count }

    /// The enemy currently on the field (nil outside battle).
    public var wildEnemy: Daemon? { session?.enemy }
    public var activeDaemon: Daemon? { session?.activeDaemon ?? save.activeDaemon }

    // MARK: - Onboarding

    /// Up to 3 starter candidates: low-tier species, aspect-diverse, with the
    /// player's affinity aspect first when available. Deterministic.
    public func starterCandidates() -> [DaemonSpecies] {
        let lowTiers = bestiary.species
            .filter { $0.tier <= .task }
            .sorted { ($0.tier, $0.id) < ($1.tier, $1.id) }
        let pool = lowTiers.isEmpty ? bestiary.species : lowTiers

        var picked: [DaemonSpecies] = []
        if let match = pool.first(where: { $0.primaryAspect == save.player.startingAspect }) {
            picked.append(match)
        }
        for candidate in pool where picked.count < 3 {
            if !picked.contains(where: { $0.id == candidate.id }),
               !picked.contains(where: { $0.primaryAspect == candidate.primaryAspect }) {
                picked.append(candidate)
            }
        }
        for candidate in pool where picked.count < 3 {
            if !picked.contains(where: { $0.id == candidate.id }) {
                picked.append(candidate)
            }
        }
        return picked
    }

    public func chooseStarter(_ species: DaemonSpecies) {
        guard !save.starterChosen else { return }
        let starter = Daemon(species: species, level: 5)
        save.capture(starter)
        save.starterChosen = true
        needsOnboarding = false
        toast("\(species.name) joined you. It has strong opinions already.")
        refreshMeta()
        persist()
    }

    // MARK: - Battles

    public func startWildEncounter() {
        guard session == nil, !save.party.isEmpty else { return }
        encounterCounter += 1
        var rng = SeededRandom("enc|\(Date().timeIntervalSince1970)|\(encounterCounter)")
        guard let wild = WorldGen.rollEncounter(bestiary: bestiary, region: region,
                                                cycle: loadCycle, rng: &rng) else { return }
        save.markSeen(wild.species.id)
        beginSession(kind: .wild(wild), seedSuffix: "wild\(encounterCounter)")
    }

    public func startRivalBattle() {
        guard session == nil, !save.party.isEmpty else { return }
        let stage = min(3, save.rivalStage + 1)
        let trainer = Rival.trainer(stage: stage, bestiary: bestiary,
                                    playerMaxLevel: save.maxPartyLevel)
        battleLog.append("\(trainer.name): \(trainer.introLine)")
        beginSession(kind: .trainer(trainer), seedSuffix: "rival\(stage)|\(encounterCounter)")
    }

    private func beginSession(kind: BattleSession.Kind, seedSuffix: String) {
        battleFinalized = false
        let s = BattleSession(kind: kind, party: save.party,
                              seed: "battle|\(seedSuffix)|\(Date().timeIntervalSince1970)",
                              dexCaught: save.caughtCount, dexTotal: dexTotal)
        session = s
        enqueue(s.start())
        persist()
    }

    /// Submit a player action. Validates & consumes resources first.
    public func act(_ action: PlayerAction) {
        guard let session, !session.isOver else { return }

        switch action {
        case .throwSphere(let sphere, _):
            guard save.sphereCount(sphere) > 0 else {
                battleLog.append("Out of \(sphere.name)s!")
                return
            }
            save.consumeSphere(sphere)
        case .useItem(let item):
            guard save.itemCount(item) > 0 else {
                battleLog.append("No \(item.name) left.")
                return
            }
            save.consumeItem(item)
        default:
            break
        }

        let events = session.submit(action)
        enqueue(events)
        objectWillChange.send()   // session is a class; force a UI refresh

        if session.isOver { finalizeBattle() }
        persist()
    }

    /// Commits battle results to the save (idempotent).
    private func finalizeBattle() {
        guard let session, let outcome = session.outcome, !battleFinalized else { return }
        battleFinalized = true

        // Write back party state (HP, XP, levels, ascensions, status).
        save.party = session.party

        switch outcome {
        case .victory:
            save.stats.battlesWon += 1
            let payout = payoutFromEvents()
            if payout > 0 { save.earn(payout) }
            if session.isTrainerBattle, let t = session.trainer,
               t.id.hasPrefix("rival_stage") {
                save.rivalStage = max(save.rivalStage, min(3, save.rivalStage + 1))
            }
        case .captured:
            if var caught = session.capturedDaemon {
                caught.resetBattleState()
                save.capture(caught)
                toast("\(caught.species.name) was bound!\(caught.isAnomalous ? " It's anomalous!" : "")")
            }
        case .defeat:
            save.stats.battlesLost += 1
            // Blackout: Patch reboots everyone; a service fee vanishes.
            for i in save.party.indices { save.party[i].fullHeal() }
            let fee = save.cycles / 10
            _ = save.spend(fee)
            toast("Party rebooted at the clinic. \(fee)¢ 'gratitude' accepted.")
        case .fled:
            break
        }

        refreshMeta()
        persist()
    }

    /// The UI calls this when its battle outro animation finishes.
    public func dismissBattle() {
        guard session?.isOver != false else { return }  // don't dismiss mid-fight
        session = nil
        eventQueue.removeAll()
    }

    /// Force-end (used by Run in overworld before session exists edge cases).
    public func abortBattle() {
        session = nil
        eventQueue.removeAll()
    }

    private func payoutFromEvents() -> Int {
        var total = 0
        for e in battleEventsThisBattle {
            if case .payout(let amount) = e { total += amount }
        }
        return total
    }

    private var battleEventsThisBattle: [BattleEvent] = []

    private func enqueue(_ events: [BattleEvent]) {
        if let first = events.first, case .battleStarted = first {
            battleEventsThisBattle = []
        }
        eventQueue.append(contentsOf: events)
        battleEventsThisBattle.append(contentsOf: events)
        for e in events {
            if let line = Narrator.line(for: e) { battleLog.append(line) }
        }
        if battleLog.count > 80 { battleLog.removeFirst(battleLog.count - 80) }
    }

    /// Choreography layer pulls pending events (FIFO) and animates them.
    public func consumeEvents() -> [BattleEvent] {
        let events = eventQueue
        eventQueue.removeAll()
        return events
    }

    // MARK: - NPCs & quests

    public func talk(to npc: NPC) {
        save.talkedTo.insert(npc.id)
        refreshMeta()
        persist()
    }

    /// Auto-claims the current quest when its objective is met.
    private func claimQuestIfReady() {
        guard let quest = currentQuest,
              QuestEngine.evaluate(quest.objective, save: save).done else { return }
        save.completedQuests.insert(quest.id)
        save.earn(quest.rewardCycles)
        for (id, n) in quest.rewardSpheres { save.inventory[id, default: 0] += n }
        for (id, n) in quest.rewardItems { save.items[id, default: 0] += n }
        toast("Quest complete: \(quest.title) — +\(quest.rewardCycles)¢")
        battleLog.append(quest.completionLine)
    }

    private func checkAchievements() {
        for a in AchievementEngine.newlyEarned(save: save, dexTotal: dexTotal) {
            save.earnedAchievements.insert(a.id)
            toast("Achievement: \(a.title)")
        }
    }

    /// Run quest + achievement checks (quests can cascade).
    private func refreshMeta() {
        claimQuestIfReady()
        claimQuestIfReady()
        checkAchievements()
    }

    private func toast(_ text: String) {
        toasts.append(text)
        if toasts.count > 4 { toasts.removeFirst() }
    }

    public func dismissToast() {
        if !toasts.isEmpty { toasts.removeFirst() }
    }

    // MARK: - Economy

    @discardableResult
    public func buySphere(_ sphere: Sphere) -> Bool {
        guard save.spend(sphere.price) else { return false }
        save.inventory[sphere.id, default: 0] += 1
        refreshMeta()
        persist()
        return true
    }

    @discardableResult
    public func buyItem(_ item: Item) -> Bool {
        guard save.spend(item.price) else { return false }
        save.items[item.id, default: 0] += 1
        refreshMeta()
        persist()
        return true
    }

    /// Use an item on a party member outside battle.
    public func useItem(_ item: Item, onPartyIndex index: Int) {
        guard save.party.indices.contains(index), save.itemCount(item) > 0 else { return }
        var d = save.party[index]
        switch item.effect {
        case .heal(let amount):
            guard !d.isFainted, d.currentHP < d.maxHP else { return }
            d.currentHP = min(d.maxHP, d.currentHP + amount)
        case .fullHeal:
            guard !d.isFainted, d.currentHP < d.maxHP else { return }
            d.currentHP = d.maxHP
        case .cureStatus:
            guard d.status != .none else { return }
            d.status = .none
            d.statusTurns = 0
        case .revive:
            guard d.isFainted else { return }
            d.currentHP = max(1, d.maxHP / 2)
            d.status = .none
        case .xpBoost(let amount):
            d.xp += amount
            let newLevel = Experience.level(forXP: d.xp)
            if newLevel > d.level {
                d.level = newLevel
                toast("\(d.species.name) reached Lv\(newLevel)!")
                if Ascension.canAscend(d.species, at: newLevel) {
                    let old = d.species.name
                    d.species = Ascension.ascend(d.species)
                    toast("✦ \(old) ascended into \(d.species.name)! ✦")
                }
            }
        }
        save.consumeItem(item)
        save.party[index] = d
        refreshMeta()
        persist()
    }

    // MARK: - Party & world management

    public func setLead(_ index: Int) {
        guard save.party.indices.contains(index), index != 0 else { return }
        save.party.swapAt(0, index)
        persist()
    }

    public func moveToBox(_ index: Int) {
        guard save.party.indices.contains(index), save.party.count > 1 else { return }
        let d = save.party.remove(at: index)
        save.box.append(d)
        persist()
    }

    public func withdrawFromBox(_ index: Int) {
        guard save.box.indices.contains(index), save.party.count < 6 else { return }
        let d = save.box.remove(at: index)
        save.party.append(d)
        persist()
    }

    public func travel(to project: String) {
        guard bestiary.regions.contains(project), session == nil else { return }
        save.currentRegion = project
        region = WorldGen.region(for: project)
        persist()
    }

    /// Free full-party heal at the Hub clinic.
    public func healPartyAtHub() {
        for i in save.party.indices { save.party[i].fullHeal() }
        persist()
    }

    // MARK: - Settings

    public var settings: GameSettings {
        get { save.settings }
        set {
            save.settings = newValue
            Cues.configure(sound: newValue.soundOn, haptics: newValue.hapticsOn)
            persist()
        }
    }

    // MARK: - Time & persistence

    /// Called by the shell on a timer; advances playtime (drives load cycles).
    public func tickPlaytime(_ dt: Double) {
        save.playtimeSeconds += dt
        playtimeSinceSave += dt
        if playtimeSinceSave > 30 {
            playtimeSinceSave = 0
            persist()
        }
    }

    public func persist() { SharedStore.save(save) }

    /// Wipe the save and restart (Settings → New Game).
    public func resetGame() {
        SharedStore.deleteSave()
        let player = AgentConfigStore.readPlayer() ?? save.player
        save = SaveState.newGame(player: player)
        session = nil
        eventQueue.removeAll()
        battleLog.removeAll()
        needsOnboarding = true
        persist()
    }
}
