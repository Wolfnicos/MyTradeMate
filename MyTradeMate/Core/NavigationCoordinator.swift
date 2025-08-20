import SwiftUI
import Foundation

@MainActor
final class NavigationCoordinator: ObservableObject {
    @Published var dashboardPath = NavigationPath()
    @Published var tradesPath = NavigationPath()
    @Published var pnlPath = NavigationPath()
    @Published var strategiesPath = NavigationPath()
    @Published var settingsPath = NavigationPath()
    
    nonisolated init() {}
    
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
    }
    
    @ViewBuilder
    func destination(for destination: NavigationDestination) -> some View {
        switch destination {
        case .dashboard:
            DashboardView()
        case .trades:
            Text("Trades View")
                .navigationTitle("Trades")
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
                .navigationTitle("Settings")
        case .exchangeKeys:
            Text("Exchange Keys")
                .navigationTitle("Exchange Keys")
        case .exchangeKeyEdit(let exchange):
            Text("Edit \(exchange.displayName) Keys")
                .navigationTitle("Edit Keys")
        case .about:
            Text("About MyTradeMate")
                .navigationTitle("About")
        }
    }
}