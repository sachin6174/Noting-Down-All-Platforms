import Foundation
import SwiftUI
import CoreData
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory = "All"
    @Published var sortOption: SortOption = .dateModified
    @Published var showFavoritesOnly = false
    @Published private(set) var debouncedSearchText = ""
    private var searchSubscription: AnyCancellable?

    init() {
        searchSubscription = $searchText.removeDuplicates()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] in self?.debouncedSearchText = $0 }
    }

    func predicate(search: String) -> NSPredicate? {
        var predicates: [NSPredicate] = []
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR noteDescription CONTAINS[cd] %@", query, query))
        }
        if selectedCategory == "General" {
            predicates.append(NSPredicate(format: "category == %@ OR category == nil OR category == ''", "General"))
        } else if selectedCategory != "All" {
            predicates.append(NSPredicate(format: "category == %@", selectedCategory))
        }
        if showFavoritesOnly { predicates.append(NSPredicate(format: "isFavorite == YES")) }
        return predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    func fetchRequest(search: String) -> NSFetchRequest<NotesTable> {
        let request = NotesTable.fetchRequest()
        request.predicate = predicate(search: search)
        request.sortDescriptors = [sortOption.descriptor, NSSortDescriptor(key: "id", ascending: true)]
        request.fetchBatchSize = 40
        return request
    }
    
    enum SortOption: String, CaseIterable {
        case title = "Title"
        case dateCreated = "Date Created"
        case dateModified = "Date Modified"
        case category = "Category"
        
        var descriptor: NSSortDescriptor {
            switch self {
            case .title:
                return NSSortDescriptor(keyPath: \NotesTable.title, ascending: true)
            case .dateCreated:
                return NSSortDescriptor(keyPath: \NotesTable.createdDate, ascending: false)
            case .dateModified:
                return NSSortDescriptor(keyPath: \NotesTable.modifiedDate, ascending: false)
            case .category:
                return NSSortDescriptor(keyPath: \NotesTable.category, ascending: true)
            }
        }
    }
    
    let categories = ["All", "Work", "Personal", "Ideas", "Shopping", "Travel", "Health", "Finance", "Education", "General"]
    
    func shouldShowNote(_ note: NotesTable) -> Bool {
        let matchesSearch = searchText.isEmpty ||
            (note.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (note.noteDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
        
        let matchesCategory = selectedCategory == "All" || note.displayCategory == selectedCategory
        
        let matchesFavorites = !showFavoritesOnly || note.isFavorite
        
        return matchesSearch && matchesCategory && matchesFavorites
    }
}
