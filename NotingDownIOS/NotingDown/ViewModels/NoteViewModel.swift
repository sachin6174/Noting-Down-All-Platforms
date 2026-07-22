import Foundation

class NoteViewModel: ObservableObject {
    @Published var notes: [Note] = []

    init() {
        // Add demo note on launch
        notes.append(Note(title: "Demo Note", description: "This is a demo note."))
    }

    func add(note: Note) {
        notes.append(note)
    }

    func delete(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
    }

    func update(note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
    }

    func delete(note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes.remove(at: index)
        }
    }
}
