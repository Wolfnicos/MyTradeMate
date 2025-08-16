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
        case .trades: return "arrow.left.arrow.right"
        case .pnl: return "chart.bar.fill"
        case .strategies: return "brain"
        case .settings: return "gearshape.fill"
        }
    }
}

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var dashboardPath = NavigationPath()
    @Published var tradesPath = NavigationPath()
    @Published var pnlPath = NavigationPath()
    @Published var strategiesPath = NavigationPath()
    @Published var settingsPath = NavigationPath()
    
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
    
    @ViewBuilder
    func destination(for destination: NavigationDestination) -> some View {
        switch destination {
        case .dashboard:
            DashboardView()
        case .trades:
            TradesView()
        case .tradeDetail(let tradeId):
            Text("Trade Detail: \(tradeId)")
                .navigationTitle("Trade Details")
        case .pnl:
            PnLDetailView()
        case .strategies:
            StrategiesView()
        case .strategyDetail(let strategyId):
            Text("Strategy Detail: \(strategyId)")
                .navigationTitle("Strategy Details")
        case .settings:
            Text("Settings")
        case .exchangeKeys:
            Text("Exchange Keys")
        case .exchangeKeyEdit(let exchange):
            Text("Edit \(exchange.displayName) Keys")
                .navigationTitle("Edit Keys")
        case .about:
            Text("About MyTradeMate")
                .navigationTitle("About")
        }
    }
}

struct RootTabs: View {
    @StateObject private var settings = AppSettings.shared
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
                Label("Trades", systemImage: "arrow.left.arrow.right")
            }
            
            NavigationStack(path: $navigationCoordinator.pnlPath) {
                PnLDetailView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        navigationCoordinator.destination(for: destination)
                    }
            }
            .tabItem {
                Label("P&L", systemImage: "chart.bar.fill")
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
                SettingsView()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        navigationCoordinator.destination(for: destination)
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .environmentObject(settings)
        .environmentObject(themeManager)
        .environmentObject(errorManager)
        .environmentObject(navigationCoordinator)
        .preferredColorScheme(themeManager.colorScheme)
        .withErrorHandling()
        .onAppear {
            // Validate settings on app launch
            SettingsValidator.autoCorrectSettings()
            
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