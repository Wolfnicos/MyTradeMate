import SwiftUI
import Combine

/// Manages app theming and appearance
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .system
    @Published var isDarkMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let settings = AppSettings.shared
    
    private init() {
        setupThemeBinding()
        updateTheme()
    }
    
    // MARK: - Theme Management
    
    private func setupThemeBinding() {
        // Monitor theme changes
        isDarkMode = settings.themeDark
        currentTheme = isDarkMode ? .dark : .light
        applyTheme()
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        
        switch theme {
        case .light:
            settings.themeDark = false
        case .dark:
            settings.themeDark = true
        case .system:
            // Use system preference
            let systemIsDark = UITraitCollection.current.userInterfaceStyle == .dark
            settings.themeDark = systemIsDark
        }
        
        applyTheme()
        Log.userAction("Theme changed", parameters: ["theme": theme.rawValue])
    }
    
    private func updateTheme() {
        let systemIsDark = UITraitCollection.current.userInterfaceStyle == .dark
        
        switch currentTheme {
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        case .system:
            isDarkMode = systemIsDark
        }
        
        applyTheme()
    }
    
    private func applyTheme() {
        // Update UI appearance
        let style: UIUserInterfaceStyle = isDarkMode ? .dark : .light
        
        // Apply to all windows
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
        
        // Update tab bar appearance to ensure icons adapt properly
        updateTabBarAppearance()
        
        Log.verbose("Applied theme: \(currentTheme.rawValue) (dark: \(isDarkMode))", category: .ui)
    }
    
    private func updateTabBarAppearance() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        
        // Ensure tab bar icons adapt properly to the current theme
        // Use system colors that automatically adapt to appearance changes
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        // Apply the same configuration to compact layout (for smaller screens)
        tabAppearance.compactInlineLayoutAppearance.normal.iconColor = UIColor.systemGray
        tabAppearance.compactInlineLayoutAppearance.selected.iconColor = UIColor.systemBlue
        tabAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        tabAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        // Apply to both standard and scroll edge appearances
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        // Ensure the tab bar itself adapts to appearance changes
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
        UITabBar.appearance().barTintColor = UIColor.systemBackground
    }
    
    // MARK: - Color Scheme
    
    var colorScheme: ColorScheme? {
        switch currentTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // Use system default
        }
    }
    
    // MARK: - Theme Colors
    
    var primaryColor: Color {
        isDarkMode ? .white : .black
    }
    
    var secondaryColor: Color {
        isDarkMode ? Color(.systemGray) : Color(.systemGray2)
    }
    
    var backgroundColor: Color {
        isDarkMode ? Color(.systemBackground) : Color(.systemBackground)
    }
    
    var cardBackgroundColor: Color {
        isDarkMode ? Color(.secondarySystemBackground) : Color(.secondarySystemBackground)
    }
    
    var accentColor: Color {
        .blue // Always use blue as accent
    }
    
    var successColor: Color {
        .green
    }
    
    var errorColor: Color {
        .red
    }
    
    var warningColor: Color {
        .orange
    }
    
    // MARK: - Trading Colors
    
    var buyColor: Color {
        .green
    }
    
    var sellColor: Color {
        .red
    }
    
    var neutralColor: Color {
        secondaryColor
    }
    
    // MARK: - Chart Colors
    
    var chartLineColor: Color {
        accentColor
    }
    
    var chartFillColor: Color {
        accentColor.opacity(0.1)
    }
    
    var candleUpColor: Color {
        .green
    }
    
    var candleDownColor: Color {
        .red
    }
}

// MARK: - App Theme Enum

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        case .system:
            return "gear"
        }
    }
}

// MARK: - View Extensions

extension View {
    func themedBackground() -> some View {
        background(ThemeManager.shared.backgroundColor)
    }
    
    func themedCardBackground() -> some View {
        background(ThemeManager.shared.cardBackgroundColor)
    }
    
    func themedForeground() -> some View {
        foregroundColor(ThemeManager.shared.primaryColor)
    }
    
    func themedSecondaryForeground() -> some View {
        foregroundColor(ThemeManager.shared.secondaryColor)
    }
}

// MARK: - Theme Modifier

struct ThemedView: ViewModifier {
    @StateObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
            .themedBackground()
    }
}

extension View {
    func themed() -> some View {
        modifier(ThemedView())
    }
}