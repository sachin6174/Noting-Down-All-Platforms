import SwiftUI
import CoreData

struct AddNoteView: View {
    @Environment(\.managedObjectContext) private var moc
    @Binding var isPresented: Bool
    
    @State private var titleText: String = ""
    @State private var noteText: String = ""
    @State private var showingAlert = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Title")
                    .font(.headline)

                TextField("Enter title", text: $titleText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Text("Description")
                    .font(.headline)

                TextEditor(text: $noteText)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )

                HStack {
                    Spacer()
                    Button("Cancel") {
                        isPresented = false
                    }
                    .frame(width: 80, height: 30)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Button("Save") {
                        addNote()
                    }
                    .frame(width: 80, height: 30)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()

            // Show the temporary alert view when needed
            if showingAlert {
                TemporaryAlertMessageView(message: "Title and description cannot be empty")
                    .transition(.opacity)
                    .zIndex(1)  // Ensure it appears above other views
            }
        }
    }

    private func addNote() {
        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = noteText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedDescription.isEmpty else {
            // Show alert for 2 seconds
            showingAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showingAlert = false
                }
            }
            return
        }

        // Create the new Core Data object (NotesTable must exist in your .xcdatamodeld)
        let newNote = NotesTable(context: moc)
        newNote.id = UUID()
        newNote.title = trimmedTitle
        newNote.noteDescription = trimmedDescription

        do {
            try moc.save()
        } catch {
            print("Error saving note: \(error.localizedDescription)")
        }
        isPresented = false
    }
}

// A renamed alert view so it won't clash with any existing 'TemporaryAlertView'
struct TemporaryAlertMessageView: View {
    let message: String

    var body: some View {
        VStack {
            Text(message)
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(8)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Preview

struct AddNoteView_Previews: PreviewProvider {
    static var previews: some View {
        // If you only have PersistenceController.shared, use that:
        AddNoteView(isPresented: .constant(true))
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
