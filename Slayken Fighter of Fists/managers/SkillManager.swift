import Foundation
import Combine

@MainActor
final class SkillManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var skills: [Skill] = []
    @Published private(set) var isLoaded: Bool = false

    // MARK: - Singleton
    static let shared = SkillManager()

    // MARK: - Init
    init() {
        loadSkills()
    }

    // MARK: - Lade Skills aus JSON
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

    // MARK: - Skill Zugriff

    /// Gibt einen Skill anhand des Namens zurück.
    func skill(named name: String) -> Skill? {
        skills.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Gibt Skills anhand der IDs zurück (case-insensitive und tolerant).
    func getSkills(for ids: [String]) -> [Skill] {
        let normalizedIDs = ids.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }

        let matched = skills.filter { skill in
            normalizedIDs.contains(skill.id.lowercased())
        }

        // 🔍 Debug-Ausgabe (hilfreich bei fehlenden Skills)
        let foundNames = matched.map { $0.name }
        let missing = normalizedIDs.filter { id in !skills.contains { $0.id.lowercased() == id } }

        if !missing.isEmpty {
            print("⚠️ [SkillManager] Nicht gefundene Skills: \(missing.joined(separator: ", "))")
        }

        print("✅ [SkillManager] Skills für Charakter geladen: \(foundNames.joined(separator: ", "))")

        return matched
    }

    /// Gibt Skills eines bestimmten Elements zurück.
    func getSkills(forElement element: String) -> [Skill] {
        skills.filter { $0.element.lowercased() == element.lowercased() }
    }

    /// Prüft, ob ein Skill existiert (tolerant).
    func contains(skillID id: String) -> Bool {
        skills.contains { $0.id.lowercased() == id.lowercased() }
    }
}
