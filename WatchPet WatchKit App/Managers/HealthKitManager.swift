import HealthKit
import Foundation

// MARK: - HealthKitManager
// Queries HealthKit for today's step count and active energy.
// All reads are done lazily (on app launch / background refresh) — no continuous polling.
@MainActor
final class HealthKitManager {

    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private init() {}

    // MARK: Authorization
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let types: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        do {
            try await store.requestAuthorization(toShare: [], read: types)
        } catch {
            print("[HealthKitManager] Auth error: \(error)")
        }
    }

    // MARK: Today's steps
    func fetchTodaySteps() async -> Int {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            store.execute(query)
        }
    }

    // MARK: Today's active energy (kcal)
    func fetchTodayActiveCalories() async -> Double {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let kcal = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: kcal)
            }
            store.execute(query)
        }
    }

    // MARK: Latest heart rate (BPM) — cosmetic only
    func fetchLatestHeartRate() async -> Double? {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return nil }

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: hrType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                continuation.resume(returning: bpm)
            }
            store.execute(query)
        }
    }
}
