import Foundation

// MARK: - Attributes
// Each attribute is 0–100 and drives which evolution form the pet takes.
struct Attributes: Codable, Equatable {
    var athleticism: Int = 0  // gains from steps / active calories
    var combat:      Int = 0  // gains from battles fought/won
    var cleanliness: Int = 0  // gains from the Clean care action
    var cuteness:    Int = 0  // gains from feeding and play
    var wisdom:      Int = 0  // gains from consistent sleep care

    /// Returns the dominant attribute name (used for evolution path selection).
    var dominant: String {
        let map: [(String, Int)] = [
            ("athleticism", athleticism),
            ("combat",      combat),
            ("cleanliness", cleanliness),
            ("cuteness",    cuteness),
            ("wisdom",      wisdom)
        ]
        return map.max(by: { $0.1 < $1.1 })?.0 ?? "cuteness"
    }

    mutating func clamp() {
        athleticism = min(100, max(0, athleticism))
        combat      = min(100, max(0, combat))
        cleanliness = min(100, max(0, cleanliness))
        cuteness    = min(100, max(0, cuteness))
        wisdom      = min(100, max(0, wisdom))
    }
}

// MARK: - VirtualPet
struct VirtualPet: Codable {
    // Identity
    var id: UUID = UUID()
    var speciesID: String = "baby_blob"   // matches Species.id in EvolutionData.json
    var stage: Int = 0                    // 0 = baby, 1 = child, 2 = adult

    // Core stats (0–100)
    var hunger:           Int = 80
    var happiness:        Int = 80
    var cleanlinessScore: Int = 80
    var health:           Int = 100

    // Attributes
    var attributes: Attributes = Attributes()

    // Lifetime tracking
    var totalSteps:     Int = 0
    var battleWins:     Int = 0
    var battlesFought:  Int = 0
    var stepsToday:     Int = 0   // reset each day

    // Time tracking for decay calculation
    var lastSaved:    Date = Date()
    var birthDate:    Date = Date()
    var stageStarted: Date = Date()  // when current stage began

    // MARK: Stat decay
    // Call this every time the app becomes active or a background task fires.
    mutating func applyDecay(since date: Date) {
        let hours = max(0, date.timeIntervalSince(lastSaved)) / 3600

        hunger           = max(0, hunger           - Int(5.0 * hours))
        happiness        = max(0, happiness        - Int(3.0 * hours))
        cleanlinessScore = max(0, cleanlinessScore - Int(2.0 * hours))

        if hunger < 20 {
            health = max(0, health - Int(2.0 * hours))
        }

        lastSaved = date
    }

    // MARK: Care actions
    mutating func feed() {
        hunger           = min(100, hunger + 25)
        cleanlinessScore = max(0, cleanlinessScore - 10)
        attributes.cuteness = min(100, attributes.cuteness + 2)
    }

    mutating func play() {
        happiness        = min(100, happiness + 20)
        hunger           = max(0, hunger - 10)
        attributes.cuteness   = min(100, attributes.cuteness + 3)
        attributes.athleticism = min(100, attributes.athleticism + 1)
    }

    mutating func clean() {
        cleanlinessScore     = min(100, cleanlinessScore + 40)
        attributes.cleanliness = min(100, attributes.cleanliness + 5)
    }

    mutating func sleep() {
        health    = min(100, health + 20)
        happiness = min(100, happiness + 10)
        attributes.wisdom = min(100, attributes.wisdom + 4)
    }

    // MARK: HealthKit update
    mutating func applyStepGain(_ newSteps: Int) {
        let delta = max(0, newSteps - stepsToday)
        stepsToday   = newSteps
        totalSteps  += delta
        let gain = delta / 200  // 1 athleticism per 200 steps
        attributes.athleticism = min(100, attributes.athleticism + gain)
        if delta > 0 { happiness = min(100, happiness + 1) }
    }

    // MARK: Battle outcome
    mutating func recordBattle(won: Bool) {
        battlesFought += 1
        attributes.combat = min(100, attributes.combat + (won ? 5 : 2))
        if won {
            battleWins += 1
            happiness = min(100, happiness + 10)
        }
    }

    // MARK: Helpers
    var isAlive: Bool { health > 0 }
    var age: TimeInterval { Date().timeIntervalSince(birthDate) }
    var timeInStage: TimeInterval { Date().timeIntervalSince(stageStarted) }

    /// Overall wellness score 0–100 used for complication display.
    var wellness: Int {
        (hunger + happiness + cleanlinessScore + health) / 4
    }
}
