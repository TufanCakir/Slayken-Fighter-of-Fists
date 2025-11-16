//
//  Bundle+Decode.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-11-01.
//

import Foundation
import os

private let decodeLogger = Logger(subsystem: "Slayken", category: "JSONDecode")

public extension Bundle {

    /// 🔹 Lädt und decodiert eine JSON-Datei sicher.
    /// - Gibt `nil` zurück, wenn die Datei fehlt, leer ist oder Fehler enthält.
    /// - Loggt alle Probleme sichtbar in der Konsole.
    func decodeSafely<T: Decodable>(_ file: String) -> T? {
        
        let name = file.contains(".json") ? file : "\(file).json"

        // MARK: - Datei suchen
        guard let url = url(forResource: name, withExtension: nil) else {
            decodeLogger.error("❌ Datei nicht gefunden: \(name)")
            print("❌ [Decode] Datei nicht gefunden: \(name)")
            return nil
        }

        // MARK: - Datei lesen
        guard let data = try? Data(contentsOf: url) else {
            decodeLogger.error("❌ Datei konnte nicht gelesen werden: \(name)")
            print("❌ [Decode] Datei konnte nicht gelesen werden: \(name)")
            return nil
        }

        if data.isEmpty {
            decodeLogger.error("⚠️ Datei ist leer: \(name)")
            print("⚠️ [Decode] Datei ist leer: \(name)")
            return nil
        }

        // MARK: - Decoder Setup
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601  // falls irgendwann Daten kommen
        decoder.nonConformingFloatDecodingStrategy = .throw
        
        do {
            let result = try decoder.decode(T.self, from: data)
            decodeLogger.info("📄 JSON erfolgreich geladen: \(name)")
            return result

        } catch let DecodingError.keyNotFound(key, context) {
            decodeLogger.error("❌ Key not found: \(key.stringValue) in \(name)")
            print("❌ [Decode] Key not found: \(key.stringValue) in \(name)")
            print("➡️ Context:", context.debugDescription)
            print("➡️ CodingPath:", context.codingPath.map(\.stringValue))

        } catch let DecodingError.typeMismatch(type, context) {
            decodeLogger.error("❌ Type mismatch: expected \(String(describing: type)) in \(name)")
            print("❌ [Decode] Type mismatch for \(type) in \(name)")
            print("➡️ Context:", context.debugDescription)
            print("➡️ CodingPath:", context.codingPath.map(\.stringValue))

        } catch let DecodingError.valueNotFound(type, context) {
            decodeLogger.error("❌ Value not found: \(String(describing: type)) in \(name)")
            print("❌ [Decode] Value not found: \(type) in \(name)")
            print("➡️ Context:", context.debugDescription)
            print("➡️ CodingPath:", context.codingPath.map(\.stringValue))

        } catch let DecodingError.dataCorrupted(context) {
            decodeLogger.error("❌ Data corrupted in \(name)")
            print("❌ [Decode] Data corrupted in \(name)")
            print("➡️ Context:", context.debugDescription)
            print("➡️ CodingPath:", context.codingPath.map(\.stringValue))

        } catch {
            decodeLogger.error("❌ Unbekannter JSON Fehler in \(name): \(error.localizedDescription)")
            print("❌ [Decode] Unbekannter Fehler in \(name): \(error.localizedDescription)")
        }

        return nil
    }
}
