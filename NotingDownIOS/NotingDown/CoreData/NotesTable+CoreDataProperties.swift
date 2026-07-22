import CoreData
import Foundation

extension NotesTable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NotesTable> {
        return NSFetchRequest<NotesTable>(entityName: "NotesTable")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var noteDescription: String?
    @NSManaged public var title: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var modifiedDate: Date?
    @NSManaged public var category: String?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var colorTag: String?
    
    var formattedCreatedDate: String {
        guard let createdDate = createdDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }
    
    var formattedModifiedDate: String {
        guard let modifiedDate = modifiedDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modifiedDate)
    }
    
    var displayCategory: String {
        return category?.isEmpty == false ? category! : "General"
    }
}

extension NotesTable: Identifiable {}
