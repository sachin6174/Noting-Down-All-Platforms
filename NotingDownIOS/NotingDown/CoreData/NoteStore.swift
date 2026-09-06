import CoreData

/// All calls belong on the supplied context's queue.
struct NoteStore {
    let context: NSManagedObjectContext
    enum ValidationError: LocalizedError {
        case emptyTitle
        var errorDescription: String? { String(localized: "A note needs a title.") }
    }

    @discardableResult
    func save(note: NotesTable? = nil, title: String, body: String,
              category: String = "General", favorite: Bool = false,
              colorTag: String? = nil, now: Date = Date()) throws -> NotesTable {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw ValidationError.emptyTitle }
        let previousValues = note.map { $0.dictionaryWithValues(forKeys: Array($0.entity.attributesByName.keys)) }
        let record = note ?? NotesTable(context: context)
        record.id = record.id ?? UUID()
        record.createdDate = record.createdDate ?? now
        record.modifiedDate = now
        record.title = title
        record.noteDescription = body
        record.category = category.isEmpty ? "General" : category
        record.isFavorite = favorite
        record.colorTag = colorTag
        do {
            try context.save()
        } catch {
            // The editor owns its draft. Restore only this record, preserving unrelated edits.
            if let previousValues { record.setValuesForKeys(previousValues) }
            else { context.delete(record) }
            throw error
        }
        return record
    }

    func delete(_ note: NotesTable) throws {
        context.delete(note)
        try context.save()
    }
}
