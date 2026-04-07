//
//  IntegrationTests.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 4/6/26.
//

//
//  IntegrationTests.swift
//  WorkoutBuilderAppTests
//
//  Integration tests covering HealthKit flow, sound file loading,
//  network handling, and persistence round-trips.
//

import Testing
import Foundation
import SwiftData
@testable import WorkoutBuilderApp

// MARK: - HealthKit Integration (TEST-2)
// These tests verify the HealthKit integration flow using the public API
// of HealthKitManager without requiring a real device or entitlements.

struct HealthKitIntegrationTests {

    @Test func healthKitManagerIsSingleton() {
        let a = HealthKitManager.shared
        let b = HealthKitManager.shared
        #expect(a === b)
    }

    @Test func fetchHeartRateReturnsEmptyForFutureRange() async {
        // Querying a future date range should return no samples
        let future = Date().addingTimeInterval(86400 * 365)
        let farFuture = future.addingTimeInterval(3600)
        let samples = await HealthKitManager.shared.fetchHeartRate(from: future, to: farFuture)
        #expect(samples.isEmpty)
    }

    @Test func fetchTodayStepsReturnsNonNegative() async {
        // Even without HealthKit authorization, steps should be >= 0, not crash
        let steps = await HealthKitManager.shared.fetchTodaySteps()
        #expect(steps >= 0)
    }

    @Test func fetchTodayCaloriesReturnsNonNegative() async {
        // Same -- should return a safe default, not throw
        let calories = await HealthKitManager.shared.fetchTodayCalories()
        #expect(calories >= 0)
    }
}

// MARK: - Sound File Integration (TEST-2)

struct SoundFileIntegrationTests {

    @Test func allSoundOptionsHaveValidFileNames() {
        for option in HIITSoundOption.allCases {
            if option == .none {
                #expect(option.fileName == nil)
            } else {
                #expect(option.fileName != nil)
                #expect(!option.fileName!.isEmpty)
            }
        }
    }

    @Test func soundFilesExistInBundle() {
        for option in HIITSoundOption.allCases {
            guard let fileName = option.fileName else { continue }
            let url = Bundle.main.url(forResource: fileName, withExtension: "wav")
            #expect(url != nil, "Missing sound file: \(fileName).wav")
        }
    }

    @Test func soundDisplayNamesAreNotEmpty() {
        for option in HIITSoundOption.allCases {
            #expect(!option.displayName.isEmpty)
        }
    }
}

// MARK: - Network Integration (TEST-2)

struct NetworkIntegrationTests {

    @Test func exerciseServiceHandlesTimeoutGracefully() async {
        let session = MockURLSession()
        session.errorToThrow = URLError(.timedOut)
        let service = ExerciseService(session: session)
        await service.fetchExercises()

        #expect(service.errorMessage != nil)
        #expect(!service.exercises.isEmpty) // falls back to bundled data
    }

    @Test func exerciseServiceHandlesMalformedResponseGracefully() async {
        let malformed = Data("{not valid json".utf8)
        let session = MockURLSession(data: malformed, statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()

        #expect(service.errorMessage != nil)
        #expect(!service.exercises.isEmpty) // falls back to bundled data
    }

    @Test func exerciseServiceHandlesHTTP500() async {
        let session = MockURLSession(data: Data(), statusCode: 500)
        let service = ExerciseService(session: session)
        await service.fetchExercises()

        #expect(service.errorMessage != nil)
        #expect(!service.exercises.isEmpty) // falls back to bundled data
    }

    @Test func exerciseServiceHandlesEmptyResponse() async {
        let emptyArray = Data("[]".utf8)
        let session = MockURLSession(data: emptyArray, statusCode: 200)
        let service = ExerciseService(session: session)
        await service.fetchExercises()

        // Empty valid JSON array should result in empty exercises
        #expect(service.exercises.isEmpty)
    }
}

// MARK: - Persistence Round-Trip Integration (TEST-2)

struct PersistenceIntegrationTests {

