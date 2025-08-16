import SwiftUI

// MARK: - Spacing System
/// Standardized spacing values used throughout the app
public struct Spacing {
    /// 2pt - Minimal spacing for tight layouts
    static let xxs: CGFloat = 2
    /// 4pt - Extra small spacing for compact elements
    static let xs: CGFloat = 4
    /// 8pt - Small spacing for related elements
    static let sm: CGFloat = 8
    /// 12pt - Medium-small spacing for component internal spacing
    static let md: CGFloat = 12
    /// 16pt - Standard spacing for most UI elements
    static let lg: CGFloat = 16
    /// 20pt - Large spacing for section separation
    static let xl: CGFloat = 20
    /// 24pt - Extra large spacing for major sections
    static let xxl: CGFloat = 24
    /// 32pt - Maximum spacing for major layout separation
    static let xxxl: CGFloat = 32
    /// 48pt - Exceptional spacing for major visual breaks
    static let huge: CGFloat = 48
    
    // MARK: - Semantic Spacing
    /// Standard padding for cards and containers
    static let cardPadding: CGFloat = lg
    /// Standard spacing between sections
    static let sectionSpacing: CGFloat = xl
    /// Standard spacing between related elements
    static let elementSpacing: CGFloat = md
    /// Standard spacing for button internal padding
    static let buttonPadding: CGFloat = lg
    /// Standard spacing for form elements
    static let formSpacing: CGFloat = md
    /// Standard spacing for list items
    static let listItemSpacing: CGFloat = sm
}

// MARK: - Corner Radius System
/// Standardized corner radius values used throughout the app
public struct CornerRadius {
    /// 4pt - Small radius for compact elements
    static let xs: CGFloat = 4
    /// 6pt - Small-medium radius for buttons and small cards
    static let sm: CGFloat = 6
    /// 8pt - Standard radius for most UI elements
    static let md: CGFloat = 8
    /// 12pt - Large radius for cards and containers
    static let lg: CGFloat = 12
    /// 16pt - Extra large radius for prominent elements
    static let xl: CGFloat = 16
    /// 20pt - Maximum radius for special elements
    static let xxl: CGFloat = 20
}

// MARK: - Colors
public struct Brand {
    static let blue = Color(light: Color(hex: "007AFF"), dark: Color(hex: "0A84FF"))
}

public struct Accent {
    static let green = Color(light: Color(hex: "34C759"), dark: Color(hex: "30D158"))
    static let red = Color(light: Color(hex: "FF3B30"), dark: Color(hex: "FF453A"))
    static let yellow = Color(light: Color(hex: "FFCC00"), dark: Color(hex: "FFD60A"))
}

public struct Bg {
    static let primary = Color(light: Color.white, dark: Color(hex: "000000"))
    static let card = Color(light: Color(hex: "F2F2F7"), dark: Color(hex: "1C1C1E"))
    static let secondary = Color(light: Color(hex: "F7F7F7"), dark: Color(hex: "2C2C2E"))
}

public struct TextColor {
    static let primary = Color(light: Color.black, dark: Color.white)
    static let secondary = Color(light: Color(hex: "8E8E93"), dark: Color(hex: "98989D"))
    static let tertiary = Color(light: Color(hex: "C7C7CC"), dark: Color(hex: "48484A"))
}

// MARK: - Typography System

/// Standardized typography system for consistent text styling across the app
public struct Typography {
    
    // MARK: - Font Sizes
    public struct FontSize {
        static let largeTitle: CGFloat = 34
        static let title1: CGFloat = 28
        static let title2: CGFloat = 22
        static let title3: CGFloat = 20
        static let headline: CGFloat = 17
        static let body: CGFloat = 17
        static let callout: CGFloat = 16
        static let subheadline: CGFloat = 15
        static let footnote: CGFloat = 13
        static let caption1: CGFloat = 12
        static let caption2: CGFloat = 11
    }
    
    // MARK: - Font Weights
    public struct FontWeight {
        static let ultraLight: Font.Weight = .ultraLight
        static let thin: Font.Weight = .thin
        static let light: Font.Weight = .light
        static let regular: Font.Weight = .regular
        static let medium: Font.Weight = .medium
        static let semibold: Font.Weight = .semibold
        static let bold: Font.Weight = .bold
        static let heavy: Font.Weight = .heavy
        static let black: Font.Weight = .black
    }
    
