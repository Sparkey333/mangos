import Foundation
import AgentDexCore

/// Reads/writes the `SaveState` JSON in a shared App Group container so the app
/// and the widget see the same data. Falls back to the app's Documents dir if no
/// App Group is configured yet (so it still runs before you set up capabilities).
public enum SharedStore {
    /// Set this to your App Group id (also enable it in both targets' capabilities).
    public static let appGroupID = "group.agentdex"
    private static let fileName = "savestate.json"

    public static var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return url
        }
        // Fallback: app sandbox Documents (widget won't see it, but app works).
        return (try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                             appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
    }

    private static var saveURL: URL { containerURL.appendingPathComponent(fileName) }

    public static func load() -> SaveState? {
        guard let data = try? Data(contentsOf: saveURL) else { return nil }
        return try? JSONDecoder().decode(SaveState.self, from: data)
    }

    public static func save(_ state: SaveState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }
}
