import SwiftUI
import UIKit

struct SimpleRichTextEditor: UIViewRepresentable {
    @Binding var text: String
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
        
        // Add simple toolbar with coordinator
        textView.inputAccessoryView = createSimpleToolbar(with: context.coordinator)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
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
    
    private func createSimpleToolbar(with coordinator: Coordinator) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let bulletButton = UIBarButtonItem(
            title: "• List",
            style: .plain,
            target: coordinator,
            action: #selector(Coordinator.insertBulletPoint)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: coordinator, action: #selector(Coordinator.dismissKeyboard))
        
        toolbar.items = [bulletButton, flexSpace, doneButton]
        return toolbar
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let parent: SimpleRichTextEditor
        weak var textView: UITextView?
        
        init(_ parent: SimpleRichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.textView = textView
            parent.text = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            self.textView = textView
            parent.isFirstResponder = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFirstResponder = false
        }
        
        @objc func insertBulletPoint() {
            guard let textView = textView else { return }
            
            let currentText = textView.text ?? ""
            let selectedRange = textView.selectedRange
            let newText = (currentText as NSString).replacingCharacters(in: selectedRange, with: "\n• ")
            textView.text = newText
            textView.selectedRange = NSRange(location: selectedRange.location + 3, length: 0)
            
            // Update parent
            parent.text = textView.text
        }
        
        @objc func dismissKeyboard() {
            textView?.resignFirstResponder()
        }
    }
}
