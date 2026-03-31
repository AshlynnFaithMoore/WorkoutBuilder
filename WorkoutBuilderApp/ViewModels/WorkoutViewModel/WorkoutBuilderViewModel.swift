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
import SwiftData

class WorkoutBuilderViewModel: ObservableObject {
    @Published var exerciseService = ExerciseService()
    @Published var currentWorkout: Workout?
    @Published var savedWorkouts: [Workout] = []
    @Published var isCreatingWorkout = false
    @Published var selectedCategory: ExerciseCategory?
    @Published var selectedEquipment: String?
    @Published var selectedLevel: String?
    @Published var searchText = ""

    private var modelContext: ModelContext?

    // Cached analytics values -- invalidated when workouts change
    private var cachedWorkoutsPerDay: [(date: Date, count: Int)]?
    private var cachedCategoryBreakdown: [(category: ExerciseCategory, count: Int)]?
    private var cachedCurrentStreak: Int?
    private var cachedCompletedWorkouts: [Workout]?

    init() {}

    /// Called once from ContentView.onAppear to inject the SwiftData context.
    func configure(with context: ModelContext) {
        guard modelContext == nil else { return }
        modelContext = context
        fetchWorkouts()
    }

    // MARK: - Data Access

    private func fetchWorkouts() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.createdDate)])
        savedWorkouts = (try? modelContext.fetch(descriptor)) ?? []
        invalidateCaches()
    }

    private func save() {
        try? modelContext?.save()
        fetchWorkouts()
    }

    private func invalidateCaches() {
        cachedWorkoutsPerDay = nil
        cachedCategoryBreakdown = nil
        cachedCurrentStreak = nil
        cachedCompletedWorkouts = nil
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
    }

    // MARK: - Workout Management

    func startNewWorkout(name: String) {
        currentWorkout = Workout(name: name)
        isCreatingWorkout = true
    }

    func addExerciseToCurrentWorkout(_ exercise: Exercise) {
        currentWorkout?.addExercise(exercise)
        objectWillChange.send()
    }

    func removeExerciseFromCurrentWorkout(at index: Int) {
        currentWorkout?.removeExercise(at: index)
        objectWillChange.send()
    }

    func updateExerciseInCurrentWorkout(at index: Int, sets: Int, reps: Int, duration: Int) {
        guard let workout = currentWorkout, index < workout.exercises.count else { return }
        workout.exercises[index].sets = sets
        workout.exercises[index].reps = reps
        workout.exercises[index].duration = duration
        workout.lastModified = Date()
        objectWillChange.send()
    }

    func saveCurrentWorkout() {
        guard let workout = currentWorkout,
              !workout.exercises.isEmpty else { return }
        modelContext?.insert(workout)
        save()
        currentWorkout = nil
        isCreatingWorkout = false
    }

    func deleteWorkout(at index: Int) {
        let workout = savedWorkouts[index]
        modelContext?.delete(workout)
        save()
    }

    // MARK: - Completion

    func completeWorkout(_ workout: Workout) {
        workout.markCompleted()
        save()
    }

    // MARK: - History Computed Properties (Cached)

    // All workouts that have been marked complete
    var completedWorkouts: [Workout] {
        if let cached = cachedCompletedWorkouts { return cached }
        let result = savedWorkouts
            .filter { $0.isCompleted }
            .sorted { ($0.completedDate ?? .distantPast) < ($1.completedDate ?? .distantPast) }
        cachedCompletedWorkouts = result
        return result
    }

    // Workouts completed per day for the bar chart
    // Returns the last 30 days, with 0 for days with no workouts
    var workoutsPerDay: [(date: Date, count: Int)] {
        if let cached = cachedWorkoutsPerDay { return cached }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let result = (0..<30).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let count = completedWorkouts.filter {
                guard let completed = $0.completedDate else { return false }
                return calendar.isDate(completed, inSameDayAs: day)
            }.count
            return (date: day, count: count)
        }
        cachedWorkoutsPerDay = result
        return result
    }

    // Category breakdown across all completed workouts for the donut chart
    var categoryBreakdown: [(category: ExerciseCategory, count: Int)] {
        if let cached = cachedCategoryBreakdown { return cached }
        var counts: [ExerciseCategory: Int] = [:]
        completedWorkouts
            .flatMap { $0.exercises }
            .forEach { counts[$0.exercise.category, default: 0] += 1 }
        let result = counts
            .map { (category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        cachedCategoryBreakdown = result
        return result
    }

    // Current weekly streak -- consecutive weeks with at least one workout
    var currentStreak: Int {
        if let cached = cachedCurrentStreak { return cached }
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
        cachedCurrentStreak = streak
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
        exerciseService.refreshExercises()
    }
}


