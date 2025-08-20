import SwiftUI
import Combine
import Foundation
import UIKit

// Modern 2025 Dashboard with neumorphic design and fluid animations
struct DashboardView: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var strategyManager: StrategyManager
    @EnvironmentObject var marketDataManager: MarketDataManager
    @EnvironmentObject var signalManager: SignalManager
    @EnvironmentObject var tradingManager: TradingManager
    
    // Modern 2025 UI State
    @State private var selectedCard: String? = nil
    @State private var showFullScreenChart = false
    @State private var scrollOffset: CGFloat = 0
    @State private var headerOpacity: Double = 1.0
    @State private var showTradingPairPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Modern Hero Section with Parallax Effect
                        ModernHeroSection()
                            .offset(y: scrollOffset * 0.5)
                        
                        // Immersive Chart Section with Glass Morphism
                        ModernChartSection(showTradingPairPicker: $showTradingPairPicker)
                            .padding(.top, 20)
                        
                        // Fluid Cards Grid with Neumorphic Design
                        ModernCardsGrid()
                            .padding(.top, 30)
                        
                        // Trading Actions with Haptic Feedback
                        ModernTradingActions()
                            .padding(.top, 20)
                            .padding(.bottom, 100) // Safe area padding
                    }
                }
                .scrollIndicators(.hidden)
                .background(
                    // Dynamic gradient background
                    themeManager.backgroundGradient
                        .ignoresSafeArea()
                )
                .overlay(
                    // Floating header with blur effect
                    ModernFloatingHeader()
                        .opacity(headerOpacity),
                    alignment: .top
                )
                .refreshable {
                    await refreshWithHaptics()
                }
            }
            .navigationBarHidden(true)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let offset = value.translation.height
                        scrollOffset = offset
                        headerOpacity = max(0.3, 1.0 - Double(abs(offset)) / 200.0)
                    }
            )
        }
        .sheet(isPresented: $showTradingPairPicker) {
            Text("Trading Pair Picker - TODO")
        }
    }
    
    // MARK: - Modern 2025 Helper Methods
    
    private func refreshWithHaptics() async {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        await dashboardVM.reloadDataAndPredict()
        
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
    }
}

// MARK: - Modern 2025 Dashboard Components

struct ModernHeroSection: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Welcome header with dynamic greeting
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText())
                        .font(Typography.title1)
                        .foregroundColor(TextColor.primary)
                    
                    Text("MyTradeMate")
                        .font(Typography.subheadline)
                        .foregroundColor(TextColor.secondary)
                }
                
                Spacer()
                
                // Live status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(),
                            value: themeManager.isDarkMode
                        )
                    
                    Text("LIVE")
                        .font(Typography.caption1Medium)
                        .foregroundColor(TextColor.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 60) // Safe area compensation
        }
    }
    
    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
}

struct ModernFloatingHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text("Dashboard")
                .font(Typography.headline)
                .foregroundColor(TextColor.primary)
            
            Spacer()
            
            // ✅ REMOVED: Useless gear icon with no action
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 0)
        )
    }
}

