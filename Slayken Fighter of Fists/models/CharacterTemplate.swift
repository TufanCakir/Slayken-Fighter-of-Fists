import Foundation

struct CharacterTemplate: Codable, Identifiable {
    let id: String
    let name: String
    let skillIDs: [String]
    let image: String
    let element: String
    let auraColor: String
    let gradient: GradientColors
    let particle: ParticleEffect
    let attack: Int
}

struct GradientColors: Codable {
    let top: String
    let bottom: String
}

struct ParticleEffect: Codable {
    let type: String
    let speed: Double
    let size: Double
}
