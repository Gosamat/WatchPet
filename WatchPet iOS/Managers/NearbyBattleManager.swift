import Foundation
import NearbyInteraction
import WatchConnectivity

// MARK: - NearbyBattleDelegate
protocol NearbyBattleDelegate: AnyObject {
    func didReceiveBattleInvite(from peerID: String)
    func didReceiveOpponentMove(moveID: String)
    func didReceiveBattleResult(opponentWon: Bool)
}

// MARK: - NearbyBattleManager
// Runs on the iPhone companion app.
// 1. Uses NearbyInteraction to detect when another WatchPet user is close (~1 m).
// 2. Sends battle messages to the paired Apple Watch via WatchConnectivity.
//
// Flow:
//   iPhone A (close to B) → NISession detects B is within range
//   → sends "battleInvite" to iPhone B via MultipeerConnectivity/network
//   → iPhone B forwards invite down to Watch B via WatchConnectivity
//   → Watch B user accepts → Watch B sends move → iPhone B relays to iPhone A
//   → iPhone A relays to Watch A → etc.
//
// NOTE: Full Multipeer or server-relay implementation is left as an extension point;
// this file provides the Watch↔iPhone side (WatchConnectivity) and the NI proximity
// detection skeleton.
final class NearbyBattleManager: NSObject, ObservableObject {

    static let shared = NearbyBattleManager()

    weak var delegate: NearbyBattleDelegate?

    // MARK: NearbyInteraction
    private var niSession: NISession?
    @Published var nearbyPeerDistance: Float? = nil   // metres

    // MARK: WatchConnectivity
    private var wcSession: WCSession?

    private override init() {
        super.init()
        setupWatchConnectivity()
    }

    // MARK: - NearbyInteraction

    /// Call this after the remote peer (other iPhone) has shared their discovery token via
    /// your signalling channel (e.g. a simple server endpoint or Multipeer).
    func startProximitySession(with peerToken: NIDiscoveryToken) {
        niSession = NISession()
        niSession?.delegate = self
        let config = NINearbyPeerConfiguration(peerToken: peerToken)
        niSession?.run(config)
    }

    func stopProximitySession() {
        niSession?.invalidate()
        niSession = nil
        nearbyPeerDistance = nil
    }

    /// The local discovery token to share with the remote peer so they can start an NI session.
    var localDiscoveryToken: NIDiscoveryToken? {
        niSession?.discoveryToken
    }

    // MARK: - WatchConnectivity

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        wcSession = WCSession.default
        wcSession?.delegate = self
        wcSession?.activate()
    }

    // MARK: Send battle invite to Watch
    func sendBattleInviteToWatch(opponentName: String) {
        sendToWatch(["type": "battleInvite", "opponentName": opponentName])
    }

    // MARK: Send opponent move to Watch
    func sendOpponentMoveToWatch(moveID: String) {
        sendToWatch(["type": "opponentMove", "moveID": moveID])
    }

    // MARK: Send battle result to Watch
    func sendBattleResultToWatch(opponentWon: Bool) {
        sendToWatch(["type": "battleResult", "opponentWon": opponentWon])
    }

    private func sendToWatch(_ message: [String: Any]) {
        guard let session = wcSession, session.isReachable else { return }
        session.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("[NearbyBattleManager] WC send error: \(error)")
        })
    }
}

// MARK: - NISessionDelegate
extension NearbyBattleManager: NISessionDelegate {

    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let peer = nearbyObjects.first else { return }
        DispatchQueue.main.async {
            self.nearbyPeerDistance = peer.distance
        }
        // Auto-invite if within ~0.8 m
        if let dist = peer.distance, dist < 0.8 {
            // In a real implementation: initiate battle invite via your signalling channel.
            // Here we just notify the delegate with a placeholder peer ID.
            delegate?.didReceiveBattleInvite(from: "nearby_peer")
        }
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        print("[NearbyBattleManager] NI session invalidated: \(error)")
        nearbyPeerDistance = nil
    }
}

// MARK: - WCSessionDelegate
extension NearbyBattleManager: WCSessionDelegate {

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error { print("[NearbyBattleManager] WC activation error: \(error)") }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    // Receive messages from Watch (player moves during multiplayer battle)
    func session(_ session: WCSession,
                 didReceiveMessage message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        switch type {
        case "playerMove":
            if let moveID = message["moveID"] as? String {
                // Relay player's move to the remote iPhone via your signalling channel
                print("[NearbyBattleManager] Player used move: \(moveID)")
            }
        default:
            break
        }
    }
}
