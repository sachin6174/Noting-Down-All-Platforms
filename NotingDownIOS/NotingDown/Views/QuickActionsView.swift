import SwiftUI

struct QuickActionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var showEditor: Bool
    @State private var selectedTemplate: NoteTemplate?
    
    enum NoteTemplate: String, CaseIterable {
        case blank = "Blank Note"
        case meeting = "Meeting Notes"
        case todo = "To-Do List"
        case idea = "Idea"
        case journal = "Journal Entry"
        case shopping = "Shopping List"
        
        var icon: String {
            switch self {
            case .blank: return "doc"
            case .meeting: return "person.3"
            case .todo: return "checklist"
            case .idea: return "lightbulb"
            case .journal: return "book"
            case .shopping: return "cart"
            }
        }
        
        var category: String {
            switch self {
            case .blank: return "General"
            case .meeting: return "Work"
            case .todo: return "Personal"
            case .idea: return "Ideas"
            case .journal: return "Personal"
            case .shopping: return "Shopping"
            }
        }
        
        var template: String {
            switch self {
            case .blank:
                return ""
            case .meeting:
                return """
                Meeting: 
                Date: \(Date().formatted(date: .abbreviated, time: .shortened))
                Attendees: 
                
                Agenda:
                • 
                
                Discussion:
                
                
                Action Items:
                • 
                """
            case .todo:
                return """
                To-Do List - \(Date().formatted(date: .abbreviated, time: .omitted))
                
                ☐ 
                ☐ 
                ☐ 
                ☐ 
                ☐ 
                """
            case .idea:
                return """
                💡 Idea
                
                Problem/Opportunity:
                
                
                Solution/Approach:
                
                
                Next Steps:
                • 
                """
            case .journal:
                return """
                \(Date().formatted(date: .complete, time: .omitted))
                
                Today I feel...
                
                
                What happened today:
                
                
                What I learned:
                
                
                Tomorrow I want to:
                
                """
            case .shopping:
                return """
                Shopping List - \(Date().formatted(date: .abbreviated, time: .omitted))
                
                Groceries:
                ☐ 
                ☐ 
                
                Household:
                ☐ 
                ☐ 
                
                Other:
                ☐ 
                ☐ 
                """
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.paddingM) {
            Text("Quick Start")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Theme.paddingM)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Theme.paddingM) {
                ForEach(NoteTemplate.allCases, id: \.self) { template in
                    TemplateCard(template: template) {
                        createNoteFromTemplate(template)
                    }
                }
            }
            .padding(.horizontal, Theme.paddingM)
        }
    }
    
    private func createNoteFromTemplate(_ template: NoteTemplate) {
        let newNote = NotesTable(context: viewContext)
        newNote.id = UUID()
        newNote.title = template.rawValue
        newNote.noteDescription = template.template
        newNote.category = template.category
        newNote.createdDate = Date()
        newNote.modifiedDate = Date()
        newNote.isFavorite = false
        
        do {
            try viewContext.save()
            showEditor = false
        } catch {
            print("Error creating note from template: \(error.localizedDescription)")
        }
    }
}

struct TemplateCard: View {
    let template: QuickActionsView.NoteTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.paddingS) {
                Image(systemName: template.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Theme.primaryGreen)
                
                Text(template.rawValue)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.paddingM)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionsView_Previews: PreviewProvider {
    @State static var showEditor = false
    
    static var previews: some View {
        QuickActionsView(showEditor: $showEditor)
            .environment(\.managedObjectContext, CoreDataStack.shared.context)
    }
}
