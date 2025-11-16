//
//  ExchangeView.swift
//  Slayken Fighter of Fists
//

import SwiftUI

struct ExchangeView: View {

    // MARK: - Managers
    @EnvironmentObject private var coinManager: CoinManager
    @EnvironmentObject private var crystalManager: CrystalManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - UI State
    @State private var selectedOption: ExchangeOption? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""

    @State private var orbGlow = false
    @State private var orbRotation = 0.0

    // MARK: - Exchange Options
    private let options: [ExchangeOption] = [
        .init(id: "ex1", title: "Convert 1000 Coins → 30 Crystals", coins: 1000, crystals: 30),
        .init(id: "ex2", title: "Convert 5000 Coins → 70 Crystals", coins: 5000, crystals: 70),
        .init(id: "ex3", title: "Convert 10000 Coins → 300 Crystals", coins: 10000, crystals: 300),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // ⭐ BACKGROUND LAYER
                backgroundLayer
                    .ignoresSafeArea()

                VStack(spacing: 28) {

                    headerSection

                    balanceSection

                    exchangeList

                    if selectedOption != nil {
                        confirmButton
                    }

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Exchange")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Exchange", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Background Layer
private extension ExchangeView {
    var backgroundLayer: some View {
        ZStack {

            // 🌑 DARK → BLUE → DARK Gradient
            LinearGradient(
                colors: [
                    .black,
                    Color.white.opacity(0.3),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        }
    }
}



//
// MARK: - UI Components
//
private extension ExchangeView {

    // MARK: Header
    var headerSection: some View {
        VStack(spacing: 4) {
            Text("Crystal Exchange")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text("Convert your coins into rare crystals.")
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: Balance view
    var balanceSection: some View {
        HStack(spacing: 20) {

            balanceCard(title: "Coins", value: coinManager.coins, color: .yellow)

            balanceCard(title: "Crystals", value: crystalManager.crystals, color: .cyan)

        }
        .padding(.horizontal, 24)
    }

    func balanceCard(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text("\(value)")
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(18)
        .shadow(color: color.opacity(0.35), radius: 8)
    }


    // MARK: Exchange list
    var exchangeList: some View {
        VStack(spacing: 16) {
            ForEach(options) { option in
                exchangeOptionRow(option)
                    .onTapGesture {
                        withAnimation(.spring) {
                            selectedOption = option
                        }
                    }
            }
        }
        .padding(.horizontal, 24)
    }

    func exchangeOptionRow(_ option: ExchangeOption) -> some View {

        let isSelected = option.id == selectedOption?.id

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(option.title)
                    .foregroundColor(.white)
                    .font(.headline)

                Text("\(option.coins) Coins → \(option.crystals) Crystals")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.white.opacity(0.16) : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.green.opacity(0.5) : .clear, lineWidth: 2)
        )
        .animation(.easeInOut, value: isSelected)
    }


    // MARK: Confirm Button
    var confirmButton: some View {
        Button {
            performExchange()
        } label: {
            Label("Confirm Exchange", systemImage: "arrow.right.arrow.left")
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.7), radius: 10)
        }
        .padding(.horizontal, 24)
    }
}



//
// MARK: - Logic
//
private extension ExchangeView {

    func performExchange() {
        guard let option = selectedOption else { return }

        if coinManager.coins < option.coins {
            alertMessage = "Not enough coins!"
            showAlert = true
            return
        }

        // Convert
        coinManager.spendCoins(option.coins)
        crystalManager.addCrystals(option.crystals)

        alertMessage = "Successfully exchanged \(option.coins) coins for \(option.crystals) crystals!"
        showAlert = true

        // Reset selection
        withAnimation {
            selectedOption = nil
        }
    }
}


// MARK: - Model
struct ExchangeOption: Identifiable {
    let id: String
    let title: String
    let coins: Int
    let crystals: Int
}




// MARK: - Preview
#Preview {
    ExchangeView()
        .environmentObject(CoinManager.shared)
        .environmentObject(CrystalManager.shared)
        .preferredColorScheme(.dark)
}
