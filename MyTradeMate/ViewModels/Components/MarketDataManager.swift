import Foundation
import Combine
import SwiftUI

// MARK: - Market Data Manager
@MainActor
final class MarketDataManager: ObservableObject {
    // MARK: - Dependencies
    private let marketDataService = MarketDataService.shared
    private let errorManager = ErrorManager.shared
    
    // MARK: - Published Properties
    @Published var price: Double = 0.0
    @Published var priceChange: Double = 0.0
    @Published var priceChangePercent: Double = 0.0
    @Published var candles: [Candle] = []
    @Published var chartPoints: [CGPoint] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date = Date()
    @Published var timeframe: Timeframe = .m5
    
    // MARK: - Private Properties
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var priceString: String {
        String(format: "%.2f", price)
    }
    
    var priceChangeString: String {
        let sign = priceChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", priceChange))"
    }
    
    var priceChangePercentString: String {
        let sign = priceChangePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", priceChangePercent))%"
    }
    
    var priceChangeColor: Color {
        priceChange >= 0 ? .green : .red
    }
    
    var lastUpdatedString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
    
    var chartData: [CandleData] {
        return candles.map { candle in
            CandleData(
                timestamp: candle.openTime,
                open: candle.open,
                high: candle.high,
                low: candle.low,
                close: candle.close,
                volume: candle.volume
            )
        }
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
        startAutoRefresh()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Observe timeframe changes with debounce
        $timeframe
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] timeframe in
                Log.app.info("User set timeframe to \(timeframe.rawValue)")
                Task { @MainActor [weak self] in
                    await self?.loadMarketData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.loadMarketData()
            }
        }
    }
    
    // MARK: - Public Methods
    func refreshData() {
        Task {
            isLoading = true
            await loadMarketData()
            isLoading = false
        }
    }
    
    func updateTimeframe(_ newTimeframe: Timeframe) {
        timeframe = newTimeframe
    }
    
    // MARK: - Data Loading
    func loadMarketData() async {
        do {
            if AppSettings.shared.demoMode {
                generateMockData()
                Log.app.info("Loaded demo market data")
            } else if AppSettings.shared.liveMarketData {
                // Load real market data
                let marketData = try await marketDataService.fetchCandles(
                    symbol: AppSettings.shared.defaultSymbol,
                    timeframe: timeframe
                )
                
                await MainActor.run {
                    self.candles = marketData
                    self.updatePriceInfo()
                    self.updateChartPoints()
                    self.lastUpdated = Date()
                }
                Log.app.info("Loaded live market data: \(marketData.count) candles")
            } else {
                // Fallback to demo data
                generateMockData()
                Log.app.info("Fallback to demo data")
            }
        } catch {
            Log.app.error("Failed to load market data: \(error.localizedDescription)")
            errorManager.handle(error, context: "Load Market Data")
            // Fallback to demo data on error
            generateMockData()
        }
    }
    
    // MARK: - Private Methods
    private func generateMockData() {
        // Generate mock data for demo mode
        let basePrice = 45000.0 + Double.random(in: -2000...2000)
        price = basePrice
        priceChange = Double.random(in: -500...500)
        priceChangePercent = (priceChange / basePrice) * 100
        
        // Generate mock candles
        candles = generateMockCandles(basePrice: basePrice)
        updateChartPoints()
        lastUpdated = Date()
    }
    
    private func generateMockCandles(basePrice: Double) -> [Candle] {
        var mockCandles: [Candle] = []
        let count = 100
        
        for i in 0..<count {
            let timestamp = Date().addingTimeInterval(-Double(i * 300)) // 5-minute intervals
            let volatility = Double.random(in: 0.002...0.01) * basePrice
            let trend = sin(Double(i) * 0.1) * volatility
            
            let open = basePrice + trend + Double.random(in: -volatility...volatility)
            let close = open + Double.random(in: -volatility/2...volatility/2)
            let high = max(open, close) + Double.random(in: 0...volatility/4)
            let low = min(open, close) - Double.random(in: 0...volatility/4)
            let volume = Double.random(in: 100...1000)
            
            let candle = Candle(
                openTime: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
            mockCandles.append(candle)
        }
        
        return mockCandles.reversed()
    }
    
    private func updatePriceInfo() {
        guard let lastCandle = candles.last,
              candles.count >= 2 else { return }
        
        let previousCandle = candles[candles.count - 2]
        price = lastCandle.close
        priceChange = lastCandle.close - previousCandle.close
        priceChangePercent = (priceChange / previousCandle.close) * 100
    }
    
    private func updateChartPoints() {
        guard !candles.isEmpty else {
            chartPoints = []
            return
        }
        
        let closes = candles.suffix(100).map { $0.close }
        guard let maxPrice = closes.max(),
              let minPrice = closes.min(),
              maxPrice > minPrice else {
            chartPoints = []
            return
        }
        
        let priceRange = maxPrice - minPrice
        chartPoints = closes.enumerated().map { index, close in
            CGPoint(
                x: CGFloat(index) / CGFloat(closes.count - 1),
                y: CGFloat((close - minPrice) / priceRange)
            )
        }
    }
    
    // MARK: - Cleanup
    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - Chart Data Model
struct CandleData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}