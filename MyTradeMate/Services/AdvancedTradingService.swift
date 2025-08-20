import Foundation
import Combine
import OSLog

// MARK: - Advanced Trading Service

@MainActor
public final class AdvancedTradingService: ObservableObject {
    public static let shared = AdvancedTradingService()
    
    @Published public var activeOrders: [AdvancedOrder] = []
    @Published public var priceAlerts: [PriceAlert] = []
    @Published public var dcaOrders: [DCAOrder] = []
    @Published public var trailingStops: [TrailingStopOrder] = []
    
    private let logger = os.Logger(subsystem: "com.mytrademate", category: "AdvancedTrading")
    private var cancellables = Set<AnyCancellable>()
    private var priceMonitorTimer: Timer?
    
    private init() {
        setupPriceMonitoring()
        loadStoredOrders()
    }
    
    // MARK: - Advanced Order Types
    
    public func placeLimitOrder(
        symbol: String,
        side: OrderSide,
        amount: Double,
        limitPrice: Double
    ) async throws -> AdvancedOrder {
        logger.info("Placing limit order: \(side.rawValue) \(amount) \(symbol) at \(limitPrice)")
        
        let order = AdvancedOrder(
            id: UUID().uuidString,
            symbol: symbol,
            type: .limit(price: limitPrice),
            side: side,
            amount: amount,
            status: .pending,
            timestamp: Date()
        )
        
        activeOrders.append(order)
        saveOrders()
        
        return order
    }
    
    public func placeStopLossOrder(
        symbol: String,
        side: OrderSide,
        amount: Double,
        stopPrice: Double
    ) async throws -> AdvancedOrder {
        logger.info("Placing stop-loss order: \(side.rawValue) \(amount) \(symbol) at \(stopPrice)")
        
        let order = AdvancedOrder(
            id: UUID().uuidString,
            symbol: symbol,
            type: .stopLoss(stopPrice: stopPrice),
            side: side,
            amount: amount,
            status: .pending,
            timestamp: Date()
        )
        
        activeOrders.append(order)
        saveOrders()
        
        return order
    }
    
    public func placeTakeProfitOrder(
        symbol: String,
        side: OrderSide,
        amount: Double,
        targetPrice: Double
    ) async throws -> AdvancedOrder {
        logger.info("Placing take-profit order: \(side.rawValue) \(amount) \(symbol) at \(targetPrice)")
        
        let order = AdvancedOrder(
            id: UUID().uuidString,
            symbol: symbol,
            type: .takeProfit(targetPrice: targetPrice),
            side: side,
            amount: amount,
            status: .pending,
            timestamp: Date()
        )
        
        activeOrders.append(order)
        saveOrders()
        
        return order
    }
    
    public func placeOCOOrder(
        symbol: String,
        side: OrderSide,
        amount: Double,
        limitPrice: Double,
        stopPrice: Double
    ) async throws -> AdvancedOrder {
        logger.info("Placing OCO order: \(side.rawValue) \(amount) \(symbol) limit:\(limitPrice) stop:\(stopPrice)")
        
        let order = AdvancedOrder(
            id: UUID().uuidString,
            symbol: symbol,
            type: .oco(limitPrice: limitPrice, stopPrice: stopPrice),
            side: side,
            amount: amount,
            status: .pending,
            timestamp: Date()
        )
        
        activeOrders.append(order)
        saveOrders()
        
        return order
    }
    
    public func placeTrailingStopOrder(
        symbol: String,
        side: OrderSide,
        amount: Double,
        trailAmount: Double,
        trailPercent: Double? = nil
    ) async throws -> TrailingStopOrder {
        logger.info("Placing trailing stop: \(side.rawValue) \(amount) \(symbol) trail:\(trailAmount)")
        
        // Get current price to set initial stop
        let currentPrice = await getCurrentPrice(symbol: symbol)
        let initialStopPrice = side == .sell ? 
            currentPrice - trailAmount : 
            currentPrice + trailAmount
        
        let order = TrailingStopOrder(
            id: UUID().uuidString,
            symbol: symbol,
            side: side,
            amount: amount,
            trailAmount: trailAmount,
            trailPercent: trailPercent,
            currentStopPrice: initialStopPrice,
            highestPrice: currentPrice,
            lowestPrice: currentPrice,
            status: .active,
            timestamp: Date()
        )
        
        trailingStops.append(order)
        saveOrders()
        
        return order
    }
    
