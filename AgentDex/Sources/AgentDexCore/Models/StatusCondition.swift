import Foundation

/// Non-volatile status conditions — the agent-flavored takes on the classics.
/// They persist after battle (heal at the Hub or with items).
public enum DaemonStatus: String, Codable, CaseIterable, Sendable {
    case none
    /// Sleep-like: cannot act for 1–3 turns. Big catch bonus.
    case stalled
    /// Confusion-like: may skip its turn or hit itself. Wears off.
    case looped
    /// Poison-like: loses 1/8 max HP each turn ("technical debt accrues").
    case deprecated
    /// Paralysis-like: 25% chance to skip, Speed halved.
    case ratelimited
    /// Burn-like: loses 1/16 max HP each turn, physical Attack cut to 2/3.
    case overheated

    public var displayName: String {
        switch self {
        case .none:        return ""
        case .stalled:     return "STALLED"
        case .looped:      return "LOOPED"
        case .deprecated:  return "DEPRECATED"
        case .ratelimited: return "RATE-LIMITED"
        case .overheated:  return "OVERHEATED"
        }
    }

    /// Hex color hint for badges/particles in the UI.
    public var colorHex: String {
        switch self {
        case .none:        return "#FFFFFF"
        case .stalled:     return "#8FA3B8"
        case .looped:      return "#C9A0FF"
        case .deprecated:  return "#9BE04A"
        case .ratelimited: return "#FFD34D"
        case .overheated:  return "#FF6A3D"
        }
    }

    /// Catch-rate multiplier while afflicted.
    public var catchMultiplier: Double {
        switch self {
        case .none:                                            return 1.0
        case .stalled:                                         return 2.5
        case .looped, .deprecated, .ratelimited, .overheated:  return 1.5
        }
    }

    /// End-of-turn chip damage as a fraction of max HP (0 = none).
    public var chipFraction: Double {
        switch self {
        case .deprecated: return 1.0 / 8.0
        case .overheated: return 1.0 / 16.0
        default:          return 0
        }
    }

    /// Speed multiplier while afflicted.
    public var speedMultiplier: Double { self == .ratelimited ? 0.5 : 1.0 }

    /// Physical-attack multiplier while afflicted.
    public var attackMultiplier: Double { self == .overheated ? 2.0 / 3.0 : 1.0 }

    /// True if the status counts down `statusTurns` and clears at zero.
    public var isTimed: Bool { self == .stalled || self == .looped }

    /// Initial duration in turns (rolled when applied), for timed statuses.
    public func rollDuration(rng: inout SeededRandom) -> Int {
        switch self {
        case .stalled: return rng.int(in: 1...3)
        case .looped:  return rng.int(in: 2...4)
        default:       return 0
        }
    }
}
