import Foundation

/// Ascension — this game's evolution. When a daemon reaches its tier's
/// ascension level, it transforms: bigger stats, a grander name, a brighter
/// aura. The transform is a pure function of the species, so it's deterministic
/// and reversible in saves (a `DaemonRecord` just stores `isAscended`).
public enum Ascension {

    /// Stat multiplier applied on ascension.
    public static let statBoost = 1.12

    /// Level at which `species` ascends, or nil if it never does.
    public static func level(for species: DaemonSpecies) -> Int? {
        species.isAscended ? nil : species.tier.ascensionLevel
    }

    /// Whether a daemon at `level` qualifies to ascend.
    public static func canAscend(_ species: DaemonSpecies, at level: Int) -> Bool {
        // Self-qualified: the `level` parameter shadows the function name.
        guard let threshold = Self.level(for: species) else { return false }
        return level >= threshold
    }

    /// The ascended form. Idempotent: ascending an ascended species returns it.
    public static func ascend(_ species: DaemonSpecies) -> DaemonSpecies {
        guard !species.isAscended else { return species }
        var s = species
        s.isAscended = true
        s.name = ascendedName(species.name, aspect: species.primaryAspect)
        s.baseStats = BaseStats(
            hp: boost(species.baseStats.hp), atk: boost(species.baseStats.atk),
            def: boost(species.baseStats.def), spa: boost(species.baseStats.spa),
            spd: boost(species.baseStats.spd), spe: boost(species.baseStats.spe)
        )
        s.sprite.auraIntensity = min(1.0, species.sprite.auraIntensity + 0.25)
        s.sprite.segments = species.sprite.segments + 2
        s.sprite.motif = "ascended-" + species.sprite.motif
        s.catchBaseRate = max(1, species.catchBaseRate / 2)
        s.flavor = species.flavor + " Since ascending, it refuses to answer to its old name."
        return s
    }

    static func boost(_ value: Int) -> Int {
        max(value + 1, Int((Double(value) * statBoost).rounded()))
    }

    /// "Explolux" → "Archexplolux" style naming, tinted per aspect.
    static func ascendedName(_ base: String, aspect: Aspect) -> String {
        let prefix: String
        switch aspect {
        case .aether: prefix = "Lumen"
        case .forge:  prefix = "Pyro"
        case .order:  prefix = "Meta"
        case .warden: prefix = "Aegis"
        case .flux:   prefix = "Omni"
        case .cipher: prefix = "Crypt"
        }
        return prefix + base.lowercased()
    }
}