    // MARK: - Price Alerts
    
    public func createPriceAlert(
        symbol: String,
        targetPrice: Double,
        direction: AlertDirection,
        message: String? = nil
    ) -> PriceAlert {
        let alert = PriceAlert(
            id: UUID().uuidString,
            symbol: symbol,
            targetPrice: targetPrice,
            direction: direction,
            message: message ?? "Price alert for \(symbol)",
            isActive: true,
            timestamp: Date()
        )
        
        priceAlerts.append(alert)
        saveOrders()
        
        logger.info("Created price alert: \(symbol) \(direction.rawValue) \(targetPrice)")
        
        return alert
    }
    
    public func removePriceAlert(id: String) {
        priceAlerts.removeAll { $0.id == id }
        saveOrders()
        logger.info("Removed price alert: \(id)")
    }
    
    // MARK: - DCA (Dollar-Cost Averaging)
    
    public func createDCAOrder(
        symbol: String,
        totalAmount: Double,
        frequency: DCAFrequency,
        numberOfOrders: Int
    ) -> DCAOrder {
        let amountPerOrder = totalAmount / Double(numberOfOrders)
        
        let dcaOrder = DCAOrder(
            id: UUID().uuidString,
            symbol: symbol,
            totalAmount: totalAmount,
            amountPerOrder: amountPerOrder,
            frequency: frequency,
            numberOfOrders: numberOfOrders,
            executedOrders: 0,
            nextExecutionDate: calculateNextExecutionDate(frequency: frequency),
            isActive: true,
            timestamp: Date()
        )
        
        dcaOrders.append(dcaOrder)
        saveOrders()
        
        logger.info("Created DCA order: \(symbol) \(totalAmount) over \(numberOfOrders) orders")
        
        return dcaOrder
    }
    
    public func pauseDCAOrder(id: String) {
        if let index = dcaOrders.firstIndex(where: { $0.id == id }) {
            dcaOrders[index].isActive = false
            saveOrders()
            logger.info("Paused DCA order: \(id)")
        }
    }
    
    public func resumeDCAOrder(id: String) {
        if let index = dcaOrders.firstIndex(where: { $0.id == id }) {
            dcaOrders[index].isActive = true
            saveOrders()
            logger.info("Resumed DCA order: \(id)")
        }
    }
    
    // MARK: - Order Management
    
    public func cancelOrder(id: String) async throws {
        if let index = activeOrders.firstIndex(where: { $0.id == id }) {
            activeOrders[index].status = .cancelled
            saveOrders()
            logger.info("Cancelled order: \(id)")
        }
        
        if let index = trailingStops.firstIndex(where: { $0.id == id }) {
            trailingStops[index].status = .cancelled
            saveOrders()
            logger.info("Cancelled trailing stop: \(id)")
        }
    }
    
    public func modifyOrder(id: String, newPrice: Double) async throws {
        if let index = activeOrders.firstIndex(where: { $0.id == id }) {
            var order = activeOrders[index]
            
            switch order.type {
            case .limit(_):
                order.type = .limit(price: newPrice)
            case .stopLoss(_):
                order.type = .stopLoss(stopPrice: newPrice)
            case .takeProfit(_):
                order.type = .takeProfit(targetPrice: newPrice)
            case .oco(let limitPrice, _):
                order.type = .oco(limitPrice: limitPrice, stopPrice: newPrice)
            default:
                throw TradingError.cannotModifyOrderType
            }
            
            activeOrders[index] = order
            saveOrders()
            logger.info("Modified order: \(id) new price: \(newPrice)")
        }
    }
    
    // MARK: - Price Monitoring
    