struct ModernChartSection: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showTradingPairPicker: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Symbol Picker and Timeframe Selector
            HStack {
                // Symbol Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trading Pair")
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                    
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .foregroundColor(Brand.blue)
                        
                        Text(dashboardVM.selectedTradingPair.displayName)
                            .font(Typography.headline)
                            .foregroundColor(TextColor.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(Typography.caption1)
                            .foregroundColor(TextColor.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.cardBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Brand.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .onTapGesture {
                        // ✅ IMPLEMENTED: Show trading pair picker
                        showTradingPairPicker = true
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
                
                Spacer()
                
                // ✅ ENHANCED: Visible Timeframe Selector with Badge
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Timeframe")
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                    
                    // Current selected timeframe badge
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Brand.blue)
                        
                        Text(dashboardVM.timeframe.rawValue.uppercased())
                            .font(Typography.calloutMedium)
                            .foregroundColor(TextColor.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Brand.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    ModernTimeframeSelector(selectedTimeframe: $dashboardVM.timeframe)
                }
            }
            .padding(.horizontal, 20)
            
            // Enhanced Chart with Glass Morphism
            ZStack {
                themeManager.glassMorphismBackground()
                
                VStack(spacing: 16) {
                    // Chart Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BTC/USDT")
                                .font(Typography.title2)
                                .foregroundColor(TextColor.primary)
                            
                            Text("$\(String(format: "%.2f", dashboardVM.price))")
                                .font(Typography.largeTitle)
                                .foregroundColor(TextColor.primary)
                                .contentTransition(.numericText())
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(dashboardVM.priceChangePercentString)
                                .font(Typography.headline)
                                .foregroundColor(dashboardVM.priceChangeColor)
                            
                            Text("24h")
                                .font(Typography.caption1)
                                .foregroundColor(TextColor.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // ✅ ENHANCED: Chart with Timeframe Badge Overlay
                    if !dashboardVM.chartData.isEmpty {
                        ZStack(alignment: .topTrailing) {
                            CandlestickChartView(data: dashboardVM.chartData.map { candle in
                                CandlePoint(
                                    time: candle.timestamp,
                                    open: candle.open,
                                    high: candle.high,
                                    low: candle.low,
                                    close: candle.close
                                )
                            })
                            .frame(height: 300)
                            
                            // Small timeframe badge overlay
                            Text(dashboardVM.timeframe.rawValue.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Brand.blue.opacity(0.8))
                                )
                                .offset(x: -8, y: 8)
                        }
                        .padding(.horizontal, 20)
                    
                    // ✅ ADD: Last update timestamp under chart
                    HStack {
                        Text("Last update: \(timeAgoString(from: dashboardVM.lastUpdated))")
                            .font(Typography.caption2)
                            .foregroundColor(TextColor.tertiary)
                        
                        Spacer()
                        
                        if dashboardVM.isLoading {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Updating...")
                            }
                            .font(Typography.caption2)
                            .foregroundColor(TextColor.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    } else {
                        // Loading state
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Brand.blue)
                            
                            Text("Loading chart data...")
                                .font(Typography.body)
                                .foregroundColor(TextColor.secondary)
                        }
                        .frame(height: 300)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .padding(.horizontal, 20)
            .onTapGesture {
                // Full screen chart action
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    // ✅ ADD: Helper function for time formatting
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

struct ModernTimeframeSelector: View {
    @Binding var selectedTimeframe: Timeframe
    @EnvironmentObject var themeManager: ThemeManager
    
    let timeframes: [Timeframe] = [.m1, .m5, .m15, .h1, .h4]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(timeframes, id: \.self) { timeframe in
                Button(action: {
                    withAnimation(themeManager.fastAnimation) {
                        selectedTimeframe = timeframe
                    }
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }) {
                    Text(timeframe.rawValue)
                        .font(Typography.calloutMedium)
                        .foregroundColor(
                            selectedTimeframe == timeframe ?
                            Color.white : TextColor.secondary
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    selectedTimeframe == timeframe ?
                                    themeManager.primaryGradient :
                                    LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                }
                .modifier(themeManager.modernButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
}

struct ModernCardsGrid: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ModernMarketDataCard()
            ModernActiveStrategiesCard()
            ModernTradingModeCard()
            ModernSignalStatusCard()
            ModernAIConfidenceCard()
            ModernActiveOrdersCard()
        }
        .padding(.horizontal, 20)
    }
}

struct ModernTradingActions: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var tradingManager: TradingManager
    @State private var showTradeDialog = false
    @State private var tradeSide: TradeSide = .buy
    @State private var tradeAmount: String = "100"
    @State private var stopLoss: String = ""
    @State private var takeProfit: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Trade Amount Input
            VStack(alignment: .leading, spacing: 12) {
                Text("Trade Amount")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                HStack {
                    TextField("Amount", text: $tradeAmount)
                        .font(Typography.body)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("USDT")
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                }
                
                // Risk Management
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stop Loss")
                            .font(Typography.caption1)
                            .foregroundColor(TextColor.secondary)
                        
                        TextField("SL Price", text: $stopLoss)
                            .font(Typography.caption1)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Take Profit")
                            .font(Typography.caption1)
                            .foregroundColor(TextColor.secondary)
                        
                        TextField("TP Price", text: $takeProfit)
                            .font(Typography.caption1)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Buy/Sell Buttons
            HStack(spacing: 16) {
                // Buy Button with Modern Gradient
                Button(action: {
                    tradeSide = .buy
                    showTradeDialog = true
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Buy")
                            .font(Typography.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .modifier(themeManager.modernButtonStyle())
                
                // Sell Button with Modern Gradient
                Button(action: {
                    tradeSide = .sell
                    showTradeDialog = true
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Sell")
                            .font(Typography.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .modifier(themeManager.modernButtonStyle())
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showTradeDialog) {
            TradeConfirmationSheet(
                tradeSide: tradeSide,
                amount: Double(tradeAmount) ?? 0,
                stopLoss: Double(stopLoss),
                takeProfit: Double(takeProfit),
                currentPrice: dashboardVM.price
            )
        }
    }
}

// Trade Confirmation Sheet
struct TradeConfirmationSheet: View {
    let tradeSide: TradeSide
    let amount: Double
    let stopLoss: Double?
    let takeProfit: Double?
    let currentPrice: Double
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tradingManager: TradingManager
    @StateObject private var tradeManager = TradeManager()
    @State private var isExecuting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Trade Summary
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: tradeSide == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(tradeSide == .buy ? .green : .red)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tradeSide == .buy ? "BUY" : "SELL")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(tradeSide == .buy ? .green : .red)
                            
                            Text("BTC/USDT")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Trade Details
                    VStack(spacing: 12) {
                        TradeDetailRow(title: "Amount", value: "\(String(format: "%.2f", amount)) USDT")
                        TradeDetailRow(title: "Price", value: "$\(String(format: "%.2f", currentPrice))")
                        TradeDetailRow(title: "Quantity", value: "\(String(format: "%.6f", amount / currentPrice)) BTC")
                        
                        if let sl = stopLoss {
                            TradeDetailRow(title: "Stop Loss", value: "$\(String(format: "%.2f", sl))")
                        }
                        
                        if let tp = takeProfit {
                            TradeDetailRow(title: "Take Profit", value: "$\(String(format: "%.2f", tp))")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    
                    Button(tradeSide == .buy ? "Buy BTC" : "Sell BTC") {
                        executeTrade()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(tradeSide == .buy ? Color.green : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isExecuting)
                }
            }
            .padding()
            .navigationTitle("Confirm Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func executeTrade() {
        isExecuting = true
        
        // Create trade request
        let tradeRequest = TradeRequest(
            side: OrderSide(rawValue: tradeSide.rawValue) ?? .buy,
            tradingPair: .btcUsd,
            amountMode: .fixedNotional,
            amount: amount,
            price: currentPrice,
            quoteCurrency: .USD,
            type: .market
        )
        
        // Execute trade
        Task {
            do {
                let result = try await tradeManager.executeOrder(tradeRequest, tradingMode: TradingMode.paper)
                print("Trade executed: \(result)")
                dismiss()
            } catch {
                print("Trade failed: \(error)")
            }
            isExecuting = false
        }
    }
}

struct TradeDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}


// MARK: - Modern Dashboard Cards (2025 Design)

struct ModernMarketDataCard: View {
    @EnvironmentObject var marketDataManager: MarketDataManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, Brand.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                // Real price from MarketDataManager
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", marketDataManager.price))")
                        .font(Typography.title3)
                        .foregroundColor(TextColor.primary)
                        .contentTransition(.numericText())
                    
                    // Price change indicator
                    HStack(spacing: 4) {
                        Image(systemName: marketDataManager.priceChange >= 0 ? "arrow.up" : "arrow.down")
                            .foregroundColor(marketDataManager.priceChangeColor)
                            .font(.caption)
                        
                        Text(marketDataManager.priceChangePercentString)
                            .font(Typography.caption2)
                            .foregroundColor(marketDataManager.priceChangeColor)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("BTC/USDT")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text("24h Change:")
                            .font(Typography.caption1)
                            .foregroundColor(TextColor.secondary)
                        
                        Spacer()
                        
                        Text(marketDataManager.priceChangeString)
                            .font(Typography.caption1)
                            .foregroundColor(marketDataManager.priceChangeColor)
                    }
                    
                    HStack {
                        Text("Volume:")
                            .font(Typography.caption1)
                            .foregroundColor(TextColor.secondary)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.0f", marketDataManager.candles.last?.volume ?? 0)) BTC")
                            .font(Typography.caption1)
                            .foregroundColor(TextColor.secondary)
                    }
                    
                    // Last updated
                    Text("Updated: \(marketDataManager.lastUpdatedString)")
                        .font(Typography.caption2)
                        .foregroundColor(TextColor.tertiary)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .background(
            themeManager.neumorphicCardBackground()
        )
    }
}

struct ModernActiveStrategiesCard: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settings: SettingsRepository
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [Brand.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                // Real strategy count from SettingsRepository
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(enabledStrategies.count)")
                        .font(Typography.title2)
                        .foregroundColor(TextColor.primary)
                        .contentTransition(.numericText())
                    
                    Text("of \(totalStrategies)")
                        .font(Typography.caption2)
                        .foregroundColor(TextColor.tertiary)
                }
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Active Strategies")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                if enabledStrategies.isEmpty {
                    Text("No strategies enabled")
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                        .padding(.top, Spacing.xs)
                } else {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(enabledStrategies.prefix(3), id: \.self) { strategy in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text(strategy)
                                    .font(Typography.caption1)
                                    .foregroundColor(TextColor.secondary)
                                
                                Spacer()
                                
                                // Strategy weight
                                if let weight = strategyWeights[strategy] {
                                    Text("\(Int(weight * 100))%")
                                        .font(Typography.caption2)
                                        .foregroundColor(TextColor.tertiary)
                                }
                            }
                        }
                        
                        if enabledStrategies.count > 3 {
                            Text("+\(enabledStrategies.count - 3) more")
                                .font(Typography.caption2)
                                .foregroundColor(TextColor.tertiary)
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }
        .padding(Spacing.xl)
        .background(
            themeManager.neumorphicCardBackground()
        )
    }
    
    // MARK: - Computed Properties
    
    private var enabledStrategies: [String] {
        var strategies: [String] = []
        
        if settings.strategyEnabled["RSI"] == true { strategies.append("RSI") }
        if settings.strategyEnabled["EMA"] == true { strategies.append("EMA") }
        if settings.strategyEnabled["MACD"] == true { strategies.append("MACD") }
        if settings.strategyEnabled["Mean Reversion"] == true { strategies.append("Mean Reversion") }
        if settings.strategyEnabled["ATR"] == true { strategies.append("ATR") }
        
        return strategies
    }
    
    private var totalStrategies: Int {
        return 5 // RSI, EMA, MACD, Mean Reversion, ATR
    }
    
    private var strategyWeights: [String: Double] {
        var weights: [String: Double] = [:]
        
        if settings.strategyEnabled["RSI"] == true { weights["RSI"] = settings.strategyWeights["RSI"] ?? 1.0 }
        if settings.strategyEnabled["EMA"] == true { weights["EMA"] = settings.strategyWeights["EMA"] ?? 1.0 }
        if settings.strategyEnabled["MACD"] == true { weights["MACD"] = settings.strategyWeights["MACD"] ?? 1.0 }
        if settings.strategyEnabled["Mean Reversion"] == true { weights["Mean Reversion"] = settings.strategyWeights["Mean Reversion"] ?? 1.0 }
        if settings.strategyEnabled["ATR"] == true { weights["ATR"] = settings.strategyWeights["ATR"] ?? 1.0 }
        
        return weights
    }
}

struct ModernTradingModeCard: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var settings: SettingsRepository
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [Accent.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                // Real trading mode from SettingsRepository
                VStack(alignment: .trailing, spacing: 4) {
                    Text(settings.tradingMode.title.uppercased())
                        .font(Typography.title3)
                        .foregroundColor(tradingModeColor)
                    
                    // Mode indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(tradingModeColor)
                            .frame(width: 8, height: 8)
                        
                        Text(tradingModeStatus)
                            .font(Typography.caption2)
                            .foregroundColor(tradingModeColor)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Trading Mode")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(tradingModeDescription)
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                    
                    // Auto trading status
                    HStack {
                        Image(systemName: settings.autoTradingEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(settings.autoTradingEnabled ? .green : .red)
                        
                        Text("Auto Trading: \(settings.autoTradingEnabled ? "ON" : "OFF")")
                            .font(Typography.caption2)
                            .foregroundColor(TextColor.tertiary)
                    }
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .background(
            themeManager.neumorphicCardBackground()
        )
    }
    
    // MARK: - Computed Properties
    
    private var tradingModeColor: Color {
        switch settings.tradingMode {
        case .live:
            return Accent.green
        case .paper:
            return Accent.yellow
        case .demo:
            return Brand.blue
        }
    }
    
    private var tradingModeStatus: String {
        switch settings.tradingMode {
        case .live:
            return "LIVE"
        case .paper:
            return "PAPER"
        case .demo:
            return "DEMO"
        }
    }
    
    private var tradingModeDescription: String {
        switch settings.tradingMode {
        case .live:
            return "Real money trading with live market data"
        case .paper:
            return "Paper trading with real market data"
        case .demo:
            return "Demo trading with simulated data"
        }
    }
}

struct ModernSignalStatusCard: View {
    @EnvironmentObject var signalManager: SignalManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [Accent.yellow, Accent.red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                // Real signal from SignalManager
                VStack(alignment: .trailing, spacing: 4) {
                    if let signal = signalManager.currentSignal {
                        Text(signal.direction.uppercased())
                            .font(Typography.title2)
                            .foregroundColor(signalColor(for: signal.direction))
                            .contentTransition(.identity)
                    } else {
                        Text("HOLD")
                            .font(Typography.title2)
                            .foregroundColor(Accent.yellow)
                    }
                    
                    // ✅ FIX: Signal confidence from finalSignal
                    if let finalDecision = signalManager.finalSignal {
                        Text("\(Int(finalDecision.confidence * 100))%")
                            .font(Typography.caption2)
                            .foregroundColor(signalColor(for: finalDecision.action.rawValue))
                    } else {
                        Text("--")
                            .font(Typography.caption2)
                            .foregroundColor(TextColor.tertiary)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Signal Status")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // ✅ FIX: Bind to finalSignal from SignalFusionEngine with enhanced AI status
                    if let finalDecision = signalManager.finalSignal {
                        Text("\(finalDecision.action.rawValue.uppercased()) signal active")
                            .font(Typography.caption1)
                            .foregroundColor(signalColor(for: finalDecision.action.rawValue))
                        
                        // ✅ ENHANCED AI STATUS MESSAGES
                        let aiComponents = finalDecision.components.filter { $0.source.contains("AI") }
                        let confidencePercent = Int(finalDecision.confidence * 100)
                        
                        // ✅ ENHANCED: Check circuit breaker status
                        if signalManager.isAIPaused {
                            // Circuit Breaker Open - AI Paused
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(Typography.caption2)
                                    .foregroundColor(.red)
                                Text("AI Paused – Circuit Breaker Active")
                                    .font(Typography.caption1)
                                    .foregroundColor(.red)
                            }
                        } else if aiComponents.isEmpty {
                            // AI Paused - Strategy-Only Mode (models unavailable)
                            HStack(spacing: 4) {
                                Image(systemName: "pause.circle.fill")
                                    .font(Typography.caption2)
                                    .foregroundColor(.orange)
                                Text("AI Paused – Strategy-Only Mode")
                                    .font(Typography.caption1)
                                    .foregroundColor(.orange)
                            }
                        } else {
                            // AI Active with confidence
                            HStack(spacing: 4) {
                                Image(systemName: "brain.head.profile")
                                    .font(Typography.caption2)
                                    .foregroundColor(.green)
                                Text("AI Active – \(confidencePercent)% confidence")
                                    .font(Typography.caption1)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        // ✅ ADD: Show ensemble rationale
                        Text(finalDecision.rationale)
                            .font(Typography.caption2)
                            .foregroundColor(TextColor.tertiary)
                            .lineLimit(2)
                        
                        // Signal age - use actual timestamp when available
                        Text("Last update: \(timeAgoString(from: Date()))")
                            .font(Typography.caption2)
                            .foregroundColor(TextColor.tertiary)
                    } else {
                        Text("No active signals")
                            .font(Typography.caption1)
                            .foregroundColor(TextColor.secondary)
                        
                        Text("Monitoring market conditions")
                            .font(Typography.caption2)
                            .foregroundColor(TextColor.tertiary)
                    }
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .background(
            themeManager.neumorphicCardBackground()
        )
    }
    
    // MARK: - Helper Methods
    
    private func signalColor(for direction: String) -> Color {
        switch direction.lowercased() {
        case "buy":
            return Accent.green
        case "sell":
            return Accent.red
        case "hold":
            return Accent.yellow
        default:
            return Accent.yellow
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

struct ModernAIConfidenceCard: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var signalManager: SignalManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "brain")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                // ✅ UPDATE: Show confidence from finalSignal with proper AI status
                VStack(alignment: .trailing, spacing: 4) {
                    if let finalDecision = signalManager.finalSignal {
                        let aiComponents = finalDecision.components.filter { $0.source.contains("AI") }
                        let confidencePercent = Int(finalDecision.confidence * 100)
                        
                        Text("\(confidencePercent)%")
                            .font(Typography.title2)
                            .foregroundColor(aiComponents.isEmpty ? .orange : .purple)
                            .contentTransition(.numericText())
                        
                        // Confidence indicator with AI status color
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                Circle()
                                    .fill(index < Int(finalDecision.confidence * 5) ? 
                                          (aiComponents.isEmpty ? .orange : .purple) : 
                                          .gray.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    } else {
                        Text("--%")
                            .font(Typography.title2)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { _ in
                                Circle()
                                    .fill(.gray.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("AI Confidence")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // ✅ UPDATE: Use finalSignal and show AI status properly
                    if let finalDecision = signalManager.finalSignal {
                        let aiComponents = finalDecision.components.filter { $0.source.contains("AI") }
                        
                        if aiComponents.isEmpty {
                            // AI Paused
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("AI Paused")
                                    .font(Typography.caption1)
                                    .foregroundColor(.orange)
                            }
                            
                            Text("Using strategies only")
                                .font(Typography.caption2)
                                .foregroundColor(TextColor.tertiary)
                        } else {
                            // AI Active
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("AI Active")
                                    .font(Typography.caption1)
                                    .foregroundColor(.green)
                            }
                            
                            Text("Combined AI + Strategy signals")
                                .font(Typography.caption2)
                                .foregroundColor(TextColor.tertiary)
                        }
                    } else {
                        Text("Analyzing market...")
                            .font(Typography.caption1)
                            .foregroundColor(TextColor.secondary)
                    }
                    
                    Text("Updated live")
                        .font(Typography.caption2)
                        .foregroundColor(TextColor.tertiary)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .background(
            themeManager.neumorphicCardBackground()
        )
    }
}

struct ModernActiveOrdersCard: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var tradingManager: TradingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "list.clipboard")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [Brand.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                Text("\(tradingManager.openPositions.count)")
                    .font(Typography.title2)
                    .foregroundColor(TextColor.primary)
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Active Positions")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                if tradingManager.openPositions.isEmpty {
                    Text("No open positions")
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                } else {
                    Text("\(tradingManager.openPositions.count) positions open")
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                }
            }
        }
        .padding(Spacing.xl)
        .background(
            themeManager.neumorphicCardBackground()
        )
    }
}

