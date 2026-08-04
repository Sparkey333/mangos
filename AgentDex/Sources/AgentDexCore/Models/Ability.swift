import Foundation

/// Passive abilities — one per daemon, assigned deterministically at generation.
/// Each hook is implemented in `BattleEngine`/`BattleSession`.
public enum Ability: String, Codable, CaseIterable, Sendable {
    /// Survives a fatal hit at 1 HP, once per battle.
    case failsafe
    /// Deals +30% damage while below 1/3 max HP.
    case overclock
    /// Takes 25% less damage from super-effective hits.
    case hardened
    /// Restores 1/16 max HP at the end of each turn.
    case hotReload
    /// Immune to DEPRECATED and OVERHEATED.
    case cleanCode
    /// Critical-hit chance doubled.
    case cacheHit
    /// +1 Speed stage when sent into battle.
    case burstMode
    /// 30% chance to OVERHEAT attackers that make physical contact.
    case firewall
    /// 25% chance to cure its own status at the end of each turn.
    case garbageCollector
    /// A single hit can never remove more than 50% of its max HP.
    case loadBalancer

    public var displayName: String {
        switch self {
        case .failsafe:         return "Failsafe"
        case .overclock:        return "Overclock"
        case .hardened:         return "Hardened"
        case .hotReload:        return "Hot Reload"
        case .cleanCode:        return "Clean Code"
        case .cacheHit:         return "Cache Hit"
        case .burstMode:        return "Burst Mode"
        case .firewall:         return "Firewall"
        case .garbageCollector: return "Garbage Collector"
        case .loadBalancer:     return "Load Balancer"
        }
    }

    public var blurb: String {
        switch self {
        case .failsafe:         return "Refuses to crash: survives a fatal hit at 1 HP, once per battle."
        case .overclock:        return "Below a third of its HP, it stops being polite. +30% damage."
        case .hardened:         return "Reads the threat model. Super-effective hits deal 25% less."
        case .hotReload:        return "Patches itself live: recovers a little HP every turn."
        case .cleanCode:        return "No tech debt here. Cannot be DEPRECATED or OVERHEATED."
        case .cacheHit:         return "Already knows where to strike. Critical-hit chance doubled."
        case .burstMode:        return "Spins up instantly: +1 Speed on entry."
        case .firewall:         return "Touch it and get burned. 30% to OVERHEAT contact attackers."
        case .garbageCollector: return "Cleans up after itself. May shrug off status each turn."
        case .loadBalancer:     return "Distributes the pain. No single hit can take over half its HP."
        }
    }

    /// Candidate abilities per aspect, in a fixed order (the generator picks one
    /// deterministically). `prime` tier daemons may roll `loadBalancer` instead.
    public static func pool(for aspect: Aspect) -> [Ability] {
        switch aspect {
        case .aether: return [.cacheHit, .hotReload, .overclock]
        case .forge:  return [.overclock, .firewall, .failsafe]
        case .order:  return [.hardened, .garbageCollector, .burstMode]
        case .warden: return [.failsafe, .hardened, .firewall]
        case .flux:   return [.burstMode, .garbageCollector, .overclock]
        case .cipher: return [.cacheHit, .burstMode, .cleanCode]
        }
    }
}
