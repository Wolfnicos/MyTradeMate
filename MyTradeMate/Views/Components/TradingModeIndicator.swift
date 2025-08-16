import SwiftUI

// MARK: - Trading Mode Indicator Component
struct TradingModeIndicator: View {
    let isDemo: Bool
    let style: Style
    let size: Size
    
    enum Style {
        case badge
        case pill
        case minimal
        case detailed
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
    
    init(isDemo: Bool = AppSettings.shared.demoMode, style: Style = .badge, size: Size = .medium) {
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
            }
        }
    }
    
    private var badgeStyle: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isDemo ? .orange : .green)
                .frame(width: size.iconSize, height: size.iconSize)
            
            Text(isDemo ? "DEMO" : "LIVE")
                .font(.system(size: size.fontSize, weight: .bold))
                .foregroundColor(isDemo ? .orange : .green)
        }
        .padding(size.padding)
        .background(
            Capsule()
                .fill((isDemo ? Color.orange : Color.green).opacity(0.15))
        )
    }
    
    private var pillStyle: some View {
        Text(isDemo ? "DEMO" : "LIVE")
            .font(.system(size: size.fontSize, weight: .bold))
            .foregroundColor(.white)
            .padding(size.padding)
            .background(
                Capsule()
                    .fill(isDemo ? .orange : .green)
            )
    }
    
    private var minimalStyle: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isDemo ? .orange : .green)
                .frame(width: size.iconSize, height: size.iconSize)
            
            Text(isDemo ? "Demo" : "Live")
                .font(.system(size: size.fontSize, weight: .medium))
                .foregroundColor(isDemo ? .orange : .green)
        }
    }
    
    private var detailedStyle: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isDemo ? .orange : .green)
                    .frame(width: size.iconSize, height: size.iconSize)
                
                Text(isDemo ? "Demo Mode" : "Live Trading")
                    .font(.system(size: size.fontSize, weight: .semibold))
                    .foregroundColor(isDemo ? .orange : .green)
            }
            
            Text(isDemo ? "Simulated trades only" : "Real trades with actual funds")
                .font(.system(size: size.fontSize - 2, weight: .regular))
                .foregroundColor(.secondary)
        }
        .padding(size.padding)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((isDemo ? Color.orange : Color.green).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isDemo ? .orange : .green, lineWidth: 1)
                )
        )
    }
}

// MARK: - Trading Mode Warning
struct TradingModeWarning: View {
    let isDemo: Bool
    let message: String?
    
    init(isDemo: Bool = AppSettings.shared.demoMode, message: String? = nil) {
        self.isDemo = isDemo
        self.message = message
    }
    
    var body: some View {
        if isDemo {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                
                Text(message ?? "Demo Mode - No real trades will be executed")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.orange.opacity(0.1))
            .cornerRadius(8)
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
}