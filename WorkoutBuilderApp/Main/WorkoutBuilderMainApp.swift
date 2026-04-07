//
//  WorkoutBuilderAppApp.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/13/25.
//

import SwiftUI
import SwiftData


@main
struct WorkoutBuilderMainApp: App {
    let container: ModelContainer?
    
    init() {
        let schema = Schema([Workout.self, WorkoutExercise.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            container = nil
        }
    }
    
    
    var body: some Scene {
        WindowGroup {
            if let container {
                ContentView()
                    .modelContainer(container)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Unable to Load Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("WorkoutBuilder was unable to set up its database. Try restarting the app or reinstalling.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
    }
    
}


  
