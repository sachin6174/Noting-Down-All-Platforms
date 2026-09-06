import CoreData

final class CoreDataStack {
    static let shared: CoreDataStack = {
        do { return try CoreDataStack() }
        catch { fatalError("Unable to open notes store: \(error.localizedDescription)") }
    }()
    let persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext { persistentContainer.viewContext }

    /// Injectable stores keep tests separate from user notes.
    init(inMemory: Bool = false, storeURL: URL? = nil) throws {
        persistentContainer = NSPersistentContainer(name: "CoreDataModels")
        let description = NSPersistentStoreDescription()
        description.type = inMemory ? NSInMemoryStoreType : NSSQLiteStoreType
        if let storeURL { description.url = storeURL }
        else if !inMemory {
            description.url = NSPersistentContainer.defaultDirectoryURL()
                .appendingPathComponent("CoreDataModels.sqlite")
        }
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        if !inMemory, let url = description.url {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        persistentContainer.persistentStoreDescriptions = [description]
        var loadError: Error?
        persistentContainer.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        context.automaticallyMergesChangesFromParent = true
        context.undoManager = nil
    }
    func saveContext() throws {
        if context.hasChanges { try context.save() }
    }
}
