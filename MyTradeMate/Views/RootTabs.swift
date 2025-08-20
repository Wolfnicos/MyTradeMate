import SwiftUI
import Foundation

// MARK: - Navigation Types
enum NavigationDestination: Hashable {
    case dashboard
    case trades
    case tradeDetail(String)
    case pnl
    case strategies
    case strategyDetail(String)
    case settings
    case exchangeKeys
    case exchangeKeyEdit(Exchange)
    case about
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .dashboard:
            hasher.combine(0)
        case .trades:
            hasher.combine(1)
        case .tradeDetail(let id):
            hasher.combine(2)
            hasher.combine(id)
        case .pnl:
            hasher.combine(3)
        case .strategies:
            hasher.combine(4)
        case .strategyDetail(let name):
            hasher.combine(5)
            hasher.combine(name)
        case .settings:
            hasher.combine(6)
        case .exchangeKeys:
            hasher.combine(7)
        case .exchangeKeyEdit(let exchange):
            hasher.combine(8)
            hasher.combine(exchange)
        case .about:
            hasher.combine(9)
        }
    }
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.dashboard, .dashboard),
             (.trades, .trades),
             (.pnl, .pnl),
             (.strategies, .strategies),
             (.settings, .settings),
             (.exchangeKeys, .exchangeKeys),
             (.about, .about):
            return true
        case (.tradeDetail(let lhsId), .tradeDetail(let rhsId)):
            return lhsId == rhsId
        case (.strategyDetail(let lhsName), .strategyDetail(let rhsName)):
            return lhsName == rhsName
        case (.exchangeKeyEdit(let lhsExchange), .exchangeKeyEdit(let rhsExchange)):
            return lhsExchange == rhsExchange
        default:
            return false
        }
    }
}

enum AppTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case trades = "Trades"
    case pnl = "P&L"
    case strategies = "Strategies"
    case settings = "Settings"
    case debug = "Debug"

    var systemImage: String {
        switch self {
        case .dashboard: return "chart.line.uptrend.xyaxis"
        case .trades: return "list.bullet.rectangle"
        case .pnl: return "dollarsign.circle"
        case .strategies: return "brain"
        case .settings: return "gearshape"
        case .debug: return "ladybug"
        }
    }
}

    // NavigationCoordinator moved to Core/NavigationCoordinator.swift

struct RootTabs: View {
    // Core services
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var themeManager: ThemeManager
    
    // Managers
    @EnvironmentObject var marketDataManager: MarketDataManager
    @EnvironmentObject var signalManager: SignalManager
    @EnvironmentObject var tradingManager: TradingManager
    @EnvironmentObject var strategyManager: StrategyManager
    @EnvironmentObject var regimeDetectionManager: RegimeDetectionManager
    @EnvironmentObject var riskManager: RiskManager
    @EnvironmentObject var pnlManager: PnLManager
    
    // View Models
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var strategiesVM: RefactoredStrategiesVM
    @EnvironmentObject var settingsVM: SettingsVM
    @EnvironmentObject var tradesVM: TradesVM
    @EnvironmentObject var pnlVM: PnLVM

    var body: some View {
        TabView {
            // Dashboard Tab
            DashboardView()
                .environmentObject(dashboardVM)
                .tabItem { Label("Dashboard", systemImage: AppTab.dashboard.systemImage) }
                .tag(AppTab.dashboard)

            // Trades Tab
            TradesView()
                .environmentObject(tradesVM)
                .tabItem { Label("Trades", systemImage: AppTab.trades.systemImage) }
                .tag(AppTab.trades)

            // P&L Tab
            PnLDetailView()
                .environmentObject(pnlVM)
                .tabItem { Label("P&L", systemImage: AppTab.pnl.systemImage) }
                .tag(AppTab.pnl)

            // Strategies Tab
            StrategiesView()
                .environmentObject(strategiesVM)
                .tabItem { Label("Strategies", systemImage: AppTab.strategies.systemImage) }
                .tag(AppTab.strategies)

            // Settings Tab
            SettingsView()
                .environmentObject(settingsVM)
                .tabItem { Label("Settings", systemImage: AppTab.settings.systemImage) }
                .tag(AppTab.settings)

            // Debug Tab
            DebugScreen()
                .tabItem { Label("Debug", systemImage: AppTab.debug.systemImage) }
                .tag(AppTab.debug)
        }
        .onChange(of: settings.tradingMode) { newMode in
            Log.settings.info("[SETTINGS] Trading mode changed to \(newMode)")
        }
        .onChange(of: settings.preferredTheme) { newTheme in
            Log.settings.info("[SETTINGS] Theme changed to \(newTheme)")
            themeManager.setTheme(newTheme)
        }
        .onChange(of: settings.verboseLogging) { isVerbose in
            Log.settings.info("[SETTINGS] Verbose logging \(isVerbose ? "enabled" : "disabled")")
        }
    }
}

struct RootTabs_Previews: PreviewProvider {
    static var previews: some View {
        RootTabs()
    }
}
