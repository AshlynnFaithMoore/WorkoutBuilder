//
//  WorkoutBuilderViewModelTests.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 3/14/26.
//


import Testing
import Foundation
@testable import WorkoutBuilderApp

// MARK: - Helpers
// A reusable exercise we can add to workouts throughout the tests.

private let sampleExercise = Exercise(
    id: "test-001",
    name: "Push-up",
    category: .chest,
    description: "Classic push-up",
    primaryMuscles: ["chest"],
    level: "beginner"
)

private let secondExercise = Exercise(
    id: "test-002",
    name: "Squat",
    category: .legs,
    description: "Bodyweight squat",
    primaryMuscles: ["quadriceps"],
    level: "beginner"
)

struct WorkoutBuilderViewModelTests {

    // MARK: - Starting a New Workout

    @Test func startNewWorkoutSetsCurrentWorkout() {
        // Arrange
        let vm = WorkoutBuilderViewModel()

        // Act
        vm.startNewWorkout(name: "Leg Day")

        // Assert
        #expect(vm.currentWorkout != nil)
        #expect(vm.currentWorkout?.name == "Leg Day")
        #expect(vm.isCreatingWorkout == true)
    }

    @Test func startNewWorkoutBeginsWithNoExercises() {
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Empty Workout")

        #expect(vm.currentWorkout?.exercises.isEmpty == true)
    }

    @Test func startingTwoWorkoutsReplacesTheFirst() {
        // If a user starts a new workout while one is in progress,
        // the second one should replace the first
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "First")
        vm.startNewWorkout(name: "Second")

