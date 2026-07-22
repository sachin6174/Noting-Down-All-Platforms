import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.textTertiary)
                    .font(.system(size: 16))
                
                TextField("Search notes...", text: $searchText)
                    .font(Theme.bodyFont)
                    .onTapGesture {
                        isEditing = true
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.textTertiary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, Theme.paddingM)
            .padding(.vertical, Theme.paddingS)
            .background(Theme.secondaryBackground)
            .cornerRadius(Theme.cornerRadiusS)
            
            if isEditing {
                Button("Cancel") {
                    searchText = ""
                    isEditing = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .font(Theme.bodyFont)
                .foregroundColor(Theme.primaryGreen)
                .transition(.move(edge: .trailing))
                .animation(.easeInOut(duration: 0.2), value: isEditing)
            }
        }
        .onTapGesture {
            if !isEditing {
                isEditing = true
            }
        }
    }
}

struct SearchBar_Previews: PreviewProvider {
    @State static var searchText = ""
    
    static var previews: some View {
        SearchBar(searchText: $searchText)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
