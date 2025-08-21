import SwiftUI

/// Premium 2025 Visual Theme for MyTradeMate
/// Inspired by Robinhood meets Binance with futuristic aesthetics
struct PremiumTheme {
    
    // MARK: - Color System
    struct Colors {
        // Primary Gradients
        static let primaryGradient = LinearGradient(
            colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let successGradient = LinearGradient(
            colors: [Color(hex: "00D632"), Color(hex: "00B428")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let dangerGradient = LinearGradient(
            colors: [Color(hex: "FF3B30"), Color(hex: "DC2626")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Background System
        static let bgPrimary = Color(hex: "0A0E27")
        static let bgSecondary = Color(hex: "1A1F3A") 
        static let bgTertiary = Color(hex: "0D1117")
        
        static let backgroundGradient = LinearGradient(
            colors: [
                Color(hex: "0A0E27"),
                Color(hex: "1A1F3A"),
                Color(hex: "0D1117")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Surface Colors
        static let surfaceGlass = Color.white.opacity(0.05)
        static let surfaceCard = Color.white.opacity(0.08)
        static let surfaceBorder = LinearGradient(
            colors: [
                Color.purple.opacity(0.6),
                Color.blue.opacity(0.3),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Text Hierarchy
        static let textPrimary = Color.white
        static let textSecondary = Color.gray
        static let textTertiary = Color.gray.opacity(0.6)
        
        // Status Colors
        static let green = Color(hex: "00D632")
        static let red = Color(hex: "FF3B30")
        static let blue = Color(hex: "007AFF")
        static let purple = Color(hex: "5856D6")
    }
    
    // MARK: - Typography System
    struct Typography {
        // Display Text
        static let displayLarge = Font.system(size: 42, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 32, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 28, weight: .semibold, design: .rounded)
        
        // Headlines
        static let headlineLarge = Font.system(size: 24, weight: .bold)
        static let headlineMedium = Font.system(size: 20, weight: .semibold)
        static let headlineSmall = Font.system(size: 18, weight: .semibold)
        
        // Body Text
        static let bodyLarge = Font.system(size: 16, weight: .regular)
        static let bodyMedium = Font.system(size: 14, weight: .regular)
        static let bodySmall = Font.system(size: 12, weight: .regular)
        
        // Labels
        static let labelLarge = Font.system(size: 14, weight: .medium)
        static let labelMedium = Font.system(size: 12, weight: .medium)
        static let labelSmall = Font.system(size: 10, weight: .medium)
    }
    
    // MARK: - Spacing System
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    // MARK: - Shadow System
    struct Shadows {
        static let card = [
            Shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10),
            Shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
        ]
        
        static let button = Shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
        static let glow = Shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
extension View {
    /// Applies premium glassmorphism card styling
    func premiumCard() -> some View {
        self
            .background(
                ZStack {
                    // Gradient border effect
                    RoundedRectangle(cornerRadius: PremiumTheme.Radius.xl)
                        .stroke(PremiumTheme.Colors.surfaceBorder, lineWidth: 1)
                    
                    // Glass effect
                    RoundedRectangle(cornerRadius: PremiumTheme.Radius.xl)
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)
                    
                    // Inner glow
                    RoundedRectangle(cornerRadius: PremiumTheme.Radius.xl)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .cornerRadius(PremiumTheme.Radius.xl)
            .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
            .overlay(
                // Shimmer effect
                RoundedRectangle(cornerRadius: PremiumTheme.Radius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear,
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: UUID())
            )
    }
    
    /// Applies premium background with animated orbs
    func premiumBackground() -> some View {
        ZStack {
            // Animated gradient background
            PremiumTheme.Colors.backgroundGradient
                .ignoresSafeArea()
            
            // Animated orbs/blobs
            GeometryReader { geometry in
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(0.3),
                                    Color.blue.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 10...20))
                                .repeatForever(autoreverses: true),
                            value: UUID()
                        )
                }
            }
            
            self
        }
    }
    
    /// Applies button press animation
    func pressAnimation(_ isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Custom Button Styles
struct PremiumButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    let glowColor: Color
    
    init(gradient: LinearGradient, glowColor: Color) {
        self.gradient = gradient
        self.glowColor = glowColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // Gradient background
                    gradient
                    
                    // Inner light
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .cornerRadius(PremiumTheme.Radius.md)
            .shadow(color: glowColor.opacity(0.4), radius: 15, x: 0, y: 8)
            .overlay(
                // Glow effect
                RoundedRectangle(cornerRadius: PremiumTheme.Radius.md)
                    .stroke(glowColor.opacity(0.3), lineWidth: 1)
                    .blur(radius: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Custom Toggle Style
struct PremiumToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? 
                        PremiumTheme.Colors.primaryGradient : 
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 50, height: 30)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                Circle()
                    .fill(.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.spring(response: 0.3), value: configuration.isOn)
            }
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}