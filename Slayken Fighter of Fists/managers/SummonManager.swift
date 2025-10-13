    import SwiftUI
    import Combine



/// Verwaltet alle beschworenen Charaktere – inklusive Speicherung & Summon-Logik.
@MainActor
final class SummonManager: ObservableObject {
    static let shared = SummonManager()

    // MARK: - Published Properties
    @Published private(set) var ownedCharacters: [GameCharacter] = []

    // MARK: - Private
    private let saveKey = "ownedCharacters"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init
    private init() {
        load()
    }

    // MARK: - Public Summon Logic

    /// Führt eine Beschwörung aus.
    /// - Parameters:
    ///   - allCharacters: Liste aller möglichen Charaktere (z. B. aus availableCharacters.json)
    ///   - count: Anzahl der zu beschwörenden Charaktere (1 oder 10)
    /// - Returns: Eine Liste der neu gezogenen Charaktere.
    @discardableResult
    func summon(from allCharacters: [GameCharacter], count: Int) -> [GameCharacter] {
        guard !allCharacters.isEmpty else {
            print("⚠️ summon(): No characters available to summon.")
            return []
        }

        // Zufällige Charaktere ziehen
        let summoned = (0..<count).compactMap { _ in allCharacters.randomElement() }

        // 🔁 Keine Duplikate hinzufügen (optional)
        for char in summoned where !ownedCharacters.contains(char) {
            ownedCharacters.append(char)
        }

        save()

        #if DEBUG
        print("✨ Summoned \(summoned.count) characters → Total owned: \(ownedCharacters.count)")
        #endif

        return summoned
    }

    // MARK: - Data Management

    /// Entfernt alle Charaktere (z. B. für Settings oder Debug)
    func removeAll() {
        ownedCharacters.removeAll()
        save()

        #if DEBUG
        print("🗑️ Removed all characters.")
        #endif
    }

    /// Prüft, ob ein Charakter bereits vorhanden ist
    func contains(_ character: GameCharacter) -> Bool {
        ownedCharacters.contains(character)
    }

    /// Entfernt einen bestimmten Charakter
    func remove(_ character: GameCharacter) {
        ownedCharacters.removeAll { $0.id == character.id }
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try encoder.encode(ownedCharacters)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("❌ Failed to save characters:", error.localizedDescription)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            #if DEBUG
            print("⚠️ No saved characters found.")
            #endif
            return
        }

        do {
            ownedCharacters = try decoder.decode([GameCharacter].self, from: data)
            #if DEBUG
            print("✅ Loaded \(ownedCharacters.count) characters from UserDefaults.")
            #endif
        } catch {
            print("❌ Failed to load characters:", error.localizedDescription)
            ownedCharacters = []
        }
    }
}



