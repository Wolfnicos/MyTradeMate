import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var appSettings = AppSettings.shared
    @ObservedObject private var settingsRepo = SettingsRepository.shared
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportedLogURL: URL?
    @State private var showWidgetConfiguration = false
    @State private var widgetRefreshStats: (lastRefresh: Date?, canRefresh: Bool, status: SettingsWidgetRefreshStatus) = (nil, true, .idle)
    
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
            ZStack {
                // Premium animated background
                themeManager.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: Spacing.xl) {
                        
                        // Modern Header
                        headerSection()
                        
                        // Search Bar
                        searchSection()
                        
                        // Settings Sections
                        ForEach(filteredSections) { section in
                            settingsSection(section)
                        }
                        
                        // Trading Mode Section
                        tradingModeSection()
                        
                        // App Info Footer
                        appInfoSection()
                        
                        // Bottom padding for tab bar
                        Color.clear
                            .frame(height: 100)
                    }
                    .padding(.horizontal, Spacing.xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedLogURL {
                ShareSheet(items: [url])
            }
        }
        .refreshable {
            updateWidgetRefreshStats()
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private func headerSection() -> some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Settings")
                        .font(Typography.title1)
                        .foregroundColor(TextColor.primary)
                    
                    Text("Configure MyTradeMate")
                        .font(Typography.subheadline)
                        .foregroundColor(TextColor.secondary)
                }
                
                Spacer()
                
                // Trading Mode Indicator
                tradingModeIndicator()
            }
            .padding(.top, 60) // Safe area compensation
        }
    }
    
    // MARK: - Search Section
    @ViewBuilder
    private func searchSection() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(TextColor.secondary)
            
            TextField("Search settings...", text: $searchText)
                .font(Typography.body)
                .foregroundColor(TextColor.primary)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(TextColor.secondary)
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Brand.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Settings Section
    @ViewBuilder
    private func settingsSection(_ section: SettingsSection) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section Header
            HStack {
                Image(systemName: section.icon)
                    .font(Typography.headline)
                    .foregroundColor(Brand.blue)
                
                Text(section.title)
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            
            // Section Items
            VStack(spacing: 0) {
                ForEach(section.items) { item in
                    settingsItem(item)
                    
                    if item.id != section.items.last?.id {
                        Divider()
                            .padding(.leading, Spacing.xl)
                    }
                }
            }
            .background(.ultraThinMaterial)
            .cornerRadius(CornerRadius.lg)
            
            // Section Footer
            if !section.footer.isEmpty {
                Text(section.footer)
                    .font(Typography.caption1)
                    .foregroundColor(TextColor.tertiary)
                    .padding(.horizontal, Spacing.lg)
            }
        }
    }
    
    // MARK: - Settings Item
    @ViewBuilder
    private func settingsItem(_ item: SettingsItem) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(item.title)
                    .font(Typography.body)
                    .foregroundColor(TextColor.primary)
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(Typography.caption1)
                        .foregroundColor(TextColor.secondary)
                }
            }
            
            Spacer()
            
            // Control
            settingsControl(for: item)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            handleItemTap(item)
        }
    }
    
    // MARK: - Settings Control
    @ViewBuilder
    private func settingsControl(for item: SettingsItem) -> some View {
        switch item.type {
        case .toggle(let binding):
            Toggle("", isOn: binding)
                .toggleStyle(ModernToggleStyle())
        
        case .button(let action):
            Button(action: action) {
                Image(systemName: "chevron.right")
                    .font(Typography.caption1)
                    .foregroundColor(TextColor.secondary)
            }
        
        case .picker(let options, let selection):
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
        
        case .slider(let binding, let range):
            Slider(value: binding, in: range)
                .accentColor(Brand.blue)
                .frame(width: 100)
        
        case .info(let text):
            Text(text)
                .font(Typography.caption1)
                .foregroundColor(TextColor.secondary)
        }
    }
    
    // MARK: - Trading Mode Section
    @ViewBuilder
    private func tradingModeSection() -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(Typography.headline)
                    .foregroundColor(Brand.blue)
                
                Text("Trading Mode")
                    .font(Typography.headline)
                    .foregroundColor(TextColor.primary)
                
                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            
            HStack(spacing: Spacing.sm) {
                ForEach(TradingMode.allCases, id: \.self) { mode in
                    tradingModeCard(mode)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .padding(.vertical, Spacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(CornerRadius.lg)
    }
    
    // MARK: - Trading Mode Card
    @ViewBuilder
    private func tradingModeCard(_ mode: TradingMode) -> some View {
        let isSelected = settingsRepo.tradingMode == mode
        let titleColor: Color = isSelected ? .white : TextColor.primary
        let descriptionColor: Color = isSelected ? .white.opacity(0.8) : TextColor.secondary
        let backgroundColor: LinearGradient = isSelected ? themeManager.primaryGradient : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
        let borderColor = isSelected ? Color.clear : Brand.blue.opacity(0.2)
        
        VStack(spacing: Spacing.xs) {
            Text(mode.title)
                .font(Typography.callout)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(titleColor)
            
            Text(mode.description)
                .font(Typography.caption1)
                .foregroundColor(descriptionColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        .onTapGesture {
            withAnimation(.spring()) {
                settingsRepo.tradingMode = mode
            }
        }
    }
    
    // MARK: - App Info Section
    @ViewBuilder
    private func appInfoSection() -> some View {
        VStack(spacing: Spacing.sm) {
            Text("MyTradeMate Pro")
                .font(Typography.headline)
                .foregroundColor(TextColor.primary)
            
            Text("Version \(appVersion)")
                .font(Typography.caption1)
                .foregroundColor(TextColor.secondary)
        }
        .padding(Spacing.lg)
        .background(.ultraThinMaterial)
        .cornerRadius(CornerRadius.md)
    }
    
    // MARK: - Trading Mode Indicator
    @ViewBuilder
    private func tradingModeIndicator() -> some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(tradingModeColor)
                .frame(width: 8, height: 8)
            
            Text(settingsRepo.tradingMode.title.uppercased())
                .font(Typography.caption1)
                .fontWeight(.medium)
                .foregroundColor(tradingModeColor)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Helper Properties
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var tradingModeColor: Color {
        switch settingsRepo.tradingMode {
        case .live: return Accent.green
        case .paper: return Accent.yellow
        case .demo: return Brand.blue
        }
    }
    
    // MARK: - Helper Methods
    private func handleItemTap(_ item: SettingsItem) {
        switch item.type {
        case .button(let action):
            action()
        default:
            break
        }
    }
    
    private func updateWidgetRefreshStats() {
        // Update widget refresh statistics
        widgetRefreshStats.lastRefresh = Date()
        widgetRefreshStats.status = .refreshing
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            widgetRefreshStats.status = .success
        }
    }
}

// MARK: - Settings Section Data
extension SettingsView {
    private var tradingSection: SettingsSection {
        SettingsSection(
            title: "Trading",
            icon: "chart.line.uptrend.xyaxis",
            footer: "Configure trading parameters and risk management",
            items: [
                SettingsItem(
                    title: "Auto Trading",
                    description: "Enable automatic trade execution",
                    type: .toggle($settingsRepo.autoTradingEnabled)
                ),
                SettingsItem(
                    title: "Confirm Trades",
                    description: "Show confirmation dialog before executing trades",
                    type: .toggle($settingsRepo.confirmTrades)
                ),
                SettingsItem(
                    title: "Paper Trading",
                    description: "Use simulated trading instead of real money",
                    type: .toggle($settingsRepo.paperTrading)
                ),
                SettingsItem(
                    title: "Trading Strategies",
                    description: "Configure and manage trading strategies",
                    type: .button {
                        // Navigate to strategies
                    }
                )
            ]
        )
    }
    
    private var interfaceSection: SettingsSection {
        SettingsSection(
            title: "Interface",
            icon: "paintbrush",
            footer: "Customize the app appearance and behavior",
            items: [
                SettingsItem(
                    title: "Dark Mode",
                    description: "Use dark theme throughout the app",
                    type: .toggle($settingsRepo.darkMode)
                ),
                SettingsItem(
                    title: "Haptic Feedback",
                    description: "Enable vibration feedback for interactions",
                    type: .toggle($settingsRepo.hapticsEnabled)
                )
            ]
        )
    }
    
    private var securitySection: SettingsSection {
        SettingsSection(
            title: "Security",
            icon: "shield",
            footer: "Protect your account and trading data",
            items: [
                SettingsItem(
                    title: "Face ID / Touch ID",
                    description: "Use biometric authentication",
                    type: .toggle(.constant(false))
                )
            ]
        )
    }
    
    private var diagnosticsSection: SettingsSection {
        SettingsSection(
            title: "Diagnostics",
            icon: "wrench.and.screwdriver",
            footer: "Debug and troubleshooting tools",
            items: [
                SettingsItem(
                    title: "Verbose Logging",
                    description: "Enable detailed debug logs",
                    type: .toggle($settingsRepo.verboseLogging)
                ),
                SettingsItem(
                    title: "Export Logs",
                    description: "Share debug logs for support",
                    type: .button {
                        exportLogs()
                    }
                )
            ]
        )
    }
    
    private func exportLogs() {
        isExporting = true
        
        Task {
            do {
                let logURL = try await LogExporter.exportDiagnosticLogs()
                await MainActor.run {
                    exportedLogURL = logURL
                    showShareSheet = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    toastManager.showError(title: "Export Failed", message: error.localizedDescription)
                    isExporting = false
                }
            }
        }
    }
}

// MARK: - Settings Models
struct SettingsSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let footer: String
    let items: [SettingsItem]
}

struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: SettingsItemType
}

enum SettingsItemType {
    case toggle(Binding<Bool>)
    case button(() -> Void)
    case picker([String], Binding<String>)
    case slider(Binding<Double>, ClosedRange<Double>)
    case info(String)
}

// MARK: - Modern Toggle Style
struct ModernToggleStyle: SwiftUI.ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? Brand.blue : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                
                Circle()
                    .fill(.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.spring(response: 0.3), value: configuration.isOn)
            }
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}


// MARK: - Settings Widget Refresh Status
enum SettingsWidgetRefreshStatus {
    case idle
    case refreshing
    case success
    case failure
}