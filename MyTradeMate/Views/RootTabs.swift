import SwiftUI
import Foundation

// Exchange model is defined in Models/Exchange.swift

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