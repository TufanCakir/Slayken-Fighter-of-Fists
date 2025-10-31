//
//  Bundle+Decode.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-11-01.
//

import Foundation

public extension Bundle {
    /// 🔹 Lädt und decodiert eine JSON-Datei sicher.
    /// Gibt `nil` zurück, wenn die Datei fehlt oder fehlerhaft ist.
    func decodeSafely<T: Decodable>(_ file: String) -> T? {
        guard let url = url(forResource: file, withExtension: nil) else {
            print("⚠️ [Decode] Datei \(file) nicht gefunden.")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ [Decode] Fehler beim Dekodieren von \(file): \(error.localizedDescription)")
            return nil
        }
    }
}
