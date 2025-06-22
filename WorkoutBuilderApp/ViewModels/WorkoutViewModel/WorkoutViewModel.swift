//
//  WorkoutViewModel.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/21/25.
//


import Foundation

class WorkoutViewModel: ObservableObject {
    // Published means views will update when this changes
    @Published var workouts: [Workout] = []
    
    // Temporary store for building a new workout
    @Published var currentWorkoutName: String = ""
    @Published var currentExercises: [Exercise] = []
    
    // Add a new workout to the list
    func saveCurrentWorkout() {
        let newWorkout = Workout(name: currentWorkoutName, exercises: currentExercises)
        workouts.append(newWorkout)
        // Reset the builder
        currentWorkoutName = ""
        currentExercises = []
    }
    
    // Add an exercise to the current workout
    func addExercise(_ exercise: Exercise) {
        currentExercises.append(exercise)
    }
    
    // Remove an exercise from the current workout
    func removeExercise(at index: Int) {
        if currentExercises.indices.contains(index) {
            currentExercises.remove(at: index)
        }
    }
}
