//
//  WorkoutBuilderView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/25/25.
//


// WorkoutBuilderView.swift
// Workout creation and editing view

import SwiftUI

struct WorkoutBuilderView: View {
    @ObservedObject var viewModel: WorkoutBuilderViewModel
    @State private var showingExerciseSelector = false
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button("Cancel") {
                    viewModel.isCreatingWorkout = false
                    viewModel.currentWorkout = nil
                }
                
                Spacer()
                
                Text(viewModel.currentWorkout?.name ?? "New Workout")
                    .font(.headline)
                
                Spacer()
                
                Button("Save") {
                    viewModel.saveCurrentWorkout()
                }
                .disabled(viewModel.currentWorkout?.exercises.isEmpty ?? true)
            }
            .padding()
            
            // Exercise List
            if let workout = viewModel.currentWorkout, !workout.exercises.isEmpty {
                List {
                    ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, workoutExercise in
                        WorkoutExerciseRowView(
                            workoutExercise: workoutExercise,
                            onUpdate: { sets, reps, duration in
                                viewModel.updateExerciseInCurrentWorkout(
                                    at: index,
                                    sets: sets,
                                    reps: reps,
                                    duration: duration
                                )
                            }
                        )
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.removeExerciseFromCurrentWorkout(at: index)
                        }
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No exercises added yet")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    Text("Tap 'Add Exercise' to get started")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Spacer()
            }
            
            // Add Exercise Button
            Button(action: {
                showingExerciseSelector = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Exercise")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding()
        }
        .sheet(isPresented: $showingExerciseSelector) {
            ExerciseSelectorView(viewModel: viewModel)
        }
    }
}

struct WorkoutExerciseRowView: View {
    let workoutExercise: WorkoutExercise
    let onUpdate: (Int, Int, Int) -> Void
    
    @State private var sets: Int
    @State private var reps: Int
    @State private var duration: Int
    @State private var showingDetails = false
    
    init(workoutExercise: WorkoutExercise, onUpdate: @escaping (Int, Int, Int) -> Void) {
        self.workoutExercise = workoutExercise
        self.onUpdate = onUpdate
        self._sets = State(initialValue: workoutExercise.sets)
        self._reps = State(initialValue: workoutExercise.reps)
        self._duration = State(initialValue: workoutExercise.duration)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(workoutExercise.exercise.name)
                        .font(.headline)
                    
                    Text(workoutExercise.exercise.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingDetails.toggle()
                }) {
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            
            if showingDetails {
                VStack(spacing: 12) {
                    HStack {
                        Text("Sets:")
                        Spacer()
                        Stepper(value: $sets, in: 1...20) {
                            Text("\(sets)")
                                .frame(width: 30)
                        }
                    }
                    
                    HStack {
                        Text("Reps:")
                        Spacer()
                        Stepper(value: $reps, in: 1...100) {
                            Text("\(reps)")
                                .frame(width: 30)
                        }
                    }
                    
                    HStack {
                        Text("Duration (sec):")
                        Spacer()
                        Stepper(value: $duration, in: 0...3600, step: 15) {
                            Text(duration > 0 ? "\(duration)s" : "N/A")
                                .frame(width: 50)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: sets) { _, newValue in
                    onUpdate(newValue, reps, duration)
                }
                .onChange(of: reps) { _, newValue in
                    onUpdate(sets, newValue, duration)
                }
                .onChange(of: duration) { _, newValue in
                    onUpdate(sets, reps, newValue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
