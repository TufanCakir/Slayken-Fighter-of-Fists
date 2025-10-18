import SwiftUI
import simd

extension String {
    /// Wandelt Hex-Farbe wie "#FF8000" oder "#00C8FF" in SIMD4<Float> um (für Metal)
    var simd: SIMD4<Float> {
        var hex = self
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        // Kurzform #FFF -> #FFFFFF
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }

        // Standardwert (weiß), falls fehlerhaft
        guard hex.count == 6,
              let intVal = Int(hex, radix: 16) else {
            return SIMD4<Float>(1, 1, 1, 1)
        }

        let r = Float((intVal >> 16) & 0xFF) / 255.0
        let g = Float((intVal >> 8) & 0xFF) / 255.0
        let b = Float(intVal & 0xFF) / 255.0
        return SIMD4<Float>(r, g, b, 1)
    }
}
