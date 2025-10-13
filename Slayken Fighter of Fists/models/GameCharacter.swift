import Foundation

/// Basisdaten für einen spielbaren Charakter.
struct GameCharacter: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let image: String

    // Beispielcharakter für Previews oder Fallbacks
    static let example = GameCharacter(
        id: "character_1",
        name: "Sly",
        image: "character1"
    )

    /// Optional: Zufälligen Dummy-Charakter erzeugen (z. B. für Summon-Demo)
    static func random() -> GameCharacter {
        let pool = [
            GameCharacter(id: "character_1", name: "Sly", image: "character1"),
        ]
        return pool.randomElement() ?? .example
    }
}

