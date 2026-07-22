import SwiftUI

struct FilterView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @State private var showingSortOptions = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.paddingS) {
                // Favorites filter
                FilterChip(
                    title: "Favorites",
                    icon: "heart.fill",
                    isSelected: searchViewModel.showFavoritesOnly,
                    color: .red
                ) {
                    searchViewModel.showFavoritesOnly.toggle()
                }
                
                // Category filters
                ForEach(searchViewModel.categories, id: \.self) { category in
                    FilterChip(
                        title: category,
                        icon: categoryIcon(for: category),
                        isSelected: searchViewModel.selectedCategory == category,
                        color: Theme.categoryColors[category] ?? .gray
                    ) {
                        searchViewModel.selectedCategory = category
                    }
                }
                
                // Sort button
                Button(action: { showingSortOptions = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(searchViewModel.sortOption.rawValue)
                    }
                    .font(Theme.captionFont)
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.paddingS)
                    .padding(.vertical, 6)
                    .background(Theme.darkGreen)
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, Theme.paddingM)
        }
        .actionSheet(isPresented: $showingSortOptions) {
            ActionSheet(
                title: Text("Sort By"),
                buttons: SearchViewModel.SortOption.allCases.map { option in
                    .default(Text(option.rawValue)) {
                        searchViewModel.sortOption = option
                    }
                } + [.cancel()]
            )
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "All": return "square.grid.2x2"
        case "Work": return "briefcase"
        case "Personal": return "person"
        case "Ideas": return "lightbulb"
        case "Shopping": return "cart"
        case "Travel": return "airplane"
        case "Health": return "heart.text.square"
        case "Finance": return "dollarsign.circle"
        case "Education": return "graduationcap"
        default: return "folder"
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(Theme.captionFont)
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, Theme.paddingS)
            .padding(.vertical, 6)
            .background(isSelected ? color : color.opacity(0.2))
            .cornerRadius(16)
        }
    }
}

struct FilterView_Previews: PreviewProvider {
    static var previews: some View {
        FilterView(searchViewModel: SearchViewModel())
            .previewLayout(.sizeThatFits)
    }
}
