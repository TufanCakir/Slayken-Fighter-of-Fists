//
//  CharacterTemplateManager.swift
//

import Foundation
import Combine

@MainActor
final class CharacterTemplateManager: ObservableObject {

    static let shared = CharacterTemplateManager()

    @Published private(set) var templates: [CharacterTemplate] = []

    private var idLookup: [String: CharacterTemplate] = [:]

    private init() {
        Task { await loadTemplates() }
    }

    private func loadTemplates() async {

        guard let loaded: [CharacterTemplate] = Bundle.main.decodeSafely("characters.json") else {
            print("❌ CharacterTemplateManager: characters.json nicht gefunden oder fehlerhaft.")
            return
        }

        print("📄 JSON geladen → \(loaded.count) Templates")

        // Duplikate entfernen
        var seen = Set<String>()
        let unique = loaded.filter { template in
            let key = template.id.lowercased()
            if seen.contains(key) {
                print("⚠️ Doppeltes Template ignoriert: \(template.name)")
                return false
            }
            seen.insert(key)
            return true
        }

        templates = unique.sorted { $0.name < $1.name }

        idLookup = Dictionary(
            uniqueKeysWithValues: templates.map {
                ($0.id.lowercased(), $0)
            }
        )

        print("📥 CharacterTemplates final geladen: \(templates.count)")
    }

    func template(id: String) -> CharacterTemplate? {
        idLookup[id.lowercased()]
    }
}
