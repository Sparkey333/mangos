import Foundation

/// XP curve and level math. Cubic ("medium-fast") curve: total XP to be level n
/// is n³. All pure functions, fully deterministic.
public enum Experience {
    public static let maxLevel = 100

    /// Total XP required to *be* the given level.
    public static func totalXP(forLevel level: Int) -> Int {
        let l = max(1, min(maxLevel, level))
        return l * l * l
    }

    /// The level a daemon with `xp` total XP has reached.
    public static func level(forXP xp: Int) -> Int {
        guard xp > 0 else { return 1 }
        var level = Int(Double(xp).squareRoot().squareRoot())  // rough start
        level = max(1, level)
        while level < maxLevel && totalXP(forLevel: level + 1) <= xp { level += 1 }
        while level > 1 && totalXP(forLevel: level) > xp { level -= 1 }
        return level
    }

    /// XP still needed to reach the next level (0 at max level).
    public static func xpToNextLevel(currentXP: Int) -> Int {
        let lvl = level(forXP: currentXP)
        guard lvl < maxLevel else { return 0 }
        return totalXP(forLevel: lvl + 1) - currentXP
    }

    /// Progress fraction through the current level, 0..<1 (1 at max level).
    public static func levelProgress(currentXP: Int) -> Double {
        let lvl = level(forXP: currentXP)
        guard lvl < maxLevel else { return 1.0 }
        let floor = totalXP(forLevel: lvl)
        let ceil = totalXP(forLevel: lvl + 1)
        return Double(currentXP - floor) / Double(max(1, ceil - floor))
    }

    /// XP granted for defeating `defeated`, to a winner at `winnerLevel`.
    /// Scales with the loser's level and tier; trainer battles pay 1.5×.
    public static func gain(defeating defeated: Daemon, winnerLevel: Int, isTrainer: Bool) -> Int {
        let base = defeated.species.tier.xpYield
        var xp = Double(base * defeated.level) / 5.0
        if isTrainer { xp *= 1.5 }
        // Mild rubber-banding: beating something above your level pays extra.
        if defeated.level > winnerLevel { xp *= 1.2 }
        return max(1, Int(xp))
    }
}
