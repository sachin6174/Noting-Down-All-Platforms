import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("defaultCategory") private var defaultCategory = "General"
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("showWordCount") private var showWordCount = true
    
    @Environment(\.presentationMode) var presentationMode
    
    private let categories = ["General", "Work", "Personal", "Ideas", "Shopping", "Travel", "Health", "Finance", "Education"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    HStack {
                        Image(systemName: "moon.circle")
                            .foregroundColor(Theme.primaryGreen)
                            .font(.system(size: 20))
                        Toggle("Dark Mode", isOn: $isDarkMode)
                    }
                }
                
                Section("Note Defaults") {
                    HStack {
                        Image(systemName: "folder.circle")
                            .foregroundColor(Theme.primaryGreen)
                            .font(.system(size: 20))
                        
                        Picker("Default Category", selection: $defaultCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(Theme.primaryGreen)
                            .font(.system(size: 20))
                        Toggle("Auto Save", isOn: $autoSave)
                    }
                    
                    HStack {
                        Image(systemName: "textformat.123")
                            .foregroundColor(Theme.primaryGreen)
                            .font(.system(size: 20))
                        Toggle("Show Word Count", isOn: $showWordCount)
                    }
                }
                
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Theme.primaryGreen)
                            .font(.system(size: 20))
                        VStack(alignment: .leading) {
                            Text("NotingDown")
                                .font(.headline)
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                    Button(action: openAppStore) {
                        HStack {
                            Image(systemName: "star.circle")
                                .foregroundColor(Theme.primaryGreen)
                                .font(.system(size: 20))
                            Text("Rate on App Store")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: shareApp) {
                        HStack {
                            Image(systemName: "heart.circle")
                                .foregroundColor(Theme.primaryGreen)
                                .font(.system(size: 20))
                            Text("Share with Friends")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.primaryGreen)
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    private func openAppStore() {
        if let url = URL(string: "https://apps.apple.com/us/app/notingdown/id6742340327") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareApp() {
        let appURL = URL(string: "https://apps.apple.com/us/app/notingdown/id6742340327")!
        let activityVC = UIActivityViewController(
            activityItems: ["Check out NotingDown - A beautiful note-taking app!", appURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
