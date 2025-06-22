//
//  ExerciseViewModel.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/21/25.
//


import Foundation
import SwiftUI

class ExerciseViewModel: ObservableObject {
    @Published var allExercises: [Exercise] = [
        Exercise(name: "Push-Up", gifName: "pushup", reps: 10, duration: 30),
        Exercise(name: "Squat", gifName: "squat", reps: 45, duration: 12),
        Exercise(name: "Plank", gifName: "plank", reps: 60, duration: nil)
    ]

    func updateExercise(_ exercise: Exercise, reps: Int?, duration: Int?) {
        guard let index = allExercises.firstIndex(where: { $0.id == exercise.id }) else { return }
        allExercises[index].reps = reps
        allExercises[index].duration = duration
    }
}
