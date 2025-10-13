import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var current: AppTheme
    @Published var allThemes: [AppTheme]

    private let saveKey = "selectedThemeID"

    private init() {
        // 1️⃣ JSON lokal laden (kein Zugriff auf self)
        let loadedThemes: [AppTheme] = Bundle.main.decode("themes.json")

        // 2️⃣ Gespeichertes Theme prüfen
        let savedID = UserDefaults.standard.string(forKey: saveKey)
        let selectedTheme = loadedThemes.first(where: { $0.id == savedID })
            ?? loadedThemes.first
            ?? AppTheme(id: "dark", name: "Dark", gradient: ["#000000", "#1C1C1E"], tint: "#FFFFFF")

        // 3️⃣ Properties initialisieren
        self.allThemes = loadedThemes
        self.current = selectedTheme
    }

    // MARK: - Funktionen
    func selectTheme(_ theme: AppTheme) {
        current = theme
        UserDefaults.standard.set(theme.id, forKey: saveKey)
    }

    var gradientColors: [Color] {
        current.gradient.map { Color(hex: $0) }
    }

    var tintColor: Color {
        Color(hex: current.tint)
    }
}
