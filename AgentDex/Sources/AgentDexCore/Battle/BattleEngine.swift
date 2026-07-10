import Foundation

/// Pure combat math. `BattleSession` orchestrates turns; this file computes
/// single interactions. The SAME math powers overworld and classic battles.
public enum BattleEngine {

    public static let baseCritChance = 1.0 / 16.0
    public static let critMultiplier = 1.5
    public static let stab = 1.5

    /// The full result of computing one damaging hit (before application).
    public struct HitResult: Equatable, Sendable {
        public var amount: Int
        public var effectiveness: Double
        public var isCrit: Bool
        public var abilityNotes: [String]   // procs that changed the number
    }

    /// Compute damage for `move` from `attacker` into `defender`, including
    /// stages, status, abilities, STAB, effectiveness, crits and the damage roll.
    public static func computeHit(
        attacker: Daemon, defender: Daemon, move: Move, rng: inout SeededRandom
    ) -> HitResult {
        guard move.category != .status, move.power > 0 else {
            return HitResult(amount: 0, effectiveness: 1.0, isCrit: false, abilityNotes: [])
        }
        var notes: [String] = []

        let a = attacker.battleStat(move.category == .physical ? .atk : .spa)
        let d = max(1, defender.battleStat(move.category == .physical ? .def : .spd))

        let baseFactor = Double((2 * attacker.level) / 5 + 2)
        var dmg = ((baseFactor * Double(move.power) * (Double(a) / Double(d))) / 50.0) + 2.0

        // STAB
        if attacker.species.aspects.contains(move.aspect) { dmg *= stab }

        // Type effectiveness
        let eff = TypeChart.multiplier(attacker: move.aspect, defenders: defender.species.aspects)
        dmg *= eff

        // Hardened: super-effective hits reduced 25%.
        if eff > 1.0 && defender.species.ability == .hardened {
            dmg *= 0.75
            notes.append("Hardened blunted the blow")
        }

        // Overclock: +30% when the attacker is below 1/3 HP.
        if attacker.species.ability == .overclock && attacker.hpFraction < (1.0 / 3.0) {
            dmg *= 1.3
            notes.append("Overclock engaged")
        }

        // Critical hit.
        var critChance = baseCritChance
        if move.highCrit { critChance *= 4 }
        if attacker.species.ability == .cacheHit { critChance *= 2 }
        let isCrit = rng.unit() < min(0.5, critChance)
        if isCrit { dmg *= critMultiplier }

        // Damage roll 0.85...1.0
        dmg *= 0.85 + 0.15 * rng.unit()

        var amount = max(1, Int(dmg))

        // Load Balancer: cap any single hit at 50% of the defender's max HP.
        let cap = defender.maxHP / 2
        if defender.species.ability == .loadBalancer && amount > cap {
            amount = max(1, cap)
            notes.append("Load Balancer capped the hit")
        }

        return HitResult(amount: amount, effectiveness: eff, isCrit: isCrit, abilityNotes: notes)
    }

    /// Accuracy check including accuracy/evasion stages.
    public static func rollAccuracy(
        attacker: Daemon, defender: Daemon, move: Move, rng: inout SeededRandom
    ) -> Bool {
        guard move.accuracy < 100 || attacker.stages[.acc] < 0 || defender.stages[.eva] > 0 else {
            // Perfect-accuracy move with no stage penalties always hits.
            if move.accuracy >= 100 { return true }
            return rng.int(in: 1...100) <= move.accuracy
        }
        let net = attacker.stages[.acc] - defender.stages[.eva]
        let chance = Double(move.accuracy) / 100.0 * StatStages.accuracyMultiplier(netStage: net)
        return rng.unit() < min(1.0, max(0.05, chance))
    }

    /// Apply `amount` damage to `target`, honoring Failsafe. Returns the actual
    /// damage dealt and whether Failsafe proc'd.
    public static func applyDamage(_ amount: Int, to target: inout Daemon) -> (dealt: Int, failsafed: Bool) {
        var dealt = min(amount, target.currentHP)
        var failsafed = false
        if dealt >= target.currentHP && target.failsafeAvailable && target.currentHP > 1 {
            dealt = target.currentHP - 1
            target.failsafeAvailable = false
            failsafed = true
        }
        target.currentHP = max(0, target.currentHP - dealt)
        return (dealt, failsafed)
    }

    /// Who acts first: higher priority, then higher effective Speed.
    public static func playerActsFirst(
        player: Daemon, playerMove: Move, enemy: Daemon, enemyMove: Move, rng: inout SeededRandom
    ) -> Bool {
        if playerMove.priority != enemyMove.priority {
            return playerMove.priority > enemyMove.priority
        }
        let ps = player.battleStat(.spe)
        let es = enemy.battleStat(.spe)
        if ps != es { return ps > es }
        return rng.unit() < 0.5  // speed tie: coin flip
    }
}