    // MARK: - Standard Font Styles
    public static let largeTitle = Font.system(size: FontSize.largeTitle, weight: FontWeight.bold, design: .rounded)
    public static let title1 = Font.system(size: FontSize.title1, weight: FontWeight.semibold, design: .rounded)
    public static let title2 = Font.system(size: FontSize.title2, weight: FontWeight.semibold, design: .rounded)
    public static let title3 = Font.system(size: FontSize.title3, weight: FontWeight.medium, design: .rounded)
    public static let headline = Font.system(size: FontSize.headline, weight: FontWeight.semibold, design: .default)
    public static let body = Font.system(size: FontSize.body, weight: FontWeight.regular, design: .default)
    public static let bodyMedium = Font.system(size: FontSize.body, weight: FontWeight.medium, design: .default)
    public static let callout = Font.system(size: FontSize.callout, weight: FontWeight.regular, design: .default)
    public static let calloutMedium = Font.system(size: FontSize.callout, weight: FontWeight.medium, design: .default)
    public static let subheadline = Font.system(size: FontSize.subheadline, weight: FontWeight.regular, design: .default)
    public static let subheadlineMedium = Font.system(size: FontSize.subheadline, weight: FontWeight.medium, design: .default)
    public static let footnote = Font.system(size: FontSize.footnote, weight: FontWeight.regular, design: .default)
    public static let footnoteMedium = Font.system(size: FontSize.footnote, weight: FontWeight.medium, design: .default)
    public static let caption1 = Font.system(size: FontSize.caption1, weight: FontWeight.regular, design: .default)
    public static let caption1Medium = Font.system(size: FontSize.caption1, weight: FontWeight.medium, design: .default)
    public static let caption2 = Font.system(size: FontSize.caption2, weight: FontWeight.regular, design: .default)
    public static let caption2Medium = Font.system(size: FontSize.caption2, weight: FontWeight.medium, design: .default)
}

// MARK: - Typography View Modifiers

struct LargeTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.largeTitle)
            .foregroundColor(TextColor.primary)
    }
}

struct Title1Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.title1)
            .foregroundColor(TextColor.primary)
    }
}

struct Title2Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.title2)
            .foregroundColor(TextColor.primary)
    }
}

struct Title3Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.title3)
            .foregroundColor(TextColor.primary)
    }
}

struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.headline)
            .foregroundColor(TextColor.primary)
    }
}

struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.body)
            .foregroundColor(TextColor.primary)
    }
}

struct BodyMediumStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.bodyMedium)
            .foregroundColor(TextColor.primary)
    }
}

struct CalloutStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.callout)
            .foregroundColor(TextColor.primary)
    }
}

struct CalloutMediumStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.calloutMedium)
            .foregroundColor(TextColor.primary)
    }
}

struct SubheadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.subheadline)
            .foregroundColor(TextColor.secondary)
    }
}

struct SubheadlineMediumStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.subheadlineMedium)
            .foregroundColor(TextColor.secondary)
    }
}

struct FootnoteStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.footnote)
            .foregroundColor(TextColor.secondary)
    }
}

struct FootnoteMediumStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.footnoteMedium)
            .foregroundColor(TextColor.secondary)
    }
}

struct Caption1Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.caption1)
            .foregroundColor(TextColor.secondary)
    }
}

struct Caption1MediumStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.caption1Medium)
            .foregroundColor(TextColor.secondary)
    }
}

struct Caption2Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.caption2)
            .foregroundColor(TextColor.secondary)
    }
}

struct Caption2MediumStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.caption2Medium)
            .foregroundColor(TextColor.secondary)
    }
}

// MARK: - Typography View Extensions

