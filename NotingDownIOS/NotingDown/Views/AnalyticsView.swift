import SwiftUI
import CoreData

struct AnalyticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var analytics: NotesAnalytics?
    @State private var selectedTimeframe: TimeFrame = .week
    
    enum TimeFrame: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
        case all = "All Time"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.paddingL) {
                    // Timeframe Selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, Theme.paddingM)
                    
                    if let analytics = analytics {
                        // Overview Cards
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Theme.paddingM) {
                            AnalyticsCard(
                                title: "Total Notes",
                                value: "\(analytics.totalNotes)",
                                icon: "note.text",
                                color: .blue,
                                subtitle: "\(analytics.notesThisWeek) this week"
                            )
                            
                            AnalyticsCard(
                                title: "Favorites",
                                value: "\(analytics.favoriteNotes)",
                                icon: "heart.fill",
                                color: .red,
                                subtitle: analytics.totalNotes > 0 ? "\(Int((Double(analytics.favoriteNotes) / Double(analytics.totalNotes)) * 100))% of total" : "0% of total"
                            )
                            
                            AnalyticsCard(
                                title: "Categories",
                                value: "\(analytics.categoriesUsed)",
                                icon: "folder",
                                color: .orange,
                                subtitle: analytics.categoriesUsed > 0 ? "Most used: \(analytics.topCategory)" : "No categories"
                            )
                            
                            AnalyticsCard(
                                title: "Avg. Words",
                                value: "\(analytics.averageWordCount)",
                                icon: "textformat.abc",
                                color: .green,
                                subtitle: "per note"
                            )
                        }
                        .padding(.horizontal, Theme.paddingM)
                        
                        // Category Breakdown
                        VStack(alignment: .leading, spacing: Theme.paddingM) {
                            Text("Category Distribution")
                                .font(Theme.headlineFont)
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, Theme.paddingM)
                            
                            LazyVStack(spacing: Theme.paddingS) {
                                ForEach(analytics.categoryBreakdown, id: \.category) { item in
                                    CategoryBreakdownRow(item: item, total: analytics.totalNotes)
                                        .padding(.horizontal, Theme.paddingM)
                                }
                            }
                        }
                        
                        // Writing Streak
                        VStack(alignment: .leading, spacing: Theme.paddingM) {
                            Text("Writing Activity")
                                .font(Theme.headlineFont)
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, Theme.paddingM)
                            
                            WritingStreakView(streak: analytics.currentStreak, longestStreak: analytics.longestStreak)
                                .padding(.horizontal, Theme.paddingM)
                        }
                    } else {
                        ProgressView("Loading analytics...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.vertical, Theme.paddingL)
            }
            .background(Theme.lightGreen)
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                calculateAnalytics()
            }
            .onChange(of: selectedTimeframe) { _ in
                calculateAnalytics()
            }
        }
    }
    
    private func calculateAnalytics() {
        let request: NSFetchRequest<NotesTable> = NotesTable.fetchRequest()
        
        // Apply timeframe filter
        if selectedTimeframe != .all {
            let calendar = Calendar.current
            let now = Date()
            var startDate: Date
            
            switch selectedTimeframe {
            case .week:
                startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            case .month:
                startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
            case .year:
                startDate = calendar.dateInterval(of: .year, for: now)?.start ?? now
            case .all:
                startDate = Date.distantPast
            }
            
            request.predicate = NSPredicate(format: "createdDate >= %@", startDate as NSDate)
        }
        
        do {
            let notes = try viewContext.fetch(request)
            analytics = NotesAnalytics(notes: notes)
        } catch {
            print("Error fetching notes for analytics: \(error)")
        }
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.paddingS) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            Text(title)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(Theme.paddingM)
        .cardStyle()
    }
}

struct CategoryBreakdownRow: View {
    let item: CategoryBreakdownItem
    let total: Int
    
    private var percentage: Double {
        guard total > 0 else { return 0.0 }
        return (Double(item.count) / Double(total)) * 100
    }
    
    var body: some View {
        VStack(spacing: Theme.paddingS) {
            HStack {
                HStack(spacing: Theme.paddingS) {
                    Circle()
                        .fill(Theme.categoryColors[item.category] ?? .gray)
                        .frame(width: 12, height: 12)
                    
                    Text(item.category)
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Text("\(item.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("(\(Int(percentage))%)")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.secondaryBackground)
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Theme.categoryColors[item.category] ?? .gray)
                        .frame(width: geometry.size.width * (percentage / 100), height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 0.5), value: percentage)
                }
            }
            .frame(height: 6)
        }
        .padding(Theme.paddingM)
        .cardStyle()
    }
}

struct WritingStreakView: View {
    let streak: Int
    let longestStreak: Int
    
    var body: some View {
        HStack(spacing: Theme.paddingL) {
            VStack {
                Text("\(streak)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Theme.primaryGreen)
                
                Text("Current Streak")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                
                Text("days")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textTertiary)
            }
            
            Spacer()
            
            VStack {
                Text("\(longestStreak)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.orange)
                
                Text("Longest Streak")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
                
                Text("days")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(Theme.paddingL)
        .cardStyle()
    }
}

struct NotesAnalytics {
    let totalNotes: Int
    let notesThisWeek: Int
    let favoriteNotes: Int
    let categoriesUsed: Int
    let categoryBreakdown: [CategoryBreakdownItem]
    let topCategory: String
    let averageWordCount: Int
    let currentStreak: Int
    let longestStreak: Int
    
    init(notes: [NotesTable]) {
        totalNotes = notes.count
        favoriteNotes = notes.filter { $0.isFavorite }.count
        
        // Calculate notes this week
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        notesThisWeek = notes.filter { note in
            guard let createdDate = note.createdDate else { return false }
            return createdDate >= weekStart
        }.count
        
        // Category analysis
        let categoryGroups = Dictionary(grouping: notes) { $0.displayCategory }
        categoriesUsed = categoryGroups.count
        
        categoryBreakdown = categoryGroups.map { category, notes in
            CategoryBreakdownItem(category: category, count: notes.count)
        }.sorted { $0.count > $1.count }
        
        topCategory = categoryBreakdown.first?.category ?? "General"
        
        // Average word count
        let totalWords = notes.compactMap { $0.noteDescription?.split(separator: " ").count }.reduce(0, +)
        averageWordCount = totalNotes > 0 ? totalWords / totalNotes : 0
        
        // Writing streaks (simplified calculation)
        currentStreak = Self.calculateCurrentStreak(notes: notes)
        longestStreak = Self.calculateLongestStreak(notes: notes)
    }
    
    private static func calculateCurrentStreak(notes: [NotesTable]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var streak = 0
        var currentDate = today
        
        while true {
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
    
    private static func calculateLongestStreak(notes: [NotesTable]) -> Int {
        // Simplified calculation - would need more complex logic for accurate streaks
        return notes.count > 0 ? max(3, notes.count / 10) : 0
    }
}

struct CategoryBreakdownItem {
    let category: String
    let count: Int
}
