import SwiftUI

// MARK: - CareMenuView
struct CareMenuView: View {

    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var lastAction: String? = nil
    @State private var pulseIndex: Int?    = nil

    var body: some View {
        ZStack {
            // Dark background
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.04, blue: 0.12),
                         Color(red: 0.04, green: 0.02, blue: 0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 6) {
                // Title
                Text("CARE")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(red: 0.00, green: 0.83, blue: 1.00))
                    .shadow(color: Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.5), radius: 4)

                // 2×2 grid
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)],
                    spacing: 6
                ) {
                    CareActionCard(
                        icon: "🍖",
                        label: "Feed",
                        hint: "+\(25) Hunger",
                        gradient: LinearGradient(
                            colors: [Color(red: 1.00, green: 0.55, blue: 0.00),
                                     Color(red: 0.80, green: 0.25, blue: 0.00)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        glowColor: Color(red: 1.00, green: 0.55, blue: 0.00),
                        isPulsing: pulseIndex == 0
                    ) {
                        petVM.feed()
                        flash("Yum!")
                    }

                    CareActionCard(
                        icon: "🎮",
                        label: "Play",
                        hint: "+20 Happy",
                        gradient: LinearGradient(
                            colors: [Color(red: 1.00, green: 0.84, blue: 0.00),
                                     Color(red: 0.80, green: 0.50, blue: 0.00)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        glowColor: Color(red: 1.00, green: 0.84, blue: 0.00),
                        isPulsing: pulseIndex == 1
                    ) {
                        petVM.play()
                        flash("Wheee!")
                    }

                    CareActionCard(
                        icon: "🛁",
                        label: "Clean",
                        hint: "+40 Clean",
                        gradient: LinearGradient(
                            colors: [Color(red: 0.00, green: 0.83, blue: 1.00),
                                     Color(red: 0.00, green: 0.40, blue: 0.70)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        glowColor: Color(red: 0.00, green: 0.83, blue: 1.00),
                        isPulsing: pulseIndex == 2
                    ) {
                        petVM.clean()
                        flash("Squeaky!")
                    }

                    CareActionCard(
                        icon: "💤",
                        label: "Sleep",
                        hint: "+20 Health",
                        gradient: LinearGradient(
                            colors: [Color(red: 0.61, green: 0.35, blue: 0.95),
                                     Color(red: 0.30, green: 0.10, blue: 0.60)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        glowColor: Color(red: 0.61, green: 0.35, blue: 0.95),
                        isPulsing: pulseIndex == 3
                    ) {
                        petVM.sleep()
                        flash("Zzz…")
                    }
                }

                // Flash feedback
                if let msg = lastAction {
                    Text(msg)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.00, green: 0.83, blue: 1.00), Color(red: 0.55, green: 0.36, blue: 0.96)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .shadow(color: Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.7), radius: 5)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(8)
        }
        .onAppear { computePulseIndex() }
    }

    // MARK: - Helpers
    private func flash(_ message: String) {
        withAnimation(.spring(response: 0.3)) { lastAction = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            dismiss()
        }
    }

    /// Highlight the card whose corresponding stat is lowest.
    private func computePulseIndex() {
        let values = [
            petVM.pet.hunger,
            petVM.pet.happiness,
            petVM.pet.cleanlinessScore,
            petVM.pet.health
        ]
        if let minVal = values.min(), let idx = values.firstIndex(of: minVal) {
            pulseIndex = idx
        }
    }
}

// MARK: - CareActionCard
private struct CareActionCard: View {
    let icon:      String
    let label:     String
    let hint:      String
    let gradient:  LinearGradient
    let glowColor: Color
    let isPulsing: Bool
    let action:    () -> Void

    @State private var borderPulse = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(icon).font(.system(size: 24))
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(hint)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradient.opacity(0.20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                glowColor.opacity(isPulsing ? (borderPulse ? 0.85 : 0.30) : 0.20),
                                lineWidth: isPulsing ? 1.5 : 1.0
                            )
                    )
                    .shadow(color: glowColor.opacity(isPulsing ? 0.35 : 0.0), radius: 5)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            if isPulsing {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    borderPulse = true
                }
            }
        }
    }
}

#Preview {
    CareMenuView().environmentObject(PetViewModel())
}
