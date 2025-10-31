//
//  Stage.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-30.
//

import Foundation

// MARK: - Stage Model
struct Stage: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let bossId: String
    let type: String
    let world: Int   // 🌍 Weltzuordnung (z. B. World 1, World 2)

    // MARK: - Beispiel für Preview/Test
    static let example = Stage(
        id: 1,
        name: "Forest Gate",
        bossId: "boss_001",
        type: "story",
        world: 1
    )
}

// MARK: - Global JSON Loader

extension Bundle {
    /// Lädt und dekodiert eine JSON-Datei aus dem Bundle.
    /// Gibt das dekodierte Objekt oder ein leeres Fallback zurück (je nach Typ).
    func decode<T: Decodable>(_ file: String, as type: T.Type = T.self) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("❌ Datei '\(file)' wurde nicht im Bundle gefunden.")
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Fehler beim Dekodieren von \(file): \(error)")
            if let array = [] as? T { return array }       // Falls es ein Array ist
            if let object = Optional<T>.none { return object } // Falls optional
            fatalError("❌ Fehler beim Laden oder Dekodieren von '\(file)'.")
        }
    }
}
