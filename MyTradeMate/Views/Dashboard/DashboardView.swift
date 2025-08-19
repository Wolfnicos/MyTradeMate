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
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Modern Hero Section with Parallax Effect
                        ModernHeroSection()
                            .offset(y: scrollOffset * 0.5)
                        
                        // Immersive Chart Section with Glass Morphism
                        ModernChartSection()
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
            
            Button(action: {
                // Settings action with haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(TextColor.secondary)
            }
            .modifier(themeManager.modernButtonStyle())
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
    @State private var selectedTimeframe: Timeframe = .m5
    
    var body: some View {
        VStack(spacing: 20) {
            // Modern Timeframe Selector with Glass Morphism
            ModernTimeframeSelector(selectedTimeframe: $selectedTimeframe)
            
            // Immersive Chart Container
            ZStack {
                // Glass morphism background
                themeManager.glassMorphismBackground()
                
                VStack(spacing: 16) {
                    // Chart header with live price
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("BTC/USDT")
                                .font(Typography.title3)
                                .foregroundColor(TextColor.primary)
                            
                            Text("$\(String(format: "%.2f", dashboardVM.price))")
                                .font(Typography.largeTitle)
                                .foregroundColor(TextColor.primary)
                                .contentTransition(.numericText())
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("+2.34%")
                                .font(Typography.headline)
                                .foregroundColor(.green)
                            
                            Text("24h")
                                .font(Typography.caption1)
                                .foregroundColor(TextColor.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Enhanced Chart
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
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
    
    var body: some View {
        HStack(spacing: 16) {
            // Buy Button with Modern Gradient
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                // Handle buy action
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
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                // Handle sell action
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
}



// MARK: - Modern Dashboard Cards (2025 Design)

struct ModernMarketDataCard: View {
    @EnvironmentObject var marketDataManager: MarketDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, Brand.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                Text("$\(String(format: "%.2f", marketDataManager.chartData.last?.close ?? 0))")
                    .font(Typography.title3)
                    .foregroundColor(TextColor.primary)
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Portfolio Value")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                HStack {
                    Text("+$1,234.56")
                        .font(Typography.caption1)
                        .foregroundColor(Accent.green)
                    
                    Text("(+2.8%)")
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(Spacing.xl)
        .background(
            ThemeManager.shared.neumorphicCardBackground()
        )
    }
}

struct ModernActiveStrategiesCard: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [Brand.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                Text("\(dashboardVM.activeStrategies.count)")
                    .font(Typography.title2)
                    .foregroundColor(TextColor.primary)
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Active Strategies")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                if dashboardVM.activeStrategies.isEmpty {
                    Text("No strategies enabled")
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                        .padding(.top, Spacing.xs)
                } else {
                    Text(dashboardVM.activeStrategies.joined(separator: ", "))
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                        .padding(.top, Spacing.xs)
                }
            }
        }
        .padding(Spacing.xl)
        .background(
            ThemeManager.shared.neumorphicCardBackground()
        )
    }
}

struct ModernTradingModeCard: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [Accent.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                Text(dashboardVM.currentTradingMode)
                    .font(Typography.title3)
                    .foregroundColor(dashboardVM.isLiveMode ? Accent.green : dashboardVM.isPaperMode ? Accent.yellow : Brand.blue)
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Trading Mode")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                Text(dashboardVM.isLiveMode ? "Real money trading" : dashboardVM.isPaperMode ? "Paper trading" : "Demo trading")
                    .font(Typography.caption1)
                    .foregroundColor(TextColor.secondary)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .background(
            ThemeManager.shared.neumorphicCardBackground()
        )
    }
}

struct ModernSignalStatusCard: View {
    @EnvironmentObject var signalManager: SignalManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [Accent.yellow, Accent.red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                Text("HOLD")
                    .font(Typography.title2)
                    .foregroundColor(Accent.yellow)
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Signal Status")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                Text("No active signals")
                    .font(Typography.caption1)
                    .foregroundColor(TextColor.secondary)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .background(
            ThemeManager.shared.neumorphicCardBackground()
        )
    }
}

struct ModernAIConfidenceCard: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "brain")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                Text("\(Int(dashboardVM.aiConfidencePercentage))%")
                    .font(Typography.title2)
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("AI Confidence")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Current signal confidence")
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                    Text("Updated live")
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .background(
            ThemeManager.shared.neumorphicCardBackground()
        )
    }
}

struct ModernActiveOrdersCard: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: "list.clipboard")
                    .font(Typography.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [Brand.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                
                Spacer()
                
                Text("0")
                    .font(Typography.title2)
                    .foregroundColor(TextColor.primary)
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Active Orders")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                Text("No pending orders")
                    .font(Typography.caption1)
                    .foregroundColor(TextColor.secondary)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.xl)
        .background(
            ThemeManager.shared.neumorphicCardBackground()
        )
    }
}
