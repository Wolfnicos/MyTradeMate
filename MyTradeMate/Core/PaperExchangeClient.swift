import Foundation

class PaperExchangeClient: ExchangeClient {
    let id: ExchangeID = .binance // Use Binance format for paper trading
    private var equity: Double = 10_000
    private var cash: Double = 10_000
    private var positions: [Position] = []
    private var lastTicker: Ticker?
    
    private var continuation: AsyncStream<Ticker>.Continuation?
    lazy var liveTickerStream: AsyncStream<Ticker> = {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }()
    
    // MARK: - WebSocket Methods
    
    func wsConnect(symbol: String) async {
        // Simulate price updates using deterministic random walk
        Task {
            var price = 30_000.0 // Starting BTC price
            var time = Date()
            let volatility = 0.001 // 0.1% per tick
            var seed: UInt64 = 42
            
            while !Task.isCancelled {
                // Deterministic random walk
                var generator = SeededRandomNumberGenerator(seed: seed)
                let change = Double.random(in: -volatility...volatility, using: &generator)
                price *= (1 + change)
                seed += 1
                
                let ticker = Ticker(
                    id: UUID(),
                    symbol: symbol,
                    price: price,
                    time: time
                )
                lastTicker = ticker
                continuation?.yield(ticker)
                
                time = time.addingTimeInterval(1)
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
    }
    
    func wsDisconnect() async {
        continuation?.finish()
    }
    
    // MARK: - Market Data
    
    func fetchCandles(symbol: String, interval: String, limit: Int) async throws -> [Candle] {
        var candles: [Candle] = []
        let now = Date()
        let intervalSeconds: TimeInterval
        
        switch interval {
        case "5m": intervalSeconds = 300
        case "1h": intervalSeconds = 3600
        case "4h": intervalSeconds = 14400
        default: intervalSeconds = 3600
        }
        
        var seed: UInt64 = 42
        var price = 30_000.0
        let volatility = 0.02 // 2% per candle
        
        for i in 0..<limit {
            var generator = SeededRandomNumberGenerator(seed: seed + UInt64(i))
            let change = Double.random(in: -volatility...volatility, using: &generator)
            price *= (1 + change)
            
            let openTime = now.addingTimeInterval(-Double(limit - i) * intervalSeconds)
            let high = price * (1 + Double.random(in: 0...0.005, using: &generator))
            let low = price * (1 - Double.random(in: 0...0.005, using: &generator))
            
            candles.append(Candle(
                openTime: openTime,
                open: price,
                high: high,
                low: low,
                close: price * (1 + Double.random(in: -0.002...0.002, using: &generator)),
                volume: Double.random(in: 100...1000, using: &generator)
            ))
        }
        
        return candles
    }
    
    // MARK: - Trading
    
    func createOrder(_ req: OrderRequest) async throws -> OrderFill {
        guard let ticker = lastTicker else {
            throw ExchangeError.invalidResponse
        }
        
        let fillPrice = req.price ?? ticker.price
        let cost = fillPrice * req.qty
        
        // Validate funds
        if req.side == .buy {
            guard cost <= cash else {
                throw ExchangeError.insufficientFunds
            }
            cash -= cost
        } else {
            guard let position = positions.first(where: { $0.symbol == req.symbol }),
                  position.qty >= req.qty else {
                throw ExchangeError.insufficientFunds
            }
        }
        
        // Update position
        updatePosition(symbol: req.symbol, qty: req.qty * (req.side == .buy ? 1 : -1), price: fillPrice)
        
        return OrderFill(
            orderId: UUID().uuidString,
            executedQty: req.qty,
            avgPrice: fillPrice,
            time: Date()
        )
    }
    
    func account() async throws -> Account {
        Account(
            equity: equity,
            cash: cash,
            positions: positions
        )
    }
    
    func supportsPaperTrading() -> Bool {
        true
    }
    
    // MARK: - Private Methods
    
    private func updatePosition(symbol: String, qty: Double, price: Double) {
        if let index = positions.firstIndex(where: { $0.symbol == symbol }) {
            var position = positions[index]
            let newQty = position.qty + qty
            
            if newQty > 0 {
                // Update existing position
                let newAvgPrice = ((position.avgPrice * position.qty) + (price * qty)) / newQty
                position = Position(symbol: symbol, qty: newQty, avgPrice: newAvgPrice)
                positions[index] = position
            } else {
                // Close position
                positions.remove(at: index)
            }
        } else if qty > 0 {
            // New position
            positions.append(Position(symbol: symbol, qty: qty, avgPrice: price))
        }
        
        // Update equity
        equity = cash + positions.reduce(0) { total, position in
            total + (position.qty * (lastTicker?.price ?? position.avgPrice))
        }
    }
}

// MARK: - Random Number Generator
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var seed: UInt64
    
    init(seed: UInt64) {
        self.seed = seed
    }
    
    mutating func next() -> UInt64 {
        seed = 6364136223846793005 &* seed &+ 1
        return seed
    }
}