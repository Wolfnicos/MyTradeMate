import SwiftUI

/// Comprehensive design tokens for 2025 iOS app standards
/// Provides consistent spacing, colors, typography, and other design primitives
struct DesignTokens {
    
    // MARK: - Spacing System
    struct Spacing {
        static let xs: CGFloat = 4      // Micro spacing
        static let sm: CGFloat = 8      // Small spacing
        static let md: CGFloat = 12     // Medium spacing
        static let lg: CGFloat = 16     // Large spacing (standard card padding)
        static let xl: CGFloat = 20     // Extra large spacing
        static let xxl: CGFloat = 24    // Section spacing
        static let xxxl: CGFloat = 32   // Major section spacing
        
        // Component-specific spacing
        static let cardPadding: CGFloat = lg        // 16pt
        static let sectionSpacing: CGFloat = xxl    // 24pt
        static let itemSpacing: CGFloat = md        // 12pt
        static let buttonPadding: CGFloat = lg      // 16pt
        static let chipPadding: CGFloat = sm        // 8pt
    }
    
    // MARK: - Border Radius System
    struct Radius {
        static let xs: CGFloat = 4      // Small elements
        static let sm: CGFloat = 6      // Chips, badges
        static let md: CGFloat = 8      // Buttons, inputs
        static let lg: CGFloat = 12     // Cards
        static let xl: CGFloat = 16     // Large cards
        static let xxl: CGFloat = 20    // Modal corners
        static let pill: CGFloat = 999  // Fully rounded
    }
    
    // MARK: - Elevation System (Shadows)
    struct Elevation {
        static let none = ShadowStyle.none
        static let sm = ShadowStyle.sm
        static let md = ShadowStyle.md
        static let lg = ShadowStyle.lg
        static let xl = ShadowStyle.xl
        
        struct ShadowStyle {
            let radius: CGFloat
            let opacity: Double
            let offset: CGSize
            
            static let none = ShadowStyle(radius: 0, opacity: 0, offset: .zero)
            static let sm = ShadowStyle(radius: 2, opacity: 0.1, offset: CGSize(width: 0, height: 1))
            static let md = ShadowStyle(radius: 4, opacity: 0.15, offset: CGSize(width: 0, height: 2))
            static let lg = ShadowStyle(radius: 8, opacity: 0.2, offset: CGSize(width: 0, height: 4))
            static let xl = ShadowStyle(radius: 12, opacity: 0.25, offset: CGSize(width: 0, height: 6))
        }
    }
    
    // MARK: - Color System
    struct Colors {
        // Brand Colors
        static let primary = Color.blue
        static let primaryVariant = Color.blue.opacity(0.8)
        static let secondary = Color.gray
        
        // Surface Colors (2025 standards)
        static let surface = Color(.systemBackground)
        static let surfaceSecondary = Color(.secondarySystemBackground)
        static let surfaceTertiary = Color(.tertiarySystemBackground)
        static let surfaceElevated = Color(.systemBackground)
        
        // Trading-specific Colors
        static let gain = Color.green
        static let gainBackground = Color.green.opacity(0.1)
        static let loss = Color.red
        static let lossBackground = Color.red.opacity(0.1)
        static let neutral = Color.gray
        static let neutralBackground = Color.gray.opacity(0.1)
        
        // Trading Mode Colors
        static let demoMode = Color.blue
        static let paperMode = Color.green
        static let liveMode = Color.red
        
        // Status Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Text Colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(.tertiaryLabel)
        static let textOnSurface = Color.primary
        
        // Border Colors
        static let border = Color(.separator)
        static let borderSecondary = Color(.quaternaryLabel)
        
        // Component Colors
        static let cardBackground = Color(.secondarySystemBackground)
        static let chipBackground = Color(.quaternarySystemFill)
    }
    
    // MARK: - Typography System
    struct Typography {
        // Display Text (Headings)
        static let displayLarge = Font.system(size: 32, weight: .bold, design: .default)
        static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)
        static let displaySmall = Font.system(size: 24, weight: .semibold, design: .default)
        
        // Headlines
        static let headlineLarge = Font.system(size: 20, weight: .semibold, design: .default)
        static let headlineMedium = Font.system(size: 18, weight: .medium, design: .default)
        static let headlineSmall = Font.system(size: 16, weight: .medium, design: .default)
        
        // Body Text
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        // Labels
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
        
        // Specialized
        static let caption = Font.system(size: 10, weight: .regular, design: .default)
        static let overline = Font.system(size: 10, weight: .semibold, design: .default)
        static let monospace = Font.system(size: 14, weight: .regular, design: .monospaced)
        
        // Trading-specific
        static let price = Font.system(size: 18, weight: .semibold, design: .default)
        static let priceSmall = Font.system(size: 14, weight: .medium, design: .default)
        static let metric = Font.system(size: 16, weight: .medium, design: .default)
        static let chipText = Font.system(size: 11, weight: .semibold, design: .default)
    }
    
    // MARK: - Animation System
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        
        // Specialized animations
        static let spring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let bounce = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)
        static let gentle = SwiftUI.Animation.easeOut(duration: 0.4)
    }
    
    // MARK: - Icon Sizes
    struct IconSize {
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Component Sizes
    struct ComponentSize {
        static let buttonHeight: CGFloat = 48
        static let buttonHeightSmall: CGFloat = 36
        static let inputHeight: CGFloat = 44
        static let chipHeight: CGFloat = 28
        static let cardMinHeight: CGFloat = 80
        static let avatarSmall: CGFloat = 32
        static let avatarMedium: CGFloat = 48
        static let avatarLarge: CGFloat = 64
    }
}

// MARK: - View Extensions for Easy Access
extension View {
    func designTokenPadding(_ token: CGFloat = DesignTokens.Spacing.lg) -> some View {
        self.padding(token)
    }
    
    func designTokenCornerRadius(_ token: CGFloat = DesignTokens.Radius.lg) -> some View {
        self.cornerRadius(token)
    }
    
    func designTokenShadow(_ style: DesignTokens.Elevation.ShadowStyle = .md) -> some View {
        self.shadow(
            color: .black.opacity(style.opacity),
            radius: style.radius,
            x: style.offset.width,
            y: style.offset.height
        )
    }
    
    func cardStyle() -> some View {
        self
            .background(DesignTokens.Colors.cardBackground)
            .designTokenCornerRadius(DesignTokens.Radius.lg)
            .designTokenShadow(DesignTokens.Elevation.sm)
    }
    
    func chipStyle(color: Color = DesignTokens.Colors.primary) -> some View {
        self
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .font(DesignTokens.Typography.chipText)
            .cornerRadius(DesignTokens.Radius.sm)
    }
}