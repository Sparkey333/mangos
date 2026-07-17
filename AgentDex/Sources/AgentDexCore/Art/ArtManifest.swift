import Foundation

/// One shippable artwork with its license provenance. No art ships without one.
public struct ArtEntry: Codable, Equatable, Sendable {
    public var key: String            // == ArtDirector.key(...)
    public var speciesID: String
    public var variant: String
    public var file: String           // relative filename within the pack
    public var license: String        // SPDX-ish: CC0-1.0, CC-BY-4.0, or our own id
    public var source: String         // URL or "higgsfield:{model}"
    public var attribution: String?   // required credit line for CC-BY etc.

    public init(key: String, speciesID: String, variant: String, file: String,
                license: String, source: String, attribution: String? = nil) {
        self.key = key; self.speciesID = speciesID; self.variant = variant
        self.file = file; self.license = license; self.source = source
        self.attribution = attribution
    }

    /// Entries requiring visible credit (surfaced in the in-app Credits screen).
    public var needsAttribution: Bool {
        attribution?.isEmpty == false && !license.hasPrefix("CC0")
    }
}

/// A folder of art with a license record. Bundled packs ship in the app;
/// generated/user packs live in Application Support/AgentDex/art/.
public struct ArtManifest: Codable, Equatable, Sendable {
    public var packID: String
    public var title: String
    public var defaultLicense: String
    public var entries: [ArtEntry]

    public init(packID: String, title: String, defaultLicense: String, entries: [ArtEntry] = []) {
        self.packID = packID; self.title = title
        self.defaultLicense = defaultLicense; self.entries = entries
    }

    public func entry(key: String) -> ArtEntry? { entries.first { $0.key == key } }

    /// Unique credit lines for a Credits screen.
    public var creditLines: [String] {
        var seen = Set<String>()
        var out: [String] = []
        for e in entries where e.needsAttribution {
            let line = "\(e.attribution!) — \(e.license)"
            if seen.insert(line).inserted { out.append(line) }
        }
        return out.sorted()
    }

    public static let decoder = JSONDecoder()
    public static var encoder: JSONEncoder {
        let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted, .sortedKeys]; return e
    }
}
