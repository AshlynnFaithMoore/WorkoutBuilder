//
//  WorkoutViewModel.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/21/25.
//


// WorkoutBuilderViewModel.swift
// ViewModel file - Contains business logic and state management

import Foundation
import SwiftUI

class WorkoutBuilderViewModel: ObservableObject {
    @Published var exerciseService = ExerciseService()
    @Published var currentWorkout: Workout?
    @Published var savedWorkouts: [Workout] = []
    @Published var isCreatingWorkout = false
    @Published var selectedCategory: ExerciseCategory?
    @Published var selectedEquipment: String?
    @Published var selectedLevel: String?
    @Published var searchText = ""
    
    init() {
            loadWorkoutsFromUserDefaults()
        }
        
        // Computed property to get available exercises
        var availableExercises: [Exercise] {
            return exerciseService.exercises
        }
    // Computed property to filter exercises by category
    var filteredExercises: [Exercise] {
        if let category = selectedCategory {
            return availableExercises.filter { $0.category == category }
        }
        return availableExercises
    }
    
    if !searchText.isEmpty {
            filtered = exerciseService.search(query: searchText)
            }
            
            // Apply category filter
            if let category = selectedCategory {
                filtered = filtered.filter { $0.category == category }
            }
            
            // Apply equipment filter
                if; let equipment = selectedEquipment {
                filtered = filtered.filter { $0.equipment.contains(equipment) }
            }
            
            // Apply level filter
                if; let level = selectedLevel {
                filtered = filtered.filter { $0.level.lowercased() == level.lowercased() }
            }
            
            return filtered
        }    // MARK: - Workout Management
    func startNewWorkout(name: String) {
        currentWorkout = Workout(name: name)
        isCreatingWorkout = true
    }
    
    func addExerciseToCurrentWorkout(_ exercise: Exercise) {
        currentWorkout?.addExercise(exercise)
    }
    
    func removeExerciseFromCurrentWorkout(at index: Int) {
        currentWorkout?.removeExercise(at: index)
    }
    
    func updateExerciseInCurrentWorkout(at index: Int, sets: Int, reps: Int, duration: Int) {
        guard var workout = currentWorkout, index < workout.exercises.count else { return }
        workout.exercises[index].sets = sets
        workout.exercises[index].reps = reps
        workout.exercises[index].duration = duration
        workout.lastModified = Date()
        currentWorkout = workout
    }
    
    func saveCurrentWorkout() {
        guard let workout = currentWorkout else { return }
        savedWorkouts.append(workout)
        currentWorkout = nil
        isCreatingWorkout = false
        saveWorkoutsToUserDefaults()
    }
    
    func deleteWorkout(at index: Int) {
        savedWorkouts.remove(at: index)
        saveWorkoutsToUserDefaults()
    }
    
    func loadWorkout(_ workout: Workout) {
        currentWorkout = workout
        isCreatingWorkout = true
    }
    
    func clearFilters() {
        selectedCategory = nil
        selectedEquipment = nil
        selectedLevel = nil
        searchText = ""
    }
    
    func refreshExercises() {
        exerciseService.fetchExercises()
    }
    
    // MARK: - Data Persistence
    private func saveWorkoutsToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(savedWorkouts) {
            UserDefaults.standard.set(encoded, forKey: "SavedWorkouts")
        }
    }
    
    func loadWorkoutsFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "SavedWorkouts"),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            savedWorkouts = decoded
        
    }
}
