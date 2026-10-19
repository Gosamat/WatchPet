import Foundation
import Combine

// MARK: - ItemManager
/// Owns and persists the player's item inventory.
/// Handles equipping, using, random drops, and the daily free-food quota.
@MainActor
final class ItemManager: ObservableObject {

    // MARK: Singleton
    static let shared = ItemManager()

    // MARK: Published state
    @Published var inventory:      [Item]         = []
    @Published var foodInventory:  FoodInventory  = FoodInventory()
    @Published var coins:          Int            = 0

    // MARK: Persistence keys
    private let defaults     = UserDefaults(suiteName: "group.com.watchpet.app") ?? .standard
    private let inventoryKey = "itemInventory_v1"
    private let foodKey      = "foodInventory_v1"
    private let coinsKey     = "playerCoins_v1"

    // MARK: Init
    private init() { load() }

    // MARK: - Inventory helpers

    /// All currently equipped items.
    var equippedItems: [Item] { inventory.filter { $0.isEquipped } }

    var equippedHead:      Item? { equippedItems.first { $0.equipSlot == .head } }
    var equippedBody:      Item? { equippedItems.first { $0.equipSlot == .body } }
    var equippedAccessory: Item? { equippedItems.first { $0.equipSlot == .accessory } }

    /// Items grouped by category for display.
    var foodItems:      [Item] { inventory.filter { ItemCatalog.template(for: $0.templateID)?.category == .food } }
    var medicineItems:  [Item] { inventory.filter { ItemCatalog.template(for: $0.templateID)?.category == .medicine } }
    var statBoostItems: [Item] { inventory.filter { ItemCatalog.template(for: $0.templateID)?.category == .statBoost } }
    var equipmentItems: [Item] { inventory.filter { ItemCatalog.template(for: $0.templateID)?.category == .equipment } }

    // MARK: - Adding items

    /// Add a new item instance to the inventory by template ID.
    func addItem(_ templateID: String) {
        let item = Item(templateID: templateID)
        inventory.append(item)
        save()
    }

    /// Award coins to the player.
    func addCoins(_ amount: Int) {
        coins += amount
        save()
    }

    // MARK: - Using consumables

    /// Use a consumable item on the pet.
    /// - Parameters:
    ///   - item: The inventory item to consume.
    ///   - pet:  The `VirtualPet` struct to mutate (inout because it is a value type).
    /// - Returns: `true` if the item was used successfully.
    @discardableResult
    func useItem(_ item: Item, on pet: inout VirtualPet) -> Bool {
        guard let template = ItemCatalog.template(for: item.templateID),
              template.isConsumable else { return false }
        applyEffect(template.effect, to: &pet)
        inventory.removeAll { $0.id == item.id }
        // If it was a food item, also deduct from food inventory tracking
        if template.category == .food {
            foodInventory.foodItemIDs.removeAll { $0 == item.id }
        }
        save()
        return true
    }

    // MARK: - Equipping

    /// Equip an equipment item. Automatically unequips anything in the same slot first.
    func equipItem(_ item: Item) {
        guard let template = ItemCatalog.template(for: item.templateID),
              let slot = template.visual?.slot,
              !template.isConsumable else { return }

        // Unequip any existing item occupying the same slot
        for i in inventory.indices where inventory[i].equipSlot == slot {
            inventory[i].isEquipped = false
            inventory[i].equipSlot  = nil
        }
        // Equip the chosen item
        if let idx = inventory.firstIndex(where: { $0.id == item.id }) {
            inventory[idx].isEquipped = true
            inventory[idx].equipSlot  = slot
        }
        save()
    }

    /// Unequip an equipment item.
    func unequipItem(_ item: Item) {
        guard let idx = inventory.firstIndex(where: { $0.id == item.id }) else { return }
        inventory[idx].isEquipped = false
        inventory[idx].equipSlot  = nil
        save()
    }

    // MARK: - Passive equipment stats
    /// Sum of all combat boosts from currently equipped items (applied during battle).
    var equippedCombatBonus: Int {
        equippedItems.compactMap { ItemCatalog.template(for: $0.templateID)?.effect.combatBoost }.reduce(0, +)
    }
    var equippedAthleticismBonus: Int {
        equippedItems.compactMap { ItemCatalog.template(for: $0.templateID)?.effect.athleticismBoost }.reduce(0, +)
    }
    var equippedCutenessBonus: Int {
        equippedItems.compactMap { ItemCatalog.template(for: $0.templateID)?.effect.cutenessBoost }.reduce(0, +)
    }
    var equippedWisdomBonus: Int {
        equippedItems.compactMap { ItemCatalog.template(for: $0.templateID)?.effect.wisdomBoost }.reduce(0, +)
    }

