import SwiftUI

@main
struct MyTradeMateApp: App {
    // Environment & Services
    @StateObject private var appState = AppState()
    @StateObject private var marketData = MarketDataService()
    @StateObject private var tradeManager = TradeManager()
    @StateObject private var riskManager = RiskManager()
    @StateObject private var aiManager = AIModelManager()
    
    // Color scheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init() {
        // Global appearance setup
        let appearance = UINavigationBar.appearance()
        appearance.largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: 34, weight: .bold)]
        appearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(marketData)
                .environmentObject(tradeManager)
                .environmentObject(riskManager)
                .environmentObject(aiManager)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .task(priority: .background) {
                    // Preload AI models
                    await aiManager.preloadModels()
                    // Start monitoring SL/TP
                    await StopMonitor.shared.start()
                }
        }
    }
}

// MARK: - App State
final class AppState: ObservableObject {
    @Published var selectedTab: Tab = .dashboard
    @Published var isTrialActive = true
    @Published var trialDaysLeft = 3
    @Published var showingError: Error?
    
    enum Tab {
        case dashboard
        case history
        case settings
    }
}

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppState.Tab.dashboard)
            
            TradeHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(AppState.Tab.history)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppState.Tab.settings)
        }
        .alert("Error", isPresented: .constant(appState.showingError != nil)) {
            Button("OK") { appState.showingError = nil }
        } message: {
            if let error = appState.showingError {
                Text(error.localizedDescription)
            }
        }
    }
}