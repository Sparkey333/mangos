import Foundation

/// Elemental "soul type" of a Daemon, derived from the source agent's role.
/// See DESIGN §3.3 and the type chart in `TypeChart`.
public enum Aspect: String, Codable, CaseIterable, Sendable {
    case aether   // research / explore / search — knowledge & light
    case forge    // coding / building / implementing — molten metal
    case order    // planning / architecture / design — crystalline geometry
    case warden   // review / critique / security / testing — stone & shield
    case flux     // general-purpose / catch-all / routing — shape-shifter
    case cipher   // data / parsing / transforms / log-only — glitch static

    /// A short hex palette hint (primary, secondary) for procedural art.
    public var palette: (primary: String, secondary: String) {
        switch self {
        case .aether: return ("#7FD7FF", "#FFFFFF")
        case .forge:  return ("#FF6A3D", "#3A2018")
        case .order:  return ("#9B8CFF", "#E8E3FF")
        case .warden: return ("#8B9DA3", "#384650")
        case .flux:   return ("#C9A0FF", "#5BE3C0")
        case .cipher: return ("#43FF8E", "#0B1A12")
        }
    }

    /// Per-stat emphasis weights used when distributing the Base Stat Total.
    /// Order: HP, ATK, DEF, SPA, SPD, SPE.
    public var statWeights: StatVector {
        switch self {
        case .aether: return StatVector(hp: 0.9, atk: 0.7, def: 0.8, spa: 1.4, spd: 1.1, spe: 1.3)
        case .forge:  return StatVector(hp: 1.1, atk: 1.5, def: 1.2, spa: 0.7, spd: 0.8, spe: 0.9)
        case .order:  return StatVector(hp: 1.0, atk: 0.8, def: 1.3, spa: 1.1, spd: 1.3, spe: 0.7)
        case .warden: return StatVector(hp: 1.4, atk: 0.9, def: 1.5, spa: 0.7, spd: 1.2, spe: 0.6)
        case .flux:   return StatVector(hp: 1.0, atk: 1.0, def: 1.0, spa: 1.0, spd: 1.0, spe: 1.1)
        case .cipher: return StatVector(hp: 0.9, atk: 1.1, def: 0.8, spa: 1.3, spd: 0.8, spe: 1.4)
        }
    }

    /// Maps an agent role string (freeform) to an Aspect. Defaults to `.flux`.
    public static func from(role: String) -> Aspect {
        let r = role.lowercased()
        func has(_ keys: [String]) -> Bool { keys.contains { r.contains($0) } }

        if has(["research", "explore", "search", "read", "investigat", "scout"]) { return .aether }
        if has(["code", "build", "implement", "engineer", "dev", "write", "author", "refactor"]) { return .forge }
        if has(["plan", "architect", "design", "strateg", "orchestrat", "coordinat"]) { return .order }
        if has(["review", "critic", "security", "audit", "test", "qa", "guard", "verify"]) { return .warden }
        if has(["data", "pars", "transform", "extract", "log", "index", "embed", "vector"]) { return .cipher }
        return .flux
    }
}
