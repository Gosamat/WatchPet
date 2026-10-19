import SwiftUI
import Combine

// MARK: - EncounterType
enum EncounterType {
    case item, battle
}

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

    // MARK: Egg / shake state
    /// 0.0–1.0 progress toward hatching; drives the UI progress ring.
    @Published var shakeProgress: Double = 0

    // MARK: Digital Crown
    @Published var crownValue: Double = 0

    // MARK: Walk encounter
    @Published var hasEncounter: Bool = false
    @Published var encounterType: EncounterType = .item

    // MARK: Dependencies
    private let persistence  = PersistenceManager.shared
    private let healthKit    = HealthKitManager.shared

    // Track previous steps to detect deltas for encounter checks
    private var previousSteps: Int = 0

    // MARK: Init
    init() {
        // Use a local constant so we can reference the tree before self is fully initialised.
        let tree = EvolutionTree.load()
        evolutionTree = tree

        // If the tree failed to load (empty) wipe any stale save so we start fresh.
        // This guards against a corrupted/missing JSON at runtime.
        if tree.species.isEmpty {
            persistence.reset()
        }

        var loaded = persistence.load() ?? VirtualPet()

        // Guard against stale saves whose speciesID no longer exists in the tree
        // (e.g. old saves before the evolution JSON was updated).
        if tree.species(for: loaded.speciesID) == nil {
            loaded = VirtualPet()   // full reset — species + all stats
        }

        // In DEBUG builds, skip the egg phase entirely so testers see the pet immediately.
        #if DEBUG
        loaded.isEgg          = false
        loaded.isEvolutionEgg = false
        #endif

        pet     = loaded
        species = tree.species(for: loaded.speciesID)
    }

    // MARK: - Lifecycle

    func onAppear() {
        applyTimeDecay()
        fetchHealthKitSteps()
        checkEvolution()
        BackgroundTaskManager.shared.scheduleNextRefresh()
        NotificationManager.shared.requestAuthorization()
        Task { await fetchHeartRate() }

        // Wire up ShakeManager callback and start monitoring
        ShakeManager.shared.onShakeDetected = { [weak self] in
            Task { @MainActor in self?.handleShake() }
        }
        ShakeManager.shared.startMonitoring()

        // Wire AppDelegate so background tasks can reach this VM
        if let delegate = WKApplication.shared().delegate as? AppDelegate {
            delegate.petVM = self
        }
    }

    func onDisappear() {
        ShakeManager.shared.stopMonitoring()
        save()
    }

    // MARK: - Time decay
    func applyTimeDecay() {
        pet.applyDecay(since: Date())
        // If the anti-cheat guard fired (clock skipped), surface it to the UI
        if pet.hasRunAway {
            hasEncounter = false
            pendingEvolution = nil
        }
    }

    // MARK: - HealthKit
    func fetchHealthKitSteps() {
        Task {
            await HealthKitManager.shared.requestAuthorization()
            let steps = await healthKit.fetchTodaySteps()
            checkForEncounter(newSteps: steps, previousSteps: previousSteps)
            previousSteps = steps
            pet.applyStepGain(steps)
            checkEvolution()
        }
    }

    private func fetchHeartRate() async {
        heartRate = await healthKit.fetchLatestHeartRate()
    }

    // MARK: - Walk encounter
    private func checkForEncounter(newSteps: Int, previousSteps: Int) {
        let stepDelta = newSteps - previousSteps
        guard stepDelta > 100 else { return }

        let rolls = stepDelta / 100
        for _ in 0..<rolls {
            if Double.random(in: 0..<1) < 0.15 {
                encounterType = Double.random(in: 0..<1) < 0.5 ? .item : .battle
                hasEncounter = true
                HapticManager.shared.playNotification()
                break
            }
        }
    }

    // MARK: - Care actions
    func feed() {
        pet.feed()
        HapticManager.shared.playClick()
        lastFedDate = Date()   // notify PetFieldView to drop food
        save()
        checkEvolution()
    }

    func play() {
        pet.play()
        HapticManager.shared.playDirectionUp()
        save()
        checkEvolution()
    }

    func clean() {
        pet.clean()
        HapticManager.shared.playRetry()
        lastCleanedDate = Date()   // notify PetFieldView to clear poops
        save()
        checkEvolution()
    }

    func sleep() {
        pet.sleep()
        HapticManager.shared.playStop()
        save()
        checkEvolution()
    }

    /// Administer medicine to cure sickness.
    func giveMedicine() {
        pet.medicine()
        HapticManager.shared.playSuccess()
        save()
    }

    // MARK: - Battle outcome (called by BattleViewModel)
    func recordBattleResult(won: Bool, remainingHP: Int) {
        pet.recordBattle(won: won)
        if won {
            // Keep battle damage — don't restore HP on win
            let newHP = max(1, remainingHP)
            pet.currentHP = newHP >= pet.maxHP ? nil : newHP
        } else {
            // Critically wounded: 1 HP and general health penalty
            pet.currentHP = 1
            pet.health = max(1, pet.health - 15)
        }
        save()
        checkEvolution()
    }

    // MARK: - Shake / Egg hatching

    func handleShake() {
        if pet.isEgg {
            pet.shakeCount += 1
            shakeProgress = Double(pet.shakeCount) / Double(pet.hatchThreshold)
            HapticManager.shared.playClick()
            if pet.shakeCount >= pet.hatchThreshold {
                hatchEgg()
            }
        } else if pet.isEvolutionEgg {
            pet.evolutionEggShakeCount += 1
            shakeProgress = Double(pet.evolutionEggShakeCount) / 2.0
            HapticManager.shared.playClick()
            if pet.evolutionEggShakeCount >= 2 {
                crackEvolutionEgg()
            }
        }
        save()
    }

    private func hatchEgg() {
        pet.isEgg = false
        pet.shakeCount = 0
        shakeProgress = 0
        HapticManager.shared.playSuccess()
        species = evolutionTree.species(for: pet.speciesID)
        discoverSpecies(pet.speciesID)
        save()
    }

    private func crackEvolutionEgg() {
        guard let newSpeciesID = pet.pendingEvolutionSpeciesID else { return }
        pet.isEvolutionEgg = false
        pet.evolutionEggShakeCount = 0
        pet.pendingEvolutionSpeciesID = nil
        shakeProgress = 0
        pet.speciesID = newSpeciesID
        pet.stage = evolutionTree.species(for: newSpeciesID)?.stage ?? pet.stage
        pet.stageStarted = Date()
        species = evolutionTree.species(for: pet.speciesID)
        isEvolving = false
        HapticManager.shared.playSuccess()
        discoverSpecies(newSpeciesID)
        save()
    }

    // MARK: - Compendium discovery
    func discoverSpecies(_ id: String) {
        guard !pet.seenSpeciesIDs.contains(id) else { return }
        pet.seenSpeciesIDs.append(id)
        // Fire a "New Discovery!" notification on the Watch
        if let speciesName = evolutionTree.species(for: id)?.name {
            NotificationManager.shared.scheduleDiscoveryNotification(speciesName: speciesName)
        }
        save()
    }

    // MARK: - Digital Crown interaction

    /// Call from a focusedValue / onChange(of:) on the Digital Crown scroll value.
    /// Every 0.5 units of crown delta adds 1 happiness point (capped per call).
    func handleCrownRotation(delta: Double) {
        let happinessGain = Int(abs(delta) / 0.5)
        guard happinessGain > 0 else { return }
        pet.happiness = min(100, pet.happiness + happinessGain)
        crownPetCount += 1   // notify PetFieldView to show hearts
        HapticManager.shared.playClick()
        save()
    }

    // MARK: - Field events (observed by PetFieldView)
    /// Bumped every time the pet is fed — triggers food-drop animation.
    @Published var lastFedDate: Date     = .distantPast
    /// Bumped every time the pet is cleaned — triggers poop-clear animation.
    @Published var lastCleanedDate: Date = .distantPast
    /// Incremented each Crown-petting threshold — triggers floating hearts.
    @Published var crownPetCount: Int    = 0

    // MARK: - Evolution gate (paywall)
    @Published var showPaywall: Bool = false
    private var evolutionBlockedForPaywall: Bool = false

    // MARK: - Evolution
    private func checkEvolution() {
        guard !isEvolving else { return }

        #if DEBUG
        // ── Debug fast-evo: one feed (hunger 80→100) unlocks evolution.
        // Paywall and all normal conditions are bypassed.
        if pet.hunger > 85,
           let path = evolutionTree.paths.first(where: { $0.fromSpeciesID == pet.speciesID }) {
            pendingEvolution = path
            return
        }
        #endif

        let wasPending = pendingEvolution != nil
        let available = evolutionTree.availableEvolution(for: pet)

        // Gate: Baby → Child (stage 0 → 1) requires full game unlock.
        // Show the paywall exactly once when they first hit the gate.
        if let path = available,
           evolutionTree.species(for: path.toSpeciesID)?.stage == 1,
           !StoreManager.shared.isFullGameUnlocked {
            pendingEvolution = nil
            if !evolutionBlockedForPaywall {
                evolutionBlockedForPaywall = true
                showPaywall = true
                if let name = currentSpecies?.name {
                    NotificationManager.shared.scheduleEvolutionReadyNotification(petName: name)
                }
            }
            return
        }

        pendingEvolution = available
        if !wasPending, available != nil, let name = currentSpecies?.name {
            NotificationManager.shared.scheduleEvolutionReadyNotification(petName: name)
        }
    }

    /// Called by PaywallView after a successful purchase.
    func onFullGamePurchased() {
        evolutionBlockedForPaywall = false
        showPaywall = false
        checkEvolution()
    }

    /// Call when the user confirms (or the app triggers) evolution.
    /// Instead of directly swapping the species, the pet enters an evolution-egg state
    /// that the player cracks open by shaking the watch.
    func triggerEvolution() {
        guard let path = pendingEvolution else { return }
        isEvolving = true
        pendingEvolution = nil

        // Put the pet into its between-stage egg — the player shakes to hatch
        pet.isEvolutionEgg = true
        pet.pendingEvolutionSpeciesID = path.toSpeciesID
        pet.evolutionEggShakeCount = 0
        shakeProgress = 0
        save()
    }

    // MARK: - Persistence
    func save() {
        persistence.save(pet)
        // Keep iPhone companion in sync on every save
        WatchConnectivityManager.shared.syncPet(pet)
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
        shakeProgress = 0
        hasEncounter = false
        previousSteps = 0
    }
}
