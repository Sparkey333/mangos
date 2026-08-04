import Foundation

/// A rendered-art variant of a species.
public enum ArtVariant: Equatable, Hashable, Sendable {
    case base
    case ascended
    case anomalous
    case alt(Int)

    public var tag: String {
        switch self {
        case .base:       return "base"
        case .ascended:   return "ascended"
        case .anomalous:  return "anomalous"
        case .alt(let n): return "alt\(n)"
        }
    }
}

/// A prompt bundle for an image generator (Higgsfield or any text-to-image API).
public struct ArtPrompt: Codable, Equatable, Sendable {
    public var key: String            // stable art key (species id + variant)
    public var speciesID: String
    public var variant: String
    public var positive: String
    public var negative: String
    public var seed: UInt64           // deterministic, from the key
    public var width: Int
    public var height: Int
    public var count: Int             // images to request (alt versions)

    public init(key: String, speciesID: String, variant: String, positive: String,
                negative: String, seed: UInt64, width: Int, height: Int, count: Int) {
        self.key = key; self.speciesID = speciesID; self.variant = variant
        self.positive = positive; self.negative = negative; self.seed = seed
        self.width = width; self.height = height; self.count = count
    }
}

/// Turns a deterministically-generated `DaemonSpecies` into a stable art key and
/// a text-to-image prompt. Pure and testable — same species → same prompt, so
/// generated art (and its alts) is reproducible and cacheable.
public enum ArtDirector {

    /// The stable art key used to name files and look them up at runtime.
    public static func key(for speciesID: String, variant: ArtVariant) -> String {
        "\(speciesID)__\(variant.tag)"
    }

    /// Build the generation prompt for a species + variant.
    public static func prompt(for species: DaemonSpecies, variant: ArtVariant = .base,
                              count: Int = 3) -> ArtPrompt {
        let k = key(for: species.id, variant: variant)
        let seed = stableHash("\(k)|art")

        let aspectStyle = style(for: species.primaryAspect)
        let secondary = species.secondaryAspect.map { "with \(style(for: $0)) undertones, " } ?? ""
        let scale = tierScale(species.tier)
        let sigil = sigilPhrase(species.sprite.sigil)
        let palette = "palette \(species.sprite.primaryColorHex) and \(species.sprite.secondaryColorHex)"

        var positive = """
        A \(species.primaryAspect.rawValue) spirit-creature daemon named \(species.name), \
        \(aspectStyle), \(secondary)built around a \(sigil), motif of \(species.sprite.motif), \
        \(palette), \(scale), \(species.nature.rawValue) demeanor, \
        centered character sprite, clean vector-illustration game art, soft rim light, \
        transparent background, no text
        """
        switch variant {
        case .base: break
        case .ascended:
            positive += ", ascended evolved form, larger and more ornate, radiant golden aura, higher detail"
        case .anomalous:
            positive += ", rare anomalous colorway, shifted hues, subtle shimmering sparkles"
        case .alt(let n):
            positive += ", alternate pose variation \(n)"
        }

        let negative = "text, watermark, signature, logo, blurry, lowres, extra limbs, " +
            "background scenery, photo, realistic human, frame, border, jpeg artifacts"

        return ArtPrompt(key: k, speciesID: species.id, variant: variant.tag,
                         positive: positive.replacingOccurrences(of: "\n", with: " "),
                         negative: negative, seed: seed,
                         width: 768, height: 768,
                         count: max(1, min(8, count)))
    }

    /// Prompts for a species: base + ascended (if it can ascend) + anomalous.
    public static func prompts(for species: DaemonSpecies) -> [ArtPrompt] {
        var out = [prompt(for: species, variant: .base)]
        if species.tier.ascensionLevel != nil && !species.isAscended {
            out.append(prompt(for: species, variant: .ascended))
        }
        out.append(prompt(for: species, variant: .anomalous, count: 1))
        return out
    }

    // MARK: - Style vocabulary

    static func style(for aspect: Aspect) -> String {
        switch aspect {
        case .aether: return "luminous knowledge-spirit of floating glyphs and starlight"
        case .forge:  return "molten metal construct with ember sparks and anvil plating"
        case .order:  return "crystalline geometric being of blueprints and lattices"
        case .warden: return "stone-and-rune guardian with a shield-like carapace"
        case .flux:   return "iridescent shape-shifter of shifting prismatic mercury"
        case .cipher: return "glitch-static entity of scanlines and redacted data"
        }
    }

    static func tierScale(_ tier: Tier) -> String {
        switch tier {
        case .sub:          return "tiny and simple"
        case .task:         return "small and nimble"
        case .specialist:   return "focused and refined"
        case .orchestrator: return "large and commanding"
        case .prime:        return "colossal legendary scale"
        }
    }

    static func sigilPhrase(_ sigil: SigilShape) -> String {
        switch sigil {
        case .spark:    return "single glowing point sigil"
        case .arrow:    return "sharp directional arrow sigil"
        case .triangle: return "triangular sigil"
        case .hexagon:  return "six-sided hexagonal sigil"
        case .mandala:  return "intricate nested mandala sigil"
        }
    }
}
