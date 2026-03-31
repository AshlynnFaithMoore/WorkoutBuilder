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
    let container: ModelContainer

    init() {
        let schema = Schema([Workout.self, WorkoutExercise.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        Self.migrateFromUserDefaults(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }

    /// One-time migration of workout data from UserDefaults to SwiftData.
    private static func migrateFromUserDefaults(context: ModelContext) {
        let migrated = UserDefaults.standard.bool(forKey: "DataMigratedToSwiftData")
        guard !migrated else { return }

        if let data = UserDefaults.standard.data(forKey: "SavedWorkouts"),
           let legacyWorkouts = try? JSONDecoder().decode([LegacyWorkout].self, from: data) {
            for legacy in legacyWorkouts {
                let workout = Workout(name: legacy.name)
                workout.createdDate = legacy.createdDate
                workout.lastModified = legacy.lastModified
                workout.completedDate = legacy.completedDate
                for legacyExercise in legacy.exercises {
                    let we = WorkoutExercise(
                        exercise: legacyExercise.exercise,
                        sets: legacyExercise.sets,
                        reps: legacyExercise.reps,
                        duration: legacyExercise.duration
                    )
                    workout.exercises.append(we)
                }
                context.insert(workout)
            }
            try? context.save()
            UserDefaults.standard.removeObject(forKey: "SavedWorkouts")
        }
        UserDefaults.standard.set(true, forKey: "DataMigratedToSwiftData")
    }
}


