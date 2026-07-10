import Foundation

/// Player-tunable settings, persisted with the save.
public struct GameSettings: Codable, Equatable, Sendable {
    public var classicBattles: Bool
    public var soundOn: Bool
    public var hapticsOn: Bool
    public var showDamageNumbers: Bool

    public init(classicBattles: Bool = false, soundOn: Bool = true,
                hapticsOn: Bool = true, showDamageNumbers: Bool = true) {
        self.classicBattles = classicBattles
        self.soundOn = soundOn
        self.hapticsOn = hapticsOn
        self.showDamageNumbers = showDamageNumbers
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        classicBattles = try c.decodeIfPresent(Bool.self, forKey: .classicBattles) ?? false
        soundOn = try c.decodeIfPresent(Bool.self, forKey: .soundOn) ?? true
        hapticsOn = try c.decodeIfPresent(Bool.self, forKey: .hapticsOn) ?? true
        showDamageNumbers = try c.decodeIfPresent(Bool.self, forKey: .showDamageNumbers) ?? true
    }
}

/// Lifetime counters that feed quests + achievements.
public struct GameStats: Codable, Equatable, Sendable {
    public var battlesWon: Int
    public var battlesLost: Int
    public var catches: Int
    public var throws_: Int          // "throws" is soft-keyword-adjacent; keep safe
    public var anomalousCatches: Int
    public var cyclesEarned: Int     // lifetime, never decremented

    public var throwsCount: Int { throws_ }

    public init(battlesWon: Int = 0, battlesLost: Int = 0, catches: Int = 0,
                throws_: Int = 0, anomalousCatches: Int = 0, cyclesEarned: Int = 0) {
        self.battlesWon = battlesWon; self.battlesLost = battlesLost
        self.catches = catches; self.throws_ = throws_
        self.anomalousCatches = anomalousCatches; self.cyclesEarned = cyclesEarned
    }

    enum CodingKeys: String, CodingKey {
        case battlesWon, battlesLost, catches
        case throws_ = "throwsMade"
        case anomalousCatches, cyclesEarned
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        battlesWon = try c.decodeIfPresent(Int.self, forKey: .battlesWon) ?? 0
        battlesLost = try c.decodeIfPresent(Int.self, forKey: .battlesLost) ?? 0
        catches = try c.decodeIfPresent(Int.self, forKey: .catches) ?? 0
        throws_ = try c.decodeIfPresent(Int.self, forKey: .throws_) ?? 0
        anomalousCatches = try c.decodeIfPresent(Int.self, forKey: .anomalousCatches) ?? 0
        cyclesEarned = try c.decodeIfPresent(Int.self, forKey: .cyclesEarned) ?? 0
    }
}

/// The live game state. NOT directly Codable — `SaveCodec` converts to/from the
/// durable `SaveFile` (which stores compact `DaemonRecord`s and regenerates
/// species deterministically on load).
public struct SaveState: Equatable, Sendable {
    public var player: PlayerProfile
    public var party: [Daemon]                 // up to 6, active first
    public var box: [Daemon]                    // overflow storage
    public var inventory: [String: Int]         // sphere id → count
    public var items: [String: Int]             // item id → count
    public var cycles: Int                      // currency
    public var dex: [String: DexStatus]         // species id → status
    public var currentRegion: String            // project name
    public var completedQuests: Set<String>
    public var earnedAchievements: Set<String>
    public var talkedTo: Set<String>            // npc ids spoken to
    public var rivalStage: Int                  // 0...3 rival bouts won
    public var starterChosen: Bool
    public var settings: GameSettings
    public var stats: GameStats
    public var playtimeSeconds: Double

