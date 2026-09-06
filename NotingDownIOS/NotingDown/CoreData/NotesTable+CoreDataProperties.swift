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
        guard let createdDate = createdDate else { return String(localized: "Unknown") }
        return createdDate.formatted(date: .abbreviated, time: .shortened)
    }
    
    var formattedModifiedDate: String {
        guard let modifiedDate = modifiedDate else { return String(localized: "Unknown") }
        return modifiedDate.formatted(date: .abbreviated, time: .shortened)
    }
    
    var displayCategory: String {
        return category?.isEmpty == false ? category! : "General"
    }
}

extension NotesTable: Identifiable {}
