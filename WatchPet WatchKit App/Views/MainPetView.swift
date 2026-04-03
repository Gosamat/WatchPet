import SwiftUI

// MARK: - MainPetView
// The home screen. Shows the creature, its key stats, and navigation to other screens.
struct MainPetView: View {

    @EnvironmentObject var petVM: PetViewModel
    @State private var showCareMenu  = false
    @State private var showStats     = false
    @State private var showBattle    = false
    @State private var navigateToBattle = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.18),
                             Color(red: 0.10, green: 0.10, blue: 0.30)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 6) {

                    // MARK: Species name + stage badge
                    HStack(spacing: 4) {
                        Text(petVM.currentSpecies?.name ?? "???")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        stageBadge
                    }

                    // MARK: Creature sprite
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 88, height: 88)

                        if petVM.isEvolving {
                            evolutionFlash
                        } else if let s = petVM.currentSpecies {
                            PixelSpriteView(
                                spritePrefix: s.spritePrefix,
                                frameCount:   s.frameCount,
                                pixelSize:    4
                            )
                        }
                    }
                    .onTapGesture { showCareMenu = true }

                    // MARK: Stat bars
                    VStack(spacing: 3) {
                        StatBar(label: "🍖", value: petVM.pet.hunger,           color: .orange)
                        StatBar(label: "😊", value: petVM.pet.happiness,        color: .yellow)
                        StatBar(label: "✨", value: petVM.pet.cleanlinessScore, color: .cyan)
                        StatBar(label: "❤️", value: petVM.pet.health,           color: .red)
                    }

                    // MARK: Action buttons
                    HStack(spacing: 10) {
                        WatchButton(label: "Care") { showCareMenu = true }
                        WatchButton(label: "Fight") { navigateToBattle = true }
                        WatchButton(label: "Stats") { showStats = true }
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 6)
            }
            .navigationDestination(isPresented: $navigateToBattle) {
                BattleSetupView()
                    .environmentObject(petVM)
            }
            .sheet(isPresented: $showCareMenu) {
                CareMenuView().environmentObject(petVM)
            }
            .sheet(isPresented: $showStats) {
                StatsView().environmentObject(petVM)
            }
            .sheet(isPresented: Binding(
                get: { petVM.pendingEvolution != nil && !petVM.isEvolving },
                set: { _ in }
            )) {
                EvolutionView().environmentObject(petVM)
            }
        }
        .onAppear { petVM.onAppear() }
        .onDisappear { petVM.onDisappear() }
    }

    // MARK: Subviews

    private var stageBadge: some View {
        Text(["Baby", "Child", "Adult"][min(petVM.pet.stage, 2)])
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(Color.white.opacity(0.12), in: Capsule())
    }

    private var evolutionFlash: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.4)).scaleEffect(1.3)
            Image(systemName: "sparkles")
                .font(.system(size: 30))
                .foregroundStyle(.yellow)
        }
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: petVM.isEvolving)
    }
}

// MARK: - StatBar
private struct StatBar: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label).font(.system(size: 10))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 5)
            Text("\(value)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 22, alignment: .trailing)
        }
    }
}

// MARK: - WatchButton
struct WatchButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainPetView()
        .environmentObject(PetViewModel())
}
