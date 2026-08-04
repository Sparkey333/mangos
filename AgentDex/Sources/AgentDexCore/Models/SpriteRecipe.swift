import Foundation

/// A data description of how to draw a Daemon, so procedural art (and later
/// hand-drawn art) stays consistent with the generated identity. The App turns
/// this into shapes/SF Symbols/palettes; no image assets are required to run.
public struct SpriteRecipe: Codable, Equatable, Sendable {
    public var sigil: SigilShape
    public var primaryColorHex: String
    public var secondaryColorHex: String
    /// A decorative motif keyword (e.g. "orbiting-glyphs", "molten-core").
    public var motif: String
    /// Aura intensity 0...1, higher for higher tiers.
    public var auraIntensity: Double
    /// Symmetry/segment count for procedural assembly.
    public var segments: Int

    public init(sigil: SigilShape, primaryColorHex: String, secondaryColorHex: String,
                motif: String, auraIntensity: Double, segments: Int) {
        self.sigil = sigil
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.motif = motif
        self.auraIntensity = auraIntensity
        self.segments = segments
    }
}
