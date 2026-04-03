import SwiftUI

// MARK: - StatsView
// Shows the pet's attributes, battle record, and total steps.
struct StatsView: View {

    @EnvironmentObject var petVM: PetViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {

                Text("Stats")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Species + description
                if let s = petVM.currentSpecies {
                    Text(s.description)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 4)
                }

                Divider().overlay(Color.white.opacity(0.2))

                // Attributes
                Text("Attributes").sectionHeader()
                AttributeRow(name: "Athleticism", value: petVM.pet.attributes.athleticism, color: .green)
                AttributeRow(name: "Combat",      value: petVM.pet.attributes.combat,      color: .red)
                AttributeRow(name: "Cleanliness", value: petVM.pet.attributes.cleanliness, color: .cyan)
                AttributeRow(name: "Cuteness",    value: petVM.pet.attributes.cuteness,    color: .pink)
                AttributeRow(name: "Wisdom",      value: petVM.pet.attributes.wisdom,      color: .purple)

                Divider().overlay(Color.white.opacity(0.2))

                // Lifetime stats
                Text("Lifetime").sectionHeader()
                InfoRow(label: "Steps",    value: "\(petVM.pet.totalSteps)")
                InfoRow(label: "Battles",  value: "\(petVM.pet.battlesFought)")
                InfoRow(label: "Wins",     value: "\(petVM.pet.battleWins)")
                InfoRow(label: "Age",      value: ageString)

                if let bpm = petVM.heartRate {
                    InfoRow(label: "❤️ BPM", value: String(format: "%.0f", bpm))
                }
            }
            .padding(10)
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.20).ignoresSafeArea())
    }

    private var ageString: String {
        let hours = Int(petVM.pet.age / 3600)
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }
}

// MARK: - Subviews
private struct AttributeRow: View {
    let name:  String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 72, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.75))
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 5)
            Text("\(value)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 22, alignment: .trailing)
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.system(size: 10)).foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value).font(.system(size: 10, weight: .semibold)).foregroundStyle(.white)
        }
    }
}

private extension Text {
    func sectionHeader() -> some View {
        self
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white.opacity(0.45))
            .textCase(.uppercase)
    }
}

#Preview {
    StatsView().environmentObject(PetViewModel())
}
