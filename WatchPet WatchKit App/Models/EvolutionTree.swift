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

    // Custom decoder so keys with default values (minTimeInStageHours,
    // attributeThresholds) are optional in JSON — Swift's synthesised
    // Codable uses `decode` (not `decodeIfPresent`) for non-Optional stored
    // properties, which throws KeyNotFound and silently kills the whole tree.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        minTimeInStageHours = try c.decodeIfPresent(Double.self,       forKey: .minTimeInStageHours) ?? 4
        minHunger           = try c.decodeIfPresent(Int.self,          forKey: .minHunger)
        minHappiness        = try c.decodeIfPresent(Int.self,          forKey: .minHappiness)
        minCleanliness      = try c.decodeIfPresent(Int.self,          forKey: .minCleanliness)
        minHealth           = try c.decodeIfPresent(Int.self,          forKey: .minHealth)
        minBattleWins       = try c.decodeIfPresent(Int.self,          forKey: .minBattleWins)
        minTotalSteps       = try c.decodeIfPresent(Int.self,          forKey: .minTotalSteps)
        attributeThresholds = try c.decodeIfPresent([String: Int].self, forKey: .attributeThresholds) ?? [:]
    }

    init(minTimeInStageHours: Double = 4,
         minHunger:           Int?   = nil,
         minHappiness:        Int?   = nil,
         minCleanliness:      Int?   = nil,
         minHealth:           Int?   = nil,
         minBattleWins:       Int?   = nil,
         minTotalSteps:       Int?   = nil,
         attributeThresholds: [String: Int] = [:]) {
        self.minTimeInStageHours = minTimeInStageHours
        self.minHunger           = minHunger
        self.minHappiness        = minHappiness
        self.minCleanliness      = minCleanliness
        self.minHealth           = minHealth
        self.minBattleWins       = minBattleWins
        self.minTotalSteps       = minTotalSteps
        self.attributeThresholds = attributeThresholds
    }

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
