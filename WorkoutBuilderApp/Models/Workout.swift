//
//  Workout.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/25/25.
//

import Foundation
import SwiftData

@Model
final class WorkoutExercise {
    /// JSON-encoded snapshot of the Exercise at the time it was added.
    var exerciseData: Data
    var sets: Int
    var reps: Int
    var duration: Int

    var workout: Workout?

    /// Reconstructs the Exercise struct from stored JSON.
    var exercise: Exercise {
        (try? JSONDecoder().decode(Exercise.self, from: exerciseData))
            ?? Exercise(name: "Unknown", category: .other, description: "Exercise data unavailable")
    }

    init(exercise: Exercise, sets: Int = 3, reps: Int = 10, duration: Int = 0) {
        self.exerciseData = (try? JSONEncoder().encode(exercise)) ?? Data()
        self.sets = sets
        self.reps = reps
        self.duration = duration
    }
}

@Model
final class Workout {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise]
    var createdDate: Date
    var lastModified: Date
    var completedDate: Date?

    var isCompleted: Bool { completedDate != nil }

    init(name: String, exercises: [WorkoutExercise] = []) {
        self.name = name
        self.exercises = exercises
        self.createdDate = Date()
        self.lastModified = Date()
    }

    func addExercise(_ exercise: Exercise) {
        let workoutExercise = WorkoutExercise(exercise: exercise)
        exercises.append(workoutExercise)
        lastModified = Date()
    }

    func removeExercise(at index: Int) {
        exercises.remove(at: index)
        lastModified = Date()
    }

    func markCompleted() {
        completedDate = Date()
    }
}

