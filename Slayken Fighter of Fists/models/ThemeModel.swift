import SwiftUI

struct AppTheme: Codable, Identifiable {
    let id: String
    let name: String
    let gradient: [String]    // Hex-Farben
    let tint: String          // Akzentfarbe
}
