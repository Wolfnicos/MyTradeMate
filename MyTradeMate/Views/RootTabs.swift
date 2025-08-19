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

    var systemImage: String {
        switch self {
        case .dashboard: return "chart.line.uptrend.xyaxis"
        case .trades: return "list.bullet.rectangle"
        case .pnl: return "dollarsign.circle"
        case .strategies: return "brain"
        case .settings: return "gearshape"
        }
    }
}

    // NavigationCoordinator moved to Core/NavigationCoordinator.swift

struct RootTabs: View {
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var errorManager = ErrorManager.shared
    @StateObject private var navigationCoordinator = NavigationCoordinator()

    var body: some View {
        TabView {
            NavigationStack(path: $navigationCoordinator.dashboardPath) {
                DashboardView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        navigationCoordinator.destination(for: destination)
                    }
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationStack(path: $navigationCoordinator.tradesPath) {
                TradesView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        navigationCoordinator.destination(for: destination)
                    }
            }
            .tabItem {
                Label("Trades", systemImage: "list.bullet.rectangle")
            }

            NavigationStack(path: $navigationCoordinator.pnlPath) {
                PnLDetailView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        navigationCoordinator.destination(for: destination)
                    }
            }
            .tabItem {
                Label("P&L", systemImage: "dollarsign.circle")
            }

            NavigationStack(path: $navigationCoordinator.strategiesPath) {
                StrategiesView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        navigationCoordinator.destination(for: destination)
                    }
            }
            .tabItem {
                Label("Strategies", systemImage: "brain")
            }

            NavigationStack(path: $navigationCoordinator.settingsPath) {
                Text("Settings")
                    .navigationTitle("Settings")
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        navigationCoordinator.destination(for: destination)
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .environmentObject(appSettings)
        .environmentObject(themeManager)
        .environmentObject(errorManager)
        .environmentObject(navigationCoordinator)
        .preferredColorScheme(themeManager.colorScheme)
        .withErrorHandling()
        .onAppear {
                // Log app launch
            Log.userAction("App launched")
        }
        .onOpenURL { url in
                // Handle deep link - implementation will be added later
            print("Deep link received: \(url)")
        }
    }
}

struct RootTabs_Previews: PreviewProvider {
    static var previews: some View {
        RootTabs()
    }
}
