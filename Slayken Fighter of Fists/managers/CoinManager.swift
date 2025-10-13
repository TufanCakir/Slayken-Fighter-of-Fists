import SwiftUI
import Combine

final class CoinManager: ObservableObject {
    static let shared = CoinManager()

    @Published private(set) var coins: Int = UserDefaults.standard.integer(forKey: "coins")

    private init() {}

    @MainActor
    func addCoins(_ amount: Int) {
        coins += amount
        save()
    }

    @MainActor
    func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        save()
        return true
    }
    
    // ✅ Reset für Settings
    func reset() {
        coins = 0
        save()
    }

    private func save() {
        UserDefaults.standard.set(coins, forKey: "coins")
    }
}
