import WidgetKit
import SwiftUI
import Charts

// MARK: - Widget Configuration (Simplified)

// MARK: - Widget Configuration Storage

struct WidgetConfiguration: Codable {
    let displayMode: String
    let primarySymbol: String
    let showDemoMode: Bool
    let colorTheme: String
    let updateFrequency: String
    
    static let `default` = WidgetConfiguration(
        displayMode: "balanced",
        primarySymbol: "AUTO",
        showDemoMode: true,
        colorTheme: "standard",
        updateFrequency: "normal"
    )
    

    
    init(displayMode: String, primarySymbol: String, showDemoMode: Bool, colorTheme: String, updateFrequency: String) {
        self.displayMode = displayMode
        self.primarySymbol = primarySymbol
        self.showDemoMode = showDemoMode
        self.colorTheme = colorTheme
        self.updateFrequency = updateFrequency
    }
    
    var updateInterval: TimeInterval {
        switch updateFrequency {
        case "fast": return 60
        case "normal": return 120
        case "slow": return 300
        case "manual": return 3600
        default: return 120
        }
    }
    
    var shouldShowDemoMode: Bool {
        return showDemoMode
    }
    
    var effectiveSymbol: String {
        return primarySymbol == "AUTO" ? "BTC/USDT" : primarySymbol
    }
}



// MARK: - Shared Data Models

struct PnLDataPoint: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
    let percentage: Double
    
    private enum CodingKeys: String, CodingKey {
        case timestamp, value, percentage
    }
}

struct WidgetData: Codable {
    let pnl: Double
    let pnlPercentage: Double
    let todayPnL: Double
    let unrealizedPnL: Double
    let equity: Double
    let openPositions: Int
    let lastPrice: Double
    let priceChange: Double
    let isDemoMode: Bool
    let connectionStatus: String
    let lastUpdated: Date
    let symbol: String
    
    // AI Signal data
    let signalDirection: String?
    let signalConfidence: Double?
    let signalReason: String?
    let signalTimestamp: Date?
    let signalModelName: String?
    
    // P&L Chart data
    let pnlHistory: [PnLDataPoint]?
    
    static let `default` = WidgetData(
        pnl: 0,
        pnlPercentage: 0,
        todayPnL: 0,
        unrealizedPnL: 0,
        equity: 10000,
        openPositions: 0,
        lastPrice: 45000,
        priceChange: 0,
        isDemoMode: true,
        connectionStatus: "disconnected",
        lastUpdated: Date(),
        symbol: "BTC/USDT",
        signalDirection: nil,
        signalConfidence: nil,
        signalReason: nil,
        signalTimestamp: nil,
        signalModelName: nil,
        pnlHistory: nil
    )
}

// MARK: - Widget Entry

