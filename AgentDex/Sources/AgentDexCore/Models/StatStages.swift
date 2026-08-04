import Foundation

/// In-battle stat stage keys. Separate from `Stat` because accuracy/evasion are
/// stage-only (they have no base stat).
public enum StageKey: String, Codable, CaseIterable, Sendable {
    case atk, def, spa, spd, spe, acc, eva
}

/// Pokémon-style stat stages, -6...+6 per key. Volatile: reset when a battle
/// starts, never persisted.
public struct StatStages: Equatable, Sendable {
    private var values: [StageKey: Int] = [:]

    public init() {}

    public subscript(_ key: StageKey) -> Int {
        get { values[key] ?? 0 }
        set { values[key] = max(-6, min(6, newValue)) }
    }

    /// Apply a delta. Returns the new stage, or nil if already capped (no change).
    @discardableResult
    public mutating func apply(_ delta: Int, to key: StageKey) -> Int? {
        let old = self[key]
        let new = max(-6, min(6, old + delta))
        guard new != old else { return nil }
        self[key] = new
        return new
    }

    public mutating func reset() { values = [:] }

    /// Multiplier for combat stats (atk/def/spa/spd/spe): (2+s)/2 up, 2/(2-s) down.
    public func multiplier(_ key: StageKey) -> Double {
        let s = self[key]
        if s >= 0 { return Double(2 + s) / 2.0 }
        return 2.0 / Double(2 - s)
    }

    /// Accuracy multiplier for a net stage (attacker acc − defender eva),
    /// clamped to ±6: (3+s)/3 up, 3/(3-s) down.
    public static func accuracyMultiplier(netStage: Int) -> Double {
        let s = max(-6, min(6, netStage))
        if s >= 0 { return Double(3 + s) / 3.0 }
        return 3.0 / Double(3 - s)
    }

    public var isNeutral: Bool { values.values.allSatisfy { $0 == 0 } }
}
