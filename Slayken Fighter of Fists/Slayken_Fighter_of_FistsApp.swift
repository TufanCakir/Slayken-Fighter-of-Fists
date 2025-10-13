//
//  SlaykenApp.swift
//  Slayken
//
//  Created by Tufan Cakir on 11.10.25.
//

import SwiftUI

@main
struct Slayken_Fighter_of_Fists_App: App {
    @StateObject private var coinManager = CoinManager.shared
    @StateObject private var crystalManager = CrystalManager.shared
    @StateObject private var accountLevelManager = AccountLevelManager.shared
    @StateObject private var characterLevelManager = CharacterLevelManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var summonManager = SummonManager.shared
    @StateObject private var teamManager = TeamManager.shared


    var body: some Scene {
        WindowGroup {
            TutorialView()
                .environmentObject(coinManager)
                .environmentObject(crystalManager)
                .environmentObject(accountLevelManager)
                .environmentObject(characterLevelManager)
                .environmentObject(themeManager)
                .environmentObject(summonManager)
                .environmentObject(teamManager)
        }
    }
}
