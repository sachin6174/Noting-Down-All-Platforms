import SwiftUI

struct Theme {
    // MARK: - Colors
    static let primaryGreen = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.85, blue: 0.55, alpha: 1)
            : UIColor(red: 0.12, green: 0.43, blue: 0.25, alpha: 1)
    })
    static let lightGreen = Color(red: 78/255, green: 187/255, blue: 120/255).opacity(0.1)
    static let mediumGreen = Color(red: 78/255, green: 187/255, blue: 120/255).opacity(0.3)
    static let darkGreen = Color(red: 60/255, green: 150/255, blue: 95/255)
    
    static let cardBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    
    // MARK: - Typography
    static let titleFont = Font.title.bold()
    static let headlineFont = Font.headline
    static let bodyFont = Font.body
    static let captionFont = Font.caption
    
    // MARK: - Spacing
    static let paddingXS: CGFloat = 4
    static let paddingS: CGFloat = 8
    static let paddingM: CGFloat = 16
    static let paddingL: CGFloat = 24
    static let paddingXL: CGFloat = 32
    
    // MARK: - Corner Radius
    static let cornerRadiusS: CGFloat = 8
    static let cornerRadiusM: CGFloat = 12
    static let cornerRadiusL: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 20
    
    static let noteTagColors: [String: Color] = [
        "red": .red, "orange": .orange, "yellow": .yellow, "green": .green,
        "blue": .blue, "purple": .purple, "pink": .pink
    ]

    // MARK: - Category Colors
    static let categoryColors: [String: Color] = [
        "Work": .blue,
        "Personal": .orange,
        "Ideas": .purple,
        "Shopping": .pink,
        "Travel": .cyan,
        "Health": .green,
        "Finance": .yellow,
        "Education": .indigo,
        "General": .gray
    ]
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cornerRadiusM)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding(.horizontal, Theme.paddingL)
            .padding(.vertical, Theme.paddingS)
            .background(Theme.primaryGreen)
            .cornerRadius(Theme.cornerRadiusS)
    }
}
