import Foundation

/// Enemy move selection. Personality comes from the daemon's Nature: aggressive
/// natures overvalue damage; patient ones like status and setup.
public enum BattleAI {

    public static func chooseMove(
        for attacker: Daemon, against defender: Daemon, rng: inout SeededRandom
    ) -> Move {
        let moves = attacker.moves.isEmpty ? [MovePool.basicStrike] : attacker.moves

        func damageScore(_ m: Move) -> Double {
            guard m.category != .status, m.power > 0 else { return 0 }
            let eff = TypeChart.multiplier(attacker: m.aspect, defenders: defender.species.aspects)
            let stab = attacker.species.aspects.contains(m.aspect) ? BattleEngine.stab : 1.0
            return Double(m.power) * eff * stab * (Double(m.accuracy) / 100.0)
        }

        func statusScore(_ m: Move) -> Double {
            guard m.category == .status else { return 0 }
            var score = 30.0
            // Inflicting a status on a healthy, statusless target is valuable.
            if m.inflictedStatus != nil {
                score = defender.status == .none ? 55.0 : 0.0
            }
            // Healing matters when hurt, is useless when healthy.
            if m.effect == .healSelf {
                score = attacker.hpFraction < 0.45 ? 90.0 : 0.0
            }
            // Setup is best early, while healthy.
            if let stage = m.stageEffect, stage.onSelf {
                score = attacker.hpFraction > 0.7 && attacker.stages[stage.key] < 2 ? 45.0 : 10.0
            }
            return score
        }

        // Personality multipliers.
        let aggressive: Set<Nature> = [.reckless, .frantic, .chaotic, .gremlin]
        let patient: Set<Nature> = [.zen, .stoic, .diligent]
        let dmgWeight = aggressive.contains(attacker.species.nature) ? 1.35
                      : patient.contains(attacker.species.nature) ? 0.85 : 1.0
        let stWeight = patient.contains(attacker.species.nature) ? 1.4
                     : aggressive.contains(attacker.species.nature) ? 0.7 : 1.0

        var best = moves[0]
        var bestScore = -1.0
        for m in moves {
            // A pinch of noise so fights don't feel scripted.
            let noise = 0.9 + 0.2 * rng.unit()
            let score = (damageScore(m) * dmgWeight + statusScore(m) * stWeight) * noise
            if score > bestScore { bestScore = score; best = m }
        }
        return best
    }
}
