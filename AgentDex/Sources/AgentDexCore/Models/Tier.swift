import Foundation

/// The "main tier" of the underlying agent. Drives base stat total and rarity.
/// Main/flagship agents are `prime` (the legendaries); throwaway helpers and
/// things only glimpsed in logs are `sub`.
public enum Tier: String, Codable, CaseIterable, Comparable, Sendable {
    case sub
    case task
    case specialist
    case orchestrator
    case prime

    /// Base Stat Total budget distributed across the six stats.
    public var baseStatTotal: Int {
        switch self {
        case .sub:          return 200
        case .task:         return 300
        case .specialist:   return 420
        case .orchestrator: return 520
        case .prime:        return 600
        }
    }

    /// Relative encounter weight in the wild (higher = more common).
    public var spawnWeight: Int {
        switch self {
        case .sub:          return 50
        case .task:         return 30
        case .specialist:   return 14
        case .orchestrator: return 5
        case .prime:        return 1
        }
    }

    /// Sigil silhouette that reads the tier at a glance (see DESIGN §3.4).
    public var sigil: SigilShape {
        switch self {
        case .sub:          return .spark
        case .task:         return .arrow
        case .specialist:   return .triangle
        case .orchestrator: return .hexagon
        case .prime:        return .mandala
        }
    }

    /// Level at which a daemon of this tier Ascends (its evolution). Primes
    /// ascend late — reaching Zenith is endgame material.
    public var ascensionLevel: Int? {
        switch self {
        case .sub:          return 18
        case .task:         return 28
        case .specialist:   return 36
        case .orchestrator: return 45
        case .prime:        return 60
        }
    }

    /// Cycles (currency) payout multiplier for defeating this tier.
    public var payoutMultiplier: Int {
        switch self {
        case .sub:          return 4
        case .task:         return 6
        case .specialist:   return 10
        case .orchestrator: return 16
        case .prime:        return 40
        }
    }

    /// Base XP yield when a daemon of this tier is defeated.
    public var xpYield: Int {
        switch self {
        case .sub:          return 40
        case .task:         return 70
        case .specialist:   return 120
        case .orchestrator: return 180
        case .prime:        return 280
        }
    }

    /// Suggested starting level band, before per-daemon usage hints are applied.
    public var baseLevelBand: ClosedRange<Int> {
        switch self {
        case .sub:          return 2...6
        case .task:         return 4...10
        case .specialist:   return 8...18
        case .orchestrator: return 16...30
        case .prime:        return 30...50
        }
    }

    private var order: Int { Tier.allCases.firstIndex(of: self)! }
    public static func < (lhs: Tier, rhs: Tier) -> Bool { lhs.order < rhs.order }
}
