//
//  ContentView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/13/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = WorkoutBuilderViewModel()

    var body: some View {
        TabView {
            // Tab 1 -- Workouts
            workoutsTab
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell")
                }

            // Tab 2 -- History
            WorkoutHistoryView(viewModel: viewModel)
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
                }
        }
        .overlay(alignment: .bottom) {
            if viewModel.exerciseService.isLoading {
                loadingBanner
            }
        }
        .onAppear {
            viewModel.configure(with: modelContext)
        }
    }

    // Extracted so the TabView body stays readable
    private var workoutsTab: some View {
        Group {
            if viewModel.isCreatingWorkout {
                WorkoutBuilderView(viewModel: viewModel)
            } else {
                HomeView(viewModel: viewModel)
            }
        }
    }

    private var loadingBanner: some View {
        HStack {
            ProgressView().scaleEffect(0.8)
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
