import Foundation

/// A combat move. Same data drives overworld (cooldown) and classic (priority).
public struct Move: Codable, Equatable, Hashable, Identifiable, Sendable {
    public enum Category: String, Codable, Sendable { case physical, special, status }

    /// What the move does beyond damage. Stage effects are ±1.
    public enum Effect: String, Codable, Sendable {
        case none
        // Status conditions (applied to the target).
        case stall, loop, deprecate, ratelimit, overheat
        // Target stage drops.
        case lowerAtk, lowerDef, lowerSpe, lowerSpa, lowerAcc
        // Self stage raises.
        case raiseAtk, raiseDef, raiseSpa, raiseSpd, raiseSpe
        // Health.
        case drain      // heal 50% of damage dealt
        case recoil     // take 25% of damage dealt
        case healSelf   // restore 50% max HP
    }

    public var id: String
    public var name: String
    public var aspect: Aspect
    public var category: Category
    public var power: Int          // 0 for status moves
    public var accuracy: Int       // 1...100
    public var cooldown: Double    // seconds, overworld pacing
    public var priority: Int       // classic-mode tie-breaker (+ = first)
    public var effect: Effect
    public var effectChance: Int   // 0...100 (0 with a non-none effect = always)
    public var highCrit: Bool      // crit chance ×4
    public var unlockLevel: Int    // learned at this level

    public init(id: String, name: String, aspect: Aspect, category: Category,
                power: Int, accuracy: Int, cooldown: Double, priority: Int = 0,
                effect: Effect = .none, effectChance: Int = 0,
                highCrit: Bool = false, unlockLevel: Int = 1) {
        self.id = id; self.name = name; self.aspect = aspect
        self.category = category; self.power = power; self.accuracy = accuracy
        self.cooldown = cooldown; self.priority = priority
        self.effect = effect; self.effectChance = effectChance
        self.highCrit = highCrit; self.unlockLevel = unlockLevel
    }

    // Backwards-compatible decoding: older saves lack highCrit/unlockLevel.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        aspect = try c.decode(Aspect.self, forKey: .aspect)
        category = try c.decode(Category.self, forKey: .category)
        power = try c.decode(Int.self, forKey: .power)
        accuracy = try c.decode(Int.self, forKey: .accuracy)
        cooldown = try c.decode(Double.self, forKey: .cooldown)
        priority = try c.decodeIfPresent(Int.self, forKey: .priority) ?? 0
        effect = (try? c.decode(Effect.self, forKey: .effect)) ?? .none
        effectChance = try c.decodeIfPresent(Int.self, forKey: .effectChance) ?? 0
        highCrit = try c.decodeIfPresent(Bool.self, forKey: .highCrit) ?? false
        unlockLevel = try c.decodeIfPresent(Int.self, forKey: .unlockLevel) ?? 1
    }

    /// The status condition this move can inflict, if any.
    public var inflictedStatus: DaemonStatus? {
        switch effect {
        case .stall:     return .stalled
        case .loop:      return .looped
        case .deprecate: return .deprecated
        case .ratelimit: return .ratelimited
        case .overheat:  return .overheated
        default:         return nil
        }
    }

    /// (key, delta, appliesToSelf) for stage effects, if any.
    public var stageEffect: (key: StageKey, delta: Int, onSelf: Bool)? {
        switch effect {
        case .lowerAtk: return (.atk, -1, false)
        case .lowerDef: return (.def, -1, false)
        case .lowerSpe: return (.spe, -1, false)
        case .lowerSpa: return (.spa, -1, false)
        case .lowerAcc: return (.acc, -1, false)
        case .raiseAtk: return (.atk, +1, true)
        case .raiseDef: return (.def, +1, true)
        case .raiseSpa: return (.spa, +1, true)
        case .raiseSpd: return (.spd, +1, true)
        case .raiseSpe: return (.spe, +1, true)
        default:        return nil
        }
    }
}

/// Move pools per aspect. Each daemon knows the 4 strongest moves whose
/// `unlockLevel` it has reached, and learns new ones as it levels.
public enum MovePool {
    /// Universal fallback so every daemon can always act.
    public static let basicStrike = Move(
        id: "ping", name: "Ping", aspect: .flux, category: .physical,
        power: 30, accuracy: 100, cooldown: 0.6
    )

