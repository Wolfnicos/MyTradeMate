import SwiftUI

// MARK: - Modern Hero Section Component
struct ModernHeroSection: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var signalManager: SignalManager
    @EnvironmentObject var tradingManager: TradingManager
    @State private var animateValue = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Portfolio Value Card
            PortfolioValueCard()
            
            // Quick Stats Row
            QuickStatsRow()
            
            // AI Signal Card
            if let signal = signalManager.finalSignal {
                AISignalCard(signal: signal)
            }
        }
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Portfolio Value Card
struct PortfolioValueCard: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var tradingManager: TradingManager
    @State private var animateValue = false
    
    var portfolioValue: Double {
        dashboardVM.portfolioValue
    }
    
    var dailyChange: Double {
        dashboardVM.dailyPnL
    }
    
    var dailyChangePercent: Double {
        dashboardVM.dailyPnLPercent
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Glass morphism background
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.15),
                        Color.purple.opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Glass effect
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
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
                
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Portfolio Value")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Animated value
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("$")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(portfolioValue.formatted(.number.precision(.fractionLength(2))))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .contentTransition(.numericText())
                                    .animation(.spring(), value: portfolioValue)
                            }
                        }
                        
                        Spacer()
                        
                        // Change indicator
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: dailyChange >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(dailyChange >= 0 ? .green : .red)
                                
                                Text("\(dailyChange >= 0 ? "+" : "")\(dailyChangePercent.formatted(.percent.precision(.fractionLength(2))))")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(dailyChange >= 0 ? .green : .red)
                            }
                            
                            Text("24h Change")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Mini chart placeholder
                    MiniChartView()
                        .frame(height: 60)
                    
                    // Bottom stats
                    HStack(spacing: 0) {
                        PortfolioStatItem(
                            title: "24h Volume",
                            value: "$\(dashboardVM.volume24h.formatted(.number.precision(.fractionLength(1))))M",
                            change: "+12.3%",
                            isPositive: true
                        )
                        
                        Divider()
                            .frame(height: 30)
                            .padding(.horizontal)
                        
                        PortfolioStatItem(
                            title: "Win Rate",
                            value: "\(Int(dashboardVM.winRate * 100))%",
                            change: "+2.1%",
                            isPositive: true
                        )
                        
                        Divider()
                            .frame(height: 30)
                            .padding(.horizontal)
                        
                        PortfolioStatItem(
                            title: "Active Bots",
                            value: "\(tradingManager.activeBotsCount)",
                            change: "Running",
                            isPositive: true
                        )
                    }
                }
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        .shadow(color: Color.blue.opacity(0.2), radius: 30, x: 0, y: 15)
        .onAppear {
            withAnimation(.spring()) {
                animateValue = true
            }
        }
    }
}

// MARK: - Mini Chart View
struct MiniChartView: View {
    @State private var animatePath = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Chart line placeholder
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: height * 0.7))
                    
                    // Create smooth curve
                    for x in stride(from: 0, to: width, by: width / 20) {
                        let y = height * (0.5 + sin(x / 30) * 0.3 * sin(x / 10))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .trim(from: 0, to: animatePath ? 1 : 0)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .animation(.easeInOut(duration: 1.5), value: animatePath)
            }
        }
        .onAppear {
            animatePath = true
        }
    }
}

// MARK: - Portfolio Stat Item
struct PortfolioStatItem: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
            
            Text(change)
                .font(.caption2)
                .foregroundColor(isPositive ? .green : .red)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Stats Row
