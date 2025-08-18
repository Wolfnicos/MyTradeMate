import SwiftUI

// MARK: - Settings Toggle Styles (using standardized components from DesignSystem)

// MARK: - Design System Extensions (Deprecated - use Typography from DesignSystem)
@available(*, deprecated, message: "Use Typography from DesignSystem instead")
extension Font {
    static let settingsTitle = Typography.title2
    static let settingsHeadline = Typography.headline
    static let settingsBody = Typography.body
    static let settingsCaption = Typography.caption1Medium
    static let settingsFootnote = Typography.footnote
}

@available(*, deprecated, message: "Use TextColor from DesignSystem instead")
extension Color {
    static let settingsPrimary = Color.primary
    static let settingsSecondary = Color.secondary
    static let settingsTertiary = Color(.tertiaryLabel)
    static let settingsBackground = Color(.systemBackground)
    static let settingsGroupedBackground = Color(.systemGroupedBackground)
    static let settingsSecondaryBackground = Color(.secondarySystemBackground)
}

// Using Spacing from DesignSystem.swift

/// A reusable help icon component that displays a tooltip when tapped
struct HelpIconView: View {
    let helpText: String
    @State private var showTooltip = false
    
    var body: some View {
        Button(action: {
            showTooltip.toggle()
        }) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.settingsSecondary)
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $showTooltip, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(helpText)
                    .bodyStyle()
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Spacing.md)
            .frame(maxWidth: 280)
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel("Help")
        .accessibilityHint("Tap to show help information")
    }
}

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var settingsRepo = SettingsRepository.shared
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var toastManager: ToastManager
    @State private var searchText = ""
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportedLogURL: URL?
    @State private var showWidgetConfiguration = false
    @State private var widgetRefreshStats: (lastRefresh: Date?, canRefresh: Bool, status: WidgetRefreshStatus) = (nil, true, .idle)
    
    // MARK: - Computed Properties
    private var filteredSections: [SettingsSection] {
        let allSections = [tradingSection, interfaceSection, securitySection, diagnosticsSection]
        
        if searchText.isEmpty {
            return allSections
        }
        
        return allSections.compactMap { section in
            let filteredItems = section.items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText) ||
                section.title.localizedCaseInsensitiveContains(searchText)
            }
            
            if !filteredItems.isEmpty {
                return SettingsSection(
                    title: section.title,
                    icon: section.icon,
                    footer: section.footer,
                    items: filteredItems
                )
            }
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredSections, id: \.title) { section in
                    Section {
                        ForEach(section.items, id: \.title) { item in
                            SettingsRowView(item: item)
                        }
                    } header: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: section.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.accentColor)
                                .frame(width: 20)
                            
                            Text(section.title)
                                .font(.settingsHeadline)
                                .foregroundColor(.settingsPrimary)
                        }
                        .padding(.top, Spacing.xs)
                    } footer: {
                        if !section.footer.isEmpty {
                            Text(section.footer)
                                .font(.settingsFootnote)
                                .foregroundColor(.settingsTertiary)
                                .padding(.horizontal, Spacing.xs)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search settings...")
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(settings.darkMode ? .dark : .light)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedLogURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showWidgetConfiguration) {
            WidgetConfigurationView()
        }
        .onAppear {
            updateWidgetRefreshStats()
        }
    }
    
    // MARK: - Settings Sections
    private var tradingSection: SettingsSection {
        SettingsSection(
            title: "Trading",
            icon: "chart.line.uptrend.xyaxis",
            footer: "Configure trading behavior, market data sources, and strategy settings. Demo Mode is recommended for new users to test strategies safely.",
            items: [
                SettingsItem(
                    title: "Current Mode",
                    description: "Trading mode indicator",
                    view: AnyView(currentModeView)
                ),
                SettingsItem(
                    title: "Demo Mode",
                    description: "Use simulated trading environment for testing strategies without real money. All trades will be virtual.",
                    view: AnyView(
                        SettingsToggleRow(
                            title: "Demo Mode",
                            description: "Use simulated trading environment for testing strategies without real money. All trades will be virtual.",
                            helpText: "Demo Mode creates a completely simulated trading environment where you can test strategies without any risk. All trades are virtual and no real money is involved. This is perfect for learning and testing new strategies.",
                            isOn: $settings.demoMode,
                            style: .warning
                        )
                    )
                ),
                SettingsItem(
                    title: "Auto Trading",
                    description: "Allow AI strategies to automatically place trades when conditions are met. Requires valid API keys and live mode.",
                    view: AnyView(
                        SettingsToggleRow(
                            title: "Auto Trading",
                            description: "Allow AI strategies to automatically place trades when conditions are met. Requires valid API keys and live mode.",
                            helpText: "Auto Trading allows the AI to execute trades automatically based on strategy signals. This requires:\n\n• Valid exchange API keys\n• Live trading mode enabled\n• Sufficient account balance\n\nThe AI will place buy/sell orders when conditions are met. Always monitor your positions when auto trading is enabled.",
                            isOn: $settings.autoTrading,
                            style: .success
                        )
                    )
                ),
                SettingsItem(
                    title: "Confirm Trades",
                    description: "Show confirmation dialog before placing any trade. Recommended for beginners and live trading.",
                    view: AnyView(
                        SettingsToggleRow(
                            title: "Confirm Trades",
                            description: "Show confirmation dialog before placing any trade. Recommended for beginners and live trading.",
                            isOn: $settings.confirmTrades
                        )
                    )
                ),
                SettingsItem(
                    title: "Paper Trading",
                    description: "Simulate trades with real market data but without actual money. Disabled when Demo Mode is active.",
                    view: AnyView(
                        SettingsToggleRow(
                            title: "Paper Trading",
                            description: "Simulate trades with real market data but without actual money. Disabled when Demo Mode is active.",
                            helpText: "Paper Trading simulates real trades using live market data without risking actual money. Unlike Demo Mode, it uses real-time prices and market conditions.\n\nKey differences:\n• Uses live market data\n• Simulates real order execution\n• Tracks realistic performance\n• Disabled when Demo Mode is active",
                            isOn: $settings.paperTrading,
                            style: .prominent,
                            isDisabled: settings.demoMode
                        )
                    )
                ),
                SettingsItem(
                    title: "Live Market Data",
                    description: "Connect to real-time exchange data feeds. Disable to use cached data and reduce API usage.",
                    view: AnyView(
                        SettingsToggleRow(
                            title: "Live Market Data",
                            description: "Connect to real-time exchange data feeds. Disable to use cached data and reduce API usage.",
                            helpText: "Live Market Data connects to real-time exchange feeds for the most current prices and market information.\n\nWhen enabled:\n• Real-time price updates\n• Current market conditions\n• Higher API usage\n\nWhen disabled:\n• Uses cached/historical data\n• Reduced API calls\n• May affect trading accuracy",
                            isOn: $settings.liveMarketData,
                            style: .default
                        )
                    )
                ),
                SettingsItem(
                    title: "Trading Pairs",
                    description: "Manage available trading pairs and set defaults. Now includes DOGE, SOL, and AVAX.",
                    view: AnyView(
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text("Available Trading Pairs")
                                    .font(.settingsBody)
                                    .fontWeight(.medium)
                                    .foregroundColor(.settingsPrimary)
                                
                                Spacer()
                                
                                Text("\(TradingPair.popular.count) pairs")
                                    .font(.settingsCaption)
                                    .foregroundColor(.settingsSecondary)
                            }
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: Spacing.xs) {
                                ForEach(TradingPair.popular, id: \.symbol) { pair in
                                    HStack(spacing: Spacing.xs) {
                                        Text(pair.baseSymbol)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Text("/")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                        
                                        Text(pair.quoteSymbol)
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, Spacing.xs)
                                    .padding(.vertical, 2)
                                    .background(Color(.quaternarySystemFill))
                                    .cornerRadius(4)
                                }
                            }
                        }
                        .padding(.vertical, Spacing.xs)
                    )
                ),
                SettingsItem(
                    title: "Timeframe Support", 
                    description: "Now supports 1m, 5m, 15m, 1h, and 4h timeframes for comprehensive market analysis",
                    view: AnyView(
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text("Available Timeframes")
                                    .font(.settingsBody)
                                    .fontWeight(.medium)
                                    .foregroundColor(.settingsPrimary)
                                
                                Spacer()
                                
                                Text("\(Timeframe.allCases.count) timeframes")
                                    .font(.settingsCaption)
                                    .foregroundColor(.settingsSecondary)
                            }
                            
                            HStack(spacing: Spacing.sm) {
                                ForEach(Timeframe.allCases, id: \.rawValue) { timeframe in
                                    Text(timeframe.displayName)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, Spacing.sm)
                                        .padding(.vertical, 4)
                                        .background(Color(.quaternarySystemFill))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.vertical, Spacing.xs)
                    )
                ),
                SettingsItem(
                    title: "Strategy Configuration",
                    description: "Configure and manage trading strategies with detailed information",
                    view: AnyView(
                        SettingsNavigationRow(
                            title: "Strategy Configuration",
                            description: "Configure and manage trading strategies with detailed information",
                            destination: AnyView(StrategyConfigurationView())
                        )
                    )
                ),
                SettingsItem(
                    title: "Routing & Confidence",
                    description: "Configure per-timeframe routing and confidence controls for AI vs Strategy systems",
                    view: AnyView(
                        SettingsNavigationRow(
                            title: "Routing & Confidence",
                            description: "Configure per-timeframe routing and confidence controls for AI vs Strategy systems",
                            destination: AnyView(routingConfidenceView)
                        )
                    )
                ),
                SettingsItem(
                    title: "Reset Paper Account",
                    description: "Reset paper trading account to initial state with default balance",
                    view: AnyView(
                        SettingsButtonRow(
                            title: "Reset Paper Account",
                            description: "Reset paper trading account to $10,000 and clear all trades and positions",
                            action: {
                                Task {
                                    await settingsRepo.resetPaperAccount()
                                    toastManager.showSuccess("Paper account reset to $10,000")
                                }
                            },
                            style: .destructive
                        )
                    )
                )
            ]
        )
    }
    
    private var interfaceSection: SettingsSection {
        SettingsSection(
            title: "Interface",
            icon: "rectangle.3.group",
            footer: "Customize the app interface and widget appearance to match your preferences.",
            items: [
                SettingsItem(
                    title: "Widget Configuration",
                    description: "Customize your home screen widget display options, colors, and update frequency",
                    view: AnyView(
                        Button(action: {
                            showWidgetConfiguration = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Widget Configuration")
                                        .font(Typography.body)
                                        .foregroundColor(.primary)
                                    
                                    Text("Customize your home screen widget display options, colors, and update frequency")
                                        .font(Typography.caption1)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    if let lastRefresh = widgetRefreshStats.lastRefresh {
                                        Text("Last updated: \(lastRefresh, formatter: widgetRefreshDateFormatter)")
                                            .font(Typography.caption2)
                                            .foregroundColor(.tertiary)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    widgetRefreshStatusIcon
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    )
                )
            ]
        )
    }
    
    private var securitySection: SettingsSection {
        SettingsSection(
            title: "Security",
            icon: "key",
            footer: "Manage exchange API credentials and app security settings. API keys are required for live trading and real-time data.",
            items: [
                SettingsItem(
                    title: "Manage API Keys",
                    description: "Configure exchange API credentials for live trading. Keys are stored securely in Keychain.",
                    view: AnyView(
                        SettingsButtonRow(
                            title: "Manage API Keys",
                            description: "Configure exchange API credentials for live trading. Keys are stored securely in Keychain.",
                            action: {
                                navigationCoordinator.navigate(to: .exchangeKeys, in: .settings)
                            },
                            style: .primary
                        )
                    )
                ),
                SettingsItem(
                    title: "Binance Configuration",
                    description: "Set up Binance API keys for trading and market data access.",
                    view: AnyView(
                        SettingsNavigationRow(
                            title: "Binance Configuration",
                            description: "Set up Binance API keys for trading and market data access.",
                            destination: AnyView(
                                BinanceKeysView()
                                    .navigationTitle("Binance Configuration")
                                    .navigationBarTitleDisplayMode(.inline)
                            )
                        )
                    )
                ),
                SettingsItem(
                    title: "Kraken Configuration",
                    description: "Set up Kraken API keys for trading and market data access.",
                    view: AnyView(
                        SettingsNavigationRow(
                            title: "Kraken Configuration",
                            description: "Set up Kraken API keys for trading and market data access.",
                            destination: AnyView(
                                KrakenKeysView()
                                    .navigationTitle("Kraken Configuration")
                                    .navigationBarTitleDisplayMode(.inline)
                            )
                        )
                    )
                ),
                SettingsItem(
                    title: "Dark Mode",
                    description: "Use dark color scheme throughout the app. Follows system setting when disabled.",
                    view: AnyView(
                        SettingsToggleRow(
                            title: "Dark Mode",
                            description: "Use dark color scheme throughout the app. Follows system setting when disabled.",
                            isOn: $settings.darkMode,
                            style: .minimal
                        )
                    )
                ),
                SettingsItem(
                    title: "Haptic Feedback",
                    description: "Enable tactile feedback for button presses, trade confirmations, and other interactions.",
                    view: AnyView(
                        SettingsToggleRow(
                            title: "Haptic Feedback",
                            description: "Enable tactile feedback for button presses, trade confirmations, and other interactions.",
                            isOn: $settings.haptics,
                            style: .default
                        )
                    )
                )
            ]
        )
    }
    
    private var diagnosticsSection: SettingsSection {
        SettingsSection(
            title: "Diagnostics",
            icon: "stethoscope",
            footer: "Debug settings, system information, and diagnostic tools for troubleshooting. Enable verbose logging only when needed as it may impact performance.",
            items: [
                SettingsItem(
                    title: "App Version",
                    description: "Current app version",
                    view: AnyView(
                        SettingsInfoRow(title: "App Version", value: Bundle.main.appVersion)
                    )
                ),
                SettingsItem(
                    title: "Build Number",
                    description: "Current build number",
                    view: AnyView(
                        SettingsInfoRow(title: "Build Number", value: Bundle.main.buildNumber)
                    )
                ),
                SettingsItem(
                    title: "AI Debug Mode",
                    description: "Enable additional AI diagnostics and debugging information. May impact performance.",
                    view: AnyView(
                        SettingsToggleRow(
                            title: "AI Debug Mode",
                            description: "Enable additional AI diagnostics and debugging information. May impact performance.",
                            helpText: "AI Debug Mode provides detailed information about AI decision-making processes:\n\n• Model input/output data\n• Confidence scores\n• Processing times\n• Strategy reasoning\n\nWarning: This may impact app performance and should only be enabled when troubleshooting AI behavior.",
                            isOn: $settings.aiDebugMode,
                            style: .warning
                        )
                    )
                ),
                SettingsItem(
                    title: "Verbose AI Logs",
                    description: "Show detailed AI processing logs including model inputs, outputs, and decision reasoning.",
                    view: AnyView(
                        SettingsToggleRow(
                            title: "Verbose AI Logs",
                            description: "Show detailed AI processing logs including model inputs, outputs, and decision reasoning.",
                            helpText: "Verbose AI Logs capture extensive details about AI processing:\n\n• Raw market data inputs\n• Feature calculations\n• Model predictions\n• Decision trees\n• Execution timing\n\nThis generates large log files and may significantly impact performance. Only enable for detailed troubleshooting.",
                            isOn: $settings.verboseAILogs,
                            style: .danger
                        )
                    )
                ),
                SettingsItem(
                    title: "PnL Demo Mode",
                    description: "Use synthetic profit/loss data for testing charts and calculations without real trading history.",
                    view: AnyView(
                        SettingsToggleRow(
                            title: "PnL Demo Mode",
                            description: "Use synthetic profit/loss data for testing charts and calculations without real trading history.",
                            isOn: $settings.pnlDemoMode,
                            style: .minimal
                        )
                    )
                ),
                SettingsItem(
                    title: "Export Logs",
                    description: "Export diagnostic logs for troubleshooting",
                    view: AnyView(
                        SettingsExportButtonRow(
                            title: "Export Logs",
                            description: "Export diagnostic logs for troubleshooting and support. Includes system logs, app settings, and device information.",
                            action: exportDiagnosticLogs,
                            isLoading: isExporting
                        )
                    )
                ),
                SettingsItem(
                    title: "Run System Check",
                    description: "Run system diagnostics",
                    view: AnyView(
                        SettingsButtonRow(
                            title: "Run System Check",
                            description: "Run system diagnostics",
                            action: runSystemDiagnostics,
                            style: .secondary
                        )
                    )
                )
            ]
        )
    }
    
    private var currentModeView: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Current Mode")
                    .font(.settingsBody)
                    .fontWeight(.medium)
                    .foregroundColor(.settingsPrimary)
                
                Text("Active trading environment")
                    .font(.settingsCaption)
                    .foregroundColor(.settingsSecondary)
            }
            
            Spacer()
            
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(settings.demoMode ? .orange : .green)
                    .frame(width: 10, height: 10)
                
                Text(settings.demoMode ? "DEMO MODE" : "LIVE MODE")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(settings.demoMode ? .orange : .green)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill((settings.demoMode ? Color.orange : Color.green).opacity(0.12))
            )
        }
        .padding(.vertical, Spacing.xs)
    }
    
    // MARK: - Routing & Confidence Configuration View
    private var routingConfidenceView: some View {
        List {
            Section {
                SettingsToggleRow(
                    title: "Strategy Routing for Short Timeframes",
                    description: "Use strategies for 5m/1h timeframes, AI for 4h. When disabled, AI is used for all timeframes.",
                    helpText: "Per-timeframe routing optimizes predictions:\n\n• 5m/1h: Strategy aggregation (faster, less complex)\n• 4h: AI model (deeper analysis)\n\nDisabling uses AI for all timeframes.",
                    isOn: $settingsRepo.useStrategyRouting,
                    style: .prominent
                )
            } header: {
                Text("Per-Timeframe Routing")
                    .font(.settingsHeadline)
            } footer: {
                Text("Controls which system handles predictions for different timeframes. Recommended: enabled for optimal performance.")
                    .font(.settingsFootnote)
                    .foregroundColor(.settingsTertiary)
            }
            
            Section {
                VStack(spacing: Spacing.md) {
                    HStack {
                        Text("Strategy Confidence Range")
                            .font(.settingsBody)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.2f", settingsRepo.strategyConfidenceMin)) - \(String(format: "%.2f", settingsRepo.strategyConfidenceMax))")
                            .font(.settingsBody)
                            .foregroundColor(.settingsSecondary)
                    }
                    
                    VStack(spacing: Spacing.sm) {
                        HStack {
                            Text("Min")
                                .font(.settingsCaption)
                                .foregroundColor(.settingsSecondary)
                            Spacer()
                            Text("Max")
                                .font(.settingsCaption)
                                .foregroundColor(.settingsSecondary)
                        }
                        
                        HStack(spacing: Spacing.md) {
                            Slider(
                                value: $settingsRepo.strategyConfidenceMin,
                                in: 0.55...0.89,
                                step: 0.01
                            )
                            .frame(maxWidth: 120)
                            
                            Text("to")
                                .font(.settingsCaption)
                                .foregroundColor(.settingsSecondary)
                            
                            Slider(
                                value: $settingsRepo.strategyConfidenceMax,
                                in: 0.56...0.90,
                                step: 0.01
                            )
                            .frame(maxWidth: 120)
                        }
                    }
                }
                .padding(.vertical, Spacing.xs)
                
            } header: {
                Text("Confidence Controls")
                    .font(.settingsHeadline)
            } footer: {
                Text("Strategy confidence is clamped to this range (0.55-0.90). AI confidence uses 0.55-0.95 range automatically.")
                    .font(.settingsFootnote)
                    .foregroundColor(.settingsTertiary)
            }
            
            Section {
                let strategyNames = ["RSI", "EMA Crossover", "MACD", "Mean Reversion", "ATR Breakout"]
                
                ForEach(strategyNames, id: \.self) { strategyName in
                    VStack(spacing: Spacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(strategyName)
                                    .font(.settingsBody)
                                    .fontWeight(.medium)
                                
                                Text("Weight: \(String(format: "%.1f", settingsRepo.getStrategyWeight(strategyName)))")
                                    .font(.settingsCaption)
                                    .foregroundColor(.settingsSecondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { settingsRepo.isStrategyEnabled(strategyName) },
                                set: { settingsRepo.updateStrategyEnabled(strategyName, enabled: $0) }
                            ))
                            .toggleStyle(SwitchToggleStyle())
                        }
                        
                        if settingsRepo.isStrategyEnabled(strategyName) {
                            HStack {
                                Text("Weight")
                                    .font(.settingsCaption)
                                    .foregroundColor(.settingsSecondary)
                                
                                Slider(
                                    value: Binding(
                                        get: { settingsRepo.getStrategyWeight(strategyName) },
                                        set: { settingsRepo.updateStrategyWeight(strategyName, weight: $0) }
                                    ),
                                    in: 0.1...2.0,
                                    step: 0.1
                                )
                                
                                Text("\(String(format: "%.1f", settingsRepo.getStrategyWeight(strategyName)))")
                                    .font(.settingsCaption)
                                    .foregroundColor(.settingsSecondary)
                                    .frame(width: 30)
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            } header: {
                Text("Strategy Settings")
                    .font(.settingsHeadline)
            } footer: {
                Text("Enable/disable individual strategies and adjust their voting weights. Higher weights have more influence in final decisions.")
                    .font(.settingsFootnote)
                    .foregroundColor(.settingsTertiary)
            }
        }
        .navigationTitle("Routing & Confidence")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Methods
    private func exportDiagnosticLogs() {
        guard !isExporting else { return }
        
        isExporting = true
        
        Task {
            do {
                let logURL = try await LogExporter.exportDiagnosticLogs()
                
                await MainActor.run {
                    self.exportedLogURL = logURL
                    self.showShareSheet = true
                    self.isExporting = false
                    
                    // Show success toast
                    toastManager.showDataExported(type: "Diagnostic logs")
                }
            } catch {
                await MainActor.run {
                    self.isExporting = false
                    
                    // Show error toast
                    toastManager.showDataExportFailed(
                        type: "diagnostic logs",
                        error: error.localizedDescription
                    )
                }
            }
        }
    }
    
    private func runSystemDiagnostics() {
        // System diagnostics functionality
        print("System diagnostics requested")
    }
    
    @ViewBuilder
    private var widgetRefreshStatusIcon: some View {
        switch widgetRefreshStats.status {
        case .idle:
            Image(systemName: "clock")
                .foregroundColor(.secondary)
                .font(.caption2)
        case .refreshing:
            ProgressView()
                .scaleEffect(0.6)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption2)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption2)
        }
    }
    
    private var widgetRefreshDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    private func updateWidgetRefreshStats() {
        widgetRefreshStats = WidgetDataManager.shared.getRefreshStats()
    }
}

