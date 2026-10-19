import Foundation

// MARK: - ItemRarity
enum ItemRarity: String, Codable, CaseIterable {
    case common, uncommon, rare, epic, legendary

    var displayName: String { rawValue.capitalized }

    /// Hex color string for use in UI rendering
    var color: String {
        switch self {
        case .common:    return "#9E9E9E"
        case .uncommon:  return "#4CAF50"
        case .rare:      return "#2196F3"
        case .epic:      return "#9C27B0"
        case .legendary: return "#FFD700"
        }
    }
}

// MARK: - ItemCategory
enum ItemCategory: String, Codable {
    case food, medicine, statBoost, equipment
}

// MARK: - EquipSlot
enum EquipSlot: String, Codable {
    case head, body, accessory
}

// MARK: - ItemEffect
/// All stat deltas that can be applied when a consumable is used or a stat-boost item consumed.
/// Default values are 0/false so older saves remain backward-compatible.
struct ItemEffect: Codable {
    var hungerGain:            Int  = 0
    var happinessGain:         Int  = 0
    var healthGain:            Int  = 0
    var cleanlinessGain:       Int  = 0
    var athleticismBoost:      Int  = 0
    var combatBoost:           Int  = 0
    var cleanlinessAttrBoost:  Int  = 0
    var cutenessBoost:         Int  = 0
    var wisdomBoost:           Int  = 0
    var curesSickness:         Bool = false
    var hpRestore:             Int  = 0
}

// MARK: - EquipVisual
/// The pixel art overlay rendered on top of the creature sprite when an equipment item is equipped.
/// Grid dimensions:
///   head      — 8 wide × 4 tall (anchored above sprite head)
///   body      — 8 wide × 6 tall (overlaid on body)
///   accessory — 8 wide × 3 tall (near eye region)
/// Each cell is either a hex colour string ("#RRGGBB") or "" for transparent.
struct EquipVisual: Codable {
    var slot: EquipSlot
    /// Row-major 2-D grid of hex colour strings; "" = transparent pixel.
    var pixels: [[String]]
}

// MARK: - Item
/// A concrete item instance in the player's inventory.
struct Item: Identifiable, Codable {
    var id: UUID = UUID()
    /// References an `ItemTemplate` in the catalog.
    var templateID: String
    var acquiredDate: Date   = Date()
    var isEquipped: Bool     = false
    var equipSlot: EquipSlot? = nil
}

// MARK: - ItemTemplate
/// The immutable blueprint for an item type.
struct ItemTemplate: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
    var emoji: String
    var category: ItemCategory
    var rarity: ItemRarity
    var effect: ItemEffect
    /// Pixel art overlay — only present for equipment items.
    var visual: EquipVisual?
    /// `true` for consumables (food, medicine, stat boosters); `false` for equipment.
    var isConsumable: Bool
    /// Soft-currency price (coins earned in-game). 0 = not purchasable with coins.
    var shopPriceCoins: Int    = 0
    /// Hard-currency price in the real-money store. 0 = not sold individually.
    var shopPriceReal: Double  = 0
}

// MARK: - ItemCatalog
/// Master list of every item template in the game. Add new entries here only.
struct ItemCatalog {

