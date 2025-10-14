import Foundation
import Combine

@MainActor
final class StageProgressManager: ObservableObject {
    static let shared = StageProgressManager()
    
    @Published var progress: [StageProgress] = [] {
        didSet { saveProgress() }
    }

    private let saveKey = "stageProgress"

    private init() {
        loadProgress()
    }

    // MARK: - Speichern
    private func saveProgress() {
        do {
            let data = try JSONEncoder().encode(progress)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("⚠️ Fehler beim Speichern: \(error)")
        }
    }

    // MARK: - Laden
    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([StageProgress].self, from: data)
        else {
            print("ℹ️ Kein gespeicherter Fortschritt gefunden – Standardwerte werden geladen.")
            return
        }
        self.progress = decoded
    }

    // MARK: - Update
    func updateProgress(for stageId: Int, completed: Bool, stars: Int) {
        // 🔹 Falls Eintrag bereits existiert → aktualisieren
        if let index = progress.firstIndex(where: { $0.id == stageId }) {
            progress[index].completed = completed
            progress[index].stars = max(progress[index].stars, stars)

            // 🔹 Nächste Stage freischalten (wenn vorhanden)
            let nextId = stageId + 1
            if let nextIndex = progress.firstIndex(where: { $0.id == nextId }) {
                progress[nextIndex].unlocked = true
            } else {
                // 🔹 Falls nächster Eintrag noch nicht existiert → neu anlegen
                progress.append(
                    StageProgress(id: nextId, unlocked: true, completed: false, stars: 0)
                )
            }
        } else {
            // 🔹 Falls Eintrag noch nicht existiert (z. B. erste Stage)
            progress.append(.init(id: stageId, unlocked: true, completed: completed, stars: stars))

            // 🔹 Und gleich den nächsten vorbereiten
            let nextId = stageId + 1
            progress.append(.init(id: nextId, unlocked: true, completed: false, stars: 0))
        }

        saveProgress()
    }


    func resetProgress() {
        progress.removeAll()
        UserDefaults.standard.removeObject(forKey: saveKey)
    }
}
