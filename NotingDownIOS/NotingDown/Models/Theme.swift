import SwiftUI

struct Theme {
    // MARK: - Colors
    static let primaryGreen = Color(red: 78/255, green: 187/255, blue: 120/255)
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
    static let titleFont = Font.system(size: 28, weight: .bold)
    static let headlineFont = Font.system(size: 20, weight: .semibold)
    static let bodyFont = Font.system(size: 16, weight: .regular)
    static let captionFont = Font.system(size: 12, weight: .medium)
    
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