extension View {
    // Primary typography styles
    func largeTitleStyle() -> some View { modifier(LargeTitleStyle()) }
    func title1Style() -> some View { modifier(Title1Style()) }
    func title2Style() -> some View { modifier(Title2Style()) }
    func title3Style() -> some View { modifier(Title3Style()) }
    func headlineStyle() -> some View { modifier(HeadlineStyle()) }
    func bodyStyle() -> some View { modifier(BodyStyle()) }
    func bodyMediumStyle() -> some View { modifier(BodyMediumStyle()) }
    func calloutStyle() -> some View { modifier(CalloutStyle()) }
    func calloutMediumStyle() -> some View { modifier(CalloutMediumStyle()) }
    func subheadlineStyle() -> some View { modifier(SubheadlineStyle()) }
    func subheadlineMediumStyle() -> some View { modifier(SubheadlineMediumStyle()) }
    func footnoteStyle() -> some View { modifier(FootnoteStyle()) }
    func footnoteMediumStyle() -> some View { modifier(FootnoteMediumStyle()) }
    func caption1Style() -> some View { modifier(Caption1Style()) }
    func caption1MediumStyle() -> some View { modifier(Caption1MediumStyle()) }
    func caption2Style() -> some View { modifier(Caption2Style()) }
    func caption2MediumStyle() -> some View { modifier(Caption2MediumStyle()) }
    
    // Legacy support (deprecated - use specific styles above)
    @available(*, deprecated, message: "Use title1Style() instead")
    func headingXL() -> some View { modifier(LargeTitleStyle()) }
    @available(*, deprecated, message: "Use title2Style() instead")
    func headingL() -> some View { modifier(Title1Style()) }
    @available(*, deprecated, message: "Use title3Style() instead")
    func headingM() -> some View { modifier(Title2Style()) }
    @available(*, deprecated, message: "Use caption1Style() instead")
    func captionStyle() -> some View { modifier(Caption1Style()) }
}

// MARK: - Button Styles

/// Standard button sizes used throughout the app
public enum ButtonSize {
    case small
    case medium
    case large
    case extraLarge
    
    var height: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 50
        case .extraLarge: return 56
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 14
        case .medium: return 16
        case .large: return 17
        case .extraLarge: return 18
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        case .extraLarge: return 14
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        case .extraLarge: return 24
        }
    }
}

/// Standard button styles used throughout the app
public enum ButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    case success
    case warning
    case ghost
    case outline
    
    func backgroundColor(isPressed: Bool = false) -> Color {
        let baseColor: Color
        switch self {
        case .primary: baseColor = Brand.blue
        case .secondary: baseColor = Bg.secondary
        case .tertiary: baseColor = Color.clear
        case .destructive: baseColor = Accent.red
        case .success: baseColor = Accent.green
        case .warning: baseColor = Accent.yellow
        case .ghost: baseColor = Color.clear
        case .outline: baseColor = Color.clear
        }
        return isPressed ? baseColor.opacity(0.8) : baseColor
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary, .destructive, .success, .warning: return .white
        case .secondary, .tertiary, .ghost, .outline: return TextColor.primary
        }
    }
    
    var borderColor: Color? {
        switch self {
        case .outline: return TextColor.secondary
        case .tertiary: return TextColor.tertiary
        default: return nil
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .primary, .destructive, .success: return .semibold
        case .secondary, .warning: return .medium
        case .tertiary, .ghost, .outline: return .regular
        }
    }
}

/// Standardized button component that handles all button styles and interactions
struct StandardButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let size: ButtonSize
    let isDisabled: Bool
    let isLoading: Bool
    let fullWidth: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        size: ButtonSize = .large,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.fullWidth = fullWidth
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard !isDisabled && !isLoading else { return }
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            // Haptic feedback
            if AppSettings.shared.haptics {
                Haptics.playImpact(.light)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.fontSize - 2, weight: style.fontWeight))
                }
                
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: size.fontSize, weight: style.fontWeight))
                }
            }
            .foregroundColor(isDisabled ? style.foregroundColor.opacity(0.5) : style.foregroundColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(style.backgroundColor(isPressed: isPressed))
                    .opacity(isDisabled ? 0.5 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(style.borderColor ?? Color.clear, lineWidth: 1)
                    .opacity(isDisabled ? 0.5 : 1.0)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isLoading ? "Loading" : "")
        .accessibilityAddTraits(isDisabled ? [] : .isButton)
    }
}

// MARK: - Convenience Button Components

