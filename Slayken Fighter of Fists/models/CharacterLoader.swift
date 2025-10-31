import Foundation

/// Lädt alle spielbaren Charaktere aus `characters.json`.
final class CharacterLoader {
    static func loadCharacters() -> [GameCharacter] {
        guard let url = Bundle.main.url(forResource: "characters", withExtension: "json") else {
            print("⚠️ characters.json nicht gefunden.")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let characters = try JSONDecoder().decode([GameCharacter].self, from: data)
            return characters
        } catch {
            print("❌ Fehler beim Laden der Charaktere: \(error)")
            return []
        }
    }
}
