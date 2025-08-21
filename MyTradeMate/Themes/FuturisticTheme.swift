import SwiftUI

// MARK: - Futuristic Design System
struct FuturisticTheme {
    
    // MARK: - Colors
    struct Colors {
        // Neural Blue Palette
        static let neuralBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
        static let neuralPurple = Color(red: 147/255, green: 51/255, blue: 234/255)
        static let neuralCyan = Color(red: 6/255, green: 182/255, blue: 212/255)
        
        // Glass Background Colors
        static let glassDark = Color.black.opacity(0.5)
        static let glassLight = Color.white.opacity(0.1)
        
        // Dark Mode Backgrounds
        static let backgroundPrimary = Color(red: 15/255, green: 23/255, blue: 42/255)
        static let backgroundSecondary = Color(red: 30/255, green: 41/255, blue: 59/255)
        static let backgroundCard = Color(red: 51/255, green: 65/255, blue: 85/255).opacity(0.5)
        
        // Light Mode Backgrounds
        static let lightBackgroundPrimary = Color(red: 248/255, green: 250/255, blue: 252/255)
        static let lightBackgroundSecondary = Color.white
        static let lightBackgroundCard = Color.white.opacity(0.8)
        
        // Status Colors
        static let success = Color(red: 34/255, green: 197/255, blue: 94/255)
        static let danger = Color(red: 239/255, green: 68/255, blue: 68/255)
        static let warning = Color(red: 245/255, green: 158/255, blue: 11/255)
        static let info = neuralBlue
        
        // Trading Colors
        static let bullish = Color(red: 34/255, green: 197/255, blue: 94/255)
        static let bearish = Color(red: 239/255, green: 68/255, blue: 68/255)
        static let neutral = Color(red: 156/255, green: 163/255, blue: 175/255)
    }
    
    // MARK: - Gradients
    struct Gradients {
        static let neuralPrimary = LinearGradient(
            colors: [Colors.neuralBlue, Colors.neuralPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let neuralSecondary = LinearGradient(
            colors: [Colors.neuralCyan, Colors.neuralBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let success = LinearGradient(
            colors: [Colors.success, Color(red: 16/255, green: 185/255, blue: 129/255)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let danger = LinearGradient(
            colors: [Colors.danger, Color(red: 220/255, green: 38/255, blue: 127/255)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let glassMorphism = LinearGradient(
            colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardBackground = LinearGradient(
            colors: [
                Colors.backgroundCard,
                Colors.backgroundCard.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let subheadline = Font.system(size: 18, weight: .medium, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 14, weight: .medium, design: .rounded)
        static let small = Font.system(size: 12, weight: .regular, design: .rounded)
    }
    
    // MARK: - Animation
    struct Animation {
        static let spring = SwiftUI.Animation.interpolatingSpring(
            mass: 1.0,
            stiffness: 100.0,
            damping: 10.0,
            initialVelocity: 0.0
        )
        
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let pulse = SwiftUI.Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let glassMorphism = Shadow(
            color: .black.opacity(0.15),
            radius: 20,
            x: 0,
            y: 8
        )
        
        static let elevated = Shadow(
            color: .black.opacity(0.25),
            radius: 10,
            x: 0,
            y: 4
        )
        
        static let subtle = Shadow(
            color: .black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - View Extensions for Easy Access
extension View {
    func neuralCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(FuturisticTheme.Gradients.glassMorphism)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: .black.opacity(0.15),
                        radius: 20,
                        x: 0,
                        y: 8
                    )
            )
    }
    
    func neuralButton() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FuturisticTheme.Gradients.neuralPrimary)
                    .shadow(
                        color: FuturisticTheme.Colors.neuralBlue.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
    }
    
    func glowEffect(color: Color = FuturisticTheme.Colors.neuralBlue, radius: CGFloat = 8) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

// MARK: - Animated Neural Background
struct NeuralBackgroundView: View {
    @State private var animate = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                colors: colorScheme == .dark ? [
                    FuturisticTheme.Colors.backgroundPrimary,
                    FuturisticTheme.Colors.backgroundSecondary
                ] : [
                    FuturisticTheme.Colors.lightBackgroundPrimary,
                    FuturisticTheme.Colors.lightBackgroundSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated orbs
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                FuturisticTheme.Colors.neuralBlue.opacity(0.3),
                                FuturisticTheme.Colors.neuralPurple.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(
                        x: animate ? 100 : -100,
                        y: animate ? -50 : 50
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.5),
                        value: animate
                    )
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
            }
            
            // Neural network lines
            Path { path in
                let width = UIScreen.main.bounds.width
                let height = UIScreen.main.bounds.height
                
                for _ in 0..<20 {
                    let startX = CGFloat.random(in: 0...width)
                    let startY = CGFloat.random(in: 0...height)
                    let endX = CGFloat.random(in: 0...width)
                    let endY = CGFloat.random(in: 0...height)
                    
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [
                        FuturisticTheme.Colors.neuralBlue.opacity(0.1),
                        Color.clear,
                        FuturisticTheme.Colors.neuralPurple.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .opacity(animate ? 0.5 : 0.2)
            .animation(
                Animation.easeInOut(duration: 4)
                    .repeatForever(autoreverses: true),
                value: animate
            )
        }
        .onAppear {
            animate = true
        }
    }
}