/// Primary action button - used for main actions
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let size: ButtonSize
    let isDisabled: Bool
    let isLoading: Bool
    let fullWidth: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .large,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.fullWidth = fullWidth
        self.action = action
    }
    
    var body: some View {
        StandardButton(
            title,
            icon: icon,
            style: .primary,
            size: size,
            isDisabled: isDisabled,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
    }
}

/// Secondary action button - used for secondary actions
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let size: ButtonSize
    let isDisabled: Bool
    let isLoading: Bool
    let fullWidth: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .large,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.fullWidth = fullWidth
        self.action = action
    }
    
    var body: some View {
        StandardButton(
            title,
            icon: icon,
            style: .secondary,
            size: size,
            isDisabled: isDisabled,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
    }
}

/// Destructive action button - used for delete/dangerous actions
struct DestructiveButton: View {
    let title: String
    let icon: String?
    let size: ButtonSize
    let isDisabled: Bool
    let isLoading: Bool
    let fullWidth: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .large,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.fullWidth = fullWidth
        self.action = action
    }
    
    var body: some View {
        StandardButton(
            title,
            icon: icon,
            style: .destructive,
            size: size,
            isDisabled: isDisabled,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
    }
}

/// Success action button - used for positive actions like buy orders
struct SuccessButton: View {
    let title: String
    let icon: String?
    let size: ButtonSize
    let isDisabled: Bool
    let isLoading: Bool
    let fullWidth: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .large,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.fullWidth = fullWidth
        self.action = action
    }
    
    var body: some View {
        StandardButton(
            title,
            icon: icon,
            style: .success,
            size: size,
            isDisabled: isDisabled,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
    }
}

/// Warning action button - used for caution actions like sell orders
struct WarningButton: View {
    let title: String
    let icon: String?
    let size: ButtonSize
    let isDisabled: Bool
    let isLoading: Bool
    let fullWidth: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .large,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.fullWidth = fullWidth
        self.action = action
    }
    
    var body: some View {
        StandardButton(
            title,
            icon: icon,
            style: .warning,
            size: size,
            isDisabled: isDisabled,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
    }
}

/// Ghost button - minimal style for subtle actions
struct GhostButton: View {
    let title: String
    let icon: String?
    let size: ButtonSize
    let isDisabled: Bool
    let isLoading: Bool
    let fullWidth: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .medium,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.fullWidth = fullWidth
        self.action = action
    }
    
    var body: some View {
        StandardButton(
            title,
            icon: icon,
            style: .ghost,
            size: size,
            isDisabled: isDisabled,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
    }
}

/// Outline button - bordered style for secondary actions
struct OutlineButton: View {
    let title: String
    let icon: String?
    let size: ButtonSize
    let isDisabled: Bool
    let isLoading: Bool
    let fullWidth: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        size: ButtonSize = .large,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.size = size
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.fullWidth = fullWidth
        self.action = action
    }
    
    var body: some View {
        StandardButton(
            title,
            icon: icon,
            style: .outline,
            size: size,
            isDisabled: isDisabled,
            isLoading: isLoading,
            fullWidth: fullWidth,
            action: action
        )
    }
}

// MARK: - Trading-Specific Buttons

/// Buy button with consistent styling for trading actions
struct BuyButton: View {
    let title: String
    let subtitle: String?
    let size: ButtonSize
    let isDisabled: Bool
    let isLoading: Bool
    let isDemoMode: Bool
    let action: () -> Void
    