    // MARK: - Apply effect
    private func applyEffect(_ effect: ItemEffect, to pet: inout VirtualPet) {
        pet.hunger           = min(100, pet.hunger           + effect.hungerGain)
        pet.happiness        = min(100, pet.happiness        + effect.happinessGain)
        pet.health           = min(100, pet.health           + effect.healthGain)
        pet.cleanlinessScore = min(100, pet.cleanlinessScore + effect.cleanlinessGain)

        pet.attributes.athleticism = min(100, pet.attributes.athleticism + effect.athleticismBoost)
        pet.attributes.combat      = min(100, pet.attributes.combat      + effect.combatBoost)
        pet.attributes.cleanliness = min(100, pet.attributes.cleanliness + effect.cleanlinessAttrBoost)
        pet.attributes.cuteness    = min(100, pet.attributes.cuteness    + effect.cutenessBoost)
        pet.attributes.wisdom      = min(100, pet.attributes.wisdom      + effect.wisdomBoost)

        if effect.curesSickness {
            pet.isSick      = false
            pet.sickCounter = 0
        }
        if effect.hpRestore > 0 {
            let current = pet.currentHP ?? pet.maxHP
            let newHP   = min(pet.maxHP, current + effect.hpRestore)
            pet.currentHP = newHP >= pet.maxHP ? nil : newHP
        }
    }

    // MARK: - Random drops

    /// Possible sources for item drops.
    enum DropSource {
        case walking        // 30 % base drop chance
        case battleWin      // 50 % base drop chance
        case battleLoss     // 15 % base drop chance
        case dailyCheckIn   // 100 % — guaranteed one item
    }

    /// Roll for a random item drop.
    /// - Parameter source: What triggered the drop roll.
    /// - Returns: An `ItemTemplate` if the roll succeeded, `nil` if it didn't.
    func rollItemDrop(source: DropSource) -> ItemTemplate? {
        let roll = Double.random(in: 0..<1)
        let dropChance: Double
        switch source {
        case .walking:      dropChance = 0.30
        case .battleWin:    dropChance = 0.50
        case .battleLoss:   dropChance = 0.15
        case .dailyCheckIn: dropChance = 1.00
        }
        guard roll < dropChance else { return nil }

        // Determine rarity based on source
        let rarityRoll = Double.random(in: 0..<1)
        let rarity: ItemRarity
        switch source {
        case .walking:
            rarity = rarityRoll < 0.70 ? .common
                   : rarityRoll < 0.95 ? .uncommon
                   : .rare
        case .battleWin:
            rarity = rarityRoll < 0.50 ? .common
                   : rarityRoll < 0.85 ? .uncommon
                   : rarityRoll < 0.98 ? .rare
                   : .epic
        case .battleLoss:
            rarity = .common
        case .dailyCheckIn:
            rarity = rarityRoll < 0.80 ? .common : .uncommon
        }

        let candidates = ItemCatalog.all.filter { $0.rarity == rarity }
        return candidates.randomElement() ?? ItemCatalog.all.first
    }

    // MARK: - Daily free food

    /// Attempt to claim one daily free food charge.
    /// If successful, adds a "food_basic" kibble to the inventory.
    /// - Returns: `true` if a charge was claimed.
    @discardableResult
    func claimDailyFreeFood() -> Bool {
        guard foodInventory.claimFreeFood() else { return false }
        addItem("food_basic")
        return true
    }

    // MARK: - Persistence

    func save() {
        if let data = try? JSONEncoder().encode(inventory) {
            defaults.set(data, forKey: inventoryKey)
        }
        if let data = try? JSONEncoder().encode(foodInventory) {
            defaults.set(data, forKey: foodKey)
        }
        defaults.set(coins, forKey: coinsKey)
    }

    private func load() {
        if let data  = defaults.data(forKey: inventoryKey),
           let items = try? JSONDecoder().decode([Item].self, from: data) {
            inventory = items
        }
        if let data = defaults.data(forKey: foodKey),
           let food = try? JSONDecoder().decode(FoodInventory.self, from: data) {
            foodInventory = food
        }
        coins = defaults.integer(forKey: coinsKey)
    }
}
