import Foundation

/// Turns an `AgentProfile` into a `DaemonSpecies` deterministically.
/// The same profile id (+ project) always yields the identical species.
public enum DaemonGenerator {

    public static func generate(from profile: AgentProfile) -> DaemonSpecies {
        var rng = SeededRandom("\(profile.id)|\(profile.project)")

        let primary = Aspect.from(role: profile.role)
        let secondary = secondaryAspect(for: profile, primary: primary, rng: &rng)
        let base = distributeStats(bst: profile.tier.baseStatTotal,
                                   primary: primary, secondary: secondary, rng: &rng)
        let nature = rng.pick(Nature.allCases)
        let ivs = IVs(hp: rng.int(in: 0...31), atk: rng.int(in: 0...31),
                      def: rng.int(in: 0...31), spa: rng.int(in: 0...31),
                      spd: rng.int(in: 0...31), spe: rng.int(in: 0...31))
        let ability = pickAbility(tier: profile.tier, primary: primary, rng: &rng)
        let sprite = spriteRecipe(tier: profile.tier, primary: primary, rng: &rng)
        let name = speciesName(base: profile.displayName, aspect: primary, rng: &rng)
        let flavor = flavorLine(profile: profile, primary: primary, nature: nature, rng: &rng)
        let catchRate = catchBaseRate(tier: profile.tier, origin: profile.origin)

        return DaemonSpecies(
            id: profile.id, name: name, sourceAgentName: profile.displayName,
            sourceProfile: profile,
            tier: profile.tier, primaryAspect: primary, secondaryAspect: secondary,
            baseStats: base, nature: nature, ivs: ivs, ability: ability,
            sprite: sprite, habitat: profile.project, origin: profile.origin,
            flavor: flavor, catchBaseRate: catchRate
        )
    }

    /// A starting level for a wild instance, blending the tier band with how
    /// often the agent has been used (`encounters`). Deterministic per profile.
    public static func wildLevel(for profile: AgentProfile) -> Int {
        var rng = SeededRandom("\(profile.id)|level")
        let band = profile.tier.baseLevelBand
        let base = rng.int(in: band)
        // Heavy use nudges the level up a little, capped within reason.
        let usageBonus = min(8, Int((log2(Double(max(1, profile.encounters)))).rounded()))
        return min(100, base + usageBonus)
    }

    // MARK: - Pieces

    static func secondaryAspect(for profile: AgentProfile, primary: Aspect,
                                rng: inout SeededRandom) -> Aspect? {
        let chance: Double
        switch profile.tier {
        case .prime:        chance = 1.0
        case .orchestrator: chance = 0.85
        case .specialist:   chance = 0.40
        case .task:         chance = 0.15
        case .sub:          chance = 0.0
        }
        guard rng.unit() < chance else { return nil }
        let others = Aspect.allCases.filter { $0 != primary }
        return rng.pick(others)
    }

    static func pickAbility(tier: Tier, primary: Aspect, rng: inout SeededRandom) -> Ability {
        // Primes have a shot at the crown-jewel ability.
        if tier == .prime && rng.unit() < 0.5 { return .loadBalancer }
        return rng.pick(Ability.pool(for: primary))
    }

    static func distributeStats(bst: Int, primary: Aspect, secondary: Aspect?,
                                rng: inout SeededRandom) -> BaseStats {
        let pW = primary.statWeights
        let sW = secondary?.statWeights
        func w(_ s: Stat) -> Double {
            let p = pW[s]
            guard let sW else { return p }
            return (p * 0.65) + (sW[s] * 0.35)
        }
        // Per-stat weight with a small deterministic jitter so individuals vary.
        var raw: [Stat: Double] = [:]
        for s in Stat.allCases { raw[s] = w(s) * (0.9 + 0.2 * rng.unit()) }
        let totalW = raw.values.reduce(0, +)
        // Scale to the BST budget, enforce a floor, then fix rounding drift.
        let floor = 10
        var result: [Stat: Int] = [:]
        for s in Stat.allCases {
            let share = Double(bst) * (raw[s]! / totalW)
            result[s] = max(floor, Int(share.rounded()))
        }
        // Reconcile to exactly `bst` by nudging the largest stat.
        var diff = bst - result.values.reduce(0, +)
        let order = Stat.allCases.sorted { result[$0]! > result[$1]! }
        var i = 0
        while diff != 0 {
            let s = order[i % order.count]
            let step = diff > 0 ? 1 : -1
            if result[s]! + step >= floor { result[s]! += step; diff -= step }
            i += 1
            if i > 10_000 { break } // safety
        }
        return BaseStats(hp: result[.hp]!, atk: result[.atk]!, def: result[.def]!,
                         spa: result[.spa]!, spd: result[.spd]!, spe: result[.spe]!)
    }