    init(
        _ title: String = "BUY",
        subtitle: String? = nil,
        size: ButtonSize = .large,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        isDemoMode: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.size = size
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.isDemoMode = isDemoMode
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard !isDisabled && !isLoading else { return }
            
            if AppSettings.shared.haptics {
                Haptics.playImpact(.medium)
            }
            
            action()
        }) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: size.fontSize, weight: .bold))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: size.fontSize - 4, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                } else if isDemoMode {
                    Text("DEMO")
                        .font(.system(size: size.fontSize - 4, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(Accent.green)
            .cornerRadius(size.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(isDemoMode ? Accent.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .disabled(isDisabled || isLoading)
        .accessibilityLabel("\(title) button")
        .accessibilityHint(isDemoMode ? "Demo mode - no real trade will be executed" : "")
    }
}

/// Sell button with consistent styling for trading actions
struct SellButton: View {
    let title: String
    let subtitle: String?
    let size: ButtonSize
    let isDisabled: Bool
    let isLoading: Bool
    let isDemoMode: Bool
    let action: () -> Void
    
    init(
        _ title: String = "SELL",
        subtitle: String? = nil,
        size: ButtonSize = .large,
        isDisabled: Bool = false,
        isLoading: Bool = false,
        isDemoMode: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.size = size
        self.isDisabled = isDisabled
        self.isLoading = isLoading
        self.isDemoMode = isDemoMode
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard !isDisabled && !isLoading else { return }
            
            if AppSettings.shared.haptics {
                Haptics.playImpact(.medium)
            }
            
            action()
        }) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: size.fontSize, weight: .bold))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: size.fontSize - 4, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                } else if isDemoMode {
                    Text("DEMO")
                        .font(.system(size: size.fontSize - 4, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(Accent.red)
            .cornerRadius(size.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(isDemoMode ? Accent.yellow.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .disabled(isDisabled || isLoading)
        .accessibilityLabel("\(title) button")
        .accessibilityHint(isDemoMode ? "Demo mode - no real trade will be executed" : "")
    }
}

// MARK: - Legacy Button Support (Deprecated - use StandardButton instead)

/// @deprecated Use StandardButton with .primary style instead
struct DangerButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        DestructiveButton(title, action: action)
    }
}

// MARK: - Card Component
struct Card<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(
        padding: CGFloat = Spacing.cardPadding,
        cornerRadius: CGFloat = CornerRadius.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Bg.card)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

// MARK: - Pill Component
struct Pill: View {
    let text: String
    let color: Color
    let size: PillSize
    
    enum PillSize {
        case small
        case medium
        case large
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return Spacing.sm
            case .medium: return Spacing.md
            case .large: return Spacing.lg
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return Spacing.xs
            case .medium: return Spacing.sm
            case .large: return Spacing.md
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return CornerRadius.xl
            case .medium: return CornerRadius.xxl
            case .large: return CornerRadius.xxl
            }
        }
    }
    
    init(text: String, color: Color, size: PillSize = .medium) {
        self.text = text
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: size.fontSize, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(color)
            .cornerRadius(size.cornerRadius)
    }
}

// MARK: - Segmented Pill
struct SegmentedPill<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let options: [(label: String, value: SelectionValue)]
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(options, id: \.value) { option in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option.value
                        Haptics.playImpact(.light)
                    }
                }) {
                    Text(option.label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selection == option.value ? .white : TextColor.primary)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .fill(selection == option.value ? Brand.blue : Color.clear)
                        )
                }
            }
        }
        .padding(Spacing.xs)
        .background(Bg.secondary)
        .cornerRadius(CornerRadius.xxl)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    enum Status {
        case live, demo, paper
        
        var color: Color {
            switch self {
            case .live: return Accent.green
            case .demo: return Accent.yellow
            case .paper: return Brand.blue
            }
        }
        
        var icon: String {
            switch self {
            case .live: return "circle.fill"
            case .demo: return "play.circle.fill"
            case .paper: return "doc.text.fill"
            }
        }
        
        var text: String {
            switch self {
            case .live: return "LIVE"
            case .demo: return "DEMO"
            case .paper: return "PAPER"
            }
        }
    }
    
    let status: Status
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: status.icon)
                .font(.system(size: 10))
            Text(status.text)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(status.color)
        .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Auto Switch
struct AutoSwitch: View {
    @Binding var isAuto: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAuto = false
                    Haptics.playImpact(.medium)
                }
            }) {
                Text("Manual")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(!isAuto ? .white : TextColor.primary)
                    .frame(width: 70, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(!isAuto ? Brand.blue : Color.clear)
                    )
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAuto = true
                    Haptics.playImpact(.medium)
                }
            }) {
                Text("Auto")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isAuto ? .white : TextColor.primary)
                    .frame(width: 70, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(isAuto ? Accent.green : Color.clear)
                    )
            }
        }
        .padding(Spacing.xxs + 1) // 3pt padding
        .background(Bg.secondary)
        .cornerRadius(CornerRadius.xl)
    }
}

