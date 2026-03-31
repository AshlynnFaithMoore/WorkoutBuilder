//
//  LegacyWorkoutExercise.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 3/31/26.
//


//
//  LegacyModels.swift
//  WorkoutBuilderApp
//
//  Codable structs matching the old UserDefaults schema.
//  Used only for one-time data migration to SwiftData.
//  Can be removed once all users have migrated.
//

import Foundation

struct LegacyWorkoutExercise: Codable {
    var id: UUID
    let exercise: Exercise
    var sets: Int
    var reps: Int
    var duration: Int
}

struct LegacyWorkout: Codable {
    var id: UUID
    var name: String
    var exercises: [LegacyWorkoutExercise]
    let createdDate: Date
    var lastModified: Date
    var completedDate: Date?
}


