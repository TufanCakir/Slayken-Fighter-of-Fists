import SwiftUI
import Combine

@MainActor
final class TeamManager: ObservableObject {
    static let shared = TeamManager()

    // MARK: - Published Properties
    @Published private(set) var selectedTeam: [GameCharacter] = []

    private let saveKey = "selectedTeam"

    // MARK: - Init
    private init() {
        load()
    }

    // MARK: - Team Editing
    func toggleMember(_ character: GameCharacter) {
        if selectedTeam.contains(character) {
            selectedTeam.removeAll { $0 == character }
        } else if selectedTeam.count < 4 {
            selectedTeam.append(character)
        }
        save()
    }

    func removeAll() {
        selectedTeam.removeAll()
        save()
    }

    func contains(_ character: GameCharacter) -> Bool {
        selectedTeam.contains(character)
    }

    // MARK: - Persistence
    private func save() {
        do {
            let data = try JSONEncoder().encode(selectedTeam)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("❌ Failed to save team:", error.localizedDescription)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        do {
            selectedTeam = try JSONDecoder().decode([GameCharacter].self, from: data)
        } catch {
            print("❌ Failed to load team:", error.localizedDescription)
        }
    }
}