// MARK: - Key Value Row
struct KeyValueRow: View {
    let title: String
    let subtitle: String?
    let trailing: AnyView?
    
    init(title: String, subtitle: String? = nil, trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(TextColor.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(TextColor.secondary)
                }
            }
            
            Spacer()
            
            if let trailing = trailing {
                trailing
            }
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Toggle Components

/// Standard toggle sizes used throughout the app
public enum ToggleSize {
    case small
    case medium
    case large
    
    var dimensions: CGSize {
        switch self {
        case .small: return CGSize(width: 40, height: 24)
        case .medium: return CGSize(width: 50, height: 30)
        case .large: return CGSize(width: 60, height: 36)
        }
    }
    
    var thumbSize: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 26
        case .large: return 32
        }
    }
    
    var padding: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 2
        case .large: return 2
        }
    }
}

/// Standard toggle styles used throughout the app
public enum ToggleStyle {
    case `default`
    case prominent
    case success
    case warning
    case danger
    case minimal
    
    func onColor(isEnabled: Bool) -> Color {
        guard isEnabled else { return offColor }
        
        switch self {
        case .default: return Brand.blue
        case .prominent: return Brand.blue
        case .success: return Accent.green
        case .warning: return Accent.yellow
        case .danger: return Accent.red
        case .minimal: return TextColor.primary
        }
    }
    
    var offColor: Color {
        switch self {
        case .minimal: return TextColor.tertiary
        default: return Color(.systemGray4)
        }
    }
    
    var thumbColor: Color {
        return .white
    }
}

/// Standardized toggle component that handles all toggle styles and interactions
struct StandardToggle: View {
    @Binding var isOn: Bool
    let style: ToggleStyle
    let toggleSize: ToggleSize
    let isDisabled: Bool
    let hapticFeedback: Bool
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    init(
        isOn: Binding<Bool>,
        style: ToggleStyle = .default,
        size: ToggleSize = .medium,
        isDisabled: Bool = false,
        hapticFeedback: Bool = true
    ) {
        self._isOn = isOn
        self.style = style
        self.toggleSize = size
        self.isDisabled = isDisabled
        self.hapticFeedback = hapticFeedback
    }
    
    private var thumbOffset: CGFloat {
        let maxOffset = toggleSize.dimensions.width - toggleSize.thumbSize - (toggleSize.padding * 2)
        if isDragging {
            let clampedOffset = max(0, min(maxOffset, dragOffset))
            return clampedOffset
        }
        return isOn ? maxOffset : 0
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background track
            RoundedRectangle(cornerRadius: toggleSize.dimensions.height / 2)
                .fill(style.onColor(isEnabled: isOn && !isDisabled))
                .frame(width: toggleSize.dimensions.width, height: toggleSize.dimensions.height)
                .opacity(isDisabled ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isOn)
            
            // Thumb
            Circle()
                .fill(style.thumbColor)
                .frame(width: toggleSize.thumbSize, height: toggleSize.thumbSize)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                .offset(x: thumbOffset + toggleSize.padding)
                .animation(.easeInOut(duration: 0.2), value: isOn)
                .opacity(isDisabled ? 0.7 : 1.0)
        }
        .onTapGesture {
            guard !isDisabled else { return }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
            
            if hapticFeedback && AppSettings.shared.haptics {
                let impact = UIImpactFeedbackGenerator(style: isOn ? .medium : .light)
                impact.impactOccurred()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard !isDisabled else { return }
                    
                    if !isDragging {
                        isDragging = true
                    }
                    
                    dragOffset = value.translation.width + (isOn ? toggleSize.dimensions.width - toggleSize.thumbSize - (toggleSize.padding * 2) : 0)
                }
                .onEnded { value in
                    guard !isDisabled else { return }
                    
                    isDragging = false
                    
                    let maxOffset = toggleSize.dimensions.width - toggleSize.thumbSize - (toggleSize.padding * 2)
                    let threshold = maxOffset / 2
                    let shouldBeOn = dragOffset > threshold
                    
                    if shouldBeOn != isOn {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isOn = shouldBeOn
                        }
                        
                        if hapticFeedback && AppSettings.shared.haptics {
                            let impact = UIImpactFeedbackGenerator(style: isOn ? .medium : .light)
                            impact.impactOccurred()
                        }
                    }
                    
                    dragOffset = 0
                }
        )
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Toggle")
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(isDisabled ? "Disabled" : "Double tap to toggle")
    }
}

