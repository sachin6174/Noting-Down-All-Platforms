import CoreData

enum AppPersistence {
    static func makeStack() -> CoreDataStack {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui-testing") {
            do {
                let directory = FileManager.default.temporaryDirectory.appendingPathComponent("NotingDownUITests", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let stack = try CoreDataStack(storeURL: directory.appendingPathComponent("UITests.sqlite"))
                if arguments.contains("-ui-reset") {
                    for note in try stack.context.fetch(NotesTable.fetchRequest()) { stack.context.delete(note) }
                    try stack.saveContext()
                }
                if arguments.contains("-ui-seed"), try stack.context.count(for: NotesTable.fetchRequest()) == 0 {
                    let store = NoteStore(context: stack.context)
                    try store.save(title: "Weekend ideas", body: "Walk by the river. Bring a notebook.", category: "Personal", favorite: true)
                    try store.save(title: "Project checklist", body: "Add tests, review accessibility, record a demo.", category: "Work")
                }
                return stack
            } catch { fatalError("UI test store failed: \(error)") }
        }
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            do { return try CoreDataStack(inMemory: true) }
            catch { fatalError("Unit test store failed: \(error)") }
        }
        #endif
        return CoreDataStack.shared
    }
}
