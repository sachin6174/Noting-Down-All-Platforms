import CoreData
import SwiftUI

struct NoteEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext

    // Local states to hold user input
    @State var title: String = ""
    @State private var saveError = false
    @State var description: String = ""
    @State var selectedCategory: String = "General"
    @State var isFavorite: Bool = false
    
    @FocusState private var titleFocused: Bool
    @FocusState private var descriptionFocused: Bool

    // If editing an existing note, otherwise nil for a new note
    var note: NotesTable?
    
    private let categories = ["General", "Work", "Personal", "Ideas", "Shopping", "Travel", "Health", "Finance", "Education"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.paddingL) {
                    // Title Section
                    VStack(alignment: .leading, spacing: Theme.paddingS) {
                        HStack {
                            Text("Title")
                                .font(Theme.headlineFont)
                                .foregroundColor(Theme.textPrimary)
                            
                            Spacer()
                            
                            Button(action: { isFavorite.toggle() }) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(isFavorite ? .red : Theme.textSecondary)
                                    .font(.system(size: 20))
                            }
                        }
                        
                        TextField("Enter note title...", text: $title)
                            .accessibilityLabel("Title")
                            .accessibilityIdentifier("editor.title")
                            .font(Theme.bodyFont)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($titleFocused)
                    }
                    .padding(.horizontal, Theme.paddingM)
                    .padding(.top, Theme.paddingM)
                    
                    // Category Section
                    VStack(alignment: .leading, spacing: Theme.paddingS) {
                        Text("Category")
                            .font(Theme.headlineFont)
                            .foregroundColor(Theme.textPrimary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.paddingS) {
                                ForEach(categories, id: \.self) { category in
                                    CategoryChip(
                                        title: category,
                                        isSelected: selectedCategory == category,
                                        color: Theme.categoryColors[category] ?? .gray
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                            .padding(.horizontal, Theme.paddingM)
                        }
                    }
                    .padding(.horizontal, Theme.paddingM)
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: Theme.paddingS) {
                        Text("Description")
                            .font(Theme.headlineFont)
                            .foregroundColor(Theme.textPrimary)
                        
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                VStack {
                                    HStack {
                                        Text("Start writing your note here...")
                                            .foregroundColor(Theme.textTertiary)
                                            .font(Theme.bodyFont)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .padding(.top, 8)
                                .padding(.leading, 5)
                            }
                            
                            TextEditor(text: $description)
                                .accessibilityLabel("Note content")
                                .accessibilityIdentifier("editor.body")
                                .font(Theme.bodyFont)
                                .focused($descriptionFocused)
                                .frame(minHeight: 200)
                        }
                        .padding(Theme.paddingS)
                        .background(Theme.secondaryBackground)
                        .cornerRadius(Theme.cornerRadiusS)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusS)
                                .stroke(descriptionFocused ? Theme.primaryGreen : Color.clear, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, Theme.paddingM)
                    
                    // Word count
                    HStack {
                        Spacer()
                        Text("Words: \(description.split(whereSeparator: \.isWhitespace).count)")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal, Theme.paddingM)
                    
                    Spacer()
                }
            }
            .background(Theme.lightGreen)
            .navigationTitle(LocalizedStringKey(note == nil ? "New Note" : "Edit Note"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .accessibilityIdentifier("editor.save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.primaryGreen)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Could not save note", isPresented: $saveError) {
                Button("OK", role: .cancel) { }
            } message: { Text("Your draft is still open. Please try again.") }
            .onAppear {
                loadNoteData()
                // Focus title for new notes
                if note == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        titleFocused = true
                    }
                }
            }
        }
    }
    
    private func loadNoteData() {
        if let note = note {
            title = note.title ?? ""
            description = note.noteDescription ?? ""
            selectedCategory = note.category ?? "General"
            isFavorite = note.isFavorite
        }
    }
    
    private func saveNote() {
        do {
            try NoteStore(context: viewContext).save(
                note: note, title: title, body: description,
                category: selectedCategory, favorite: isFavorite,
                colorTag: note?.colorTag)
            presentationMode.wrappedValue.dismiss()
        } catch {
            saveError = true
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(LocalizedStringKey(title))
                .font(Theme.captionFont)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, Theme.paddingM)
                .padding(.vertical, Theme.paddingS)
                .background(isSelected ? color : color.opacity(0.2))
                .cornerRadius(20)
                .frame(minHeight: 44)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct NoteEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataStack.shared.context
        return NoteEditorView(note: nil)
            .environment(\.managedObjectContext, context)
    }
}
