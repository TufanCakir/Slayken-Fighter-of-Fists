//
//  EventShopManager.swift
//  Slayken Fighter of Fists
//

import Foundation
import SwiftUI
import Combine

// MARK: - RAW JSON STRUCTURES
struct EventShopWrapper: Codable {
    let categories: [EventShopCategoryRaw]
}

struct EventShopCategoryRaw: Identifiable, Codable {
    let id: String
    let title: String
    let items: [EventShopItemRef]
}

struct EventShopItemRef: Codable {
    let id: String
}


// MARK: - FULL ITEM (equipment.json)
struct EventShopItem: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let rarity: String
    let slot: String
    let type: String

    /// Optionales Bild (für Assets)
    let image: String?

    let stats: Stats
    let shop: ShopInfo

    struct Stats: Codable {
        let damageMultiplier: Double?
        let attackMultiplier: Double?
        let duration: Int?
    }

    struct ShopInfo: Codable {
        let price: Int
        let currency: String
    }
}


// MARK: - RESOLVED SHOP CATEGORY (für UI)
struct EventShopCategory: Identifiable {
    let id: String
    let title: String
    let items: [EventShopItem]
}


// MARK: - SHOP MANAGER
@MainActor
final class EventShopManager: ObservableObject {

    static let shared = EventShopManager()

    // UI-Daten
    @Published var categories: [EventShopCategory] = []

    // Ausrüstung aus equipment.json
    private var allItems: [String: EventShopItem] = [:]


    // MARK: Init
    private init() {
        loadAllItems()
        loadCategories()
        print("🔧 EventShopManager initialisiert")
    }


    // MARK: - Lade equipment.json
    private func loadAllItems() {
        guard let items: [EventShopItem] = Bundle.main.decode("equipment.json") else {
            print("❌ Fehler: equipment.json konnte nicht geladen werden")
            return
        }

        // Dictionary für schnellen Zugriff
        allItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

        print("📦 \(allItems.count) Items geladen aus equipment.json")

        // ⭐ INVENTORY bekommt ALLE möglichen Items (für Equip View)
        InventoryManager.shared.registerEquipmentItems(items)
    }


    // MARK: - Lade eventShop.json → UI Kategorien
    private func loadCategories() {

        guard let wrapper: EventShopWrapper = Bundle.main.decode("eventShop.json") else {
            print("❌ Fehler: eventShop.json konnte nicht geladen werden")
            categories = []
            return
        }

        var finalCategories: [EventShopCategory] = []

        for raw in wrapper.categories {

            let resolvedItems = raw.items.compactMap { ref -> EventShopItem? in

                guard let item = allItems[ref.id] else {
                    print("⚠️ WARNUNG: item '\(ref.id)' existiert NICHT in equipment.json → wird übersprungen")
                    return nil
                }

                return item
            }

            finalCategories.append(
                EventShopCategory(id: raw.id, title: raw.title, items: resolvedItems)
            )
        }

        categories = finalCategories

        print("🛍 Shop-Kategorien geladen: \(categories.count)")
    }


    // MARK: - Ergebnis eines Kaufs
    enum PurchaseResult {
        case success
        case notEnoughCurrency
        case alreadyOwned
    }


    // MARK: - BUY LOGIK
    func buy(_ item: EventShopItem) -> PurchaseResult {

        print("🛒 Kaufversuch: \(item.name) [\(item.id)]")

        // Bereits im Besitz?
        if InventoryManager.shared.owns(item.id) {
            print("⚠️ Kauf abgelehnt: bereits im Besitz")
            return .alreadyOwned
        }

        let price = item.shop.price
        let currency = item.shop.currency

        print("💰 Preis: \(price) \(currency)")

        // Kostenlos
        if price == 0 {
            InventoryManager.shared.addItem(item.id)
            return .success
        }

        // Zu wenig Währung?
        guard spend(currency: currency, amount: price) else {
            print("❌ Nicht genug \(currency)")
            return .notEnoughCurrency
        }

        // Erfolg
        InventoryManager.shared.addItem(item.id)
        print("✅ Kauf erfolgreich: \(item.name)")

        return .success
    }


    // MARK: - Währungsabzug
    private func spend(currency: String, amount: Int) -> Bool {

        print("➡️ Versuche \(amount) \(currency) abzuziehen")

        switch currency {

        case "event_crystal", "crystal":
            return CrystalManager.shared.spendCrystals(amount)

        case "coin":
            return CoinManager.shared.spendCoins(amount)

        default:
            print("⚠️ Unbekannte Währung: \(currency)")
            return false
        }
    }


    // MARK: - Helper
    func item(for ref: EventShopItemRef) -> EventShopItem? {
        allItems[ref.id]
    }
}
