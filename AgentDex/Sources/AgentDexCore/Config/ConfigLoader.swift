import Foundation

/// Loads `agents.json` / `player.json`. The App passes a bundle URL; tests and
/// the package use the bundled example resources.
public enum ConfigLoader {

    public struct AgentsFile: Codable, Sendable {
        public var agents: [AgentProfile]
        public init(agents: [AgentProfile]) { self.agents = agents }
    }

    public enum ConfigError: Error, CustomStringConvertible {
        case missingResource(String)
        case decodeFailed(String, underlying: Error)
        public var description: String {
            switch self {
            case .missingResource(let n): return "Config resource not found: \(n)"
            case .decodeFailed(let n, let e): return "Failed to decode \(n): \(e)"
            }
        }
    }

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        return d
    }()

    public static func loadAgents(from data: Data) throws -> [AgentProfile] {
        do { return try decoder.decode(AgentsFile.self, from: data).agents }
        catch { throw ConfigError.decodeFailed("agents.json", underlying: error) }
    }

    public static func loadPlayer(from data: Data) throws -> PlayerProfile {
        do { return try decoder.decode(PlayerProfile.self, from: data) }
        catch { throw ConfigError.decodeFailed("player.json", underlying: error) }
    }

    public static func loadAgents(at url: URL) throws -> [AgentProfile] {
        try loadAgents(from: try Data(contentsOf: url))
    }

    public static func loadPlayer(at url: URL) throws -> PlayerProfile {
        try loadPlayer(from: try Data(contentsOf: url))
    }

    /// Loads the example seed data bundled with `AgentDexCore` (handy for the
    /// prototype and for tests). Returns sensible fallbacks if absent.
    public static func loadBundledExamples() -> (agents: [AgentProfile], player: PlayerProfile) {
        let player: PlayerProfile = {
            guard let url = Bundle.module.url(forResource: "player.example", withExtension: "json"),
                  let p = try? loadPlayer(at: url) else { return .placeholder }
            return p
        }()
        let agents: [AgentProfile] = {
            guard let url = Bundle.module.url(forResource: "agents.example", withExtension: "json"),
                  let a = try? loadAgents(at: url) else { return SampleData.agents }
            return a
        }()
        return (agents, player)
    }
}

/// Built-in fallback roster so the engine has something to chew on even with no
/// JSON present (mirrors `Config/agents.example.json`).
public enum SampleData {
    public static let agents: [AgentProfile] = [
        AgentProfile(id: "explore", displayName: "Explore", tier: .specialist, role: "researcher", project: "mangos", origin: .used, encounters: 40, notes: "broad fan-out reader"),
        AgentProfile(id: "plan", displayName: "Plan", tier: .specialist, role: "architect", project: "mangos", origin: .used, encounters: 18),
        AgentProfile(id: "general", displayName: "General-Purpose", tier: .task, role: "general", project: "mangos", origin: .used, encounters: 60),
        AgentProfile(id: "code-reviewer", displayName: "Code Reviewer", tier: .specialist, role: "review security", project: "mangos", origin: .directlyCreated, encounters: 12),
        AgentProfile(id: "log-scout", displayName: "Log Scout", tier: .sub, role: "log parsing", project: "mangos", origin: .seenInLogs, encounters: 3),
        AgentProfile(id: "builder", displayName: "Builder", tier: .task, role: "coder implementer", project: "mangos", origin: .used, encounters: 25),
        AgentProfile(id: "prime-orchestra", displayName: "Maestro", tier: .prime, role: "orchestrator planner", project: "mangos", origin: .directlyCreated, encounters: 7, notes: "the flagship that runs the others"),
    ]
}
