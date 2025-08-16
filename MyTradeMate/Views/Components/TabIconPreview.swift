import SwiftUI

/// Preview component to verify tab icons work correctly in both light and dark modes
struct TabIconPreview: View {
    @State private var selectedTab: AppTab = .dashboard
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tab Icons Preview")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Test icons in both light and dark modes")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Tab bar preview
            TabView(selection: $selectedTab) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    VStack(spacing: 16) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 48))
                            .foregroundColor(.primary)
                        
                        Text(tab.rawValue)
                            .font(.headline)
                        
                        Text("Icon: \(tab.systemImage)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Test icon in different states
                        HStack(spacing: 20) {
                            VStack {
                                Image(systemName: tab.systemImage)
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                                Text("Normal")
                                    .font(.caption2)
                            }
                            
                            VStack {
                                Image(systemName: tab.systemImage)
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                                Text("Selected")
                                    .font(.caption2)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.systemImage)
                    }
                    .tag(tab)
                }
            }
        }
        .padding()
    }
}

/// Test view to verify tab icons adapt to color scheme changes
struct TabIconColorSchemeTest: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Color Scheme: \(colorScheme == .dark ? "Dark" : "Light")")
                .font(.headline)
            
            Text("All tab icons should adapt automatically:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    VStack(spacing: 8) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 32))
                            .foregroundColor(.primary)
                        
                        Text(tab.rawValue)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#if DEBUG
struct TabIconPreview_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TabIconPreview()
                .previewDisplayName("Tab Icons")
            
            TabIconColorSchemeTest()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            TabIconColorSchemeTest()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif