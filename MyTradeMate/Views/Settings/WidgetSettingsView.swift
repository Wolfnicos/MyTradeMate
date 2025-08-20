import SwiftUI

/// Widget configuration view with live preview
/// Provides display style, symbol selection, and refresh controls
struct WidgetSettingsView: View {
    @StateObject private var widgetStore = WidgetSettingsStore.shared
    @State private var showingSymbolPicker = false
    
    var body: some View {
        List {
            // Widget Preview Section
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Preview")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Refresh now") {
                            Task {
                                await widgetStore.refreshData()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .disabled(widgetStore.isRefreshing)
                    }
                    
                    // Live widget preview
                    WidgetPreview(
                        style: widgetStore.displayStyle,
                        symbol: widgetStore.primarySymbol,
                        isRefreshing: widgetStore.isRefreshing
                    )
                    
                    // Last refresh info
                    if let lastRefresh = widgetStore.lastRefreshed {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Last refreshed: \(timeFormatter.string(from: lastRefresh))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if widgetStore.isRefreshing {
                                ProgressView()
                                    .scaleEffect(0.6)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Display Style Section
            Section("Display Style") {
                ForEach(WidgetDisplayStyle.allCases, id: \.self) { style in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(style.title)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text(style.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if widgetStore.displayStyle == style {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        widgetStore.setDisplayStyle(style)
                    }
                }
            }
            
            // Primary Symbol Section
            Section("Primary Symbol") {
                Button(action: { showingSymbolPicker = true }) {
                    HStack {
                        Text("Trading Pair")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(PairFormatter.shared.format(widgetStore.primarySymbol.displayName).displayString)
                            .foregroundColor(.secondary)
                            .tradingPairGuard()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.tertiary)
                    }
                }
            }
            
            // Update Frequency Section
            Section("Update Frequency") {
                ForEach(WidgetUpdateFrequency.allCases, id: \.self) { frequency in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(frequency.title)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text(frequency.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if widgetStore.updateFrequency == frequency {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        widgetStore.setUpdateFrequency(frequency)
                    }
                }
            }
            
            // Widget Management Section
            Section("Widget Management") {
                NavigationLink("Add to Home Screen") {
                    WidgetInstallationGuide()
                }
                
                Button("Reset to Default") {
                    widgetStore.resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Widget")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSymbolPicker) {
            SymbolPickerView(
                selectedSymbol: $widgetStore.primarySymbol,
                onDismiss: { showingSymbolPicker = false }
            )
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }
}

// MARK: - Widget Display Styles

enum WidgetDisplayStyle: String, CaseIterable, Codable {
    case minimal = "minimal"
    case balanced = "balanced"
    case detailed = "detailed"
    
    var title: String {
        switch self {
        case .minimal: return "Minimal"
        case .balanced: return "Balanced"
        case .detailed: return "Detailed"
        }
    }
    
    var description: String {
        switch self {
        case .minimal: return "Price and change only"
        case .balanced: return "Price, change, and key metrics"
        case .detailed: return "Full information with AI status"
        }
    }
}

// MARK: - Widget Update Frequencies

enum WidgetUpdateFrequency: String, CaseIterable, Codable {
    case manual = "manual"
    case minutes5 = "5m"
    case minutes15 = "15m" 
    case hour1 = "1h"
    
    var title: String {
        switch self {
        case .manual: return "Manual"
        case .minutes5: return "5 minutes"
        case .minutes15: return "15 minutes"
        case .hour1: return "1 hour"
        }
    }
    
    var description: String {
        switch self {
        case .manual: return "Update only when opened"
        case .minutes5: return "Automatic updates every 5 minutes"
        case .minutes15: return "Automatic updates every 15 minutes"
        case .hour1: return "Automatic updates every hour"
        }
    }
    
    var timeInterval: TimeInterval? {
        switch self {
        case .manual: return nil
        case .minutes5: return 5 * 60
        case .minutes15: return 15 * 60
        case .hour1: return 60 * 60
        }
    }
}

// MARK: - Trading Symbol Model

struct TradingSymbol: Codable, Equatable, Identifiable {
    let id = UUID()
    let base: String
    let quote: String
    
    var displayName: String {
        return "\(base)/\(quote)"
    }
    
    var pair: String {
        return "\(base)\(quote)"
    }
    
    // Common trading pairs
    static let btcUSD = TradingSymbol(base: "BTC", quote: "USD")
    static let btcUSDT = TradingSymbol(base: "BTC", quote: "USDT")
    static let ethUSD = TradingSymbol(base: "ETH", quote: "USD")
    static let ethUSDT = TradingSymbol(base: "ETH", quote: "USDT")
    static let ethEUR = TradingSymbol(base: "ETH", quote: "EUR")
    
    static let popular = [btcUSD, btcUSDT, ethUSD, ethUSDT, ethEUR]
}

// MARK: - Widget Settings Store

@MainActor
final class WidgetSettingsStore: ObservableObject {
    static let shared = WidgetSettingsStore()
    
    @Published var displayStyle: WidgetDisplayStyle = .balanced
    @Published var primarySymbol: TradingSymbol = .btcUSD
    @Published var updateFrequency: WidgetUpdateFrequency = .minutes15
    @Published var lastRefreshed: Date?
    @Published var isRefreshing: Bool = false
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadSettings()
    }
    
    func setDisplayStyle(_ style: WidgetDisplayStyle) {
        displayStyle = style
        saveSettings()
    }
    
    func setUpdateFrequency(_ frequency: WidgetUpdateFrequency) {
        updateFrequency = frequency
        saveSettings()
    }
    
    func refreshData() async {
        isRefreshing = true
        
        // Simulate data refresh
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
        
        lastRefreshed = Date()
        isRefreshing = false
        
        saveSettings()
    }
    
    func resetToDefaults() {
        displayStyle = .balanced
        primarySymbol = .btcUSD
        updateFrequency = .minutes15
        lastRefreshed = nil
        
        saveSettings()
    }
    
    private func loadSettings() {
        if let styleData = userDefaults.data(forKey: "widgetDisplayStyle"),
           let style = try? JSONDecoder().decode(WidgetDisplayStyle.self, from: styleData) {
            displayStyle = style
        }
        
        if let symbolData = userDefaults.data(forKey: "widgetPrimarySymbol"),
           let symbol = try? JSONDecoder().decode(TradingSymbol.self, from: symbolData) {
            primarySymbol = symbol
        }
        
        if let frequencyData = userDefaults.data(forKey: "widgetUpdateFrequency"),
           let frequency = try? JSONDecoder().decode(WidgetUpdateFrequency.self, from: frequencyData) {
            updateFrequency = frequency
        }
        
        lastRefreshed = userDefaults.object(forKey: "widgetLastRefreshed") as? Date
    }
    
    private func saveSettings() {
        if let styleData = try? JSONEncoder().encode(displayStyle) {
            userDefaults.set(styleData, forKey: "widgetDisplayStyle")
        }
        
        if let symbolData = try? JSONEncoder().encode(primarySymbol) {
            userDefaults.set(symbolData, forKey: "widgetPrimarySymbol")
        }
        
        if let frequencyData = try? JSONEncoder().encode(updateFrequency) {
            userDefaults.set(frequencyData, forKey: "widgetUpdateFrequency")
        }
        
        userDefaults.set(lastRefreshed, forKey: "widgetLastRefreshed")
    }
}

// MARK: - Symbol Picker

struct SymbolPickerView: View {
    @Binding var selectedSymbol: TradingSymbol
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            List(TradingSymbol.popular) { symbol in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(PairFormatter.shared.format(symbol.displayName).displayString)
                            .font(.headline)
                            .tradingPairGuard()
                        
                        Text(PairFormatter.shared.format(symbol.displayName, style: .baseOnly).displayString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if selectedSymbol == symbol {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSymbol = symbol
                    onDismiss()
                }
            }
            .navigationTitle("Select Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Widget Preview Component

/// Widget preview component that mirrors Dashboard styling/formatting
struct WidgetPreview: View {
    let style: WidgetDisplayStyle
    let symbol: TradingSymbol
    let isRefreshing: Bool
    
    @StateObject private var aiStatusStore = AIStatusStore.shared
    @StateObject private var marketDataManager = MarketDataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Preview label
            HStack {
                Text("Widget Preview")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(style.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Widget preview content based on style
            widgetContent
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var widgetContent: some View {
        switch style {
        case .minimal:
            minimalWidgetView
        case .balanced:
            balancedWidgetView
        case .detailed:
            detailedWidgetView
        }
    }
    
    private var minimalWidgetView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(PairFormatter.shared.format(symbol.displayName).displayString)
                    .font(.headline)
                    .fontWeight(.bold)
                    .tradingPairGuard()
                
                if isRefreshing {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 16)
                        .cornerRadius(4)
                        .shimmer()
                } else {
                    Text(MoneyFormatter.shared.format(value: 43256.78, currency: "USD").displayString)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .moneyValueGuard()
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(MoneyFormatter.shared.formatPercentageChange(2.34).displayString)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(MoneyFormatter.shared.formatPercentageChange(2.34).semanticColor)
                    .percentageGuard()
                
                Text(MoneyFormatter.shared.formatChange(987.45, currency: "USD").displayString)
                    .font(.caption)
                    .foregroundColor(MoneyFormatter.shared.formatChange(987.45, currency: "USD").semanticColor)
            }
        }
    }
    
    private var balancedWidgetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(PairFormatter.shared.format(symbol.displayName).displayString)
                        .font(.headline)
                        .fontWeight(.bold)
                        .tradingPairGuard()
                    
                    if isRefreshing {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 20)
                            .cornerRadius(4)
                            .shimmer()
                    } else {
                        Text(MoneyFormatter.shared.format(value: 43256.78, currency: "USD").displayString)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .moneyValueGuard()
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(MoneyFormatter.shared.formatPercentageChange(2.34).displayString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(MoneyFormatter.shared.formatPercentageChange(2.34).semanticColor)
                        .percentageGuard()
                    
                    Text(MoneyFormatter.shared.formatChange(987.45, currency: "USD").displayString)
                        .font(.caption)
                        .foregroundColor(MoneyFormatter.shared.formatChange(987.45, currency: "USD").semanticColor)
                }
            }
            
            // Key metrics
            HStack(spacing: 16) {
                MetricColumn(title: "24h High", value: MoneyFormatter.shared.format(value: 44123, currency: "USD", style: .compact).displayString, isRefreshing: isRefreshing)
                MetricColumn(title: "24h Low", value: MoneyFormatter.shared.format(value: 42011, currency: "USD", style: .compact).displayString, isRefreshing: isRefreshing)
                MetricColumn(title: "Volume", value: MoneyFormatter.shared.format(value: 2400000000, currency: "USD", style: .compact).displayString, isRefreshing: isRefreshing)
            }
        }
    }
    
    private var detailedWidgetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with AI status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(PairFormatter.shared.format(symbol.displayName).displayString)
                        .font(.headline)
                        .fontWeight(.bold)
                        .tradingPairGuard()
                    
                    if isRefreshing {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 20)
                            .cornerRadius(4)
                            .shimmer()
                    } else {
                        Text(MoneyFormatter.shared.format(value: 43256.78, currency: "USD").displayString)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .moneyValueGuard()
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        AIStatusIndicator(
                            status: aiStatusStore.status,
                            size: .small
                        )
                        
                        if let confidence = aiStatusStore.status.state.confidence {
                            Text("\(Int(confidence * 100))%")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(MoneyFormatter.shared.formatPercentageChange(2.34).displayString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(MoneyFormatter.shared.formatPercentageChange(2.34).semanticColor)
                        .percentageGuard()
                    
                    Text(MoneyFormatter.shared.formatChange(987.45, currency: "USD").displayString)
                        .font(.caption)
                        .foregroundColor(MoneyFormatter.shared.formatChange(987.45, currency: "USD").semanticColor)
                }
            }
            
            // Metrics grid
            HStack(spacing: 12) {
                MetricColumn(title: "24h High", value: MoneyFormatter.shared.format(value: 44123, currency: "USD", style: .compact).displayString, isRefreshing: isRefreshing)
                MetricColumn(title: "24h Low", value: MoneyFormatter.shared.format(value: 42011, currency: "USD", style: .compact).displayString, isRefreshing: isRefreshing)
                MetricColumn(title: "Volume", value: MoneyFormatter.shared.format(value: 2400000000, currency: "USD", style: .compact).displayString, isRefreshing: isRefreshing)
            }
            
            // AI Signal
            HStack {
                Text("AI Signal:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if isRefreshing {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 12)
                        .cornerRadius(4)
                        .shimmer()
                } else {
                    Text("Strong Buy")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
        }
    }
}

struct MetricColumn: View {
    let title: String
    let value: String
    let isRefreshing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.tertiary)
            
            if isRefreshing {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 12)
                    .cornerRadius(4)
                    .shimmer()
            } else {
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .moneyValueGuard()
            }
        }
    }
}

