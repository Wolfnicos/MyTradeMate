import SwiftUI
import Combine
import Foundation
import UIKit

struct DashboardView: View {
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var strategyManager: StrategyManager
    @EnvironmentObject var marketDataManager: MarketDataManager
    @EnvironmentObject var signalManager: SignalManager
    @EnvironmentObject var tradingManager: TradingManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Candle Chart Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Chart")
                                .font(.headline)
                            Spacer()
                            Picker("Timeframe", selection: $marketDataManager.timeframe) {
                                Text("1m").tag(Timeframe.m1)
                                Text("5m").tag(Timeframe.m5)
                                Text("15m").tag(Timeframe.m15)
                                Text("1h").tag(Timeframe.h1)
                                Text("4h").tag(Timeframe.h4)
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal)
                        
                        CandlestickChartView(data: marketDataManager.chartData.map { candle in
                            CandlePoint(
                                time: candle.timestamp,
                                open: candle.open,
                                high: candle.high,
                                low: candle.low,
                                close: candle.close
                            )
                        })
                            .frame(height: 200)
                            .padding(.horizontal)
                    }
                    
                    // Cards Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // Market Data Card
                        MarketDataCard()
                        
                        // Active Strategies Card
                        ActiveStrategiesCard()
                        
                        // Trading Mode Card
                        TradingModeCard()
                        
                        // Signal Status Card
                        SignalStatusCard()
                        
                        // AI Confidence Card
                        AIConfidenceCard()
                        
                        // Active Orders Card
                        ActiveOrdersCard()
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await marketDataManager.loadMarketData()
            }
        }
    }
}

struct ActiveStrategiesCard: View {
    @EnvironmentObject var strategyManager: StrategyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("Active Strategies")
                    .font(.headline)
                Spacer()
                Text("\(strategyManager.activeStrategies.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if strategyManager.activeStrategies.isEmpty {
                Text("No strategies enabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(strategyManager.activeStrategies, id: \.name) { strategy in
                    HStack {
                        Text(strategy.name)
                            .font(.caption)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(12)
    }
}

struct TradingModeCard: View {
    @EnvironmentObject var settings: SettingsRepository
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Trading Mode")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                Text(settings.tradingMode.rawValue.capitalized)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(modeColor)
                Spacer()
            }
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(12)
    }
    
    private var modeColor: Color {
        switch settings.tradingMode {
        case .live:
            return .red
        case .paper:
            return .orange
        case .demo:
            return .blue
        }
    }
}

struct MarketDataCard: View {
    @EnvironmentObject var marketDataManager: MarketDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.purple)
                Text("Market Data")
                    .font(.headline)
                Spacer()
            }
            
            if marketDataManager.price > 0 {
                HStack {
                    Text("$\(marketDataManager.price, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(12)
    }
}

struct SignalStatusCard: View {
    @EnvironmentObject var signalManager: SignalManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.yellow)
                Text("Signal Status")
                    .font(.headline)
                Spacer()
            }
            
            if let currentSignal = signalManager.currentSignal {
                HStack {
                    Text(currentSignal.direction.uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(signalColor)
                    Spacer()
                    Text("\(currentSignal.confidence * 100, specifier: "%.1f")%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No signal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(12)
    }
    
    private var signalColor: Color {
        guard let currentSignal = signalManager.currentSignal else { return .secondary }
        switch currentSignal.direction.lowercased() {
        case "buy":
            return .green
        case "sell":
            return .red
        case "hold":
            return .orange
        default:
            return .secondary
        }
    }
}

struct AIConfidenceCard: View {
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var signalManager: SignalManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("AI Confidence")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Min")
                    Spacer()
                    Text("\(settings.strategyConfidenceMin * 100, specifier: "%.0f")%")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Max")
                    Spacer()
                    Text("\(settings.strategyConfidenceMax * 100, specifier: "%.0f")%")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Current")
                    Spacer()
                    Text("\(signalManager.confidence * 100, specifier: "%.1f")%")
                        .foregroundColor(confidenceColor)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(12)
    }
    
    private var confidenceColor: Color {
        let confidence = signalManager.confidence
        if confidence >= settings.strategyConfidenceMax {
            return .green
        } else if confidence >= settings.strategyConfidenceMin {
            return .orange
        } else {
            return .red
        }
    }
}

struct ActiveOrdersCard: View {
    @EnvironmentObject var tradingManager: TradingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(.blue)
                Text("Active Orders")
                    .font(.headline)
                Spacer()
                Text("\(tradingManager.openPositions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if tradingManager.openPositions.isEmpty {
                Text("No active orders")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(tradingManager.openPositions, id: \.id) { position in
                    HStack {
                        Text(position.pair.symbol)
                            .font(.caption)
                        Spacer()
                        Text("\(position.quantity, specifier: "%.4f")")
                            .font(.caption)
                            .foregroundColor(position.isLong ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemGray6))
        .cornerRadius(12)
    }
}
