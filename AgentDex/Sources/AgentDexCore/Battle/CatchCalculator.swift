import Foundation

/// The headline feature: fighting + sphere throwing. Computes capture chance and
/// the classic "shake" tension beat. See DESIGN §5.4.
public enum CatchCalculator {

    public struct Attempt: Equatable, Sendable {
        public var probability: Double   // 0...1, the true capture chance
        public var shakes: Int           // 0...3; 3 + capture == success drama
        public var captured: Bool
    }

    /// The 0...1 capture probability, before rolling. Pure & testable.
    /// - throwQuality: 0...1 skill bonus from the resonance-ring timing mini-game.
    public static func probability(
        target: Daemon, sphere: Sphere, throwQuality: Double = 0
    ) -> Double {
        let species = target.species

        // Primes need a Prime Sigil to be realistically bindable.
        if species.tier == .prime && !sphere.canBindPrime {
            return min(0.02, baseProbability(target: target, sphere: sphere, throwQuality: throwQuality))
        }
        return baseProbability(target: target, sphere: sphere, throwQuality: throwQuality)
    }

    private static func baseProbability(
        target: Daemon, sphere: Sphere, throwQuality: Double
    ) -> Double {
        let species = target.species
        let maxHP = Double(max(1, target.maxHP))
        let hp = Double(max(0, target.currentHP))

        // Gen-style core: lower HP → much higher rate.
        // a = ((3*max - 2*cur) * rate * ball) / (3*max)
        let rate = Double(species.catchBaseRate)
        var ball = sphere.baseMultiplier

        // Aspect affinity bonus.
        if let aff = sphere.affinityAspect, species.aspects.contains(aff) {
            ball *= 2.0
        }
        // HP-scaling spheres reward a nearly-fainted target.
        if sphere.hpScaling > 0 {
            let lowness = 1.0 - (hp / maxHP)           // 0 full, 1 empty
            ball *= 1.0 + sphere.hpScaling * lowness
        }

        var a = ((3 * maxHP - 2 * hp) * rate * ball) / (3 * maxHP)

        // Status bonus.
        switch target.status {
        case .stalled: a *= 1.5
        case .looped:  a *= 2.0
        case .none:    break
        }

        // Throw-skill bonus from the ring mini-game (up to +60%).
        a *= 1.0 + 0.6 * max(0, min(1, throwQuality))

        // Normalize against the 255 scale into a probability.
        let p = a / 255.0
        return max(0, min(1, p))
    }

    /// Expected number of shakes (0...3) for given probability — pure UI drama.
    public static func shakeCount(for probability: Double) -> Int {
        // The closer to a sure thing, the more shakes survive before catch/break.
        switch probability {
        case 1.0...:        return 3
        case 0.7..<1.0:     return 3
        case 0.45..<0.7:    return 2
        case 0.2..<0.45:    return 1
        default:            return 0
        }
    }

    /// Resolve a throw deterministically against `rng`.
    public static func attempt(
        target: Daemon, sphere: Sphere, throwQuality: Double = 0, rng: inout SeededRandom
    ) -> Attempt {
        let p = probability(target: target, sphere: sphere, throwQuality: throwQuality)
        let captured = rng.unit() < p
        // On capture, always show the full dramatic 3 shakes; on failure, show how
        // close it was.
        let shakes = captured ? 3 : min(shakeCount(for: p), 2)
        return Attempt(probability: p, shakes: shakes, captured: captured)
    }
}
