import Foundation

// MARK: - Species
// Describes a single creature form. Sprite names correspond to PNG assets
// inside the Sprites/ folder (e.g. "baby_blob_idle_0.png").
struct Species: Codable, Identifiable {
    let id: String            // e.g. "child_fighter"
    let name: String          // display name, e.g. "Knucklox"
    let stage: Int            // 0 / 1 / 2
    let spritePrefix: String  // base name for sprite frames, e.g. "child_fighter"
    let frameCount: Int       // number of idle animation frames
    let description: String   // shown on the stats screen

    /// Move pool available to this species in battles.
    let moves: [Move]
}

// MARK: - Move
struct Move: Codable, Identifiable {
    let id: String
    let name: String
    let basePower: Int      // raw damage before attribute scaling
    let accuracy: Int       // 0–100 hit chance
    let attributeBoost: String  // which attribute the attacker's stat scales from
}

// MARK: - Convenience default moves
extension Move {
    static let tackle  = Move(id: "tackle",  name: "Tackle",   basePower: 20, accuracy: 95, attributeBoost: "combat")
    static let scratch = Move(id: "scratch", name: "Scratch",  basePower: 18, accuracy: 100, attributeBoost: "combat")
    static let sprint  = Move(id: "sprint",  name: "Sprint",   basePower: 22, accuracy: 90, attributeBoost: "athleticism")
    static let charm   = Move(id: "charm",   name: "Charm",    basePower: 15, accuracy: 100, attributeBoost: "cuteness")
    static let bite    = Move(id: "bite",    name: "Bite",     basePower: 30, accuracy: 85, attributeBoost: "combat")
    static let blazing = Move(id: "blazing", name: "Blazing Fist", basePower: 40, accuracy: 80, attributeBoost: "combat")
    static let swiftKick = Move(id: "swift_kick", name: "Swift Kick", basePower: 35, accuracy: 90, attributeBoost: "athleticism")
    static let cute_eyes = Move(id: "cute_eyes", name: "Cute Eyes", basePower: 28, accuracy: 95, attributeBoost: "cuteness")
    static let insight   = Move(id: "insight",   name: "Insight",   basePower: 32, accuracy: 88, attributeBoost: "wisdom")
}
