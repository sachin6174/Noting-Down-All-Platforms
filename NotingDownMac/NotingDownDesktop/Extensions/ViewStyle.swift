import SwiftUI

struct AppStyle {
    static let padding = EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
    static let cornerRadius: CGFloat = 8
    static let spacing: CGFloat = 16

    struct Colors {
        static let background = Color(.windowBackgroundColor)
        static let inputBackground = Color(.textBackgroundColor)
        static let accent = Color.accentColor
        static let destructive = Color.red
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
    }
}

extension View {
    func standardButton(background: Color = AppStyle.Colors.accent) -> some View {
        self.frame(height: 32)
            .padding(.horizontal, 16)
            .background(background)
            .foregroundColor(.white)
            .cornerRadius(AppStyle.cornerRadius)
    }
}
