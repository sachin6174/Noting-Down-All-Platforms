import XCTest
import CoreData
import Combine
@testable import NotingDown

@MainActor
final class NoteStoreTests: XCTestCase {
    private var stack: CoreDataStack!
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        stack = try CoreDataStack(storeURL: directory.appendingPathComponent("Tests.sqlite"))
    }

    override func tearDownWithError() throws {
        stack.context.reset()
        for store in stack.persistentContainer.persistentStoreCoordinator.persistentStores {
            try stack.persistentContainer.persistentStoreCoordinator.remove(store)
        }
        stack = nil
        try FileManager.default.removeItem(at: directory)
    }

    func testCreateUpdateReopenAndDelete() throws {
        let store = NoteStore(context: stack.context)
        let created = Date(timeIntervalSince1970: 100)
        let modified = Date(timeIntervalSince1970: 200)
        let note = try store.save(title: "  Café ideas \n", body: "First draft", now: created)
        let id = try XCTUnwrap(note.id)
        try store.save(note: note, title: "Café ideas", body: "Edited\n第二行", category: "Work", favorite: true, colorTag: "blue", now: modified)
        XCTAssertEqual(note.createdDate, created)
        XCTAssertEqual(note.modifiedDate, modified)
        stack.context.reset()
        for persistentStore in stack.persistentContainer.persistentStoreCoordinator.persistentStores {
            try stack.persistentContainer.persistentStoreCoordinator.remove(persistentStore)
        }
        stack = try CoreDataStack(storeURL: directory.appendingPathComponent("Tests.sqlite"))
        let reopened = try XCTUnwrap(stack.context.fetch(NotesTable.fetchRequest()).first)
        XCTAssertEqual(reopened.id, id)
        XCTAssertEqual(reopened.title, "Café ideas")
        XCTAssertEqual(reopened.noteDescription, "Edited\n第二行")
        XCTAssertEqual(reopened.category, "Work")
        XCTAssertEqual(reopened.colorTag, "blue")
        XCTAssertTrue(reopened.isFavorite)
        try NoteStore(context: stack.context).delete(reopened)
        stack.context.reset()
        XCTAssertEqual(try stack.context.count(for: NotesTable.fetchRequest()), 0)
    }

    func testBlankTitleDoesNotInsertOrMutateNote() throws {
        let store = NoteStore(context: stack.context)
        XCTAssertThrowsError(try store.save(title: " \n\t ", body: "draft"))
        XCTAssertEqual(try stack.context.count(for: NotesTable.fetchRequest()), 0)
        let note = try store.save(title: "Keep me", body: "Original")
        XCTAssertThrowsError(try store.save(note: note, title: " ", body: "Lost"))
        XCTAssertEqual(note.title, "Keep me")
        XCTAssertEqual(note.noteDescription, "Original")
        XCTAssertFalse(stack.context.hasChanges)
    }

    func testSearchCombinesTextCategoryAndFavorite() throws {
        let store = NoteStore(context: stack.context)
        try store.save(title: "Café plan", body: "A", category: "Work", favorite: true)
        try store.save(title: "Other", body: "CAFE in body", category: "Work")
        try store.save(title: "Café holiday", body: "B", category: "Travel", favorite: true)
        let query = SearchViewModel()
        XCTAssertEqual(try stack.context.fetch(query.fetchRequest(search: " cafe ")).count, 3)
        query.selectedCategory = "Work"
        XCTAssertEqual(try stack.context.fetch(query.fetchRequest(search: "cafe")).count, 2)
        query.showFavoritesOnly = true
        XCTAssertEqual(try stack.context.fetch(query.fetchRequest(search: "cafe")).map(\.title), ["Café plan"])
        XCTAssertTrue(try stack.context.fetch(query.fetchRequest(search: "' OR 1=1")).isEmpty)
    }

    func testFailedSaveCanBeRetriedWithoutDuplicateOrLostUnrelatedEdit() throws {
        let context = FailingSaveContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = stack.persistentContainer.persistentStoreCoordinator
        let store = NoteStore(context: context)
        context.failSave = true
        XCTAssertThrowsError(try store.save(title: "Retry me", body: "Draft"))
        XCTAssertEqual(try context.count(for: NotesTable.fetchRequest()), 0)
        context.failSave = false
        let note = try store.save(title: "Retry me", body: "Original")
        let other = try store.save(title: "Other note", body: "Keep")
        other.noteDescription = "Unrelated pending edit"
        context.failSave = true
        XCTAssertThrowsError(try store.save(note: note, title: "Changed", body: "Changed"))
        XCTAssertEqual(note.title, "Retry me")
        XCTAssertEqual(note.noteDescription, "Original")
        XCTAssertEqual(other.noteDescription, "Unrelated pending edit")
        context.failSave = false
        try store.save(note: note, title: "Changed", body: "Changed")
        XCTAssertEqual(try context.count(for: NotesTable.fetchRequest()), 2)
        context.reset()
    }

    func testGeneralIncludesLegacyMissingCategories() throws {
        for category in [nil, "", "General", "Work"] as [String?] {
            let note = NotesTable(context: stack.context)
            note.id = UUID()
            note.title = "Legacy"
            note.category = category
        }
        try stack.saveContext()
        let query = SearchViewModel()
        query.selectedCategory = "General"
        XCTAssertEqual(try stack.context.fetch(query.fetchRequest(search: "")).count, 3)
    }

    func testSortOrderUsesNewestFirstAndTitleAscending() throws {
        let store = NoteStore(context: stack.context)
        let old = try store.save(title: "Alpha", body: "", category: "Work", now: Date(timeIntervalSince1970: 100))
        try store.save(title: "Zulu", body: "", category: "General", now: Date(timeIntervalSince1970: 200))
        let query = SearchViewModel()
        XCTAssertEqual(try stack.context.fetch(query.fetchRequest(search: "")).map(\.title), ["Zulu", "Alpha"])
        try store.save(note: old, title: "Alpha", body: "", category: "Work", now: Date(timeIntervalSince1970: 300))
        XCTAssertEqual(try stack.context.fetch(query.fetchRequest(search: "")).map(\.title), ["Alpha", "Zulu"])
        query.sortOption = .dateCreated
        XCTAssertEqual(try stack.context.fetch(query.fetchRequest(search: "")).map(\.title), ["Zulu", "Alpha"])
        query.sortOption = .title
        XCTAssertEqual(try stack.context.fetch(query.fetchRequest(search: "")).map(\.title), ["Alpha", "Zulu"])
        query.sortOption = .category
        XCTAssertEqual(try stack.context.fetch(query.fetchRequest(search: "")).map(\.title), ["Zulu", "Alpha"])
    }

    func testDebouncePublishesLatestQuery() {
        let model = SearchViewModel()
        let published = expectation(description: "Latest search published")
        let subscription = model.$debouncedSearchText.dropFirst().sink {
            XCTAssertEqual($0, "latest")
            published.fulfill()
        }
        model.searchText = "l"
        model.searchText = "la"
        model.searchText = "latest"
        wait(for: [published], timeout: 2)
        withExtendedLifetime(subscription) {}
    }

    func testJSONAndCSVPreserveUnicodeQuotesAndNewlines() throws {
        let note = try NoteStore(context: stack.context).save(title: "Café, \"ideas\"", body: "First\n第二行", favorite: true)
        let jsonURL = try XCTUnwrap(ExportManager.shared.exportNotes([note], format: .json))
        defer { try? FileManager.default.removeItem(at: jsonURL) }
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: jsonURL)) as? [String: Any])
        let notes = try XCTUnwrap(json["notes"] as? [[String: Any]])
        XCTAssertEqual(notes.first?["description"] as? String, "First\n第二行")
        XCTAssertEqual(notes.first?["isFavorite"] as? Bool, true)
        let csvURL = try XCTUnwrap(ExportManager.shared.exportNotes([note], format: .csv))
        defer { try? FileManager.default.removeItem(at: csvURL) }
        let csv = try String(contentsOf: csvURL, encoding: .utf8)
        XCTAssertTrue(csv.contains("\"Café, \"\"ideas\"\"\""))
        XCTAssertTrue(csv.contains("\"First\n第二行\""))
    }
}

private final class FailingSaveContext: NSManagedObjectContext {
    var failSave = false
    override func save() throws {
        if failSave { throw NSError(domain: "NotingDownTests", code: 1) }
        try super.save()
    }
}
