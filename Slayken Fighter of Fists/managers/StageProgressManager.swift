//
//  StageProgressManager.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-30.
//

import Foundation
import Combine

// MARK: - Stage Progress Model
struct StageProgress: Identifiable, Codable, Hashable {
    let id: Int
    var unlocked: Bool
    var completed: Bool
    var stars: Int
    var world: Int? = nil  // Optional: Für Welt-Zuordnung

    static let example = StageProgress(id: 1, unlocked: true, completed: false, stars: 0, world: 1)
}

// MARK: - StageProgressManager
@MainActor
final class StageProgressManager: ObservableObject {
    static let shared = StageProgressManager()

    // MARK: - Published Data
    @Published private(set) var progress: [StageProgress] = [] {
        didSet { saveProgress() }
    }

    // MARK: - Private
    private let saveKey = "stageProgress"
    private let defaults = UserDefaults.standard

    private init() {
        loadProgress()
    }

    // MARK: - Save
    private func saveProgress() {
        do {
            let data = try JSONEncoder().encode(progress)
            defaults.set(data, forKey: saveKey)
        } catch {
            print("⚠️ Fehler beim Speichern des Fortschritts: \(error.localizedDescription)")
        }
    }

    // MARK: - Load
    private func loadProgress() {
        guard let data = defaults.data(forKey: saveKey) else {
            print("ℹ️ Kein gespeicherter Fortschritt gefunden. Standardwerte werden verwendet.")
            return
        }

        do {
            progress = try JSONDecoder().decode([StageProgress].self, from: data)
        } catch {
            print("⚠️ Fehler beim Laden des Fortschritts: \(error.localizedDescription)")
            progress = []
        }
    }

    // MARK: - Zugriff
    func progressForStage(_ id: Int) -> StageProgress? {
        progress.first(where: { $0.id == id })
    }

    func isUnlocked(_ id: Int) -> Bool {
        progress.first(where: { $0.id == id })?.unlocked ?? (id == 1)
    }

    func isCompleted(_ id: Int) -> Bool {
        progress.first(where: { $0.id == id })?.completed ?? false
    }

    func starsForStage(_ id: Int) -> Int {
        progress.first(where: { $0.id == id })?.stars ?? 0
    }

    // MARK: - Update Logic
    func updateProgress(for stageId: Int, completed: Bool, stars: Int, world: Int? = nil) {
        // 🔹 Bestehenden Eintrag finden oder neuen erstellen
        if let index = progress.firstIndex(where: { $0.id == stageId }) {
            progress[index].completed = completed
            progress[index].stars = max(progress[index].stars, stars)
        } else {
            progress.append(StageProgress(
                id: stageId,
                unlocked: true,
                completed: completed,
                stars: stars,
                world: world
            ))
        }

        // 🔹 Nächste Stage automatisch freischalten
        let nextId = stageId + 1
        if !progress.contains(where: { $0.id == nextId }) {
            progress.append(StageProgress(id: nextId, unlocked: true, completed: false, stars: 0))
        }

        // 🔹 Optional: Ganze Welt freischalten
        if completed, let world = world {
            unlockNextWorld(after: world)
        }

        saveProgress()
    }

    // MARK: - Weltfortschritt
    private func unlockNextWorld(after currentWorld: Int) {
        // Logik: Wenn alle Stages in Welt X abgeschlossen → Welt X+1 freischalten
        let currentWorldStages = progress.filter { $0.world == currentWorld }
        let allCompleted = !currentWorldStages.isEmpty && currentWorldStages.allSatisfy { $0.completed }

        if allCompleted {
            print("🌍 Welt \(currentWorld + 1) freigeschaltet!")
            progress.append(
                StageProgress(id: (progress.map { $0.id }.max() ?? 0) + 1,
                              unlocked: true,
                              completed: false,
                              stars: 0,
                              world: currentWorld + 1)
            )
        }
    }

    // MARK: - Reset
    func resetProgress() {
        progress.removeAll()
        defaults.removeObject(forKey: saveKey)
        print("🔁 Fortschritt zurückgesetzt.")
    }

    // MARK: - Debug Utility
    func printDebugProgress() {
        print("📊 Aktueller Fortschritt:")
        for stage in progress.sorted(by: { $0.id < $1.id }) {
            print("  • Stage \(stage.id) → unlocked: \(stage.unlocked), completed: \(stage.completed), stars: \(stage.stars)")
        }
    }
}
