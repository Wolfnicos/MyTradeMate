import Foundation
import Combine
import OSLog

// MARK: - Markets Service

@MainActor
public final class MarketsService: ObservableObject {
    public static let shared = MarketsService()
    
    @Published public var allMarkets: [MarketData] = []
    @Published public var topGainers: [MarketData] = []
    @Published public var topLosers: [MarketData] = []
    @Published public var highVolume: [MarketData] = []
    @Published public var trending: [MarketData] = []
    @Published public var favorites: Set<String> = []
    @Published public var heatmapData: [HeatmapItem] = []
    
    @Published public var isLoading = false
    @Published public var lastUpdated: Date = Date()
    
    private let logger = Logger(subsystem: "com.mytrademate", category: "Markets")
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // Filters
    @Published public var selectedCategory: MarketCategory = .all
    @Published public var selectedSortBy: SortOption = .marketCap
    @Published public var searchQuery: String = ""
    @Published public var priceRange: PriceRange = .all
    @Published public var volumeFilter: VolumeFilter = .all
    
    private init() {
        loadFavorites()
        setupAutoRefresh()
        loadInitialData()
    }
    
    // MARK: - Data Loading
    
    public func refreshMarkets() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // In a real app, this would fetch from multiple exchanges
            let markets = await fetchMarketsData()
            
            allMarkets = markets
            updateDerivedData()
            lastUpdated = Date()
            
