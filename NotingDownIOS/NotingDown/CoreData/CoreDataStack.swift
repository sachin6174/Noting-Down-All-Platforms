import CoreData

class CoreDataStack {
    // Singleton instance for easy access
    static let shared = CoreDataStack()

    // The persistent container for your application.
    lazy var persistentContainer: NSPersistentContainer = {
        // Change "MyModel" to your actual model name, e.g. "CoreDataModels"
        let container = NSPersistentContainer(name: "CoreDataModels")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    // Convenience access to the managed object context
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // Save context if there are changes
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
