import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) var viewContext
    @StateObject private var searchViewModel = SearchViewModel()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NotesTable.modifiedDate, ascending: false)],
        animation: .default)
    private var allNotes: FetchedResults<NotesTable>
    
    @State private var showEditor = false
    @State private var editingNote: NotesTable? = nil
    @State private var noteToDelete: NotesTable? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var showingEmptyState = false
    @State private var showingAnalytics = false
    @State private var showingVoiceNote = false
    @State private var showingSettings = false
    
    private var filteredNotes: [NotesTable] {
        allNotes.filter { note in
            searchViewModel.shouldShowNote(note)
        }.sorted { note1, note2 in
            let descriptor = searchViewModel.sortOption.descriptor
            let comparison = descriptor.compare(note1, to: note2)
            return descriptor.ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search and filters
                VStack(spacing: Theme.paddingS) {
                    // Search bar
                    SearchBar(searchText: $searchViewModel.searchText)
                    
                    // Filter chips
                    FilterView(searchViewModel: searchViewModel)
                }
                .padding(.horizontal, Theme.paddingM)
                .padding(.bottom, Theme.paddingS)
                .background(Theme.lightGreen)
                
                // Notes list or empty state
                if filteredNotes.isEmpty {
                    EmptyStateView(
                        hasNotes: !allNotes.isEmpty,
                        searchText: searchViewModel.searchText
                    ) {
                        // Clear filters action
                        searchViewModel.searchText = ""
                        searchViewModel.selectedCategory = "All"
                        searchViewModel.showFavoritesOnly = false
                    }
                } else {
                    VStack(spacing: 0) {
                        // Smart Suggestions (only show when not searching)
                        if searchViewModel.searchText.isEmpty && searchViewModel.selectedCategory == "All" && !searchViewModel.showFavoritesOnly {
                            SmartSuggestionsView()
                                .padding(.bottom, Theme.paddingM)
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: Theme.paddingS) {
                                ForEach(filteredNotes, id: \.objectID) { note in
                                    NavigationLink(destination: NoteDetailView(note: note)) {
                                        NoteCard(
                                            note: note,
                                            onFavoriteToggle: {
                                                toggleFavorite(note: note)
                                            },
                                            onDelete: {
                                                confirmDelete(note: note)
                                            }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, Theme.paddingM)
                            .padding(.top, Theme.paddingS)
                        }
                    }
                    .background(Theme.lightGreen)
                }
                
                Spacer()
            }
            .background(Theme.lightGreen)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.primaryGreen)
                        Text("NotingDown")
                            .font(Theme.titleFont)
                            .foregroundColor(Theme.textPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: Theme.paddingS) {
                        Button(action: { showingVoiceNote = true }) {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            editingNote = nil
                            showEditor = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Theme.primaryGreen)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { showingAnalytics = true }) {
                            Label("Analytics", systemImage: "chart.bar")
                        }
                        
                        Button(action: { showingSettings = true }) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        Divider()
                        
                        Button(action: { exportNotes() }) {
                            Label("Export All Notes", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { shareApp() }) {
                            Label("Share App", systemImage: "heart")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.primaryGreen)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showEditor) {
            EnhancedNoteEditorView(note: editingNote)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingVoiceNote) {
            VoiceNoteView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingAnalytics) {
            AnalyticsView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("Delete Note", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let note = noteToDelete {
                    delete(note: note)
                }
                noteToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                noteToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
        .onAppear {
            updateFetchRequest()
        }
        .onChange(of: searchViewModel.sortOption) { _ in
            updateFetchRequest()
        }
    }
    
    private func updateFetchRequest() {
        // This will be handled by our custom filtering logic
    }
    
    private func toggleFavorite(note: NotesTable) {
        withAnimation(.easeInOut(duration: 0.3)) {
            note.isFavorite.toggle()
            note.modifiedDate = Date()
            saveContext()
        }
    }
    
    private func confirmDelete(note: NotesTable) {
        noteToDelete = note
        showDeleteConfirmation = true
    }
    
    private func delete(note: NotesTable) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewContext.delete(note)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
    
    private func exportNotes() {
        let exportText = allNotes.map { note in
            """
            Title: \(note.title ?? "Untitled")
            Category: \(note.displayCategory)
            Created: \(note.formattedCreatedDate)
            Modified: \(note.formattedModifiedDate)
            
            \(note.noteDescription ?? "")
            
            ---
            
            """
        }.joined()
        
        let activityVC = UIActivityViewController(
            activityItems: [exportText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func shareApp() {
        let appURL = URL(string: "https://apps.apple.com/us/app/notingdown/id6742340327")!
        let activityVC = UIActivityViewController(
            activityItems: ["Check out NotingDown - A beautiful note-taking app!", appURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

struct EmptyStateView: View {
    let hasNotes: Bool
    let searchText: String
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.paddingL) {
            Image(systemName: hasNotes ? "magnifyingglass" : "note.text")
                .font(.system(size: 60))
                .foregroundColor(Theme.textTertiary)
            
            VStack(spacing: Theme.paddingS) {
                Text(hasNotes ? "No notes found" : "No notes yet")
                    .font(Theme.headlineFont)
                    .foregroundColor(Theme.textPrimary)
                
                Text(hasNotes ? 
                     "Try adjusting your search or filters" :
                     "Create your first note to get started")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if hasNotes {
                Button("Clear Filters", action: onClearFilters)
                    .primaryButtonStyle()
            }
        }
        .padding(Theme.paddingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.lightGreen)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, CoreDataStack.shared.context)
}
