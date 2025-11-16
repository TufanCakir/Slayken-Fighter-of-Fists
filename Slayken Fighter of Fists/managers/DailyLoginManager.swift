//
//  DailyLoginManager.swift
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class DailyLoginManager: ObservableObject {

    static let shared = DailyLoginManager()

    @Published private(set) var currentDay: Int = 1         // 1–7
    @Published private(set) var claimedToday: Bool = false  // ob schon abgeholt

    private let dayKey = "login_current_day"
    private let claimedKey = "login_claimed_today"
    private let lastLoginKey = "login_last_date"

    private init() {
        load()
        evaluateNewDay()
    }

    // MARK: - Prüfen ob neuer Tag
    private func evaluateNewDay() {
        if let savedDate = UserDefaults.standard.string(forKey: lastLoginKey),
           let last = ISO8601DateFormatter().date(from: savedDate) {

            if Calendar.current.isDateInToday(last) {
                // gleicher Tag → alles ok
                return
            }
        }

        // Neuer Tag!
        claimedToday = false
        currentDay += 1

        if currentDay > 7 {
            currentDay = 1  // Reset nach Tag 7
        }

        save()
    }

    // MARK: - Claim Logik
    func claim(reward: DailyReward) -> Bool {

        if claimedToday { return false }

        // Coins Reward
        if let coins = reward.coins {
            CoinManager.shared.addCoins(coins)
        }

        // Crystal Reward
        if let crystals = reward.crystals {
            CrystalManager.shared.addCrystals(crystals)
        }

        claimedToday = true

        UserDefaults.standard.set(
            ISO8601DateFormatter().string(from: Date()),
            forKey: lastLoginKey
        )

        save()
        return true
    }

    // MARK: - Save & Load
    private func save() {
        UserDefaults.standard.set(currentDay, forKey: dayKey)
        UserDefaults.standard.set(claimedToday, forKey: claimedKey)
    }

    private func load() {
        currentDay = UserDefaults.standard.integer(forKey: dayKey)
        if currentDay == 0 { currentDay = 1 }

        claimedToday = UserDefaults.standard.bool(forKey: claimedKey)
    }
}
