//
//  HudIconManager.swift
//

import SwiftUI
import Combine

struct HudIcon: Codable {
    let symbol: String
    let color: String
}

@MainActor
final class HudIconManager: ObservableObject {

    static let shared = HudIconManager()

    private(set) var icons: [String: HudIcon] = [:]

    private init() {
        load()
    }

    private func load() {
        if let loaded: [String: HudIcon] = Bundle.main.decode("hudIcons.json") {
            icons = loaded
        } else {
            print("❌ hudIcons.json konnte NICHT geladen werden")
        }
    }

    func icon(for key: String) -> HudIcon? {
        icons[key]
    }
}
