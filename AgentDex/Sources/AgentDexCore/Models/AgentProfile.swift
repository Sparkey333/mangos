import Foundation

/// How you came to know an agent — flavors rarity and "fog of war".
public enum Origin: String, Codable, Sendable {
    case directlyCreated = "directly_created"   // an agent you authored
    case used                                    // an agent you invoked
    case seenInLogs = "seen_in_logs"             // only glimpsed indirectly
}

/// The seed record for one agent/sub-agent. Edit `Config/agents.json` to add
/// these; each one deterministically becomes a `DaemonSpecies`.
public struct AgentProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: String            // stable identity → stable creature
    public var displayName: String
    public var tier: Tier
    public var role: String          // freeform; mapped to an Aspect
    public var project: String       // becomes the habitat/region
    public var origin: Origin
    public var encounters: Int       // usage count → rarity/level hints
    public var notes: String?

    public init(id: String, displayName: String, tier: Tier, role: String,
                project: String, origin: Origin = .used, encounters: Int = 1,
                notes: String? = nil) {
        self.id = id; self.displayName = displayName; self.tier = tier
        self.role = role; self.project = project; self.origin = origin
        self.encounters = encounters; self.notes = notes
    }
}
