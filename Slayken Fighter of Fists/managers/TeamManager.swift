//
//  TeamManager.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-31.
//

import SwiftUI
import Combine

@MainActor
final class TeamManager: ObservableObject {
    // MARK: - Singleton
    static let shared = TeamManager()

    // MARK: - Published Properties
    @Published private(set) var selectedTeam: [GameCharacter] = []     // aktive Kämpfer im Team
    @Published private(set) var createdCharacters: [GameCharacter] = [] // alle erstellten Charaktere
    @Published var activeCharacter: GameCharacter?                     // aktuell ausgewählter Held

    // MARK: - Keys
    private let teamSaveKey = "selectedTeam"
    private let createdSaveKey = "createdCharacters"
    private let activeSaveKey = "activeCharacter"

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    private init() {
        loadAll()
        setupAutoSave()
    }

    // MARK: - 🧠 Combine Auto-Save
    private func setupAutoSave() {
        // Team speichern
        $selectedTeam
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] in self?.save($0, key: self?.teamSaveKey) }
            .store(in: &cancellables)

        // Erstellte Charaktere speichern
        $createdCharacters
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] in self?.save($0, key: self?.createdSaveKey) }
            .store(in: &cancellables)

        // Aktiven Charakter speichern
        $activeCharacter
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] character in
                guard let self else { return }
                if let char = character {
                    self.save([char], key: self.activeSaveKey)
                } else {
                    UserDefaults.standard.removeObject(forKey: self.activeSaveKey)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - ⚔️ Team Management
    func toggleMember(_ character: GameCharacter) {
        if let index = selectedTeam.firstIndex(of: character) {
            selectedTeam.remove(at: index)
            print("❎ Removed \(character.name) from team.")
        } else if selectedTeam.count < 4 {
            selectedTeam.append(character)
            print("✅ Added \(character.name) to team.")
        } else {
            print("⚠️ Team limit reached (max 4 members).")
        }
    }

    func contains(_ character: GameCharacter) -> Bool {
        selectedTeam.contains(character)
    }

    func clearTeam() {
        selectedTeam.removeAll()
        print("🧹 Cleared team.")
    }

    func removeAllData() {
        selectedTeam.removeAll()
        createdCharacters.removeAll()
        activeCharacter = nil
        saveAll()
        print("🗑️ All data removed (team, characters, active).")
    }

    // MARK: - 🧍 Charakterverwaltung
    func addCharacter(_ character: GameCharacter) {
        guard !createdCharacters.contains(where: { $0.id == character.id }) else {
            print("⚠️ Character '\(character.name)' already exists.")
            return
        }
        createdCharacters.append(character)
    }

    func deleteCharacter(_ character: GameCharacter) {
        createdCharacters.removeAll { $0.id == character.id }
        selectedTeam.removeAll { $0.id == character.id }
        if activeCharacter?.id == character.id {
            activeCharacter = nil
        }
        saveAll()
        print("🗑️ Deleted character '\(character.name)'.")
    }

    func setActiveCharacter(_ character: GameCharacter?) {
        activeCharacter = character
        if let char = character {
            print("🔥 Active character set to: \(char.name)")
        } else {
            print("❎ Active character cleared.")
        }
    }

    // MARK: - 🧪 Level & EXP
    func addExp(to id: String, amount: Int) {
        guard var char = createdCharacters.first(where: { $0.id == id }) else { return }
        char.gainExp(amount)
        updateCharacter(char)
    }

    private func updateCharacter(_ updated: GameCharacter) {
        if let index = createdCharacters.firstIndex(where: { $0.id == updated.id }) {
            createdCharacters[index] = updated
        }
        if let teamIndex = selectedTeam.firstIndex(where: { $0.id == updated.id }) {
            selectedTeam[teamIndex] = updated
        }
        if activeCharacter?.id == updated.id {
            activeCharacter = updated
        }
    }

    // MARK: - 💾 Save & Load
    private func saveAll() {
        save(selectedTeam, key: teamSaveKey)
        save(createdCharacters, key: createdSaveKey)
        if let active = activeCharacter {
            save([active], key: activeSaveKey)
        }
    }

    private func loadAll() {
        selectedTeam = loadArray(forKey: teamSaveKey)
        createdCharacters = loadArray(forKey: createdSaveKey)

        let activeList = loadArray(forKey: activeSaveKey)
        activeCharacter = activeList.first

        print("📦 Loaded \(createdCharacters.count) chars, \(selectedTeam.count) in team, active: \(activeCharacter?.name ?? "none").")
    }

    private func save<T: Encodable>(_ data: T, key: String?) {
        guard let key, !key.isEmpty else { return }
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: key)
        } catch {
            print("❌ Failed to save '\(key)': \(error.localizedDescription)")
        }
    }

    private func loadArray(forKey key: String) -> [GameCharacter] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([GameCharacter].self, from: data)
        } catch {
            print("⚠️ Failed to decode '\(key)': \(error.localizedDescription)")
            return []
        }
    }
}