    /// Full learnset for an aspect, ascending by unlock level.
    public static func moves(for aspect: Aspect) -> [Move] {
        switch aspect {
        case .aether: return [
            Move(id: "aether_glimmer", name: "Glimmer", aspect: .aether, category: .special, power: 35, accuracy: 100, cooldown: 0.7, unlockLevel: 1),
            Move(id: "aether_insight", name: "Insight", aspect: .aether, category: .status, power: 0, accuracy: 100, cooldown: 1.2, effect: .raiseSpa, unlockLevel: 1),
            Move(id: "aether_skim", name: "Skim", aspect: .aether, category: .special, power: 50, accuracy: 100, cooldown: 0.9, highCrit: true, unlockLevel: 8),
            Move(id: "aether_beam", name: "Knowledge Beam", aspect: .aether, category: .special, power: 75, accuracy: 95, cooldown: 1.6, unlockLevel: 16),
            Move(id: "aether_citation", name: "Citation Storm", aspect: .aether, category: .special, power: 65, accuracy: 100, cooldown: 1.5, effect: .drain, unlockLevel: 22),
            Move(id: "aether_recall", name: "Total Recall", aspect: .aether, category: .status, power: 0, accuracy: 100, cooldown: 2.0, effect: .healSelf, unlockLevel: 26),
            Move(id: "aether_nova", name: "Insight Nova", aspect: .aether, category: .special, power: 110, accuracy: 90, cooldown: 2.4, unlockLevel: 32)
        ]
        case .forge: return [
            Move(id: "forge_spark", name: "Spark", aspect: .forge, category: .physical, power: 40, accuracy: 100, cooldown: 0.7, unlockLevel: 1),
            Move(id: "forge_temper", name: "Temper", aspect: .forge, category: .status, power: 0, accuracy: 100, cooldown: 1.2, effect: .raiseAtk, unlockLevel: 1),
            Move(id: "forge_rivet", name: "Rivet Rush", aspect: .forge, category: .physical, power: 45, accuracy: 100, cooldown: 0.7, priority: 1, unlockLevel: 5),
            Move(id: "forge_solder", name: "Solder", aspect: .forge, category: .physical, power: 50, accuracy: 100, cooldown: 1.0, effect: .overheat, effectChance: 30, unlockLevel: 9),
            Move(id: "forge_hotpatch", name: "Hot Patch", aspect: .forge, category: .physical, power: 55, accuracy: 100, cooldown: 1.3, effect: .drain, unlockLevel: 13),
            Move(id: "forge_hammer", name: "Hammer Pass", aspect: .forge, category: .physical, power: 80, accuracy: 95, cooldown: 1.7, unlockLevel: 18),
            Move(id: "forge_meltdown", name: "Meltdown", aspect: .forge, category: .physical, power: 120, accuracy: 85, cooldown: 2.6, effect: .recoil, unlockLevel: 32)
        ]
        case .order: return [
            Move(id: "order_shard", name: "Shard", aspect: .order, category: .special, power: 45, accuracy: 100, cooldown: 0.8, unlockLevel: 1),
            Move(id: "order_align", name: "Align", aspect: .order, category: .status, power: 0, accuracy: 100, cooldown: 1.0, effect: .lowerSpe, unlockLevel: 1),
            Move(id: "order_schema", name: "Schema", aspect: .order, category: .status, power: 0, accuracy: 100, cooldown: 1.1, effect: .raiseSpd, unlockLevel: 7),
            Move(id: "order_deadline", name: "Deadline", aspect: .order, category: .special, power: 60, accuracy: 100, cooldown: 1.4, effect: .ratelimit, effectChance: 30, unlockLevel: 12),
            Move(id: "order_lattice", name: "Lattice", aspect: .order, category: .special, power: 78, accuracy: 95, cooldown: 1.7, unlockLevel: 17),
            Move(id: "order_refactor", name: "Refactor", aspect: .order, category: .status, power: 0, accuracy: 100, cooldown: 2.0, effect: .healSelf, unlockLevel: 23),
            Move(id: "order_blueprint", name: "Grand Blueprint", aspect: .order, category: .special, power: 105, accuracy: 90, cooldown: 2.3, unlockLevel: 30)
        ]
        case .warden: return [
            Move(id: "warden_bash", name: "Rune Bash", aspect: .warden, category: .physical, power: 45, accuracy: 100, cooldown: 0.8, unlockLevel: 1),
            Move(id: "warden_ward", name: "Ward", aspect: .warden, category: .status, power: 0, accuracy: 100, cooldown: 1.0, effect: .lowerAtk, unlockLevel: 1),
            Move(id: "warden_bulwark", name: "Bulwark", aspect: .warden, category: .status, power: 0, accuracy: 100, cooldown: 1.1, effect: .raiseDef, unlockLevel: 6),
            Move(id: "warden_quarantine", name: "Quarantine", aspect: .warden, category: .physical, power: 55, accuracy: 100, cooldown: 1.3, effect: .deprecate, effectChance: 30, unlockLevel: 10),
            Move(id: "warden_lockdown", name: "Lockdown", aspect: .warden, category: .status, power: 0, accuracy: 85, cooldown: 1.8, effect: .stall, unlockLevel: 15),
            Move(id: "warden_audit", name: "Audit Strike", aspect: .warden, category: .physical, power: 70, accuracy: 95, cooldown: 1.6, effect: .lowerDef, effectChance: 30, unlockLevel: 19),
            Move(id: "warden_slam", name: "Bulwark Slam", aspect: .warden, category: .physical, power: 100, accuracy: 90, cooldown: 2.2, unlockLevel: 28)
        ]
        case .flux: return [
            Move(id: "flux_shift", name: "Shift", aspect: .flux, category: .physical, power: 40, accuracy: 100, cooldown: 0.7, unlockLevel: 1),
            Move(id: "flux_mirror", name: "Mirror", aspect: .flux, category: .status, power: 0, accuracy: 100, cooldown: 1.2, effect: .raiseSpa, unlockLevel: 4),
            Move(id: "flux_pivot", name: "Pivot", aspect: .flux, category: .physical, power: 50, accuracy: 100, cooldown: 0.8, priority: 1, unlockLevel: 6),
            Move(id: "flux_hotswap", name: "Hot Swap", aspect: .flux, category: .status, power: 0, accuracy: 100, cooldown: 1.1, effect: .raiseSpe, unlockLevel: 9),
            Move(id: "flux_improvise", name: "Improvise", aspect: .flux, category: .special, power: 60, accuracy: 100, cooldown: 1.3, unlockLevel: 12),
            Move(id: "flux_surge", name: "Iridescent Surge", aspect: .flux, category: .special, power: 80, accuracy: 92, cooldown: 1.8, unlockLevel: 18),
            Move(id: "flux_unwind", name: "Unwind", aspect: .flux, category: .special, power: 100, accuracy: 88, cooldown: 2.3, unlockLevel: 28)
        ]
        case .cipher: return [
            Move(id: "cipher_static", name: "Static", aspect: .cipher, category: .special, power: 38, accuracy: 100, cooldown: 0.7, unlockLevel: 1),
            Move(id: "cipher_loop", name: "Loop", aspect: .cipher, category: .status, power: 0, accuracy: 90, cooldown: 1.6, effect: .loop, unlockLevel: 6),
            Move(id: "cipher_obfuscate", name: "Obfuscate", aspect: .cipher, category: .status, power: 0, accuracy: 100, cooldown: 1.2, effect: .lowerAcc, unlockLevel: 8),
            Move(id: "cipher_scrape", name: "Scrape", aspect: .cipher, category: .special, power: 55, accuracy: 100, cooldown: 1.3, effect: .drain, unlockLevel: 11),
            Move(id: "cipher_glitch", name: "Glitch", aspect: .cipher, category: .special, power: 76, accuracy: 95, cooldown: 1.6, unlockLevel: 16),
            Move(id: "cipher_zeroday", name: "Zero Day", aspect: .cipher, category: .special, power: 70, accuracy: 100, cooldown: 1.7, highCrit: true, unlockLevel: 21),
            Move(id: "cipher_corrupt", name: "Corrupt", aspect: .cipher, category: .special, power: 112, accuracy: 88, cooldown: 2.5, effect: .deprecate, effectChance: 20, unlockLevel: 32)
        ]
        }
    }

    /// The (up to 4) strongest moves unlocked at `level`, weakest-first.
    public static func knownMoves(for aspect: Aspect, secondary: Aspect?, level: Int,
                                  rng: inout SeededRandom) -> [Move] {
        var unlocked = moves(for: aspect).filter { $0.unlockLevel <= level }
        if let secondary {
            // One signature move from the secondary aspect joins the pool.
            let secUnlocked = moves(for: secondary).filter { $0.unlockLevel <= level }
            if let pick = secUnlocked.isEmpty ? nil : Optional(rng.pick(secUnlocked)) {
                unlocked.append(pick)
            }
        }
        guard !unlocked.isEmpty else { return [basicStrike] }
        let strongest = unlocked.sorted { $0.unlockLevel < $1.unlockLevel }.suffix(4)
        return Array(strongest)
    }

    /// Moves newly unlocked when leveling from `oldLevel` (exclusive) to
    /// `newLevel` (inclusive), primary aspect only.
    public static func newlyUnlocked(for aspect: Aspect, from oldLevel: Int, to newLevel: Int) -> [Move] {
        moves(for: aspect).filter { $0.unlockLevel > oldLevel && $0.unlockLevel <= newLevel }
    }
}
