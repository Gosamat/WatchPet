import SwiftUI

// MARK: - BattleView
// Turn-based battle screen.
struct BattleView: View {

    @ObservedObject var battleVM: BattleViewModel
    @EnvironmentObject var petVM: PetViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.02, blue: 0.18).ignoresSafeArea()

            if let battle = battleVM.battle {
                VStack(spacing: 6) {

                    // MARK: HP bars
                    HStack {
                        HPBar(name:    battle.opponent.name,
                              hp:      battle.opponent.hp,
                              maxHP:   battle.opponent.maxHP,
                              color:   .red,
                              leading: false)

                        Text("VS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))

                        HPBar(name:    battle.player.name,
                              hp:      battle.player.hp,
                              maxHP:   battle.player.maxHP,
                              color:   .green,
                              leading: true)
                    }

                    // MARK: Battle log (last 3 entries)
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(battleVM.recentLog) { entry in
                            Text(entry.text)
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(5)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))

                    // MARK: Move buttons / result
                    if battleVM.showResult {
                        resultView(won: battle.result == .playerWon)
                    } else if battle.turn == .player && !battleVM.isProcessingAI {
                        movesGrid(moves: battle.player.moves)
                    } else {
                        ProgressView().tint(.yellow)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(8)
            }
        }
        .navigationTitle("Battle")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Subviews

    private func movesGrid(moves: [Move]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(moves) { move in
                Button(action: { battleVM.playerMove(move) }) {
                    VStack(spacing: 1) {
                        Text(move.name)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("PWR \(move.basePower)")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color.indigo.opacity(0.4), in: RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func resultView(won: Bool) -> some View {
        VStack(spacing: 5) {
            Text(won ? "Victory! 🎉" : "Defeated…")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(won ? .yellow : .red)
            Button("Done") {
                battleVM.dismissBattle()
                dismiss()
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(Color.white.opacity(0.15), in: Capsule())
        }
    }
}

// MARK: - HPBar
private struct HPBar: View {
    let name:    String
    let hp:      Int
    let maxHP:   Int
    let color:   Color
    let leading: Bool

    private var fraction: CGFloat { CGFloat(max(0, hp)) / CGFloat(max(1, maxHP)) }

    var body: some View {
        VStack(alignment: leading ? .leading : .trailing, spacing: 2) {
            Text(name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            GeometryReader { geo in
                ZStack(alignment: leading ? .leading : .trailing) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.8))
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 5)
            Text("\(hp)/\(maxHP)")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let vm = PetViewModel()
    let bvm = BattleViewModel(petVM: vm)
    return BattleView(battleVM: bvm).environmentObject(vm)
}