struct TradingEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
    let configuration: WidgetConfiguration
    
    init(date: Date, data: WidgetData, configuration: WidgetConfiguration? = nil) {
        self.date = date
        self.data = data
        self.configuration = configuration ?? WidgetDataManager.shared.loadWidgetConfiguration()
    }
    
    var pnl: Double { data.pnl }
    var pnlPercentage: Double { data.pnlPercentage }
    var todayPnL: Double { data.todayPnL }
    var unrealizedPnL: Double { data.unrealizedPnL }
    var equity: Double { data.equity }
    var openPositions: Int { data.openPositions }
    var lastPrice: Double { data.lastPrice }
    var priceChange: Double { data.priceChange }
    var isDemoMode: Bool { data.isDemoMode }
    var symbol: String { 
        // Use configured symbol if not auto, otherwise use data symbol
        configuration.primarySymbol == "AUTO" ? data.symbol : configuration.effectiveSymbol
    }
    
    // Signal properties
    var signalDirection: String? { data.signalDirection }
    var signalConfidence: Double? { data.signalConfidence }
    var signalReason: String? { data.signalReason }
    var signalTimestamp: Date? { data.signalTimestamp }
    var signalModelName: String? { data.signalModelName }
    
    var connectionStatus: ConnectionStatus {
        ConnectionStatus(rawValue: data.connectionStatus) ?? .disconnected
    }
    
    var hasSignal: Bool {
        signalDirection != nil && signalConfidence != nil
    }
    
    var signalColor: Color {
        guard let direction = signalDirection else { return .secondary }
        return colorForDirection(direction, theme: configuration.colorTheme)
    }
    
    var pnlColor: Color {
        return colorForPnL(pnl, theme: configuration.colorTheme)
    }
    
    var todayPnLColor: Color {
        return colorForPnL(todayPnL, theme: configuration.colorTheme)
    }
    
    var unrealizedPnLColor: Color {
        return colorForPnL(unrealizedPnL, theme: configuration.colorTheme)
    }
    
    var priceChangeColor: Color {
        return colorForPnL(priceChange, theme: configuration.colorTheme)
    }
    
    var shouldShowDemoMode: Bool {
        return configuration.shouldShowDemoMode && isDemoMode
    }
    
    private func colorForDirection(_ direction: String, theme: String) -> Color {
        switch direction.uppercased() {
        case "BUY": return positiveColor(for: theme)
        case "SELL": return negativeColor(for: theme)
        case "HOLD": return .secondary
        default: return .secondary
        }
    }
    
    private func colorForPnL(_ value: Double, theme: String) -> Color {
        if value > 0 {
            return positiveColor(for: theme)
        } else if value < 0 {
            return negativeColor(for: theme)
        } else {
            return .secondary
        }
    }
    
    private func positiveColor(for theme: String) -> Color {
        switch theme {
        case "standard": return .green
        case "vibrant": return Color(red: 0.0, green: 0.8, blue: 0.2)
        case "subtle": return Color(red: 0.4, green: 0.7, blue: 0.4)
        case "monochrome": return .primary
        default: return .green
        }
    }
    
    private func negativeColor(for theme: String) -> Color {
        switch theme {
        case "standard": return .red
        case "vibrant": return Color(red: 1.0, green: 0.2, blue: 0.2)
        case "subtle": return Color(red: 0.7, green: 0.4, blue: 0.4)
        case "monochrome": return .secondary
        default: return .red
        }
    }
    
    var signalStrength: String {
        guard let confidence = signalConfidence else { return "Unknown" }
        if confidence >= 0.8 { return "Very Strong" }
        else if confidence >= 0.6 { return "Strong" }
        else if confidence >= 0.4 { return "Moderate" }
        else if confidence >= 0.2 { return "Weak" }
        else { return "Very Weak" }
    }
    
    enum ConnectionStatus: String, CaseIterable {
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

// MARK: - Widget Data Manager
// Using shared WidgetDataManager from main app

// MARK: - Widget Provider

struct TradingProvider: TimelineProvider {
    func placeholder(in context: Context) -> TradingEntry {
        let config = WidgetDataManager.shared.loadWidgetConfiguration()
        
        // Generate sample P&L history data
        let now = Date()
        let sampleHistory = (0..<20).map { i in
            PnLDataPoint(
                timestamp: now.addingTimeInterval(-Double(i * 300)), // 5 minute intervals
                value: 10000 + Double.random(in: -500...1500),
                percentage: Double.random(in: -5.0...15.0)
            )
        }
        
        return TradingEntry(
            date: Date(),
            data: WidgetData(
                pnl: 1250.50,
                pnlPercentage: 2.5,
                todayPnL: 125.30,
                unrealizedPnL: 45.20,
                equity: 11250.50,
                openPositions: 3,
                lastPrice: 45250.75,
                priceChange: 1.2,
                isDemoMode: true,
                connectionStatus: "connected",
                lastUpdated: Date(),
                symbol: config.effectiveSymbol,
                signalDirection: "BUY",
                signalConfidence: 0.75,
                signalReason: "Strong buy signal on 1h",
                signalTimestamp: Date().addingTimeInterval(-300),
                signalModelName: "AI-1h",
                pnlHistory: sampleHistory
            ),
            configuration: config
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TradingEntry) -> Void) {
        let config = WidgetDataManager.shared.loadWidgetConfiguration()
        let data = WidgetDataManager.shared.loadWidgetData()
        let entry = TradingEntry(date: Date(), data: data, configuration: config)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TradingEntry>) -> Void) {
        let config = WidgetDataManager.shared.loadWidgetConfiguration()
        let data = WidgetDataManager.shared.loadWidgetData()
        let entry = TradingEntry(date: Date(), data: data, configuration: config)
        
        // Use configured update frequency, but respect manual mode
        let nextUpdate: Date
        let policy: TimelineReloadPolicy
        
        if config.updateFrequency == "manual" {
            // For manual mode, set a far future date and use .never policy
            nextUpdate = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
            policy = .never
        } else {
            // Use configured interval for automatic updates
            nextUpdate = Date().addingTimeInterval(config.updateInterval)
            policy = .after(nextUpdate)
        }
        
        let timeline = Timeline(entries: [entry], policy: policy)
        completion(timeline)
    }
}



