//
//  HealthKitManager.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 3/16/26.
//


import HealthKit
import Foundation

// HealthKitManager is the single point of contact between
// the app and Apple Health. No other file imports HealthKit directly.
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let store = HKHealthStore()
    
    // Published so the UI can react to authorization state
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    
    // The data types we want to read
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.workoutType()
    ]
    
    // The data types we want to write
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.workoutType()
    ]
    
    // MARK: - Authorization
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run { self.errorMessage = "HealthKit is not available on this device" }
            return
        }
        
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run { self.isAuthorized = true }
        } catch {
            await MainActor.run { self.errorMessage = "HealthKit authorization failed: \(error.localizedDescription)" }
        }
    }
    
    // MARK: - Save Workout
    // Call this when a user marks a workout as complete
    func saveWorkout(
        name: String,
        startDate: Date,
        endDate: Date,
        calories: Double?
    ) async throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        
        try await builder.beginCollection(at: startDate)
        
        // Add calorie sample if we have one
        if let calories = calories, calories > 0 {
            let calorieType = HKQuantityType(.activeEnergyBurned)
            let calorieQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            let calorieSample = HKQuantitySample(
                type: calorieType,
                quantity: calorieQuantity,
                start: startDate,
                end: endDate
            )
            try await builder.addSamples([calorieSample])
        }
        
        try await builder.endCollection(at: endDate)
        try await builder.finishWorkout()
    }
    
    // MARK: - Read Heart Rate
    // Fetches heart rate samples for a given time range (e.g. during a HIIT session)
    func fetchHeartRate(from startDate: Date, to endDate: Date) async -> [HeartRateSample] {
        let type = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let heartRateSamples = (samples as? [HKQuantitySample] ?? []).map {
                    HeartRateSample(
                        date: $0.startDate,
                        bpm: Int($0.quantity.doubleValue(for: .init(from: "count/min")))
                    )
                }
                continuation.resume(returning: heartRateSamples)
            }
            store.execute(query)
        }
    }
    
    // MARK: - Read Step Count
    // Fetches total steps for today
    func fetchTodaySteps() async -> Int {
        let type = HKQuantityType(.stepCount)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let steps = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                continuation.resume(returning: steps)
            }
            store.execute(query)
        }
    }
    
    // MARK: - Read Active Calories
    // Fetches total active calories burned today
    func fetchTodayCalories() async -> Double {
        let type = HKQuantityType(.activeEnergyBurned)
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date())
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let calories = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            store.execute(query)
        }
    }
}

// MARK: - Supporting Types
struct HeartRateSample: Identifiable {
    let id = UUID()
    let date: Date
    let bpm: Int
}