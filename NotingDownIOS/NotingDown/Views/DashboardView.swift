import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var recentNotes: [NotesTable] = []
    @State private var favoriteNotes: [NotesTable] = []
    @State private var quickStats: DashboardStats?
    @State private var showingAllRecent = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.paddingL) {
                // Welcome Header
                VStack(alignment: .leading, spacing: Theme.paddingS) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(greetingMessage())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            
                            Text("Ready to capture your thoughts?")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            AsyncImage(url: URL(string: "https://via.placeholder.com/50")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Theme.primaryGreen.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(Theme.primaryGreen)
                                    )
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, Theme.paddingM)
                
                // Quick Stats
                if let stats = quickStats {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Theme.paddingM) {
                        QuickStatCard(
                            title: "Notes",
                            value: "\(stats.totalNotes)",
                            subtitle: "Total",
                            icon: "note.text",
                            color: .blue
                        )
                        
                        QuickStatCard(
                            title: "This Week",
                            value: "\(stats.notesThisWeek)",
                            subtitle: "Added",
                            icon: "calendar",
                            color: .green
                        )
                        
                        QuickStatCard(
                            title: "Streak",
                            value: "\(stats.writingStreak)",
                            subtitle: "Days",
                            icon: "flame",
                            color: .orange
                        )
                    }
                    .padding(.horizontal, Theme.paddingM)
                }
                
                // Recent Notes
                VStack(alignment: .leading, spacing: Theme.paddingM) {
                    HStack {
                        Text("Recent Notes")
                            .font(Theme.headlineFont)
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                        
                        if recentNotes.count > 3 {
                            Button("See All") {
                                showingAllRecent = true
                            }
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.primaryGreen)
                        }
                    }
                    .padding(.horizontal, Theme.paddingM)
                    
                    if recentNotes.isEmpty {
                        VStack(spacing: Theme.paddingM) {
                            Image(systemName: "note.text.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.textTertiary)
                            
                            Text("No notes yet")
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.textSecondary)
                            
                            Text("Create your first note to get started!")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Theme.paddingXL)
                        .cardStyle()
                        .padding(.horizontal, Theme.paddingM)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.paddingM) {
                                ForEach(Array(recentNotes.prefix(5).enumerated()), id: \.element.objectID) { index, note in
                                    CompactNoteCard(note: note)
                                        .slideInTransition(delay: Double(index) * 0.1)
                                }
                            }
                            .padding(.horizontal, Theme.paddingM)
                        }
                    }
                }
                
                // Favorites
                if !favoriteNotes.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.paddingM) {
                        Text("Favorites")
                            .font(Theme.headlineFont)
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, Theme.paddingM)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.paddingM) {
                                ForEach(Array(favoriteNotes.prefix(3).enumerated()), id: \.element.objectID) { index, note in
                                    CompactNoteCard(note: note, showFavoriteIcon: true)
                                        .slideInTransition(delay: Double(index) * 0.1)
                                }
                            }
                            .padding(.horizontal, Theme.paddingM)
                        }
                    }
                }
                
                // Quick Actions
                VStack(alignment: .leading, spacing: Theme.paddingM) {
                    Text("Quick Actions")
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)
                        .padding(.horizontal, Theme.paddingM)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Theme.paddingM) {
                        QuickActionButton(
                            title: "New Note",
                            icon: "plus.circle",
                            color: Theme.primaryGreen
                        ) {
                            // Handle new note
                        }
                        
                        QuickActionButton(
                            title: "Voice Note",
                            icon: "mic.circle",
                            color: .red
                        ) {
                            // Handle voice note
                        }
                        
                        QuickActionButton(
                            title: "Quick Idea",
                            icon: "lightbulb.circle",
                            color: .yellow
                        ) {
                            // Handle quick idea
                        }
                        
                        QuickActionButton(
                            title: "Daily Journal",
                            icon: "book.circle",
                            color: .purple
                        ) {
                            // Handle daily journal
                        }
                    }
                    .padding(.horizontal, Theme.paddingM)
                }
            }
            .padding(.vertical, Theme.paddingL)
        }
        .background(Theme.lightGreen)
        .refreshable {
            loadDashboardData()
        }
        .onAppear {
            loadDashboardData()
        }
        .sheet(isPresented: $showingAllRecent) {
            AllRecentNotesView(notes: recentNotes)
        }
    }
    
    private func greetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<22:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }
    
    private func loadDashboardData() {
        let recentRequest: NSFetchRequest<NotesTable> = NotesTable.fetchRequest()
        recentRequest.sortDescriptors = [NSSortDescriptor(keyPath: \NotesTable.modifiedDate, ascending: false)]
        recentRequest.fetchLimit = 10
        
        let favoriteRequest: NSFetchRequest<NotesTable> = NotesTable.fetchRequest()
        favoriteRequest.predicate = NSPredicate(format: "isFavorite == YES")
        favoriteRequest.sortDescriptors = [NSSortDescriptor(keyPath: \NotesTable.modifiedDate, ascending: false)]
        favoriteRequest.fetchLimit = 5
        
        do {
            recentNotes = try viewContext.fetch(recentRequest)
            favoriteNotes = try viewContext.fetch(favoriteRequest)
            
            // Calculate stats
            let allNotesRequest: NSFetchRequest<NotesTable> = NotesTable.fetchRequest()
            let allNotes = try viewContext.fetch(allNotesRequest)
            
            let calendar = Calendar.current
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let notesThisWeek = allNotes.filter { note in
                guard let createdDate = note.createdDate else { return false }
                return createdDate >= weekStart
            }.count
            
            quickStats = DashboardStats(
                totalNotes: allNotes.count,
                notesThisWeek: notesThisWeek,
                writingStreak: calculateWritingStreak(from: allNotes)
            )
            
        } catch {
            print("Error loading dashboard data: \(error)")
        }
    }
    
    private func calculateWritingStreak(from notes: [NotesTable]) -> Int {
        // Simplified streak calculation
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var streak = 0
        var currentDate = today
        
        for _ in 0..<30 { // Check last 30 days maximum
            let hasNoteOnDate = notes.contains { note in
                guard let createdDate = note.createdDate else { return false }
                return calendar.isDate(createdDate, inSameDayAs: currentDate)
            }
            
            if hasNoteOnDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.paddingS) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.paddingM)
        .cardStyle()
    }
}

