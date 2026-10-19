import Foundation

// MARK: - Attributes
struct Attributes: Codable, Equatable {
    var athleticism: Int = 0
    var combat:      Int = 0
    var cleanliness: Int = 0
    var cuteness:    Int = 0
    var wisdom:      Int = 0

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
    var speciesID: String = "baby_flame"
    var stage: Int = 0

    // Core stats (0–100)
    var hunger:           Int = 80
    var happiness:        Int = 80
    var cleanlinessScore: Int = 80
    var health:           Int = 100

    // Battle HP — nil means full HP (for backward-compatible saves)
    var currentHP: Int? = nil

    // Attributes
    var attributes: Attributes = Attributes()

    // Lifetime tracking
    var totalSteps:     Int = 0
    var battleWins:     Int = 0
    var battlesFought:  Int = 0
    var stepsToday:     Int = 0

    // Time tracking
    var lastSaved:    Date = Date()
    var birthDate:    Date = Date()
    var stageStarted: Date = Date()

    // MARK: - Egg / Hatching state
    /// True while the pet hasn't hatched from its initial egg yet.
    var isEgg: Bool = false
    /// Counts shakes accumulated toward the hatch threshold.
    var shakeCount: Int = 0
    /// Number of shakes required to hatch the initial egg.
    var hatchThreshold: Int = 2
    /// True when an evolution has been triggered and the pet is in its between-stage egg form.
    var isEvolutionEgg: Bool = false
    /// Shake count toward cracking the evolution egg (threshold is 15).
    var evolutionEggShakeCount: Int = 0
    /// The speciesID to apply once the evolution egg cracks.
    var pendingEvolutionSpeciesID: String? = nil

    // MARK: - Compendium
    /// IDs of species the player has encountered (their own pet + battled opponents).
    var seenSpeciesIDs: [String] = []

    // MARK: - Sickness
    /// True when the pet is diseased. Stat gains halved; decay 1.5× faster.
    var isSick: Bool = false
    /// Increments every decay cycle when cleanliness is low. Triggers sickness at threshold.
    var sickCounter: Int = 0
    // Threshold is a constant — not persisted, defined here for clarity
    private var sickCounterThreshold: Int { 5 }

    // MARK: Battle HP helpers
    var maxHP: Int { 50 + attributes.combat / 2 }
    /// Current battle HP, defaulting to full when nil.
    var effectiveHP: Int { min(currentHP ?? maxHP, maxHP) }

    // MARK: - Run-away state (anti-cheat + neglect)
    /// True when the pet detected a suspicious time jump (> 7 days) or was fatally neglected.
    var hasRunAway: Bool = false

    // MARK: - Stat decay
    mutating func applyDecay(since date: Date) {
        let rawDelta = date.timeIntervalSince(lastSaved)
        let hours = max(0, rawDelta) / 3600

        // ── Anti-cheat / extreme-neglect guard ──────────────────────────────
        // If the clock jumped forward more than 7 days (168 h), the pet ran away.
        // This prevents clock-skipping exploits and handles true extreme neglect.
        if hours > 168 {
            hasRunAway = true
            health = 0
            lastSaved = date
            return
        }

        // Base decay multiplier when sick
        let sickMult: Double = isSick ? 1.5 : 1.0

        hunger           = max(0, hunger           - Int(5.0 * hours * sickMult))
        happiness        = max(0, happiness        - Int(3.0 * hours * sickMult))
        cleanlinessScore = max(0, cleanlinessScore - Int(2.0 * hours))  // cleanliness decays same rate

        // Health decays faster when both hungry AND unhealthy
        let healthDecayRate: Double
        if hunger < 20 && health < 50 {
            healthDecayRate = 6.0 * sickMult   // 3× base (2.0) when critically hungry + low health
        } else if hunger < 20 {
            healthDecayRate = 2.0 * sickMult
        } else {
            healthDecayRate = isSick ? 1.0 : 0.0
        }
        health = max(0, health - Int(healthDecayRate * hours))

        // Dirty pet sickness progression
        if cleanlinessScore < 20 {
            sickCounter += 1
            if sickCounter >= sickCounterThreshold && !isSick {
                isSick = true
                sickCounter = 0
            }
        } else {
            // Slowly recover counter when clean
            sickCounter = max(0, sickCounter - 1)
        }

        // Passive HP regen: 2 HP per hour while not at full
        if let hp = currentHP {
            let regenAmount = max(1, Int(2.0 * hours))
            let newHP = min(maxHP, hp + regenAmount)
            currentHP = newHP >= maxHP ? nil : newHP
        }

        lastSaved = date
    }

