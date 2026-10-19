import StoreKit
import Foundation
import Combine

// MARK: - StoreManager
/// "Indie Darling" monetization model:
///   • App is FREE to download
///   • $3.99 one-time unlock gates first evolution (Baby → Child)
///   • Cosmetic-only IAPs ($0.99–$1.99) — zero gameplay effect
/// No subscriptions, no pay-to-win food or stamina systems.
@MainActor
final class StoreManager: ObservableObject {

    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoadingProducts = false
    @Published var lastPurchaseError: String? = nil

    // MARK: - Product IDs (must match App Store Connect)
    enum ProductID {
        // ── Core unlock ──────────────────────────────────────────────────────
        /// One-time $3.99 unlock — removes the evolution gate and unlocks all 12 creatures.
        static let fullGameUnlock   = "com.watchpet.fullgame"

        // ── Cosmetic themes ($0.99 each, purely visual) ──────────────────────
        static let themeGameboy     = "com.watchpet.theme.gameboy"     // Gameboy Green palette
        static let themeVirtualBoy  = "com.watchpet.theme.virtualboy"  // Virtual Boy Red palette
        static let themeOLED        = "com.watchpet.theme.oled"        // Pure OLED Black
        static let themeSakura      = "com.watchpet.theme.sakura"      // Sakura Pink
        static let themeHalloween   = "com.watchpet.theme.halloween"   // Seasonal: Spooky Orange
        static let themeWinter      = "com.watchpet.theme.winter"      // Seasonal: Winter Blue

        static let all: [String] = [
            fullGameUnlock,
            themeGameboy, themeVirtualBoy, themeOLED, themeSakura,
            themeHalloween, themeWinter,
        ]
    }

    // MARK: - Computed helpers
    var isFullGameUnlocked: Bool { purchasedProductIDs.contains(ProductID.fullGameUnlock) }

    func isThemeOwned(_ id: String) -> Bool {
        id == "cyberpunk" || purchasedProductIDs.contains(id)
    }

    func product(for id: String) -> Product? { products.first { $0.id == id } }

    // MARK: - Init
    private init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    // MARK: - Product loading
    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: ProductID.all)
                .sorted { $0.price < $1.price }
        } catch {
            print("[StoreManager] Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        lastPurchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await handlePurchase(productID: transaction.productID)
                    await transaction.finish()
                    return true
                case .unverified(_, let error):
                    lastPurchaseError = "Purchase could not be verified."
                    print("[StoreManager] Unverified: \(error)")
                    return false
                }
            case .pending:
                lastPurchaseError = "Purchase is pending approval."
                return false
            case .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastPurchaseError = "Purchase failed. Please try again."
            return false
        }
    }

    // MARK: - Handle fulfilled purchase
    private func handlePurchase(productID: String) async {
        purchasedProductIDs.insert(productID)

        switch productID {
        case ProductID.fullGameUnlock:
            // Notify PetViewModel to re-check evolution gate
            NotificationCenter.default.post(name: .fullGameUnlocked, object: nil)

        case ProductID.themeGameboy, ProductID.themeVirtualBoy,
             ProductID.themeOLED, ProductID.themeSakura,
             ProductID.themeHalloween, ProductID.themeWinter:
            // Auto-apply newly purchased theme
            await MainActor.run {
                CosmeticsManager.shared.applyTheme(productID)
            }

        default:
            print("[StoreManager] Unhandled productID: \(productID)")
        }
    }

    // MARK: - Restore / entitlement refresh
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.revocationDate == nil {
                purchasedProductIDs.insert(tx.productID)
            }
        }
    }

    func restorePurchases() async {
        do { try await AppStore.sync() } catch {
            print("[StoreManager] Restore error: \(error)")
        }
        await updatePurchasedProducts()
        if isFullGameUnlocked {
            NotificationCenter.default.post(name: .fullGameUnlocked, object: nil)
        }
    }
}

extension Notification.Name {
    static let fullGameUnlocked = Notification.Name("WatchPet.fullGameUnlocked")
}
