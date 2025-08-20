import SwiftUI
import UIKit

// MARK: - Modern 2025 Trading Buttons
struct BuyButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let isDisabled: Bool
    let isDemoMode: Bool
    let action: () -> Void
    
    // Modern 2025 UI State
    @State private var isPressed = false
    @State private var showGlow = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 12) {
                // Modern icon with glow effect
                ZStack {
                    if showGlow {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.successColor)
                            .blur(radius: 2)
                            .scaleEffect(1.2)
                            .opacity(0.6)
                            .animation(themeManager.slowAnimation.repeatForever(autoreverses: true), value: showGlow)
                    }
                    
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Text("BUY")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Demo mode indicator
                if isDemoMode {
                    Image(systemName: "dumbbell.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                // Modern gradient with neumorphic effect
                ZStack {
                    if isDisabled {
                        themeManager.neumorphicCardBackground()
                    } else {
                        LinearGradient(
                            colors: [
                                themeManager.successColor,
                                themeManager.successColor.opacity(0.8),
                                themeManager.successColor.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .overlay(
                // Subtle border and shadow
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isDemoMode ? themeManager.warningColor.opacity(0.5) : Color.clear,
                        lineWidth: isDemoMode ? 2 : 0
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: isDisabled ? Color.clear : themeManager.successColor.opacity(0.3),
                radius: isPressed ? 8 : 12,
                x: 0,
                y: isPressed ? 2 : 4
            )
        }
        .disabled(isDisabled)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(themeManager.fastAnimation, value: isPressed)
        .pressEvents {
            withAnimation(themeManager.fastAnimation) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(themeManager.fastAnimation) {
                isPressed = false
            }
        }
        .onAppear {
            if !isDisabled {
                withAnimation(themeManager.defaultAnimation.delay(0.5)) {
                    showGlow = true
                }
            }
        }
    }
}

struct SellButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let isDisabled: Bool
    let isDemoMode: Bool
    let action: () -> Void
    
    // Modern 2025 UI State
    @State private var isPressed = false
    @State private var showGlow = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 12) {
                // Modern icon with glow effect
                ZStack {
                    if showGlow {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.errorColor)
                            .blur(radius: 2)
                            .scaleEffect(1.2)
                            .opacity(0.6)
                            .animation(themeManager.slowAnimation.repeatForever(autoreverses: true), value: showGlow)
                    }
                    
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Text("SELL")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Demo mode indicator
                if isDemoMode {
                    Image(systemName: "dumbbell.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                // Modern gradient with neumorphic effect
                ZStack {
                    if isDisabled {
                        themeManager.neumorphicCardBackground()
                    } else {
                        LinearGradient(
                            colors: [
                                themeManager.errorColor,
                                themeManager.errorColor.opacity(0.8),
                                themeManager.errorColor.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .overlay(
                // Subtle border and shadow
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isDemoMode ? themeManager.warningColor.opacity(0.5) : Color.clear,
                        lineWidth: isDemoMode ? 2 : 0
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: isDisabled ? Color.clear : themeManager.errorColor.opacity(0.3),
                radius: isPressed ? 8 : 12,
                x: 0,
                y: isPressed ? 2 : 4
            )
        }
        .disabled(isDisabled)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(themeManager.fastAnimation, value: isPressed)
        .pressEvents {
            withAnimation(themeManager.fastAnimation) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(themeManager.fastAnimation) {
                isPressed = false
            }
        }
        .onAppear {
            if !isDisabled {
                withAnimation(themeManager.defaultAnimation.delay(0.5)) {
                    showGlow = true
                }
            }
        }
    }
}

// MARK: - Modern Button Style
struct ModernTradingButtonStyle: SwiftUI.ButtonStyle {
    @EnvironmentObject var themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(themeManager.fastAnimation, value: configuration.isPressed)
    }
}

// MARK: - Legacy Button Style (Enhanced)
struct TradingButtonStyle: SwiftUI.ButtonStyle {
    @EnvironmentObject var themeManager: ThemeManager
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(themeManager.fastAnimation, value: configuration.isPressed)
    }
}

// MARK: - Modern Loading State View
struct TradingLoadingStateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let message: String
    
    // Modern 2025 UI State
    @State private var isVisible = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        HStack(spacing: 16) {
            // Modern animated progress indicator
            ZStack {
                Circle()
                    .stroke(themeManager.primaryColor.opacity(0.2), lineWidth: 3)
                    .frame(width: 24, height: 24)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [themeManager.primaryColor, themeManager.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(
                        themeManager.slowAnimation.repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(TextColor.primary)
                
                Text("Please wait...")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(TextColor.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            themeManager.neumorphicCardBackground()
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .animation(themeManager.defaultAnimation.delay(0.1), value: isVisible)
        .onAppear {
            withAnimation(themeManager.defaultAnimation.delay(0.1)) {
                isVisible = true
            }
            rotationAngle = 360
        }
    }
}

// MARK: - Modern Trading Button Container
struct ModernTradingButtonContainer: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let buyAction: () -> Void
    let sellAction: () -> Void
    let isDisabled: Bool
    let isDemoMode: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Buy/Sell buttons
            HStack(spacing: 16) {
                BuyButton(isDisabled: isDisabled, isDemoMode: isDemoMode, action: buyAction)
                SellButton(isDisabled: isDisabled, isDemoMode: isDemoMode, action: sellAction)
            }
            
            // Demo mode warning
            if isDemoMode {
                TradingModeWarning(isDemo: true, message: "Trading in demo mode - no real funds")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            themeManager.glassMorphismBackground()
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        // Modern buttons
        VStack(spacing: 16) {
            Text("Modern 2025 Trading Buttons")
                .font(.headline)
            
            HStack(spacing: 16) {
                BuyButton(isDisabled: false, isDemoMode: false) {}
                SellButton(isDisabled: false, isDemoMode: false) {}
            }
            
            HStack(spacing: 16) {
                BuyButton(isDisabled: false, isDemoMode: true) {}
                SellButton(isDisabled: false, isDemoMode: true) {}
            }
            
            HStack(spacing: 16) {
                BuyButton(isDisabled: true, isDemoMode: false) {}
                SellButton(isDisabled: true, isDemoMode: false) {}
            }
        }
        
        Divider()
        
        // Modern loading state
        VStack(spacing: 16) {
            Text("Modern Loading State")
                .font(.headline)
            
            TradingLoadingStateView(message: "Submitting order...")
        }
        
        Divider()
        
        // Modern button container
        VStack(spacing: 16) {
            Text("Modern Button Container")
                .font(.headline)
            
            ModernTradingButtonContainer(
                buyAction: {},
                sellAction: {},
                isDisabled: false,
                isDemoMode: true
            )
        }
    }
    .padding()
    .background(ThemeManager.shared.backgroundGradient)
    .environmentObject(ThemeManager.shared)
}