    // MARK: - Care actions
    mutating func feed() {
        let gainMult: Int = isSick ? 1 : 2   // halved when sick
        hunger           = min(100, hunger + 25 * gainMult / 2)
        cleanlinessScore = max(0, cleanlinessScore - 10)
        attributes.cuteness = min(100, attributes.cuteness + (isSick ? 1 : 2))
    }

    mutating func play() {
        let gainMult: Double = isSick ? 0.5 : 1.0
        happiness          = min(100, happiness + Int(20.0 * gainMult))
        hunger             = max(0, hunger - 10)
        attributes.cuteness    = min(100, attributes.cuteness + Int(3.0 * gainMult))
        attributes.athleticism = min(100, attributes.athleticism + Int(1.0 * gainMult))
    }

    mutating func clean() {
        // 50% chance to cure sickness when cleaned while sick
        if isSick, Double.random(in: 0..<1) < 0.5 {
            isSick = false
            sickCounter = 0
        }
        cleanlinessScore       = min(100, cleanlinessScore + 40)
        attributes.cleanliness = min(100, attributes.cleanliness + 5)
    }

    mutating func sleep() {
        let gainMult: Double = isSick ? 0.5 : 1.0
        health    = min(100, health + Int(20.0 * gainMult))
        happiness = min(100, happiness + Int(10.0 * gainMult))
        attributes.wisdom = min(100, attributes.wisdom + Int(4.0 * gainMult))
        // Amplified HP regen from sleep (+20 HP)
        let hp = currentHP ?? maxHP
        let newHP = min(maxHP, hp + 20)
        currentHP = newHP >= maxHP ? nil : newHP
    }

    /// Administer medicine — cures sickness at the cost of a temporary health dip.
    mutating func medicine() {
        guard isSick else { return }
        isSick = false
        sickCounter = 0
        health = max(1, health - 10)    // the cure stings a little
    }

    // MARK: HealthKit update
    mutating func applyStepGain(_ newSteps: Int) {
        let delta = max(0, newSteps - stepsToday)
        stepsToday   = newSteps
        totalSteps  += delta
        let gainMult: Int = isSick ? 1 : 2
        let gain = (delta / 200) * gainMult / 2
        attributes.athleticism = min(100, attributes.athleticism + gain)
        if delta > 0 { happiness = min(100, happiness + 1) }
    }

    // MARK: Battle outcome
    mutating func recordBattle(won: Bool) {
        battlesFought += 1
        // Combat gains halved when pet is unhappy
        let combatGain: Int
        if happiness < 20 {
            combatGain = won ? 2 : 1
        } else {
            combatGain = won ? 5 : 2
        }
        attributes.combat = min(100, attributes.combat + combatGain)
        if won {
            battleWins += 1
            happiness = min(100, happiness + 10)
        }
    }

    // MARK: Helpers
    var isAlive: Bool { health > 0 }
    var age: TimeInterval { Date().timeIntervalSince(birthDate) }
    var timeInStage: TimeInterval { Date().timeIntervalSince(stageStarted) }

    var wellness: Int {
        (hunger + happiness + cleanlinessScore + health) / 4
    }
}
