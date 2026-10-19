import SwiftUI

// MARK: - StatsView
struct StatsView: View {

    @EnvironmentObject var petVM: PetViewModel
    @ObservedObject private var cosmetics = CosmeticsManager.shared
    @ObservedObject private var store = StoreManager.shared

    var body: some View {
        TabView {
            statsPage
            lifetimePage
            compendiumPage
            themesPage
        }
        .tabViewStyle(.page)
        .background(
            LinearGradient(
                colors: [cosmetics.activeTheme.bgTop, cosmetics.activeTheme.bgBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Page 1: Wellness + Attributes
    private var statsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                wellnessHeader

                if let s = petVM.currentSpecies {
                    Text(s.description)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.60))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 2)
                }

                neonDivider

                sectionLabel("ATTRIBUTES").padding(.top, 2)

                NeonAttributeBar(name: "Athletics",   value: petVM.pet.attributes.athleticism,
                                 color: Color(red: 0.22, green: 1.00, blue: 0.08))
                NeonAttributeBar(name: "Combat",      value: petVM.pet.attributes.combat,
                                 color: Color(red: 1.00, green: 0.27, blue: 0.00))
                NeonAttributeBar(name: "Cleanliness", value: petVM.pet.attributes.cleanliness,
                                 color: Color(red: 0.00, green: 0.83, blue: 1.00))
                NeonAttributeBar(name: "Cuteness",    value: petVM.pet.attributes.cuteness,
                                 color: Color(red: 1.00, green: 0.40, blue: 0.70))
                NeonAttributeBar(name: "Wisdom",      value: petVM.pet.attributes.wisdom,
                                 color: Color(red: 0.61, green: 0.35, blue: 0.95))

                Spacer(minLength: 8)
            }
            .padding(10)
        }
    }

    // MARK: - Page 2: Lifetime Stats
    private var lifetimePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("LIFETIME").padding(.top, 4)

                DataRow(label: "Steps",   value: "\(petVM.pet.totalSteps)",    icon: "figure.walk")
                DataRow(label: "Battles", value: "\(petVM.pet.battlesFought)", icon: "bolt.fill")
                DataRow(label: "Wins",    value: "\(petVM.pet.battleWins)",    icon: "trophy.fill")
                DataRow(label: "Age",     value: ageString,                    icon: "clock.fill")

                if let bpm = petVM.heartRate {
                    DataRow(label: "Heart Rate",
                            value: String(format: "%.0f BPM", bpm),
                            icon: "heart.fill")
                }

                neonDivider.padding(.vertical, 4)

                sectionLabel("MOVES")
                if let moves = petVM.currentSpecies?.moves {
                    ForEach(moves) { move in
                        moveRow(move)
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(10)
        }
    }

    // MARK: - Page 4: Themes
    private var themesPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("THEMES").padding(.top, 4)
                Text("Tap to apply · Buy more on iPhone")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))

                ForEach(CosmeticTheme.all, id: \.id) { theme in
                    let owned = store.isThemeOwned(theme.id)
                    Button {
                        guard owned else { return }
                        cosmetics.applyTheme(theme.id)
                        HapticManager.shared.playClick()
                    } label: {
                        HStack(spacing: 8) {
                            Text(theme.icon).font(.system(size: 14))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(theme.name)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(owned ? .white : .white.opacity(0.35))
                                if cosmetics.activeTheme.id == theme.id {
                                    Text("ACTIVE")
                                        .font(.system(size: 7, weight: .black, design: .monospaced))
                                        .foregroundStyle(theme.accent)
                                }
                            }
                            Spacer()
                            if !owned {
                                Text("$0.99")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.30))
                            } else if cosmetics.activeTheme.id == theme.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(theme.accent)
                                    .font(.system(size: 12))
                            }
                        }
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(cosmetics.activeTheme.id == theme.id
                                      ? theme.accent.opacity(0.12) : Color.white.opacity(0.04))
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(cosmetics.activeTheme.id == theme.id
                                                  ? theme.accent.opacity(0.35) : Color.clear, lineWidth: 1))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!owned)
                }
                Spacer(minLength: 8)
            }
            .padding(10)
        }
    }

    // MARK: - Page 3: Compendium
    private var compendiumPage: some View {
        let allSpecies = petVM.evolutionTree.species.sorted {
            $0.stage == $1.stage ? $0.id < $1.id : $0.stage < $1.stage
        }
        let seen = Set(petVM.pet.seenSpeciesIDs)

        return ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("COMPENDIUM").padding(.top, 4)

                Text("\(seen.count)/\(allSpecies.count) discovered")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                          spacing: 6) {
                    ForEach(allSpecies) { sp in
                        CompendiumCell(species: sp, isDiscovered: seen.contains(sp.id))
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(10)
        }
    }

    // MARK: - Wellness Ring Header
    private var wellnessHeader: some View {
        let wellness = petVM.pet.wellness
        let fraction = CGFloat(wellness) / 100.0

        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 5)
                    .frame(width: 48, height: 48)

                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.00, green: 0.83, blue: 1.00),
                                Color(red: 0.55, green: 0.36, blue: 0.96),
                                Color(red: 0.22, green: 1.00, blue: 0.08)
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 48, height: 48)
                    .shadow(color: Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.5), radius: 4)

                Text("\(wellness)")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(petVM.currentSpecies?.name ?? "???")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.5), radius: 3)

                Text("WELLNESS · \(wellness)%")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.80))

                let stages = ["BABY", "CHILD", "ADULT"]
                Text(stages[min(petVM.pet.stage, 2)])
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.61, green: 0.35, blue: 0.95))
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.61, green: 0.35, blue: 0.95).opacity(0.15))
                            .overlay(Capsule().strokeBorder(Color(red: 0.61, green: 0.35, blue: 0.95).opacity(0.40), lineWidth: 1))
                    )
            }

            Spacer()
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.04, green: 0.08, blue: 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.18), lineWidth: 1)
                )
        }
    }

    // MARK: - Move row
    private func moveRow(_ move: Move) -> some View {
        HStack {
            Text(move.name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.80))
            Spacer()
            Text("PWR \(move.basePower)")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(Color(red: 1.00, green: 0.27, blue: 0.00).opacity(0.80))
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))
    }

    // MARK: - Helpers
    private var ageString: String {
        let hours = Int(petVM.pet.age / 3600)
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }

    private var neonDivider: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear,
                             Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.30),
                             .clear],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(height: 1)
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(Color(red: 0.00, green: 0.83, blue: 1.00))
                .frame(width: 3, height: 10)
                .cornerRadius(1.5)
            Text(text)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.45))
        }
    }
}

