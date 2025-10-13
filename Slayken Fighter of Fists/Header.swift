import SwiftUI

/// Universeller App-Header für Ressourcenanzeige.
/// Zeigt Coins, Crystals und Account-Level aus den Managern.
struct HeaderView: View {
    // MARK: - EnvironmentObjects
    @EnvironmentObject var coinManager: CoinManager
    @EnvironmentObject var crystalManager: CrystalManager
    @EnvironmentObject var accountManager: AccountLevelManager

    // MARK: - Icons (optional aus JSON ladbar)
    @State private var icons: HUDIconSet = Bundle.main.decode("hudIcons.json")

    var body: some View {
        HStack(spacing: 14) {
            resourceItem(
                symbol: icons.level.symbol,
                color: Color(hex: icons.level.color),
                value: accountManager.level,
                label: "Lv."
            )
            resourceItem(
                symbol: icons.coin.symbol,
                color: Color(hex: icons.coin.color),
                value: coinManager.coins
            )
            resourceItem(
                symbol: icons.crystal.symbol,
                color: Color(hex: icons.crystal.color),
                value: crystalManager.crystals
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [.black, .blue, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }

    // MARK: - Einzelnes Element
    private func resourceItem(symbol: String, color: Color, value: Int, label: String? = nil) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundColor(color)
                .font(.system(size: 20, weight: .semibold))
            if let label = label {
                Text("\(label) \(value)")
                    .foregroundColor(color)
                    .font(.headline.bold())
            } else {
                Text("\(value)")
                    .foregroundColor(color)
                    .font(.headline.bold())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .clipShape(Capsule())
        .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    HeaderView()
        .environmentObject(CoinManager.shared)
        .environmentObject(CrystalManager.shared)
        .environmentObject(AccountLevelManager.shared)
}
