import Foundation

enum Exchange: String, CaseIterable, Sendable {
    case binance = "Binance"
    case kraken = "Kraken"
}

actor MarketDataService {
    private var client: ExchangeClient
    private var binance = BinanceClient()
    private var kraken = KrakenClient()
    
    init(defaultExchange: Exchange = .binance) {
        switch defaultExchange {
        case .binance: client = binance
        case .kraken: client = kraken
        }
    }
    
    func switchExchange(_ ex: Exchange) {
        Task { await client.disconnectTickers() }
        switch ex {
        case .binance: client = binance
        case .kraken: client = kraken
        }
    }
    
    func connect(symbols: [String]) async throws {
        try await client.connectTickers(symbols: symbols)
    }
    
    func disconnect() async {
        await client.disconnectTickers()
    }
    
    var stream: AsyncStream<Ticker> { client.tickerStream }
}