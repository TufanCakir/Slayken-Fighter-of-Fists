//
//  SkillManager.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-31.
//

import Foundation
import Combine

@MainActor
final class SkillManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var skills: [Skill] = []
    @Published private(set) var isLoaded = false

    // MARK: - Singleton
    static let shared = SkillManager()

    // MARK: - Private Cache
    private var skillLookup: [String: Skill] = [:]

    // MARK: - Init
    private init() {
        Task.detached(priority: .background) { [weak self] in
            await self?.loadSkills()
        }
    }

    // MARK: - Lade Skills aus JSON
    private func loadSkills() async {
        guard let url = Bundle.main.url(forResource: "skills", withExtension: "json") else {
            print("⚠️ [SkillManager] skills.json nicht gefunden im Bundle.")
            await MainActor.run { self.isLoaded = true }
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Skill].self, from: data)

            await MainActor.run {
                // ✅ Duplikate nach ID entfernen (manuell statt KeyPath)
                var seen: Set<String> = []
                let unique = decoded.filter { skill in
                    let key = skill.id.lowercased()
                    if seen.contains(key) { return false }
                    seen.insert(key)
                    return true
                }

                // ✅ Sortieren & speichern
                self.skills = unique.sorted(by: { $0.id.lowercased() < $1.id.lowercased() })
                self.isLoaded = true

                // 🔍 Cache für schnelle Abfragen
                self.skillLookup = Dictionary(uniqueKeysWithValues: unique.map {
                    ($0.id.lowercased(), $0)
                })

                print("✅ [SkillManager] \(unique.count) Skills erfolgreich geladen.")
            }

        } catch {
            await MainActor.run {
                print("❌ [SkillManager] Fehler beim Laden: \(error.localizedDescription)")
                self.skills = []
                self.isLoaded = true
            }
        }
    }

    // MARK: - Zugriff per Name oder ID
    func skill(named name: String) -> Skill? {
        skills.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    func skill(id: String) -> Skill? {
        skillLookup[id.lowercased()]
    }

    func summonRandomSkill() -> Skill? {
        guard !skills.isEmpty else { return nil }

        let randomSkill = skills.randomElement()
        print("🎁 Summoned Skill: \(randomSkill?.name ?? "none")")
        return randomSkill
    }

    func summonTenSkills() -> [Skill] {
        var result: [Skill] = []
        for _ in 0..<10 {
            if let skill = summonRandomSkill() {
                result.append(skill)
            }
        }
        return result
    }

    
    // MARK: - Mehrere Skills abrufen
    func getSkills(for ids: [String]) -> [Skill] {
        guard !ids.isEmpty else { return [] }

        let normalized = ids.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }

        let matched = normalized.compactMap { skillLookup[$0] }

        let missing = normalized.filter { skillLookup[$0] == nil }
        if !missing.isEmpty {
            print("⚠️ [SkillManager] Fehlende Skill-IDs: \(missing.joined(separator: ", "))")
        }

        let foundNames = matched.map(\.name).joined(separator: ", ")
        print("✅ [SkillManager] Gefundene Skills: \(foundNames)")
        return matched
    }

    // MARK: - Skills nach Element
    func getSkills(forElement element: String) -> [Skill] {
        let lower = element.lowercased()
        let filtered = skills.filter { $0.element.lowercased() == lower }
        print("🌪 [SkillManager] \(filtered.count) Skills für Element \(element.capitalized) gefunden.")
        return filtered
    }

    // MARK: - Existenzprüfung
    func contains(skillID id: String) -> Bool {
        skillLookup[id.lowercased()] != nil
    }

    // MARK: - Debug-Ausgabe
    func printAllSkills() {
        print("📘 Alle Skills:")
        for skill in skills {
            print("• [\(skill.element.capitalized)] \(skill.name) (\(skill.id)) – Typ: \(skill.type)")
        }
    }
}
