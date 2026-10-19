import Foundation
import WatchConnectivity

// MARK: - WatchConnectivityManager (Watch side)
// Pushes pet state to the iPhone companion and receives store/IAP confirmations.
// Uses two channels:
//   • applicationContext  – fires even when phone is not reachable (best-effort)
//   • sendMessage        – fires immediately when phone IS reachable
final class WatchConnectivityManager: NSObject, WCSessionDelegate {

    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send pet snapshot to iPhone

    /// Call after every save so the phone always has up-to-date data.
    func syncPet(_ pet: VirtualPet) {
        guard WCSession.default.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(pet) else { return }
        let payload: [String: Any] = ["pet": data, "timestamp": Date().timeIntervalSince1970]

        // Always update applicationContext so phone gets it even if not reachable
        try? WCSession.default.updateApplicationContext(payload)

        // Also try immediate message if phone is reachable
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }

    // MARK: - Receive messages from iPhone (store purchases, settings)

    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        // e.g. iPhone just confirmed an IAP; we can credit food/items here
        if let action = message["action"] as? String {
            handlePhoneAction(action, payload: message)
        }
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        if let action = applicationContext["action"] as? String {
            handlePhoneAction(action, payload: applicationContext)
        }
    }

    private func handlePhoneAction(_ action: String, payload: [String: Any]) {
        // Post a notification so PetViewModel can react on the main thread
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .phoneActionReceived,
                object: nil,
                userInfo: payload
            )
        }
    }

    // MARK: - WCSessionDelegate stubs
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
}

extension Notification.Name {
    static let phoneActionReceived = Notification.Name("WatchPet.phoneActionReceived")
}
