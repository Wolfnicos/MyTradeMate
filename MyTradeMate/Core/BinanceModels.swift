import Foundation

// MARK: - Binance API Models
enum BinanceModels {
    struct KlineData: Codable {
        let openTime: Int64
        let open: String
        let high: String
        let low: String
        let close: String
        let volume: String
        let closeTime: Int64
        let quoteVolume: String
        let trades: Int
        let takerBuyBaseVolume: String
        let takerBuyQuoteVolume: String
        
        enum CodingKeys: Int, CodingKey {
            case openTime = 0
            case open = 1
            case high = 2
            case low = 3
            case close = 4
            case volume = 5
            case closeTime = 6
            case quoteVolume = 7
            case trades = 8
            case takerBuyBaseVolume = 9
            case takerBuyQuoteVolume = 10
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
                timestamp: Date(timeIntervalSince1970: TimeInterval(openTime / 1000)),
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
        }
    }
    
    struct AccountInfo: Codable {
        let makerCommission: Int
        let takerCommission: Int
        let buyerCommission: Int
        let sellerCommission: Int
        let canTrade: Bool
        let canWithdraw: Bool
        let canDeposit: Bool
        let updateTime: Int64
        let accountType: String
        let balances: [Balance]
        
        struct Balance: Codable {
            let asset: String
            let free: String
            let locked: String
            
            func toAccountBalance() -> Account.Balance? {
                guard let free = Decimal(string: free),
                      let locked = Decimal(string: locked) else {
                    return nil
                }
                
                return Account.Balance(
                    asset: asset,
                    free: free,
                    locked: locked
                )
            }
        }
    }
    
    struct OrderResponse: Codable {
        let symbol: String
        let orderId: Int64
        let clientOrderId: String
        let transactTime: Int64
        let price: String
        let origQty: String
        let executedQty: String
        let status: String
        let timeInForce: String
        let type: String
        let side: String
        
        func toOrder() -> Order? {
            guard let price = Decimal(string: price),
                  let quantity = Decimal(string: origQty),
                  let filledQty = Decimal(string: executedQty),
                  let side = Order.Side(rawValue: side.lowercased()),
                  let type = Order.OrderType(rawValue: type.lowercased()),
                  let status = Order.Status(rawValue: status.lowercased()),
                  let timeInForce = Order.TimeInForce(rawValue: timeInForce.lowercased()) else {
                return nil
            }
            
            var order = Order(
                symbol: symbol,
                side: side,
                type: type,
                quantity: quantity,
                price: price,
                exchange: .binance,
                timeInForce: timeInForce
            )
            
            order.status = status
            order.filledQuantity = filledQty
            
            return order
        }
    }
    
    // WebSocket message models
    struct WSMessage: Codable {
        let stream: String
        let data: WSData
    }
    
    struct WSData: Codable {
        let e: String  // Event type
        let E: Int64  // Event time
        let s: String // Symbol
        let k: WSKline?
        
        struct WSKline: Codable {
            let t: Int64   // Kline start time
            let T: Int64   // Kline close time
            let s: String  // Symbol
            let i: String  // Interval
            let o: String  // Open price
            let h: String  // High price
            let l: String  // Low price
            let c: String  // Close price
            let v: String  // Base asset volume
            let x: Bool    // Is this kline closed?
        }
    }
}
