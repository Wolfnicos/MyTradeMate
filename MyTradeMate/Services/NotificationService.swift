import Foundation
import UserNotifications
import Combine
import OSLog

// MARK: - Notification Service

@MainActor
public final class NotificationService: ObservableObject {
    public static let shared = NotificationService()
    
    @Published public var isAuthorized = false
    @Published public var notificationSettings: UNNotificationSettings?
    
    private let logger = Logger(subsystem: "com.mytrademate", category: "Notifications")
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAuthorizationStatus()
        setupNotificationObservers()
    }
    
    // MARK: - Authorization
    
    public func requestAuthorization() async throws {
        logger.info("Requesting notification authorization")
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .provisional]
        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        
        isAuthorized = granted
        
        if granted {
            logger.info("Notification authorization granted")
        } else {
            logger.warning("Notification authorization denied")
        }
        
        await updateNotificationSettings()
    }
    
    private func checkAuthorizationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.notificationSettings = settings
                self.isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            }
        }
    }
    
    private func updateNotificationSettings() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationSettings = settings
        isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }
    
    // MARK: - Trading Notifications
    
    public func sendTradeNotification(title: String, body: String, symbol: String? = nil) {
        guard isAuthorized else {
            logger.warning("Cannot send notification - not authorized")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        if let symbol = symbol {
            content.userInfo = ["symbol": symbol, "type": "trade"]
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate delivery
        )
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to send notification: \(error)")
            } else {
                self?.logger.info("Trade notification sent: \(title)")
            }
        }
    }
    
    public func sendPriceAlert(symbol: String, currentPrice: Double, targetPrice: Double, direction: PriceDirection) {
        let title = "Price Alert: \(symbol)"
        let body = "Price \(direction.description) \(String(format: "%.2f", targetPrice)). Current: \(String(format: "%.2f", currentPrice))"
        
        sendTradeNotification(title: title, body: body, symbol: symbol)
    }
    
    public func sendSignalNotification(signal: String, confidence: Double, symbol: String) {
        let title = "Trading Signal: \(signal)"
        let body = "\(symbol) - \(String(format: "%.0f", confidence * 100))% confidence"
        
        sendTradeNotification(title: title, body: body, symbol: symbol)
    }
    
    // MARK: - Scheduled Notifications
    
    public func scheduleMarketOpenNotification() {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Market Open"
        content.body = "Crypto markets are active. Check your positions!"
        content.sound = .default
        
        // Schedule for 9 AM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "market-open-daily",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to schedule market open notification: \(error)")
            } else {
                self?.logger.info("Market open notification scheduled")
            }
        }
    }
    
    public func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        logger.info("All notifications cancelled")
    }
    
    public func cancelNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        logger.info("Notification cancelled: \(identifier)")
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Listen for price updates
        NotificationCenter.default.publisher(for: .priceUpdate)
            .sink { [weak self] notification in
                self?.handlePriceUpdate(notification)
            }
            .store(in: &cancellables)
        
        // Listen for trade executions
        NotificationCenter.default.publisher(for: .tradeExecuted)
            .sink { [weak self] notification in
                self?.handleTradeExecution(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handlePriceUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let symbol = userInfo["symbol"] as? String,
              let price = userInfo["price"] as? Double else { return }
        
        // Check for price alerts (this would be more sophisticated in a real app)
        checkPriceAlerts(symbol: symbol, currentPrice: price)
    }
    
    private func handleTradeExecution(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let symbol = userInfo["symbol"] as? String,
              let side = userInfo["side"] as? String,
              let amount = userInfo["amount"] as? Double else { return }
        
        let title = "Trade Executed"
        let body = "\(side) \(String(format: "%.4f", amount)) \(symbol)"
        
        sendTradeNotification(title: title, body: body, symbol: symbol)
    }
    
    private func checkPriceAlerts(symbol: String, currentPrice: Double) {
        // This would check stored price alerts and trigger notifications
        // For demo purposes, we'll skip this implementation
    }
}

// MARK: - Supporting Types

public enum PriceDirection {
    case above
    case below
    
    var description: String {
        switch self {
        case .above: return "above"
        case .below: return "below"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let tradeExecuted = Notification.Name("tradeExecuted")
}