import SwiftUI

// MARK: - BattleSetupView
// Entry point for the battle feature. Lets the user start an AI battle
// or wait for a nearby player (future multiplayer via iPhone relay).
struct BattleSetupView: View {

    @EnvironmentObject var petVM: PetViewModel
    @State private var battleVM: BattleViewModel?
    @State private var showBattle = false

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.04, blue: 0.20).ignoresSafeArea()

            VStack(spacing: 10) {
                Text("Battle")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                if let s = petVM.currentSpecies {
                    PixelSpriteView(spritePrefix: s.spritePrefix,
                                    frameCount: s.frameCount,
                                    pixelSize: 3)
                }

                WatchButton(label: "Fight Wild") {
                    startAIBattle()
                }

                Text("Or open iPhone app\nto battle a friend")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            .padding(10)
        }
        .navigationDestination(isPresented: $showBattle) {
            if let vm = battleVM {
                BattleView(battleVM: vm)
                    .environmentObject(petVM)
            }
        }
    }

    private func startAIBattle() {
        guard let opponent = petVM.randomOpponentSpecies() else { return }
        let vm = BattleViewModel(petVM: petVM)
        vm.startBattle(against: opponent)
        battleVM  = vm
        showBattle = true
    }
}
