import SwiftUI

// MARK: - BattleSetupView
struct BattleSetupView: View {

    @EnvironmentObject var petVM: PetViewModel
    @State private var battleVM:   BattleViewModel?
    @State private var showBattle  = false
    @State private var glowPulse   = false
    @State private var bgPulse     = false

    var body: some View {
        ZStack {
            // Dark battle-prep background
            battlePrepBackground

            VStack(spacing: 10) {

                // MARK: Title
                Text("BATTLE")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.00, green: 0.27, blue: 0.00),
                                     Color(red: 0.80, green: 0.00, blue: 0.60)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(red: 1.00, green: 0.27, blue: 0.00).opacity(glowPulse ? 0.8 : 0.3), radius: glowPulse ? 8 : 3)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            glowPulse = true
                        }
                    }

                // MARK: Pet sprite in glow card
                ZStack {
                    // Pulsing outer ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color(red: 1.00, green: 0.27, blue: 0.00),
                                         Color(red: 0.55, green: 0.36, blue: 0.96)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 68, height: 68)
                        .scaleEffect(glowPulse ? 1.08 : 0.95)
                        .opacity(glowPulse ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowPulse)

                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.10, green: 0.03, blue: 0.20),
                                         Color(red: 0.05, green: 0.01, blue: 0.12)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 58, height: 58)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(red: 1.00, green: 0.27, blue: 0.00).opacity(0.40), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 1.00, green: 0.27, blue: 0.00).opacity(glowPulse ? 0.5 : 0.2), radius: 8)

                    if let s = petVM.currentSpecies {
                        PixelSpriteView(spritePrefix: s.spritePrefix,
                                        frameCount:   s.frameCount,
                                        pixelSize:    3)
                        .shadow(color: Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.5), radius: 4)
                    }
                }

                // MARK: Fight Wild button
                Button {
                    startAIBattle()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10, weight: .black))
                        Text("FIGHT WILD")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.00, green: 0.27, blue: 0.00),
                                     Color(red: 0.60, green: 0.00, blue: 0.50)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .shadow(color: Color(red: 1.00, green: 0.27, blue: 0.00).opacity(0.5), radius: 5)
                }
                .buttonStyle(.plain)
                .disabled(petVM.pet.isEgg || petVM.pet.isEvolutionEgg)
            }
            .padding(10)
        }
        .navigationDestination(isPresented: $showBattle) {
            if let vm = battleVM {
                BattleView(battleVM: vm)
                    .environmentObject(petVM)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                bgPulse = true
            }
        }
    }

    // MARK: - Battle Prep Background
    private var battlePrepBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.02, blue: 0.18),
                         Color(red: 0.02, green: 0.01, blue: 0.08)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 0.50, green: 0.00, blue: 0.20).opacity(bgPulse ? 0.18 : 0.06), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 100
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Start AI Battle
    private func startAIBattle() {
        guard let opponent = petVM.randomOpponentSpecies() else { return }
        let vm = BattleViewModel(petVM: petVM)
        vm.startBattle(against: opponent)
        battleVM   = vm
        showBattle = true
    }
}
