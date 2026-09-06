import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: NSAttributedString
    @Binding var isFirstResponder: Bool
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        context.coordinator.textView = textView
        textView.backgroundColor = UIColor.clear
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.accessibilityLabel = String(localized: "Note content")
        textView.accessibilityIdentifier = "editor.body"
        textView.dataDetectorTypes = [.link, .phoneNumber, .address]
        textView.allowsEditingTextAttributes = true
        
        // Add formatting toolbar
        textView.inputAccessoryView = createFormattingToolbar(for: textView, coordinator: context.coordinator)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self
        if uiView.attributedText != text {
            uiView.attributedText = text
        }
        
        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createFormattingToolbar(for textView: UITextView, coordinator: Coordinator) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let boldButton = UIBarButtonItem(
            image: UIImage(systemName: "bold"),
            style: .plain,
            target: textView,
            action: #selector(UITextView.toggleBoldface)
        )
        
        let italicButton = UIBarButtonItem(
            image: UIImage(systemName: "italic"),
            style: .plain,
            target: textView,
            action: #selector(UITextView.toggleItalics)
        )
        
        let underlineButton = UIBarButtonItem(
            image: UIImage(systemName: "underline"),
            style: .plain,
            target: textView,
            action: #selector(UITextView.toggleUnderline)
        )
        
        let bulletButton = UIBarButtonItem(
            title: String(localized: "• List"),
            style: .plain,
            target: coordinator,
            action: #selector(Coordinator.insertBulletPoint)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: textView, action: #selector(UIResponder.resignFirstResponder))
        
        boldButton.accessibilityLabel = String(localized: "Bold")
        italicButton.accessibilityLabel = String(localized: "Italic")
        underlineButton.accessibilityLabel = String(localized: "Underline")
        toolbar.items = [boldButton, italicButton, underlineButton, bulletButton, flexSpace, doneButton]
        return toolbar
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        weak var textView: UITextView?
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.attributedText
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFirstResponder = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFirstResponder = false
        }
        
        @objc func insertBulletPoint() {
            guard let textView else { return }
            textView.insertText("\n• ")
            parent.text = textView.attributedText
        }
    }
}

