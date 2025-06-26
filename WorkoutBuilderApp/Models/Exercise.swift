//
//  Exercise.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/25/25.
//


// Exercise.swift
// Model file - Contains data structures

import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    var id = UUID() // Unique identifier for each exercise
    let name: String
    let category: ExerciseCategory
    let description: String
    
    // Static property to provide sample exercises
    static let sampleExercises = [
        Exercise(name: "Push-ups", category: .chest, description: "Classic upper body exercise"),
        Exercise(name: "Squats", category: .legs, description: "Lower body compound movement"),
        Exercise(name: "Plank", category: .core, description: "Core stability exercise"),
        Exercise(name: "Bench Press", category: .chest, description: "Chest strengthening exercise"),
        Exercise(name: "Deadlifts", category: .legs, description: "Full body compound lift"),
        Exercise(name: "Pull-ups", category: .back, description: "Upper body pulling exercise"),
        Exercise(name: "Shoulder Press", category: .shoulders, description: "Shoulder strengthening"),
        Exercise(name: "Bicep Curls", category: .arms, description: "Bicep isolation exercise")
    ]
}

enum ExerciseCategory: String, CaseIterable, Codable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case arms = "Arms"
    case shoulders = "Shoulders"
    case core = "Core"
}
