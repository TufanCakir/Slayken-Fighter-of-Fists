import Foundation

struct GameCharacter: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let image: String
    let element: String
    let auraColor: String
    let gradient: GradientColors
    let particle: ParticleEffect
    let skillIDs: [String]   // Skill-Referenzen
}

struct GradientColors: Codable, Hashable {
    let top: String
    let bottom: String
}

struct ParticleEffect: Codable, Hashable {
    let type: String
    let speed: Float
    let size: Float
}

// Beispielcharakter (Fallback)
extension GameCharacter {
    static let example = GameCharacter(
        id: "character_1",
        name: "Sly",
        image: "character1",
        element: "fire",
        auraColor: "#FF4500",
        gradient: GradientColors(top: "#FF8000", bottom: "#400000"),
        particle: ParticleEffect(type: "flame", speed: 1.2, size: 6.0),
        skillIDs: ["skill_fire_001", "skill_ice_001", "skill_void_001"],

    )
}
