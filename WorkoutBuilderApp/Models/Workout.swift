//
//  WorkoutExercise.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/25/25.
//


// Workout.swift
// Model file - Contains workout-related data structures

import Foundation

struct WorkoutExercise: Identifiable, Codable {
    var id = UUID()
    let exercise: Exercise
    var sets: Int
    var reps: Int
    var duration: Int // in seconds, 0 if not applicable
    
    init(exercise: Exercise, sets: Int = 3, reps: Int = 10, duration: Int = 0) {
        self.exercise = exercise
        self.sets = sets
        self.reps = reps
        self.duration = duration
    }
}

struct Workout: Identifiable, Codable {
    var id = UUID()
    var name: String
    var exercises: [WorkoutExercise]
    let createdDate: Date
    var lastModified: Date
    
    init(name: String, exercises: [WorkoutExercise] = []) {
        self.name = name
        self.exercises = exercises
        self.createdDate = Date()
        self.lastModified = Date()
    }
    
    mutating func addExercise(_ exercise: Exercise) {
        let workoutExercise = WorkoutExercise(exercise: exercise)
        exercises.append(workoutExercise)
        lastModified = Date()
    }
    
    mutating func removeExercise(at index: Int) {
        exercises.remove(at: index)
        lastModified = Date()
    }
}
