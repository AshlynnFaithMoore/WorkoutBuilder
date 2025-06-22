//
//  Workout.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/17/25.
//

import Foundation
struct Workout: Identifiable {
    let id = UUID()
    var name: String
    var exercises: [Exercise] // A list (array) of Exercise objects that belong to this workout.
    
}
