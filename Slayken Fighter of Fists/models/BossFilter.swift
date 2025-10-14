import SwiftUI

struct Boss: Codable, Identifiable {
    let id: String
    let name: String
    let image: String
    let element: String
    let hp: Int
    let defense: Int
    let filter: BossFilter // 🔥 hier kommt der Farbfilter dazu
}


struct BossFilter: Codable {
    let r: Float
    let g: Float
    let b: Float
    let a: Float
    
    /// SwiftUI-Farbe für visuelle Effekte
    var color: Color {
        Color(
            red: Double(r),
            green: Double(g),
            blue: Double(b),
            opacity: Double(a)
        )
    }
    
    /// Metal-kompatibler SIMD-Wert
    var simd: SIMD4<Float> {
        SIMD4<Float>(r, g, b, a)
    }
}