    private func setupPriceMonitoring() {
        // Monitor prices every 2 seconds
        priceMonitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkOrderTriggers()
                await self?.updateTrailingStops()
                self?.checkPriceAlerts()
                await self?.executeDCAOrders()
            }
        }
        
        // Listen for price updates
        NotificationCenter.default.publisher(for: .priceUpdate)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handlePriceUpdate(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkOrderTriggers() async {
        for (index, order) in activeOrders.enumerated() {
            guard order.status == .pending else { continue }
            
            let currentPrice = await getCurrentPrice(symbol: order.symbol)
            var shouldExecute = false
            
            switch order.type {
            case .limit(let price):
                shouldExecute = (order.side == .buy && currentPrice <= price) ||
                               (order.side == .sell && currentPrice >= price)
                
            case .stopLoss(let stopPrice):
                shouldExecute = (order.side == .buy && currentPrice >= stopPrice) ||
                               (order.side == .sell && currentPrice <= stopPrice)
                
            case .takeProfit(let targetPrice):
                shouldExecute = (order.side == .buy && currentPrice <= targetPrice) ||
                               (order.side == .sell && currentPrice >= targetPrice)
                
            case .oco(let limitPrice, let stopPrice):
                let limitTriggered = (order.side == .buy && currentPrice <= limitPrice) ||
                                    (order.side == .sell && currentPrice >= limitPrice)
                let stopTriggered = (order.side == .buy && currentPrice >= stopPrice) ||
                                   (order.side == .sell && currentPrice <= stopPrice)
                shouldExecute = limitTriggered || stopTriggered
                
            default:
                continue
            }
            
            if shouldExecute {
                await executeOrder(index: index, currentPrice: currentPrice)
            }
        }
    }
    
    private func updateTrailingStops() async {
        for (index, order) in trailingStops.enumerated() {
            guard order.status == .active else { continue }
            
            let currentPrice = await getCurrentPrice(symbol: order.symbol)
            var updatedOrder = order
            
            if order.side == .sell {
                // For sell orders, trail the stop up as price increases
                if currentPrice > order.highestPrice {
                    updatedOrder.highestPrice = currentPrice
                    updatedOrder.currentStopPrice = currentPrice - order.trailAmount
                }
                
                // Check if stop should trigger
                if currentPrice <= order.currentStopPrice {
                    await executeTrailingStop(index: index, currentPrice: currentPrice)
                    continue
                }
            } else {
                // For buy orders, trail the stop down as price decreases
                if currentPrice < order.lowestPrice {
                    updatedOrder.lowestPrice = currentPrice
                    updatedOrder.currentStopPrice = currentPrice + order.trailAmount
                }
                
                // Check if stop should trigger
                if currentPrice >= order.currentStopPrice {
                    await executeTrailingStop(index: index, currentPrice: currentPrice)
                    continue
                }
            }
            
            trailingStops[index] = updatedOrder
        }
        
        saveOrders()
    }
    
    private func checkPriceAlerts() {
        for (index, alert) in priceAlerts.enumerated() {
            guard alert.isActive else { continue }
            
            Task {
                let currentPrice = await getCurrentPrice(symbol: alert.symbol)
                var shouldTrigger = false
                
                switch alert.direction {
                case .above:
                    shouldTrigger = currentPrice >= alert.targetPrice
                case .below:
                    shouldTrigger = currentPrice <= alert.targetPrice
                }
                
                if shouldTrigger {
                    await MainActor.run {
                        self.triggerPriceAlert(index: index, currentPrice: currentPrice)
                    }
                }
            }
        }
    }
    
    private func executeDCAOrders() async {
        let now = Date()
        
        for (index, dcaOrder) in dcaOrders.enumerated() {
            guard dcaOrder.isActive && 
                  dcaOrder.executedOrders < dcaOrder.numberOfOrders &&
                  now >= dcaOrder.nextExecutionDate else { continue }
            
            // Execute DCA order
            do {
                _ = try await TradingService.shared.placeOrder(
                    symbol: dcaOrder.symbol,
                    side: .buy,
                    amount: dcaOrder.amountPerOrder
                )
                
                // Update DCA order
                var updatedOrder = dcaOrder
                updatedOrder.executedOrders += 1
                updatedOrder.nextExecutionDate = calculateNextExecutionDate(frequency: dcaOrder.frequency)
                
                if updatedOrder.executedOrders >= updatedOrder.numberOfOrders {
                    updatedOrder.isActive = false
                    logger.info("DCA order completed: \(dcaOrder.id)")
                }
                
                dcaOrders[index] = updatedOrder
                saveOrders()
                
                logger.info("Executed DCA order: \(dcaOrder.symbol) \(dcaOrder.amountPerOrder)")
                
            } catch {
                logger.error("Failed to execute DCA order: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func executeOrder(index: Int, currentPrice: Double) async {
        let order = activeOrders[index]
        
        do {
            _ = try await TradingService.shared.placeOrder(
                symbol: order.symbol,
                side: order.side,
                amount: order.amount,
                price: currentPrice
            )
            
            activeOrders[index].status = .filled
            activeOrders[index].fillPrice = currentPrice
            saveOrders()
            
            logger.info("Executed order: \(order.id) at \(currentPrice)")
            
            // Send notification
            NotificationService.shared.sendTradeNotification(
                title: "Order Executed",
                body: "\(order.side.rawValue) \(order.amount) \(order.symbol) at \(String(format: "%.2f", currentPrice))",
                symbol: order.symbol
            )
            
        } catch {
            logger.error("Failed to execute order: \(error)")
            activeOrders[index].status = .rejected
            saveOrders()
        }
    }
    
    private func executeTrailingStop(index: Int, currentPrice: Double) async {
        let order = trailingStops[index]
        
        do {
            _ = try await TradingService.shared.placeOrder(
                symbol: order.symbol,
                side: order.side,
                amount: order.amount,
                price: currentPrice
            )
            
            trailingStops[index].status = .executed
            saveOrders()
            
            logger.info("Executed trailing stop: \(order.id) at \(currentPrice)")
            
            // Send notification
            NotificationService.shared.sendTradeNotification(
                title: "Trailing Stop Executed",
                body: "\(order.side.rawValue) \(order.amount) \(order.symbol) at \(String(format: "%.2f", currentPrice))",
                symbol: order.symbol
            )
            
        } catch {
            logger.error("Failed to execute trailing stop: \(error)")
        }
    }
    
    private func triggerPriceAlert(index: Int, currentPrice: Double) {
        let alert = priceAlerts[index]
        
        // Send notification
        NotificationService.shared.sendPriceAlert(
            symbol: alert.symbol,
            currentPrice: currentPrice,
            targetPrice: alert.targetPrice,
            direction: alert.direction == .above ? .above : .below
        )
        
        // Deactivate alert
        priceAlerts[index].isActive = false
        saveOrders()
        
        logger.info("Triggered price alert: \(alert.symbol) \(alert.direction.rawValue) \(alert.targetPrice)")
    }
    
    private func getCurrentPrice(symbol: String) async -> Double {
        // Get current price from WebSocketService or API
        return WebSocketService.shared.priceUpdates[symbol] ?? 45000.0
    }
    
    private func calculateNextExecutionDate(frequency: DCAFrequency) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        }
    }
    
    private func handlePriceUpdate(_ notification: Notification) async {
        // Price updates are handled by the timer-based monitoring
        // This could be used for more immediate responses if needed
    }
    
    // MARK: - Data Persistence
    
    private func saveOrders() {
        // Save to UserDefaults for demo (in production, use Core Data)
        if let ordersData = try? JSONEncoder().encode(activeOrders) {
            UserDefaults.standard.set(ordersData, forKey: "advanced_orders")
        }
        
        if let alertsData = try? JSONEncoder().encode(priceAlerts) {
            UserDefaults.standard.set(alertsData, forKey: "price_alerts")
        }
        
        if let dcaData = try? JSONEncoder().encode(dcaOrders) {
            UserDefaults.standard.set(dcaData, forKey: "dca_orders")
        }
        
        if let trailingData = try? JSONEncoder().encode(trailingStops) {
            UserDefaults.standard.set(trailingData, forKey: "trailing_stops")
        }
    }
    
    private func loadStoredOrders() {
        // Load from UserDefaults
        if let ordersData = UserDefaults.standard.data(forKey: "advanced_orders"),
           let orders = try? JSONDecoder().decode([AdvancedOrder].self, from: ordersData) {
            activeOrders = orders
        }
        
        if let alertsData = UserDefaults.standard.data(forKey: "price_alerts"),
           let alerts = try? JSONDecoder().decode([PriceAlert].self, from: alertsData) {
            priceAlerts = alerts
        }
        
        if let dcaData = UserDefaults.standard.data(forKey: "dca_orders"),
           let dca = try? JSONDecoder().decode([DCAOrder].self, from: dcaData) {
            dcaOrders = dca
        }
        
        if let trailingData = UserDefaults.standard.data(forKey: "trailing_stops"),
           let trailing = try? JSONDecoder().decode([TrailingStopOrder].self, from: trailingData) {
            trailingStops = trailing
        }
    }
}

// MARK: - Supporting Types

public struct AdvancedOrder: Identifiable, Codable {
    public let id: String
    public let symbol: String
    public var type: AdvancedOrderType
    public let side: OrderSide
    public let amount: Double
    public var status: AdvancedOrderStatus
    public var fillPrice: Double?
    public let timestamp: Date
    
    public init(id: String, symbol: String, type: AdvancedOrderType, side: OrderSide, amount: Double, status: AdvancedOrderStatus, timestamp: Date) {
        self.id = id
        self.symbol = symbol
        self.type = type
        self.side = side
        self.amount = amount
        self.status = status
        self.timestamp = timestamp
    }
}

public enum AdvancedOrderType: Codable {
    case market
    case limit(price: Double)
    case stopLoss(stopPrice: Double)
    case takeProfit(targetPrice: Double)
    case oco(limitPrice: Double, stopPrice: Double)
}

public enum AdvancedOrderStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case filled = "FILLED"
    case cancelled = "CANCELLED"
    case rejected = "REJECTED"
    case partiallyFilled = "PARTIALLY_FILLED"
}

