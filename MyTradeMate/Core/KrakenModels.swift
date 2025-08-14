import Foundation

enum KrakenModels {
    // Kraken uses a unique response format with an errors array and result object
    struct Response<T: Codable>: Codable {
        let error: [String]
        let result: T?
        
        func validate() throws -> T {
            if !error.isEmpty {
                throw ExchangeError.serverError(error.joined(separator: ", "))
            }
            
            guard let result = result else {
                throw ExchangeError.serverError("Empty response")
            }
            
            return result
        }
    }
    
    struct OHLC: Codable {
        let time: Double
        let open: String
        let high: String
        let low: String
        let close: String
        let vwap: String
        let volume: String
        let count: Int
        
        enum CodingKeys: Int, CodingKey {
            case time = 0
            case open = 1
            case high = 2
            case low = 3
            case close = 4
            case vwap = 5
            case volume = 6
            case count = 7
        }
        
        func toCandle(symbol: String, timeframe: TimeFrame) -> Candle? {
            guard let open = Decimal(string: open),
                  let high = Decimal(string: high),
                  let low = Decimal(string: low),
                  let close = Decimal(string: close),
                  let volume = Decimal(string: volume) else {
                return nil
            }
            
            return Candle(
                symbol: symbol,
                timeframe: timeframe,
                timestamp: Date(timeIntervalSince1970: time),
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
        }
    }
    
    struct OHLCResponse: Codable {
        let last: Int
        let pairs: [String: [OHLC]]
        
        enum CodingKeys: String, CodingKey {
            case last
            case pairs
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.last = try container.decode(Int.self, forKey: .last)
            
            // Decode dynamic pair keys
            var pairs: [String: [OHLC]] = [:]
            let pairsContainer = try decoder.container(keyedBy: DynamicCodingKeys.self)
            for key in pairsContainer.allKeys {
                if key.stringValue != "last" {
                    pairs[key.stringValue] = try pairsContainer.decode([OHLC].self, forKey: key)
                }
            }
            self.pairs = pairs
        }
    }
    
    struct Balance: Codable {
        let asset: String
        let balance: String
        let hold: String
        
        func toAccountBalance() -> Account.Balance? {
            guard let free = Decimal(string: balance),
                  let locked = Decimal(string: hold) else {
                return nil
            }
            
            return Account.Balance(
                asset: asset,
                free: free,
                locked: locked
            )
        }
    }
    
    struct OrderInfo: Codable {
        let refid: String?
        let userref: Int?
        let status: String
        let opentm: Double
        let starttm: Double
        let expiretm: Double
        let descr: OrderDescription
        let vol: String
        let vol_exec: String
        let cost: String
        let fee: String
        let price: String
        let stopprice: String?
        let limitprice: String?
        let misc: String
        let oflags: String
        
        struct OrderDescription: Codable {
            let pair: String
            let type: String
            let ordertype: String
            let price: String
            let price2: String
            let leverage: String
            let order: String
            let close: String?
        }
        
        func toOrder() -> Order? {
            guard let quantity = Decimal(string: vol),
                  let filledQty = Decimal(string: vol_exec),
                  let price = Decimal(string: descr.price),
                  let side = Order.Side(rawValue: descr.type.lowercased()),
                  let type = mapOrderType(descr.ordertype),
                  let status = mapOrderStatus(status) else {
                return nil
            }
            
            var order = Order(
                symbol: descr.pair,
                side: side,
                type: type,
                quantity: quantity,
                price: price,
                exchange: .kraken
            )
            
            order.status = status
            order.filledQuantity = filledQty
            
            if let stopPrice = stopprice.flatMap({ Decimal(string: $0) }) {
                order.stopPrice = stopPrice
            }
            
            return order
        }
        
        private func mapOrderType(_ type: String) -> Order.OrderType? {
            switch type.lowercased() {
            case "market": return .market
            case "limit": return .limit
            case "stop-loss": return .stopLoss
            case "take-profit": return .takeProfit
            default: return nil
            }
        }
        
        private func mapOrderStatus(_ status: String) -> Order.Status? {
            switch status.lowercased() {
            case "pending": return .new
            case "open": return .new
            case "closed": return .filled
            case "canceled": return .cancelled
            case "expired": return .expired
            default: return nil
            }
        }
    }
    
    // WebSocket message models
    struct WSMessage: Codable {
        let event: String
        let pair: [String]?
        let subscription: Subscription?
        let status: String?
        let errorMessage: String?
        
        struct Subscription: Codable {
            let name: String
            let interval: Int?
        }
    }
    
    struct WSOHLCUpdate: Codable {
        let channelID: Int
        let data: [OHLCData]
        let channelName: String
        let pair: String
        
        struct OHLCData: Codable {
            let time: Double
            let etime: Double
            let open: String
            let high: String
            let low: String
            let close: String
            let vwap: String
            let volume: String
            let count: Int
        }
    }
}

// MARK: - Dynamic Coding Keys
private struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        return nil
    }
}
