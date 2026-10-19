import SwiftUI

// MARK: - EvolutionView
struct EvolutionView: View {

    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var ringPulse  = false
    @State private var titleGlow  = false
    @State private var arrowBounce = false

    var body: some View {
        ZStack {
            // Full-screen dramatic background
            evolutionBackground

            if let path = petVM.pendingEvolution {
                let toSpecies = petVM.evolutionTree.species(for: path.toSpeciesID)

                VStack(spacing: 6) {

                    // MARK: Pulsing title
                    Text("EVOLUTION!")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.00, green: 0.84, blue: 0.00),
                                         Color(red: 0.00, green: 0.83, blue: 1.00)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .shadow(color: Color(red: 1.00, green: 0.84, blue: 0.00).opacity(titleGlow ? 0.9 : 0.3), radius: titleGlow ? 8 : 3)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                titleGlow = true
                            }
                        }

                    // MARK: Sprite pair with energy rings
                    HStack(spacing: 8) {

                        // Current form
                        VStack(spacing: 3) {
                            ZStack {
                                energyRings(color: Color(red: 0.00, green: 0.83, blue: 1.00))
                                if let cur = petVM.currentSpecies {
                                    PixelSpriteView(spritePrefix: cur.spritePrefix,
                                                    frameCount:   cur.frameCount,
                                                    pixelSize:    3)
                                    .shadow(color: Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.7), radius: 5)
                                }
                            }
                            if let cur = petVM.currentSpecies {
                                Text(cur.name).speciesChip(color: Color(red: 0.00, green: 0.83, blue: 1.00))
                            }
                        }

                        // Arrow
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 1.00, green: 0.84, blue: 0.00),
                                                 Color(red: 0.61, green: 0.35, blue: 0.95)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .scaleEffect(arrowBounce ? 1.25 : 0.95)
                                .animation(.spring(response: 0.4, dampingFraction: 0.5).repeatForever(autoreverses: true), value: arrowBounce)
                                .onAppear { arrowBounce = true }
                        }

                        // Evolving into
                        VStack(spacing: 3) {
                            ZStack {
                                energyRings(color: Color(red: 0.61, green: 0.35, blue: 0.95))
                                if let next = toSpecies {
                                    PixelSpriteView(spritePrefix: next.spritePrefix,
                                                    frameCount:   next.frameCount,
                                                    pixelSize:    3)
                                    .saturation(petVM.isEvolving ? 1 : 0)
                                    .animation(.easeIn(duration: 0.4), value: petVM.isEvolving)
                                    .shadow(color: Color(red: 0.61, green: 0.35, blue: 0.95).opacity(0.7), radius: 5)
                                } else {
                                    Text("???")
                                        .font(.system(size: 14, weight: .black, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }
                            if let next = toSpecies {
                                Text(next.name).speciesChip(color: Color(red: 0.61, green: 0.35, blue: 0.95))
                            } else {
                                Text("???").speciesChip(color: .white.opacity(0.3))
                            }
                        }
                    }

                    // MARK: Actions
                    if petVM.isEvolving {
                        HStack(spacing: 6) {
                            ProgressView().tint(Color(red: 1.00, green: 0.84, blue: 0.00))
                            Text("Evolving…")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color(red: 1.00, green: 0.84, blue: 0.00).opacity(0.8))
                        }
                    } else {
                        HStack(spacing: 8) {
                            // Power-up Evolve button
                            Button {
                                petVM.triggerEvolution()
                            } label: {
                                Text("EVOLVE!")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 12).padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(red: 1.00, green: 0.84, blue: 0.00),
                                                             Color(red: 1.00, green: 0.55, blue: 0.00)],
                                                    startPoint: .leading, endPoint: .trailing
                                                )
                                            )
                                            .shadow(color: Color(red: 1.00, green: 0.84, blue: 0.00).opacity(0.6), radius: 6)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button("Later") { dismiss() }
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.50))
                                .padding(.horizontal, 8).padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                                )
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(10)
            }
        }
        .onChange(of: petVM.isEvolving) { _, evolving in
            if !evolving { dismiss() }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                ringPulse = true
            }
        }
    }

    // MARK: - Background
    private var evolutionBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.02, blue: 0.18),
                         Color(red: 0.02, green: 0.01, blue: 0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Radial violet glow from center
            RadialGradient(
                colors: [Color(red: 0.40, green: 0.10, blue: 0.80).opacity(ringPulse ? 0.28 : 0.10), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 130
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Energy Rings
    private func energyRings(color: Color) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .strokeBorder(
                        color.opacity(ringPulse ? 0.15 : 0.40),
                        lineWidth: 1.2
                    )
                    .frame(
                        width: CGFloat(30 + i * 12),
                        height: CGFloat(30 + i * 12)
                    )
                    .scaleEffect(ringPulse ? 1.0 + CGFloat(i) * 0.05 : 0.85 + CGFloat(i) * 0.05)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(Double(i) * 0.25),
                        value: ringPulse
                    )
            }
        }
        .frame(width: 54, height: 54)
    }
}

// MARK: - Text helpers
private extension Text {
    func speciesChip(color: Color) -> some View {
        self
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 4).padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
                    .overlay(Capsule().strokeBorder(color.opacity(0.35), lineWidth: 1))
            )
    }
}

#Preview {
    EvolutionView().environmentObject(PetViewModel())
}
