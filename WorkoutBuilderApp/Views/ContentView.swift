//
//  ContentView.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/13/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WorkoutBuilderViewModel()
    
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
    }
}
