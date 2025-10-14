// MARK: - Models

import Foundation

struct Stage: Identifiable, Hashable {
    let id: Int
    let name: String
    let bossId: String
    let type: String
}


struct Boss: Identifiable, Codable {
    let id: String
    let name: String
    let image: String
    let background: String?
    let element: String?   // <–– neu, optional!
    let hp: Int
}

// MARK: - JSON Loader (global!)

extension Bundle {
    func decode<T: Decodable>(_ file: String) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("❌ Datei \(file) nicht gefunden.")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("❌ Datei \(file) konnte nicht geladen werden.")
        }

        let decoder = JSONDecoder()
        guard let loaded = try? decoder.decode(T.self, from: data) else {
            fatalError("❌ Datei \(file) konnte nicht dekodiert werden.")
        }

        return loaded
    }
}
