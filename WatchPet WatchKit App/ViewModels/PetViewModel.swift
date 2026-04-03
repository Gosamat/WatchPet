import SwiftUI
import Combine

// MARK: - PetViewModel
// Central game-logic hub. All UI observes this object.
@MainActor
final class PetViewModel: ObservableObject {

    // MARK: Published state
    @Published var pet: VirtualPet
    @Published var species: Species?
    @Published var evolutionTree: EvolutionTree
    @Published var pendingEvolution: EvolutionPath?   // non-nil when evolution is ready
    @Published var isEvolving: Bool = false
    @Published var heartRate: Double? = nil

    // MARK: Dependencies
    private let persistence  = PersistenceManager.shared
    private let healthKit    = HealthKitManager.shared

    // MARK: Init
    init() {
        evolutionTree = EvolutionTree.load()
        pet = persistence.load() ?? VirtualPet()
        species = evolutionTree.species(for: pet.speciesID)
    }

    // MARK: - Lifecycle

    func onAppear() {
        applyTimeDecay()
        fetchHealthKitSteps()
        checkEvolution()
        BackgroundTaskManager.shared.scheduleNextRefresh()
        Task { await fetchHeartRate() }
    }

    func onDisappear() {
        save()
    }

    // MARK: - Time decay
    // Applies stat decay for the time elapsed since last save.
    func applyTimeDecay() {
        pet.applyDecay(since: Date())
    }

    // MARK: - HealthKit
    func fetchHealthKitSteps() {
        Task {
            await HealthKitManager.shared.requestAuthorization()
            let steps = await healthKit.fetchTodaySteps()
            pet.applyStepGain(steps)
            checkEvolution()
        }
    }

    private func fetchHeartRate() async {
        heartRate = await healthKit.fetchLatestHeartRate()
    }

    // MARK: - Care actions
    func feed()  { pet.feed();  save(); checkEvolution() }
    func play()  { pet.play();  save(); checkEvolution() }
    func clean() { pet.clean(); save(); checkEvolution() }
    func sleep() { pet.sleep(); save(); checkEvolution() }

    // MARK: - Battle outcome (called by BattleViewModel)
    func recordBattleResult(won: Bool) {
        pet.recordBattle(won: won)
        save()
        checkEvolution()
    }

    // MARK: - Evolution
    private func checkEvolution() {
        guard !isEvolving else { return }
        pendingEvolution = evolutionTree.availableEvolution(for: pet)
    }

    /// Call when the user confirms (or the app triggers) evolution.
    func triggerEvolution() {
        guard let path = pendingEvolution else { return }
        isEvolving = true
        pendingEvolution = nil

        // Animate for 2 seconds then apply species change
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self else { return }
            self.pet.speciesID   = path.toSpeciesID
            self.pet.stage       = (self.evolutionTree.species(for: path.toSpeciesID)?.stage) ?? self.pet.stage
            self.pet.stageStarted = Date()
            self.species          = self.evolutionTree.species(for: self.pet.speciesID)
            self.isEvolving       = false
            self.save()
        }
    }

    // MARK: - Persistence
    func save() {
        persistence.save(pet)
    }

    // MARK: - Helpers
    var currentSpecies: Species? {
        evolutionTree.species(for: pet.speciesID)
    }

    func opponentSpecies(for battle: BattleState) -> Species? {
        evolutionTree.species(for: battle.opponent.name)
    }

    /// Returns a random opponent species at the same or nearby stage for an AI battle.
    func randomOpponentSpecies() -> Species? {
        let sameStage = evolutionTree.species.filter { $0.stage == pet.stage && $0.id != pet.speciesID }
        return sameStage.randomElement() ?? evolutionTree.species.first
    }

    // MARK: - New game
    func resetPet() {
        persistence.reset()
        pet = VirtualPet()
        species = evolutionTree.species(for: pet.speciesID)
        pendingEvolution = nil
        isEvolving = false
    }
}
