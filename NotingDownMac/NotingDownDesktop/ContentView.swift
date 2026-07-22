//
//  ContentView.swift
//  NotingDownDesktop
//
//  Created by sachin kumar on 22/02/25.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(entity: NotesTable.entity(), sortDescriptors: [])
    private var notes: FetchedResults<NotesTable>

    @State private var searchText: String = ""
    @State private var showEditor: Bool = false
    @State private var selectedNote: NotesTable?
    @State private var noteToDelete: NotesTable?
    @State private var showingDeleteConfirmation = false

    var filteredNotes: [NotesTable] {
        if searchText.isEmpty {
            return Array(notes)
        } else {
            return notes.filter {
                ($0.title ?? "").localizedCaseInsensitiveContains(searchText)
                    || ($0.noteDescription ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            // Left sidebar
            VStack(spacing: 0) {
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color.gray.opacity(0.1))

                List {
                    ForEach(Array(filteredNotes.enumerated()), id: \.element) { index, note in
                        Button {
                            selectedNote = note
                        } label: {
                            HStack(spacing: 15) {
                                Text("\(index + 1).")
                                    .bold()
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .leading)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(note.title ?? "No Title")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(note.noteDescription ?? "No Description")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            noteToDelete = filteredNotes[index]
                            showingDeleteConfirmation = true
                        }
                    }
                }
                .listStyle(InsetListStyle())
            }
            .frame(width: 300)  // Fixed width for left panel
            .navigationTitle("Notes")
            .toolbarRole(.automatic)
            .onAppear {
                // Select first note when app launches
                if selectedNote == nil && !filteredNotes.isEmpty {
                    selectedNote = filteredNotes[0]
                }
            }

            // Right detail view
            Group {
                if let note = selectedNote {
                    NoteEditorView(
                        note: note, selectedNote: $selectedNote, isPresented: $showEditor
                    )
                    .environment(\.managedObjectContext, moc)
                    .frame(width: 600)  // Fixed width for right panel
                } else {
                    VStack {
                        Text(notes.isEmpty ? "Add a note" : "Select a note")
                            .foregroundColor(.secondary)
                        if notes.isEmpty {
                            Button {
                                showEditor = true
                            } label: {
                                Label("New Note", systemImage: "plus.circle")
                            }
                            .buttonStyle(.borderless)
                            .padding(.top, 8)
                        }
                    }
                    .frame(width: 600)  // Fixed width for right panel
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NoteEditorView(note: nil, selectedNote: $selectedNote, isPresented: $showEditor)
                .environment(\.managedObjectContext, moc)
        }
        .confirmationDialog(
            "Delete Note?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let note = noteToDelete {
                    moc.delete(note)
                    try? moc.save()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    ContentView()
}
