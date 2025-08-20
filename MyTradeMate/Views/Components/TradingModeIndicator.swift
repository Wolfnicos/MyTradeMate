import SwiftUI
import UIKit

// MARK: - Trading Mode Indicator Component
struct TradingModeIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var appSettings = AppSettings.shared
    
    let isDemo: Bool?
    let style: Style
    let size: Size
    
    // Modern 2025 UI State
    @State private var isPressed = false
    @State private var showDetails = false
    
    private var effectiveIsDemo: Bool {
        isDemo ?? appSettings.demoMode
    }
    
    enum Style {
        case badge
        case pill
        case minimal
        case detailed
        case modern2025 // New modern style
    }
    
    enum Size {
        case small
        case medium
        case large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
    }
    
    init(isDemo: Bool? = nil, style: Style = .modern2025, size: Size = .medium) {
        self.isDemo = isDemo
        self.style = style
        self.size = size
    }
    
    var body: some View {
        Group {
            switch style {
            case .badge:
                badgeStyle
            case .pill:
                pillStyle
            case .minimal:
                minimalStyle
            case .detailed:
                detailedStyle
            case .modern2025:
                modern2025Style
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(themeManager.fastAnimation, value: isPressed)
    }
    
    // MARK: - Modern 2025 Style
    private var modern2025Style: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(themeManager.defaultAnimation) {
                showDetails.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // Modern icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: effectiveIsDemo ? 
                                    [themeManager.warningColor, themeManager.warningColor.opacity(0.7)] :
                                    [themeManager.successColor, themeManager.successColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size.iconSize + 4, height: size.iconSize + 4)
                    
                    Circle()
                        .fill(effectiveIsDemo ? .orange : .green)
                        .frame(width: size.iconSize, height: size.iconSize)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(effectiveIsDemo ? "DEMO" : "LIVE")
                        .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                        .foregroundColor(effectiveIsDemo ? themeManager.warningColor : themeManager.successColor)
                    
                    if showDetails {
                        Text(effectiveIsDemo ? "Simulated Trading" : "Live Trading")
                            .font(.system(size: size.fontSize - 2, weight: .medium))
                            .foregroundColor(TextColor.secondary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                
                Spacer()
                
                // Animated chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: size.fontSize - 2, weight: .semibold))
                    .foregroundColor(TextColor.secondary)
                    .rotationEffect(.degrees(showDetails ? 90 : 0))
                    .animation(themeManager.defaultAnimation, value: showDetails)
            }
            .padding(size.padding)
            .background(
                themeManager.neumorphicCardBackground()
            )
            .overlay(
                // Subtle border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        effectiveIsDemo ? themeManager.warningColor.opacity(0.3) : themeManager.successColor.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - Legacy Styles (Enhanced)
    private var badgeStyle: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(effectiveIsDemo ? themeManager.warningColor : themeManager.successColor)
                .frame(width: size.iconSize, height: size.iconSize)
            
            Text(effectiveIsDemo ? "DEMO" : "LIVE")
                .font(.system(size: size.fontSize, weight: .bold))
                .foregroundColor(effectiveIsDemo ? themeManager.warningColor : themeManager.successColor)
        }
        .padding(size.padding)
        .background(
            Capsule()
                .fill(
                    (effectiveIsDemo ? themeManager.warningColor : themeManager.successColor)
                        .opacity(0.15)
                )
        )
    }
    
    private var pillStyle: some View {
        Text(effectiveIsDemo ? "DEMO" : "LIVE")
            .font(.system(size: size.fontSize, weight: .bold))
            .foregroundColor(.white)
            .padding(size.padding)
            .background(
                Capsule()
                    .fill(effectiveIsDemo ? themeManager.warningColor : themeManager.successColor)
            )
    }
    
    private var minimalStyle: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(effectiveIsDemo ? themeManager.warningColor : themeManager.successColor)
                .frame(width: size.iconSize, height: size.iconSize)
            
            Text(effectiveIsDemo ? "Demo" : "Live")
                .font(.system(size: size.fontSize, weight: .medium))
                .foregroundColor(effectiveIsDemo ? themeManager.warningColor : themeManager.successColor)
        }
    }
    
    private var detailedStyle: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(effectiveIsDemo ? themeManager.warningColor : themeManager.successColor)
                    .frame(width: size.iconSize, height: size.iconSize)
                
                Text(effectiveIsDemo ? "Demo Mode" : "Live Trading")
                    .font(.system(size: size.fontSize, weight: .semibold))
                    .foregroundColor(effectiveIsDemo ? themeManager.warningColor : themeManager.successColor)
            }
            
            Text(effectiveIsDemo ? "Simulated trades only" : "Real trades with actual funds")
                .font(.system(size: size.fontSize - 2, weight: .regular))
                .foregroundColor(TextColor.secondary)
        }
        .padding(size.padding)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    (effectiveIsDemo ? themeManager.warningColor : themeManager.successColor)
                        .opacity(0.1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            effectiveIsDemo ? themeManager.warningColor : themeManager.successColor,
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Trading Mode Warning (Modernized)
struct TradingModeWarning: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject private var appSettings = AppSettings.shared
    
    let isDemo: Bool?
    let message: String?
    
    // Modern 2025 UI State
    @State private var isVisible = false
    
    private var effectiveIsDemo: Bool {
        isDemo ?? appSettings.demoMode
    }
    
    init(isDemo: Bool? = nil, message: String? = nil) {
        self.isDemo = isDemo
        self.message = message
    }
    
    var body: some View {
        if effectiveIsDemo {
            HStack(spacing: 12) {
                // Modern icon with glow effect
                ZStack {
                    Circle()
                        .fill(themeManager.warningColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(themeManager.warningColor)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Demo Mode Active")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(themeManager.warningColor)
                    
                    Text(message ?? "No real trades will be executed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                themeManager.neumorphicCardBackground()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.warningColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(themeManager.defaultAnimation.delay(0.1), value: isVisible)
            .onAppear {
                withAnimation(themeManager.defaultAnimation.delay(0.1)) {
                    isVisible = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("All Styles") {
    VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Demo Mode Indicators")
                .font(.headline)
            
            HStack(spacing: 12) {
                TradingModeIndicator(isDemo: true, style: .badge, size: .small)
                TradingModeIndicator(isDemo: true, style: .badge, size: .medium)
                TradingModeIndicator(isDemo: true, style: .badge, size: .large)
            }
            
            HStack(spacing: 12) {
                TradingModeIndicator(isDemo: true, style: .pill, size: .small)
                TradingModeIndicator(isDemo: true, style: .pill, size: .medium)
                TradingModeIndicator(isDemo: true, style: .pill, size: .large)
            }
            
            TradingModeIndicator(isDemo: true, style: .minimal, size: .medium)
            
            TradingModeIndicator(isDemo: true, style: .detailed, size: .medium)
            
            // New modern 2025 style
            TradingModeIndicator(isDemo: true, style: .modern2025, size: .medium)
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Live Mode Indicators")
                .font(.headline)
            
            HStack(spacing: 12) {
                TradingModeIndicator(isDemo: false, style: .badge, size: .small)
                TradingModeIndicator(isDemo: false, style: .badge, size: .medium)
                TradingModeIndicator(isDemo: false, style: .badge, size: .large)
            }
            
            HStack(spacing: 12) {
                TradingModeIndicator(isDemo: false, style: .pill, size: .small)
                TradingModeIndicator(isDemo: false, style: .pill, size: .medium)
                TradingModeIndicator(isDemo: false, style: .pill, size: .large)
            }
            
            TradingModeIndicator(isDemo: false, style: .minimal, size: .medium)
            
            TradingModeIndicator(isDemo: false, style: .detailed, size: .medium)
            
            // New modern 2025 style
            TradingModeIndicator(isDemo: false, style: .modern2025, size: .medium)
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Warning Component")
                .font(.headline)
            
            TradingModeWarning(isDemo: true)
            TradingModeWarning(isDemo: true, message: "Custom demo mode warning message")
        }
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}