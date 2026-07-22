import CoreData
import Foundation

class CoreDataMigrationHelper {
    static func performMigrationIfNeeded() {
        let coordinator = CoreDataStack.shared.persistentContainer.persistentStoreCoordinator
        
        guard let storeURL = coordinator.persistentStores.first?.url else {
            print("No store URL found")
            return
        }
        
        do {
            // Check if migration is needed
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )
            
            let model = CoreDataStack.shared.persistentContainer.managedObjectModel
            
            if !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
                print("Core Data migration needed")
                try migrateStore(at: storeURL, coordinator: coordinator)
            } else {
                print("No Core Data migration needed")
            }
        } catch {
            print("Error checking migration: \(error)")
        }
    }
    
    private static func migrateStore(at storeURL: URL, coordinator: NSPersistentStoreCoordinator) throws {
        // Add default values for new attributes
        let context = CoreDataStack.shared.context
        
        let fetchRequest: NSFetchRequest<NotesTable> = NotesTable.fetchRequest()
        let notes = try context.fetch(fetchRequest)
        
        for note in notes {
            // Set default values for new attributes
            if note.createdDate == nil {
                note.createdDate = Date()
            }
            if note.modifiedDate == nil {
                note.modifiedDate = Date()
            }
            if note.category == nil || note.category?.isEmpty == true {
                note.category = "General"
            }
            // isFavorite already has a default value of false
        }
        
        try context.save()
        print("Core Data migration completed successfully")
    }
}
