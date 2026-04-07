//
//  WorkoutBuilderViewModelTests.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 3/14/26.
//


import Testing
import Foundation
import SwiftData
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

// Creates a WorkoutBuilderViewModel backed by an in-memory SwiftData store.
@MainActor
private func makeViewModel() -> WorkoutBuilderViewModel {
    let schema = Schema([Workout.self, WorkoutExercise.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let vm = WorkoutBuilderViewModel()
    vm.configure(with: container.mainContext)
    return vm
}
@Suite(.serialized)
@MainActor
struct WorkoutBuilderViewModelTests {

    // MARK: - Starting a New Workout

    @Test func startNewWorkoutSetsCurrentWorkout() {
        // Arrange
        let vm = makeViewModel()

        // Act
        vm.startNewWorkout(name: "Leg Day")

        // Assert
        #expect(vm.currentWorkout != nil)
        #expect(vm.currentWorkout?.name == "Leg Day")
        #expect(vm.isCreatingWorkout == true)
    }

    @Test func startNewWorkoutBeginsWithNoExercises() {
        let vm = makeViewModel()
        vm.startNewWorkout(name: "Empty Workout")

        #expect(vm.currentWorkout?.exercises.isEmpty == true)
    }

    @Test func startingTwoWorkoutsReplacesTheFirst() {
        // If a user starts a new workout while one is in progress,
        // the second one should replace the first
        let vm = makeViewModel()
        vm.startNewWorkout(name: "First")
        vm.startNewWorkout(name: "Second")

        #expect(vm.currentWorkout?.name == "Second")
    }

    // MARK: - Adding Exercises

    @Test func addExerciseAppendsToCurrentWorkout() {
        let vm = makeViewModel()
        vm.startNewWorkout(name: "Test Workout")

        vm.addExerciseToCurrentWorkout(sampleExercise)

        #expect(vm.currentWorkout?.exercises.count == 1)
        #expect(vm.currentWorkout?.exercises.first?.exercise.name == "Push-up")
    }

    @Test func addMultipleExercisesPreservesOrder() {
        let vm = makeViewModel()
        vm.startNewWorkout(name: "Test Workout")

        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.addExerciseToCurrentWorkout(secondExercise)

        #expect(vm.currentWorkout?.exercises.count == 2)
        #expect(vm.currentWorkout?.exercises[0].exercise.name == "Push-up")
        #expect(vm.currentWorkout?.exercises[1].exercise.name == "Squat")
    }

    @Test func addExerciseDoesNothingWithNoActiveWorkout() {
        // Shouldn't crash if called before startNewWorkout
        let vm = makeViewModel()
        vm.addExerciseToCurrentWorkout(sampleExercise)

        #expect(vm.currentWorkout == nil)
    }

    @Test func addedExerciseHasDefaultSetsAndReps() {
        let vm = makeViewModel()
        vm.startNewWorkout(name: "Test")
        vm.addExerciseToCurrentWorkout(sampleExercise)

        let exercise = vm.currentWorkout?.exercises.first
        #expect(exercise?.sets == 3)
        #expect(exercise?.reps == 10)
        #expect(exercise?.duration == 0)
    }

    // MARK: - Removing Exercises

    @Test func removeExerciseDeletesAtCorrectIndex() {
        let vm = makeViewModel()
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
        let vm = makeViewModel()
        vm.startNewWorkout(name: "Test")
        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.removeExerciseFromCurrentWorkout(at: 0)

        #expect(vm.currentWorkout?.exercises.isEmpty == true)
    }

    // MARK: - Updating Exercises

    @Test func updateExerciseChangesCorrectValues() {
        let vm = makeViewModel()
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
        let vm = makeViewModel()
        vm.startNewWorkout(name: "Test")

        // No exercises added, index 0 is out of bounds
        vm.updateExerciseInCurrentWorkout(at: 0, sets: 5, reps: 12, duration: 30)

        #expect(vm.currentWorkout?.exercises.isEmpty == true)
    }

    @Test func updateExerciseOnlyChangesTargetIndex() {
        let vm = makeViewModel()
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
        let vm = makeViewModel()
        vm.startNewWorkout(name: "Push Day")
        vm.addExerciseToCurrentWorkout(sampleExercise)

        vm.saveCurrentWorkout()

        #expect(vm.savedWorkouts.count == 1)
        #expect(vm.savedWorkouts.first?.name == "Push Day")
    }

    @Test func saveWorkoutClearsCurrentWorkout() {
        let vm = makeViewModel()
        vm.startNewWorkout(name: "Push Day")
        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.saveCurrentWorkout()

        #expect(vm.currentWorkout == nil)
        #expect(vm.isCreatingWorkout == false)
    }

    @Test func saveEmptyWorkoutDoesNotSave() {
        // The Save button is disabled when exercises is empty,
        // but the ViewModel should also handle this defensively
        let vm = makeViewModel()
        vm.startNewWorkout(name: "Empty")

        // Don't add any exercises, try to save
        vm.saveCurrentWorkout()

        // An empty workout should not be persisted
        #expect(vm.savedWorkouts.isEmpty)
    }

    @Test func canSaveMultipleWorkouts() {
        let vm = makeViewModel()

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
        let vm = makeViewModel()

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
        let vm = makeViewModel()

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
        let vm = makeViewModel()
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

    // MARK: - Persistence Round-Trip

    @Test func savedWorkoutsPersistAcrossViewModelInstances() {
        let schema = Schema([Workout.self, WorkoutExercise.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])

        // Save with one ViewModel instance
        let vm1 = WorkoutBuilderViewModel()
        vm1.configure(with: container.mainContext)
        vm1.startNewWorkout(name: "Persisted Workout")
        vm1.addExerciseToCurrentWorkout(sampleExercise)
        vm1.saveCurrentWorkout()

        // Load with a new ViewModel pointing to the same container
        let vm2 = WorkoutBuilderViewModel()
        vm2.configure(with: container.mainContext)

        #expect(vm2.savedWorkouts.count == 1)
        #expect(vm2.savedWorkouts.first?.name == "Persisted Workout")
    }

    // MARK: - Workout Completion

    @Test func completingWorkoutSetsCompletedDate() {
        let vm = makeViewModel()
        vm.startNewWorkout(name: "Workout")
        vm.addExerciseToCurrentWorkout(sampleExercise)
        vm.saveCurrentWorkout()

        let workout = vm.savedWorkouts.first!
        vm.completeWorkout(workout)

        #expect(workout.isCompleted == true)
        #expect(workout.completedDate != nil)
    }
    
    
  // MARK: - Filter Combinations (TEST-6)

      @Test func categoryAndSearchFiltersApplyTogether() {
          let vm = makeViewModel()
          vm.exerciseService.exercises = [
              Exercise(id: "fc-001", name: "Push-up", category: .chest,
                       description: "Chest push-up", primaryMuscles: ["chest"], level: "beginner"),
              Exercise(id: "fc-002", name: "Bench Press", category: .chest,
                       description: "Barbell bench press", primaryMuscles: ["chest"],
                       equipment: ["barbell"], level: "intermediate"),
              Exercise(id: "fc-003", name: "Squat", category: .legs,
                       description: "Bodyweight squat", primaryMuscles: ["quadriceps"], level: "beginner")
          ]
          vm.selectedCategory = .chest
          vm.searchText = "bench"

          let filtered = vm.filteredExercises
          #expect(filtered.count == 1)
          #expect(filtered.first?.name == "Bench Press")
      }

      @Test func categoryAndEquipmentFiltersApplyTogether() {
          let vm = makeViewModel()
          vm.exerciseService.exercises = [
              Exercise(id: "fc-010", name: "Bench Press", category: .chest,
                       description: "Barbell bench press", primaryMuscles: ["chest"],
                       equipment: ["barbell"], level: "intermediate"),
              Exercise(id: "fc-011", name: "Push-up", category: .chest,
                       description: "Bodyweight push-up", primaryMuscles: ["chest"],
                       equipment: ["body only"], level: "beginner"),
              Exercise(id: "fc-012", name: "Barbell Squat", category: .legs,
                       description: "Barbell squat", primaryMuscles: ["quadriceps"],
                       equipment: ["barbell"], level: "intermediate")
          ]
          vm.selectedCategory = .chest
          vm.selectedEquipment = "barbell"

          let filtered = vm.filteredExercises
          #expect(filtered.count == 1)
          #expect(filtered.first?.name == "Bench Press")
      }

      @Test func categoryEquipmentAndLevelFiltersApplyTogether() {
          let vm = makeViewModel()
          vm.exerciseService.exercises = [
              Exercise(id: "fc-020", name: "Easy Bench", category: .chest,
                       description: "Easy bench press", primaryMuscles: ["chest"],
                       equipment: ["barbell"], level: "beginner"),
              Exercise(id: "fc-021", name: "Bench Press", category: .chest,
                       description: "Barbell bench press", primaryMuscles: ["chest"],
                       equipment: ["barbell"], level: "intermediate")
          ]
          vm.selectedCategory = .chest
          vm.selectedEquipment = "barbell"
          vm.selectedLevel = "beginner"

          let filtered = vm.filteredExercises
          #expect(filtered.count == 1)
          #expect(filtered.first?.name == "Easy Bench")
      }

      @Test func allFiltersTogetherNarrowsCorrectly() {
          let vm = makeViewModel()
          vm.exerciseService.exercises = [
              Exercise(id: "fc-030", name: "Beginner Barbell Press", category: .chest,
                       description: "Beginner press", primaryMuscles: ["chest"],
                       equipment: ["barbell"], level: "beginner"),
              Exercise(id: "fc-031", name: "Advanced Barbell Press", category: .chest,
                       description: "Advanced press", primaryMuscles: ["chest"],
                       equipment: ["barbell"], level: "expert"),
              Exercise(id: "fc-032", name: "Beginner Barbell Squat", category: .legs,
                       description: "Beginner squat", primaryMuscles: ["quadriceps"],
                       equipment: ["barbell"], level: "beginner")
          ]
          vm.selectedCategory = .chest
          vm.selectedEquipment = "barbell"
          vm.selectedLevel = "beginner"
          vm.searchText = "press"

          let filtered = vm.filteredExercises
          #expect(filtered.count == 1)
          #expect(filtered.first?.id == "fc-030")
      }

      @Test func noFiltersMatchReturnsEmpty() {
          let vm = makeViewModel()
          vm.exerciseService.exercises = [
              Exercise(id: "fc-040", name: "Push-up", category: .chest,
                       description: "Push-up", primaryMuscles: ["chest"], level: "beginner")
          ]
          vm.selectedCategory = .legs
          vm.searchText = "push"

          let filtered = vm.filteredExercises
          #expect(filtered.isEmpty)
      }
  }




