import Foundation

/// The full set of species generated from your configured agents, plus helpers
/// for spawning wild encounters by region.
public struct Bestiary: Sendable {
    public let profiles: [AgentProfile]
    public let species: [DaemonSpecies]
    private let levelByID: [String: Int]

    public init(profiles: [AgentProfile]) {
        self.profiles = profiles
        self.species = profiles.map(DaemonGenerator.generate)
        var levels: [String: Int] = [:]
        for p in profiles { levels[p.id] = DaemonGenerator.wildLevel(for: p) }
        self.levelByID = levels
    }

    public func species(id: String) -> DaemonSpecies? { species.first { $0.id == id } }

    public var regions: [String] {
        Array(Set(profiles.map { $0.project })).sorted()
    }

    public func species(inRegion region: String) -> [DaemonSpecies] {
        let ids = Set(profiles.filter { $0.project == region }.map { $0.id })
        return species.filter { ids.contains($0.id) }
    }

    /// Default wild level for a species (deterministic, from its profile).
    public func wildLevel(for speciesID: String) -> Int { levelByID[speciesID] ?? 5 }

    /// Spawn a live wild Daemon for a species at its natural level.
    public func spawn(_ speciesID: String, rng: inout SeededRandom) -> Daemon? {
        guard let sp = species(id: speciesID) else { return nil }
        let lvl = wildLevel(for: speciesID)
        return Daemon(species: sp, level: lvl, instanceID: UUID())
    }

    /// Pick a weighted-random wild species for a region (rarer tiers less likely).
    public func rollEncounter(inRegion region: String, rng: inout SeededRandom) -> DaemonSpecies? {
        let pool = species(inRegion: region)
        guard !pool.isEmpty else { return nil }
        let weights = pool.map { $0.tier.spawnWeight }
        let total = weights.reduce(0, +)
        guard total > 0 else { return rng.pick(pool) }
        var roll = rng.int(in: 1...total)
        for (i, w) in weights.enumerated() {
            roll -= w
            if roll <= 0 { return pool[i] }
        }
        return pool.last
    }
}
