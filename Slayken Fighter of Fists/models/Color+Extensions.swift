import SwiftUI
import simd

// MARK: - HEX → Color + SIMD Support
extension Color {
    /// Erstellt eine `Color` aus einem Hex-String wie `#FF0000` oder `#80FF0000` (ARGB)
    init(hex: String) {
        // 🔹 Nur alphanumerische Zeichen behalten (#, Leerzeichen usw. entfernen)
        var sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        // Unterstützt Kurzformen wie #FFF → #FFFFFF
        if sanitized.count == 3 {
            sanitized = sanitized.map { "\($0)\($0)" }.joined()
        }

        var int: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch sanitized.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Fallback: Schwarz
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }

    /// Gibt die Farbe als `SIMD4<Float>` zurück – ideal für Metal-Shader
    var simd: SIMD4<Float> {
        let components = UIColor(self).cgColor.components ?? [1, 1, 1, 1]
        if components.count >= 4 {
            return SIMD4(Float(components[0]), Float(components[1]), Float(components[2]), Float(components[3]))
        } else {
            // Falls nur RGB ohne Alpha
            return SIMD4(Float(components[0]), Float(components[1]), Float(components[2]), 1)
        }
    }
}

// MARK: - SIMD4 → Color
extension Color {
    /// Erstellt eine `Color` aus einem Metal-kompatiblen SIMD4-Vektor
    init(simd vector: SIMD4<Float>) {
        self.init(
            .sRGB,
            red: Double(vector.x),
            green: Double(vector.y),
            blue: Double(vector.z),
            opacity: Double(vector.w)
        )
    }
}

// MARK: - GradientColors → SIMD Gradient
extension GradientColors {
    /// Wandelt Hex-Strings aus JSON in Metal-kompatible Farben um
    var simdGradient: (top: SIMD4<Float>, bottom: SIMD4<Float>) {
        (Color(hex: top).simd, Color(hex: bottom).simd)
    }
}
