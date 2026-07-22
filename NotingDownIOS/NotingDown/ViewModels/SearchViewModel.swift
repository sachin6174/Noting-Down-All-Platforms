import Foundation
import SwiftUI

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedCategory = "All"
    @Published var sortOption: SortOption = .dateModified
    @Published var showFavoritesOnly = false
    
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
