import SwiftUI
import simd

// MARK: - Color ⇄ HEX + SIMD Extensions
extension Color {
    /// Erstellt eine `Color` aus einem Hex-String wie `#RRGGBB` oder `#AARRGGBB`.
    /// Unterstützt auch Kurzformen wie `#FFF`.
    init(hex: String) {
        // 🔹 Nur alphanumerische Zeichen behalten (entfernt #, Leerzeichen etc.)
        var sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        // Unterstützt Kurzformen wie #FFF → #FFFFFF
        if sanitized.count == 3 {
            sanitized = sanitized.map { "\($0)\($0)" }.joined()
        }

        // Falls Länge unpassend, abbrechen
        guard [6, 8].contains(sanitized.count) else {
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
            return
        }

        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)

        let r, g, b, a: Double
        if sanitized.count == 6 {
            r = Double((value >> 16) & 0xFF) / 255.0
            g = Double((value >> 8) & 0xFF) / 255.0
            b = Double(value & 0xFF) / 255.0
            a = 1.0
        } else {
            a = Double((value >> 24) & 0xFF) / 255.0
            r = Double((value >> 16) & 0xFF) / 255.0
            g = Double((value >> 8) & 0xFF) / 255.0
            b = Double(value & 0xFF) / 255.0
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Gibt die Farbe als 32-Bit Float-Vektor zurück – ideal für Metal-Shader.
    var simd: SIMD4<Float> {
        #if canImport(UIKit)
        let color = UIColor(self)
        var r: CGFloat = 1, g: CGFloat = 1, b: CGFloat = 1, a: CGFloat = 1
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        var r: Double = 1, g: Double = 1, b: Double = 1, a: Double = 1
        NSColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        return SIMD4(Float(r), Float(g), Float(b), Float(a))
    }

    /// Erstellt eine `Color` aus einem Metal-kompatiblen `SIMD4<Float>`-Vektor.
    init(simd vector: SIMD4<Float>) {
        self.init(.sRGB,
                  red: Double(vector.x),
                  green: Double(vector.y),
                  blue: Double(vector.z),
                  opacity: Double(vector.w))
    }

    /// Konvertiert eine `Color` in einen hexadezimalen String (`#RRGGBB`).
    func toHexString() -> String {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        let nsColor = NSColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - GradientColors → SIMD Gradient
extension GradientColors {
    /// Gibt die oberen und unteren Farben als SIMD-Gradient zurück (für Metal-Shader nutzbar).
    var simdGradient: (top: SIMD4<Float>, bottom: SIMD4<Float>) {
        (Color(hex: top).simd, Color(hex: bottom).simd)
    }
}
