import SwiftUI
import Combine

// MARK: - BattleViewModel
@MainActor
final class BattleViewModel: ObservableObject {

    @Published var battle: BattleState?
    @Published var isProcessingAI: Bool = false
    @Published var showResult: Bool = false

    private weak var petVM: PetViewModel?

    init(petVM: PetViewModel) {
        self.petVM = petVM
    }

    // MARK: Start a battle
    func startBattle(against opponentSpecies: Species) {
        guard
            let petVM,
            let playerSpecies = petVM.currentSpecies
        else { return }

        battle = BattleState.make(
            pet: petVM.pet,
            petSpecies: playerSpecies,
            opponentSpecies: opponentSpecies
        )
        petVM.discoverSpecies(opponentSpecies.id)
        showResult = false
    }

    // MARK: Player executes a move
    func playerMove(_ move: Move) {
        guard var b = battle, !b.isOver, b.turn == .player else { return }

        b.executePlayerMove(move)
        battle = b

        if b.isOver {
            finishBattle(state: b)
            return
        }

        // Small delay so the player can read the log before AI responds
        isProcessingAI = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            guard let self else { return }
            self.isProcessingAI = false
            var updated = self.battle!
            updated.executeAIMove()
            self.battle = updated
            if updated.isOver { self.finishBattle(state: updated) }
        }
    }

    // MARK: Resolve outcome
    private func finishBattle(state: BattleState) {
        let won = state.result == .playerWon
        petVM?.recordBattleResult(won: won, remainingHP: state.player.hp)
        showResult = true
    }

    // MARK: Dismiss
    func dismissBattle() {
        battle = nil
        showResult = false
    }

    // MARK: Convenience
    var recentLog: [BattleLogEntry] {
        Array((battle?.log ?? []).suffix(4))
    }
}
