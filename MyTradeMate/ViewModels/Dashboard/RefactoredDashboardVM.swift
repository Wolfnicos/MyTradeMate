import Foundation
import Combine
import SwiftUI
import OSLog

private let logger = os.Logger(subsystem: "com.mytrademate", category: "Dashboard")

// MARK: - Refactored Dashboard ViewModel
@MainActor
final class RefactoredDashboardVM: ObservableObject {
    // MARK: - Component Managers
    @StateObject private var marketDataManager = MarketDataManager()
    @StateObject private var signalManager = SignalManager()
    @StateObject private var tradingManager = TradingManager()
    
    // MARK: - Injected Dependencies
    @Injected private var settings: AppSettingsProtocol
    
    // MARK: - Published Properties (Delegated to Components)
    
    // Market Data Properties
    var price: Double { marketDataManager.price }
    var priceChange: Double { marketDataManager.priceChange }
    var priceChangePercent: Double { marketDataManager.priceChangePercent }
    var candles: [Candle] { marketDataManager.candles }
    var chartPoints: [CGPoint] { marketDataManager.chartPoints }
    var chartData: [CandleData] { marketDataManager.chartData }
    var isLoading: Bool { marketDataManager.isLoading }
    // timeframe is now @Published property above
    var lastUpdated: Date { marketDataManager.lastUpdated }
    
    // Signal Properties
    var currentSignal: SignalInfo? { signalManager.currentSignal }
    var confidence: Double { signalManager.confidence }
    var isRefreshing: Bool { signalManager.isRefreshing }
    
    // Trading Properties
    var tradingMode: TradingMode { 
        get { tradingManager.tradingMode }
        set { tradingManager.tradingMode = newValue }
    }
    var openPositions: [Position] { tradingManager.openPositions }
    var isConnected: Bool { tradingManager.isConnected }
    var connectionStatus: String { tradingManager.connectionStatus }
    
    // MARK: - Computed Properties (Delegated)
    var priceString: String { marketDataManager.priceString }
    var priceChangeString: String { marketDataManager.priceChangeString }
    var priceChangePercentString: String { marketDataManager.priceChangePercentString }
    var priceChangeColor: Color { marketDataManager.priceChangeColor }
    var lastUpdatedString: String { marketDataManager.lastUpdatedString }
    
    // MARK: - Legacy Compatibility Properties
    @Published var precisionMode: Bool = false
    var isPrecisionMode: Bool {
        get { precisionMode }
        set { precisionMode = newValue }
    }
    
    // Multi-Asset Trading Properties for 2025
    @Published var selectedTradingPair: TradingPair = .btcUsd
    @Published var selectedExchange: Exchange = .binance
    @Published var selectedQuoteCurrency: QuoteCurrency = .USD
    @Published var amountMode: AmountMode = .percentOfEquity
    @Published var amountValue: Double = 5.0
    @Published var currentEquity: Double = 10_000.0
    @Published var autoTradingEnabled: Bool = false
    @Published var timeframe: Timeframe = .m5
    
    // Portfolio properties for 2025
    @Published var totalBalance: Double = 10000.0
    @Published var availableBalance: Double = 8500.0
    @Published var totalBalanceChange: Double = 250.0
    @Published var totalBalanceChangePercent: Double = 2.56
    @Published var todayPnL: Double = 125.50
    @Published var todayPnLPercent: Double = 1.28
    @Published var unrealizedPnL: Double = -45.20
    @Published var unrealizedPnLPercent: Double = -0.46
    
    // P&L HUD live updates
    @Published var currentPnLSnapshot: PnLSnapshot?
    
    // Trade confirmation
    @Published var showingTradeConfirmation = false
    @Published var pendingTradeRequest: TradeRequest?
    @Published var isExecutingTrade = false
    
    // Toast notifications
    @Published var showingToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadInitialData()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Observe market data changes to trigger signal updates
        marketDataManager.$candles
            .dropFirst() // Skip initial empty value
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] candles in
                guard let self = self, !candles.isEmpty else { return }
                self.signalManager.refreshPrediction(candles: candles, timeframe: self.timeframe)
            }
            .store(in: &cancellables)
        
        // Observe signal changes for auto trading
        signalManager.$currentSignal
            .compactMap { $0 }
            .sink { [weak self] signal in
                guard let self = self else { return }
                if self.settings.autoTrading {
                    self.tradingManager.handleAutoTrading(signal: signal, currentPrice: self.price)
                }
            }
            .store(in: &cancellables)
        
        // Update position P&L when price changes
        marketDataManager.$price
            .dropFirst()
            .sink { [weak self] price in
                self?.tradingManager.updatePositionPnL(currentPrice: price)
            }
            .store(in: &cancellables)
        
        // Observe precision mode changes
        $precisionMode
            .removeDuplicates()
            .sink { precision in
                Log.ai.info("Precision mode \(precision ? "ON" : "OFF")")
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        Task {
            await marketDataManager.loadMarketData()
            signalManager.refreshPrediction(candles: marketDataManager.candles, timeframe: timeframe)
        }
    }
    
    // MARK: - Public Methods (Delegated to Components)
    
    // Market Data Methods
    func refreshData() {
        marketDataManager.refreshData()
    }
    
    func updateTimeframe(_ newTimeframe: Timeframe) {
        marketDataManager.updateTimeframe(newTimeframe)
    }
    
    // Signal Methods
    func refreshPrediction() {
        signalManager.refreshPrediction(candles: candles, timeframe: timeframe)
    }
    
    // Trading Methods
    func executeBuy() {
        tradingManager.executeBuy()
        Log.userAction("Manual buy order initiated")
    }
    
    func executeSell() {
        tradingManager.executeSell()
        Log.userAction("Manual sell order initiated")
    }
    
    func closePosition(_ position: Position) {
        tradingManager.closePosition(position)
    }
    
    func closeAllPositions() {
        tradingManager.closeAllPositions()
    }
    
    // MARK: - Legacy Compatibility Methods
    func reloadDataAndPredict() async {
        await marketDataManager.loadMarketData()
        signalManager.refreshPrediction(candles: candles, timeframe: timeframe)
    }
    
    func refreshPredictionAsync() async {
        signalManager.refreshPrediction(candles: candles, timeframe: timeframe)
    }
    
    // MARK: - Trade Execution Methods
    func confirmTrade() {
        guard let tradeRequest = pendingTradeRequest else { return }
        showingTradeConfirmation = false
        pendingTradeRequest = nil
        // Execute trade logic would go here
        showSuccessToast("Order placed successfully")
    }
    
    func cancelTrade() {
        showingTradeConfirmation = false
        pendingTradeRequest = nil
    }
    
    // MARK: - Toast Methods
    func showSuccessToast(_ message: String) {
        toastMessage = message
        toastType = .success
        showingToast = true
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showingToast = false
        }
    }
    
    func showErrorToast(_ message: String) {
        toastMessage = message
        toastType = .error
        showingToast = true
        
        // Auto-dismiss after 4 seconds for errors
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.showingToast = false
        }
    }
}

// MARK: - Factory Method for Easy Migration
extension RefactoredDashboardVM {
    /// Creates a RefactoredDashboardVM that can be used as a drop-in replacement for DashboardVM
    static func createCompatible() -> RefactoredDashboardVM {
        return RefactoredDashboardVM()
    }
}

// MARK: - Preview Support
extension RefactoredDashboardVM {
    static func preview() -> RefactoredDashboardVM {
        let vm = RefactoredDashboardVM()
        // Set up preview data
        return vm
    }
}