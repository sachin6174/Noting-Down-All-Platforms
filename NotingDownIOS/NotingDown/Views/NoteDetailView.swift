import SwiftUI

struct NoteDetailView: View {
    let note: NotesTable
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showEditor = false
    @State private var showShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.paddingL) {
                // Header with category and favorite
                HStack {
                    Text(note.displayCategory)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.categoryColors[note.displayCategory] ?? .gray)
                        .padding(.horizontal, Theme.paddingM)
                        .padding(.vertical, Theme.paddingS)
                        .background(
                            (Theme.categoryColors[note.displayCategory] ?? .gray)
                                .opacity(0.2)
                        )
                        .cornerRadius(16)
                    
                    Spacer()
                    
                    if note.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                    }
                }
                
                // Title
                Text(note.title ?? "Untitled")
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                
                // Metadata
                VStack(alignment: .leading, spacing: Theme.paddingXS) {
                    if let createdDate = note.createdDate {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(Theme.textTertiary)
                                .font(.system(size: 14))
                            Text("Created: \(createdDate, style: .date) at \(createdDate, style: .time)")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                    
                    if let modifiedDate = note.modifiedDate {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(Theme.textTertiary)
                                .font(.system(size: 14))
                            Text("Modified: \(modifiedDate, style: .relative)")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                
                Divider()
                    .background(Theme.primaryGreen.opacity(0.3))
                
                // Content
                if let description = note.noteDescription, !description.isEmpty {
                    Text(description)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textPrimary)
                        .lineSpacing(4)
                } else {
                    Text("No description provided.")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
                        .italic()
                }
                
                Spacer(minLength: 50)
            }
            .padding(Theme.paddingL)
        }
        .background(Theme.lightGreen)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Note Details")
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showEditor = true }) {
                        Label("Edit Note", systemImage: "pencil")
                    }
                    
                    Button(action: { toggleFavorite() }) {
                        Label(
                            note.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: note.isFavorite ? "heart.slash" : "heart"
                        )
                    }
                    
                    Button(action: { shareNote() }) {
                        Label("Share Note", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { deleteNote() }) {
                        Label("Delete Note", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.primaryGreen)
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NoteEditorView(note: note)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private func toggleFavorite() {
        withAnimation(.easeInOut(duration: 0.3)) {
            note.isFavorite.toggle()
            note.modifiedDate = Date()
            saveContext()
        }
    }
    
    private func shareNote() {
        let shareText = """
        \(note.title ?? "Untitled")
        
        \(note.noteDescription ?? "")
        
        Created with NotingDown
        """
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func deleteNote() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewContext.delete(note)
            saveContext()
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
}

struct NoteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataStack.shared.context
        let note = NotesTable(context: context)
        note.title = "Sample Note"
        note.noteDescription = "This is a sample note description that shows how the detail view looks with content."
        note.category = "Work"
        note.createdDate = Date()
        note.modifiedDate = Date()
        note.isFavorite = true
        
        return NavigationView {
            NoteDetailView(note: note)
        }
        .environment(\.managedObjectContext, context)
    }
}
