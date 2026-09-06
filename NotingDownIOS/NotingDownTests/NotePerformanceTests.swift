import XCTest
import CoreData
@testable import NotingDown

@MainActor
final class NotePerformanceTests: XCTestCase {
    func testSQLiteSearchWithTwoThousandNotes() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let stack = try CoreDataStack(storeURL: directory.appendingPathComponent("Benchmark.sqlite"))
        defer {
            stack.context.reset()
            for store in stack.persistentContainer.persistentStoreCoordinator.persistentStores {
                try? stack.persistentContainer.persistentStoreCoordinator.remove(store)
            }
            try? FileManager.default.removeItem(at: directory)
        }
        for index in 0..<2_000 {
            let note = NotesTable(context: stack.context)
            note.id = UUID()
            note.title = "Note \(index)"
            note.noteDescription = String(repeating: "Text for a realistic local note. ", count: 20)
            note.category = index.isMultiple(of: 2) ? "Work" : "Personal"
            note.isFavorite = index.isMultiple(of: 5)
            note.modifiedDate = Date(timeIntervalSince1970: Double(index))
        }
        try stack.saveContext()
        let query = SearchViewModel()
        query.selectedCategory = "Work"
        query.showFavoritesOnly = true
        let request = query.fetchRequest(search: "realistic")
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            stack.context.reset()
            do {
                let results = try stack.context.fetch(request)
                XCTAssertEqual(results.count, 200)
                // Fault in the visible first page, as the lazy list does.
                XCTAssertEqual(results.prefix(40).compactMap(\.title).count, 40)
            } catch { XCTFail("Benchmark fetch failed: \(error)") }
        }
    }
}
