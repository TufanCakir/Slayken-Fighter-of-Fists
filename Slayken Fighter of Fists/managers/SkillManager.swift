import Foundation
import Combine

@MainActor
final class SkillManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var skills: [Skill] = []
    @Published private(set) var isLoaded: Bool = false

    
    // MARK: - Singleton Instance
    static let shared = SkillManager()

    // MARK: - Initializer
    init() {
        loadSkills()
    }

    // MARK: - Skill Loading
    private func loadSkills() {
        guard let url = Bundle.main.url(forResource: "skills", withExtension: "json") else {
            print("⚠️ [SkillManager] skills.json nicht gefunden im Bundle.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Skill].self, from: data)
            skills = decoded
            isLoaded = true
            print("✅ [SkillManager] \(decoded.count) Skills erfolgreich geladen.")
        } catch {
            print("❌ [SkillManager] Fehler beim Laden der Skills: \(error.localizedDescription)")
        }
    }

    // MARK: - Skill Access
    /// Gibt einen Skill anhand seines Namens zurück.
    func skill(named name: String) -> Skill? {
        skills.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Gibt alle Skills zurück, deren ID in einer ID-Liste enthalten ist.
    func getSkills(for ids: [String]) -> [Skill] {
        skills.filter { ids.contains($0.id) }
    }

    /// Gibt Skills eines bestimmten Elements (z. B. fire, ice, void) zurück.
    func getSkills(forElement element: String) -> [Skill] {
        skills.filter { $0.element.lowercased() == element.lowercased() }
    }

    /// Prüft, ob ein bestimmter Skill existiert.
    func contains(skillID id: String) -> Bool {
        skills.contains { $0.id == id }
    }
}
