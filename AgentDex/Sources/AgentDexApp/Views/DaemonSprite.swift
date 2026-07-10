import SwiftUI
import AgentDexCore

/// Procedural rendering of a `SpriteRecipe` — zero image assets required, so the
/// prototype runs out of the box. Later this can be swapped for hand-drawn art
/// keyed by the same recipe. The sigil shape + segments + palette + aura make
/// each generated daemon read distinctly.
///
/// - `animating`: spins the orbiting segments and adds a gentle body bob.
/// - `anomalous`: the "shiny" treatment — hue-shifted 180° with pulsing sparkles.
/// - Ascended forms (motif prefixed "ascended-") get a golden ring cue.
public struct DaemonSprite: View {
    public let recipe: SpriteRecipe
    public var size: CGFloat = 96
    public var anomalous: Bool = false
    public var animating: Bool = false

    @State private var orbitPhase: Double = 0
    @State private var bobbing: Bool = false
    @State private var sparkleBright: Bool = false

    public init(recipe: SpriteRecipe, size: CGFloat = 96, anomalous: Bool = false, animating: Bool = false) {
        self.recipe = recipe
        self.size = size
        self.anomalous = anomalous
        self.animating = animating
    }

    private var primary: Color { Color(hex: recipe.primaryColorHex) }
    private var secondary: Color { Color(hex: recipe.secondaryColorHex) }
    private var isAscendedForm: Bool { recipe.motif.hasPrefix("ascended-") }
    private var segmentCount: Int { max(1, recipe.segments) }

    public var body: some View {
        ZStack {
            // Aura — brighter for higher tiers.
            Circle()
                .fill(primary.opacity(0.25 + 0.4 * recipe.auraIntensity))
                .blur(radius: size * 0.12)
                .frame(width: size, height: size)

            // Core sigil (the body) — bobs gently when animating.
            sigilShape
                .fill(
                    LinearGradient(
                        colors: [primary, secondary],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: size * 0.62, height: size * 0.62)
                .shadow(color: primary.opacity(0.8), radius: size * 0.08)
                .offset(y: bobbing ? -size * 0.035 : 0)

            // Orbiting segments hint the symmetry / tier; the whole ring spins
            // when animating.
            orbitDots
                .rotationEffect(.degrees(orbitPhase))

            // Ascended cue: a golden ring around the body.
            if isAscendedForm {
                Circle()
                    .stroke(Color(hex: "#FFD700"), lineWidth: 2)
                    .frame(width: size * 0.8, height: size * 0.8)
            }
        }
        .frame(width: size, height: size)
        .hueRotation(.degrees(anomalous ? 180 : 0))
        .overlay(anomalousSparkles)
        .onAppear(perform: startAnimations)
        .accessibilityLabel("Daemon sigil: \(recipe.sigil.rawValue), motif \(recipe.motif)\(anomalous ? ", anomalous" : "")")
    }

    // MARK: - Pieces

    private var orbitDots: some View {
        ZStack {
            ForEach(0..<segmentCount, id: \.self) { i in
                Circle()
                    .fill(secondary)
                    .frame(width: size * 0.08, height: size * 0.08)
                    .offset(y: -size * 0.42)
                    .rotationEffect(.degrees(Double(i) / Double(segmentCount) * 360))
            }
        }
    }

    /// Three tiny white sparkles that pulse — the anomalous ("shiny") tell.
    @ViewBuilder private var anomalousSparkles: some View {
        if anomalous {
            ZStack {
                sparkle.offset(x: -size * 0.28, y: -size * 0.30)
                sparkle.offset(x: size * 0.32, y: -size * 0.10)
                sparkle.offset(x: -size * 0.06, y: size * 0.34)
            }
            .opacity(sparkleBright ? 0.95 : 0.25)
        }
    }

    private var sparkle: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size * 0.05, height: size * 0.05)
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

    // MARK: - Animation

    private func startAnimations() {
        if animating {
            orbitPhase = 0
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                orbitPhase = 360
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                bobbing = true
            }
        }
        if anomalous {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                sparkleBright = true
            }
        }
    }
}

/// A simple regular polygon shape for the sigils. This is the module's single
/// definition — other views reference it from here.
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
