import SwiftUI
import WidgetKit

struct WidgetConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var configuration: WidgetConfiguration
    @State private var showingPreview = false
    @State private var refreshStats: (lastRefresh: Date?, canRefresh: Bool, status: WidgetRefreshStatus) = (nil, true, .idle)
    
    init() {
        _configuration = State(initialValue: WidgetDataManager.shared.loadWidgetConfiguration())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display Options") {
                    Picker("Display Mode", selection: $configuration.displayMode) {
                        Text("Minimal").tag("minimal")
                        Text("Balanced").tag("balanced")
                        Text("Detailed").tag("detailed")
                    }
                    .pickerStyle(.segmented)
                    
                    Text(displayModeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Symbol Selection") {
                    Picker("Primary Symbol", selection: $configuration.primarySymbol) {
                        Text("Auto (Current)").tag("AUTO")
                        Text("Bitcoin (BTC/USDT)").tag("BTC/USDT")
                        Text("Ethereum (ETH/USDT)").tag("ETH/USDT")
                        Text("Cardano (ADA/USDT)").tag("ADA/USDT")
                        Text("Polkadot (DOT/USDT)").tag("DOT/USDT")
                        Text("Chainlink (LINK/USDT)").tag("LINK/USDT")
                    }
                    
                    Text("Choose which trading symbol to display in the widget. 'Auto' uses your currently active trading symbol.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Appearance") {
                    Toggle("Show Demo Mode Badge", isOn: $configuration.showDemoMode)
                    
                    Text("Display a badge when the app is in demo trading mode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Color Theme", selection: $configuration.colorTheme) {
                        Text("Standard").tag("standard")
                        Text("Vibrant").tag("vibrant")
                        Text("Subtle").tag("subtle")
                        Text("Monochrome").tag("monochrome")
                    }
                    
                    Text(colorThemeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Update Settings") {
                    Picker("Update Frequency", selection: $configuration.updateFrequency) {
                        Text("Fast (1 min)").tag("fast")
                        Text("Normal (2 min)").tag("normal")
                        Text("Slow (5 min)").tag("slow")
                        Text("Manual").tag("manual")
                    }
                    
                    Text(updateFrequencyDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Preview & Control") {
                    Button("Preview Widget") {
                        showingPreview = true
                    }
                    .foregroundColor(.blue)
                    
                    HStack {
                        Button("Refresh Widget Now") {
                            WidgetDataManager.shared.manualRefresh()
                            updateRefreshStats()
                        }
                        .foregroundColor(.green)
                        .disabled(!refreshStats.canRefresh)
                        
                        Spacer()
                        
                        refreshStatusView
                    }
                    
                    if let lastRefresh = refreshStats.lastRefresh {
                        Text("Last refreshed: \(lastRefresh, formatter: refreshDateFormatter)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Preview your widget or manually refresh it with current data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Widget Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveConfiguration()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            WidgetPreviewView(configuration: configuration)
        }
        .onAppear {
            updateRefreshStats()
        }
    }
    
    @ViewBuilder
    private var refreshStatusView: some View {
        switch refreshStats.status {
        case .idle:
            Image(systemName: "clock")
                .foregroundColor(.secondary)
                .font(.caption)
        case .refreshing:
            ProgressView()
                .scaleEffect(0.8)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption)
        }
    }
    
    private var refreshDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    private func updateRefreshStats() {
        refreshStats = WidgetDataManager.shared.getRefreshStats()
    }
    
    private var displayModeDescription: String {
        switch configuration.displayMode {
        case "minimal":
            return "Show only total P&L value"
        case "balanced":
            return "Show P&L and key metrics (recommended)"
        case "detailed":
            return "Show all available information"
        default:
            return ""
        }
    }
    
    private var colorThemeDescription: String {
        switch configuration.colorTheme {
        case "standard":
            return "Green for gains, red for losses"
        case "vibrant":
            return "Bright, high-contrast colors"
        case "subtle":
            return "Muted, softer colors"
        case "monochrome":
            return "Black and white theme"
        default:
            return ""
        }
    }
    
    private var updateFrequencyDescription: String {
        switch configuration.updateFrequency {
        case "fast":
            return "Updates every minute (higher battery usage)"
        case "normal":
            return "Updates every 2 minutes (recommended)"
        case "slow":
            return "Updates every 5 minutes (battery friendly)"
        case "manual":
            return "Only updates when app is opened"
        default:
            return ""
        }
    }
    
    private func saveConfiguration() {
        WidgetDataManager.shared.saveWidgetConfiguration(configuration)
        dismiss()
    }
}

struct WidgetPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let configuration: WidgetConfiguration
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Widget Preview")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("This is how your widget will appear on the home screen with your current settings.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Small Widget Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Small Widget")
                            .font(.headline)
                        
                        WidgetPreviewCard(size: .small, configuration: configuration)
                    }
                    
                    // Medium Widget Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Medium Widget")
                            .font(.headline)
                        
                        WidgetPreviewCard(size: .medium, configuration: configuration)
                    }
                    
                    // Large Widget Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Large Widget")
                            .font(.headline)
                        
                        WidgetPreviewCard(size: .large, configuration: configuration)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Preview")
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

struct WidgetPreviewCard: View {
    enum WidgetSize {
        case small, medium, large
        
        var dimensions: CGSize {
            switch self {
            case .small: return CGSize(width: 155, height: 155)
            case .medium: return CGSize(width: 329, height: 155)
            case .large: return CGSize(width: 329, height: 345)
            }
        }
    }
    
    let size: WidgetSize
    let configuration: WidgetConfiguration
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemGray6))
            .frame(width: size.dimensions.width, height: size.dimensions.height)
            .overlay(
                previewContent
                    .padding(12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
    
    @ViewBuilder
    private var previewContent: some View {
        switch size {
        case .small:
            smallWidgetPreview
        case .medium:
            mediumWidgetPreview
        case .large:
            largeWidgetPreview
        }
    }
    
    private var smallWidgetPreview: some View {
        VStack(spacing: 6) {
            HStack {
                Text(headerTitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if configuration.shouldShowDemoMode {
                    Text("DEMO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.orange.opacity(0.2))
                        .cornerRadius(3)
                }
            }
            
            VStack(spacing: 2) {
                if configuration.displayMode == "detailed" {
                    HStack {
                        Text("Total")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                HStack {
                    Text("$1,250.50")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(positiveColor)
                    
                    Spacer()
                    
                    if configuration.displayMode != "minimal" {
                        Text("+2.5%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(positiveColor)
                    }
                }
            }
            
            if configuration.displayMode == "balanced" || configuration.displayMode == "detailed" {
                HStack {
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("$125.30")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(positiveColor)
                }
            }
            
            if configuration.displayMode == "detailed" {
                HStack {
                    Text(configuration.effectiveSymbol)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("3 pos")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var mediumWidgetPreview: some View {
        VStack(spacing: 12) {
            HStack {
                Text("MyTradeMate")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if configuration.shouldShowDemoMode {
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
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Portfolio")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("$1,250.50")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(positiveColor)
                            
                            Text("(+2.5%)")
                                .font(.caption)
                                .foregroundColor(positiveColor)
                        }
                        
                        HStack {
                            Text("Today:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("$125.30")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(positiveColor)
                        }
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Signal")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(positiveColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Buy")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(positiveColor)
                            
                            Text("75% • Strong")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var largeWidgetPreview: some View {
        VStack(spacing: 16) {
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
                
                if configuration.shouldShowDemoMode {
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
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total P&L")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .bottom, spacing: 6) {
                            Text("$1,250.50")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(positiveColor)
                            
                            Text("(+2.5%)")
                                .font(.subheadline)
                                .foregroundColor(positiveColor)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$125.30")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(positiveColor)
                        }
                        
                        HStack {
                            Text("Positions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("3")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Profit % Over Time")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .overlay(
                            Text("Chart Preview")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Market")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Text(configuration.effectiveSymbol)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("$45,250.75")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("AI Signal")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(positiveColor)
                        
                        Text("Buy")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(positiveColor)
                        
                        Text("75%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var headerTitle: String {
        switch configuration.displayMode {
        case "minimal": return "P&L"
        case "balanced": return "Portfolio"
        case "detailed": return "MyTradeMate"
        default: return "P&L"
        }
    }
    
    private var positiveColor: Color {
        switch configuration.colorTheme {
        case "standard": return .green
        case "vibrant": return Color(red: 0.0, green: 0.8, blue: 0.2)
        case "subtle": return Color(red: 0.4, green: 0.7, blue: 0.4)
        case "monochrome": return .primary
        default: return .green
        }
    }
}

#Preview {
    WidgetConfigurationView()
}