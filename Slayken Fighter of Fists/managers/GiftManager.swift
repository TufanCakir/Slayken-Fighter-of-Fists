//
//  GiftManager.swift
//  Slayken Fighter of Fists
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class GiftManager: ObservableObject {

    static let shared = GiftManager()

    @Published private(set) var claimedGifts: Set<String> = []

    private let saveKey = "claimed_gifts"

    private init() {
        load()
    }

    func isClaimed(_ id: String) -> Bool {
        claimedGifts.contains(id)
    }

    func claim(_ gift: GiftItem) -> Bool {
        if isClaimed(gift.id) { return false }

        claimedGifts.insert(gift.id)
        save()

        // Reward anwenden
        if let coins = gift.reward.coins {
            CoinManager.shared.addCoins(coins)
        }
        if let crystals = gift.reward.crystals {
            CrystalManager.shared.addCrystals(crystals)
        }

        return true
    }

    private func save() {
        UserDefaults.standard.set(Array(claimedGifts), forKey: saveKey)
    }

    private func load() {
        if let saved = UserDefaults.standard.array(forKey: saveKey) as? [String] {
            claimedGifts = Set(saved)
        }
    }
}
