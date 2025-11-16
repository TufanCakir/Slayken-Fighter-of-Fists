//
//  SlaykenApp.swift
//  Slayken Fighter of Fists
//


import SwiftUI
import os


@main
struct Slayken_Fighter_of_FistsApp: App {

    // MARK: - Logger
    private let logger = Logger(subsystem: "Slayken", category: "App")

    // MARK: - Manager Instanzen (Singletons)
    @StateObject private var eventShopManager        = EventShopManager.shared
    @StateObject private var inventoryManager        = InventoryManager.shared

    @StateObject private var coinManager             = CoinManager.shared
    @StateObject private var crystalManager          = CrystalManager.shared
    @StateObject private var accountManager          = AccountLevelManager.shared
    @StateObject private var characterManager        = CharacterManager.shared
    @StateObject private var templateManager         = CharacterTemplateManager.shared
    @StateObject private var teamManager             = TeamManager.shared

    @StateObject private var progressManager         = StageProgressManager.shared
    @StateObject private var skillManager            = SkillManager.shared

    @StateObject private var giftManager             = GiftManager.shared
    @StateObject private var dailyLoginManager       = DailyLoginManager.shared

    // MARK: - Non-Singleton
    @StateObject private var musicManager            = MusicManager()


    // MARK: - Scene
    var body: some Scene {
        WindowGroup {

            TutorialView()
                .preferredColorScheme(.dark)

                // MARK: - Reihenfolge beachten!
                // 1️⃣ Shop lädt equipment.json
                // 2️⃣ Inventory hängt vom Shop ab
                .environmentObject(eventShopManager)
                .environmentObject(inventoryManager)

                // MARK: - UI / System / Player Progress
                .environmentObject(coinManager)
                .environmentObject(crystalManager)
                .environmentObject(accountManager)

                // MARK: - Charakter-bezogene Manager
                .environmentObject(characterManager)
                .environmentObject(templateManager)
                .environmentObject(teamManager)

                // MARK: - Gameplay Manager
                .environmentObject(skillManager)
                .environmentObject(progressManager)

                // MARK: - Social / Daily Features
                .environmentObject(giftManager)
                .environmentObject(dailyLoginManager)

                // MARK: - Audio
                .environmentObject(musicManager)

                // MARK: - APP START LOGGING
                .onAppear {
                    logAppStart()
                }
        }
    }

    // MARK: - Logging Funktion
    private func logAppStart() {
        logger.info("🚀 Slayken App gestartet")
        print("🚀 Slayken App gestartet")

        let count = templateManager.templates.count
        logger.info("Character Templates geladen: \(count)")
        print("📦 Character Templates geladen: \(count)")

        // Liste ausgeben
        templateManager.templates.forEach {
            print(" → \(String(describing: $0.id)) | Name: \($0.name)")
        }
    }
}
