import SwiftUI
import WatchKit

// MARK: - WatchPetApp
@main
struct WatchPetApp: App {

    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var petVM = PetViewModel()

    var body: some Scene {
        WindowGroup {
            MainPetView()
                .environmentObject(petVM)
        }
    }
}

// MARK: - AppDelegate
// Handles background task callbacks and app lifecycle.
final class AppDelegate: NSObject, WKApplicationDelegate {

    // Injected by the app so background tasks can update pet state.
    // Set via the @WKApplicationDelegateAdaptor bridging mechanism.
    var petVM: PetViewModel?

    func applicationDidFinishLaunching() {
        BackgroundTaskManager.shared.scheduleNextRefresh()
        Task { await HealthKitManager.shared.requestAuthorization() }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        guard let petVM else {
            for task in backgroundTasks { task.setTaskCompletedWithSnapshot(false) }
            return
        }
        BackgroundTaskManager.shared.handle(backgroundTasks, petViewModel: petVM)
    }
}
