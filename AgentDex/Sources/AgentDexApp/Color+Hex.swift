import SwiftUI

public extension Color {
    /// Build a Color from a "#RRGGBB" string (the form used in `SpriteRecipe`).
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r, g, b: Double
        if s.count == 6 {
            r = Double((rgb >> 16) & 0xFF) / 255
            g = Double((rgb >> 8) & 0xFF) / 255
            b = Double(rgb & 0xFF) / 255
        } else {
            r = 0.6; g = 0.6; b = 0.6
        }
        self.init(red: r, green: g, blue: b)
    }
}
