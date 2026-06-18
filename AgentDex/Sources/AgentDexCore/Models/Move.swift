import Foundation

/// A combat move. Same data drives overworld (cooldown) and classic (priority).
public struct Move: Codable, Equatable, Identifiable, Sendable {
    public enum Category: String, Codable, Sendable { case physical, special, status }
    public enum Effect: String, Codable, Sendable {
        case none
        case stall      // "Stalled" status — helps catch rate
        case loop       // "Looped" status — skips a turn sometimes; helps catch
        case lowerDef
        case lowerSpe
        case raiseAtk
        case heal
    }

    public var id: String
    public var name: String
    public var aspect: Aspect
    public var category: Category
    public var power: Int          // 0 for status moves
    public var accuracy: Int       // 0...100
    public var cooldown: Double    // seconds, overworld pacing
    public var priority: Int       // classic mode tie-breaker
    public var effect: Effect
    public var effectChance: Int   // 0...100

    public init(id: String, name: String, aspect: Aspect, category: Category,
                power: Int, accuracy: Int, cooldown: Double, priority: Int = 0,
                effect: Effect = .none, effectChance: Int = 0) {
        self.id = id; self.name = name; self.aspect = aspect
        self.category = category; self.power = power; self.accuracy = accuracy
        self.cooldown = cooldown; self.priority = priority
        self.effect = effect; self.effectChance = effectChance
    }
}

/// The move pool a Daemon draws its (up to 4) known moves from, keyed by Aspect.
public enum MovePool {
    /// A small universal "struggle"-style move so every daemon can always act.
    public static let basicStrike = Move(
        id: "ping", name: "Ping", aspect: .flux, category: .physical,
        power: 30, accuracy: 100, cooldown: 0.6
    )

    /// Returns the candidate moves for an aspect (ordered, strongest last).
    public static func moves(for aspect: Aspect) -> [Move] {
        switch aspect {
        case .aether: return [
            Move(id: "aether_glimmer", name: "Glimmer", aspect: .aether, category: .special, power: 35, accuracy: 100, cooldown: 0.7),
            Move(id: "aether_insight", name: "Insight", aspect: .aether, category: .status, power: 0, accuracy: 100, cooldown: 1.2, effect: .raiseAtk, effectChance: 100),
            Move(id: "aether_beam", name: "Knowledge Beam", aspect: .aether, category: .special, power: 75, accuracy: 95, cooldown: 1.6),
            Move(id: "aether_nova", name: "Insight Nova", aspect: .aether, category: .special, power: 110, accuracy: 90, cooldown: 2.4)
        ]
        case .forge: return [
            Move(id: "forge_spark", name: "Spark", aspect: .forge, category: .physical, power: 40, accuracy: 100, cooldown: 0.7),
            Move(id: "forge_temper", name: "Temper", aspect: .forge, category: .status, power: 0, accuracy: 100, cooldown: 1.2, effect: .raiseAtk, effectChance: 100),
            Move(id: "forge_hammer", name: "Hammer Pass", aspect: .forge, category: .physical, power: 80, accuracy: 95, cooldown: 1.7),
            Move(id: "forge_meltdown", name: "Meltdown", aspect: .forge, category: .physical, power: 120, accuracy: 85, cooldown: 2.6)
        ]
        case .order: return [
            Move(id: "order_align", name: "Align", aspect: .order, category: .status, power: 0, accuracy: 100, cooldown: 1.0, effect: .lowerSpe, effectChance: 100),
            Move(id: "order_shard", name: "Shard", aspect: .order, category: .special, power: 45, accuracy: 100, cooldown: 0.8),
            Move(id: "order_lattice", name: "Lattice", aspect: .order, category: .special, power: 78, accuracy: 95, cooldown: 1.7),
            Move(id: "order_blueprint", name: "Grand Blueprint", aspect: .order, category: .special, power: 105, accuracy: 90, cooldown: 2.3)
        ]
        case .warden: return [
            Move(id: "warden_ward", name: "Ward", aspect: .warden, category: .status, power: 0, accuracy: 100, cooldown: 1.0, effect: .lowerDef, effectChance: 100),
            Move(id: "warden_bash", name: "Rune Bash", aspect: .warden, category: .physical, power: 45, accuracy: 100, cooldown: 0.8),
            Move(id: "warden_lockdown", name: "Lockdown", aspect: .warden, category: .status, power: 0, accuracy: 90, cooldown: 1.8, effect: .stall, effectChance: 100),
            Move(id: "warden_bulwark", name: "Bulwark Slam", aspect: .warden, category: .physical, power: 100, accuracy: 90, cooldown: 2.2)
        ]
        case .flux: return [
            Move(id: "flux_shift", name: "Shift", aspect: .flux, category: .physical, power: 40, accuracy: 100, cooldown: 0.7),
            Move(id: "flux_mirror", name: "Mirror", aspect: .flux, category: .status, power: 0, accuracy: 100, cooldown: 1.2, effect: .raiseAtk, effectChance: 100),
            Move(id: "flux_surge", name: "Iridescent Surge", aspect: .flux, category: .special, power: 80, accuracy: 92, cooldown: 1.8),
            Move(id: "flux_unwind", name: "Unwind", aspect: .flux, category: .special, power: 100, accuracy: 88, cooldown: 2.3)
        ]
        case .cipher: return [
            Move(id: "cipher_static", name: "Static", aspect: .cipher, category: .special, power: 38, accuracy: 100, cooldown: 0.7),
            Move(id: "cipher_loop", name: "Loop", aspect: .cipher, category: .status, power: 0, accuracy: 90, cooldown: 1.6, effect: .loop, effectChance: 100),
            Move(id: "cipher_glitch", name: "Glitch", aspect: .cipher, category: .special, power: 76, accuracy: 95, cooldown: 1.6),
            Move(id: "cipher_corrupt", name: "Corrupt", aspect: .cipher, category: .special, power: 112, accuracy: 88, cooldown: 2.5)
        ]
        }
    }
}
