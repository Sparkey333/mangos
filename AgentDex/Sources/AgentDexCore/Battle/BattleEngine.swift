import Foundation

/// Resolves combat. The SAME engine powers both the overworld "no screen switch"
/// fights and the optional classic turn-based mode — only presentation differs,
/// so balance stays identical (DESIGN §5.1).
public enum BattleEngine {

    public struct MoveOutcome: Equatable, Sendable {
        public var hit: Bool
        public var damage: Int
        public var effectiveness: Double
        public var isCrit: Bool
        public var appliedStatus: DaemonStatus?
        public var message: String
    }

    public static let critChance = 0.0625
    public static let critMultiplier = 1.5
    public static let stab = 1.5

    /// Raw damage (no application). Deterministic given `rng`.
    public static func damage(
        attacker: Daemon, defender: Daemon, move: Move, rng: inout SeededRandom
    ) -> (amount: Int, effectiveness: Double, isCrit: Bool) {
        guard move.category != .status, move.power > 0 else { return (0, 1.0, false) }

        // Physical uses ATK vs DEF; special uses SPA vs SPD.
        let a = attacker.stat(move.category == .physical ? .atk : .spa)
        let d = max(1, defender.stat(move.category == .physical ? .def : .spd))

        let level = attacker.level
        let baseFactor = Double((2 * level) / 5 + 2)
        var dmg = ((baseFactor * Double(move.power) * (Double(a) / Double(d))) / 50.0) + 2.0

        // STAB
        if attacker.species.aspects.contains(move.aspect) { dmg *= stab }
        // Type effectiveness
        let eff = TypeChart.multiplier(attacker: move.aspect, defenders: defender.species.aspects)
        dmg *= eff
        // Critical hit
        let crit = rng.unit() < critChance
        if crit { dmg *= critMultiplier }
        // Damage roll 0.85...1.0
        let roll = 0.85 + 0.15 * rng.unit()
        dmg *= roll

        return (max(1, Int(dmg)), eff, crit)
    }

    /// Resolve a move, mutating attacker/defender. Returns a describable outcome.
    @discardableResult
    public static func resolveMove(
        attacker: inout Daemon, defender: inout Daemon, move: Move, rng: inout SeededRandom
    ) -> MoveOutcome {
        // Accuracy check.
        if move.accuracy < 100, rng.int(in: 1...100) > move.accuracy {
            return MoveOutcome(hit: false, damage: 0, effectiveness: 1.0, isCrit: false,
                               appliedStatus: nil, message: "\(attacker.species.name)'s \(move.name) missed!")
        }

        if move.category == .status {
            return applyStatusMove(attacker: &attacker, defender: &defender, move: move, rng: &rng)
        }

        let d = damage(attacker: attacker, defender: defender, move: move, rng: &rng)
        defender.currentHP = max(0, defender.currentHP - d.amount)

        var status: DaemonStatus? = nil
        if move.effectChance > 0, rng.int(in: 1...100) <= move.effectChance {
            switch move.effect {
            case .stall: defender.status = .stalled; status = .stalled
            case .loop:  defender.status = .looped;  status = .looped
            default: break
            }
        }

        var msg = "\(attacker.species.name) used \(move.name)!"
        if d.isCrit { msg += " Critical hit!" }
        if d.effectiveness > 1.0 { msg += " It's super effective!" }
        else if d.effectiveness < 1.0 { msg += " It's not very effective…" }
        if defender.isFainted { msg += " \(defender.species.name) fainted!" }

        return MoveOutcome(hit: true, damage: d.amount, effectiveness: d.effectiveness,
                           isCrit: d.isCrit, appliedStatus: status, message: msg)
    }

    private static func applyStatusMove(
        attacker: inout Daemon, defender: inout Daemon, move: Move, rng: inout SeededRandom
    ) -> MoveOutcome {
        var status: DaemonStatus? = nil
        var msg = "\(attacker.species.name) used \(move.name)!"
        let applies = move.effectChance == 0 || rng.int(in: 1...100) <= move.effectChance
        if applies {
            switch move.effect {
            case .stall: defender.status = .stalled; status = .stalled; msg += " \(defender.species.name) is stalled!"
            case .loop:  defender.status = .looped;  status = .looped;  msg += " \(defender.species.name) is stuck in a loop!"
            case .heal:
                let healed = attacker.maxHP / 2
                attacker.currentHP = min(attacker.maxHP, attacker.currentHP + healed)
                msg += " It restored HP."
            case .raiseAtk, .lowerDef, .lowerSpe, .none:
                msg += " (Stat shift acknowledged — full stat stages land in M1.)"
            }
        }
        return MoveOutcome(hit: true, damage: 0, effectiveness: 1.0, isCrit: false,
                           appliedStatus: status, message: msg)
    }

    /// Who acts first in classic mode: higher priority, then higher Speed.
    public static func actsFirst(_ a: Daemon, moveA: Move, _ b: Daemon, moveB: Move) -> Bool {
        if moveA.priority != moveB.priority { return moveA.priority > moveB.priority }
        return a.stat(.spe) >= b.stat(.spe)
    }

    /// Simple AI: pick the move with the best expected damage (status moves get a
    /// small baseline so they're considered but not spammed).
    public static func chooseMove(for attacker: Daemon, against defender: Daemon) -> Move {
        let moves = attacker.species.moves.isEmpty ? [MovePool.basicStrike] : attacker.species.moves
        func score(_ m: Move) -> Double {
            if m.category == .status { return 15 }
            let eff = TypeChart.multiplier(attacker: m.aspect, defenders: defender.species.aspects)
            let st = attacker.species.aspects.contains(m.aspect) ? BattleEngine.stab : 1.0
            return Double(m.power) * eff * st * (Double(m.accuracy) / 100.0)
        }
        return moves.max { score($0) < score($1) } ?? MovePool.basicStrike
    }
}
