//
//  CharacterManager.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-30.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CharacterManager: ObservableObject {

    // MARK: - Published States
    @Published private(set) var characters: [GameCharacter] = []
    @Published var activeCharacter: GameCharacter?
    @Published private(set) var isLoaded: Bool = false

    // MARK: - Singleton
    static let shared = CharacterManager()

    // MARK: - Storage Keys
    private let savedCharactersKey = "savedCharacters"
    private let activeCharacterIDKey = "activeCharacterID"
    private let progressKey = "characterProgress"

    // MARK: - Init
    private init() {
        loadAll()
    }

    // MARK: - Initial Load (Bundle + Persistenz)
    private func loadAll() {
        if let data = UserDefaults.standard.data(forKey: savedCharactersKey),
           let decoded = try? JSONDecoder().decode([GameCharacter].self, from: data) {
            self.characters = decoded
            print("✅ [CharacterManager] \(decoded.count) gespeicherte Charaktere geladen.")
        } else {
            loadFromBundle()
        }

        applySavedProgress()
        loadActiveCharacter()
        isLoaded = true
    }

    func loadCharacterSkills(_ character: GameCharacter, skillManager: SkillManager) -> [Skill] {
        skillManager.getSkills(for: character.skillIDs)
    }

    private func loadFromBundle() {
        guard let url = Bundle.main.url(forResource: "characters", withExtension: "json") else {
            print("⚠️ [CharacterManager] Keine characters.json gefunden. Verwende leeres Array.")
            self.characters = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([GameCharacter].self, from: data)
            self.characters = decoded
            print("✅ [CharacterManager] \(decoded.count) Charaktere aus Bundle geladen.")
        } catch {
            print("❌ [CharacterManager] Fehler beim Laden: \(error.localizedDescription)")
            self.characters = []
        }
    }

    // MARK: - Aktiver Charakter
    func loadActiveCharacter() {
        guard let savedID = UserDefaults.standard.string(forKey: activeCharacterIDKey),
              let found = characters.first(where: { $0.id == savedID }) else {
            activeCharacter = characters.first
            print("🆕 Kein gespeicherter Charakter – setze ersten als aktiv.")
            return
        }
        activeCharacter = found
        print("🎮 Aktiver Charakter geladen: \(found.name)")
    }

    func setActiveCharacter(_ character: GameCharacter) {
        activeCharacter = character
        UserDefaults.standard.set(character.id, forKey: activeCharacterIDKey)
        saveAll()
        print("🧙‍♂️ Aktiver Charakter gesetzt: \(character.name)")
    }

    // MARK: - Add / Update Charaktere
    func addCharacter(_ newChar: GameCharacter) {
        // Duplikate vermeiden
        if characters.contains(where: { $0.id == newChar.id }) { return }

        characters.append(newChar)
        saveAll()
        print("✨ Neuer Charakter hinzugefügt: \(newChar.name)")
    }

    private func updateCharacter(_ updated: GameCharacter) {
        if let index = characters.firstIndex(where: { $0.id == updated.id }) {
            characters[index] = updated
            if activeCharacter?.id == updated.id {
                activeCharacter = updated
            }
            saveAll()
        }
    }

    // MARK: - Level & Erfahrung
    func levelUp(id: String, expGained: Int) {
        guard var char = characters.first(where: { $0.id == id }) else { return }

        var exp = char.exp + expGained
        var level = char.level

        while exp >= level * 100 {
            exp -= level * 100
            level += 1
            print("🆙 \(char.name) erreicht Level \(level)")
        }

        char.exp = exp
        char.level = level
        updateCharacter(char)
    }

    func getLevel(for id: String) -> Int {
        characters.first(where: { $0.id == id })?.level ?? 1
    }

    // MARK: - Fortschritt speichern / laden
    private func saveProgress() {
        let progress = characters.map { ["id": $0.id, "level": $0.level, "exp": $0.exp] }
        UserDefaults.standard.set(progress, forKey: progressKey)
        print("💾 Fortschritt gespeichert.")
    }

    private func applySavedProgress() {
        guard let saved = UserDefaults.standard.array(forKey: progressKey) as? [[String: Any]] else { return }

        for entry in saved {
            guard let id = entry["id"] as? String else { continue }
            if var char = characters.first(where: { $0.id == id }) {
                char.level = entry["level"] as? Int ?? 1
                char.exp = entry["exp"] as? Int ?? 0
                updateCharacter(char)
            }
        }
        print("📊 Fortschritt angewendet.")
    }

    // MARK: - Speichern & Laden (komplett)
    private func saveAll() {
        saveCharacters()
        saveProgress()
    }

    private func saveCharacters() {
        if let data = try? JSONEncoder().encode(characters) {
            UserDefaults.standard.set(data, forKey: savedCharactersKey)
        }
    }

    func reloadCharacters() {
        loadAll()
    }

    // MARK: - Reset
    func resetProgress() {
        for i in characters.indices {
            characters[i].level = 1
            characters[i].exp = 0
        }
        saveAll()
        print("🔄 Fortschritt & Level zurückgesetzt.")
    }
}
// MARK: - EQUIPMENT SYSTEM (Diablo Style)
extension CharacterManager {

        /// Item ausrüsten
        func equip(_ item: EventShopItem) {
            guard var active = activeCharacter else { return }

            // Beispiel: item.slot = "weapon"
            active.equipped[item.slot] = item.id

            activeCharacter = active
            saveAll()
            objectWillChange.send()
        }

        /// Item ablegen
        func unequip(slot: String) {
            guard var active = activeCharacter else { return }

            active.equipped[slot] = nil

            activeCharacter = active
            saveAll()
            objectWillChange.send()
        }

        /// Ausgerüstetes Item für Slot abrufen
        func equippedItem(for slot: String) -> EventShopItem? {
            guard let id = activeCharacter?.equipped[slot] else { return nil }
            return InventoryManager.shared.allEquipment[id]
        }
    }

