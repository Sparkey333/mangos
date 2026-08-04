import Foundation

/// Dex record state per species.
public enum DexStatus: String, Codable, Sendable {
    case unknown    // never encountered
    case seen       // met in the wild (or glimpsed in logs)
    case caught
}

/// The generated, immutable "species" for one agent. Same agent → same species.
/// Carries its `sourceProfile` so saves can store tiny records and regenerate
/// the species deterministically on load (see `DaemonRecord`).
public struct DaemonSpecies: Codable, Equatable, Identifiable, Sendable {
    public var id: String                 // == source AgentProfile.id
    public var name: String               // species name, derived from agent
    public var sourceAgentName: String
    public var sourceProfile: AgentProfile
    public var tier: Tier
    public var primaryAspect: Aspect
    public var secondaryAspect: Aspect?
    public var baseStats: BaseStats
    public var nature: Nature
    public var ivs: IVs
    public var ability: Ability
    public var sprite: SpriteRecipe
    public var habitat: String            // source project
    public var origin: Origin
    public var flavor: String             // the in-voice description
    public var catchBaseRate: Int         // lower = harder (like Pokémon's rate)
    public var isAscended: Bool           // evolved form?

    public init(id: String, name: String, sourceAgentName: String,
                sourceProfile: AgentProfile, tier: Tier,
                primaryAspect: Aspect, secondaryAspect: Aspect?, baseStats: BaseStats,
                nature: Nature, ivs: IVs, ability: Ability, sprite: SpriteRecipe,
                habitat: String, origin: Origin, flavor: String, catchBaseRate: Int,
                isAscended: Bool = false) {
        self.id = id; self.name = name; self.sourceAgentName = sourceAgentName
        self.sourceProfile = sourceProfile
        self.tier = tier; self.primaryAspect = primaryAspect
        self.secondaryAspect = secondaryAspect; self.baseStats = baseStats
        self.nature = nature; self.ivs = ivs; self.ability = ability
        self.sprite = sprite; self.habitat = habitat; self.origin = origin
        self.flavor = flavor; self.catchBaseRate = catchBaseRate
        self.isAscended = isAscended
    }

    public var aspects: [Aspect] { secondaryAspect.map { [primaryAspect, $0] } ?? [primaryAspect] }

    /// Computed max HP at a given level (used to spawn instances).
    public func maxHP(at level: Int) -> Int {
        StatMath.value(for: .hp, base: baseStats.hp, iv: ivs.hp, level: level, nature: nature)
    }

    public func stat(_ stat: Stat, at level: Int) -> Int {
        StatMath.value(for: stat, base: baseStats[stat], iv: ivs[stat], level: level, nature: nature)
    }

    /// The moves a freshly-encountered member of this species knows at `level`.
    public func knownMoves(at level: Int) -> [Move] {
        var rng = SeededRandom("\(id)|moves")
        return MovePool.knownMoves(for: primaryAspect, secondary: secondaryAspect,
                                   level: level, rng: &rng)
    }
}

/// A live, mutable Daemon — in the world, in your party, or in a battle.
/// Not persisted directly: `DaemonRecord` stores the durable bits and
/// regenerates the species from its profile (deterministic generation!).
public struct Daemon: Equatable, Identifiable, Sendable {
    public var species: DaemonSpecies
    public var level: Int
    public var xp: Int
    public var currentHP: Int
    public var status: DaemonStatus
    public var statusTurns: Int           // remaining turns for timed statuses
    public var moves: [Move]              // up to 4, evolves with leveling
    public var isAnomalous: Bool          // "shiny": rare hue-shifted individual

    // Volatile battle state (reset by BattleSession at battle start).
    public var stages: StatStages
    public var failsafeAvailable: Bool

    /// Distinguishes individuals of the same species.
    public var instanceID: UUID
    public var id: UUID { instanceID }

    public init(species: DaemonSpecies, level: Int, xp: Int? = nil,
                currentHP: Int? = nil, status: DaemonStatus = .none,
                statusTurns: Int = 0, moves: [Move]? = nil,
                isAnomalous: Bool = false, instanceID: UUID = UUID()) {
        self.species = species
        self.level = max(1, min(Experience.maxLevel, level))
        self.xp = xp ?? Experience.totalXP(forLevel: level)
        self.currentHP = currentHP ?? species.maxHP(at: level)
        self.status = status
        self.statusTurns = statusTurns
        self.moves = moves ?? species.knownMoves(at: level)
        self.isAnomalous = isAnomalous
        self.stages = StatStages()
        self.failsafeAvailable = species.ability == .failsafe
        self.instanceID = instanceID
    }

    public var maxHP: Int { species.maxHP(at: level) }
    public var isFainted: Bool { currentHP <= 0 }
    public var hpFraction: Double { maxHP > 0 ? Double(currentHP) / Double(maxHP) : 0 }

    /// Raw stat (no stages/status). Battle math applies stages via BattleEngine.
    public func stat(_ stat: Stat) -> Int { species.stat(stat, at: level) }

    /// Effective in-battle stat with stages and status applied.
    public func battleStat(_ stat: Stat) -> Int {
        var value = Double(self.stat(stat))
        switch stat {
        case .atk: value *= stages.multiplier(.atk) * status.attackMultiplier
        case .def: value *= stages.multiplier(.def)
        case .spa: value *= stages.multiplier(.spa)
        case .spd: value *= stages.multiplier(.spd)
        case .spe: value *= stages.multiplier(.spe) * status.speedMultiplier
        case .hp: break
        }
        return max(1, Int(value))
    }

    public mutating func resetBattleState() {
        stages.reset()
        failsafeAvailable = species.ability == .failsafe
    }

    public mutating func fullHeal() {
        currentHP = maxHP
        status = .none
        statusTurns = 0
    }
}

/// The compact, durable form of a Daemon that goes in the save file. Species
/// data is NOT stored — it's regenerated from the profile, which also means
/// generator improvements retroactively upgrade saved daemons.
public struct DaemonRecord: Codable, Equatable, Sendable {
    public var profile: AgentProfile
    public var level: Int
    public var xp: Int
    public var currentHP: Int
    public var status: DaemonStatus
    public var statusTurns: Int
    public var isAscended: Bool
    public var isAnomalous: Bool
    public var instanceID: UUID

    public init(from daemon: Daemon) {
        self.profile = daemon.species.sourceProfile
        self.level = daemon.level
        self.xp = daemon.xp
        self.currentHP = daemon.currentHP
        self.status = daemon.status
        self.statusTurns = daemon.statusTurns
        self.isAscended = daemon.species.isAscended
        self.isAnomalous = daemon.isAnomalous
        self.instanceID = daemon.instanceID
    }

    /// Rebuild the live daemon (species regenerated deterministically).
    public func hydrate() -> Daemon {
        var species = DaemonGenerator.generate(from: profile)
        if isAscended { species = Ascension.ascend(species) }
        let hp = min(max(0, currentHP), species.maxHP(at: level))
        return Daemon(species: species, level: level, xp: xp, currentHP: hp,
                      status: status, statusTurns: statusTurns,
                      isAnomalous: isAnomalous, instanceID: instanceID)
    }
}