    @Test func workoutSurvivesFullCRUDCycle() {
        let schema = Schema([Workout.self, WorkoutExercise.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])

        let vm = WorkoutBuilderViewModel()
        vm.configure(with: container.mainContext)

        let exercise = Exercise(
            id: "int-001", name: "Push-up", category: .chest,
            description: "Push-up", primaryMuscles: ["chest"], level: "beginner"
        )

        // Create
        vm.startNewWorkout(name: "Integration Test")
        vm.addExerciseToCurrentWorkout(exercise)
        vm.saveCurrentWorkout()
        #expect(vm.savedWorkouts.count == 1)

        // Read
        let saved = vm.savedWorkouts.first!
        #expect(saved.name == "Integration Test")
        #expect(saved.exercises.count == 1)

        // Update (complete)
        vm.completeWorkout(saved)
        #expect(saved.isCompleted == true)

        // Delete
        vm.deleteWorkout(at: 0)
        #expect(vm.savedWorkouts.isEmpty)
    }

    @Test func multipleWorkoutsWithExercisesPersistCorrectly() {
        let schema = Schema([Workout.self, WorkoutExercise.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])

        let vm = WorkoutBuilderViewModel()
        vm.configure(with: container.mainContext)

        let pushup = Exercise(id: "int-010", name: "Push-up", category: .chest, description: "Push-up")
        let squat = Exercise(id: "int-011", name: "Squat", category: .legs, description: "Squat")

        // Save two workouts
        vm.startNewWorkout(name: "Upper Body")
        vm.addExerciseToCurrentWorkout(pushup)
        vm.saveCurrentWorkout()

        vm.startNewWorkout(name: "Lower Body")
        vm.addExerciseToCurrentWorkout(squat)
        vm.saveCurrentWorkout()

        #expect(vm.savedWorkouts.count == 2)

        // Verify via a fresh ViewModel against the same container
        let vm2 = WorkoutBuilderViewModel()
        vm2.configure(with: container.mainContext)
        #expect(vm2.savedWorkouts.count == 2)

        let names = Set(vm2.savedWorkouts.map { $0.name })
        #expect(names.contains("Upper Body"))
        #expect(names.contains("Lower Body"))
    }

    @Test func cascadeDeleteRemovesExercises() {
        let schema = Schema([Workout.self, WorkoutExercise.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let vm = WorkoutBuilderViewModel()
        vm.configure(with: context)

        let exercise = Exercise(id: "int-020", name: "Push-up", category: .chest, description: "Push-up")
        vm.startNewWorkout(name: "To Delete")
        vm.addExerciseToCurrentWorkout(exercise)
        vm.saveCurrentWorkout()

        // Delete the workout
        vm.deleteWorkout(at: 0)

        // Verify no orphan WorkoutExercise objects remain
        let exerciseDescriptor = FetchDescriptor<WorkoutExercise>()
        let remainingExercises = (try? context.fetch(exerciseDescriptor)) ?? []
        #expect(remainingExercises.isEmpty)
    }
}

// MARK: - Image Cache Integration (TEST-2)

struct ImageCacheIntegrationTests {

    @Test func validURLPassesValidation() {
        let url = URL(string: "https://raw.githubusercontent.com/example/image.png")!
        #expect(ImageCache.isValid(url: url) == true)
    }

    @Test func httpURLFailsValidation() {
        let url = URL(string: "http://raw.githubusercontent.com/example/image.png")!
        #expect(ImageCache.isValid(url: url) == false)
    }

    @Test func unknownHostFailsValidation() {
        let url = URL(string: "https://evil-site.com/malicious.png")!
        #expect(ImageCache.isValid(url: url) == false)
    }

    @Test func clearCacheDoesNotCrash() {
        ImageCache.shared.clearCache()
    }
}

