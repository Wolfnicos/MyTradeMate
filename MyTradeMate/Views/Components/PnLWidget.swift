import SwiftUI
import UIKit

struct PnLSnapshot {
    let equity: Double
    let realizedToday: Double
    let unrealized: Double
    let totalPnL: Double
    let totalPnLPercent: Double
    let timestamp: Date
    
    init(equity: Double, realizedToday: Double, unrealized: Double) {
        self.equity = equity
        self.realizedToday = realizedToday
        self.unrealized = unrealized
        self.totalPnL = realizedToday + unrealized
        self.totalPnLPercent = equity > 0 ? (totalPnL / equity) * 100 : 0
        self.timestamp = Date()
    }
}

// MARK: - Modern 2025 PnL Widget
struct PnLWidget: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let snapshot: PnLSnapshot
    let isDemoMode: Bool
    
    // Modern 2025 UI State
    @State private var isVisible = false
    @State private var animateValues = false
    @State private var showDetails = false
    
    private let spacing: CGFloat = 16
    private let cardPadding: CGFloat = 20
    private let cornerRadius: CGFloat = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // Modern header with icon and demo mode indicator
            modernHeaderView
            
            // Main metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ModernPnLMetricCard(
                    title: "Total Equity",
                    value: String(format: "$%.2f", snapshot.equity),
                    change: nil,
                    changeColor: themeManager.primaryColor,
                    icon: "dollarsign.circle.fill"
                )
                
                ModernPnLMetricCard(
                    title: "Today's P&L",
                    value: String(format: "$%.2f", snapshot.realizedToday),
                    change: snapshot.realizedToday,
                    changeColor: snapshot.realizedToday >= 0 ? themeManager.successColor : themeManager.errorColor,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                ModernPnLMetricCard(
                    title: "Unrealized P&L",
                    value: String(format: "$%.2f", snapshot.unrealized),
                    change: snapshot.unrealized,
                    changeColor: snapshot.unrealized >= 0 ? themeManager.successColor : themeManager.errorColor,
                    icon: "chart.bar.fill"
                )
                
                ModernPnLMetricCard(
                    title: "Total P&L",
                    value: String(format: "$%.2f", snapshot.totalPnL),
                    change: snapshot.totalPnL,
                    changeColor: snapshot.totalPnL >= 0 ? themeManager.successColor : themeManager.errorColor,
                    showPercent: true,
                    percentValue: snapshot.totalPnLPercent,
                    icon: "chart.pie.fill"
                )
            }
            
            // Expandable details section
            if showDetails {
                modernDetailsSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(cardPadding)
        .background(
            themeManager.neumorphicCardBackground()
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            // Subtle border
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(themeManager.primaryColor.opacity(0.1), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(themeManager.defaultAnimation.delay(0.1), value: isVisible)
        .onAppear {
            withAnimation(themeManager.defaultAnimation.delay(0.1)) {
                isVisible = true
            }
            withAnimation(themeManager.defaultAnimation.delay(0.3)) {
                animateValues = true
            }
        }
    }
    
    // MARK: - Modern Header View
    private var modernHeaderView: some View {
        HStack(spacing: 12) {
            // Modern icon with gradient
            ZStack {
                Circle()
                    .fill(themeManager.primaryColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.primaryColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Portfolio P&L")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(TextColor.primary)
                
                if isDemoMode {
                    HStack(spacing: 6) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(themeManager.warningColor)
                        
                        Text("DEMO MODE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(themeManager.warningColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        themeManager.warningColor.opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            // Expandable details button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                withAnimation(themeManager.defaultAnimation) {
                    showDetails.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Text(showDetails ? "Hide" : "Details")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.accentColor)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(themeManager.accentColor)
                        .rotationEffect(.degrees(showDetails ? 180 : 0))
                        .animation(themeManager.defaultAnimation, value: showDetails)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    themeManager.accentColor.opacity(0.1)
                )
                .clipShape(Capsule())
            }
            
            // Timestamp
            VStack(alignment: .trailing, spacing: 2) {
                Text(snapshot.timestamp, style: .time)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(TextColor.secondary)
                
                Text(snapshot.timestamp, style: .date)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(TextColor.secondary)
            }
        }
    }
    
    // MARK: - Modern Details Section
    private var modernDetailsSection: some View {
        VStack(spacing: 12) {
            Divider()
                .background(themeManager.primaryColor.opacity(0.2))
            
            HStack(spacing: 16) {
                // Performance indicator
                VStack(spacing: 6) {
                    Text("Performance")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                    
                    ZStack {
                        Circle()
                            .stroke(themeManager.primaryColor.opacity(0.2), lineWidth: 4)
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .trim(from: 0, to: min(1.0, abs(snapshot.totalPnLPercent) / 100.0))
                            .stroke(
                                snapshot.totalPnLPercent >= 0 ? themeManager.successColor : themeManager.errorColor,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    Text(String(format: "%.1f%%", snapshot.totalPnLPercent))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(snapshot.totalPnLPercent >= 0 ? themeManager.successColor : themeManager.errorColor)
                }
                
                Spacer()
                
                // Risk metrics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Risk Metrics")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Drawdown:")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(TextColor.secondary)
                            
                            Spacer()
                            
                            Text("\(snapshot.totalPnL < 0 ? String(format: "%.2f%%", abs(snapshot.totalPnLPercent)) : "0.00%")")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(snapshot.totalPnL < 0 ? themeManager.errorColor : themeManager.successColor)
                        }
                        
                        HStack {
                            Text("Volatility:")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(TextColor.secondary)
                            
                            Spacer()
                            
                            Text("Medium")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(themeManager.warningColor)
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Modern PnL Metric Card
struct ModernPnLMetricCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    let value: String
    let change: Double?
    let changeColor: Color
    let showPercent: Bool
    let percentValue: Double?
    let icon: String
    
    // Modern 2025 UI State
    @State private var isVisible = false
    @State private var showGlow = false
    
    init(title: String, value: String, change: Double?, changeColor: Color, showPercent: Bool = false, percentValue: Double? = nil, icon: String = "chart.bar.fill") {
        self.title = title
        self.value = value
        self.change = change
        self.changeColor = changeColor
        self.showPercent = showPercent
        self.percentValue = percentValue
        self.icon = icon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and title
            HStack(spacing: 6) {
                ZStack {
                    if showGlow {
                        Image(systemName: icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(changeColor)
                            .blur(radius: 1)
                            .scaleEffect(1.1)
                            .opacity(0.6)
                            .animation(themeManager.slowAnimation.repeatForever(autoreverses: true), value: showGlow)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(changeColor)
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(TextColor.secondary)
            }
            
            // Value with animation
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(changeColor)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(themeManager.defaultAnimation.delay(0.1), value: isVisible)
            
            // Change indicator
            if let change = change {
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(changeColor)
                    
                    if showPercent, let percent = percentValue {
                        Text(String(format: "%.2f%%", percent))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(changeColor)
                    } else {
                        Text(abs(change), format: .currency(code: "USD"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(changeColor)
                    }
                }
                .opacity(isVisible ? 1.0 : 0.0)
                .offset(x: isVisible ? 0 : -10)
                .animation(themeManager.defaultAnimation.delay(0.2), value: isVisible)
            }
        }
        .padding(12)
        .background(
            changeColor.opacity(0.05)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(changeColor.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            withAnimation(themeManager.defaultAnimation.delay(0.1)) {
                isVisible = true
            }
            withAnimation(themeManager.defaultAnimation.delay(0.5)) {
                showGlow = true
            }
        }
    }
}

// MARK: - Legacy PnL Metric Card (Enhanced)
struct PnLMetricCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    let value: String
    let change: Double?
    let changeColor: Color
    let showPercent: Bool
    let percentValue: Double?
    
    init(title: String, value: String, change: Double?, changeColor: Color, showPercent: Bool = false, percentValue: Double? = nil) {
        self.title = title
        self.value = value
        self.change = change
        self.changeColor = changeColor
        self.showPercent = showPercent
        self.percentValue = percentValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(TextColor.secondary)
            
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(changeColor)
            
            if let change = change {
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                        .foregroundColor(changeColor)
                    
                    if showPercent, let percent = percentValue {
                        Text(String(format: "%.2f%%", percent))
                            .font(.caption2)
                            .foregroundColor(changeColor)
                    } else {
                        Text(abs(change), format: .currency(code: "USD"))
                            .font(.caption2)
                            .foregroundColor(changeColor)
                    }
                }
            }
        }
        .padding(8)
        .background(
            themeManager.primaryColor.opacity(0.05)
        )
        .cornerRadius(6)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        PnLWidget(
            snapshot: PnLSnapshot(
                equity: 10250.75,
                realizedToday: 125.50,
                unrealized: -45.20
            ),
            isDemoMode: false
        )
        
        PnLWidget(
            snapshot: PnLSnapshot(
                equity: 9875.30,
                realizedToday: -124.70,
                unrealized: 89.15
            ),
            isDemoMode: true
        )
    }
    .padding()
    .background(ThemeManager.shared.backgroundGradient)
    .environmentObject(ThemeManager.shared)
}