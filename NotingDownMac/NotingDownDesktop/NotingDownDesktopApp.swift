//
//  NotingDownDesktopApp.swift
//  NotingDownDesktop
//
//  Created by sachin kumar on 22/02/25.
//

import SwiftUI

@main
struct NotingDownDesktopApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NotesListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .frame(minWidth: 900, maxWidth: 900, minHeight: 600, maxHeight: 600)
        }
        .windowResizability(.contentSize)
    }
}
