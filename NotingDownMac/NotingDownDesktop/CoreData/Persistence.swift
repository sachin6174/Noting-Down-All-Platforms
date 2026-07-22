import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Change container name to match your model filename "CoreDataTables"
        container = NSPersistentContainer(name: "CoreDataTables")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Loading store failed: \(error)")
            }
        }
    }
}
