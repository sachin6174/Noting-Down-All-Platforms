import Foundation
import SwiftUI

class ExportManager: ObservableObject {
    static let shared = ExportManager()
    
    enum ExportFormat: String, CaseIterable {
        case text = "Plain Text (.txt)"
        case markdown = "Markdown (.md)"
        case json = "JSON (.json)"
        case csv = "CSV (.csv)"
        
        var fileExtension: String {
            switch self {
            case .text: return "txt"
            case .markdown: return "md"
            case .json: return "json"
            case .csv: return "csv"
            }
        }
    }
    
    func exportNotes(_ notes: [NotesTable], format: ExportFormat) -> URL? {
        let fileName = "NotingDown_Export_\(Date().formatted(date: .abbreviated, time: .omitted))"
        let content: String
        
        switch format {
        case .text:
            content = exportAsText(notes)
        case .markdown:
            content = exportAsMarkdown(notes)
        case .json:
            content = exportAsJSON(notes)
        case .csv:
            content = exportAsCSV(notes)
        }
        
        return saveToTemporaryFile(content: content, fileName: fileName, extension: format.fileExtension)
    }
    
    private func exportAsText(_ notes: [NotesTable]) -> String {
        return notes.map { note in
            """
            TITLE: \(note.title ?? "Untitled")
            CATEGORY: \(note.displayCategory)
            CREATED: \(note.formattedCreatedDate)
            MODIFIED: \(note.formattedModifiedDate)
            FAVORITE: \(note.isFavorite ? "Yes" : "No")
            
            CONTENT:
            \(note.noteDescription ?? "")
            
            =====================================
            
            """
        }.joined()
    }
    
    private func exportAsMarkdown(_ notes: [NotesTable]) -> String {
        var markdown = "# NotingDown Export\n\n"
        markdown += "Generated on \(Date().formatted(date: .complete, time: .shortened))\n\n"
        markdown += "---\n\n"
        
        for note in notes {
            markdown += "## \(note.title ?? "Untitled")\n\n"
            markdown += "**Category:** \(note.displayCategory)  \n"
            markdown += "**Created:** \(note.formattedCreatedDate)  \n"
            markdown += "**Modified:** \(note.formattedModifiedDate)  \n"
            if note.isFavorite {
                markdown += "**Favorite:** ⭐  \n"
            }
            markdown += "\n"
            markdown += "\(note.noteDescription ?? "")\n\n"
            markdown += "---\n\n"
        }
        
        return markdown
    }
    
    private func exportAsJSON(_ notes: [NotesTable]) -> String {
        let notesData = notes.map { note in
            [
                "id": note.id?.uuidString ?? "",
                "title": note.title ?? "",
                "description": note.noteDescription ?? "",
                "category": note.category ?? "",
                "isFavorite": note.isFavorite,
                "createdDate": note.createdDate?.ISO8601Format() ?? "",
                "modifiedDate": note.modifiedDate?.ISO8601Format() ?? ""
            ]
        }
        
        let exportData = [
            "exportDate": Date().ISO8601Format(),
            "appVersion": "1.0",
            "totalNotes": notes.count,
            "notes": notesData
        ] as [String: Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return "Error creating JSON: \(error.localizedDescription)"
        }
    }
    
    private func exportAsCSV(_ notes: [NotesTable]) -> String {
        var csv = "Title,Category,Description,Favorite,Created,Modified\n"
        
        for note in notes {
            let title = escapeCSV(note.title ?? "")
            let category = escapeCSV(note.displayCategory)
            let description = escapeCSV(note.noteDescription ?? "")
            let favorite = note.isFavorite ? "Yes" : "No"
            let created = escapeCSV(note.formattedCreatedDate)
            let modified = escapeCSV(note.formattedModifiedDate)
            
            csv += "\(title),\(category),\(description),\(favorite),\(created),\(modified)\n"
        }
        
        return csv
    }
    
    private func escapeCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
    
    private func saveToTemporaryFile(content: String, fileName: String, extension: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(fileName).\(`extension`)")
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving file: \(error.localizedDescription)")
            return nil
        }
    }
}

struct ExportView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var exportManager = ExportManager.shared
    @State private var selectedFormat: ExportManager.ExportFormat = .markdown
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    let notes: [NotesTable]
    
    var body: some View {
        NavigationView {
            VStack(spacing: Theme.paddingL) {
                VStack(alignment: .leading, spacing: Theme.paddingM) {
                    Text("Export \(notes.count) notes")
                        .font(Theme.headlineFont)
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Choose your preferred export format:")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, Theme.paddingL)
                
                VStack(spacing: Theme.paddingS) {
                    ForEach(ExportManager.ExportFormat.allCases, id: \.self) { format in
                        Button(action: { selectedFormat = format }) {
                            HStack {
                                Image(systemName: selectedFormat == format ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedFormat == format ? Theme.primaryGreen : Theme.textTertiary)
                                
                                Text(format.rawValue)
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.textPrimary)
                                
                                Spacer()
                            }
                            .padding(Theme.paddingM)
                            .cardStyle()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.paddingL)
                
                Spacer()
                
                Button("Export Notes") {
                    if let url = exportManager.exportNotes(notes, format: selectedFormat) {
                        exportURL = url
                        showingShareSheet = true
                    }
                }
                .primaryButtonStyle()
                .padding(.horizontal, Theme.paddingL)
            }
            .padding(.vertical, Theme.paddingL)
            .background(Theme.lightGreen)
            .navigationTitle("Export Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.primaryGreen)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
