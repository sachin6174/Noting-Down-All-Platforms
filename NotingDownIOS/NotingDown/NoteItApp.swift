//
//  NoteItApp.swift
//  NoteIt
//
//  Created by sachin kumar on 19/02/25.
//

import SwiftUI
import FirebaseCore

@main
struct NoteItApp: App {
    let persistenceController = AppPersistence.makeStack()
    @AppStorage("isDarkMode") private var isDarkMode = false

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.context)
                .preferredColorScheme(isDarkMode ? .dark : .light)

        }
    }
}
