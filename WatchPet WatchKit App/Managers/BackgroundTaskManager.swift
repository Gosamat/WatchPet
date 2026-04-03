import WatchKit

// MARK: - BackgroundTaskManager
// Schedules periodic background refresh so stat decay runs even when the app is closed.
// watchOS budget is limited — we request ~20-minute intervals and the system honours them
// when it has budget available.
final class BackgroundTaskManager {

    static let shared = BackgroundTaskManager()
    private init() {}

    private let refreshInterval: TimeInterval = 20 * 60  // 20 minutes

    // MARK: Schedule next refresh
    func scheduleNextRefresh() {
        let fireDate = Date().addingTimeInterval(refreshInterval)
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: fireDate,
            userInfo: nil
        ) { error in
            if let error = error {
                print("[BackgroundTaskManager] Schedule error: \(error)")
            }
        }
    }

    // MARK: Handle background task
    // Call from WatchPetApp's handleBackgroundTasks(:).
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>, petViewModel: PetViewModel) {
        for task in backgroundTasks {
            switch task {
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                // Update pet stats for the time elapsed since last save
                petViewModel.applyTimeDecay()
                petViewModel.fetchHealthKitSteps()
                petViewModel.save()

                // Schedule the next refresh
                scheduleNextRefresh()

                refreshTask.setTaskCompletedWithSnapshot(false)

            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                snapshotTask.setTaskCompleted(
                    restoredDefaultState: true,
                    estimatedSnapshotExpiration: Date().addingTimeInterval(refreshInterval),
                    userInfo: nil
                )

            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
