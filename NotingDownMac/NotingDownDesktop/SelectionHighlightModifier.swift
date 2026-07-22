import SwiftUI

struct SelectionHighlightModifier: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .background(isSelected ? Color.selectionBlue.opacity(0.2) : Color.clear)
            .cornerRadius(6)
    }
}

extension View {
    func highlightedWhenSelected(_ isSelected: Bool) -> some View {
        modifier(SelectionHighlightModifier(isSelected: isSelected))
    }
}
