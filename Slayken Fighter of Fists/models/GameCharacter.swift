import Foundation

/// 🔹 Basisdaten für einen spielbaren Charakter.
struct GameCharacter: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let image: String
    let element: String
    let auraColor: String
    let gradient: GradientColors
    let particle: ParticleEffect
    let skills: [String]

    // MARK: - Beispielcharakter (Fallback)
    static let example = GameCharacter(
        id: "character_1",
        name: "Sly",
        image: "character1",
        element: "fire",
        auraColor: "#FF4500",
        gradient: GradientColors(top: "#FF8000", bottom: "#400000"),
        particle: ParticleEffect(type: "flame", speed: 1.2, size: 6.0),
        skills: ["Inferno Punch", "Blazing Kick"]
    )

    // MARK: - Zufälliger Dummy (z. B. für Summon-Demo)
    static func random() -> GameCharacter {
        let pool: [GameCharacter] = [
            .init(
                id: "character_1",
                name: "Sly",
                image: "character1",
                element: "fire",
                auraColor: "#FF4500",
                gradient: GradientColors(top: "#FF8000", bottom: "#400000"),
                particle: ParticleEffect(type: "flame", speed: 1.2, size: 6.0),
                skills: ["Inferno Punch", "Blazing Kick"]
            ),
            .init(
                id: "character_2",
                name: "Keyo",
                image: "character2",
                element: "ice",
                auraColor: "#00C8FF",
                gradient: GradientColors(top: "#A0E8FF", bottom: "#002040"),
                particle: ParticleEffect(type: "snow", speed: 0.6, size: 5.0),
                skills: ["Frost Smash", "Glacial Wall"]
            ),
            .init(
                id: "character_3",
                name: "Kenix",
                image: "character3",
                element: "void",
                auraColor: "#9A00FF",
                gradient: GradientColors(top: "#5A00A0", bottom: "#0C0018"),
                particle: ParticleEffect(type: "dark", speed: 0.8, size: 7.0),
                skills: ["Void Strike", "Dark Collapse"]
            )
        ]

        return pool.randomElement() ?? .example
    }
}

/// 🔹 Farbverlauf (z. B. für Hintergrund oder Aura)
struct GradientColors: Codable, Hashable {
    let top: String
    let bottom: String
}

/// 🔹 Partikelkonfiguration (für Shader-Effekte)
struct ParticleEffect: Codable, Hashable {
    let type: String
    let speed: Float
    let size: Float
}
