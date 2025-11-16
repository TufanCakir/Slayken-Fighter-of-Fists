//
//  SlaykenApp.swift
//  Slayken Fighter of Fists
//

import SwiftUI

@main
struct SlaykenApp: App {

    // ⚠️ WICHTIG: REIHENFOLGE!
    // Erst Shop → lädt equipment.json
    // Dann Inventory → erhält Items

    @StateObject private var eventShopManager     = EventShopManager.shared
    @StateObject private var inventoryManager     = InventoryManager.shared

    // Restliche Singletons
    @StateObject private var coinManager          = CoinManager.shared
    @StateObject private var crystalManager       = CrystalManager.shared
    @StateObject private var accountManager       = AccountLevelManager.shared
    @StateObject private var characterManager     = CharacterManager.shared
    @StateObject private var teamManager          = TeamManager.shared
    @StateObject private var progressManager      = StageProgressManager.shared
    @StateObject private var skillManager         = SkillManager.shared

    // Non-Singleton
    @StateObject private var musicManager         = MusicManager()

    var body: some Scene {
        WindowGroup {
            TutorialView()
                .preferredColorScheme(.dark)
                .environmentObject(eventShopManager)    // 1️⃣ Erst Shop
                .environmentObject(inventoryManager)     // 2️⃣ Dann Inventory
                .environmentObject(coinManager)
                .environmentObject(crystalManager)
                .environmentObject(accountManager)
                .environmentObject(characterManager)
                .environmentObject(teamManager)
                .environmentObject(progressManager)
                .environmentObject(skillManager)
                .environmentObject(musicManager)
        }
    }
}
