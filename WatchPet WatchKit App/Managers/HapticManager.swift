import WatchKit
import Foundation

// MARK: - HapticManager
// Thin wrapper around WKInterfaceDevice haptic playback.
// All methods are nonisolated so they can be called from any context;
// WKInterfaceDevice.current() is safe to call from any thread on watchOS.
final class HapticManager {

    static let shared = HapticManager()
    private init() {}

    func playSuccess()       { WKInterfaceDevice.current().play(.success) }
    func playFailure()       { WKInterfaceDevice.current().play(.failure) }
    func playClick()         { WKInterfaceDevice.current().play(.click) }
    func playNotification()  { WKInterfaceDevice.current().play(.notification) }
    func playRetry()         { WKInterfaceDevice.current().play(.retry) }
    func playStart()         { WKInterfaceDevice.current().play(.start) }
    func playStop()          { WKInterfaceDevice.current().play(.stop) }
    func playDirectionUp()   { WKInterfaceDevice.current().play(.directionUp) }
    func playDirectionDown() { WKInterfaceDevice.current().play(.directionDown) }
}
