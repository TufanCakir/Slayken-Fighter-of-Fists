//
//  CoinManager.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-30.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CoinManager: ObservableObject {
    // MARK: - Singleton
    static let shared = CoinManager()

    // MARK: - Published State
    @Published private(set) var coins: Int = 0

    // MARK: - Private Constants
    private let saveKey = "coins"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    private init() {
        load()
        setupAutoSave()
    }

    // MARK: - Public API

    /// Fügt eine bestimmte Menge an Coins hinzu.
    func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        coins += amount
    }

    /// Versucht, Coins auszugeben. Gibt `true` zurück, wenn erfolgreich.
    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard amount > 0, coins >= amount else { return false }
        coins -= amount
        return true
    }

    /// Setzt den Kontostand zurück (z. B. in den Einstellungen).
    func reset() {
        coins = 0
    }

    // MARK: - Auto Save mit Combine
    private func setupAutoSave() {
        $coins
            .dropFirst() // Initialwert überspringen
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    // MARK: - Persistence
    private func save() {
        UserDefaults.standard.set(coins, forKey: saveKey)
    }

    private func load() {
        coins = UserDefaults.standard.integer(forKey: saveKey)
    }
}
