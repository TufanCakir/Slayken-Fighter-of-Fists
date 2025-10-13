import SwiftUI
import Combine

final class AccountLevelManager: ObservableObject {
    static let shared = AccountLevelManager()

    @Published private(set) var level: Int
    @Published private(set) var exp: Int

    private init() {
        self.level = UserDefaults.standard.integer(forKey: "accountLevel")
        self.exp = UserDefaults.standard.integer(forKey: "accountExp")

        if level == 0 { level = 1 } // Start bei Level 1
    }

    @MainActor
    func addExp(_ amount: Int) {
        exp += amount
        let expToNext = level * 200

        if exp >= expToNext {
            exp -= expToNext
            level += 1
            print("🎉 Account erreicht Level \(level)")
        }

        save()
    }
    
    // ✅ Reset für Settings
    func reset() {
        level = 1
        exp = 0
        save()
    }

    private func save() {
        UserDefaults.standard.set(level, forKey: "accountLevel")
        UserDefaults.standard.set(exp, forKey: "accountExp")
    }
}
