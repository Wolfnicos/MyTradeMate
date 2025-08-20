import SwiftUI
import Foundation

// MARK: - Debug Data Models

// Using FinalDecision from SignalFusionEngine.swift

// Extension for FinalDecision to add formattedJSON
extension FinalDecision {
    var formattedJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8) ?? "Error encoding JSON"
        } catch {
            return "Error encoding JSON: \(error.localizedDescription)"
        }
    }
}

struct ExchangeAdapterStatus: Identifiable {
    let id = UUID()
    let name: String
    let status: AdapterStatus
    let lastError: String?
    let lastUpdate: Date
    let isConnected: Bool
    
    enum AdapterStatus: String, CaseIterable {
        case connected = "Connected"
        case disconnected = "Disconnected"
        case error = "Error"
        case connecting = "Connecting"
        case unknown = "Unknown"
        
        var color: Color {
            switch self {
            case .connected: return .green
            case .disconnected: return .red
            case .error: return .orange
            case .connecting: return .blue
            case .unknown: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .connected: return "checkmark.circle.fill"
            case .disconnected: return "xmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .connecting: return "arrow.clockwise.circle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }
}

// MARK: - Debug View Model

@MainActor
class DebugViewModel: ObservableObject {
    @Published var lastDecision: FinalDecision?
    @Published var exchangeAdapters: [ExchangeAdapterStatus] = []
    @Published var isLoading = false
    @Published var lastRefreshTime: Date = Date()
    
    private let signalManager = SignalManager.shared
    private let marketDataManager = MarketDataManager.shared
    private let tradingManager = TradingManager.shared
    
    init() {
        loadDebugData()
    }
    
    func loadDebugData() {
        isLoading = true
        
        // Simulate loading time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refreshLastDecision()
            self.refreshExchangeAdapters()
            self.isLoading = false
            self.lastRefreshTime = Date()
        }
    }
    
    func refreshLastDecision() {
        // Create mock decision based on current signal
        if let currentSignal = signalManager.currentSignal {
            let action = Action(rawValue: currentSignal.direction.lowercased()) ?? .hold
            lastDecision = FinalDecision(
                action: action,
                confidence: currentSignal.confidence,
                rationale: "AI ensemble decision based on \(currentSignal.direction)",
                components: [
                    FinalDecision.Component(
                        source: "AI_Model",
                        vote: action,
                        weight: 0.6,
                        score: 0.6
                    ),
                    FinalDecision.Component(
                        source: "RSI_Strategy",
                        vote: action,
                        weight: 0.4,
                        score: 0.4
                    )
                ]
            )
        } else {
            // Mock decision when no signal available
            lastDecision = FinalDecision(
                action: .hold,
                confidence: 0.0,
                rationale: "No active signal available",
                components: []
            )
        }
    }
    
    func refreshExchangeAdapters() {
        // Mock exchange adapter statuses
        exchangeAdapters = [
            ExchangeAdapterStatus(
                name: "Binance Live",
                status: .connected,
                lastError: nil,
                lastUpdate: Date(),
                isConnected: true
            ),
            ExchangeAdapterStatus(
                name: "Kraken Live",
                status: .disconnected,
                lastError: "API key not configured",
                lastUpdate: Date().addingTimeInterval(-3600),
                isConnected: false
            ),
            ExchangeAdapterStatus(
                name: "Paper Trading",
                status: .connected,
                lastError: nil,
                lastUpdate: Date(),
                isConnected: true
            ),
            ExchangeAdapterStatus(
                name: "Demo Mode",
                status: .connected,
                lastError: nil,
                lastUpdate: Date(),
                isConnected: true
            )
        ]
    }
    
    func exportDebugData() -> String {
        var debugInfo = "=== MyTradeMate Debug Report ===\n"
        debugInfo += "Generated: \(Date())\n\n"
        
        if let decision = lastDecision {
            debugInfo += "=== Last Decision ===\n"
            debugInfo += "Action: \(decision.action.rawValue)\n"
            debugInfo += "Confidence: \(String(format: "%.2f", decision.confidence))\n"
            debugInfo += "Rationale: \(decision.rationale)\n"
            debugInfo += "Components: \(decision.components.count) components\n\n"
        }
        
        debugInfo += "=== Exchange Adapters ===\n"
        for adapter in exchangeAdapters {
            debugInfo += "\(adapter.name): \(adapter.status.rawValue)\n"
            if let error = adapter.lastError {
                debugInfo += "  Error: \(error)\n"
            }
            debugInfo += "  Last Update: \(adapter.lastUpdate)\n"
        }
        
        return debugInfo
    }
}

// MARK: - Debug Screen View

struct DebugScreen: View {
    @StateObject private var viewModel = DebugViewModel()
    @State private var showingExportSheet = false
    @State private var showingJSONDetail = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with refresh button
                    headerSection
                    
                    // Last Decision Section
                    if let decision = viewModel.lastDecision {
                        lastDecisionSection(decision)
                    }
                    
                    // Exchange Adapters Section
                    exchangeAdaptersSection
                    
                    // Export Section
                    exportSection
                }
                .padding()
            }
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.loadDebugData()
            }
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(items: [viewModel.exportDebugData()])
            }
            .sheet(isPresented: $showingJSONDetail) {
                if let decision = viewModel.lastDecision {
                    JSONDetailView(decision: decision)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug Console")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Last updated: \(viewModel.lastRefreshTime, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.loadDebugData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.isLoading)
            }
            
            if viewModel.isLoading {
                ProgressView("Loading debug data...")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Last Decision Section
    
    private func lastDecisionSection(_ decision: FinalDecision) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last Final Decision")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View JSON") {
                    showingJSONDetail = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Action:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(decision.action.rawValue.uppercased())
                        .foregroundColor(actionColor(decision.action))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Confidence:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(String(format: "%.1f", decision.confidence * 100))%")
                        .foregroundColor(confidenceColor(decision.confidence))
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Symbol:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("BTC")
                }
                
                HStack {
                    Text("Timeframe:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("5m")
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rationale:")
                        .fontWeight(.medium)
                    Text(decision.rationale)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                if !decision.components.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Components:")
                            .fontWeight(.medium)
                        
                        ForEach(decision.components, id: \.source) { component in
                            HStack {
                                Text(component.source)
                                    .font(.caption)
                                Spacer()
                                Text("\(String(format: "%.2f", component.score))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Exchange Adapters Section
    
    private var exchangeAdaptersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exchange Adapters")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.exchangeAdapters) { adapter in
                    ExchangeAdapterRow(adapter: adapter)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingExportSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Debug Report")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Text("Export includes last decision, exchange status, and system information")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func actionColor(_ action: Action) -> Color {
        switch action {
        case .buy: return .green
        case .sell: return .red
        case .hold: return .orange
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.7 { return .green }
        if confidence >= 0.5 { return .orange }
        return .red
    }
}

// MARK: - Exchange Adapter Row

struct ExchangeAdapterRow: View {
    let adapter: ExchangeAdapterStatus
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: adapter.status.icon)
                .foregroundColor(adapter.status.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(adapter.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(adapter.status.rawValue)
                    .font(.caption)
                    .foregroundColor(adapter.status.color)
                
                if let error = adapter.lastError {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(adapter.lastUpdate, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Circle()
                    .fill(adapter.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - JSON Detail View

struct JSONDetailView: View {
    let decision: FinalDecision
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Final Decision JSON")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(decision.formattedJSON)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("JSON Detail")
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

// MARK: - Share Sheet

// Using existing ShareSheet from the app

// MARK: - Preview

#Preview {
    DebugScreen()
}