        #expect(vm.currentWorkout?.name == "Second")
    }

    // MARK: - Adding Exercises

    @Test func addExerciseAppendsToCurrentWorkout() {
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Test Workout")

        vm.addExerciseToCurrentWorkout(sampleExercise)

        #expect(vm.currentWorkout?.exercises.count == 1)
        #expect(vm.currentWorkout?.exercises.first?.exercise.name == "Push-up")
    }

    @Test func addMultipleExercisesPreservesOrder() {
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Test Workout")

        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.addExerciseToCurrentWorkout(secondExercise)

        #expect(vm.currentWorkout?.exercises.count == 2)
        #expect(vm.currentWorkout?.exercises[0].exercise.name == "Push-up")
        #expect(vm.currentWorkout?.exercises[1].exercise.name == "Squat")
    }

    @Test func addExerciseDoesNothingWithNoActiveWorkout() {
        // Shouldn't crash if called before startNewWorkout
        let vm = WorkoutBuilderViewModel()
        vm.addExerciseToCurrentWorkout(sampleExercise)

        #expect(vm.currentWorkout == nil)
    }

    @Test func addedExerciseHasDefaultSetsAndReps() {
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Test")
        vm.addExerciseToCurrentWorkout(sampleExercise)

        let exercise = vm.currentWorkout?.exercises.first
        #expect(exercise?.sets == 3)
        #expect(exercise?.reps == 10)
        #expect(exercise?.duration == 0)
    }

    // MARK: - Removing Exercises

    @Test func removeExerciseDeletesAtCorrectIndex() {
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Test")
        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.addExerciseToCurrentWorkout(secondExercise)

        // Remove the first one
        vm.removeExerciseFromCurrentWorkout(at: 0)

        #expect(vm.currentWorkout?.exercises.count == 1)
        // Squat should now be at index 0
        #expect(vm.currentWorkout?.exercises.first?.exercise.name == "Squat")
    }

    @Test func removeLastExerciseLeavesEmptyList() {
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Test")
        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.removeExerciseFromCurrentWorkout(at: 0)

        #expect(vm.currentWorkout?.exercises.isEmpty == true)
    }

    // MARK: - Updating Exercises

    @Test func updateExerciseChangesCorrectValues() {
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Test")
        vm.addExerciseToCurrentWorkout(sampleExercise)

        vm.updateExerciseInCurrentWorkout(at: 0, sets: 5, reps: 12, duration: 30)

        let exercise = vm.currentWorkout?.exercises.first
        #expect(exercise?.sets == 5)
        #expect(exercise?.reps == 12)
        #expect(exercise?.duration == 30)
    }

    @Test func updateExerciseAtInvalidIndexDoesNotCrash() {
        // Out of bounds index should be silently ignored
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Test")

        // No exercises added, index 0 is out of bounds
        vm.updateExerciseInCurrentWorkout(at: 0, sets: 5, reps: 12, duration: 30)

        #expect(vm.currentWorkout?.exercises.isEmpty == true)
    }

    @Test func updateExerciseOnlyChangesTargetIndex() {
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Test")
        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.addExerciseToCurrentWorkout(secondExercise)

        // Update only the second exercise
        vm.updateExerciseInCurrentWorkout(at: 1, sets: 6, reps: 8, duration: 0)

        // First exercise should be unchanged
        #expect(vm.currentWorkout?.exercises[0].sets == 3)
        // Second exercise should be updated
        #expect(vm.currentWorkout?.exercises[1].sets == 6)
    }

    // MARK: - Saving Workouts

    @Test func saveWorkoutAppendsToSavedWorkouts() {
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Push Day")
        vm.addExerciseToCurrentWorkout(sampleExercise)

        vm.saveCurrentWorkout()

        #expect(vm.savedWorkouts.count == 1)
        #expect(vm.savedWorkouts.first?.name == "Push Day")
    }

    @Test func saveWorkoutClearsCurrentWorkout() {
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Push Day")
        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.saveCurrentWorkout()

        #expect(vm.currentWorkout == nil)
        #expect(vm.isCreatingWorkout == false)
    }

    @Test func saveEmptyWorkoutDoesNotSave() {
        // The Save button is disabled when exercises is empty,
        // but the ViewModel should also handle this defensively
        let vm = WorkoutBuilderViewModel()
        vm.startNewWorkout(name: "Empty")

        // Don't add any exercises, try to save
        vm.saveCurrentWorkout()

        // An empty workout should not be persisted
        #expect(vm.savedWorkouts.isEmpty)
    }

    @Test func canSaveMultipleWorkouts() {
        let vm = WorkoutBuilderViewModel()

        vm.startNewWorkout(name: "Push Day")
        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.saveCurrentWorkout()

        vm.startNewWorkout(name: "Pull Day")
        vm.addExerciseToCurrentWorkout(secondExercise)
        vm.saveCurrentWorkout()

        #expect(vm.savedWorkouts.count == 2)
    }

    // MARK: - Deleting Workouts

    @Test func deleteWorkoutRemovesAtCorrectIndex() {
        let vm = WorkoutBuilderViewModel()

        vm.startNewWorkout(name: "Push Day")
        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.saveCurrentWorkout()

        vm.startNewWorkout(name: "Pull Day")
        vm.addExerciseToCurrentWorkout(secondExercise)
        vm.saveCurrentWorkout()

        vm.deleteWorkout(at: 0)

        #expect(vm.savedWorkouts.count == 1)
        #expect(vm.savedWorkouts.first?.name == "Pull Day")
    }

    // MARK: - Loading a Workout

    @Test func loadWorkoutSetCurrentWorkout() {
        let vm = WorkoutBuilderViewModel()

        vm.startNewWorkout(name: "Push Day")
        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.saveCurrentWorkout()

        // Now load that saved workout back
        let saved = vm.savedWorkouts.first!
        vm.loadWorkout(saved)

        #expect(vm.currentWorkout?.name == "Push Day")
        #expect(vm.isCreatingWorkout == true)
    }

    // MARK: - Filtering

    @Test func clearFiltersResetsAllFilterState() {
        let vm = WorkoutBuilderViewModel()
        vm.selectedCategory = .chest
        vm.selectedEquipment = "barbell"
        vm.selectedLevel = "beginner"
        vm.searchText = "push"

        vm.clearFilters()

        #expect(vm.selectedCategory == nil)
        #expect(vm.selectedEquipment == nil)
        #expect(vm.selectedLevel == nil)
        #expect(vm.searchText == "")
    }
}
