import CoreData
import SwiftUI

struct NoteEditorView: View {
    // MARK: - Environment & Fetch
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NotesTable.title, ascending: true)],
        animation: .default
    ) private var allNotes: FetchedResults<NotesTable>

    // MARK: - External Bindings
    var note: NotesTable?
    @Binding var selectedNote: NotesTable?
    @Binding var isPresented: Bool

    // MARK: - State
    @State private var title: String = ""
    @State private var noteDescription: String = ""
    @State private var showingDeleteAlert = false
    @State private var showingAlert = false
    @State private var showNoNotesAlert = false
    @State private var originalTitle: String = ""
    @State private var originalDescription: String = ""
    @State private var isEditing: Bool = false

    private let maxTitleLength = 50
    private let maxDescriptionLength = 1000

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            AppStyle.Colors.background
                .ignoresSafeArea()

            // Main content
            contentView
                .padding(AppStyle.padding)
                .overlay(alertView)  // Show "title/description empty" alert if needed
        }
        .frame(width: 600, height: 520)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Color.clear.frame(width: 1)  // This creates an empty space instead of the title
            }
            toolbarContent
        }
        .onAppear(perform: loadNoteData)
        .onChange(of: note) { _, newValue in
            updateNoteData(newValue)
        }
        .alert("Delete Note?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let noteToDelete = note {
                    handleNoteDeletion(noteToDelete)
                    isPresented = false
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert(isPresented: $showNoNotesAlert) {
            noNotesAlert
        }
    }

    // MARK: - Main Content
    private var contentView: some View {
        VStack(spacing: AppStyle.spacing) {
            // Title Section (removed duplicate header here)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Title")
                        .font(.headline)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    Spacer()
                    Text("\(title.count)/\(maxTitleLength)")
                        .font(.caption)
                        .foregroundColor(title.count > maxTitleLength ? .red : .gray)
                }

                TextField("Enter title", text: $title)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(AppStyle.cornerRadius)
                    .onChange(of: title) { oldValue, newValue in
                        if newValue.count > maxTitleLength {
                            DispatchQueue.main.async {
                                title = String(newValue.prefix(maxTitleLength))
                            }
                        }
                    }
            }

            // Description Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Description")
                        .font(.headline)
                        .foregroundColor(AppStyle.Colors.textPrimary)
                    Spacer()
                    Text("\(noteDescription.count)/\(maxDescriptionLength)")
                        .font(.caption)
                        .foregroundColor(
                            noteDescription.count > maxDescriptionLength ? .red : .gray)
                }

                TextEditor(text: $noteDescription)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(AppStyle.cornerRadius)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .onChange(of: noteDescription) { oldValue, newValue in
                        if newValue.count > maxDescriptionLength {
                            DispatchQueue.main.async {
                                noteDescription = String(newValue.prefix(maxDescriptionLength))
                            }
                        }
                    }
            }

            Spacer()

            // Action Buttons
            HStack(spacing: AppStyle.spacing) {
                Button("Cancel") {
                    if note == nil {
                        isPresented = false
                    } else {
                        title = originalTitle
                        noteDescription = originalDescription
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.escape, modifiers: [])

                Button("Save") {
                    handleSave()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(title.isEmpty || noteDescription.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(20)
        .background(Color(.windowBackgroundColor))
        .animation(.easeInOut(duration: 0.2), value: showingAlert)
    }

    // Update the alert view to be more polished
    private var alertView: some View {
        Group {
            if showingAlert {
                TemporaryAlertView(message: "Please fill in both title and description")
                    .transition(.moveAndFade)
                    .zIndex(1)
            }
        }
    }

    // MARK: - Toolbar (Delete Button, etc.)
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            if note != nil {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    // MARK: - Delete & No-Notes Alerts
    private var noNotesAlert: Alert {
        Alert(
            title: Text("No Notes"),
            message: Text("There are no notes to delete."),
            dismissButton: .cancel(Text("OK"))
        )
    }

    // MARK: - Helpers
    private func handleNoteDeletion(_ note: NotesTable) {
        guard let currentIndex = allNotes.firstIndex(of: note) else { return }

        // Select next note before deletion
        if currentIndex + 1 < allNotes.count {
            selectedNote = allNotes[currentIndex + 1]
        } else if currentIndex > 0 {
            selectedNote = allNotes[currentIndex - 1]
        } else {
            selectedNote = nil
        }

        // Perform deletion
        moc.delete(note)
        do {
            try moc.save()
        } catch {
            print("Error deleting note: \(error)")
        }
    }

    private func handleSave() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = noteDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        // Show a temporary alert if empty
        guard !trimmedTitle.isEmpty, !trimmedDescription.isEmpty else {
            showingAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingAlert = false
            }
            return
        }

        // If editing an existing note
        if let note = note {
            note.title = trimmedTitle
            note.noteDescription = trimmedDescription
            try? moc.save()

            // Update "original" so if user cancels next time, it reverts to these new values
            originalTitle = trimmedTitle
            originalDescription = trimmedDescription

        } else {
            // Creating a new note
            let newNote = NotesTable(context: moc)
            newNote.id = UUID()
            newNote.title = trimmedTitle
            newNote.noteDescription = trimmedDescription
            try? moc.save()

            selectedNote = newNote
            isPresented = false
        }
    }

    // MARK: - Lifecycle
    private func loadNoteData() {
        // Load existing note data if editing
        if let note = note {
            title = note.title ?? ""
            noteDescription = note.noteDescription ?? ""
            originalTitle = note.title ?? ""
            originalDescription = note.noteDescription ?? ""
        }
    }

    private func updateNoteData(_ newNote: NotesTable?) {
        // Whenever 'note' changes externally, reload fields
        if let newNote = newNote {
            title = newNote.title ?? ""
            noteDescription = newNote.noteDescription ?? ""
            originalTitle = newNote.title ?? ""
            originalDescription = newNote.noteDescription ?? ""
        } else {
            title = ""
            noteDescription = ""
            originalTitle = ""
            originalDescription = ""
        }
    }
}

// Add this extension at the bottom of the file
extension AnyTransition {
    static var moveAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        )
    }
}
