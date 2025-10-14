import SwiftUI
import Combine

struct CharacterProgress: Codable, Identifiable {
    let id: String
    var level: Int
    var exp: Int
}

final class CharacterLevelManager: ObservableObject {
    static let shared = CharacterLevelManager()

    @Published private(set) var characters: [CharacterProgress] = []
    private let saveKey = "characterProgressData"

    private init() {
        load()
    }

    @MainActor
    func levelUp(id: String, expGained: Int) {
        if let index = characters.firstIndex(where: { $0.id == id }) {
            var char = characters[index]
            char.exp += expGained

            let expToNext = char.level * 100
            if char.exp >= expToNext {
                char.exp -= expToNext
                char.level += 1
                print("🔥 \(id) erreicht Level \(char.level)")
            }
            characters[index] = char
        } else {
            let newChar = CharacterProgress(id: id, level: 1, exp: expGained)
            characters.append(newChar)
        }
        save()
    }

    func getLevel(for id: String) -> Int {
        characters.first(where: { $0.id == id })?.level ?? 1
    }
    
    func reset() {
        characters.removeAll()
        UserDefaults.standard.removeObject(forKey: saveKey)
        print("🧩 Character progress reset.")
    }

    private func save() {
        if let data = try? JSONEncoder().encode(characters) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([CharacterProgress].self, from: data)
        else { return }
        characters = decoded
    }
}