struct CompactNoteCard: View {
    let note: NotesTable
    let showFavoriteIcon: Bool
    
    init(note: NotesTable, showFavoriteIcon: Bool = false) {
        self.note = note
        self.showFavoriteIcon = showFavoriteIcon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.paddingS) {
            HStack {
                if showFavoriteIcon {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                }
                
                Spacer()
                
                Text(note.displayCategory)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.categoryColors[note.displayCategory])
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        (Theme.categoryColors[note.displayCategory] ?? .gray).opacity(0.2)
                    )
                    .cornerRadius(8)
            }
            
            Text(note.title ?? "Untitled")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)
            
            if let description = note.noteDescription, !description.isEmpty {
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(3)
            }
            
            Spacer()
            
            if let modifiedDate = note.modifiedDate {
                Text(modifiedDate, style: .relative)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .frame(width: 160, height: 120)
        .padding(Theme.paddingM)
        .cardStyle()
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.paddingS) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
            }
            .padding(Theme.paddingM)
            .cardStyle()
        }
        .hapticButton()
    }
}

struct DashboardStats {
    let totalNotes: Int
    let notesThisWeek: Int
    let writingStreak: Int
}

struct AllRecentNotesView: View {
    let notes: [NotesTable]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(notes, id: \.objectID) { note in
                    VStack(alignment: .leading, spacing: Theme.paddingS) {
                        Text(note.title ?? "Untitled")
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.textPrimary)
                        
                        if let description = note.noteDescription {
                            Text(description)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .lineLimit(2)
                        }
                        
                        HStack {
                            Text(note.displayCategory)
                                .font(.system(size: 10))
                                .foregroundColor(Theme.categoryColors[note.displayCategory])
                            
                            Spacer()
                            
                            if let modifiedDate = note.modifiedDate {
                                Text(modifiedDate, style: .relative)
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.textTertiary)
                            }
                        }
                    }
                    .padding(.vertical, Theme.paddingXS)
                }
            }
            .navigationTitle("Recent Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
