//
//  ContentView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/13/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WorkoutBuilderViewModel()
    @State private var showingError = false
    @State private var showingDebugInfo = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isCreatingWorkout {
                    WorkoutBuilderView(viewModel: viewModel)
                } else {
                    HomeView(viewModel: viewModel)
                }
            }
        }
        .onAppear {
        }
        .alert("Error Loading Exercises", isPresented: $showingError) {
            Button("Retry") {
                viewModel.refreshExercises
            }
            Button("Continue with Sample Data") {
                // Continue with sample exercises
            }
            Button("Debug Info") {
                showingDebugInfo = true
            }
        } message: {
            Text(viewModel.exerciseService.errorMessage ?? "An error occurred while loading exercises.")
        }
        .alert("Debug Information", isPresented: $showingDebugInfo) {
            Button("Validate Data") {
                viewModel.exerciseService.validateExerciseData()
            }
            Button("Test JSON Parsing") {
                viewModel.exerciseService.testJSONParsing()
            }
            Button("Clear Cache") {
                viewModel.exerciseService.clearCache()
                viewModel.refreshExercises()
            }
            Button("OK") { }
        } message: {
            Text("Total exercises loaded: \(viewModel.exerciseService.exercises.count)")
        }
        .onChange(of: viewModel.exerciseService.errorMessage) { oldValue, newValue in
            showingError = newValue != nil
        }
        .overlay(alignment: .bottom) {
            if viewModel.exerciseService.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading exercises...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                .padding()
            }
        }
    }
}
                    

                    //#Preview {
                        //ContentView()
                    
