import Foundation

/// Cyclic rock-paper-scissors type chart (DESIGN §5.3):
///   Aether > Cipher > Warden > Forge > Order > Flux > Aether
/// Each Aspect is super-effective (×1.5) against the next in the cycle and
/// resisted (×0.67) by the one before it. Flux is the neutral wildcard.
public enum TypeChart {
    /// The attacking cycle order.
    static let cycle: [Aspect] = [.aether, .cipher, .warden, .forge, .order, .flux]

    public static let superEffective = 1.5
    public static let resisted = 0.67
    public static let neutral = 1.0

    /// Effectiveness of `attacker` vs a single `defender` aspect.
    public static func multiplier(attacker: Aspect, defender: Aspect) -> Double {
        guard let ai = cycle.firstIndex(of: attacker),
              let di = cycle.firstIndex(of: defender) else { return neutral }
        let n = cycle.count
        if (ai + 1) % n == di { return superEffective } // attacker beats next
        if (di + 1) % n == ai { return resisted }       // defender beats attacker
        return neutral
    }

    /// Combined effectiveness vs a (possibly dual-aspect) defender.
    public static func multiplier(attacker: Aspect, defenders: [Aspect]) -> Double {
        defenders.reduce(1.0) { $0 * multiplier(attacker: attacker, defender: $1) }
    }
}
