import Foundation
import SwiftUI
import Combine

/// Modern 2025 Theme Manager with adaptive design, neumorphic elements, and fluid animations
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .system
    @Published var isDarkMode: Bool = false
    
    // 2025 Design System Properties
    @Published var primaryGradient: LinearGradient = LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
    @Published var backgroundGradient: LinearGradient = LinearGradient(colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.8)], startPoint: .top, endPoint: .bottom)
    @Published var cardShadowColor: Color = .black.opacity(0.1)
    @Published var neumorphicShadow: (highlight: Color, shadow: Color) = (.white.opacity(0.7), .black.opacity(0.2))
    
    // Animation Properties
    @Published var defaultAnimation: Animation = .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.2)
    @Published var fastAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1)
    @Published var slowAnimation: Animation = .spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.3)
    
    private var cancellables = Set<AnyCancellable>()
    private let settingsRepo: SettingsRepository
    
    init(settingsRepo: SettingsRepository = SettingsRepository.shared) {
        self.settingsRepo = settingsRepo
        setupThemeBinding()
        updateTheme()
    }
    
    // MARK: - Theme Management
    
    private func setupThemeBinding() {
        // Read initial theme from SettingsRepository
        currentTheme = settingsRepo.preferredTheme
        updateTheme()
        
        // Monitor SettingsRepository theme changes
        settingsRepo.$preferredTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTheme in
                if self?.currentTheme != newTheme {
                    self?.currentTheme = newTheme
                    self?.updateTheme()
                }
            }
            .store(in: &cancellables)
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        updateTheme()
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
        
        // Update 2025 design system colors based on theme
        updateDesignSystemColors()
        
        // Don't save to AppSettings here to avoid infinite loop
        // AppSettings will be updated separately when user changes theme
        
        applyTheme()
    }
    
    // MARK: - 2025 Design System Color Updates
    
    private func updateDesignSystemColors() {
        withAnimation(defaultAnimation) {
            if isDarkMode {
                // Dark mode 2025 colors
                primaryGradient = LinearGradient(
                    colors: [Color(red: 0.2, green: 0.6, blue: 1.0), Color(red: 0.4, green: 0.8, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                backgroundGradient = LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                cardShadowColor = .white.opacity(0.05)
                neumorphicShadow = (.white.opacity(0.1), .black.opacity(0.4))
            } else {
                // Light mode 2025 colors
                primaryGradient = LinearGradient(
                    colors: [Color(red: 0.0, green: 0.5, blue: 1.0), Color(red: 0.2, green: 0.7, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                backgroundGradient = LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                cardShadowColor = .black.opacity(0.08)
                neumorphicShadow = (.white.opacity(0.9), .black.opacity(0.15))
            }
        }
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
    
    // MARK: - 2025 Design System Helpers
    
    /// Returns neumorphic card background with modern styling
    func neumorphicCardBackground() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: isDarkMode ? 
                                [Color.white.opacity(0.1), Color.clear] :
                                [Color.white.opacity(0.8), Color.black.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: neumorphicShadow.shadow, radius: 8, x: 4, y: 4)
            .shadow(color: neumorphicShadow.highlight, radius: 8, x: -2, y: -2)
    }
    
    /// Returns modern glass morphism background
    func glassMorphismBackground() -> some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isDarkMode ? 0.2 : 0.6),
                                Color.white.opacity(isDarkMode ? 0.1 : 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    /// Returns modern button style with haptic feedback
    func modernButtonStyle() -> some ViewModifier {
        ModernButtonStyleModifier(themeManager: self)
    }
    
    /// Returns card animation for modern interactions
    func cardAnimation() -> Animation {
        .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)
    }
    
    private func updateTabBarAppearance() {
        let tabAppearance = UITabBarAppearance()
        
        // Use the same configuration as navigation bar for consistency
        tabAppearance.configureWithDefaultBackground()
        
        // Remove any solid background color to allow full translucency
        tabAppearance.backgroundColor = .clear
        
        // Use the same blur effect as navigation bars
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        
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
        
        // Apply to both standard and scroll edge appearances for consistency
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        // Ensure the tab bar is translucent like navigation bar
        UITabBar.appearance().isTranslucent = true
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

public enum AppTheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    public var id: String { rawValue }
    
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

// MARK: - Modern 2025 Style Modifiers

struct ModernButtonStyleModifier: ViewModifier {
    let themeManager: ThemeManager
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(themeManager.fastAnimation, value: isPressed)
            .onTapGesture {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
            .pressEvents {
                withAnimation(themeManager.fastAnimation) {
                    isPressed = true
                }
            } onRelease: {
                withAnimation(themeManager.fastAnimation) {
                    isPressed = false
                }
            }
    }
}

// Helper for press events
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
                if pressing {
                    onPress()
                } else {
                    onRelease()
                }
            })
    }
}