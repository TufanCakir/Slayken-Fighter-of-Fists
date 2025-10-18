import SwiftUI

/// Eine zentrale Factory, die anhand eines Namens automatisch den passenden Screen erzeugt.
/// So bleibt HomeView, FooterView und NavigationView übersichtlich und flexibel.
@MainActor
struct ScreenFactory {

    /// Erzeugt eine beliebige View anhand ihres registrierten Namens.
    static func make(_ name: String) -> AnyView {
        switch name {

        // MARK: - Hauptscreens
        case "SettingsView":
            AnyView(SettingsView())

        case "NewsView":
            AnyView(NewsView())

        // MARK: - Kampfsystem
        case "ShowdownView":
            AnyView(ShowdownView())

        case "EventView":
            AnyView(EventView())

        case "BattleSceneView":
            makeBattleSceneView()

        // MARK: - Fallback
        default:
            AnyView(fallbackView(for: name))
        }
    }
}

//
// MARK: - Erweiterungen
//
extension ScreenFactory {

    /// Erstellt eine Beispiel-BattleScene mit Boss & Team aus JSON-Dateien.
    private static func makeBattleSceneView() -> AnyView {
        let bosses: [Boss] = Bundle.main.decode("bosses.json")
        let summonManager = SummonManager.shared
        let teamManager = TeamManager.shared

        guard let boss = bosses.first else {
            return AnyView(fallbackView(for: "BattleScene (keine Bossdaten)"))
        }

        // MARK: - Teamquelle bestimmen
        let team: [GameCharacter] = {
            if !teamManager.selectedTeam.isEmpty {
                return teamManager.selectedTeam
            } else if !summonManager.ownedCharacters.isEmpty {
                return summonManager.ownedCharacters
            } else {
                return [GameCharacter.example]
            }
        }()

        // MARK: - BattleController erzeugen
        let controller = BattleSceneController(
            boss: boss,
            bossHp: boss.hp,
            team: team,
            coinManager: .shared,
            crystalManager: .shared,
            accountManager: .shared,
            characterManager: .shared,
            skillManager: .shared
        )

        // MARK: - Scene aufbauen
        return AnyView(
            BattleSceneView(controller: controller)
                .environmentObject(teamManager)
                .environmentObject(summonManager)
                .environmentObject(CoinManager.shared)
                .environmentObject(CrystalManager.shared)
                .environmentObject(AccountLevelManager.shared)
                .environmentObject(CharacterLevelManager.shared)
                .environmentObject(SkillManager.shared)
        )
    }

    /// Universeller Fallback für ungültige Screen-Namen.
    private static func fallbackView(for name: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)

            Text("Screen „\(name)“ nicht gefunden")
                .font(.headline)
                .foregroundColor(.gray)

            Text("Bitte überprüfe den Namen oder füge ihn in der ScreenFactory hinzu.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .shadow(color: .black.opacity(0.3), radius: 6)
        )
        .padding()
    }
}
