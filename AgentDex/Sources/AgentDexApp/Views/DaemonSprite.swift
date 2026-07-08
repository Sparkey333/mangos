import SwiftUI
import AgentDexCore

/// Procedural rendering of a `SpriteRecipe` — zero image assets required, so the
/// prototype runs out of the box. Later this can be swapped for hand-drawn art
/// keyed by the same recipe. The sigil shape + segments + palette + aura make
/// each generated daemon read distinctly.
public struct DaemonSprite: View {
    public let recipe: SpriteRecipe
    public var size: CGFloat = 96

    public init(recipe: SpriteRecipe, size: CGFloat = 96) {
        self.recipe = recipe; self.size = size
    }

    public var body: some View {
        ZStack {
            // Aura
            Circle()
                .fill(Color(hex: recipe.primaryColorHex).opacity(0.25 + 0.4 * recipe.auraIntensity))
                .blur(radius: size * 0.12)
                .frame(width: size, height: size)

            // Core sigil
            sigilShape
                .fill(
                    LinearGradient(
                        colors: [Color(hex: recipe.primaryColorHex), Color(hex: recipe.secondaryColorHex)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: size * 0.62, height: size * 0.62)
                .shadow(color: Color(hex: recipe.primaryColorHex).opacity(0.8), radius: size * 0.08)

            // Orbiting segments hint the symmetry / tier.
            ForEach(0..<max(1, recipe.segments), id: \.self) { i in
                Circle()
                    .fill(Color(hex: recipe.secondaryColorHex))
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(y: -size * 0.42)
                    .rotationEffect(.degrees(Double(i) / Double(max(1, recipe.segments)) * 360))
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Daemon sigil: \(recipe.sigil.rawValue), motif \(recipe.motif)")
    }

    @ViewBuilder private var sigilShape: some View {
        switch recipe.sigil {
        case .spark:    Circle()
        case .arrow:    Capsule()
        case .triangle: RegularPolygon(sides: 3)
        case .hexagon:  RegularPolygon(sides: 6)
        case .mandala:  RegularPolygon(sides: 12)
        }
    }
}

/// A simple regular polygon shape for the sigils.
struct RegularPolygon: Shape {
    let sides: Int
    func path(in rect: CGRect) -> Path {
        guard sides >= 3 else { return Path(ellipseIn: rect) }
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        for i in 0..<sides {
            let angle = (Double(i) / Double(sides)) * 2 * .pi - .pi / 2
            let pt = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}
