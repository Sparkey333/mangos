import SwiftUI
import AgentDexCore

/// Shows real pack art for a species when available, else the procedural
/// `DaemonSprite`. This is the single swap point: replace `DaemonSprite(recipe:)`
/// call sites with `ArtworkView(species:)` to opt a screen into real art without
/// ever risking a blank — the fallback always renders.
public struct ArtworkView: View {
    public let species: DaemonSpecies
    public var variant: ArtVariant
    public var size: CGFloat
    public var animating: Bool

    public init(species: DaemonSpecies, variant: ArtVariant = .base,
                size: CGFloat = 96, animating: Bool = false) {
        self.species = species
        // An anomalous individual with no bespoke anomalous art still reads as
        // anomalous via the procedural hue-shift fallback.
        self.variant = species.isAscended && variant == .base ? .ascended : variant
        self.size = size
        self.animating = animating
    }

    public var body: some View {
        if let image = ArtResolver.image(for: species.id, variant: variant) {
            Image(cross: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityLabel("\(species.name) artwork")
        } else {
            DaemonSprite(recipe: species.sprite,
                         size: size,
                         anomalous: variant == .anomalous,
                         animating: animating)
        }
    }
}
