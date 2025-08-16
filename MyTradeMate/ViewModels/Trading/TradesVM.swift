import Foundation
import Combine
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.mytrademate", category: "Trades")

enum TradeSortOption: String, CaseIterable, Identifiable {
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    case priceHighest = "Price (Highest)"
    case priceLowest = "Price (Lowest)"
    case quantityLargest = "Quantity (Largest)"
    case quantitySmallest = "Quantity (Smallest)"
    
    var id: String { rawValue }
}

enum TradeFilterOption: String, CaseIterable, Identifiable {
    case all = "All Trades"
    case buyOnly = "Long Only"
    case sellOnly = "Short Only"
    
    var id: String { rawValue }
}

@MainActor
final class TradesVM: ObservableObject {
    // MARK: - Published Properties
    @Published var openPositions: [Trade] = []
    @Published var recentFills: [Fill] = []
    @Published var totalPnL: Double = 0.0
    @Published var totalPnLPercent: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var filterOption: TradeFilterOption = .all
    @Published var sortOption: TradeSortOption = .dateNewest
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Computed Properties
    var totalPnLString: String {
        let sign = totalPnL >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", totalPnL))"
    }
    
    var totalPnLColor: Color {
        totalPnL >= 0 ? Accent.green : Accent.red
    }
    
    var hasOpenPositions: Bool {
        !openPositions.isEmpty
    }
    
    var trades: [Trade] {
        openPositions
    }
    
