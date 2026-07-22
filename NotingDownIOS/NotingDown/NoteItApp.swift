//
//  NoteItApp.swift
//  NoteIt
//
//  Created by sachin kumar on 19/02/25.
//

import SwiftUI

@main
struct NoteItApp: App {
    let persistenceController = CoreDataStack.shared
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.context)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear {
                    // Perform migration if needed
                    CoreDataMigrationHelper.performMigrationIfNeeded()
                }
        }
    }
}
