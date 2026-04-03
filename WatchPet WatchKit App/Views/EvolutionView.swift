import SwiftUI

// MARK: - EvolutionView
// Shown as a sheet when pendingEvolution is non-nil.
// Displays both current and incoming forms, lets the user confirm.
struct EvolutionView: View {

    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.03, blue: 0.20).ignoresSafeArea()

            if let path = petVM.pendingEvolution {
                let toSpecies = petVM.evolutionTree.species(for: path.toSpeciesID)

                VStack(spacing: 8) {
                    Text("Evolution!")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.yellow)

                    HStack(spacing: 12) {
                        // Current form
                        VStack(spacing: 3) {
                            if let cur = petVM.currentSpecies {
                                PixelSpriteView(spritePrefix: cur.spritePrefix,
                                                frameCount:   cur.frameCount,
                                                pixelSize:    3)
                                Text(cur.name).speciesLabel()
                            }
                        }

                        Image(systemName: "arrow.right")
                            .foregroundStyle(.yellow)
                            .font(.system(size: 14, weight: .bold))

                        // Evolving into
                        VStack(spacing: 3) {
                            if let next = toSpecies {
                                PixelSpriteView(spritePrefix: next.spritePrefix,
                                                frameCount:   next.frameCount,
                                                pixelSize:    3)
                                    .saturation(petVM.isEvolving ? 1 : 0)
                                    .animation(.easeIn(duration: 0.4), value: petVM.isEvolving)
                                Text(next.name).speciesLabel()
                            } else {
                                Text("???").speciesLabel()
                            }
                        }
                    }

                    if petVM.isEvolving {
                        ProgressView().tint(.yellow)
                    } else {
                        HStack(spacing: 8) {
                            Button("Evolve!") {
                                petVM.triggerEvolution()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.yellow)
                            .foregroundStyle(.black)
                            .font(.system(size: 12, weight: .bold))

                            Button("Later") { dismiss() }
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                .padding(10)
            }
        }
        .onChange(of: petVM.isEvolving) { _, evolving in
            if !evolving { dismiss() }
        }
    }
}

private extension Text {
    func speciesLabel() -> some View {
        self
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.white.opacity(0.8))
    }
}

#Preview {
    EvolutionView().environmentObject(PetViewModel())
}