    public init(player: PlayerProfile, party: [Daemon] = [], box: [Daemon] = [],
                inventory: [String: Int] = [:], items: [String: Int] = [:],
                cycles: Int = 0, dex: [String: DexStatus] = [:],
                currentRegion: String = "mangos",
                completedQuests: Set<String> = [], earnedAchievements: Set<String> = [],
                talkedTo: Set<String> = [], rivalStage: Int = 0,
                starterChosen: Bool = false, settings: GameSettings = GameSettings(),
                stats: GameStats = GameStats(), playtimeSeconds: Double = 0) {
        self.player = player; self.party = party; self.box = box
        self.inventory = inventory; self.items = items; self.cycles = cycles
        self.dex = dex; self.currentRegion = currentRegion
        self.completedQuests = completedQuests
        self.earnedAchievements = earnedAchievements
        self.talkedTo = talkedTo; self.rivalStage = rivalStage
        self.starterChosen = starterChosen; self.settings = settings
        self.stats = stats; self.playtimeSeconds = playtimeSeconds
    }

    // MARK: Derived

    public var activeDaemon: Daemon? { party.first { !$0.isFainted } ?? party.first }
    public var caughtCount: Int { dex.values.filter { $0 == .caught }.count }
    public var seenCount: Int { dex.values.filter { $0 != .unknown }.count }
    public var maxPartyLevel: Int { party.map { $0.level }.max() ?? 5 }
    public var loadCycle: LoadCycle { LoadCycle.at(playtimeSeconds: playtimeSeconds) }

    // MARK: Mutations

    public mutating func markSeen(_ speciesID: String) {
        if (dex[speciesID] ?? .unknown) == .unknown { dex[speciesID] = .seen }
    }

    public mutating func capture(_ daemon: Daemon) {
        dex[daemon.species.id] = .caught
        stats.catches += 1
        if daemon.isAnomalous { stats.anomalousCatches += 1 }
        if party.count < 6 { party.append(daemon) } else { box.append(daemon) }
    }

    public mutating func earn(_ amount: Int) {
        cycles += amount
        stats.cyclesEarned += max(0, amount)
    }

    @discardableResult
    public mutating func spend(_ amount: Int) -> Bool {
        guard cycles >= amount else { return false }
        cycles -= amount
        return true
    }

    public func sphereCount(_ sphere: Sphere) -> Int { inventory[sphere.id] ?? 0 }
}

extension SaveState {

    @discardableResult
    public mutating func consumeSphere(_ sphere: Sphere) -> Bool {
        let n = inventory[sphere.id] ?? 0
        guard n > 0 else { return false }
        inventory[sphere.id] = n - 1
        stats.throws_ += 1
        return true
    }

    public func itemCount(_ item: Item) -> Int { items[item.id] ?? 0 }

    @discardableResult
    public mutating func consumeItem(_ item: Item) -> Bool {
        let n = items[item.id] ?? 0
        guard n > 0 else { return false }
        items[item.id] = n - 1
        return true
    }

    /// A fresh game seeded from a player profile and the starter kit.
    public static func newGame(player: PlayerProfile) -> SaveState {
        var inv: [String: Int] = [:]
        for s in Sphere.starterKit { inv[s.id, default: 0] += 1 }
        return SaveState(player: player, inventory: inv,
                         items: ["hotfix": 2], cycles: 200)
    }
}

// MARK: - Durable format

/// The versioned on-disk format. Species are stored as records (profile +
/// instance state) and regenerated on load, so generator improvements
/// retroactively upgrade saved daemons.
public struct SaveFile: Codable, Sendable {
    public var version: Int
    public var player: PlayerProfile
    public var party: [DaemonRecord]
    public var box: [DaemonRecord]
    public var inventory: [String: Int]
    public var items: [String: Int]
    public var cycles: Int
    public var dex: [String: DexStatus]
    public var currentRegion: String
    public var completedQuests: [String]
    public var earnedAchievements: [String]
    public var talkedTo: [String]
    public var rivalStage: Int
    public var starterChosen: Bool
    public var settings: GameSettings
    public var stats: GameStats
    public var playtimeSeconds: Double

