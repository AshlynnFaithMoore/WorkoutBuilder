//
//  Exercise.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/17/25.
//

import Foundation
struct Exercise: Identifiable {
    let id = UUID() // unique identifier to distinguish between exercises when rendering them in a list
    var name: String // name of exercise
    var gifName: String // gif name
    var reps: Int?       // Optional: only for rep-based exercises
    var duration: Int?   // Optional: only for time-based exercises (in seconds)
}
