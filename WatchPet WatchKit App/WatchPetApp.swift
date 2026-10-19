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
                .onAppear {
                    // Give the AppDelegate a reference so background tasks can update state.
                    appDelegate.petVM = petVM
                }
        }
    }
}

// MARK: - AppDelegate
// Handles background task callbacks and app lifecycle.
final class AppDelegate: NSObject, WKApplicationDelegate {

    // Injected by the app so background tasks can update pet state.
    var petVM: PetViewModel?

    func applicationDidFinishLaunching() {
        BackgroundTaskManager.shared.scheduleNextRefresh()
        Task { await HealthKitManager.shared.requestAuthorization() }
    }

    func applicationWillResignActive() {
        // Stop motion monitoring when the app moves to background to conserve battery.
        Task { @MainActor in
            ShakeManager.shared.stopMonitoring()
        }
    }

    func applicationDidBecomeActive() {
        // Resume monitoring when the app returns to foreground if pet needs shaking.
        Task { @MainActor in
            guard let petVM else { return }
            if petVM.pet.isEgg || petVM.pet.isEvolutionEgg {
                ShakeManager.shared.startMonitoring()
            }
        }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        guard let petVM else {
            for task in backgroundTasks { task.setTaskCompletedWithSnapshot(false) }
            return
        }
        BackgroundTaskManager.shared.handle(backgroundTasks, petViewModel: petVM)
    }
}
