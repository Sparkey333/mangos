import Foundation

/// The server's "load cycle" — this world's day/night. Derived from playtime so
/// it's deterministic and testable. Affects spawn rates and overworld tint.
public enum LoadCycle: String, CaseIterable, Sendable {
    case idle   // calm: more subs/tasks, softer light
    case busy   // standard mix
    case peak   // rare spawns more likely, world hums

    /// 10 minutes per phase, cycling idle → busy → peak.
    public static func at(playtimeSeconds: Double) -> LoadCycle {
        let phase = Int(playtimeSeconds / 600) % 3
        return [LoadCycle.idle, .busy, .peak][phase]
    }

    /// Spawn-weight multiplier for a tier during this cycle.
    public func spawnMultiplier(for tier: Tier) -> Double {
        switch (self, tier) {
        case (.idle, .sub), (.idle, .task):                 return 1.4
        case (.idle, .orchestrator), (.idle, .prime):        return 0.3
        case (.peak, .specialist):                           return 1.5
        case (.peak, .orchestrator):                         return 2.0
        case (.peak, .prime):                                return 3.0
        default:                                             return 1.0
        }
    }

    /// Ambient tint (hex) the scene overlays on the world.
    public var tintHex: String {
        switch self {
        case .idle: return "#1B2838"
        case .busy: return "#101822"
        case .peak: return "#2A1030"
        }
    }

    public var displayName: String {
        switch self {
        case .idle: return "Idle Hours"
        case .busy: return "Busy Hours"
        case .peak: return "Peak Load"
        }
    }
}

/// Region biomes — each project maps to one deterministically.
public enum Biome: String, CaseIterable, Sendable {
    case grove      // overgrown repo: greens
    case forge      // ember foundry: oranges
    case archive    // deep blue stacks
    case datalake   // teal shallows
    case voidnet    // purple static
    case cache      // warm sandstone

    public var groundHex: String {
        switch self {
        case .grove:    return "#12291B"
        case .forge:    return "#2A1510"
        case .archive:  return "#0E1B2E"
        case .datalake: return "#0D2626"
        case .voidnet:  return "#1B1029"
        case .cache:    return "#292112"
        }
    }

    public var accentHex: String {
        switch self {
        case .grove:    return "#39B54A"
        case .forge:    return "#FF6A3D"
        case .archive:  return "#4A90D9"
        case .datalake: return "#3ED8C3"
        case .voidnet:  return "#9B59D0"
        case .cache:    return "#E0B04A"
        }
    }
}

/// A circular encounter zone ("tall code") in normalized 0...1 coordinates.
public struct EncounterPatch: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var radius: Double
}

/// A decorative/interactive landmark in normalized coordinates.
public struct Landmark: Equatable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case serverPillar   // humming monolith
        case dataSpring     // glowing pool
        case brokenBuild    // rubble, comedic signage
        case antenna        // blinking relay
    }
    public var x: Double
    public var y: Double
    public var kind: Kind
}

/// A generated region: one per project. Deterministic from the project name.
public struct Region: Equatable, Sendable {
    public var project: String
    public var displayName: String
    public var biome: Biome
    public var patches: [EncounterPatch]
    public var landmarks: [Landmark]
}

public enum WorldGen {

    /// Build the region for a project. Same project → same region, forever.
    public static func region(for project: String) -> Region {
        var rng = SeededRandom("region|\(project)")

        let biomes = Biome.allCases
        let biome = biomes[Int(stableHash(project) % UInt64(biomes.count))]

        var patches: [EncounterPatch] = []
        let patchCount = rng.int(in: 3...5)
        for _ in 0..<patchCount {
            patches.append(EncounterPatch(
                x: 0.12 + 0.76 * rng.unit(),
                y: 0.15 + 0.6 * rng.unit(),
                radius: 0.07 + 0.08 * rng.unit()
            ))
        }

        var landmarks: [Landmark] = []
        let kinds = Landmark.Kind.allCases
        let landmarkCount = rng.int(in: 2...4)
        for _ in 0..<landmarkCount {
            landmarks.append(Landmark(
                x: 0.08 + 0.84 * rng.unit(),
                y: 0.1 + 0.7 * rng.unit(),
                kind: kinds[rng.int(in: 0...(kinds.count - 1))]
            ))
        }

        return Region(
            project: project,
            displayName: displayName(for: project, biome: biome),
            biome: biome,
            patches: patches,
            landmarks: landmarks
        )
    }

    static func displayName(for project: String, biome: Biome) -> String {
        let pretty = project.prefix(1).uppercased() + project.dropFirst()
        switch biome {
        case .grove:    return "\(pretty) Grove"
        case .forge:    return "The \(pretty) Foundry"
        case .archive:  return "\(pretty) Archives"
        case .datalake: return "Lake \(pretty)"
        case .voidnet:  return "\(pretty) Void-Net"
        case .cache:    return "\(pretty) Cache Flats"
        }
    }

    /// Roll a wild encounter for a region + load cycle, weighting tier spawn
    /// weights by the cycle's multipliers, and rolling the anomalous (shiny) bit.
    public static func rollEncounter(
        bestiary: Bestiary, region: Region, cycle: LoadCycle, rng: inout SeededRandom
    ) -> Daemon? {
        let pool = bestiary.species(inRegion: region.project)
        let usable = pool.isEmpty ? bestiary.species : pool
        guard !usable.isEmpty else { return nil }

        let weights = usable.map { sp -> Double in
            Double(sp.tier.spawnWeight) * cycle.spawnMultiplier(for: sp.tier)
        }
        let total = weights.reduce(0, +)
        var roll = rng.unit() * max(0.0001, total)
        var chosen = usable[usable.count - 1]
        for (i, w) in weights.enumerated() {
            roll -= w
            if roll <= 0 { chosen = usable[i]; break }
        }

        var level = bestiary.wildLevel(for: chosen.id)
        // Peak-load daemons run a little hotter.
        if cycle == .peak { level = min(Experience.maxLevel, level + rng.int(in: 0...3)) }

        let anomalous = rng.unit() < 1.0 / 64.0
        return Daemon(species: chosen, level: level, isAnomalous: anomalous)
    }
}
