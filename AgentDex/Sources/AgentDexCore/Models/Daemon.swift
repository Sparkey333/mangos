import Foundation

/// A non-volatile status condition. `stalled`/`looped` improve catch rate.
public enum DaemonStatus: String, Codable, Sendable {
    case none, stalled, looped
}

/// The generated, immutable "species" for one agent. Same agent → same species.
public struct DaemonSpecies: Codable, Equatable, Identifiable, Sendable {
    public var id: String                 // == source AgentProfile.id
    public var name: String               // species name, derived from agent
    public var sourceAgentName: String
    public var tier: Tier
    public var primaryAspect: Aspect
    public var secondaryAspect: Aspect?
    public var baseStats: BaseStats
    public var nature: Nature
    public var ivs: IVs
    public var moves: [Move]
    public var sprite: SpriteRecipe
    public var habitat: String            // source project
    public var origin: Origin
    public var flavor: String             // the in-voice description
    public var catchBaseRate: Int         // lower = harder (like Pokémon's rate)

    public init(id: String, name: String, sourceAgentName: String, tier: Tier,
                primaryAspect: Aspect, secondaryAspect: Aspect?, baseStats: BaseStats,
                nature: Nature, ivs: IVs, moves: [Move], sprite: SpriteRecipe,
                habitat: String, origin: Origin, flavor: String, catchBaseRate: Int) {
        self.id = id; self.name = name; self.sourceAgentName = sourceAgentName
        self.tier = tier; self.primaryAspect = primaryAspect
        self.secondaryAspect = secondaryAspect; self.baseStats = baseStats
        self.nature = nature; self.ivs = ivs; self.moves = moves; self.sprite = sprite
        self.habitat = habitat; self.origin = origin; self.flavor = flavor
        self.catchBaseRate = catchBaseRate
    }

    public var aspects: [Aspect] { secondaryAspect.map { [primaryAspect, $0] } ?? [primaryAspect] }

    /// Computed max HP at a given level (used to spawn instances).
    public func maxHP(at level: Int) -> Int {
        StatMath.value(for: .hp, base: baseStats.hp, iv: ivs.hp, level: level, nature: nature)
    }

    public func stat(_ stat: Stat, at level: Int) -> Int {
        StatMath.value(for: stat, base: baseStats[stat], iv: ivs[stat], level: level, nature: nature)
    }
}

/// A live, mutable Daemon in the world or in your party.
public struct Daemon: Codable, Equatable, Identifiable, Sendable {
    public var species: DaemonSpecies
    public var level: Int
    public var currentHP: Int
    public var status: DaemonStatus
    /// Distinguishes individuals of the same species in the party.
    public var instanceID: UUID

    public var id: UUID { instanceID }

    public init(species: DaemonSpecies, level: Int,
                currentHP: Int? = nil, status: DaemonStatus = .none,
                instanceID: UUID = UUID()) {
        self.species = species
        self.level = level
        self.currentHP = currentHP ?? species.maxHP(at: level)
        self.status = status
        self.instanceID = instanceID
    }

    public var maxHP: Int { species.maxHP(at: level) }
    public var isFainted: Bool { currentHP <= 0 }
    public var hpFraction: Double { maxHP > 0 ? Double(currentHP) / Double(maxHP) : 0 }

    public func stat(_ stat: Stat) -> Int { species.stat(stat, at: level) }
}
