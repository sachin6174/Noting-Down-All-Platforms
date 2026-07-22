import SwiftUI
import CoreData

struct SmartSuggestionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var suggestions: [NoteSuggestion] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.paddingM) {
            Text("Smart Suggestions")
                .font(Theme.headlineFont)
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Theme.paddingM)
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating suggestions...")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, Theme.paddingM)
            } else if suggestions.isEmpty {
                Text("No suggestions available")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, Theme.paddingM)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.paddingM) {
                        ForEach(suggestions, id: \.id) { suggestion in
                            SuggestionCard(suggestion: suggestion) {
                                applySuggestion(suggestion)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.paddingM)
                }
            }
        }
        .onAppear {
            generateSuggestions()
        }
    }
    
    private func generateSuggestions() {
        // Simulate AI-powered suggestion generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.suggestions = SmartSuggestionEngine.generateSuggestions(from: self.getAllNotes())
            self.isLoading = false
        }
    }
    
    private func getAllNotes() -> [NotesTable] {
        let request: NSFetchRequest<NotesTable> = NotesTable.fetchRequest()
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching notes: \(error)")
            return []
        }
    }
    
    private func applySuggestion(_ suggestion: NoteSuggestion) {
        // Apply the suggestion (create note, add reminder, etc.)
        let newNote = NotesTable(context: viewContext)
        newNote.id = UUID()
        newNote.title = suggestion.title
        newNote.noteDescription = suggestion.content
        newNote.category = suggestion.suggestedCategory
        newNote.createdDate = Date()
        newNote.modifiedDate = Date()
        newNote.isFavorite = false
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving suggested note: \(error)")
        }
    }
}

struct SuggestionCard: View {
    let suggestion: NoteSuggestion
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.paddingS) {
                HStack {
                    Image(systemName: suggestion.icon)
                        .foregroundColor(suggestion.color)
                        .font(.system(size: 20))
                    
                    Spacer()
                    
                    Text(suggestion.type.rawValue)
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textTertiary)
                }
                
                Text(suggestion.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Text(suggestion.description)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Text("Tap to create")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.primaryGreen)
                }
            }
            .padding(Theme.paddingM)
            .frame(width: 200, height: 120)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NoteSuggestion {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let description: String
    let content: String
    let suggestedCategory: String
    let icon: String
    let color: Color
    let priority: Int
}

enum SuggestionType: String {
    case reminder = "Reminder"
    case followUp = "Follow-up"
    case template = "Template"
    case related = "Related"
    case trend = "Trending"
}

class SmartSuggestionEngine {
    static func generateSuggestions(from notes: [NotesTable]) -> [NoteSuggestion] {
        var suggestions: [NoteSuggestion] = []
        
        // Add time-based suggestions
        suggestions.append(contentsOf: generateTimeBased())
        
        // Add content-based suggestions
        suggestions.append(contentsOf: generateContentBased(from: notes))
        
        // Add habit-based suggestions
        suggestions.append(contentsOf: generateHabitBased(from: notes))
        
        // Sort by priority and return top suggestions
        return Array(suggestions.sorted { $0.priority > $1.priority }.prefix(5))
    }
    
