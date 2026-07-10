import Foundation
import SpriteKit
import AgentDexCore
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Builds animated, procedural SpriteKit nodes for daemons from their
/// `SpriteRecipe`. Pure presentation: geometry + palette in, living node out.
/// No image assets required — everything is SKShapeNode-based so it stays
/// consistent with the generated identity (DESIGN: recipes, not sprites).
public enum SpriteNodeFactory {

    // MARK: - Daemon node

    /// A self-animating daemon: pulsing aura, sigil body with glow, orbiting
    /// segment dots, and an idle bob. `anomalous` hue-shifts the palette and
    /// adds glitchy white sparks.
    public static func daemonNode(recipe: SpriteRecipe, anomalous: Bool, size: CGFloat) -> SKNode {
        let container = SKNode()

        let intensity = CGFloat(max(0.0, min(1.0, recipe.auraIntensity)))
        var primary = color(hex: recipe.primaryColorHex)
        var secondary = color(hex: recipe.secondaryColorHex)
        if anomalous {
            primary = hueShifted(primary)
            secondary = hueShifted(secondary)
        }

        // Aura: soft pulsing disc behind everything.
        let aura = SKShapeNode(circleOfRadius: size * 0.55)
        aura.fillColor = primary.withAlphaComponent(0.15 + 0.3 * intensity)
        aura.strokeColor = SKColor.clear
        aura.zPosition = 0
        container.addChild(aura)
        let auraGrow = SKAction.scale(to: 1.12, duration: 1.4)
        auraGrow.timingMode = .easeInEaseOut
        let auraShrink = SKAction.scale(to: 0.94, duration: 1.4)
        auraShrink.timingMode = .easeInEaseOut
        aura.run(.repeatForever(.sequence([auraGrow, auraShrink])))

        // Orbit: `segments` dots slowly circling the body.
        let orbit = SKNode()
        orbit.zPosition = 1
        container.addChild(orbit)
        let dotCount = max(0, recipe.segments)
        for i in 0..<dotCount {
            let dot = SKShapeNode(circleOfRadius: size * 0.05)
            dot.fillColor = secondary
            dot.strokeColor = SKColor.clear
            let angle = CGFloat(i) / CGFloat(max(1, dotCount)) * 2 * .pi
            dot.position = CGPoint(x: cos(angle) * size * 0.45,
                                   y: sin(angle) * size * 0.45)
            orbit.addChild(dot)
        }
        orbit.run(.repeatForever(.rotate(byAngle: 2 * .pi, duration: 8)))

        // Body: the sigil silhouette.
        let body = SKShapeNode(path: bodyPath(for: recipe.sigil, size: size))
        body.fillColor = primary
        body.strokeColor = secondary
        body.lineWidth = 2
        body.glowWidth = 2 + 4 * intensity
        body.zPosition = 2
        if recipe.sigil == .arrow { body.zRotation = .pi / 4 }
        container.addChild(body)
        let bobUp = SKAction.moveBy(x: 0, y: 3, duration: 0.6)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = SKAction.moveBy(x: 0, y: -3, duration: 0.6)
        bobDown.timingMode = .easeInEaseOut
        body.run(.repeatForever(.sequence([bobUp, bobDown])))

        // Anomalous ("shiny") glitch sparks: staggered white blips.
        if anomalous {
            for i in 0..<3 {
                let spark = SKShapeNode(circleOfRadius: 2)
                spark.fillColor = SKColor.white
                spark.strokeColor = SKColor.clear
                spark.zPosition = 3
                spark.alpha = 0
                let angle = CGFloat(i) * (2 * .pi / 3) + .pi / 6
                spark.position = CGPoint(x: cos(angle) * size * 0.32,
                                         y: sin(angle) * size * 0.32)
                container.addChild(spark)
                spark.run(.sequence([
                    .wait(forDuration: Double(i) * 0.4),
                    .repeatForever(.sequence([
                        .fadeIn(withDuration: 0.35),
                        .fadeOut(withDuration: 0.35),
                        .wait(forDuration: 0.5)
                    ]))
                ]))
            }
        }

        return container
    }

    // MARK: - Colors

    /// Parses "#RRGGBB" (leading '#' optional) into an SKColor.
    /// The single hex→color definition for the App's scenes.
    static func color(hex: String) -> SKColor {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        var value: UInt64 = 0
        let scanner = Scanner(string: cleaned)
        guard scanner.scanHexInt64(&value) else { return SKColor.white }
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        return SKColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    /// Rotates the hue 180 degrees — the "anomalous" palette inversion.
    static func hueShifted(_ color: SKColor) -> SKColor {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        #if os(macOS)
        let rgb = color.usingColorSpace(.deviceRGB) ?? color
        rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        #else
        guard color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return color }
        #endif
        return SKColor(hue: fmod(h + 0.5, 1.0), saturation: s, brightness: b, alpha: a)
    }

    // MARK: - Paths

    private static func bodyPath(for sigil: SigilShape, size: CGFloat) -> CGPath {
        let radius = size * 0.3
        switch sigil {
        case .spark:
            return CGPath(ellipseIn: CGRect(x: -radius, y: -radius,
                                            width: radius * 2, height: radius * 2),
                          transform: nil)
        case .arrow:
            // Capsule; the caller rotates it so it reads as directional.
            let w = size * 0.6
            let h = size * 0.24
            return CGPath(roundedRect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h),
                          cornerWidth: h / 2, cornerHeight: h / 2, transform: nil)
        case .triangle, .hexagon, .mandala:
            return polygonPath(sides: max(3, sigil.symmetry), radius: radius)
        }
    }

    private static func polygonPath(sides: Int, radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<sides {
            let angle = CGFloat(i) / CGFloat(sides) * 2 * .pi + .pi / 2
            let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
