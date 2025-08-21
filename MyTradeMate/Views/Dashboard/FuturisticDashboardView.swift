import SwiftUI
import Charts

struct FuturisticDashboardView: View {
    @StateObject private var dashboardVM = RefactoredDashboardVM()
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    @State private var showAIInsights = true
    @State private var portfolioAnimation = false
    
    var body: some View {
        ZStack {
            // Neural Background
            NeuralBackgroundView()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Portfolio Overview Card
                    PortfolioOverviewCard(dashboardVM: dashboardVM)
                    
                    // AI Prediction Card
                    AIPredictionCard()
                    
                    // Live Markets Grid
                    LiveMarketsGrid()
                    
                    // AI Intelligence Feed
                    if showAIInsights {
                        AIIntelligenceFeed()
                    }
                    
                    // Performance Metrics
                    PerformanceMetricsGrid()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Space for tab bar
            }
        }
    }
}

// MARK: - Portfolio Overview Card
struct PortfolioOverviewCard: View {
    @ObservedObject var dashboardVM: RefactoredDashboardVM
    @State private var animateValue = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Portfolio Display
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text("$")
                                .font(FuturisticTheme.Typography.title)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("125,432.89")
                                .font(FuturisticTheme.Typography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .scaleEffect(animateValue ? 1.05 : 1.0)
                                .animation(FuturisticTheme.Animation.spring, value: animateValue)
                        }
                        
                        Text("Total Portfolio Value")
                            .font(FuturisticTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(FuturisticTheme.Colors.success)
                            
                            Text("+12.34%")
                                .font(FuturisticTheme.Typography.headline)
                                .fontWeight(.bold)
                                .foregroundColor(FuturisticTheme.Colors.success)
                        }
                        
                        Text("+$14,234")
                            .font(FuturisticTheme.Typography.caption)
                            .foregroundColor(FuturisticTheme.Colors.success)
                    }
                }
                
                // Simplified Chart Area
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    FuturisticTheme.Colors.neuralBlue.opacity(0.1),
                                    FuturisticTheme.Colors.neuralPurple.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)
                    
                    VStack {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 24))
                                .foregroundColor(FuturisticTheme.Colors.neuralBlue)
                            
                            Text("Real-time Portfolio Chart")
                                .font(FuturisticTheme.Typography.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Timeframe Pills
                        HStack(spacing: 8) {
                            ForEach(["1m", "5m", "15m", "1h", "4h", "1d"], id: \.self) { timeframe in
                                Button(action: {}) {
                                    Text(timeframe)
                                        .font(FuturisticTheme.Typography.small)
                                        .fontWeight(.medium)
                                        .foregroundColor(timeframe == "1h" ? .white : .white.opacity(0.6))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(timeframe == "1h" ? FuturisticTheme.Gradients.neuralPrimary : Color.clear)
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(FuturisticTheme.Gradients.glassMorphism)
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
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
            
            // Quick Stats Row
            HStack(spacing: 0) {
                QuickStatItem(label: "24h Change", value: "+$14,234", isPositive: true)
                    .frame(maxWidth: .infinity)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 40)
                
                QuickStatItem(label: "Win Rate", value: "87.3%", isPositive: true)
                    .frame(maxWidth: .infinity)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 40)
                
                QuickStatItem(label: "Active Bots", value: "6", isPositive: nil)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(FuturisticTheme.Colors.backgroundCard.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            .offset(y: -12)
        }
        .onAppear {
            animateValue = true
        }
    }
}

struct QuickStatItem: View {
    let label: String
    let value: String
    let isPositive: Bool?
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(FuturisticTheme.Typography.small)
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(FuturisticTheme.Typography.caption)
                .fontWeight(.bold)
                .foregroundColor(
                    isPositive == true ? FuturisticTheme.Colors.success :
                    isPositive == false ? FuturisticTheme.Colors.danger :
                    .white
                )
        }
    }
}

// MARK: - AI Prediction Card
struct AIPredictionCard: View {
    @State private var confidence: Double = 94.2
    @State private var animatePrediction = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundColor(FuturisticTheme.Colors.neuralBlue)
                        .scaleEffect(animatePrediction ? 1.1 : 1.0)
                        .animation(FuturisticTheme.Animation.pulse, value: animatePrediction)
                    
                    Text("AI Prediction")
                        .font(FuturisticTheme.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(FuturisticTheme.Colors.warning)
                    .scaleEffect(animatePrediction ? 1.2 : 1.0)
                    .animation(FuturisticTheme.Animation.pulse, value: animatePrediction)
            }
            
            VStack(spacing: 16) {
                // Prediction Display
                Text("STRONG BUY")
                    .font(FuturisticTheme.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(FuturisticTheme.Colors.success)
                    .scaleEffect(animatePrediction ? 1.05 : 1.0)
                    .animation(FuturisticTheme.Animation.spring, value: animatePrediction)
                
                // Confidence Gauge
                HStack(spacing: 8) {
                    Image(systemName: "gauge.medium")
                        .font(.system(size: 14))
                        .foregroundColor(FuturisticTheme.Colors.warning)
                    
                    Text("Confidence: \(Int(confidence))%")
                        .font(FuturisticTheme.Typography.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Prediction Details
                VStack(spacing: 8) {
                    PredictionDetailRow(label: "Target Price", value: "$102,450", color: FuturisticTheme.Colors.success)
                    PredictionDetailRow(label: "Stop Loss", value: "$92,100", color: FuturisticTheme.Colors.danger)
                    PredictionDetailRow(label: "Timeframe", value: "24-48h", color: .white)
                }
            }
        }
        .padding(24)
        .neuralCard()
        .onAppear {
            animatePrediction = true
        }
    }
}

struct PredictionDetailRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(FuturisticTheme.Typography.small)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(FuturisticTheme.Typography.small)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Live Markets Grid
struct LiveMarketsGrid: View {
    @State private var selectedCrypto = "BTC"
    