// MARK: - Supporting Views
struct SettingsRowView: View {
    let item: SettingsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            item.view
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let description: String
    let helpText: String?
    @Binding var isOn: Bool
    let style: ToggleStyle
    let isDisabled: Bool
    
    init(
        title: String, 
        description: String, 
        helpText: String? = nil, 
        isOn: Binding<Bool>, 
        style: ToggleStyle = .default,
        isDisabled: Bool = false
    ) {
        self.title = title
        self.description = description
        self.helpText = helpText
        self._isOn = isOn
        self.style = style
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.settingsBody)
                        .fontWeight(.medium)
                        .foregroundColor(isDisabled ? .settingsSecondary : .settingsPrimary)
                    
                    if !description.isEmpty {
                        Text(description)
                            .font(.settingsCaption)
                            .foregroundColor(.settingsSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                HStack(spacing: Spacing.sm) {
                    if let helpText = helpText {
                        HelpIconView(helpText: helpText)
                    }
                    
                    StandardToggle(
                        isOn: $isOn,
                        style: style,
                        size: .medium,
                        isDisabled: isDisabled,
                        hapticFeedback: true
                    )
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let description: String
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.settingsBody)
                    .fontWeight(.medium)
                    .foregroundColor(.settingsPrimary)
                
                if !description.isEmpty {
                    Text(description)
                        .font(.settingsCaption)
                        .foregroundColor(.settingsSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct SettingsInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.settingsBody)
                .fontWeight(.medium)
                .foregroundColor(.settingsPrimary)
            
            Spacer()
            
            Text(value)
                .font(.settingsBody)
                .foregroundColor(.settingsSecondary)
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct SettingsButtonRow: View {
    let title: String
    let description: String
    let action: () -> Void
    let style: SettingsButtonStyle
    
    enum SettingsButtonStyle {
        case primary
        case secondary
        case destructive
        
        var buttonStyle: ButtonStyle {
            switch self {
            case .primary: return .primary
            case .secondary: return .ghost
            case .destructive: return .destructive
            }
        }
        
        var color: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return .settingsSecondary
            case .destructive: return .red
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(title)
                            .font(.settingsBody)
                            .fontWeight(.medium)
                            .foregroundColor(style.color)
                        
                        if !description.isEmpty {
                            Text(description)
                                .font(.settingsCaption)
                                .foregroundColor(.settingsSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, Spacing.xs)
    }
}

struct SettingsExportButtonRow: View {
    let title: String
    let description: String
    let action: () -> Void
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(title)
                            .font(.settingsBody)
                            .fontWeight(.medium)
                            .foregroundColor(isLoading ? .settingsSecondary : .accentColor)
                        
                        if !description.isEmpty {
                            Text(description)
                                .font(.settingsCaption)
                                .foregroundColor(.settingsSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoading)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Supporting Types
struct SettingsSection {
    let title: String
    let icon: String
    let footer: String
    let items: [SettingsItem]
}

struct SettingsItem {
    let title: String
    let description: String
    let view: AnyView
}

// Bundle extension is defined in Utils/LogExporter.swift

#Preview {
    SettingsView()
        .preferredColorScheme(nil)
}
