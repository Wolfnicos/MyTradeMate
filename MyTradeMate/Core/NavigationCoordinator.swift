import SwiftUI
import Foundation

// MARK: - Navigation Destinations
enum NavigationDestination: Hashable {
    case dashboard
    case trades
    case tradeDetail(String) // Trade ID
    case pnl
    case strategies
    case strategyDetail(String) // Strategy ID
    case settings
    case exchangeKeys
    case exchangeKeyEdit(Exchange)
    case about
}

// MARK: - Navigation Coordinator
@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var dashboardPath = NavigationPath()
    @Published var tradesPath = NavigationPath()
    @Published var pnlPath = NavigationPath()
    @Published var strategiesPath = NavigationPath()
    @Published var settingsPath = NavigationPath()
    
    // MARK: - Navigation Methods
    
    func navigate(to destination: NavigationDestination, in tab: AppTab) {
        switch tab {
        case .dashboard:
            dashboardPath.append(destination)
        case .trades:
            tradesPath.append(destination)
        case .pnl:
            pnlPath.append(destination)
        case .strategies:
            strategiesPath.append(destination)
        case .settings:
            settingsPath.append(destination)
        }
        
        Log.userAction("Navigated to \(destination) in \(tab) tab")
    }
    
    func popToRoot(in tab: AppTab) {
        switch tab {
        case .dashboard:
            dashboardPath.removeLast(dashboardPath.count)
        case .trades:
            tradesPath.removeLast(tradesPath.count)
        case .pnl:
            pnlPath.removeLast(pnlPath.count)
        case .strategies:
            strategiesPath.removeLast(strategiesPath.count)
        case .settings:
            settingsPath.removeLast(settingsPath.count)
        }
    }
    
    func pop(in tab: AppTab) {
        switch tab {
        case .dashboard:
            if !dashboardPath.isEmpty {
                dashboardPath.removeLast()
            }
        case .trades:
            if !tradesPath.isEmpty {
                tradesPath.removeLast()
            }
        case .pnl:
            if !pnlPath.isEmpty {
                pnlPath.removeLast()
            }
        case .strategies:
            if !strategiesPath.isEmpty {
                strategiesPath.removeLast()
            }
        case .settings:
            if !settingsPath.isEmpty {
                settingsPath.removeLast()
            }
        }
    }
    
    // MARK: - Deep Linking Support
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            return
        }
        
        switch host {
        case "dashboard":
            navigate(to: .dashboard, in: .dashboard)
        case "trades":
            if let tradeId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                navigate(to: .tradeDetail(tradeId), in: .trades)
            } else {
                navigate(to: .trades, in: .trades)
            }
        case "strategies":
            if let strategyId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                navigate(to: .strategyDetail(strategyId), in: .strategies)
            } else {
                navigate(to: .strategies, in: .strategies)
            }
        case "settings":
            navigate(to: .settings, in: .settings)
        default:
            break
        }
    }
}

// MARK: - App Tab Enum
enum AppTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case trades = "Trades"
    case pnl = "P&L"
    case strategies = "Strategies"
    case settings = "Settings"
    
    var systemImage: String {
        switch self {
        case .dashboard:
            return "chart.line.uptrend.xyaxis"
        case .trades:
            return "arrow.left.arrow.right"
        case .pnl:
            return "chart.bar.fill"
        case .strategies:
            return "brain"
        case .settings:
            return "gearshape.fill"
        }
    }
}

// MARK: - Navigation View Builder
extension NavigationCoordinator {
    @ViewBuilder
    func destination(for destination: NavigationDestination) -> some View {
        switch destination {
        case .dashboard:
            DashboardView()
        case .trades:
            TradesView()
        case .tradeDetail(let tradeId):
            TradeDetailView(tradeId: tradeId)
        case .pnl:
            PnLDetailView()
        case .strategies:
            StrategiesView()
        case .strategyDetail(let strategyId):
            StrategyDetailView(strategyId: strategyId)
        case .settings:
            Text("Settings") // SettingsView()
        case .exchangeKeys:
            Text("Exchange Keys") // ExchangeKeysView()
        case .exchangeKeyEdit(let exchange):
            ExchangeKeyEditView(exchange: exchange) { _, _ in
                // Handle save
            }
        case .about:
            AboutView()
        }
    }
}

// MARK: - Placeholder Views
// These would be implemented as needed
struct TradeDetailView: View {
    let tradeId: String
    
    var body: some View {
        Text("Trade Detail: \(tradeId)")
            .navigationTitle("Trade Details")
    }
}

struct StrategyDetailView: View {
    let strategyId: String
    
    var body: some View {
        Text("Strategy Detail: \(strategyId)")
            .navigationTitle("Strategy Details")
    }
}

struct AboutView: View {
    var body: some View {
        Text("About MyTradeMate")
            .navigationTitle("About")
    }
}