public struct TrailingStopOrder: Identifiable, Codable {
    public let id: String
    public let symbol: String
    public let side: OrderSide
    public let amount: Double
    public let trailAmount: Double
    public let trailPercent: Double?
    public var currentStopPrice: Double
    public var highestPrice: Double
    public var lowestPrice: Double
    public var status: TrailingStopStatus
    public let timestamp: Date
    
    public init(id: String, symbol: String, side: OrderSide, amount: Double, trailAmount: Double, trailPercent: Double?, currentStopPrice: Double, highestPrice: Double, lowestPrice: Double, status: TrailingStopStatus, timestamp: Date) {
        self.id = id
        self.symbol = symbol
        self.side = side
        self.amount = amount
        self.trailAmount = trailAmount
        self.trailPercent = trailPercent
        self.currentStopPrice = currentStopPrice
        self.highestPrice = highestPrice
        self.lowestPrice = lowestPrice
        self.status = status
        self.timestamp = timestamp
    }
}

public enum TrailingStopStatus: String, Codable, CaseIterable {
    case active = "ACTIVE"
    case executed = "EXECUTED"
    case cancelled = "CANCELLED"
}

public struct PriceAlert: Identifiable, Codable {
    public let id: String
    public let symbol: String
    public let targetPrice: Double
    public let direction: AlertDirection
    public let message: String
    public var isActive: Bool
    public let timestamp: Date
    