// MARK: - Widget Installation Guide

struct WidgetInstallationGuide: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Widget to Home Screen")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Follow these steps to add the MyTradeMate widget to your home screen for quick market updates.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Steps
                    VStack(alignment: .leading, spacing: 20) {
                        InstallationStep(
                            number: 1,
                            title: "Enter Jiggle Mode",
                            description: "Long press on your home screen until apps start wiggling",
                            icon: "hand.tap"
                        )
                        
                        InstallationStep(
                            number: 2,
                            title: "Tap the + Button",
                            description: "Look for the + button in the top-left corner and tap it",
                            icon: "plus.circle"
                        )
                        
                        InstallationStep(
                            number: 3,
                            title: "Find MyTradeMate",
                            description: "Search for 'MyTradeMate' in the widget gallery",
                            icon: "magnifyingglass"
                        )
                        
                        InstallationStep(
                            number: 4,
                            title: "Choose Widget Size",
                            description: "Select your preferred widget size (Small, Medium, or Large)",
                            icon: "rectangle.3.group"
                        )
                        
                        InstallationStep(
                            number: 5,
                            title: "Add Widget",
                            description: "Tap 'Add Widget' and position it on your home screen",
                            icon: "checkmark.circle"
                        )
                    }
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tips")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            TipRow(
                                icon: "lightbulb",
                                tip: "Configure your widget settings here first for the best experience"
                            )
                            
                            TipRow(
                                icon: "arrow.clockwise",
                                tip: "Widgets update automatically based on your frequency settings"
                            )
                            
                            TipRow(
                                icon: "hand.tap",
                                tip: "Tap the widget to open MyTradeMate directly to your dashboard"
                            )
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Widget Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InstallationStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.orange)
                .frame(width: 20)
            
            Text(tip)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Widget Settings") {
    NavigationView {
        WidgetSettingsView()
    }
}

#Preview("Widget Preview - Minimal") {
    WidgetPreview(
        style: .minimal,
        symbol: .btcUSD,
        isRefreshing: false
    )
    .padding()
}

#Preview("Widget Preview - Detailed") {
    WidgetPreview(
        style: .detailed,
        symbol: .btcUSD,
        isRefreshing: true
    )
    .padding()
}

#Preview("Installation Guide") {
    WidgetInstallationGuide()
}