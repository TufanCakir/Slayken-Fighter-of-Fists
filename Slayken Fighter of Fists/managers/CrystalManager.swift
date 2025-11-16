//
//  CrystalManager.swift
//  Slayken Fighter of Fists
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CrystalManager: ObservableObject {

    // MARK: - Singleton
    static let shared = CrystalManager()

    // MARK: - State
    @Published private(set) var crystals: Int = 0

    private let saveKey = "crystals"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    private init() {
        load()
        autoSave()
    }

    // MARK: - Public API
    func addCrystals(_ amount: Int) {
        guard amount >= 0 else { return }
        crystals += amount
    }

    @discardableResult
    func spendCrystals(_ amount: Int) -> Bool {

        // Preis 0 → immer TRUE
        if amount == 0 { return true }

        guard amount > 0, crystals >= amount else { return false }

        crystals -= amount
        return true
    }

    func reset() {
        crystals = 0
    }

    // MARK: - Auto Save
    private func autoSave() {
        $crystals
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.save()
            }
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