struct EnhancedNoteEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var title: String = ""
    @State private var saveError = false
    @AppStorage("defaultCategory") private var defaultCategory = "General"
    @AppStorage("showWordCount") private var showWordCount = true
    @State private var richText: NSAttributedString = NSAttributedString()
    @State private var selectedCategory: String = "General"
    @State private var isFavorite: Bool = false
    @State private var colorTag: String = ""
    @State private var isRichTextFocused: Bool = false
    @State private var showingVoiceNote = false
    
    @FocusState private var titleFocused: Bool
    
    var note: NotesTable?
    
    private let categories = ["General", "Work", "Personal", "Ideas", "Shopping", "Travel", "Health", "Finance", "Education"]
    private let colorTags = ["", "red", "orange", "yellow", "green", "blue", "purple", "pink"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.paddingL) {
                    // Title and Header Section
                    VStack(alignment: .leading, spacing: Theme.paddingM) {
                        HStack {
                            VStack(alignment: .leading, spacing: Theme.paddingS) {
                                Text("Title")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textSecondary)
                                
                                TextField("Enter note title...", text: $title)
                                    .accessibilityLabel("Title")
                                    .accessibilityIdentifier("editor.title")
                                    .font(.headline)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($titleFocused)
                            }
                            
                            VStack(spacing: Theme.paddingS) {
                                Button(action: { isFavorite.toggle() }) {
                                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                                        .foregroundColor(isFavorite ? .red : Theme.textSecondary)
                                        .font(.system(size: 24))
                                }
                                .frame(minWidth: 44, minHeight: 44)
                                .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
                                
                                Menu {
                                    Button(action: { showingVoiceNote = true }) {
                                        Label("Voice Note", systemImage: "mic")
                                    }
                                    

                                    
                                    Button(action: { insertCurrentDateTime() }) {
                                        Label("Insert Date/Time", systemImage: "calendar")
                                    }
                                    
                                    Button(action: { insertTemplate(.todo) }) {
                                        Label("Todo List", systemImage: "checklist")
                                    }
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(Theme.primaryGreen)
                                        .font(.system(size: 24))
                                }
                                .frame(minWidth: 44, minHeight: 44)
                                .accessibilityLabel("More actions")
                            }
                        }
                        
                        // Category Selection
                        VStack(alignment: .leading, spacing: Theme.paddingS) {
                            Text("Category")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.paddingS) {
                                    ForEach(categories, id: \.self) { category in
                                        CategoryChip(
                                            title: category,
                                            isSelected: selectedCategory == category,
                                            color: Theme.categoryColors[category] ?? .gray
                                        ) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                                .padding(.horizontal, Theme.paddingS)
                            }
                        }
                        
                        // Color Tags
                        VStack(alignment: .leading, spacing: Theme.paddingS) {
                            Text("Color Tag")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: Theme.paddingS) {
                                ForEach(colorTags, id: \.self) { color in
                                    Button(action: { colorTag = color }) {
                                        Circle()
                                            .fill(Theme.noteTagColors[color] ?? Color.clear)
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle()
                                                    .stroke(color.isEmpty ? Theme.textTertiary : Color.clear, lineWidth: 1)
                                            )
                                            .overlay(
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 12, weight: .bold))
                                                    .opacity(colorTag == color ? 1 : 0)
                                            )
                                    }
                                    .frame(minWidth: 44, minHeight: 44)
                                    .accessibilityLabel(Text(LocalizedStringKey(color.isEmpty ? "No color" : color)))
                                    .accessibilityAddTraits(colorTag == color ? .isSelected : [])
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, Theme.paddingM)
                    
                    // Rich Text Editor
                    VStack(alignment: .leading, spacing: Theme.paddingS) {
                        Text("Content")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, Theme.paddingM)
                        
                        RichTextEditor(text: $richText, isFirstResponder: $isRichTextFocused)
                            .frame(minHeight: 300)
                            .padding(Theme.paddingS)
                            .background(Theme.cardBackground)
                            .cornerRadius(Theme.cornerRadiusM)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.cornerRadiusM)
                                    .stroke(isRichTextFocused ? Theme.primaryGreen : Color.clear, lineWidth: 2)
                            )
                            .padding(.horizontal, Theme.paddingM)
                    }
                    
                    // Word Count and Stats
                    if showWordCount { VStack(alignment: .trailing) {
                        Spacer()
                        Text("Words: \(richText.string.split(whereSeparator: \.isWhitespace).count)")
                        Text("Characters: \(richText.string.count)")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal, Theme.paddingM)
                    }
                }
            }
            .background(Theme.lightGreen)
            .navigationTitle(LocalizedStringKey(note == nil ? "New Note" : "Edit Note"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .accessibilityIdentifier("editor.save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.primaryGreen)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadNoteData()
                if note == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        titleFocused = true
                    }
                }
            }
        }
        .alert("Could not save note", isPresented: $saveError) {
            Button("OK", role: .cancel) { }
        } message: { Text("Your draft is still open. Please try again.") }
        .sheet(isPresented: $showingVoiceNote) {
            VoiceNoteView()
        }
    }
    
    private func loadNoteData() {
        if note == nil { selectedCategory = defaultCategory }
        if let note = note {
            title = note.title ?? ""
            
            // Convert plain text to attributed string
            if let description = note.noteDescription {
                richText = NSAttributedString(string: description, attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: UIColor.label
                ])
            }
            
            selectedCategory = note.category ?? "General"
            isFavorite = note.isFavorite
            colorTag = note.colorTag ?? ""
        }
    }
    
    private func saveNote() {
        do {
            try NoteStore(context: viewContext).save(
                note: note, title: title, body: richText.string,
                category: selectedCategory, favorite: isFavorite,
                colorTag: colorTag.isEmpty ? nil : colorTag)
            HapticManager.shared.notification(.success)
            presentationMode.wrappedValue.dismiss()
        } catch {
            saveError = true
        }
    }
    
    private func insertCurrentDateTime() {
        let dateString = Date().formatted(date: .abbreviated, time: .shortened)
        let currentText = NSMutableAttributedString(attributedString: richText)
        let dateText = NSAttributedString(string: "\n📅 \(dateString)\n", attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.systemBlue
        ])
        currentText.append(dateText)
        richText = currentText
    }
    
    private func insertTemplate(_ template: TemplateType) {
        let templateText: String
        
        switch template {
        case .todo:
            templateText = "\n☐ \n☐ \n☐ \n"
        }
        
        let currentText = NSMutableAttributedString(attributedString: richText)
        let template = NSAttributedString(string: templateText, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label
        ])
        currentText.append(template)
        richText = currentText
    }
    
    enum TemplateType {
        case todo
    }
}
