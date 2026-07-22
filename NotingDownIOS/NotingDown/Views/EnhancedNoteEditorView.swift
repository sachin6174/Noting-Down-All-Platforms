import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var text: NSAttributedString
    @Binding var isFirstResponder: Bool
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = UIColor.clear
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.dataDetectorTypes = [.link, .phoneNumber, .address]
        textView.allowsEditingTextAttributes = true
        
        // Add formatting toolbar
        textView.inputAccessoryView = createFormattingToolbar(for: textView, coordinator: context.coordinator)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
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
            title: "• List",
            style: .plain,
            target: coordinator,
            action: #selector(Coordinator.insertBulletPoint)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: textView, action: #selector(UIResponder.resignFirstResponder))
        
        toolbar.items = [boldButton, italicButton, underlineButton, bulletButton, flexSpace, doneButton]
        return toolbar
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let parent: RichTextEditor
        
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
            // This method will be called from the toolbar button
            // We'll use a simple approach by finding the currently active text view
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first,
                   let textView = self.findTextView(in: window.rootViewController?.view) {
                    
                    let currentText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
                    let bullet = NSAttributedString(string: "\n• ", attributes: [
                        .font: UIFont.systemFont(ofSize: 16),
                        .foregroundColor: UIColor.label
                    ])
                    
                    let selectedRange = textView.selectedRange
                    currentText.insert(bullet, at: selectedRange.location)
                    
                    textView.attributedText = currentText
                    textView.selectedRange = NSRange(location: selectedRange.location + bullet.length, length: 0)
                    
                    // Update the parent's text binding
                    self.parent.text = textView.attributedText
                }
            }
        }
        
        private func findTextView(in view: UIView?) -> UITextView? {
            guard let view = view else { return nil }
            
            if let textView = view as? UITextView {
                return textView
            }
            
            for subview in view.subviews {
                if let textView = findTextView(in: subview) {
                    return textView
                }
            }
            
            return nil
        }
    }
}

struct EnhancedNoteEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var title: String = ""
    @State private var richText: NSAttributedString = NSAttributedString()
    @State private var selectedCategory: String = "General"
    @State private var isFavorite: Bool = false
    @State private var colorTag: String = ""
    @State private var isRichTextFocused: Bool = false
    @State private var showingVoiceNote = false
    @State private var showingImagePicker = false
    @State private var selectedImages: [UIImage] = []
    
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
                                    .font(.system(size: 18, weight: .semibold))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($titleFocused)
                            }
                            
                            VStack(spacing: Theme.paddingS) {
                                Button(action: { isFavorite.toggle() }) {
                                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                                        .foregroundColor(isFavorite ? .red : Theme.textSecondary)
                                        .font(.system(size: 24))
                                }
                                
                                Menu {
                                    Button(action: { showingVoiceNote = true }) {
                                        Label("Voice Note", systemImage: "mic")
                                    }
                                    
                                    Button(action: { showingImagePicker = true }) {
                                        Label("Add Image", systemImage: "photo")
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
                            
                            HStack(spacing: Theme.paddingS) {
                                ForEach(colorTags, id: \.self) { color in
                                    Button(action: { colorTag = color }) {
                                        Circle()
                                            .fill(color.isEmpty ? Color.clear : Color(color))
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
                    
                    // Image Attachments
                    if !selectedImages.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.paddingS) {
                            Text("Attachments")
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, Theme.paddingM)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.paddingS) {
                                    ForEach(selectedImages.indices, id: \.self) { index in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: selectedImages[index])
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(Theme.cornerRadiusS)
                                            
                                            Button(action: {
                                                selectedImages.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Color.white, in: Circle())
                                            }
                                            .offset(x: 5, y: -5)
                                        }
                                    }
                                }
                                .padding(.horizontal, Theme.paddingM)
                            }
                        }
                    }
                    
                    // Word Count and Stats
                    HStack {
                        Spacer()
                        Text("\(richText.string.split(separator: " ").count) words • \(richText.string.count) characters")
                            .font(Theme.captionFont)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal, Theme.paddingM)
                }
            }
            .background(Theme.lightGreen)
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
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
        .sheet(isPresented: $showingVoiceNote) {
            VoiceNoteView()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(images: $selectedImages)
        }
    }
    
    private func loadNoteData() {
        if let note = note {
            title = note.title ?? ""
            
            // Convert plain text to attributed string
            if let description = note.noteDescription {
                richText = NSAttributedString(string: description, attributes: [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.label
                ])
            }
            
            selectedCategory = note.category ?? "General"
            isFavorite = note.isFavorite
            colorTag = note.colorTag ?? ""
        }
    }
    
    private func saveNote() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = richText.string
        
        if let note = note {
            // Update existing note
            note.title = trimmedTitle
            note.noteDescription = content
            note.category = selectedCategory
            note.isFavorite = isFavorite
            note.colorTag = colorTag.isEmpty ? nil : colorTag
            note.modifiedDate = Date()
        } else {
            // Create new note
            let newNote = NotesTable(context: viewContext)
            newNote.id = UUID()
            newNote.title = trimmedTitle
            newNote.noteDescription = content
            newNote.category = selectedCategory
            newNote.isFavorite = isFavorite
            newNote.colorTag = colorTag.isEmpty ? nil : colorTag
            newNote.createdDate = Date()
            newNote.modifiedDate = Date()
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving note: \(error.localizedDescription)")
        }
    }
    
    private func insertCurrentDateTime() {
        let dateString = Date().formatted(date: .abbreviated, time: .shortened)
        let currentText = NSMutableAttributedString(attributedString: richText)
        let dateText = NSAttributedString(string: "\n📅 \(dateString)\n", attributes: [
            .font: UIFont.systemFont(ofSize: 16),
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
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label
        ])
        currentText.append(template)
        richText = currentText
    }
    
    enum TemplateType {
        case todo
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.images.append(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
