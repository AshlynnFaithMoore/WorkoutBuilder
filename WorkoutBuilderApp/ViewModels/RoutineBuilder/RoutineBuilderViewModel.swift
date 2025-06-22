//
//  WorkoutBuilderViewModel.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/21/25.
//

import Foundation


class RoutineBuilderViewModel: ObservableObject {
    @Published var selectedExercises: [Exercise] = []
    @Published var workoutName: String = ""

    func addExercise(_ exercise: Exercise) {
        selectedExercises.append(exercise)
    }

    func updateExercise(at index: Int, reps: Int?, duration: Int?) {
        selectedExercises[index].reps = reps
        selectedExercises[index].duration = duration
    }

    func removeExercise(at index: Int) {
        selectedExercises.remove(at: index)
    }

    func saveWorkout() -> Workout {
        Workout(name: workoutName, exercises: selectedExercises)
    }
}
