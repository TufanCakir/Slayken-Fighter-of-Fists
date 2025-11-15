//
//  StageProgressManager.swift
//  Slayken Fighter of Fists
//

import Foundation
import Combine

// MARK: - Stage Progress Model
struct StageProgress: Identifiable, Codable {
    let id: Int
    var unlocked: Bool
    var completed: Bool
    var stars: Int     // ⭐ echte Spieler-Sterne: 0–3

    static let empty = StageProgress(id: 0, unlocked: false, completed: false, stars: 0)

    static let example = StageProgress(
        id: 1,
        unlocked: true,
        completed: false,
        stars: 0
    )
}

@MainActor
final class StageProgressManager: ObservableObject {

    static let shared = StageProgressManager()

    // MARK: - Published
    @Published private(set) var progress: [StageProgress] = [] {
        didSet { saveProgress() }
    }

    // MARK: - Storage
    private let saveKey = "stageProgress"
    private let defaults = UserDefaults.standard

    private init() {
        loadProgress()
    }

    // MARK: - Save
    private func saveProgress() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: saveKey)
    }

    // MARK: - Load
    private func loadProgress() {
        guard let data = defaults.data(forKey: saveKey) else { return }
        progress = (try? JSONDecoder().decode([StageProgress].self, from: data)) ?? []
    }

    // MARK: - Getter
    func progressForStage(_ id: Int) -> StageProgress {
        progress.first(where: { $0.id == id }) ??
        StageProgress(id: id, unlocked: id == 1, completed: false, stars: 0)
    }

    func isUnlocked(_ id: Int) -> Bool {
        progressForStage(id).unlocked
    }

    func isCompleted(_ id: Int) -> Bool {
        progressForStage(id).completed
    }

    func starsForStage(_ id: Int) -> Int {
        progressForStage(id).stars
    }

    // MARK: - Update Progress
    func updateProgress(for stageId: Int, completed: Bool, stars: Int) {

        // 🔹 Stage aktualisieren oder hinzufügen
        if let index = progress.firstIndex(where: { $0.id == stageId }) {
            progress[index].completed = completed
            progress[index].stars = max(progress[index].stars, stars) // best score behalten
        } else {
            progress.append(StageProgress(
                id: stageId,
                unlocked: true,
                completed: completed,
                stars: stars
            ))
        }

        // 🔹 Nächste Stage freischalten
        unlockNextStage(after: stageId)
    }

    // MARK: - Unlock System
    private func unlockNextStage(after stageId: Int) {
        let nextId = stageId + 1

        guard !progress.contains(where: { $0.id == nextId }) else { return }

        progress.append(StageProgress(
            id: nextId,
            unlocked: true,
            completed: false,
            stars: 0
        ))
    }

    // MARK: - Reset
    func resetProgress() {
        progress.removeAll()
        defaults.removeObject(forKey: saveKey)
        print("🔁 Fortschritt komplett zurückgesetzt.")
    }

    // MARK: - Debug
    func printDebug() {
        print("📊 Stage Progress:")
        for p in progress.sorted(by: { $0.id < $1.id }) {
            print("• Stage \(p.id): unlocked=\(p.unlocked), completed=\(p.completed), stars=\(p.stars)")
        }
    }
}
