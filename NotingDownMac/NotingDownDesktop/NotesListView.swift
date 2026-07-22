import CoreData
import SwiftUI

struct NotesListView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NotesTable.title, ascending: true)],
        animation: .default
    ) private var notes: FetchedResults<NotesTable>

    @State private var selectedNote: NotesTable?
    @State private var isNewNotePresented = false
    @State private var searchText: String = ""

    var filteredNotes: [NotesTable] {
        if searchText.isEmpty {
            return Array(notes)
        } else {
            return notes.filter {
                ($0.title ?? "").localizedCaseInsensitiveContains(searchText)
                    || ($0.noteDescription ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(AppStyle.padding)
                    .background(Color.gray.opacity(0.05))

                ScrollViewReader { proxy in
                    List(filteredNotes) { note in
                        Button(action: {
                            selectedNote = note
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(note.title ?? "Untitled")
                                    .font(.headline)
                                    .foregroundColor(
                                        selectedNote?.id == note.id
                                            ? .blue : AppStyle.Colors.textPrimary
                                    )
                                Text(note.noteDescription ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(AppStyle.Colors.textSecondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .id(note.id)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden)
                    .onChange(of: selectedNote) { oldValue, newNote in
                        if let noteId = newNote?.id {
                            withAnimation {
                                proxy.scrollTo(noteId, anchor: .center)
                            }
                        }
                    }
                }
            }
            .frame(width: 280)
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        selectedNote = nil
                        isNewNotePresented = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .background(Color.appBackground)
        } detail: {
            if let selectedNote = selectedNote {
                NoteEditorView(
                    note: selectedNote, selectedNote: $selectedNote,
                    isPresented: $isNewNotePresented
                )
                .id(selectedNote.objectID)  // Force view update when selection changes
            } else {
                Text("Select a note or create a new one")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(
            isPresented: $isNewNotePresented,
            onDismiss: {
                if selectedNote == nil && !notes.isEmpty {
                    selectedNote = notes.last
                }
            }
        ) {
            NavigationStack {
                NoteEditorView(
                    note: nil, selectedNote: $selectedNote, isPresented: $isNewNotePresented
                )
                .environment(\.managedObjectContext, moc)
            }
            .frame(width: 600, height: 520)
            .background(Color(.windowBackgroundColor))
        }
        .onAppear {
            if selectedNote == nil && !notes.isEmpty {
                selectedNote = notes[notes.count - 1]
            }
        }
    }
}