    // swiftlint:disable line_length
    static let all: [ItemTemplate] = [

        // ── FOOD ─────────────────────────────────────────────────────────────
        ItemTemplate(
            id: "food_basic", name: "Kibble",
            description: "Basic nutrition.",
            emoji: "🥩", category: .food, rarity: .common,
            effect: ItemEffect(hungerGain: 25),
            isConsumable: true, shopPriceCoins: 5
        ),
        ItemTemplate(
            id: "food_berry", name: "Berry",
            description: "A sweet berry.",
            emoji: "🍓", category: .food, rarity: .uncommon,
            effect: ItemEffect(hungerGain: 35, happinessGain: 5),
            isConsumable: true, shopPriceCoins: 12
        ),
        ItemTemplate(
            id: "food_fish", name: "Fish",
            description: "Rich protein.",
            emoji: "🐟", category: .food, rarity: .uncommon,
            effect: ItemEffect(hungerGain: 40, athleticismBoost: 1),
            isConsumable: true, shopPriceCoins: 15
        ),
        ItemTemplate(
            id: "food_cake", name: "Cake",
            description: "A festive treat!",
            emoji: "🎂", category: .food, rarity: .rare,
            effect: ItemEffect(hungerGain: 50, happinessGain: 15, cutenessBoost: 2),
            isConsumable: true, shopPriceCoins: 30
        ),
        ItemTemplate(
            id: "food_elixir", name: "Growth Elixir",
            description: "Boosts all attributes!",
            emoji: "✨", category: .food, rarity: .epic,
            effect: ItemEffect(
                hungerGain: 60, happinessGain: 20,
                athleticismBoost: 3, combatBoost: 3,
                cutenessBoost: 3, wisdomBoost: 3
            ),
            isConsumable: true, shopPriceCoins: 80
        ),

        // ── MEDICINE ─────────────────────────────────────────────────────────
        ItemTemplate(
            id: "medicine_basic", name: "Medicine",
            description: "Cures sickness.",
            emoji: "💊", category: .medicine, rarity: .common,
            effect: ItemEffect(healthGain: 10, curesSickness: true),
            isConsumable: true, shopPriceCoins: 20
        ),
        ItemTemplate(
            id: "medicine_super", name: "Super Med",
            description: "Full heal + cure.",
            emoji: "💉", category: .medicine, rarity: .rare,
            effect: ItemEffect(healthGain: 50, curesSickness: true, hpRestore: 30),
            isConsumable: true, shopPriceCoins: 60
        ),

        // ── STAT BOOSTERS ────────────────────────────────────────────────────
        ItemTemplate(
            id: "boost_combat", name: "Power Shard",
            description: "+5 Combat permanently.",
            emoji: "⚔️", category: .statBoost, rarity: .uncommon,
            effect: ItemEffect(combatBoost: 5),
            isConsumable: true, shopPriceCoins: 40
        ),
        ItemTemplate(
            id: "boost_athlete", name: "Running Shoes",
            description: "+5 Athleticism.",
            emoji: "👟", category: .statBoost, rarity: .uncommon,
            effect: ItemEffect(athleticismBoost: 5),
            isConsumable: true, shopPriceCoins: 40
        ),
        ItemTemplate(
            id: "boost_wisdom", name: "Ancient Scroll",
            description: "+5 Wisdom.",
            emoji: "📜", category: .statBoost, rarity: .rare,
            effect: ItemEffect(wisdomBoost: 5),
            isConsumable: true, shopPriceCoins: 40
        ),

        // ── EQUIPMENT — HEAD SLOT ────────────────────────────────────────────
        ItemTemplate(
            id: "hat_cap", name: "Cap",
            description: "A simple cap.",
            emoji: "🧢", category: .equipment, rarity: .common,
            effect: ItemEffect(cutenessBoost: 2),
            visual: EquipVisual(slot: .head, pixels: [
                ["",         "#3B82F6", "#3B82F6", "#3B82F6", "#3B82F6", "#3B82F6", "#3B82F6", ""],
                ["#3B82F6",  "#3B82F6", "#3B82F6", "#3B82F6", "#3B82F6", "#3B82F6", "#3B82F6", "#3B82F6"],
                ["",         "",        "",        "",        "",        "",        "",        ""],
                ["",         "",        "",        "",        "",        "",        "",        ""],
            ]),
            isConsumable: false, shopPriceCoins: 50
        ),
        ItemTemplate(
            id: "hat_crown", name: "Crown",
            description: "Royalty.",
            emoji: "👑", category: .equipment, rarity: .epic,
            effect: ItemEffect(cutenessBoost: 5, wisdomBoost: 3),
            visual: EquipVisual(slot: .head, pixels: [
                ["#FFD700", "",        "#FFD700", "",        "#FFD700", "",        "#FFD700", ""],
                ["#FFD700", "#FFD700", "#FFD700", "#FFD700", "#FFD700", "#FFD700", "#FFD700", "#FFD700"],
                ["#FFD700", "#FFD700", "#FFD700", "#FFD700", "#FFD700", "#FFD700", "#FFD700", "#FFD700"],
                ["",        "",        "",        "",        "",        "",        "",        ""],
            ]),
            isConsumable: false, shopPriceCoins: 200
        ),
        ItemTemplate(
            id: "hat_helmet", name: "Battle Helm",
            description: "Increases combat.",
            emoji: "⛑️", category: .equipment, rarity: .rare,
            effect: ItemEffect(athleticismBoost: 2, combatBoost: 5),
            visual: EquipVisual(slot: .head, pixels: [
                ["",        "#9E9E9E", "#9E9E9E", "#9E9E9E", "#9E9E9E", "#9E9E9E", "#9E9E9E", ""],
                ["#9E9E9E", "#9E9E9E", "#FF5252", "#9E9E9E", "#9E9E9E", "#FF5252", "#9E9E9E", "#9E9E9E"],
                ["#9E9E9E", "#9E9E9E", "#9E9E9E", "#9E9E9E", "#9E9E9E", "#9E9E9E", "#9E9E9E", "#9E9E9E"],
                ["",        "",        "",        "",        "",        "",        "",        ""],
            ]),
            isConsumable: false, shopPriceCoins: 120
        ),

        // ── EQUIPMENT — BODY SLOT ────────────────────────────────────────────
        ItemTemplate(
            id: "body_cape", name: "Hero Cape",
            description: "A flowing cape.",
            emoji: "🦸", category: .equipment, rarity: .uncommon,
            effect: ItemEffect(happinessGain: 5, combatBoost: 3),
            visual: EquipVisual(slot: .body, pixels: [
                ["",        "",        "#E53935", "#E53935", "#E53935", "#E53935", "",        ""],
                ["",        "#E53935", "#E53935", "#E53935", "#E53935", "#E53935", "#E53935", ""],
                ["",        "#E53935", "",        "",        "",        "",        "#E53935", ""],
                ["",        "#E53935", "",        "",        "",        "",        "#E53935", ""],
                ["",        "",        "#E53935", "",        "",        "#E53935", "",        ""],
                ["",        "",        "",        "",        "",        "",        "",        ""],
            ]),
            isConsumable: false, shopPriceCoins: 80
        ),

        // ── EQUIPMENT — ACCESSORY SLOT ───────────────────────────────────────
        ItemTemplate(
            id: "acc_goggles", name: "Goggles",
            description: "Cool goggles.",
            emoji: "🥽", category: .equipment, rarity: .uncommon,
            effect: ItemEffect(wisdomBoost: 3),
            visual: EquipVisual(slot: .accessory, pixels: [
                ["#424242", "#FFEB3B", "#424242", "#424242", "#FFEB3B", "#424242", "", ""],
                ["#424242", "#424242", "#424242", "#424242", "#424242", "#424242", "", ""],
                ["",        "",        "",        "",        "",        "",        "", ""],
            ]),
            isConsumable: false, shopPriceCoins: 60
        ),
    ]
    // swiftlint:enable line_length

    /// Look up a template by its string ID. Returns nil if not found.
    static func template(for id: String) -> ItemTemplate? {
        all.first { $0.id == id }
    }
}