    let cryptos = [
        ("BTC", "$95,234.56", "+2.34%", true),
        ("ETH", "$3,456.78", "-1.23%", false),
        ("SOL", "$178.90", "+5.67%", true),
        ("AVAX", "$45.23", "+3.21%", true)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Live Markets")
                    .font(FuturisticTheme.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {}) {
                        Image(systemName: "grid.fill")
                            .font(.system(size: 14))
                            .foregroundColor(FuturisticTheme.Colors.neuralBlue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(FuturisticTheme.Colors.neuralBlue.opacity(0.2))
                            )
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(Array(cryptos.enumerated()), id: \.offset) { index, crypto in
                    CryptoCard(
                        symbol: crypto.0,
                        price: crypto.1,
                        change: crypto.2,
                        isPositive: crypto.3,
                        isSelected: selectedCrypto == crypto.0
                    )
                    .onTapGesture {
                        withAnimation(FuturisticTheme.Animation.spring) {
                            selectedCrypto = crypto.0
                        }
                    }
                }
            }
        }
    }
}

struct CryptoCard: View {
    let symbol: String
    let price: String
    let change: String
    let isPositive: Bool
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(FuturisticTheme.Colors.warning)
                    
                    Text(symbol)
                        .font(FuturisticTheme.Typography.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(change)
                    .font(FuturisticTheme.Typography.small)
                    .fontWeight(.medium)
                    .foregroundColor(isPositive ? FuturisticTheme.Colors.success : FuturisticTheme.Colors.danger)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((isPositive ? FuturisticTheme.Colors.success : FuturisticTheme.Colors.danger).opacity(0.2))
                    )
            }
            
            Text(price)
                .font(FuturisticTheme.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Vol: 45.2B")
                .font(FuturisticTheme.Typography.small)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isSelected ? 
                    FuturisticTheme.Gradients.neuralPrimary.opacity(0.3) :
                    FuturisticTheme.Gradients.glassMorphism
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? 
                            FuturisticTheme.Colors.neuralBlue :
                            Color.white.opacity(0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(FuturisticTheme.Animation.spring, value: isSelected)
    }
}

// MARK: - AI Intelligence Feed
struct AIIntelligenceFeed: View {
    let insights = [
        ("bullish", "Strong buying pressure detected. Neural network predicts 8% upside in 24h", 92),
        ("alert", "Unusual whale activity detected. Large accumulation phase ongoing", 88),
        ("neutral", "RSI cooling down from overbought. Good entry point approaching", 85)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("AI Intelligence Feed")
                    .font(FuturisticTheme.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(FuturisticTheme.Colors.warning)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
                    AIInsightCard(
                        type: insight.0,
                        message: insight.1,
                        confidence: insight.2
                    )
                }
            }
        }
        .padding(20)
        .neuralCard()
    }
}

struct AIInsightCard: View {
    let type: String
    let message: String
    let confidence: Int
    
    var iconName: String {
        switch type {
        case "bullish": return "arrow.up.right"
        case "bearish": return "arrow.down.right"
        case "alert": return "exclamationmark.triangle"
        default: return "info.circle"
        }
    }
    
    var iconColor: Color {
        switch type {
        case "bullish": return FuturisticTheme.Colors.success
        case "bearish": return FuturisticTheme.Colors.danger
        case "alert": return FuturisticTheme.Colors.warning
        default: return FuturisticTheme.Colors.info
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(message)
                    .font(FuturisticTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 12))
                            .foregroundColor(FuturisticTheme.Colors.neuralBlue)
                        
                        Text("\(confidence)% confidence")
                            .font(FuturisticTheme.Typography.small)
                            .foregroundColor(FuturisticTheme.Colors.neuralBlue)
                    }
                    
                    Text("Just now")
                        .font(FuturisticTheme.Typography.small)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(iconColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(iconColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Performance Metrics Grid
struct PerformanceMetricsGrid: View {
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            MetricCard(
                icon: "arrow.up.right",
                title: "$23,456",
                subtitle: "Total Profit",
                change: "+23.4%",
                isPositive: true,
                gradient: FuturisticTheme.Gradients.success
            )
            
            MetricCard(
                icon: "target",
                title: "1,247",
                subtitle: "Total Trades",
                change: "87.3%",
                isPositive: true,
                gradient: FuturisticTheme.Gradients.neuralPrimary
            )
            
            MetricCard(
                icon: "award",
                title: "Expert",
                subtitle: "Trader Rank",
                change: "Level 5",
                isPositive: nil,
                gradient: FuturisticTheme.Gradients.neuralSecondary
            )
            
            MetricCard(
                icon: "bolt.fill",
                title: "AI Score",
                subtitle: "Performance",
                change: "94.2%",
                isPositive: true,
                gradient: LinearGradient(
                    colors: [FuturisticTheme.Colors.warning, Color.orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let change: String
    let isPositive: Bool?
    let gradient: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(change)
                    .font(FuturisticTheme.Typography.small)
                    .fontWeight(.bold)
                    .foregroundColor(
                        isPositive == true ? FuturisticTheme.Colors.success :
                        isPositive == false ? FuturisticTheme.Colors.danger :
                        .white.opacity(0.8)
                    )
            }
            
            Text(title)
                .font(FuturisticTheme.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(FuturisticTheme.Typography.small)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(gradient.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        FuturisticTheme.Colors.backgroundPrimary
            .ignoresSafeArea()
        
        FuturisticDashboardView()
    }
}