//
//  HomePageView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/21/25.
import SwiftUI
//


struct HomeView: View {
    @ObservedObject var viewModel: WorkoutBuilderViewModel
    @State private var showingNewWorkoutDialog = false
    @State private var newWorkoutName = ""
    
    init(viewModel: WorkoutBuilderViewModel) {
            self.viewModel = viewModel
        }
    
    
    var body: some View {
        VStack {
            HStack {
                Text("My Workouts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    showingNewWorkoutDialog = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            if viewModel.savedWorkouts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("No workouts yet")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("Tap the + button to create your first workout")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                Spacer()
            } else {
                List {
                    ForEach(viewModel.savedWorkouts) { workout in
                        WorkoutRowView(workout: workout) {
                            viewModel.loadWorkout(workout)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteWorkout(at: index)
                        }
                    }
                }
            }
        }
        .alert("New Workout", isPresented: $showingNewWorkoutDialog) {
            TextField("Workout Name", text: $newWorkoutName)
            Button("Create") {
                if !newWorkoutName.isEmpty {
                    viewModel.startNewWorkout(name: newWorkoutName)
                    newWorkoutName = ""
                }
            }
            Button("Cancel", role: .cancel) {
                newWorkoutName = ""
            }
        } message: {
            Text("Enter a name for your new workout")
        }
    }
}

struct WorkoutRowView: View {
    let workout: Workout
    let onTap: () -> Void
    
    init(workout: Workout, onTap: @escaping () -> Void) {
            self.workout = workout
            self.onTap = onTap
        }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(workout.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(workout.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Created: \(workout.createdDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
