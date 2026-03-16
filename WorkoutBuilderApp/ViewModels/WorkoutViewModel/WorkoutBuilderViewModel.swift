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
    
    // Computed property to filter exercises by category, equipment, level, and search
    var filteredExercises: [Exercise] {
        var filtered = availableExercises
        
        // Apply search filter first
        if !searchText.isEmpty {
            filtered = exerciseService.search(query: searchText)
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply equipment filter
        if let equipment = selectedEquipment {
            filtered = filtered.filter { $0.equipment.contains(equipment) }
        }
        
        // Apply level filter
        if let level = selectedLevel {
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
        guard let workout = currentWorkout,
              !workout.exercises.isEmpty else { return } 
        savedWorkouts.append(workout)
        currentWorkout = nil
        isCreatingWorkout = false
        saveWorkoutsToUserDefaults()
    }
    
    func deleteWorkout(at index: Int) {
        savedWorkouts.remove(at: index)
        saveWorkoutsToUserDefaults()
    }
    
    
    // MARK: - Completion
    func completeWorkout(_ workout: Workout) {
        guard let index = savedWorkouts.firstIndex(where: { $0.id == workout.id }) else { return }
        savedWorkouts[index].markCompleted()
        saveWorkoutsToUserDefaults()
    }

    // MARK: - History Computed Properties

    // All workouts that have been marked complete
    var completedWorkouts: [Workout] {
        savedWorkouts
            .filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? .distantPast) < ($1.completedDate ?? .distantPast) }
    }

    // Workouts completed per day for the bar chart
    // Returns the last 30 days, with 0 for days with no workouts
    var workoutsPerDay: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<30).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let count = completedWorkouts.filter {
                guard let completed = $0.completedDate else { return false }
                return calendar.isDate(completed, inSameDayAs: day)
            }.count
            return (date: day, count: count)
        }
    }

    // Category breakdown across all completed workouts for the donut chart
    var categoryBreakdown: [(category: ExerciseCategory, count: Int)] {
        var counts: [ExerciseCategory: Int] = [:]
        completedWorkouts
            .flatMap { $0.exercises }
            .forEach { counts[$0.exercise.category, default: 0] += 1 }
        return counts
            .map { (category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    // Current weekly streak — consecutive weeks with at least one workout
    var currentStreak: Int {
        guard !completedWorkouts.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        while true {
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            let hasWorkout = completedWorkouts.contains {
                guard let date = $0.completedDate else { return false }
                return date >= weekStart && date < weekEnd
            }
            if hasWorkout {
                streak += 1
                weekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
            } else {
                break
            }
        }
        return streak
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
        exerciseService.refreshExercises() // now wraps Task { await fetchExercises() } internally
    }
    
    // MARK: - Data Persistence
    private func saveWorkoutsToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(savedWorkouts) {
            UserDefaults.standard.set(encoded, forKey: "SavedWorkouts")
        }
    }
    
    private func loadWorkoutsFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "SavedWorkouts"),
           let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
            savedWorkouts = decoded
        }
    }
}
