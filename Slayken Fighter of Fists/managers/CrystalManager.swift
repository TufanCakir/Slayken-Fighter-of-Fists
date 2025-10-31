//
//  CrystalManager.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-30.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CrystalManager: ObservableObject {
    // MARK: - Singleton
    static let shared = CrystalManager()

    // MARK: - Published State
    @Published private(set) var crystals: Int = 0

    // MARK: - Private
    private let saveKey = "crystals"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    private init() {
        load()
        setupAutoSave()
    }

    // MARK: - Public API

    /// Fügt eine bestimmte Menge an Kristallen hinzu.
    func addCrystals(_ amount: Int) {
        guard amount > 0 else { return }
        crystals += amount
    }

    /// Versucht, Kristalle auszugeben. Gibt `true` zurück, wenn erfolgreich.
    @discardableResult
    func spendCrystals(_ amount: Int) -> Bool {
        guard amount > 0, crystals >= amount else { return false }
        crystals -= amount
        return true
    }

    /// Setzt den Kontostand auf 0 (z. B. in den Einstellungen).
    func reset() {
        crystals = 0
    }

    // MARK: - Auto Save mit Combine
    private func setupAutoSave() {
        $crystals
            .dropFirst() // Initialwert überspringen
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    // MARK: - Persistence
    private func save() {
        UserDefaults.standard.set(crystals, forKey: saveKey)
    }

    private func load() {
        crystals = UserDefaults.standard.integer(forKey: saveKey)
    }
}
