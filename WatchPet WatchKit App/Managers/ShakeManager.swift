import CoreMotion
import Foundation

// MARK: - ShakeManager
// Monitors accelerometer data to detect shake gestures.
// Used for hatching eggs (initial and evolution) by detecting sustained high-G motion.
@MainActor
final class ShakeManager {

    static let shared = ShakeManager()

    private let motionManager = CMMotionManager()

    /// Called on the main actor whenever a qualifying shake is detected.
    var onShakeDetected: (() -> Void)?

    // Shake detection state
    private var consecutiveHighGCount: Int = 0
    private let highGThreshold: Double = 2.5
    private let requiredConsecutive: Int = 3

    // Debounce — minimum seconds between delivered callbacks
    private let debounceInterval: TimeInterval = 0.3
    private var lastShakeTime: Date = .distantPast

    private init() {}

    // MARK: - Start / Stop

    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable,
              !motionManager.isAccelerometerActive else { return }

        motionManager.accelerometerUpdateInterval = 0.1

        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self, let data, error == nil else { return }
            self.processAccelerometerData(data)
        }
    }

    func stopMonitoring() {
        guard motionManager.isAccelerometerActive else { return }
        motionManager.stopAccelerometerUpdates()
        consecutiveHighGCount = 0
    }

    // MARK: - Detection logic

    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let x = data.acceleration.x
        let y = data.acceleration.y
        let z = data.acceleration.z
        let magnitude = sqrt(x * x + y * y + z * z)

        if magnitude > highGThreshold {
            consecutiveHighGCount += 1
        } else {
            consecutiveHighGCount = 0
        }

        if consecutiveHighGCount >= requiredConsecutive {
            consecutiveHighGCount = 0   // reset so it must build up again
            deliverShake()
        }
    }

    private func deliverShake() {
        let now = Date()
        guard now.timeIntervalSince(lastShakeTime) >= debounceInterval else { return }
        lastShakeTime = now
        onShakeDetected?()
    }
}
