import SwiftUI

struct FuturisticTabBar: View {
    @Binding var selectedTab: Int
    @State private var tabAnimation = false
    
    let tabs = [
        (icon: "house.fill", title: "Dashboard", id: 0),
        (icon: "chart.line.uptrend.xyaxis", title: "Trading", id: 1),
        (icon: "brain.head.profile", title: "AI Bots", id: 2),
        (icon: "chart.bar.fill", title: "Analytics", id: 3)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.id) { tab in
                TabBarItem(
                    icon: tab.icon,
                    title: tab.title,
                    isSelected: selectedTab == tab.id
                )
                .onTapGesture {
                    withAnimation(FuturisticTheme.Animation.spring) {
                        selectedTab = tab.id
                        tabAnimation.toggle()
                    }
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            // Glassmorphism background
            RoundedRectangle(cornerRadius: 24)
                .fill(FuturisticTheme.Colors.glassDark)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 34) // Safe area padding
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Selection background
                if isSelected {
                    Circle()
                        .fill(FuturisticTheme.Gradients.neuralPrimary)
                        .frame(width: 48, height: 48)
                        .scaleEffect(iconScale)
                        .animation(FuturisticTheme.Animation.spring, value: isSelected)
                }
                
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 20 : 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .scaleEffect(iconScale)
                    .animation(FuturisticTheme.Animation.spring, value: isSelected)
            }
            
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .animation(FuturisticTheme.Animation.easeInOut, value: isSelected)
        }
        .onChange(of: isSelected) { newValue in
            if newValue {
                withAnimation(FuturisticTheme.Animation.spring) {
                    iconScale = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(FuturisticTheme.Animation.spring) {
                        iconScale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Main Navigation View
struct FuturisticMainView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background
            NeuralBackgroundView()
            
            VStack(spacing: 0) {
                // Header
                NeuralHeaderView()
                
                // Content Area
                ZStack {
                    switch selectedTab {
                    case 0:
                        FuturisticDashboardView()
                    case 1:
                        FuturisticTradingView()
                    case 2:
                        FuturisticBotsView()
                    case 3:
                        FuturisticAnalyticsView()
                    default:
                        FuturisticDashboardView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
            
            // Floating Tab Bar
            VStack {
                Spacer()
                FuturisticTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

// MARK: - Placeholder Views for Other Tabs
struct FuturisticTradingView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Chart and Trading Interface
                TradingInterfaceCard()
                
                // Quick Order Panel
                QuickOrderPanel()
                
                // Recent Trades
                RecentTradesCard()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

struct TradingInterfaceCard: View {
    @State private var selectedTimeframe = "1H"
    @State private var selectedCrypto = "BTC"
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with symbol and price
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(selectedCrypto)/USD")
                        .font(FuturisticTheme.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text("$95,234.56")
                            .font(FuturisticTheme.Typography.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("+2.34%")
                            .font(FuturisticTheme.Typography.caption)
                            .foregroundColor(FuturisticTheme.Colors.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(FuturisticTheme.Colors.success.opacity(0.2))
                            )
                    }
                }
                
                Spacer()
                
                // Timeframe selector
                HStack(spacing: 4) {
                    ForEach(["1M", "5M", "15M", "1H", "4H", "1D"], id: \.self) { tf in
                        Button(action: { selectedTimeframe = tf }) {
                            Text(tf)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedTimeframe == tf ? .white : .white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(selectedTimeframe == tf ? FuturisticTheme.Gradients.neuralPrimary : Color.clear)
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
            }
            
            // Chart Area
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                FuturisticTheme.Colors.neuralBlue.opacity(0.05),
                                FuturisticTheme.Colors.neuralPurple.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 300)
                
                VStack {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 24))
                            .foregroundColor(FuturisticTheme.Colors.neuralBlue)
                        
                        Text("Advanced Trading Chart")
                            .font(FuturisticTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    Text("Real-time data streaming")
                        .font(FuturisticTheme.Typography.small)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom)
                }
            }
            
            // Technical Indicators
            HStack(spacing: 12) {
                TechnicalIndicator(label: "RSI", value: "68.4", color: .white)
                TechnicalIndicator(label: "MACD", value: "Bullish", color: FuturisticTheme.Colors.success)
                TechnicalIndicator(label: "Volume", value: "High", color: .white)
                TechnicalIndicator(label: "Trend", value: "↑ Strong", color: FuturisticTheme.Colors.success)
            }
        }
        .padding(24)
        .neuralCard()
    }
}

struct TechnicalIndicator: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(FuturisticTheme.Typography.small)
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(FuturisticTheme.Typography.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct QuickOrderPanel: View {
    @State private var orderType = "Market"
    @State private var orderAmount = "1000"
    @State private var limitPrice = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Quick Trade")
                .font(FuturisticTheme.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Order type selector
            HStack(spacing: 8) {
                ForEach(["Market", "Limit"], id: \.self) { type in
                    Button(action: { orderType = type }) {
                        Text(type)
                            .font(FuturisticTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(orderType == type ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(orderType == type ? FuturisticTheme.Gradients.neuralPrimary : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
            
            // Amount input
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount (USD)")
                    .font(FuturisticTheme.Typography.small)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Enter amount", text: $orderAmount)
                        .font(FuturisticTheme.Typography.body)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // Buy/Sell buttons
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("Buy")
                        .font(FuturisticTheme.Typography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(FuturisticTheme.Gradients.success)
                        )
                }
                
                Button(action: {}) {
                    Text("Sell")
                        .font(FuturisticTheme.Typography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(FuturisticTheme.Gradients.danger)
                        )
                }
            }
        }
        .padding(24)
        .neuralCard()
    }
}

struct RecentTradesCard: View {
    let trades = [
        ("BTC/USD", "Buy", "0.05", "$94,856", "+$234.50", "2 min ago", true),
        ("ETH/USD", "Sell", "2.3", "$3,478", "-$45.20", "15 min ago", false),
        ("SOL/USD", "Buy", "10", "$175.50", "+$34.00", "1 hour ago", true)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Trades")
                    .font(FuturisticTheme.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(Array(trades.enumerated()), id: \.offset) { index, trade in
                    TradeRow(
                        pair: trade.0,
                        type: trade.1,
                        amount: trade.2,
                        price: trade.3,
                        pnl: trade.4,
                        time: trade.5,
                        isProfit: trade.6
                    )
                }
            }
        }
        .padding(20)
        .neuralCard()
    }
}

struct TradeRow: View {
    let pair: String
    let type: String
    let amount: String
    let price: String
    let pnl: String
    let time: String
    let isProfit: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pair)
                    .font(FuturisticTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(type)
                    .font(FuturisticTheme.Typography.small)
                    .foregroundColor(type == "Buy" ? FuturisticTheme.Colors.success : FuturisticTheme.Colors.danger)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill((type == "Buy" ? FuturisticTheme.Colors.success : FuturisticTheme.Colors.danger).opacity(0.2))
                    )
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(pnl)
                    .font(FuturisticTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isProfit ? FuturisticTheme.Colors.success : FuturisticTheme.Colors.danger)
                
                Text(time)
                    .font(FuturisticTheme.Typography.small)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 8)
    }
}

// Placeholder views for other tabs
struct FuturisticBotsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("AI Trading Bots")
                    .font(FuturisticTheme.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("Coming soon...")
                    .font(FuturisticTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

struct FuturisticAnalyticsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Analytics Dashboard")
                    .font(FuturisticTheme.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("Performance metrics coming soon...")
                    .font(FuturisticTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
}

#Preview {
    FuturisticMainView()
}