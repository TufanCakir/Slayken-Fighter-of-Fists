//
//  ScreenFactory.swift
//  Slayken Fighter of Fists
//
//  Created by Tufan Cakir on 2025-10-30.
//

import SwiftUI

/// 🧭 Zentrale Factory zum Erzeugen von Screens anhand ihres Namens.
/// Erleichtert Navigation, Debugging und modulare Erweiterung.
@MainActor
struct ScreenFactory {

    // MARK: - Public API
    /// Gibt eine vollständig konfigurierte AnyView basierend auf einem Namen zurück.
    /// - Parameter name: Eindeutiger Identifier (z. B. `"EventView"`, `"ShowdownView"`).
    /// - Returns: Eine vollständig vorbereitete `AnyView`
    static func make(_ name: String) -> AnyView {
        switch name {

        // MARK: - ⚙️ Core Screens
        case "SettingsView":  return AnyView(SettingsView())
        case "NewsView":      return AnyView(NewsView())

        // MARK: - ⚔️ Kampf- & Spielsystem
        case "ShowdownView":  return AnyView(ShowdownView())
        case "EventView":     return AnyView(EventView())
        case "BattleSceneView": return makeBattleSceneView()
        case "EquipmentView":     return AnyView(EquipmentView())

        // MARK: - 🧩 Fallback
        default:
            return AnyView(fallbackView(for: name))
        }
    }
}

//
// MARK: - 🔧 Erweiterungen
//
private extension ScreenFactory {

    /// Erstellt eine BattleScene mit echten Boss-Daten (Debug/Preview).
    static func makeBattleSceneView() -> AnyView {
        do {
            // ✅ JSON sicher laden
            let bosses: [Boss] = try Bundle.main.decodeSafe("bosses.json")
            guard let boss = bosses.first else {
                return AnyView(fallbackView(for: "BattleSceneView – keine Bossdaten"))
            }

            // 🧩 Manager (Singletons)
            let coin = CoinManager.shared
            let crystal = CrystalManager.shared
            let account = AccountLevelManager.shared
            let team = TeamManager.shared
            let character = CharacterManager.shared
            let skill = SkillManager.shared

            // 🎮 Controller konfigurieren
            let controller = BattleSceneController(
                boss: boss,
                bossHp: boss.hp,
                coinManager: coin,
                crystalManager: crystal,
                accountManager: account,
                characterManager: character,
                skillManager: skill
            )

            // ✅ Vollständige BattleScene
            return AnyView(
                BattleSceneView(controller: controller)
                    .environmentObjects(coin, crystal, account, team, character, skill)
                    .preferredColorScheme(.dark)
                    .background(Color.black.ignoresSafeArea())
            )

        } catch {
            print("⚠️ [ScreenFactory] Fehler beim Laden von bosses.json:", error)
            return AnyView(fallbackView(for: "BattleSceneView (JSON-Fehler)"))
        }
    }

    /// 🧱 Fallback für nicht registrierte Screens
    static func fallbackView(for name: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "questionmark.app.fill")
                .font(.system(size: 70))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.yellow, .orange)

            Text("Screen „\(name)“ nicht gefunden")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Text("Dieser Bildschirm ist noch nicht in der ScreenFactory registriert.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Divider().background(Color.white.opacity(0.25)).padding(.vertical, 8)

            Button {
                print("🐞 Debug: Screen '\(name)' fehlt in ScreenFactory.make()")
            } label: {
                Label("Debug-Log anzeigen", systemImage: "ladybug.fill")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.5))
                .shadow(color: .black.opacity(0.6), radius: 10, y: 4)
        )
        .padding()
    }
}

//
// MARK: - 🧰 Bundle + View Helpers
//
private extension Bundle {
    /// JSON-Decode mit sauberem Fehler-Handling und Default-Fallback
    func decodeSafe<T: Decodable>(_ file: String) throws -> T {
        guard let url = url(forResource: file, withExtension: nil) else {
            throw NSError(domain: "ScreenFactory.FileNotFound", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "\(file) nicht gefunden"])
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NSError(domain: "ScreenFactory.DecodeError", code: 500,
                          userInfo: [NSLocalizedDescriptionKey: "Fehler beim Decodieren von \(file): \(error)"])
        }
    }
}

private extension View {
    /// Mehrere EnvironmentObjects gleichzeitig anhängen.
    func environmentObjects(
        _ coin: CoinManager,
        _ crystal: CrystalManager,
        _ account: AccountLevelManager,
        _ team: TeamManager,
        _ character: CharacterManager,
        _ skill: SkillManager
    ) -> some View {
        self.environmentObject(coin)
            .environmentObject(crystal)
            .environmentObject(account)
            .environmentObject(team)
            .environmentObject(character)
            .environmentObject(skill)
    }
}
