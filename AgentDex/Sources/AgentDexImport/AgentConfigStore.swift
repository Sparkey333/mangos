import Foundation
import AgentDexCore

/// Where the user-editable `agents.json` / `player.json` live, shared between the
/// importer CLI (writes) and the app (reads). This lets you regenerate your
/// roster without rebuilding the app.
///
/// Default location:
///   macOS: ~/Library/Application Support/AgentDex/
///   iOS:   <app>/Documents/AgentDex/
public enum AgentConfigStore {
    public static let folderName = "AgentDex"

    public static var directory: URL {
        let base: URL
        #if os(macOS)
        base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        #else
        base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        #endif
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public static var agentsURL: URL { directory.appendingPathComponent("agents.json") }
    public static var playerURL: URL { directory.appendingPathComponent("player.json") }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    public static func writeAgents(_ agents: [AgentProfile], to url: URL? = nil) throws {
        let payload = ConfigLoader.AgentsFile(agents: agents)
        let data = try encoder.encode(payload)
        try data.write(to: url ?? agentsURL, options: .atomic)
    }

    public static func writePlayer(_ player: PlayerProfile, to url: URL? = nil) throws {
        let data = try encoder.encode(player)
        try data.write(to: url ?? playerURL, options: .atomic)
    }

    /// Read the user's agents.json if present, else nil (caller falls back to
    /// the bundled examples).
    public static func readAgents() -> [AgentProfile]? {
        guard FileManager.default.fileExists(atPath: agentsURL.path) else { return nil }
        return try? ConfigLoader.loadAgents(at: agentsURL)
    }

    public static func readPlayer() -> PlayerProfile? {
        guard FileManager.default.fileExists(atPath: playerURL.path) else { return nil }
        return try? ConfigLoader.loadPlayer(at: playerURL)
    }
}
