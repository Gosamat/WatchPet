import Foundation

// MARK: - FoodInventory
/// Tracks the player's daily free-food quota and food item stock.
/// Persisted independently from the main pet save so it survives resets.
struct FoodInventory: Codable {

    // MARK: State
    /// The last date/time free food was refreshed (used to detect day rollover).
    var lastFreeClaimDate: Date? = nil
    /// How many free food items remain today. Resets to `dailyFreeFood` at midnight.
    var freeFoodRemaining: Int  = 5
    /// UUIDs of food `Item` instances currently in the player's inventory.
    var foodItemIDs: [UUID] = []
    /// Set by the "Unlimited Food" one-time IAP. Bypasses the daily cap forever.
    var hasUnlimitedFood: Bool  = false

    // MARK: Constants
    static let dailyFreeFood = 5

    // MARK: Refresh
    /// Resets `freeFoodRemaining` to the daily maximum if calendar day has changed.
    /// Call this before any read of `freeFoodRemaining`.
    mutating func refreshIfNewDay() {
        let cal = Calendar.current
        if let last = lastFreeClaimDate, cal.isDateInToday(last) { return }
        freeFoodRemaining = Self.dailyFreeFood
        lastFreeClaimDate = Date()
    }

    // MARK: Claiming
    /// Attempts to claim one free food charge.
    /// - Returns: `true` if a charge was consumed (or unlimited food is active); `false` if depleted.
    @discardableResult
    mutating func claimFreeFood() -> Bool {
        refreshIfNewDay()
        guard hasUnlimitedFood || freeFoodRemaining > 0 else { return false }
        if !hasUnlimitedFood { freeFoodRemaining -= 1 }
        return true
    }

    // MARK: Computed helpers
    /// Whether the player can claim at least one free food charge right now.
    var canClaim: Bool {
        if hasUnlimitedFood { return true }
        var copy = self
        copy.refreshIfNewDay()
        return copy.freeFoodRemaining > 0
    }

    /// The Date at which `freeFoodRemaining` will next reset (start of tomorrow).
    var nextRefreshDate: Date {
        Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
    }

    /// Formatted time remaining until next refresh, e.g. "3h 42m".
    var timeUntilRefresh: String {
        let seconds = max(0, nextRefreshDate.timeIntervalSinceNow)
        let h = Int(seconds) / 3_600
        let m = (Int(seconds) % 3_600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
