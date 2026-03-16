//
//  HomePageView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/21/25.
import SwiftUI
//


struct HomeView: View {
    @ObservedObject var viewModel: WorkoutBuilderViewModel
    @StateObject private var timerViewModel = HIITTimerViewModel()
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
            
            // HIIT Timer Section
                        VStack(spacing: 16) {
                            HStack {
                                Text("Quick Actions")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            Button(action: {
                                timerViewModel.isShowingCustomization = true
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "timer")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(Color.orange)
                                        .cornerRadius(25)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("HIIT Timer")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("Set intervals for high-intensity workouts")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                        .padding(.bottom)
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
                        WorkoutRowView(
                            workout: workout,
                            onTap: { viewModel.loadWorkout(workout) },
                            onComplete: { viewModel.completeWorkout(workout) }
                        )
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
        .sheet(isPresented: $timerViewModel.isShowingCustomization) {
                    HIITTimerCustomizationView(timerViewModel: timerViewModel)
                }
                .fullScreenCover(isPresented: $timerViewModel.isShowingActiveTimer) {
                    HIITTimerActiveView(timerViewModel: timerViewModel)
        }
                .sheet(isPresented: $timerViewModel.isShowingSessionSummary) {
                    HIITSessionSummaryView(timerViewModel: timerViewModel)
                }
    }
    
}

struct WorkoutRowView: View {
    let workout: Workout
    let onTap: () -> Void
    let onComplete: () -> Void  // ← add this

    init(workout: Workout, onTap: @escaping () -> Void, onComplete: @escaping () -> Void) {
        self.workout = workout
        self.onTap = onTap
        self.onComplete = onComplete
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Created: \(workout.createdDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Show a checkmark if already completed, button if not
                    if workout.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else {
                        Button(action: onComplete) {
                            Text("Complete")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                        // Stop the Complete tap from also triggering the row tap
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }

                Text("\(workout.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
