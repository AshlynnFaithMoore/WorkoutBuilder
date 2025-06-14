//
//  WorkoutBuilderAppApp.swift
//  WorkoutBuilderApp
//
//  Created by Ashlynn Moore on 6/13/25.
//

import SwiftUI

@main
struct WorkoutBuilderAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