    public init(from state: SaveState) {
        version = 2
        player = state.player
        party = state.party.map(DaemonRecord.init)
        box = state.box.map(DaemonRecord.init)
        inventory = state.inventory
        items = state.items
        cycles = state.cycles
        dex = state.dex
        currentRegion = state.currentRegion
        completedQuests = Array(state.completedQuests)
        earnedAchievements = Array(state.earnedAchievements)
        talkedTo = Array(state.talkedTo)
        rivalStage = state.rivalStage
        starterChosen = state.starterChosen
        settings = state.settings
        stats = state.stats
        playtimeSeconds = state.playtimeSeconds
    }

    public func hydrate() -> SaveState {
        SaveState(
            player: player,
            party: party.map { $0.hydrate() },
            box: box.map { $0.hydrate() },
            inventory: inventory,
            items: items,
            cycles: cycles,
            dex: dex,
            currentRegion: currentRegion,
            completedQuests: Set(completedQuests),
            earnedAchievements: Set(earnedAchievements),
            talkedTo: Set(talkedTo),
            rivalStage: rivalStage,
            starterChosen: starterChosen,
            settings: settings,
            stats: stats,
            playtimeSeconds: playtimeSeconds
        )
    }
}

/// Serialize/deserialize saves, including a best-effort rescue of the v1
/// prototype format (which embedded whole species in the save).
public enum SaveCodec {

    public static func encode(_ state: SaveState) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(SaveFile(from: state))
    }

    public static func decode(_ data: Data) -> SaveState? {
        if let file = try? JSONDecoder().decode(SaveFile.self, from: data), file.version >= 2 {
            return file.hydrate()
        }
        return rescueLegacy(data)
    }

    /// v1 saves embedded full species JSON. Recover what matters: the player,
    /// party species ids + levels, inventory, and dex — rebuilt against
    /// deterministic generation via each species' embedded source data.
    static func rescueLegacy(_ data: Data) -> SaveState? {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return nil
        }
        // Player.
        var player = PlayerProfile.placeholder
        if let p = root["player"] as? [String: Any] {
            player = PlayerProfile(
                handle: p["handle"] as? String ?? "Conductor",
                bio: p["bio"] as? String ?? "",
                startingAspect: Aspect(rawValue: p["startingAspect"] as? String ?? "") ?? .flux,
                traits: p["traits"] as? [String] ?? []
            )
        }
        var state = SaveState.newGame(player: player)

        // Party: rebuild profiles from the embedded v1 species dictionaries.
        func daemon(from dict: [String: Any]) -> Daemon? {
            guard let species = dict["species"] as? [String: Any],
                  let id = species["id"] as? String else { return nil }
            let tier = Tier(rawValue: species["tier"] as? String ?? "") ?? .task
            let origin = Origin(rawValue: species["origin"] as? String ?? "") ?? .used
            let profile = AgentProfile(
                id: id,
                displayName: species["sourceAgentName"] as? String ?? id,
                tier: tier,
                role: (species["primaryAspect"] as? String) ?? "general",
                project: species["habitat"] as? String ?? "mangos",
                origin: origin
            )
            let level = dict["level"] as? Int ?? 5
            return DaemonRecord(
                from: Daemon(species: DaemonGenerator.generate(from: profile), level: level)
            ).hydrate()
        }
        if let party = root["party"] as? [[String: Any]] {
            state.party = party.compactMap(daemon(from:))
        }
        if let box = root["box"] as? [[String: Any]] {
            state.box = box.compactMap(daemon(from:))
        }
        if let inv = root["inventory"] as? [String: Int] { state.inventory = inv }
        if let dex = root["dex"] as? [String: String] {
            for (k, v) in dex { state.dex[k] = DexStatus(rawValue: v) ?? .seen }
        }
        state.stats.catches = state.caughtCount
        state.starterChosen = !state.party.isEmpty
        return state
    }
}
