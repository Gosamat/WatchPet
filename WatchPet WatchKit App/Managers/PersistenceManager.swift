import Foundation

// MARK: - PersistenceManager
// Saves and loads VirtualPet state using UserDefaults.
// The App Group identifier lets the complication and the iOS companion share the same data.
final class PersistenceManager {

    static let shared = PersistenceManager()

    // Replace with your actual App Group ID after configuring it in Xcode Signing & Capabilities.
    private let appGroupID = "group.com.watchpet.app"
    private let petKey     = "virtualPet_v1"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private init() {}

    // MARK: Save
    func save(_ pet: VirtualPet) {
        do {
            let data = try JSONEncoder().encode(pet)
            defaults.set(data, forKey: petKey)
        } catch {
            print("[PersistenceManager] Save failed: \(error)")
        }
    }

    // MARK: Load
    func load() -> VirtualPet? {
        guard let data = defaults.data(forKey: petKey) else { return nil }
        do {
            return try JSONDecoder().decode(VirtualPet.self, from: data)
        } catch {
            print("[PersistenceManager] Load failed: \(error)")
            return nil
        }
    }

    // MARK: Reset (for testing / new game)
    func reset() {
        defaults.removeObject(forKey: petKey)
    }
}
