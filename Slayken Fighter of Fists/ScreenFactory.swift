import SwiftUI

/// Eine zentrale Factory, die anhand eines Namens automatisch den passenden Screen erzeugt.
/// Verhindert lange Switch-Logik in HomeView, FooterView und NavigationLinks.
@MainActor
struct ScreenFactory {
    
    /// Erzeugt eine beliebige View anhand ihres Namens.
    static func make(_ name: String) -> AnyView {
        switch name {
        
        // MARK: - Hauptviews
        
     
   
      
        case "SettingsView":
            AnyView(SettingsView())
            
     
        case "NewsView":
            AnyView(NewsView())
            
        // MARK: - Kampfsystem
        case "ShowdownView":
            AnyView(ShowdownView())
            
        case "EventView":
            AnyView(EventView())
            
        // MARK: - Direkter Battle-Test (z. B. im Debug)
        case "BattleSceneView":
            makeBattleSceneView()
            
        // MARK: - Fallback
        default:
            AnyView(fallbackView(for: name))
        }
    }
}

// MARK: - Erweiterungen
extension ScreenFactory {
    
    /// Erzeugt eine BattleScene mit Beispielteam und Boss aus JSON.
    private static func makeBattleSceneView() -> AnyView {
        let bosses: [Boss] = Bundle.main.decode("bosses.json")
        let summonManager = SummonManager.shared
        let teamManager = TeamManager.shared
        
        guard let boss = bosses.first else {
            return AnyView(fallbackView(for: "BattleScene (keine Bossdaten)"))
        }
        
        // Teamquelle: erst echtes Team, dann Summons, dann Beispiel
        let team: [GameCharacter] = {
            if !teamManager.selectedTeam.isEmpty {
                return teamManager.selectedTeam
            } else if !summonManager.ownedCharacters.isEmpty {
                return summonManager.ownedCharacters
            } else {
                return [GameCharacter.example]
            }
        }()
        
        let controller = BattleSceneController(
            boss: boss,
            bossHp: boss.hp,
            team: team,
            coinManager: CoinManager.shared,
            crystalManager: CrystalManager.shared,
            accountManager: AccountLevelManager.shared,
            characterManager: CharacterLevelManager.shared
        )
        
        return AnyView(
            BattleSceneView(controller: controller)
                .environmentObject(teamManager)
                .environmentObject(summonManager)
                .environmentObject(CoinManager.shared)
                .environmentObject(CrystalManager.shared)
                .environmentObject(AccountLevelManager.shared)
                .environmentObject(CharacterLevelManager.shared)
        )
    }
    
    /// Universeller Fallback für unbekannte Screen-Namen.
    private static func fallbackView(for name: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(.yellow)
            
            Text("🚧 Screen '\(name)' not found")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.15))
        )
        .padding()
    }
}