            logger.info("Markets data refreshed: \(markets.count) markets")
            
        } catch {
            logger.error("Failed to refresh markets: \(error)")
        }
    }
    
    private func fetchMarketsData() async -> [MarketData] {
        // Simulate API call with realistic crypto data
        return generateMockMarketData()
    }
    
    private func generateMockMarketData() -> [MarketData] {
        let cryptos = [
            ("BTC", "Bitcoin", 45000.0, 850_000_000_000),
            ("ETH", "Ethereum", 3200.0, 385_000_000_000),
            ("BNB", "Binance Coin", 420.0, 65_000_000_000),
            ("XRP", "Ripple", 0.65, 35_000_000_000),
            ("ADA", "Cardano", 1.25, 42_000_000_000),
            ("SOL", "Solana", 95.0, 42_000_000_000),
            ("DOT", "Polkadot", 28.0, 32_000_000_000),
            ("DOGE", "Dogecoin", 0.08, 11_000_000_000),
            ("AVAX", "Avalanche", 85.0, 31_000_000_000),
            ("SHIB", "Shiba Inu", 0.000025, 14_000_000_000),
            ("MATIC", "Polygon", 1.85, 17_000_000_000),
            ("LTC", "Litecoin", 180.0, 13_000_000_000),
            ("UNI", "Uniswap", 25.0, 19_000_000_000),
            ("LINK", "Chainlink", 28.5, 16_000_000_000),
            ("ATOM", "Cosmos", 32.0, 9_000_000_000),
            ("XLM", "Stellar", 0.35, 8_500_000_000),
            ("ALGO", "Algorand", 1.45, 10_000_000_000),
            ("VET", "VeChain", 0.045, 3_200_000_000),
            ("ICP", "Internet Computer", 45.0, 20_000_000_000),
            ("FIL", "Filecoin", 35.0, 15_000_000_000)
        ]
        
        return cryptos.map { symbol, name, basePrice, marketCap in
            let priceChange = Double.random(in: -15...15)
            let volumeMultiplier = Double.random(in: 0.5...3.0)
            let volume = Double(marketCap) * 0.1 * volumeMultiplier
            
            return MarketData(
                symbol: symbol,
                name: name,
                price: basePrice * (1 + priceChange / 100),
                priceChange24h: priceChange,
                volume24h: volume,
                marketCap: Double(marketCap),
                rank: cryptos.firstIndex(where: { $0.0 == symbol }) ?? 0 + 1,
                category: categorizeSymbol(symbol),
                lastUpdated: Date()
            )
        }
    }
    
    private func categorizeSymbol(_ symbol: String) -> MarketCategory {
        switch symbol {
        case "BTC", "ETH", "BNB", "XRP", "ADA":
            return .topCap
        case "SOL", "DOT", "AVAX", "MATIC", "ATOM":
            return .layer1
        case "UNI", "LINK":
            return .defi
        case "DOGE", "SHIB":
            return .meme
        default:
            return .altcoins
        }
    }
    
    private func updateDerivedData() {
        // Top gainers (sorted by 24h change, positive only)
        topGainers = allMarkets
            .filter { $0.priceChange24h > 0 }
            .sorted { $0.priceChange24h > $1.priceChange24h }
            .prefix(10)
            .map { $0 }
        
        // Top losers (sorted by 24h change, negative only)
        topLosers = allMarkets
            .filter { $0.priceChange24h < 0 }
            .sorted { $0.priceChange24h < $1.priceChange24h }
            .prefix(10)
            .map { $0 }
        
        // High volume (sorted by 24h volume)
        highVolume = allMarkets
            .sorted { $0.volume24h > $1.volume24h }
            .prefix(10)
            .map { $0 }
        
        // Trending (mix of volume and price change)
        trending = allMarkets
            .sorted { market1, market2 in
                let score1 = abs(market1.priceChange24h) * 0.7 + (market1.volume24h / 1_000_000_000) * 0.3
                let score2 = abs(market2.priceChange24h) * 0.7 + (market2.volume24h / 1_000_000_000) * 0.3
                return score1 > score2
            }
            .prefix(10)
            .map { $0 }
        
        // Generate heatmap data
        generateHeatmapData()
    }
    
    private func generateHeatmapData() {
        heatmapData = allMarkets.prefix(20).map { market in
            HeatmapItem(
                symbol: market.symbol,
                name: market.name,
                priceChange: market.priceChange24h,
                marketCap: market.marketCap,
                size: calculateHeatmapSize(marketCap: market.marketCap)
            )
        }
    }
    
    private func calculateHeatmapSize(marketCap: Double) -> HeatmapSize {
        if marketCap > 100_000_000_000 {
            return .large
        } else if marketCap > 10_000_000_000 {
            return .medium
        } else {
            return .small
        }
    }
    
    // MARK: - Filtering and Sorting
    
    public var filteredMarkets: [MarketData] {
        var filtered = allMarkets
        
        // Category filter
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { market in
                market.symbol.localizedCaseInsensitiveContains(searchQuery) ||
                market.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Price range filter
        switch priceRange {
        case .under1:
            filtered = filtered.filter { $0.price < 1.0 }
        case .range1to10:
            filtered = filtered.filter { $0.price >= 1.0 && $0.price < 10.0 }
        case .range10to100:
            filtered = filtered.filter { $0.price >= 10.0 && $0.price < 100.0 }
        case .over100:
            filtered = filtered.filter { $0.price >= 100.0 }
        case .all:
            break
        }
        
        // Volume filter
        switch volumeFilter {
        case .high:
            filtered = filtered.filter { $0.volume24h > 1_000_000_000 }
        case .medium:
            filtered = filtered.filter { $0.volume24h > 100_000_000 && $0.volume24h <= 1_000_000_000 }
        case .low:
            filtered = filtered.filter { $0.volume24h <= 100_000_000 }
        case .all:
            break
        }
        
        // Sort
        switch selectedSortBy {
        case .marketCap:
            filtered.sort { $0.marketCap > $1.marketCap }
        case .price:
            filtered.sort { $0.price > $1.price }
        case .priceChange:
            filtered.sort { $0.priceChange24h > $1.priceChange24h }
        case .volume:
            filtered.sort { $0.volume24h > $1.volume24h }
        case .name:
            filtered.sort { $0.name < $1.name }
        case .rank:
            filtered.sort { $0.rank < $1.rank }
        }
        
        return filtered
    }
    
    // MARK: - Favorites Management
    
    public func toggleFavorite(_ symbol: String) {
        if favorites.contains(symbol) {
            favorites.remove(symbol)
            logger.info("Removed \(symbol) from favorites")
        } else {
            favorites.insert(symbol)
            logger.info("Added \(symbol) to favorites")
        }
        saveFavorites()
    }
    
    public func isFavorite(_ symbol: String) -> Bool {
        return favorites.contains(symbol)
    }
    
    public var favoriteMarkets: [MarketData] {
        return allMarkets.filter { favorites.contains($0.symbol) }
    }
    
    // MARK: - Market Analysis
    
    public func getMarketOverview() -> MarketOverview {
        let totalMarketCap = allMarkets.reduce(0) { $0 + $1.marketCap }
        let totalVolume = allMarkets.reduce(0) { $0 + $1.volume24h }
        
        let gainers = allMarkets.filter { $0.priceChange24h > 0 }.count
        let losers = allMarkets.filter { $0.priceChange24h < 0 }.count
        let neutral = allMarkets.count - gainers - losers
        
        let btcDominance = allMarkets.first(where: { $0.symbol == "BTC" })?.marketCap ?? 0
        let dominancePercent = totalMarketCap > 0 ? (btcDominance / totalMarketCap) * 100 : 0
        
        return MarketOverview(
            totalMarketCap: totalMarketCap,
            totalVolume24h: totalVolume,
            btcDominance: dominancePercent,
            gainersCount: gainers,
            losersCount: losers,
            neutralCount: neutral,
            fearGreedIndex: calculateFearGreedIndex()
        )
    }
    
    private func calculateFearGreedIndex() -> Int {
        // Simplified fear & greed calculation based on market movements
        let avgChange = allMarkets.reduce(0) { $0 + $1.priceChange24h } / Double(allMarkets.count)
        let volatility = TechnicalIndicatorsService.shared.standardDeviation(
            values: allMarkets.map { $0.priceChange24h }
        )
        
        // Scale to 0-100 (0 = Extreme Fear, 100 = Extreme Greed)
        let baseScore = 50 + (avgChange * 2) // Price change influence
        let volatilityPenalty = volatility * 0.5 // High volatility = more fear
        
        let score = baseScore - volatilityPenalty
        return Int(max(0, min(100, score)))
    }
    
    // MARK: - Data Persistence
    
    private func saveFavorites() {
        let favoritesArray = Array(favorites)
        UserDefaults.standard.set(favoritesArray, forKey: "market_favorites")
    }
    
    private func loadFavorites() {
        if let favoritesArray = UserDefaults.standard.array(forKey: "market_favorites") as? [String] {
            favorites = Set(favoritesArray)
        }
    }
    
    // MARK: - Auto Refresh
    
    private func setupAutoRefresh() {
        // Refresh every 30 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshMarkets()
            }
        }
    }
    
    private func loadInitialData() {
        Task {
            await refreshMarkets()
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - Supporting Types

public struct MarketData: Identifiable, Codable {
    public let id = UUID()
    public let symbol: String
    public let name: String
    public let price: Double
    public let priceChange24h: Double
    public let volume24h: Double
    public let marketCap: Double
    public let rank: Int
    public let category: MarketCategory
    public let lastUpdated: Date
    
    public var priceChangePercent: Double {
        return priceChange24h
    }
    
    public var formattedPrice: String {
        if price < 0.01 {
            return String(format: "$%.6f", price)
        } else if price < 1.0 {
            return String(format: "$%.4f", price)
        } else {
            return String(format: "$%.2f", price)
        }
    }
    
    public var formattedMarketCap: String {
        return formatLargeNumber(marketCap)
    }
    
    public var formattedVolume: String {
        return formatLargeNumber(volume24h)
    }
    
    private func formatLargeNumber(_ number: Double) -> String {
        if number >= 1_000_000_000_000 {
            return String(format: "$%.2fT", number / 1_000_000_000_000)
        } else if number >= 1_000_000_000 {
            return String(format: "$%.2fB", number / 1_000_000_000)
        } else if number >= 1_000_000 {
            return String(format: "$%.2fM", number / 1_000_000)
        } else {
            return String(format: "$%.0f", number)
        }
    }
    
    public init(symbol: String, name: String, price: Double, priceChange24h: Double, volume24h: Double, marketCap: Double, rank: Int, category: MarketCategory, lastUpdated: Date) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.priceChange24h = priceChange24h
        self.volume24h = volume24h
        self.marketCap = marketCap
        self.rank = rank
        self.category = category
        self.lastUpdated = lastUpdated
    }
}

public enum MarketCategory: String, CaseIterable, Codable {
    case all = "All"
    case topCap = "Top Cap"
    case layer1 = "Layer 1"
    case defi = "DeFi"
    case meme = "Meme"
    case altcoins = "Altcoins"
    
    public var displayName: String {
        return rawValue
    }
}

public enum SortOption: String, CaseIterable {
    case marketCap = "Market Cap"
    case price = "Price"
    case priceChange = "24h Change"
    case volume = "Volume"
    case name = "Name"
    case rank = "Rank"
    
    public var displayName: String {
        return rawValue
    }
}

public enum PriceRange: String, CaseIterable {
    case all = "All Prices"
    case under1 = "Under $1"
    case range1to10 = "$1 - $10"
    case range10to100 = "$10 - $100"
    case over100 = "Over $100"
    
    public var displayName: String {
        return rawValue
    }
}

public enum VolumeFilter: String, CaseIterable {
    case all = "All Volume"
    case high = "High (>$1B)"
    case medium = "Medium ($100M-$1B)"
    case low = "Low (<$100M)"
    
    public var displayName: String {
        return rawValue
    }
}

public struct HeatmapItem: Identifiable {
    public let id = UUID()
    public let symbol: String
    public let name: String
    public let priceChange: Double
    public let marketCap: Double
    public let size: HeatmapSize
    
    public init(symbol: String, name: String, priceChange: Double, marketCap: Double, size: HeatmapSize) {
        self.symbol = symbol
        self.name = name
        self.priceChange = priceChange
        self.marketCap = marketCap
        self.size = size
    }
}

public enum HeatmapSize {
    case small
    case medium
    case large
}

public struct MarketOverview {
    public let totalMarketCap: Double
    public let totalVolume24h: Double
    public let btcDominance: Double
    public let gainersCount: Int
    public let losersCount: Int
    public let neutralCount: Int
    public let fearGreedIndex: Int
    
    public var fearGreedLabel: String {
        switch fearGreedIndex {
        case 0...24:
            return "Extreme Fear"
        case 25...44:
            return "Fear"
        case 45...55:
            return "Neutral"
        case 56...75:
            return "Greed"
        case 76...100:
            return "Extreme Greed"
        default:
            return "Unknown"
        }
    }
    
    public init(totalMarketCap: Double, totalVolume24h: Double, btcDominance: Double, gainersCount: Int, losersCount: Int, neutralCount: Int, fearGreedIndex: Int) {
        self.totalMarketCap = totalMarketCap
        self.totalVolume24h = totalVolume24h
        self.btcDominance = btcDominance
        self.gainersCount = gainersCount
        self.losersCount = losersCount
        self.neutralCount = neutralCount
        self.fearGreedIndex = fearGreedIndex
    }
}