// MARK: - CompendiumCell
private struct CompendiumCell: View {
    let species: Species
    let isDiscovered: Bool
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isDiscovered
                                    ? Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.30)
                                    : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )

                if isDiscovered {
                    PixelSpriteView(spritePrefix: species.spritePrefix,
                                    frameCount: species.frameCount,
                                    pixelSize: 2)
                } else {
                    Text("?")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.20))
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            CompendiumDetailView(species: species, isDiscovered: isDiscovered)
        }
    }
}

// MARK: - CompendiumDetailView
private struct CompendiumDetailView: View {
    let species: Species
    let isDiscovered: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if isDiscovered {
                    PixelSpriteView(spritePrefix: species.spritePrefix,
                                    frameCount: species.frameCount,
                                    pixelSize: 4)
                        .padding(.top, 8)
                } else {
                    Text("?")
                        .font(.system(size: 40, weight: .black, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.15))
                        .padding(.top, 8)
                }

                Text(isDiscovered ? species.name : "???")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                let stages = ["Baby", "Child", "Adult"]
                Text(stages[min(species.stage, 2)])
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.61, green: 0.35, blue: 0.95))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.61, green: 0.35, blue: 0.95).opacity(0.15))
                    )

                if isDiscovered {
                    Text(species.description)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.60))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 6)

                    Divider().overlay(Color.white.opacity(0.10))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("MOVES")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                        ForEach(species.moves) { move in
                            HStack {
                                Text(move.name)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.80))
                                Spacer()
                                Text("PWR \(move.basePower)")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundStyle(Color(red: 1.00, green: 0.27, blue: 0.00).opacity(0.80))
                            }
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.04)))
                        }
                    }
                    .padding(.horizontal, 6)
                }

                Spacer(minLength: 8)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.04, blue: 0.10),
                         Color(red: 0.04, green: 0.02, blue: 0.12)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - NeonAttributeBar
private struct NeonAttributeBar: View {
    let name:  String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.75))
                .frame(width: 66, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.07))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.55)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                        .shadow(color: color.opacity(0.4), radius: 2)
                }
            }
            .frame(height: 6)

            Text(String(format: "%02d", value))
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(color.opacity(0.85))
                .frame(width: 22, alignment: .trailing)
        }
    }
}

// MARK: - DataRow
private struct DataRow: View {
    let label: String
    let value: String
    let icon:  String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.70))
                .frame(width: 14)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.60))

            Spacer()

            Text(value)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.04))
        )
    }
}

#Preview {
    StatsView().environmentObject(PetViewModel())
}