    public init(id: String, symbol: String, targetPrice: Double, direction: AlertDirection, message: String, isActive: Bool, timestamp: Date) {
        self.id = id
        self.symbol = symbol
        self.targetPrice = targetPrice
        self.direction = direction
        self.message = message
        self.isActive = isActive
        self.timestamp = timestamp
    }
}

public enum AlertDirection: String, Codable, CaseIterable {
    case above = "ABOVE"
    case below = "BELOW"
}

public struct DCAOrder: Identifiable, Codable {
    public let id: String
    public let symbol: String
    public let totalAmount: Double
    public let amountPerOrder: Double
    public let frequency: DCAFrequency
    public let numberOfOrders: Int
    public var executedOrders: Int
    public var nextExecutionDate: Date
    public var isActive: Bool
    public let timestamp: Date
    
    public init(id: String, symbol: String, totalAmount: Double, amountPerOrder: Double, frequency: DCAFrequency, numberOfOrders: Int, executedOrders: Int, nextExecutionDate: Date, isActive: Bool, timestamp: Date) {
        self.id = id
        self.symbol = symbol
        self.totalAmount = totalAmount
        self.amountPerOrder = amountPerOrder
        self.frequency = frequency
        self.numberOfOrders = numberOfOrders
        self.executedOrders = executedOrders
        self.nextExecutionDate = nextExecutionDate
        self.isActive = isActive
        self.timestamp = timestamp
    }
}

public enum DCAFrequency: String, Codable, CaseIterable {
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case monthly = "MONTHLY"
}

public enum TradingError: LocalizedError {
    case cannotModifyOrderType
    case orderNotFound
    case invalidOrderParameters
    
    public var errorDescription: String? {
        switch self {
        case .cannotModifyOrderType:
            return "Cannot modify this order type"
        case .orderNotFound:
            return "Order not found"
        case .invalidOrderParameters:
            return "Invalid order parameters"
        }
    }
}