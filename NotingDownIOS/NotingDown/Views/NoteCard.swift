import SwiftUI

struct NoteCard: View {
    let note: NotesTable
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.paddingS) {
            // Header with title and favorite button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title ?? "Untitled")
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(note.displayCategory)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.categoryColors[note.displayCategory] ?? .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            (Theme.categoryColors[note.displayCategory] ?? .gray)
                                .opacity(0.2)
                        )
                        .cornerRadius(12)
                }
                
                Spacer()
                
                Button(action: onFavoriteToggle) {
                    Image(systemName: note.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(note.isFavorite ? .red : Theme.textSecondary)
                        .font(.system(size: 18))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Description preview
            if let description = note.noteDescription, !description.isEmpty {
                Text(description)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            // Footer with date and actions
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if let createdDate = note.createdDate {
                        Text("Created: \(createdDate, style: .date)")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textTertiary)
                    }
                    
                    if let modifiedDate = note.modifiedDate {
                        Text("Modified: \(modifiedDate, style: .relative)")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textTertiary)
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(Theme.paddingM)
        .cardStyle()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

struct NoteCard_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataStack.shared.context
        let note = NotesTable(context: context)
        note.title = "Sample Note"
        note.noteDescription = "This is a sample note description that shows how the card looks with content."
        note.category = "Work"
        note.createdDate = Date()
        note.modifiedDate = Date()
        note.isFavorite = true
        
        return NoteCard(note: note, onFavoriteToggle: {}, onDelete: {})
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
