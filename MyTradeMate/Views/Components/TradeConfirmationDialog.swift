import SwiftUI
import UIKit

// Using DesignSystem for spacing and corner radius

// MARK: - Modern 2025 Trade Confirmation Dialog
struct TradeConfirmationDialog: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let trade: TradeRequest
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let onExecutionComplete: (Bool) -> Void // New callback for execution result
    
    // Modern 2025 UI State
    @State private var isExecuting = false
    @State private var executionError: String?
    @State private var isVisible = false
    @State private var showDetails = false
    @State private var animateValues = false
    
    @EnvironmentObject private var toastManager: ToastManager
    
    init(
        trade: TradeRequest,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onExecutionComplete: @escaping (Bool) -> Void
    ) {
        self.trade = trade
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.onExecutionComplete = onExecutionComplete
    }
    
    var body: some View {
        ConfirmationDialog(
            title: "Confirm Trade",
            message: "Please review your order details",
            icon: trade.side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
            iconColor: trade.side == .buy ? themeManager.successColor : themeManager.errorColor,
            confirmButtonText: confirmButtonText,
            confirmButtonColor: trade.side == .buy ? themeManager.successColor : themeManager.errorColor,
            cancelButtonText: "Cancel",
            isDestructive: false,
            isExecuting: isExecuting,
            onConfirm: handleConfirm,
            onCancel: onCancel,
            content: {
                AnyView(
                    VStack(spacing: 20) {
                        // Modern Order Summary
                        modernOrderSummaryView
                        
                        // Modern Trading Mode Warning
                        modernTradingModeWarning
                        
                        // Expandable Details Section
                        if showDetails {
                            modernDetailsSection
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Error message if any
                        if let error = executionError {
                            modernErrorMessageView(error)
                        }
                        
                        // Details Toggle Button
                        modernDetailsToggleButton
                    }
                )
            }
        )
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1.0 : 0.9)
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
    
    private var confirmButtonText: String {
        if AppSettings.shared.demoMode {
            return "Confirm \(trade.side.rawValue.capitalized) (DEMO)"
        } else {
            return "Confirm \(trade.side.rawValue.capitalized)"
        }
    }
    
    private var tradingModeDisplayText: String {
        if AppSettings.shared.demoMode {
            return "DEMO"
        } else {
            return "LIVE TRADING"
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 1.0 {
            return String(format: "%.4f", amount)
        } else if amount >= 0.001 {
            return String(format: "%.6f", amount)
        } else {
            return String(format: "%.8f", amount)
        }
    }
    
    // MARK: - Modern Order Summary View
    private var modernOrderSummaryView: some View {
        VStack(spacing: 20) {
            // Modern header with icon
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            trade.side == .buy ? 
                                themeManager.successColor.opacity(0.1) : 
                                themeManager.errorColor.opacity(0.1)
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: trade.side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(
                            trade.side == .buy ? themeManager.successColor : themeManager.errorColor
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order Summary")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(TextColor.primary)
                    
                    Text("Review your trade details")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                }
                
                Spacer()
            }
            
            // Modern order details grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ModernOrderSummaryCard(
                    title: "Symbol",
                    value: trade.symbol,
                    icon: "chart.line.uptrend.xyaxis",
                    color: themeManager.primaryColor
                )
                
                ModernOrderSummaryCard(
                    title: "Side",
                    value: trade.side.rawValue.uppercased(),
                    icon: trade.side == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                    color: trade.side == .buy ? themeManager.successColor : themeManager.errorColor
                )
                
                ModernOrderSummaryCard(
                    title: "Amount",
                    value: formatAmount(trade.amount),
                    icon: "number.circle.fill",
                    color: themeManager.accentColor
                )
                
                ModernOrderSummaryCard(
                    title: "Est. Price",
                    value: String(format: "$%.2f", trade.price),
                    icon: "dollarsign.circle.fill",
                    color: themeManager.warningColor
                )
                
                ModernOrderSummaryCard(
                    title: "Order Type",
                    value: "Market Order",
                    icon: "list.bullet.circle.fill",
                    color: themeManager.primaryColor
                )
                
                ModernOrderSummaryCard(
                    title: "Est. Value",
                    value: String(format: "$%.2f", trade.amount * trade.price),
                    icon: "chart.pie.fill",
                    color: themeManager.accentColor
                )
            }
            
            // Trading mode indicator
            HStack(spacing: 12) {
                Image(systemName: AppSettings.shared.demoMode ? "dumbbell.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppSettings.shared.demoMode ? themeManager.warningColor : themeManager.errorColor)
                
                Text("Trading Mode")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(TextColor.secondary)
                
                Spacer()
                
                Text(tradingModeDisplayText)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppSettings.shared.demoMode ? themeManager.warningColor : themeManager.errorColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        AppSettings.shared.demoMode ? 
                            themeManager.warningColor.opacity(0.1) : 
                            themeManager.errorColor.opacity(0.1)
                    )
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                AppSettings.shared.demoMode ? 
                    themeManager.warningColor.opacity(0.05) : 
                    themeManager.errorColor.opacity(0.05)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        AppSettings.shared.demoMode ? 
                            themeManager.warningColor.opacity(0.2) : 
                            themeManager.errorColor.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .padding(20)
        .background(
            themeManager.neumorphicCardBackground()
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    trade.side == .buy ? 
                        themeManager.successColor.opacity(0.2) : 
                        themeManager.errorColor.opacity(0.2),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Modern Details Toggle Button
    private var modernDetailsToggleButton: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(themeManager.defaultAnimation) {
                showDetails.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(themeManager.accentColor)
                    .rotationEffect(.degrees(showDetails ? 0 : 0))
                    .animation(themeManager.defaultAnimation, value: showDetails)
                
                Text(showDetails ? "Hide Details" : "Show Details")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                themeManager.accentColor.opacity(0.1)
            )
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Modern Details Section
    private var modernDetailsSection: some View {
        VStack(spacing: 16) {
            Divider()
                .background(themeManager.primaryColor.opacity(0.2))
            
            HStack(spacing: 20) {
                // Risk assessment
                VStack(spacing: 8) {
                    Text("Risk Level")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                    
                    ZStack {
                        Circle()
                            .stroke(themeManager.warningColor.opacity(0.2), lineWidth: 3)
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                themeManager.warningColor,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    Text("Medium")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(themeManager.warningColor)
                }
                
                Spacer()
                
                // Market conditions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Market Conditions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Volatility:")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(TextColor.secondary)
                            
                            Spacer()
                            
                            Text("High")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(themeManager.errorColor)
                        }
                        
                        HStack {
                            Text("Liquidity:")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(TextColor.secondary)
                            
                            Spacer()
                            
                            Text("Good")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(themeManager.successColor)
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Action Handlers
    
    private func handleConfirm() {
        Task {
            await handleTradeExecution()
        }
    }
    
    private func handleTradeExecution() async {
        isExecuting = true
        
        // Haptic feedback for execution start
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Simulate trade execution
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let success = true
        isExecuting = false
        
        // Haptic feedback for execution result
        let notificationFeedback = UINotificationFeedbackGenerator()
        if success {
            notificationFeedback.notificationOccurred(.success)
        } else {
            notificationFeedback.notificationOccurred(.error)
        }
        
        // Notify parent of execution result
        onExecutionComplete(success)
        
        // If successful, also call the original onConfirm callback
        if success {
            onConfirm()
        }
    }
    
    // MARK: - Modern UI Components
    
    private func modernErrorMessageView(_ error: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(themeManager.errorColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(themeManager.errorColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Order Failed")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.errorColor)
                
                Text(error)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(TextColor.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            themeManager.errorColor.opacity(0.05)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.errorColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var modernTradingModeWarning: some View {
        Group {
            if AppSettings.shared.demoMode {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(themeManager.warningColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(themeManager.warningColor)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Demo Mode Active")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.warningColor)
                        
                        Text("This is a simulated trade - no real funds will be used")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(TextColor.secondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    themeManager.warningColor.opacity(0.05)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.warningColor.opacity(0.2), lineWidth: 1)
                )
            } else {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(themeManager.errorColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(themeManager.errorColor)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Live Trading Mode")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.errorColor)
                        
                        Text("This will place a real order with actual funds")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(TextColor.secondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    themeManager.errorColor.opacity(0.05)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.errorColor.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Order Status Tracking View
    
    private func orderStatusTrackingView(_ trackedOrder: TrackedOrder) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Order Status")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                Text("ID: \(String(trackedOrder.id.prefix(8)))")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(TextColor.secondary)
            }
            
            CompactOrderStatusView(trackedOrder: trackedOrder)
        }
        .padding(12)
        .background(
            themeManager.primaryColor.opacity(0.05)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Modern Order Summary Card
struct ModernOrderSummaryCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    // Modern 2025 UI State
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and title
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(TextColor.secondary)
            }
            
            // Value
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(TextColor.primary)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(themeManager.defaultAnimation.delay(0.1), value: isVisible)
        }
        .padding(12)
        .background(
            color.opacity(0.05)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            withAnimation(themeManager.defaultAnimation.delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Legacy Order Summary Row (Enhanced)
struct OrderSummaryRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let label: String
    let value: String
    let valueColor: Color
    let valueWeight: Font.Weight
    let showBadge: Bool
    
    init(
        label: String,
        value: String,
        valueColor: Color = .primary,
        valueWeight: Font.Weight = .regular,
        showBadge: Bool = false
    ) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.valueWeight = valueWeight
        self.showBadge = showBadge
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(TextColor.secondary)
            
            Spacer()
            
            if showBadge {
                Text(value)
                    .font(.system(size: 12, weight: valueWeight))
                    .foregroundColor(valueColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(valueColor.opacity(0.15))
                    .cornerRadius(6)
            } else {
                Text(value)
                    .font(.system(size: 14, weight: valueWeight))
                    .foregroundColor(valueColor)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            TradeConfirmationDialog(
                trade: TradeRequest(
                    symbol: "BTC/USDT",
                    side: .buy,
                    amount: 0.001,
                    price: 45000.0,
                    type: .market,
                    timeInForce: .goodTillCanceled
                ),
                onConfirm: {},
                onCancel: {},
                onExecutionComplete: { _ in }
            )
            
            TradeConfirmationDialog(
                trade: TradeRequest(
                    symbol: "ETH/USDT",
                    side: .sell,
                    amount: 0.5,
                    price: 3200.0,
                    type: .market,
                    timeInForce: .goodTillCanceled
                ),
                onConfirm: {},
                onCancel: {},
                onExecutionComplete: { _ in }
            )
        }
        .environmentObject(ToastManager())
        .environmentObject(ThemeManager.shared)
        .padding()
    }
}