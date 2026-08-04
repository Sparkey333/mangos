import Foundation

/// The six combat stats. Pokémon-shaped so the mental model transfers.
public enum Stat: String, Codable, CaseIterable, Sendable {
    case hp, atk, def, spa, spd, spe
}

/// A vector of six values, used for base stats, IVs, and weights.
public struct StatVector: Codable, Equatable, Sendable {
    public var hp: Double
    public var atk: Double
    public var def: Double
    public var spa: Double
    public var spd: Double
    public var spe: Double

    public init(hp: Double, atk: Double, def: Double, spa: Double, spd: Double, spe: Double) {
        self.hp = hp; self.atk = atk; self.def = def
        self.spa = spa; self.spd = spd; self.spe = spe
    }

    public subscript(_ stat: Stat) -> Double {
        switch stat {
        case .hp: return hp
        case .atk: return atk
        case .def: return def
        case .spa: return spa
        case .spd: return spd
        case .spe: return spe
        }
    }

    public var sum: Double { hp + atk + def + spa + spd + spe }
}

/// Integer base stats for a species.
public struct BaseStats: Codable, Equatable, Sendable {
    public var hp, atk, def, spa, spd, spe: Int

    public init(hp: Int, atk: Int, def: Int, spa: Int, spd: Int, spe: Int) {
        self.hp = hp; self.atk = atk; self.def = def
        self.spa = spa; self.spd = spd; self.spe = spe
    }

    public subscript(_ stat: Stat) -> Int {
        switch stat {
        case .hp: return hp
        case .atk: return atk
        case .def: return def
        case .spa: return spa
        case .spd: return spd
        case .spe: return spe
        }
    }

    public var total: Int { hp + atk + def + spa + spd + spe }
}

/// Individual Values (0...31), the per-daemon genetic jitter.
public typealias IVs = BaseStats

/// Nature nudges one stat up and another down by ~10% (Pokémon-style flavor).
public enum Nature: String, Codable, CaseIterable, Sendable {
    case diligent, reckless, stoic, frantic, aloof, gremlin, zen, chaotic

    /// (boosted, lowered). `nil` means neutral.
    public var modifiers: (up: Stat, down: Stat)? {
        switch self {
        case .diligent: return (.def, .spe)
        case .reckless: return (.atk, .def)
        case .stoic:    return (.spd, .atk)
        case .frantic:  return (.spe, .def)
        case .aloof:    return (.spa, .hp)
        case .gremlin:  return (.spe, .spa)
        case .zen:      return (.hp, .atk)
        case .chaotic:  return (.atk, .spd)
        }
    }

    public func multiplier(for stat: Stat) -> Double {
        guard let m = modifiers else { return 1.0 }
        if stat == m.up { return 1.1 }
        if stat == m.down { return 0.9 }
        return 1.0
    }
}

public enum StatMath {
    /// HP uses the classic formula; other stats share theirs. Level 1...100.
    public static func value(
        for stat: Stat, base: Int, iv: Int, level: Int, nature: Nature
    ) -> Int {
        let lvl = max(1, min(100, level))
        if stat == .hp {
            return ((2 * base + iv) * lvl) / 100 + lvl + 10
        }
        let raw = ((2 * base + iv) * lvl) / 100 + 5
        return Int(Double(raw) * nature.multiplier(for: stat))
    }
}
