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
// first screen the app loads
    var body: some Scene {
        WindowGroup {
            HomePageView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