    static func spriteRecipe(tier: Tier, primary: Aspect,
                             rng: inout SeededRandom) -> SpriteRecipe {
        let palette = primary.palette
        let motif = rng.pick(motifs(for: primary))
        let auraByTier: [Tier: Double] = [.sub: 0.15, .task: 0.3, .specialist: 0.5,
                                          .orchestrator: 0.75, .prime: 1.0]
        return SpriteRecipe(
            sigil: tier.sigil,
            primaryColorHex: palette.primary,
            secondaryColorHex: palette.secondary,
            motif: motif,
            auraIntensity: auraByTier[tier] ?? 0.3,
            segments: tier.sigil.symmetry
        )
    }

    static func motifs(for aspect: Aspect) -> [String] {
        switch aspect {
        case .aether: return ["orbiting-glyphs", "halo-rings", "starfield-core"]
        case .forge:  return ["molten-core", "anvil-spark", "ember-trail"]
        case .order:  return ["lattice-shell", "blueprint-grid", "crystal-facets"]
        case .warden: return ["rune-shield", "stone-plates", "ward-circle"]
        case .flux:   return ["iridescent-shift", "prism-cloud", "mercury-drip"]
        case .cipher: return ["glitch-static", "redacted-bars", "scanline-veil"]
        }
    }

    static func speciesName(base: String, aspect: Aspect, rng: inout SeededRandom) -> String {
        let suffixes: [Aspect: [String]] = [
            .aether: ["lux", "ari", "sol"],
            .forge:  ["mok", "dross", "kor"],
            .order:  ["geon", "alis", "dex"],
            .warden: ["gar", "thol", "rune"],
            .flux:   ["morph", "shi", "vex"],
            .cipher: ["hex", "null", "zib"]
        ]
        let cleaned = base.lowercased().filter { $0.isLetter }
        let stem = String(cleaned.prefix(5))
        let root = stem.isEmpty ? "dae" : stem
        let suffix = rng.pick(suffixes[aspect] ?? ["mon"])
        return (root + suffix).capitalized
    }

    static func flavorLine(profile: AgentProfile, primary: Aspect, nature: Nature,
                           rng: inout SeededRandom) -> String {
        let originBits: [String]
        switch profile.origin {
        case .directlyCreated: originBits = [
            "Hand-forged by the Conductor and weirdly proud of it.",
            "Custom-built. Considers itself artisanal.",
            "Written from scratch on a Tuesday that got out of hand."
        ]
        case .used: originBits = [
            "Bound after one too many late-night invocations.",
            "Answered so many calls it started screening them.",
            "A reliable regular. Has a usual. The usual is 'everything, now.'"
        ]
        case .seenInLogs: originBits = [
            "Only ever glimpsed in the logs, like a rumor with a stack trace.",
            "Exists mostly as timestamps and hearsay.",
            "Nobody remembers summoning it. It remembers, though."
        ]
        }
        let aspectBit: String
        switch primary {
        case .aether: aspectBit = "Reads everything. Retains most of it. Won't stop citing sources."
        case .forge:  aspectBit = "Builds first, asks questions during the postmortem."
        case .order:  aspectBit = "Has a plan for the plan. The plan has a subsection."
        case .warden: aspectBit = "Reviews your every move. Lovingly. Relentlessly."
        case .flux:   aspectBit = "Does a bit of everything, master of the current vibe."
        case .cipher: aspectBit = "Speaks fluent log. Translation services not included."
        }
        let originBit = rng.pick(originBits)
        return "\(originBit) \(aspectBit) Nature: \(nature.rawValue)."
    }

    static func catchBaseRate(tier: Tier, origin: Origin) -> Int {
        // Lower = harder (mirrors Pokémon's 3...255 scale).
        let byTier: [Tier: Int] = [.sub: 200, .task: 150, .specialist: 90,
                                   .orchestrator: 45, .prime: 5]
        var rate = byTier[tier] ?? 100
        if origin == .seenInLogs { rate = max(1, rate / 2) } // ghosts are slippery
        return rate
    }
}
