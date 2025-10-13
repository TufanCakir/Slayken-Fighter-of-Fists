import SwiftUI
import Combine

final class CrystalManager: ObservableObject {
    static let shared = CrystalManager()

    @Published private(set) var crystals: Int = UserDefaults.standard.integer(forKey: "crystals")

    private init() {}

    @MainActor
    func addCrystals(_ amount: Int) {
        crystals += amount
        save()
    }

    @MainActor
    func spendCrystals(_ amount: Int) -> Bool {
        guard crystals >= amount else { return false }
        crystals -= amount
        save()
        return true
    }
    
    // ✅ Reset für Settings
     func reset() {
         crystals = 0
         save()
     }

    private func save() {
        UserDefaults.standard.set(crystals, forKey: "crystals")
    }
}
