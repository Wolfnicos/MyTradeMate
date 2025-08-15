import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var vm = DashboardVM()
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                priceSection
                miniChartSection
                controlsSection
                signalCardSection
                quickActionsSection
                positionsPreviewSection
                connectionStatusSection
            }
            .padding()
        }
        .background(Bg.primary)
        .navigationTitle("Dashboard")
        .onAppear {
            vm.refreshData()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("BTC/USDT")
                    .headingM()
                    .foregroundColor(TextColor.primary)
                
                Text("Binance")
                    .captionStyle()
            }
            
            Spacer()
            
            StatusBadge(status: settings.demoMode ? .demo : .live)
        }
    }
    
    // MARK: - Price Section
    private var priceSection: some View {
        Card {
            VStack(spacing: 8) {
                Text("$\(vm.priceString)")
                    .headingXL()
                    .foregroundColor(TextColor.primary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: vm.price)
                
                HStack(spacing: 12) {
                    Text(vm.priceChangeString)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(vm.priceChangeColor)
                    
                    Text("(\(vm.priceChangePercentString))")
                        .font(.system(size: 14))
                        .foregroundColor(vm.priceChangeColor.opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Mini Chart Section
    private var miniChartSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Price Chart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(TextColor.primary)
                
                if vm.isLoading {
                    ProgressView()
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                } else if !vm.chartPoints.isEmpty {
                    SparklineChart(points: vm.chartPoints)
                        .frame(height: 100)
                } else {
                    Text("No data available")
                        .captionStyle()
                        .frame(height: 100)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        Card {
            VStack(spacing: 16) {
                // Timeframe selector
                HStack {
                    Text("Timeframe")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                    
                    Spacer()
                    
                    SegmentedPill(
                        selection: $vm.timeframe,
                        options: [
                            ("5m", Timeframe.m5),
                            ("1h", Timeframe.h1),
                            ("4h", Timeframe.h4)
                        ]
                    )
                }
                
                // Mode selector
                HStack {
                    Text("Mode")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                    
                    Spacer()
                    
                    SegmentedPill(
                        selection: $vm.isPrecisionMode,
                        options: [
                            ("Normal", false),
                            ("Precision", true)
                        ]
                    )
                }
                
                // Auto/Manual switch
                HStack {
                    Text("Trading")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                    
                    Spacer()
                    
                    AutoSwitch(isAuto: $settings.autoTrading)
                }
            }
        }
        .onChange(of: vm.timeframe) { _ in
            vm.refreshData()
        }
    }
    
    // MARK: - Signal Card Section
    private var signalCardSection: some View {
        Card {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(vm.currentSignal?.direction.uppercased() ?? "HOLD")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(signalColor)
                            
                            if settings.demoMode {
                                Pill(text: "DEMO", color: Accent.yellow)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text("\(Int(vm.currentSignal?.confidence ?? 0))% confidence")
                                .captionStyle()
                            
                            Text("•")
                                .captionStyle()
                            
                            Text(vm.timeframe.rawValue)
                                .captionStyle()
                            
                            Text("•")
                                .captionStyle()
                            
                            Text(vm.lastUpdatedString)
                                .captionStyle()
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        vm.refreshPrediction()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Brand.blue)
                            .padding(8)
                            .background(Brand.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .disabled(vm.isRefreshing)
                }
                
                if let reason = vm.currentSignal?.reason {
                    Text(reason)
                        .font(.system(size: 13))
                        .foregroundColor(TextColor.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                vm.executeBuy()
            }) {
                Text("BUY")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Accent.green)
                    .cornerRadius(12)
            }
            .disabled(settings.autoTrading)
            
            Button(action: {
                vm.executeSell()
            }) {
                Text("SELL")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Accent.red)
                    .cornerRadius(12)
            }
            .disabled(settings.autoTrading)
        }
        .opacity(settings.autoTrading ? 0.5 : 1.0)
    }
    
    // MARK: - Positions Preview Section
    private var positionsPreviewSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Open Positions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(TextColor.primary)
                    
                    Spacer()
                    
                    NavigationLink(destination: TradesView()) {
                        Text("View All")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Brand.blue)
                    }
                }
                
                if vm.openPositions.isEmpty {
                    Text("No open positions")
                        .captionStyle()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(vm.openPositions.prefix(2)) { position in
                        PositionRow(position: position)
                    }
                }
            }
        }
    }
    
    // MARK: - Connection Status Section
    private var connectionStatusSection: some View {
        Card {
            HStack {
                Image(systemName: vm.isConnected ? "wifi" : "wifi.slash")
                    .font(.system(size: 14))
                    .foregroundColor(vm.isConnected ? Accent.green : Accent.red)
                
                Text(vm.connectionStatus)
                    .font(.system(size: 14))
                    .foregroundColor(TextColor.secondary)
                
                Spacer()
                
                if vm.isConnected {
                    Circle()
                        .fill(Accent.green)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Accent.green.opacity(0.3), lineWidth: 8)
                                .scaleEffect(vm.isConnected ? 2 : 1)
                                .opacity(vm.isConnected ? 0 : 1)
                                .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: vm.isConnected)
                        )
                }
            }
        }
    }
    
    // MARK: - Helpers
    private var signalColor: Color {
        guard let signal = vm.currentSignal else { return TextColor.secondary }
        switch signal.direction {
        case "BUY": return Accent.green
        case "SELL": return Accent.red
        default: return TextColor.secondary
        }
    }
}

// MARK: - Sparkline Chart
struct SparklineChart: View {
    let points: [CGPoint]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard points.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                
                path.move(to: CGPoint(
                    x: points[0].x * width,
                    y: (1 - points[0].y) * height
                ))
                
                for point in points.dropFirst() {
                    path.addLine(to: CGPoint(
                        x: point.x * width,
                        y: (1 - point.y) * height
                    ))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [Brand.blue, Brand.blue.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
        }
    }
}

// MARK: - Position Row
struct PositionRow: View {
    let position: Position
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(position.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(TextColor.primary)
                
                Text("\(position.side) • \(position.size)")
                    .font(.system(size: 12))
                    .foregroundColor(TextColor.secondary)
            }
            
            Spacer()
            
            Text(position.pnlString)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(position.pnl >= 0 ? Accent.green : Accent.red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashboardView()
                .environmentObject(AppSettings.shared)
        }
    }
}