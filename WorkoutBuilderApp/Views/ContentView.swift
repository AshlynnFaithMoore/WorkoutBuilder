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
            viewModel.loadWorkoutsFromUserDefaults()
                    }
                    .alert("Error Loading Exercises", isPresented: $showingError) {
                        Button("Retry") {
                            $viewModel.refreshExercises
                        }
                        Button("Continue with Sample Data") {
                            // Continue with sample exercises
                        }
                    } message: {
                        Text($viewModel.exerciseService.errorMessage ?? "An error occurred while loading exercises.")
                    }
                    .onChange(of: $viewModel.exerciseService.errorMessage) { _, errorMessage in
                        showingError = errorMessage != nil
                    }
                }
}