// MARK: - Convenience Toggle Components

/// Default toggle for general use cases
struct DefaultToggle: View {
    @Binding var isOn: Bool
    let isDisabled: Bool
    
    init(isOn: Binding<Bool>, isDisabled: Bool = false) {
        self._isOn = isOn
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        StandardToggle(
            isOn: $isOn,
            style: .default,
            size: .medium,
            isDisabled: isDisabled
        )
    }
}

/// Large, prominent toggle for important settings
struct ProminentToggle: View {
    @Binding var isOn: Bool
    let isDisabled: Bool
    
    init(isOn: Binding<Bool>, isDisabled: Bool = false) {
        self._isOn = isOn
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        StandardToggle(
            isOn: $isOn,
            style: .prominent,
            size: .large,
            isDisabled: isDisabled
        )
    }
}

/// Green toggle for positive actions (e.g., enabling features)
struct SuccessToggle: View {
    @Binding var isOn: Bool
    let isDisabled: Bool
    
    init(isOn: Binding<Bool>, isDisabled: Bool = false) {
        self._isOn = isOn
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        StandardToggle(
            isOn: $isOn,
            style: .success,
            size: .medium,
            isDisabled: isDisabled
        )
    }
}

/// Yellow/orange toggle for caution actions (e.g., demo mode)
struct WarningToggle: View {
    @Binding var isOn: Bool
    let isDisabled: Bool
    
    init(isOn: Binding<Bool>, isDisabled: Bool = false) {
        self._isOn = isOn
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        StandardToggle(
            isOn: $isOn,
            style: .warning,
            size: .medium,
            isDisabled: isDisabled
        )
    }
}

/// Red toggle for dangerous actions (e.g., verbose logging)
struct DangerToggle: View {
    @Binding var isOn: Bool
    let isDisabled: Bool
    
    init(isOn: Binding<Bool>, isDisabled: Bool = false) {
        self._isOn = isOn
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        StandardToggle(
            isOn: $isOn,
            style: .danger,
            size: .medium,
            isDisabled: isDisabled
        )
    }
}

/// Small, subtle toggle for less important settings
struct MinimalToggle: View {
    @Binding var isOn: Bool
    let isDisabled: Bool
    
    init(isOn: Binding<Bool>, isDisabled: Bool = false) {
        self._isOn = isOn
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        StandardToggle(
            isOn: $isOn,
            style: .minimal,
            size: .small,
            isDisabled: isDisabled
        )
    }
}

/// Complete toggle row component for settings screens
struct StandardToggleRow: View {
    let title: String
    let description: String?
    let helpText: String?
    @Binding var isOn: Bool
    let style: ToggleStyle
    let isDisabled: Bool
    let showDivider: Bool
    
    init(
        title: String,
        description: String? = nil,
        helpText: String? = nil,
        isOn: Binding<Bool>,
        style: ToggleStyle = .default,
        isDisabled: Bool = false,
        showDivider: Bool = true
    ) {
        self.title = title
        self.description = description
        self.helpText = helpText
        self._isOn = isOn
        self.style = style
        self.isDisabled = isDisabled
        self.showDivider = showDivider
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isDisabled ? TextColor.secondary : TextColor.primary)
                    
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(TextColor.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if let helpText = helpText {
                        HelpIconView(helpText: helpText)
                    }
                    
                    StandardToggle(
                        isOn: $isOn,
                        style: style,
                        size: .medium,
                        isDisabled: isDisabled
                    )
                }
            }
            
            if showDivider {
                Divider()
                    .opacity(0.3)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Help icon component for toggle rows
private struct HelpIconView: View {
    let helpText: String
    @State private var showTooltip = false
    
    var body: some View {
        Button(action: {
            showTooltip.toggle()
        }) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(TextColor.secondary)
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showTooltip, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(helpText)
                    .font(.body)
                    .foregroundColor(TextColor.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: 280)
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel("Help")
        .accessibilityHint("Tap to show help information")
    }
}

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    init(light: Color, dark: Color) {
        self = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
