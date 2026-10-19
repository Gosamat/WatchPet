import Foundation
import WatchConnectivity
import Combine

// MARK: - PhoneConnectivityManager (iPhone side)
// Receives pet state from the Watch and exposes it to SwiftUI views.
@MainActor
final class PhoneConnectivityManager: NSObject, ObservableObject {

    static let shared = PhoneConnectivityManager()

    @Published var petSnapshot: PetSnapshot? = nil
    @Published var isWatchReachable: Bool = false
    @Published var lastSyncDate: Date? = nil

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send action to Watch (e.g., after IAP)
    func sendAction(_ action: String, payload: [String: Any] = [:]) {
        var message: [String: Any] = ["action": action]
        message.merge(payload) { _, new in new }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil)
        } else {
            try? WCSession.default.updateApplicationContext(message)
        }
    }

    // MARK: - Decode helper
    private func decodePet(from data: Data) {
        if let snapshot = try? JSONDecoder().decode(PetSnapshot.self, from: data) {
            self.petSnapshot = snapshot
            self.lastSyncDate = Date()
        }
    }
}

// MARK: - WCSessionDelegate
extension PhoneConnectivityManager: WCSessionDelegate {

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any]) {
        guard let data = message["pet"] as? Data else { return }
        Task { @MainActor in self.decodePet(from: data) }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["pet"] as? Data else { return }
        Task { @MainActor in self.decodePet(from: data) }
    }

    // Required on iOS only
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