    var filteredTrades: [Trade] {
        var filtered = trades
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { trade in
                trade.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply side filter
        switch filterOption {
        case .all:
            break
        case .buyOnly:
            filtered = filtered.filter { $0.side == .long }
        case .sellOnly:
            filtered = filtered.filter { $0.side == .short }
        }
        
        // Apply sorting
        switch sortOption {
        case .dateNewest:
            filtered.sort { $0.timestamp > $1.timestamp }
        case .dateOldest:
            filtered.sort { $0.timestamp < $1.timestamp }
        case .priceHighest:
            filtered.sort { $0.currentPrice > $1.currentPrice }
        case .priceLowest:
            filtered.sort { $0.currentPrice < $1.currentPrice }
        case .quantityLargest:
            filtered.sort { $0.size > $1.size }
        case .quantitySmallest:
            filtered.sort { $0.size < $1.size }
        }
        
        return filtered
    }
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadInitialData()
        startAutoRefresh()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Observe position updates
        NotificationCenter.default.publisher(for: .init("PositionUpdated"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        refreshData()
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updatePnL()
        }
    }
    
    // MARK: - Data Management
    func refreshData() {
        isLoading = true
        
        Task {
            do {
                if AppSettings.shared.demoMode {
                    // Generate demo trades
                    await loadDemoData()
                } else {
                    // Load real trades from exchange
                    await loadRealTrades()
                }
                
                await MainActor.run {
                    self.updatePnL()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                logger.error("Failed to load trades: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadDemoData() async {
        // Generate demo positions
        let demoPositions = [
            Trade(
                id: UUID().uuidString,
                symbol: "BTCUSDT",
                side: .long,
                size: 0.01,
                entryPrice: 44500,
                currentPrice: 45000,
                leverage: 1,
                timestamp: Date().addingTimeInterval(-3600)
            ),
            Trade(
                id: UUID().uuidString,
                symbol: "ETHUSD",
                side: .short,
                size: 0.1,
                entryPrice: 2250,
                currentPrice: 2230,
                leverage: 2,
                timestamp: Date().addingTimeInterval(-7200)
            )
        ]
        
        // Generate demo fills
        let demoFills = [
            Fill(
                id: UUID().uuidString,
                symbol: "BTCUSDT",
                side: .buy,
                size: 0.01,
                price: 44500,
                fee: 0.45,
                timestamp: Date().addingTimeInterval(-3600)
            ),
            Fill(
                id: UUID().uuidString,
                symbol: "ETHUSD",
                side: .sell,
                size: 0.1,
                price: 2250,
                fee: 0.23,
                timestamp: Date().addingTimeInterval(-7200)
            ),
            Fill(
                id: UUID().uuidString,
                symbol: "BTCUSDT",
                side: .sell,
                size: 0.005,
                price: 45200,
                fee: 0.23,
                timestamp: Date().addingTimeInterval(-1800)
            )
        ]
        
        await MainActor.run {
            self.openPositions = demoPositions
            self.recentFills = demoFills
        }
    }
    
    private func loadRealTrades() async {
        // TODO: Implement real trade loading from exchange
        logger.info("Loading real trades from exchange")
    }
    
    private func updatePnL() {
        let total = openPositions.reduce(0) { $0 + $1.pnl }
        let totalPercent = openPositions.reduce(0) { $0 + $1.pnlPercent } / Double(max(1, openPositions.count))
        
        totalPnL = total
        totalPnLPercent = totalPercent
    }
    
    // MARK: - Trading Actions
    func closePosition(_ trade: Trade) {
        logger.info("Closing position: \(trade.id)")
        
        Haptics.impact(.medium)
        
        if AppSettings.shared.confirmTrades {
            // Show confirmation
            logger.info("Close position confirmation required")
        } else {
            // Close immediately
            executeClose(trade)
        }
    }
    
    private func executeClose(_ trade: Trade) {
        // Remove from open positions
        openPositions.removeAll { $0.id == trade.id }
        
        // Add to recent fills
        let fill = Fill(
            id: UUID().uuidString,
            symbol: trade.symbol,
            side: trade.side == .long ? .sell : .buy,
            size: trade.size,
            price: trade.currentPrice,
            fee: trade.size * trade.currentPrice * 0.001,
            timestamp: Date()
        )
        
        recentFills.insert(fill, at: 0)
        
        // Keep only recent 20 fills
        if recentFills.count > 20 {
            recentFills = Array(recentFills.prefix(20))
        }
        
        updatePnL()
        
        logger.info("Position closed: \(trade.symbol) - PnL: \(trade.pnlString)")
    }
    
    func closeAllPositions() {
        logger.info("Closing all positions")
        
        Haptics.impact(.heavy)
        
        for position in openPositions {
            executeClose(position)
        }
    }
    
    // MARK: - Filtering and Sorting
    func updateSort(_ newSort: TradeSortOption) {
        sortOption = newSort
    }
    
    func updateFilter(_ newFilter: TradeFilterOption) {
        filterOption = newFilter
    }
    
    func updateSearch(_ newSearch: String) {
        searchText = newSearch
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - Trade Model
struct Trade: Identifiable {
    enum Side {
        case long, short
        
        var displayName: String {
            switch self {
            case .long: return "LONG"
            case .short: return "SHORT"
            }
        }
        
        var color: Color {
            switch self {
            case .long: return Accent.green
            case .short: return Accent.red
            }
        }
    }
    
    let id: String
    let symbol: String
    let side: Side
    let size: Double
    let entryPrice: Double
    var currentPrice: Double
    let leverage: Int
    let timestamp: Date
    
    var pnl: Double {
        let priceChange = currentPrice - entryPrice
        let pnlAmount = side == .long ? priceChange : -priceChange
        return pnlAmount * size * Double(leverage)
    }
    
    var pnlPercent: Double {
        let percent = ((currentPrice - entryPrice) / entryPrice) * 100
        return side == .long ? percent : -percent
    }
    
    var pnlString: String {
        let sign = pnl >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", pnl))"
    }
    
    var pnlPercentString: String {
        let sign = pnlPercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", pnlPercent))%"
    }
    
    var sizeString: String {
        return String(format: "%.4f", size)
    }
    
    var entryPriceString: String {
        return "$\(String(format: "%.2f", entryPrice))"
    }
    
    var currentPriceString: String {
        return "$\(String(format: "%.2f", currentPrice))"
    }
}

// MARK: - Fill Model
struct Fill: Identifiable {
    enum Side {
        case buy, sell
        
        var displayName: String {
            switch self {
            case .buy: return "BUY"
            case .sell: return "SELL"
            }
        }
        
        var color: Color {
            switch self {
            case .buy: return Accent.green
            case .sell: return Accent.red
            }
        }
    }
    
    let id: String
    let symbol: String
    let side: Side
    let size: Double
    let price: Double
    let fee: Double
    let timestamp: Date
    
    var priceString: String {
        return "$\(String(format: "%.2f", price))"
    }
    
    var sizeString: String {
        return String(format: "%.4f", size)
    }
    
    var feeString: String {
        return "$\(String(format: "%.4f", fee))"
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
