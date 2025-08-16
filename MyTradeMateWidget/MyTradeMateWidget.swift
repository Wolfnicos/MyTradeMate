import WidgetKit
import SwiftUI
import Intents

// MARK: - Widget Entry

struct TradingEntry: TimelineEntry {
    let date: Date
    let pnl: Double
    let pnlPercentage: Double
    let openPositions: Int
    let connectionStatus: ConnectionStatus
    let lastPrice: Double
    let priceChange: Double
    let isDemoMode: Bool
    
    enum ConnectionStatus {
        case connected
        case disconnected
        case error
        
        var color: Color {
            switch self {
            case .connected: return .green
            case .disconnected: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .connected: return "wifi"
            case .disconnected: return "wifi.slash"
            case .error: return "exclamationmark.triangle"
            }
        }
    }
}

// MARK: - Widget Provider

struct TradingProvider: TimelineProvider {
    func placeholder(in context: Context) -> TradingEntry {
        TradingEntry(
            date: Date(),
            pnl: 1250.50,
            pnlPercentage: 2.5,
            openPositions: 3,
            connectionStatus: .connected,
            lastPrice: 45250.75,
            priceChange: 1.2,
            isDemoMode: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TradingEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TradingEntry>) -> Void) {
        Task {
            let entry = await fetchTradingData()
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60))) // Update every minute
            completion(timeline)
        }
    }
    
    private func fetchTradingData() async -> TradingEntry {
        // In a real implementation, this would fetch data from the main app
        // For now, return mock data
        return TradingEntry(
            date: Date(),
            pnl: Double.random(in: -500...2000),
            pnlPercentage: Double.random(in: -5...10),
            openPositions: Int.random(in: 0...5),
            connectionStatus: .connected,
            lastPrice: 45000 + Double.random(in: -1000...1000),
            priceChange: Double.random(in: -5...5),
            isDemoMode: UserDefaults(suiteName: "group.com.mytrademate.app")?.bool(forKey: "demoMode") ?? true
        )
    }
}

// MARK: - Widget Views

struct TradingWidgetSmallView: View {
    let entry: TradingEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("P&L")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(entry.pnl))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(entry.pnl >= 0 ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: entry.connectionStatus.icon)
                        .font(.caption)
                        .foregroundColor(entry.connectionStatus.color)
                    
                    if entry.isDemoMode {
                        Text("DEMO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BTC/USDT")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("$\(entry.lastPrice, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.priceChange >= 0 ? "+" : "")\(entry.priceChange, specifier: "%.1f")%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(entry.priceChange >= 0 ? .green : .red)
                    
                    Text("\(entry.openPositions) pos")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct TradingWidgetMediumView: View {
    let entry: TradingEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - P&L and Status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Portfolio")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if entry.isDemoMode {
                        Text("DEMO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total P&L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(formatCurrency(entry.pnl))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(entry.pnl >= 0 ? .green : .red)
                        
                        Text("(\(entry.pnlPercentage >= 0 ? "+" : "")\(entry.pnlPercentage, specifier: "%.1f")%)")
                            .font(.caption)
                            .foregroundColor(entry.pnl >= 0 ? .green : .red)
                    }
                }
                
                HStack {
                    Label("\(entry.openPositions)", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("Connected", systemImage: entry.connectionStatus.icon)
                        .font(.caption)
                        .foregroundColor(entry.connectionStatus.color)
                }
            }
            
            Divider()
            
            // Right side - Price Info
            VStack(alignment: .leading, spacing: 8) {
                Text("BTC/USDT")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("$\(entry.lastPrice, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("\(entry.priceChange >= 0 ? "+" : "")\(entry.priceChange, specifier: "%.2f")%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(entry.priceChange >= 0 ? .green : .red)
                    
                    Spacer()
                    
                    Text("24h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct TradingWidget: Widget {
    let kind: String = "TradingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TradingProvider()) { entry in
            if #available(iOS 17.0, *) {
                TradingWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TradingWidgetView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Trading Metrics")
        .description("View your current P&L, positions, and market data")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TradingWidgetView: View {
    let entry: TradingEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            TradingWidgetSmallView(entry: entry)
        case .systemMedium:
            TradingWidgetMediumView(entry: entry)
        default:
            TradingWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Interactive Actions (iOS 17+)

@available(iOS 17.0, *)
struct RefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Trading Data"
    static var description = IntentDescription("Refresh your trading metrics and market data")
    
    func perform() async throws -> some IntentResult {
        // Trigger a refresh of the widget data
        WidgetCenter.shared.reloadTimelines(ofKind: "TradingWidget")
        return .result()
    }
}

@available(iOS 17.0, *)
struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open MyTradeMate"
    static var description = IntentDescription("Open the MyTradeMate app")
    
    func perform() async throws -> some IntentResult {
        // This would open the main app
        return .result()
    }
}

// MARK: - Helper Functions

private func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
}

// MARK: - Widget Bundle

@main
struct MyTradeMateWidgets: WidgetBundle {
    var body: some Widget {
        TradingWidget()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TradingWidget()
} timeline: {
    TradingEntry(
        date: Date(),
        pnl: 1250.50,
        pnlPercentage: 2.5,
        openPositions: 3,
        connectionStatus: .connected,
        lastPrice: 45250.75,
        priceChange: 1.2,
        isDemoMode: true
    )
    
    TradingEntry(
        date: Date().addingTimeInterval(60),
        pnl: -350.25,
        pnlPercentage: -1.8,
        openPositions: 1,
        connectionStatus: .disconnected,
        lastPrice: 44890.25,
        priceChange: -0.8,
        isDemoMode: false
    )
}