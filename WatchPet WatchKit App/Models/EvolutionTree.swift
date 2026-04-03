import Foundation

// MARK: - EvolutionCondition
// All non-nil fields must be satisfied for evolution to trigger.
struct EvolutionCondition: Codable {
    var minTimeInStageHours: Double = 4      // minimum hours in current stage
    var minHunger:           Int?            // pet must have eaten reasonably well
    var minHappiness:        Int?
    var minCleanliness:      Int?
    var minHealth:           Int?
    var minBattleWins:       Int?
    var minTotalSteps:       Int?

    // Attribute thresholds — all listed keys must meet or exceed their value
    var attributeThresholds: [String: Int] = [:]

    func isSatisfied(by pet: VirtualPet) -> Bool {
        guard pet.timeInStage / 3600 >= minTimeInStageHours else { return false }
        if let v = minHunger,      pet.hunger           < v { return false }
        if let v = minHappiness,   pet.happiness        < v { return false }
        if let v = minCleanliness, pet.cleanlinessScore < v { return false }
        if let v = minHealth,      pet.health           < v { return false }
        if let v = minBattleWins,  pet.battleWins       < v { return false }
        if let v = minTotalSteps,  pet.totalSteps       < v { return false }

        let attrs = pet.attributes
        for (key, threshold) in attributeThresholds {
            let value: Int
            switch key {
            case "athleticism": value = attrs.athleticism
            case "combat":      value = attrs.combat
            case "cleanliness": value = attrs.cleanliness
            case "cuteness":    value = attrs.cuteness
            case "wisdom":      value = attrs.wisdom
            default:            value = 0
            }
            if value < threshold { return false }
        }
        return true
    }
}

// MARK: - EvolutionPath
struct EvolutionPath: Codable {
    let fromSpeciesID: String
    let toSpeciesID:   String
    let condition:     EvolutionCondition
    /// Priority: when multiple paths are satisfied the highest-priority one wins.
    let priority:      Int
}

// MARK: - EvolutionTree
struct EvolutionTree: Codable {
    let species: [Species]
    let paths:   [EvolutionPath]

    func species(for id: String) -> Species? {
        species.first { $0.id == id }
    }

    /// Returns the best available evolution for the pet, or nil if not ready.
    func availableEvolution(for pet: VirtualPet) -> EvolutionPath? {
        paths
            .filter { $0.fromSpeciesID == pet.speciesID && $0.condition.isSatisfied(by: pet) }
            .max(by: { $0.priority < $1.priority })
    }
}

// MARK: - Loading from bundle
extension EvolutionTree {
    static func load() -> EvolutionTree {
        guard
            let url  = Bundle.main.url(forResource: "EvolutionData", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let tree = try? JSONDecoder().decode(EvolutionTree.self, from: data)
        else {
            return EvolutionTree(species: [], paths: [])
        }
        return tree
    }
}