    private static func generateTimeBased() -> [NoteSuggestion] {
        let calendar = Calendar.current
        let now = Date()
        var suggestions: [NoteSuggestion] = []
        
        // Morning routine suggestion
        if calendar.component(.hour, from: now) < 10 {
            suggestions.append(NoteSuggestion(
                type: .template,
                title: "Morning Routine",
                description: "Start your day with intention",
                content: """
                🌅 Morning Routine - \(now.formatted(date: .abbreviated, time: .omitted))
                
                ☐ Review today's goals
                ☐ Check priorities
                ☐ Morning exercise/meditation
                ☐ Healthy breakfast
                
                Mood: 
                Energy Level: 
                
                Today's Focus:
                """,
                suggestedCategory: "Personal",
                icon: "sunrise",
                color: .orange,
                priority: 8
            ))
        }
        
        // Weekend planning
        if calendar.component(.weekday, from: now) == 6 { // Friday
            suggestions.append(NoteSuggestion(
                type: .template,
                title: "Weekend Planning",
                description: "Plan your weekend activities",
                content: """
                🎯 Weekend Plan - \(now.formatted(date: .abbreviated, time: .omitted))
                
                Saturday:
                ☐ 
                ☐ 
                ☐ 
                
                Sunday:
                ☐ 
                ☐ 
                ☐ 
                
                Fun Activities:
                • 
                • 
                
                Self-care:
                • 
                """,
                suggestedCategory: "Personal",
                icon: "calendar.badge.plus",
                color: .blue,
                priority: 7
            ))
        }
        
        return suggestions
    }
    
    private static func generateContentBased(from notes: [NotesTable]) -> [NoteSuggestion] {
        var suggestions: [NoteSuggestion] = []
        
        // Analyze note patterns
        let categories = notes.compactMap { $0.category }
        let categoryCounts = Dictionary(grouping: categories, by: { $0 }).mapValues { $0.count }
        let topCategory = categoryCounts.max { $0.value < $1.value }?.key ?? "Work"
        
        // Suggest follow-up based on most used category
        if categoryCounts[topCategory] ?? 0 > 3 {
            suggestions.append(NoteSuggestion(
                type: .followUp,
                title: "\(topCategory) Review",
                description: "Review your recent \(topCategory.lowercased()) notes",
                content: """
                📝 \(topCategory) Review - \(Date().formatted(date: .abbreviated, time: .omitted))
                
                Recent Accomplishments:
                • 
                • 
                • 
                
                Pending Items:
                • 
                • 
                • 
                
                Next Steps:
                • 
                • 
                
                Reflections:
                
                """,
                suggestedCategory: topCategory,
                icon: "arrow.triangle.2.circlepath",
                color: Theme.categoryColors[topCategory] ?? .gray,
                priority: 6
            ))
        }
        
        // Suggest weekly review if user has many notes
        if notes.count > 10 {
            suggestions.append(NoteSuggestion(
                type: .template,
                title: "Weekly Review",
                description: "Reflect on your week",
                content: """
                🔄 Weekly Review - Week of \(Date().formatted(date: .abbreviated, time: .omitted))
                
                Key Achievements:
                1. 
                2. 
                3. 
                
                Challenges Faced:
                • 
                • 
                
                Lessons Learned:
                • 
                • 
                
                Next Week's Focus:
                1. 
                2. 
                3. 
                
                Gratitude:
                • 
                • 
                """,
                suggestedCategory: "Personal",
                icon: "arrow.clockwise",
                color: .purple,
                priority: 5
            ))
        }
        
        return suggestions
    }
    
    private static func generateHabitBased(from notes: [NotesTable]) -> [NoteSuggestion] {
        var suggestions: [NoteSuggestion] = []
        
        let recentNotes = notes.filter { note in
            guard let createdDate = note.createdDate else { return false }
            return Date().timeIntervalSince(createdDate) < 7 * 24 * 60 * 60 // Last 7 days
        }
        
        // If user is active, suggest habit tracking
        if recentNotes.count > 5 {
            suggestions.append(NoteSuggestion(
                type: .template,
                title: "Habit Tracker",
                description: "Track your daily habits",
                content: """
                📊 Habit Tracker - \(Date().formatted(date: .abbreviated, time: .omitted))
                
                Daily Habits:
                ☐ Exercise (30 min)
                ☐ Read (20 min)
                ☐ Meditate (10 min)
                ☐ Drink 8 glasses of water
                ☐ Take notes/journal
                ☐ Connect with someone
                
                Weekly Goals:
                ☐ 
                ☐ 
                ☐ 
                
                Notes:
                
                """,
                suggestedCategory: "Health",
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                priority: 4
            ))
        }
        
        return suggestions
    }
}