// MARK: - Widget Views

struct TradingWidgetSmallView: View {
    let entry: TradingEntry
    
    var body: some View {
        VStack(spacing: 6) {
            // Header with status and mode
            HStack {
                Text(headerTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    if entry.shouldShowDemoMode {
                        Text("DEMO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    Image(systemName: entry.connectionStatus.icon)
                        .font(.caption2)
                        .foregroundColor(entry.connectionStatus.color)
                }
            }
            
            // Main P&L display
            VStack(spacing: 2) {
                if shouldShowDetailedInfo {
                    HStack {
                        Text("Total")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                HStack {
                    Text(formatCurrency(entry.pnl))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(entry.pnlColor)
                    
                    Spacer()
                    
                    if shouldShowPercentage {
                        Text("\(entry.pnlPercentage >= 0 ? "+" : "")\(entry.pnlPercentage, specifier: "%.1f")%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(entry.pnlColor)
                    }
                }
            }
            
            // Today's P&L (only in balanced/detailed mode)
            if shouldShowTodayPnL {
                HStack {
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatCurrency(entry.todayPnL))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(entry.todayPnLColor)
                }
            }
            
            // Bottom info (only in detailed mode)
            if shouldShowBottomInfo {
                HStack {
                    Text(entry.symbol)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if entry.openPositions > 0 {
                        Text("\(entry.openPositions) pos")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No positions")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var headerTitle: String {
        switch entry.configuration.displayMode {
        case "minimal": return "P&L"
        case "balanced": return "Portfolio"
        case "detailed": return "MyTradeMate"
        default: return "P&L"
        }
    }
    
    private var shouldShowDetailedInfo: Bool {
        entry.configuration.displayMode == "detailed"
    }
    
    private var shouldShowPercentage: Bool {
        entry.configuration.displayMode != "minimal"
    }
    
    private var shouldShowTodayPnL: Bool {
        entry.configuration.displayMode == "balanced" || entry.configuration.displayMode == "detailed"
    }
    
    private var shouldShowBottomInfo: Bool {
        entry.configuration.displayMode == "detailed"
    }
}

struct TradingWidgetMediumView: View {
    let entry: TradingEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with mode indicator
            HStack {
                Text("MyTradeMate")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    if entry.shouldShowDemoMode {
                        Text("DEMO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2))
                            .cornerRadius(6)
                    }
                    
                    Image(systemName: entry.connectionStatus.icon)
                        .font(.caption)
                        .foregroundColor(entry.connectionStatus.color)
                }
            }
            
            HStack(spacing: 16) {
                // Left side - P&L Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Portfolio")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text(formatCurrency(entry.pnl))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(entry.pnlColor)
                            
                            Text("(\(entry.pnlPercentage >= 0 ? "+" : "")\(entry.pnlPercentage, specifier: "%.1f")%)")
                                .font(.caption)
                                .foregroundColor(entry.pnlColor)
                        }
                        
                        HStack {
                            Text("Today:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(formatCurrency(entry.todayPnL))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(entry.todayPnLColor)
                        }
                        
                        HStack {
                            Text("Positions:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("\(entry.openPositions)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Divider()
                
                // Right side - AI Signal Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Signal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    if entry.hasSignal {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .center, spacing: 6) {
                                Image(systemName: signalIcon(for: entry.signalDirection))
                                    .font(.title2)
                                    .foregroundColor(entry.signalColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.signalDirection?.capitalized ?? "Unknown")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(entry.signalColor)
                                    
                                    if let confidence = entry.signalConfidence {
                                        Text("\(Int(confidence * 100))% • \(entry.signalStrength)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            if let reason = entry.signalReason {
                                Text(reason)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            if let timestamp = entry.signalTimestamp {
                                Text(formatSignalTime(timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "brain")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                Text("No Signal")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Analyzing market conditions...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func signalIcon(for direction: String?) -> String {
        guard let direction = direction else { return "brain" }
        switch direction.uppercased() {
        case "BUY": return "arrow.up.circle.fill"
        case "SELL": return "arrow.down.circle.fill"
        case "HOLD": return "pause.circle.fill"
        default: return "brain"
        }
    }
    
    private func formatSignalTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct TradingWidgetLargeView: View {
    let entry: TradingEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with title and status
            headerView
            
            // Main content area with P&L chart
            HStack(spacing: 16) {
                // Left side - P&L metrics
                pnlMetricsView
                
                // Right side - P&L chart
                pnlChartView
            }
            
            // Bottom section with signal and additional info
            bottomInfoView
        }
        .padding()
        .background(.regularMaterial)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("MyTradeMate")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Portfolio Performance")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    if entry.shouldShowDemoMode {
                        Text("DEMO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2))
                            .cornerRadius(6)
                    }
                    
                    Image(systemName: entry.connectionStatus.icon)
                        .font(.caption)
                        .foregroundColor(entry.connectionStatus.color)
                }
                
                Text("Updated \(formatUpdateTime(entry.date))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var pnlMetricsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Total P&L
            VStack(alignment: .leading, spacing: 4) {
                Text("Total P&L")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 6) {
                    Text(formatCurrency(entry.pnl))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(entry.pnlColor)
                    
                    Text("(\(entry.pnlPercentage >= 0 ? "+" : "")\(entry.pnlPercentage, specifier: "%.1f")%)")
                        .font(.subheadline)
                        .foregroundColor(entry.pnlColor)
                }
            }
            
            Divider()
            
            // Breakdown metrics
            VStack(alignment: .leading, spacing: 8) {
                metricRow(title: "Today", value: formatCurrency(entry.todayPnL), 
                         color: entry.todayPnLColor)
                
                metricRow(title: "Unrealized", value: formatCurrency(entry.unrealizedPnL), 
                         color: entry.unrealizedPnLColor)
                
                metricRow(title: "Equity", value: formatCurrency(entry.equity), 
                         color: .primary)
                
                metricRow(title: "Positions", value: "\(entry.openPositions)", 
                         color: .primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var pnlChartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profit % Over Time")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            if let pnlHistory = entry.data.pnlHistory, !pnlHistory.isEmpty {
                Chart(pnlHistory, id: \.id) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("P&L %", point.percentage)
                        )
                        .foregroundStyle(point.percentage >= 0 ? .green : .red)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("P&L %", point.percentage)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    (point.percentage >= 0 ? Color.green : Color.red).opacity(0.3),
                                    (point.percentage >= 0 ? Color.green : Color.red).opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Zero line reference
                    RuleMark(y: .value("Zero", 0))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.3))
                        AxisValueLabel(format: .dateTime.hour().minute())
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.secondary.opacity(0.3))
                        AxisValueLabel {
                            if let percentage = value.as(Double.self) {
                                Text("\(percentage >= 0 ? "+" : "")\(percentage, specifier: "%.1f")%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 120)
            } else {
                // Empty state for chart
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("No Chart Data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Start trading to see performance")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(8)
        .frame(maxWidth: .infinity)
    }
    
    private var bottomInfoView: some View {
        HStack(spacing: 16) {
            // Market info
            VStack(alignment: .leading, spacing: 4) {
                Text("Market")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text(entry.symbol)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(formatCurrency(entry.lastPrice))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text("\(entry.priceChange >= 0 ? "+" : "")\(entry.priceChange, specifier: "%.1f")%")
                        .font(.caption)
                        .foregroundColor(entry.priceChangeColor)
                }
            }
            
            Spacer()
            
            // AI Signal info
            VStack(alignment: .trailing, spacing: 4) {
                Text("AI Signal")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                if entry.hasSignal {
                    HStack(spacing: 6) {
                        Image(systemName: signalIcon(for: entry.signalDirection))
                            .font(.subheadline)
                            .foregroundColor(entry.signalColor)
                        
                        Text(entry.signalDirection?.capitalized ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(entry.signalColor)
                        
                        if let confidence = entry.signalConfidence {
                            Text("\(Int(confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "brain")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("No Signal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func metricRow(title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
    
    private func signalIcon(for direction: String?) -> String {
        guard let direction = direction else { return "brain" }
        switch direction.uppercased() {
        case "BUY": return "arrow.up.circle.fill"
        case "SELL": return "arrow.down.circle.fill"
        case "HOLD": return "pause.circle.fill"
        default: return "brain"
        }
    }
    
    private func formatUpdateTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Widget Configuration

struct TradingWidget: Widget {
    let kind: String = "TradingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TradingProvider()) { entry in
            TradingWidgetView(entry: entry)
        }
        .configurationDisplayName("Trading Metrics")
        .description("View your current P&L, positions, and market data. Configure display options in the MyTradeMate app settings.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
        case .systemLarge:
            TradingWidgetLargeView(entry: entry)
        default:
            TradingWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Interactive Actions (Future Enhancement)
// Interactive actions can be added in future versions using AppIntents framework

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
        data: WidgetData(
            pnl: 1250.50,
            pnlPercentage: 2.5,
            todayPnL: 125.30,
            unrealizedPnL: 45.20,
            equity: 11250.50,
            openPositions: 3,
            lastPrice: 45250.75,
            priceChange: 1.2,
            isDemoMode: true,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT",
            signalDirection: "BUY",
            signalConfidence: 0.75,
            signalReason: "Strong buy signal on 1h",
            signalTimestamp: Date().addingTimeInterval(-300),
            signalModelName: "AI-1h",
            pnlHistory: nil
        ),
        configuration: WidgetConfiguration.default
    )
    
    TradingEntry(
        date: Date().addingTimeInterval(60),
        data: WidgetData(
            pnl: -350.25,
            pnlPercentage: -1.8,
            todayPnL: -75.50,
            unrealizedPnL: -25.30,
            equity: 9649.75,
            openPositions: 1,
            lastPrice: 44890.25,
            priceChange: -0.8,
            isDemoMode: false,
            connectionStatus: "disconnected",
            lastUpdated: Date(),
            symbol: "BTC/USDT",
            signalDirection: "SELL",
            signalConfidence: 0.45,
            signalReason: "Moderate sell signal on 4h",
            signalTimestamp: Date().addingTimeInterval(-600),
            signalModelName: "AI-4h",
            pnlHistory: nil
        ),
        configuration: WidgetConfiguration(
            displayMode: "minimal",
            primarySymbol: "BTC/USDT",
            showDemoMode: false,
            colorTheme: "vibrant",
            updateFrequency: "fast"
        )
    )
}

#Preview(as: .systemMedium) {
    TradingWidget()
} timeline: {
    TradingEntry(
        date: Date(),
        data: WidgetData(
            pnl: 1250.50,
            pnlPercentage: 2.5,
            todayPnL: 125.30,
            unrealizedPnL: 45.20,
            equity: 11250.50,
            openPositions: 3,
            lastPrice: 45250.75,
            priceChange: 1.2,
            isDemoMode: true,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT",
            signalDirection: "BUY",
            signalConfidence: 0.85,
            signalReason: "Very strong buy signal on 1h",
            signalTimestamp: Date().addingTimeInterval(-180),
            signalModelName: "AI-1h",
            pnlHistory: nil
        ),
        configuration: WidgetConfiguration.default
    )
    
    TradingEntry(
        date: Date().addingTimeInterval(60),
        data: WidgetData(
            pnl: -350.25,
            pnlPercentage: -1.8,
            todayPnL: -75.50,
            unrealizedPnL: -25.30,
            equity: 9649.75,
            openPositions: 1,
            lastPrice: 44890.25,
            priceChange: -0.8,
            isDemoMode: false,
            connectionStatus: "error",
            lastUpdated: Date(),
            symbol: "BTC/USDT",
            signalDirection: nil,
            signalConfidence: nil,
            signalReason: nil,
            signalTimestamp: nil,
            signalModelName: nil,
            pnlHistory: nil
        ),
        configuration: WidgetConfiguration(
            displayMode: "detailed",
            primarySymbol: "ETH/USDT",
            showDemoMode: true,
            colorTheme: "subtle",
            updateFrequency: "slow"
        )
    )
}
#Preview(as: .systemLarge) {
    TradingWidget()
} timeline: {
    // Generate sample P&L history for preview
    let now = Date()
    let sampleHistory = (0..<24).map { i in
        let basePercentage = 2.5
        let variation = sin(Double(i) * 0.3) * 3.0 + Double.random(in: -1.0...1.0)
        return PnLDataPoint(
            timestamp: now.addingTimeInterval(-Double(i * 300)), // 5 minute intervals
            value: 10000 + (basePercentage + variation) * 100,
            percentage: basePercentage + variation
        )
    }.reversed()
    
    TradingEntry(
        date: Date(),
        data: WidgetData(
            pnl: 1250.50,
            pnlPercentage: 2.5,
            todayPnL: 125.30,
            unrealizedPnL: 45.20,
            equity: 11250.50,
            openPositions: 3,
            lastPrice: 45250.75,
            priceChange: 1.2,
            isDemoMode: true,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT",
            signalDirection: "BUY",
            signalConfidence: 0.85,
            signalReason: "Very strong buy signal on 1h",
            signalTimestamp: Date().addingTimeInterval(-180),
            signalModelName: "AI-1h",
            pnlHistory: Array(sampleHistory)
        ),
        configuration: WidgetConfiguration.default
    )
    
    // Negative P&L example
    let negativeHistory = (0..<24).map { i in
        let basePercentage = -1.8
        let variation = sin(Double(i) * 0.4) * 2.0 + Double.random(in: -0.5...0.5)
        return PnLDataPoint(
            timestamp: now.addingTimeInterval(-Double(i * 300)),
            value: 10000 + (basePercentage + variation) * 100,
            percentage: basePercentage + variation
        )
    }.reversed()
    
    TradingEntry(
        date: Date().addingTimeInterval(60),
        data: WidgetData(
            pnl: -350.25,
            pnlPercentage: -1.8,
            todayPnL: -75.50,
            unrealizedPnL: -25.30,
            equity: 9649.75,
            openPositions: 1,
            lastPrice: 44890.25,
            priceChange: -0.8,
            isDemoMode: false,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT",
            signalDirection: "SELL",
            signalConfidence: 0.65,
            signalReason: "Strong sell signal on 4h",
            signalTimestamp: Date().addingTimeInterval(-600),
            signalModelName: "AI-4h",
            pnlHistory: Array(negativeHistory)
        ),
        configuration: WidgetConfiguration(
            displayMode: "detailed",
            primarySymbol: "AUTO",
            showDemoMode: false,
            colorTheme: "monochrome",
            updateFrequency: "normal"
        )
    )
}