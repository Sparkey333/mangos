import Foundation

/// Fighting + sphere throwing. Gen-4-style shake checks so near-misses *read*
/// as fair, plus critical captures that scale with your Dex progress.
public enum CatchCalculator {

    public struct Attempt: Equatable, Sendable {
        public var probability: Double   // 0...1, the per-throw capture chance
        public var shakes: Int           // 0...3 shakes shown before the verdict
        public var captured: Bool
        public var critical: Bool        // critical capture: one emphatic shake

        public init(probability: Double, shakes: Int, captured: Bool, critical: Bool) {
            self.probability = probability; self.shakes = shakes
            self.captured = captured; self.critical = critical
        }
    }

    /// The 0...1 capture probability for a single throw. Pure & testable.
    /// - throwQuality: 0...1 skill bonus from the resonance-ring timing game.
    public static func probability(
        target: Daemon, sphere: Sphere, throwQuality: Double = 0
    ) -> Double {
        let species = target.species
        // Primes need a Prime Sigil to be realistically bindable.
        if species.tier == .prime && !sphere.canBindPrime {
            return min(0.02, rawProbability(target: target, sphere: sphere, throwQuality: throwQuality))
        }
        return rawProbability(target: target, sphere: sphere, throwQuality: throwQuality)
    }

    private static func rawProbability(
        target: Daemon, sphere: Sphere, throwQuality: Double
    ) -> Double {
        let species = target.species
        let maxHP = Double(max(1, target.maxHP))
        let hp = Double(max(0, target.currentHP))

        let rate = Double(species.catchBaseRate)
        var ball = sphere.baseMultiplier

        // Aspect affinity bonus.
        if let aff = sphere.affinityAspect, species.aspects.contains(aff) {
            ball *= 2.0
        }
        // HP-scaling spheres reward a nearly-fainted target.
        if sphere.hpScaling > 0 {
            let lowness = 1.0 - (hp / maxHP)
            ball *= 1.0 + sphere.hpScaling * lowness
        }

        var a = ((3 * maxHP - 2 * hp) * rate * ball) / (3 * maxHP)
        a *= target.status.catchMultiplier
        a *= 1.0 + 0.6 * max(0, min(1, throwQuality))

        return max(0, min(1, a / 255.0))
    }

    /// Chance this throw is a *critical capture* (single decisive shake).
    /// Scales with how much of the Dex you've caught — mastery pays.
    public static func criticalChance(dexCaught: Int, dexTotal: Int) -> Double {
        guard dexTotal > 0 else { return 0 }
        let completion = Double(dexCaught) / Double(dexTotal)
        return 0.02 + 0.10 * completion   // 2%...12%
    }

    /// Resolve a throw with Gen-4-style shake checks: four sub-checks each with
    /// probability p^(1/4); the number that pass = shakes shown; all four =
    /// capture. Critical captures make a single check at p^(1/2).
    public static func attempt(
        target: Daemon, sphere: Sphere, throwQuality: Double = 0,
        dexCaught: Int = 0, dexTotal: Int = 0, rng: inout SeededRandom
    ) -> Attempt {
        let p = probability(target: target, sphere: sphere, throwQuality: throwQuality)
        guard p < 1.0 else {
            return Attempt(probability: 1.0, shakes: 3, captured: true, critical: false)
        }

        let critRoll = rng.unit() < criticalChance(dexCaught: dexCaught, dexTotal: dexTotal)
        if critRoll {
            let captured = rng.unit() < pow(p, 0.5)
            return Attempt(probability: p, shakes: captured ? 1 : 0,
                           captured: captured, critical: true)
        }

        let shakeChance = pow(p, 0.25)
        var passed = 0
        for _ in 0..<4 {
            if rng.unit() < shakeChance { passed += 1 } else { break }
        }
        let captured = passed == 4
        return Attempt(probability: p, shakes: captured ? 3 : min(passed, 3),
                       captured: captured, critical: false)
    }
}