struct QuickStatsRow: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var signalManager: SignalManager
    @EnvironmentObject var tradingManager: TradingManager
    
    var aiConfidence: Double {
        signalManager.finalSignal?.confidence ?? 0.0
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Today's P&L",
                    value: "\(dashboardVM.dailyPnL >= 0 ? "+" : "")$\(dashboardVM.dailyPnL.formatted(.number.precision(.fractionLength(0))))",
                    change: "\(dashboardVM.dailyPnLPercent >= 0 ? "+" : "")\(dashboardVM.dailyPnLPercent.formatted(.percent.precision(.fractionLength(1))))",
                    color: dashboardVM.dailyPnL >= 0 ? .green : .red
                )
                
                QuickStatCard(
                    icon: "brain",
                    title: "AI Confidence",
                    value: "\(Int(aiConfidence * 100))%",
                    change: signalManager.finalSignal?.action.rawValue.capitalized ?? "Hold",
                    color: .blue
                )
                
                QuickStatCard(
                    icon: "bolt.fill",
                    title: "Active Trades",
                    value: "\(tradingManager.openPositions.count)",
                    change: "\(tradingManager.profitablePositions.count) Profit",
                    color: .orange
                )
                
                QuickStatCard(
                    icon: "shield.fill",
                    title: "Risk Score",
                    value: riskScoreText,
                    change: "\(Int(dashboardVM.riskScore * 100))/100",
                    color: riskScoreColor
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var riskScoreText: String {
        let score = dashboardVM.riskScore
        switch score {
        case 0..<0.3: return "Low"
        case 0.3..<0.7: return "Medium"
        default: return "High"
        }
    }
    
    private var riskScoreColor: Color {
        let score = dashboardVM.riskScore
        switch score {
        case 0..<0.3: return .green
        case 0.3..<0.7: return .orange
        default: return .red
        }
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let icon: String
    let title: String
    let value: String
    let change: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
            
            Text(change)
                .font(.caption2)
                .foregroundColor(color)
        }
        .frame(width: 140)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - AI Signal Card
struct AISignalCard: View {
    let signal: FinalSignal
    @State private var pulseAnimation = false
    
    var signalColor: Color {
        switch signal.action {
        case .buy: return .green
        case .sell: return .red
        case .hold: return .gray
        }
    }
    
    var signalIcon: String {
        switch signal.action {
        case .buy: return "arrow.up.circle.fill"
        case .sell: return "arrow.down.circle.fill"
        case .hold: return "minus.circle.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(signalColor)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(signalColor.opacity(0.3), lineWidth: 8)
                                .scaleEffect(pulseAnimation ? 2 : 1)
                                .opacity(pulseAnimation ? 0 : 1)
                                .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: pulseAnimation)
                        )
                    
                    Text("AI Signal Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Now")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Signal Content
            HStack {
                // Signal Direction
                VStack(alignment: .leading, spacing: 4) {
                    Text(signal.action.rawValue.uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(signalColor)
                    
                    Text("Signal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Confidence
                VStack(alignment: .center, spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: signal.confidence)
                            .stroke(
                                LinearGradient(
                                    colors: [signalColor, signalColor.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(signal.confidence * 100))%")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    Text("Confidence")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Icon
                Image(systemName: signalIcon)
                    .font(.system(size: 40))
                    .foregroundColor(signalColor)
                    .padding()
                    .background(signalColor.opacity(0.1))
                    .cornerRadius(16)
            }
            
            // Reason
            if !signal.rationale.isEmpty {
                Text(signal.rationale)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(signalColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: signalColor.opacity(0.2), radius: 10, x: 0, y: 5)
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - Extensions for missing properties
extension RefactoredDashboardVM {
    var volume24h: Double {
        // Calculate from market data or return a default
        return 45.2
    }
    
    var winRate: Double {
        // Calculate win rate or return a default
        return 0.68
    }
    
    var riskScore: Double {
        // Calculate risk score or return a default
        return 0.28
    }
}

extension TradingManager {
    var activeBotsCount: Int {
        // Return number of active bots/strategies
        return 6
    }
    
    var profitablePositions: [Position] {
        // Filter profitable positions
        return openPositions.filter { $0.unrealizedPnL > 0 }
    }
}

// MARK: - Position Protocol for compatibility
protocol Position {
    var unrealizedPnL: Double { get }
}