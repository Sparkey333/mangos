import Foundation

/// Dex record state per species.
public enum DexStatus: String, Codable, Sendable {
    case unknown    // never encountered
    case seen       // met in the wild (or glimpsed in logs)
    case caught
}

/// The persisted game state. Codable so the App and Widgets share one JSON file
/// (via an App Group container). Keep this small and stable.
public struct SaveState: Codable, Equatable, Sendable {
    public var player: PlayerProfile
    public var party: [Daemon]                 // up to 6, active first
    public var box: [Daemon]                    // overflow storage
    public var inventory: [String: Int]         // sphere id → count
    public var dex: [String: DexStatus]         // species id → status
    public var currentRegion: String

    public init(player: PlayerProfile, party: [Daemon] = [], box: [Daemon] = [],
                inventory: [String: Int] = [:], dex: [String: DexStatus] = [:],
                currentRegion: String = "Hub") {
        self.player = player; self.party = party; self.box = box
        self.inventory = inventory; self.dex = dex; self.currentRegion = currentRegion
    }

    public var activeDaemon: Daemon? { party.first { !$0.isFainted } ?? party.first }
    public var caughtCount: Int { dex.values.filter { $0 == .caught }.count }
    public var seenCount: Int { dex.values.filter { $0 != .unknown }.count }

    public mutating func markSeen(_ speciesID: String) {
        if (dex[speciesID] ?? .unknown) == .unknown { dex[speciesID] = .seen }
    }

    public mutating func capture(_ daemon: Daemon) {
        dex[daemon.species.id] = .caught
        if party.count < 6 { party.append(daemon) } else { box.append(daemon) }
    }

    public func sphereCount(_ sphere: Sphere) -> Int { inventory[sphere.id] ?? 0 }

    @discardableResult
    public mutating func consumeSphere(_ sphere: Sphere) -> Bool {
        let n = inventory[sphere.id] ?? 0
        guard n > 0 else { return false }
        inventory[sphere.id] = n - 1
        return true
    }

    /// A fresh game seeded from a player profile and the starter kit.
    public static func newGame(player: PlayerProfile) -> SaveState {
        var inv: [String: Int] = [:]
        for s in Sphere.starterKit { inv[s.id, default: 0] += 1 }
        return SaveState(player: player, inventory: inv)
    }
}
