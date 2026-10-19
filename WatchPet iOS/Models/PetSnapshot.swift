import Foundation

// MARK: - PetSnapshot
// Lightweight mirror of VirtualPet decoded from Watch → Phone WCSession data.
// Only carries fields the phone companion actually needs to display.
struct PetSnapshot: Codable {
    var speciesID: String = "baby_flame"
    var stage: Int = 0
    var hunger: Int = 80
    var happiness: Int = 80
    var cleanlinessScore: Int = 80
    var health: Int = 100
    var totalSteps: Int = 0
    var battleWins: Int = 0
    var battlesFought: Int = 0
    var seenSpeciesIDs: [String] = []
    var isEgg: Bool = true
    var hasRunAway: Bool = false
    var birthDate: Date = Date()

    var wellness: Int { (hunger + happiness + cleanlinessScore + health) / 4 }

    var ageString: String {
        let hours = Int(Date().timeIntervalSince(birthDate) / 3600)
        return hours < 24 ? "\(hours)h" : "\(hours / 24)d"
    }
}
