import SwiftUI
import StoreKit

// MARK: - PaywallView
// Shown when the player's pet is ready to evolve for the first time
// but the full game hasn't been purchased yet.
struct PaywallView: View {

    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreManager.shared

    @State private var isPurchasing = false
    @State private var purchaseSuccess = false
    @State private var glowPulse = false

    private var unlockProduct: Product? {
        store.product(for: StoreManager.ProductID.fullGameUnlock)
    }

    private var priceString: String {
        unlockProduct?.displayPrice ?? "$3.99"
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.04, blue: 0.14),
                         Color(red: 0.08, green: 0.02, blue: 0.16)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {

                    // Evolve teaser
                    evolutionTeaser

                    // Value proposition
                    featureList

                    // CTA
                    purchaseButton

                    // Fine print
                    HStack(spacing: 8) {
                        Button("Restore") {
                            Task { await store.restorePurchases() }
                        }
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.40))

                        Text("·").foregroundStyle(.white.opacity(0.20))

                        Button("Later") { dismiss() }
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.40))
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .onChange(of: store.isFullGameUnlocked) { unlocked in
            if unlocked {
                purchaseSuccess = true
                petVM.onFullGamePurchased()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
            }
        }
    }

    // MARK: - Evolution Teaser
    private var evolutionTeaser: some View {
        ZStack {
            // Glow rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color(red: 0.00, green: 0.83, blue: 1.00),
                                     Color(red: 0.55, green: 0.36, blue: 0.96)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 50 + CGFloat(i) * 14, height: 50 + CGFloat(i) * 14)
                    .opacity(glowPulse ? 0.15 + Double(i) * 0.08 : 0.05)
                    .scaleEffect(glowPulse ? 1.0 : 0.92)
            }

            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.00, green: 0.84, blue: 0.00),
                                 Color(red: 0.00, green: 0.83, blue: 1.00)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .scaleEffect(glowPulse ? 1.12 : 0.92)
        }
        .frame(height: 80)
        .padding(.top, 4)
    }

    // MARK: - Feature list
    private var featureList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EVOLUTION READY")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(Color(red: 0.00, green: 0.83, blue: 1.00))
                .frame(maxWidth: .infinity, alignment: .center)

            Text("\(petVM.currentSpecies?.name ?? "Your pet") is ready to evolve!")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Divider().overlay(Color.white.opacity(0.08)).padding(.vertical, 2)

            ForEach(features, id: \.0) { icon, text in
                HStack(spacing: 6) {
                    Text(icon).font(.system(size: 11))
                    Text(text)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.04, green: 0.08, blue: 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.20), lineWidth: 1)
                )
        }
    }

    private let features: [(String, String)] = [
        ("🐉", "All 12 creature forms unlocked"),
        ("⚔️", "Full Arena & battle progression"),
        ("🔬", "Complete Compendium"),
        ("❤️", "Unlimited lineages — raise forever"),
        ("🚫", "No subscriptions. No pay-to-win."),
    ]

    // MARK: - Purchase button
    private var purchaseButton: some View {
        VStack(spacing: 6) {
            if purchaseSuccess {
                Label("Unlocked!", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(Color(red: 0.22, green: 1.00, blue: 0.08))
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    guard !isPurchasing else { return }
                    if store.isFullGameUnlocked {
                        petVM.onFullGamePurchased()
                        dismiss()
                    } else if let product = unlockProduct {
                        isPurchasing = true
                        Task {
                            await store.purchase(product)
                            isPurchasing = false
                        }
                    }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .scaleEffect(0.7)
                                .frame(height: 18)
                        } else {
                            VStack(spacing: 1) {
                                Text("Unlock Full Game")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                Text(priceString + " · One-time")
                                    .font(.system(size: 9, design: .monospaced))
                                    .opacity(0.80)
                            }
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.00, green: 0.83, blue: 1.00),
                                     Color(red: 0.55, green: 0.36, blue: 0.96)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .shadow(color: Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.4), radius: 6)
                }
                .buttonStyle(.plain)
                .disabled(isPurchasing)
            }

            if let error = store.lastPurchaseError {
                Text(error)
                    .font(.system(size: 8))
                    .foregroundStyle(Color(red: 1.00, green: 0.27, blue: 0.00))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    PaywallView().environmentObject(PetViewModel())
}
