import Foundation
import SwiftUI
import AgentDexCore
import AgentDexImport
#if os(macOS)
import AppKit
public typealias CrossImage = NSImage
#else
import UIKit
public typealias CrossImage = UIImage
#endif

/// Resolves a species+variant to real artwork if a pack provides it, else nil so
/// the caller falls back to the procedural `DaemonSprite`. Search order:
///   1. user/generated packs in Application Support/AgentDex/art/
///   2. bundled art in the app's resources (art/…)
/// Results are cached in-memory. Missing art is normal — never an error.
public enum ArtResolver {
    /// Set false to force procedural rendering everywhere (debug / A-B).
    public static var enabled = true

    private static var cache: [String: CrossImage] = [:]
    private static var missing: Set<String> = []

    public static var artDirectory: URL {
        AgentConfigStore.directory.appendingPathComponent("art", isDirectory: true)
    }

    public static func image(for speciesID: String, variant: ArtVariant) -> CrossImage? {
        guard enabled else { return nil }
        let key = ArtDirector.key(for: speciesID, variant: variant)
        if let cached = cache[key] { return cached }
        if missing.contains(key) { return nil }

        for base in searchDirectories() {
            for ext in ["png", "jpg", "jpeg", "webp"] {
                let url = base.appendingPathComponent("\(key).\(ext)")
                if FileManager.default.fileExists(atPath: url.path),
                   let img = CrossImage(contentsOfFile: url.path) {
                    cache[key] = img
                    return img
                }
            }
        }
        missing.insert(key)
        return nil
    }

    private static func searchDirectories() -> [URL] {
        var dirs = [artDirectory]
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent("art", isDirectory: true) {
            dirs.append(bundled)
        }
        return dirs
    }

    /// Aggregate credit lines from every manifest.json found in the pack dirs.
    public static func creditLines() -> [String] {
        var lines: [String] = []
        for base in searchDirectories() {
            let manifestURL = base.appendingPathComponent("manifest.json")
            if let data = try? Data(contentsOf: manifestURL),
               let manifest = try? ArtManifest.decoder.decode(ArtManifest.self, from: data) {
                lines.append(contentsOf: manifest.creditLines)
            }
        }
        return Array(Set(lines)).sorted()
    }

    public static func clearCache() { cache.removeAll(); missing.removeAll() }
}

public extension Image {
    init(cross image: CrossImage) {
        #if os(macOS)
        self.init(nsImage: image)
        #else
        self.init(uiImage: image)
        #endif
    }
}
