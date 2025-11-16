//
//  EventShopManager.swift
//  Slayken Fighter of Fists
//

import Foundation
import SwiftUI
import Combine

// MARK: - RAW JSON (eventShop.json)
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
    
    let image: String?          // <— HIER NEU


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

// MARK: - RESOLVED SHOP CATEGORY
struct EventShopCategory: Identifiable {
    let id: String
    let title: String
    let items: [EventShopItem]
}



// MARK: - EVENT SHOP MANAGER
@MainActor
final class EventShopManager: ObservableObject {

    static let shared = EventShopManager()

    // Für Shop UI
    @Published var categories: [EventShopCategory] = []

    // Alle Items aus equipment.json
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
            print("❌ equipment.json fehlt oder fehlerhaft")
            return
        }

        // Dictionary → extrem schnell für Lookups
        allItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

        print("📦 \(allItems.count) Ausrüstungsgegenstände geladen")

        // ⭐ WICHTIG: Inventory bekommt ALLE möglichen Items
        InventoryManager.shared.registerEquipmentItems(items)
    }



    // MARK: - Lade eventShop.json
    private func loadCategories() {

        guard let wrapper: EventShopWrapper = Bundle.main.decode("eventShop.json") else {
            print("❌ eventShop.json konnte NICHT geladen werden!")
            categories = []
            return
        }

        var finalCategories: [EventShopCategory] = []

        for rawCategory in wrapper.categories {

            let resolvedItems = rawCategory.items.compactMap { ref -> EventShopItem? in

                if let item = allItems[ref.id] {
                    return item
                }

                print("⚠️ WARNUNG: '\(ref.id)' steht in eventShop.json, existiert aber NICHT in equipment.json")
                return nil
            }

            finalCategories.append(
                EventShopCategory(
                    id: rawCategory.id,
                    title: rawCategory.title,
                    items: resolvedItems
                )
            )
        }

        categories = finalCategories

        print("🛍 \(categories.count) Shop-Kategorien geladen")
    }



    // MARK: - Kauf Ergebnisse
    enum PurchaseResult {
        case success
        case notEnoughCurrency
        case alreadyOwned
    }


    // MARK: - BUY
    func buy(_ item: EventShopItem) -> PurchaseResult {

        print("🛒 Kaufversuch: \(item.id) – \(item.name)")

        // Bereits vorhanden?
        if InventoryManager.shared.owns(item.id) {
            print("⚠️ Kauf abgelehnt: Item bereits im Besitz")
            return .alreadyOwned
        }

        // Preis / Währung
        let price = item.shop.price
        let currency = item.shop.currency

        print("💰 Preis: \(price) \(currency)")

        // Preis 0 = immer kaufbar
        if price == 0 {
            InventoryManager.shared.addItem(item.id)
            print("✨ Kostenloses Item hinzugefügt")
            return .success
        }

        // Zu wenig?
        guard spendCurrency(currency, amount: price) else {
            print("❌ Nicht genug \(currency)")
            return .notEnoughCurrency
        }

        // Erfolg
        InventoryManager.shared.addItem(item.id)

        print("✅ Kauf erfolgreich: \(item.name)")
        return .success
    }



    // MARK: - Currency Spending
    private func spendCurrency(_ currency: String, amount: Int) -> Bool {

        print("➡️ Versuche abzuziehen: \(amount) \(currency)")

        switch currency {

        case "event_crystal":
            return CrystalManager.shared.spendCrystals(amount)

        case "crystal":
            return CrystalManager.shared.spendCrystals(amount)

        case "coin":
            return CoinManager.shared.spendCoins(amount)

        default:
            print("⚠️ FEHLER: Unbekannte Währung '\(currency)'")
            return false
        }
    }


    // MARK: - Helper
    func item(for ref: EventShopItemRef) -> EventShopItem? {
        allItems[ref.id]
    }
}
