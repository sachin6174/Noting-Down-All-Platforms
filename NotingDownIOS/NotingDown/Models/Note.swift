import Foundation

struct Note: Identifiable, Equatable {
    let id: UUID
    var title: String
    var description: String

    init(id: UUID = UUID(), title: String, description: String) {
        self.id = id
        self.title = title
        self.description = description
    }
}
