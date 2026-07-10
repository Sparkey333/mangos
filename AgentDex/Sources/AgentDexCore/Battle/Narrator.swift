import Foundation

/// Turns battle events into human-readable log lines, with the house voice.
/// Both battle presentations share it, so the tone never drifts.
public enum Narrator {

    /// A log line for an event, or nil for events that are purely visual.
    public static func line(for event: BattleEvent) -> String? {
        switch event {
        case .battleStarted(let name, let level, let isTrainer, let trainerName):
            if isTrainer, let trainerName {
                return "\(trainerName) sends out \(name) (Lv\(level))!"
            }
            return "A wild \(name) (Lv\(level)) appeared!"
        case .daemonSent(let side, let name, let level):
            return side == .player ? "Go, \(name) (Lv\(level))!" : "\(name) (Lv\(level)) steps up!"
        case .moveUsed(_, let user, let moveName, _):
            return "\(user) used \(moveName)!"
        case .damage(_, let amount, _, _, let effectiveness, let crit):
            var bits: [String] = []
            if crit { bits.append("Critical hit!") }
            if effectiveness > 1.0 { bits.append("It's super effective!") }
            else if effectiveness < 1.0 { bits.append("It's not very effective…") }
            bits.append("(\(amount) damage)")
            return bits.joined(separator: " ")
        case .missed(_, let moveName):
            return "\(moveName) missed!"
        case .statusApplied(let side, let status):
            let who = side == .enemy ? "The wild daemon" : "Your daemon"
            return "\(who) is \(status.displayName)!"
        case .statusCleared(_, let status):
            return "\(status.displayName) wore off."
        case .statusTick(_, let status, let damage, _):
            return "\(status.displayName) saps \(damage) HP."
        case .skippedTurn(_, let reason):
            return "Turn skipped — \(reason)!"
        case .selfHit(_, let amount, _):
            return "It hit itself in the confusion! (\(amount) damage)"
        case .statChanged(_, let key, let delta, _):
            let dir = delta > 0 ? "rose" : "fell"
            return "\(key.rawValue.uppercased()) \(dir)!"
        case .statChangeFailed(_, let key):
            return "\(key.rawValue.uppercased()) can't go further!"
        case .abilityProc(_, let ability, let note):
            return "[\(ability.displayName)] \(note)."
        case .healed(_, let amount, _):
            return "Recovered \(amount) HP."
        case .fainted(_, let name):
            return "\(name) crashed!"
        case .xpGained(let amount, let to):
            return "\(to) gained \(amount) XP."
        case .leveledUp(let name, let level):
            return "\(name) reached Lv\(level)!"
        case .learnedMove(let name, let moveName):
            return "\(name) learned \(moveName)!"
        case .moveNotLearned(let name, let moveName):
            return "\(name) wanted to learn \(moveName), but its moveset is full."
        case .ascended(let oldName, let newName):
            return "✦ \(oldName) ascended into \(newName)! ✦"
        case .sphereThrown(let sphereName, let shakes, let captured, let critical):
            if captured {
                return critical ? "Critical capture! The \(sphereName) barely shook."
                                : "Gotcha! Bound after \(shakes) shakes."
            }
            return shakes == 0 ? "It broke out instantly. Rude."
                               : "So close — \(shakes) shake\(shakes == 1 ? "" : "s") — it broke free!"
        case .itemUsed(let itemName, let target):
            return "Used \(itemName) on \(target)."
        case .fleeAttempt(let success):
            return success ? "Got away clean." : "Couldn't escape!"
        case .payout(let amount):
            return "Earned \(amount)¢."
        case .battleEnded(let outcome):
            switch outcome {
            case .victory:  return "Victory!"
            case .defeat:   return "Your party wiped. Patch is expecting you."
            case .captured: return nil // the sphere line already landed
            case .fled:     return nil
            }
        case .message(let text):
            return text
        }
    }
}
