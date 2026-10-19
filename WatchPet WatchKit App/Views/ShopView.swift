import SwiftUI
import StoreKit

// MARK: - ShopView
/// In-app store. Shows the daily free-food claim, coin-purchasable items,
/// and real-money IAP bundles. Optimised for the small watch display.
struct ShopView: View {

    @EnvironmentObject var petVM: PetViewModel
    @ObservedObject private var itemManager  = ItemManager.shared
    @ObservedObject private var storeManager = StoreManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSection: ShopSection = .daily
    @State private var purchaseInProgress = false
    @State private var feedbackMessage: String?

    enum ShopSection: String, CaseIterable {
        case daily  = "Daily"
        case coins  = "Coins"
        case iap    = "Packs"
    }

    // MARK: Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section tabs
                sectionPicker
                    .padding(.horizontal, 4)
                    .padding(.top, 4)

                Divider().background(Color.white.opacity(0.1))

                // Content
                Group {
                    switch selectedSection {
                    case .daily:  dailySection
                    case .coins:  coinShopSection
                    case .iap:    iapSection
                    }
                }
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 12, weight: .semibold))
                }
                ToolbarItem(placement: .confirmationAction) {
                    coinsBadge
                }
            }
            // Feedback banner
            .overlay(alignment: .top) {
                if let msg = feedbackMessage {
                    Text(msg)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.85), in: Capsule())
                        .padding(.top, 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: feedbackMessage)
        }
    }

    // MARK: - Section picker
    private var sectionPicker: some View {
        HStack(spacing: 4) {
            ForEach(ShopSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedSection = section }
                } label: {
                    Text(section.rawValue)
                        .font(.system(size: 10, weight: selectedSection == section ? .bold : .regular))
                        .foregroundStyle(selectedSection == section ? .black : .white.opacity(0.7))
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedSection == section ? Color.yellow : Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Coins badge
    private var coinsBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "circle.fill")
                .foregroundStyle(.yellow)
                .font(.system(size: 8))
            Text("\(itemManager.coins)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.yellow)
        }
    }

    // MARK: - Daily section
    private var dailySection: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Free food card
                dailyFoodCard

                // Daily check-in card
                dailyCheckInCard

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
    }

    private var dailyFoodCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("🥩 Daily Food")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                if itemManager.foodInventory.hasUnlimitedFood {
                    Text("UNLIMITED")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Color.yellow, in: Capsule())
                }
            }

            if itemManager.foodInventory.hasUnlimitedFood {
                Text("You have unlimited food!")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                let food = itemManager.foodInventory
                Text("\(food.freeFoodRemaining)/\(FoodInventory.dailyFreeFood) remaining")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                if food.freeFoodRemaining == 0 {
                    Text("Resets in \(food.timeUntilRefresh)")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }
            }

            Button {
                claimFreeFood()
            } label: {
                Text(itemManager.foodInventory.canClaim ? "Claim Free Food" : "Come back tomorrow!")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        itemManager.foodInventory.canClaim
                            ? LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!itemManager.foodInventory.canClaim)
        }
        .padding(10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private var dailyCheckInCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🎁 Daily Check-In")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
            Text("Open the app once per day for a random item drop.")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)
            Button {
                claimDailyCheckIn()
            } label: {
                Text("Claim Item")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Coin shop section
    private var coinShopSection: some View {
        let coinItems = ItemCatalog.all.filter { $0.shopPriceCoins > 0 }
        return List(coinItems) { template in
            coinShopRow(template)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
        }
        .listStyle(.plain)
    }

    private func coinShopRow(_ template: ItemTemplate) -> some View {
        HStack(spacing: 8) {
            Text(template.emoji).font(.system(size: 20))

            VStack(alignment: .leading, spacing: 1) {
                Text(template.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                Text(template.description)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
            Spacer()

            Button {
                buyCoinItem(template)
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                    Text("\(template.shopPriceCoins)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.yellow)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(itemManager.coins < template.shopPriceCoins)
        }
    }

    // MARK: - IAP section
    private var iapSection: some View {
        Group {
            if storeManager.products.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    if storeManager.isLoadingProducts {
                        ProgressView()
                    } else {
                        Text("Store unavailable")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                        Button("Retry") {
                            Task { await storeManager.loadProducts() }
                        }
                        .font(.system(size: 11))
                    }
                    Spacer()
                }
            } else {
                List {
                    ForEach(storeManager.products) { product in
                        iapRow(product)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                    }
                    Section {
                        Button("Restore Purchases") {
                            Task { await storeManager.restorePurchases() }
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func iapRow(_ product: Product) -> some View {
        let isPurchased = storeManager.purchasedProductIDs.contains(product.id)
        return HStack(spacing: 8) {
            // Icon
            iapIcon(for: product.id)

            // Details
            VStack(alignment: .leading, spacing: 1) {
                Text(product.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                Text(product.description)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(2)
            }
            Spacer()

            // Buy / owned button
            if isPurchased {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 16))
            } else {
                Button {
                    Task { await buyIAPProduct(product) }
                } label: {
                    Text(product.displayPrice)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .disabled(purchaseInProgress)
            }
        }
    }

    @ViewBuilder
    private func iapIcon(for productID: String) -> some View {
        let (emoji, color): (String, Color) = {
            switch productID {
            case StoreManager.ProductID.fullGameUnlock:   return ("🐉", .cyan)
            case StoreManager.ProductID.themeGameboy:     return ("🎮", .green)
            case StoreManager.ProductID.themeVirtualBoy:  return ("🔴", .red)
            case StoreManager.ProductID.themeOLED:        return ("⬛️", .white)
            case StoreManager.ProductID.themeSakura:      return ("🌸", .pink)
            case StoreManager.ProductID.themeHalloween:   return ("🎃", .orange)
            case StoreManager.ProductID.themeWinter:      return ("❄️", .blue)
            default:                                      return ("📦", .gray)
            }
        }()
        Text(emoji)
            .font(.system(size: 20))
            .frame(width: 30, height: 30)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Actions

    private func claimFreeFood() {
        let claimed = itemManager.claimDailyFreeFood()
        if claimed {
            showFeedback("Kibble added to bag!")
        }
    }

    private func claimDailyCheckIn() {
        if let drop = itemManager.rollItemDrop(source: .dailyCheckIn) {
            itemManager.addItem(drop.id)
            showFeedback("Got \(drop.emoji) \(drop.name)!")
        }
    }

    private func buyCoinItem(_ template: ItemTemplate) {
        guard itemManager.coins >= template.shopPriceCoins else { return }
        itemManager.coins -= template.shopPriceCoins
        itemManager.addItem(template.id)
        showFeedback("Bought \(template.name)!")
    }

    private func buyIAPProduct(_ product: Product) async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        let success = await storeManager.purchase(product)
        if success {
            showFeedback("Purchase complete!")
        } else if let err = storeManager.lastPurchaseError {
            showFeedback(err)
        }
    }

    private func showFeedback(_ message: String) {
        feedbackMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            feedbackMessage = nil
        }
    }
}

#Preview {
    ShopView()
        .environmentObject(PetViewModel())
}
