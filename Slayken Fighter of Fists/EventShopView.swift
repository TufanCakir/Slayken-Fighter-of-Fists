import SwiftUI

struct EventShopView: View {

    @EnvironmentObject var shop: EventShopManager
    @EnvironmentObject var crystalManager: CrystalManager
    @EnvironmentObject var coinManager: CoinManager

    @State private var messageText = ""
    @State private var showMessage = false

    var body: some View {
        ZStack {

            ScrollView {
                VStack(spacing: 32) {

                    // MARK: - HEADER
                    Text("Event Shop")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 10)

                    // MARK: - CATEGORY LIST
                    ForEach(shop.categories) { category in

                        VStack(alignment: .leading, spacing: 14) {

                            Text(category.title)
                                .font(.title2.bold())
                                .foregroundColor(.cyan)
                                .padding(.horizontal)

                            VStack(spacing: 14) {

                                // 👉 Kategorie enthält bereits FULL ITEMS
                                ForEach(category.items) { item in

                                    EventShopItemRow(
                                        item: item,
                                        onBuy: {
                                            let result = shop.buy(item)
                                            handleBuyResult(result, item: item)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom)
            }

            // MARK: - MESSAGE POPUP
            if showMessage {
                VStack {
                    Text(messageText)
                        .font(.headline.bold())
                        .padding()
                        .foregroundColor(.white)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(radius: 8)
                }
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color.black.ignoresSafeArea())
        .animation(.easeInOut, value: showMessage)
    }
}


// MARK: - RESULT HANDLING
private extension EventShopView {

    func handleBuyResult(_ result: EventShopManager.PurchaseResult, item: EventShopItem) {

        switch result {

        case .success:
            messageText = "✔️ \(item.name) gekauft!"
            print("🟢 SUCCESS: \(item.id) wurde gekauft.")

        case .alreadyOwned:
            messageText = "⚠️ Bereits im Besitz"
            print("🟡 WARNUNG: \(item.id) ist schon im Besitz.")

        case .notEnoughCurrency:
            messageText = "❌ Nicht genug Währung"
            print("🔴 FEHLER: Zu wenig Währung für \(item.id).")
        }


        showPopup()
    }

    func showPopup() {
        withAnimation {
            showMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showMessage = false
            }
        }
    }
}
