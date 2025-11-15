//
//  SlaykenApp.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 11.10.25.
//

import SwiftUI

@main
struct SlaykenApp: App {

    // MARK: - Shared Managers (Singletons)
    @StateObject private var coinManager = CoinManager.shared
    @StateObject private var crystalManager = CrystalManager.shared
    @StateObject private var accountManager = AccountLevelManager.shared
    @StateObject private var characterManager = CharacterManager.shared
    @StateObject private var teamManager = TeamManager.shared
    @StateObject private var progressManager = StageProgressManager.shared
    @StateObject private var skillManager = SkillManager.shared

    // MARK: - Local Managers (Non-Singleton)
    @StateObject private var musicManager = MusicManager()

    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            FooterTabView()
                .environmentObjects(
                    coinManager,
                    crystalManager,
                    accountManager,
                    characterManager,
                    teamManager,
                    progressManager,
                    skillManager,
                    musicManager
                )
        }
    }
}

// MARK: - Root Entry View
private struct RootView: View {
    var body: some View {
        TutorialView()
            .preferredColorScheme(.dark)
    }
}

// MARK: - Environment Injection Helper
private extension View {
    func environmentObjects(
        _ coin: CoinManager,
        _ crystal: CrystalManager,
        _ account: AccountLevelManager,
        _ character: CharacterManager,
        _ team: TeamManager,
        _ progress: StageProgressManager,
        _ skill: SkillManager,
        _ music: MusicManager
    ) -> some View {
        self.environmentObject(coin)
            .environmentObject(crystal)
            .environmentObject(account)
            .environmentObject(character)
            .environmentObject(team)
            .environmentObject(progress)
            .environmentObject(skill)
            .environmentObject(music)
    }
}
