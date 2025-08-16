import Foundation
import Network
import OSLog

private let logger = Logger(subsystem: "com.mytrademate", category: "ConnectionManager")

/// Manages WebSocket connections intelligently based on app state and network conditions
@MainActor
final class ConnectionManager: ObservableObject {
    static let shared = ConnectionManager()
    
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var connectionQuality: ConnectionQuality = .unknown
    @Published var isIntelligentModeEnabled = true
    @Published var activeConnections: Set<String> = []
    
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var appStateObserver: NSObjectProtocol?
    private var connectionHealthTimer: Timer?
    
    // Connection management
    private var connectionPriorities: [String: ConnectionPriority] = [:]
    private var connectionLastActivity: [String: Date] = [:]
    private var connectionRetryCount: [String: Int] = [:]
    
    enum NetworkStatus {
        case unknown
        case unavailable
        case cellular
        case wifi
        case ethernet
        
        var description: String {
            switch self {
            case .unknown: return "Unknown"
            case .unavailable: return "Unavailable"
            case .cellular: return "Cellular"
            case .wifi: return "WiFi"
            case .ethernet: return "Ethernet"
            }
        }
        
        var isExpensive: Bool {
            return self == .cellular
        }
    }
    
    enum ConnectionQuality {
        case unknown
        case poor
        case fair
        case good
        case excellent
        
        var description: String {
            switch self {
            case .unknown: return "Unknown"
            case .poor: return "Poor"
            case .fair: return "Fair"
            case .good: return "Good"
            case .excellent: return "Excellent"
            }
        }
    }
    
    enum ConnectionPriority: Int, CaseIterable {
        case critical = 0    // Always maintain (trading data)
        case high = 1        // Maintain when possible (market data)
        case medium = 2      // Maintain on good connections (news, social)
        case low = 3         // Maintain only on excellent connections (analytics)
        
        var description: String {
            switch self {
            case .critical: return "Critical"
            case .high: return "High"
            case .medium: return "Medium"
            case .low: return "Low"
            }
        }
    }
    
    private init() {
        setupNetworkMonitoring()
        setupAppStateObserver()
        startConnectionHealthMonitoring()
    }
    
    deinit {
        networkMonitor.cancel()
        connectionHealthTimer?.invalidate()
        if let observer = appStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Setup
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.handleNetworkPathUpdate(path)
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }
    
    private func setupAppStateObserver() {
        appStateObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppDidEnterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppWillEnterForeground()
        }
    }
    
    private func startConnectionHealthMonitoring() {
        connectionHealthTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.performConnectionHealthCheck()
            }
        }
    }
    
    // MARK: - Network Path Handling
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        let previousStatus = networkStatus
        
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                networkStatus = .wifi
            } else if path.usesInterfaceType(.cellular) {
                networkStatus = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                networkStatus = .ethernet
            } else {
                networkStatus = .unknown
            }
            
            // Assess connection quality
            assessConnectionQuality(path: path)
        } else {
            networkStatus = .unavailable
            connectionQuality = .unknown
        }
        
        if previousStatus != networkStatus {
            logger.info("Network status changed: \(previousStatus.description) -> \(networkStatus.description)")
            handleNetworkStatusChange()
        }
    }
    
    private func assessConnectionQuality(path: NWPath) {
        // Simplified quality assessment based on network type and constraints
        if path.isExpensive {
            connectionQuality = networkStatus == .cellular ? .fair : .good
        } else {
            switch networkStatus {
            case .wifi, .ethernet:
                connectionQuality = path.isConstrained ? .good : .excellent
            case .cellular:
                connectionQuality = .fair
            default:
                connectionQuality = .unknown
            }
        }
    }
    
    private func handleNetworkStatusChange() {
        guard isIntelligentModeEnabled else { return }
        
        switch networkStatus {
        case .unavailable:
            pauseAllConnections()
        case .cellular:
            optimizeForCellular()
        case .wifi, .ethernet:
            optimizeForWiFi()
        case .unknown:
            useConservativeSettings()
        }
    }
    
    // MARK: - App State Handling
    
    private func handleAppDidEnterBackground() {
        logger.info("App entered background - optimizing connections")
        
        guard isIntelligentModeEnabled else { return }
        
        // Reduce connection frequency and maintain only critical connections
        pauseNonCriticalConnections()
        
        // Notify WebSocket managers to reduce activity
        NotificationCenter.default.post(name: .optimizeForBackground, object: self)
    }
    
    private func handleAppWillEnterForeground() {
        logger.info("App entering foreground - restoring connections")
        
        guard isIntelligentModeEnabled else { return }
        
        // Restore all connections based on current network conditions
        restoreOptimalConnections()
        
        // Notify WebSocket managers to resume normal activity
        NotificationCenter.default.post(name: .optimizeForForeground, object: self)
    }
    
    // MARK: - Connection Optimization
    
    private func pauseAllConnections() {
        logger.warning("Pausing all connections due to network unavailability")
        NotificationCenter.default.post(name: .pauseAllConnections, object: self)
    }
    
    private func optimizeForCellular() {
        logger.info("Optimizing connections for cellular network")
        
        // Maintain only critical and high priority connections
        let allowedPriorities: Set<ConnectionPriority> = [.critical, .high]
        optimizeConnectionsForPriorities(allowedPriorities)
        
        // Reduce update frequencies
        NotificationCenter.default.post(
            name: .optimizeForCellular,
            object: self,
            userInfo: ["maxConnections": 2, "updateInterval": 10.0]
        )
    }
    
    private func optimizeForWiFi() {
        logger.info("Optimizing connections for WiFi network")
        
        // Allow all priority levels based on connection quality
        let allowedPriorities: Set<ConnectionPriority>
        switch connectionQuality {
        case .excellent:
            allowedPriorities = Set(ConnectionPriority.allCases)
        case .good:
            allowedPriorities = [.critical, .high, .medium]
        case .fair:
            allowedPriorities = [.critical, .high]
        default:
            allowedPriorities = [.critical]
        }
        
        optimizeConnectionsForPriorities(allowedPriorities)
        
        // Use normal update frequencies
        NotificationCenter.default.post(
            name: .optimizeForWiFi,
            object: self,
            userInfo: ["maxConnections": 5, "updateInterval": 2.0]
        )
    }
    
    private func useConservativeSettings() {
        logger.info("Using conservative connection settings")
        
        // Maintain only critical connections
        optimizeConnectionsForPriorities([.critical])
        
        NotificationCenter.default.post(
            name: .useConservativeSettings,
            object: self,
            userInfo: ["maxConnections": 1, "updateInterval": 30.0]
        )
    }
    
    private func pauseNonCriticalConnections() {
        logger.info("Pausing non-critical connections for background mode")
        
        // Maintain only critical connections
        optimizeConnectionsForPriorities([.critical])
        
        NotificationCenter.default.post(name: .pauseNonCriticalConnections, object: self)
    }
    
    private func restoreOptimalConnections() {
        logger.info("Restoring optimal connections for foreground mode")
        
        // Restore connections based on current network status
        handleNetworkStatusChange()
    }
    
    private func optimizeConnectionsForPriorities(_ allowedPriorities: Set<ConnectionPriority>) {
        let connectionsToMaintain = connectionPriorities.compactMap { (connectionId, priority) in
            allowedPriorities.contains(priority) ? connectionId : nil
        }
        
        let connectionsToPause = Set(connectionPriorities.keys).subtracting(connectionsToMaintain)
        
        if !connectionsToPause.isEmpty {
            logger.info("Pausing \(connectionsToPause.count) connections: \(connectionsToPause.joined(separator: ", "))")
            
            NotificationCenter.default.post(
                name: .pauseSpecificConnections,
                object: self,
                userInfo: ["connections": connectionsToPause]
            )
        }
        
        if !connectionsToMaintain.isEmpty {
            logger.info("Maintaining \(connectionsToMaintain.count) connections: \(connectionsToMaintain.joined(separator: ", "))")
        }
    }
    
    // MARK: - Connection Health Monitoring
    
    private func performConnectionHealthCheck() {
        let now = Date()
        let staleThreshold: TimeInterval = 300 // 5 minutes
        
        for (connectionId, lastActivity) in connectionLastActivity {
            let timeSinceActivity = now.timeIntervalSince(lastActivity)
            
            if timeSinceActivity > staleThreshold {
                logger.warning("Connection \(connectionId) appears stale (no activity for \(String(format: "%.1f", timeSinceActivity))s)")
                
                // Suggest reconnection for stale connections
                NotificationCenter.default.post(
                    name: .connectionHealthCheck,
                    object: self,
                    userInfo: ["connectionId": connectionId, "action": "reconnect"]
                )
            }
        }
    }
    
    // MARK: - Public Interface
    
    func registerConnection(_ connectionId: String, priority: ConnectionPriority) {
        connectionPriorities[connectionId] = priority
        connectionLastActivity[connectionId] = Date()
        connectionRetryCount[connectionId] = 0
        activeConnections.insert(connectionId)
        
        logger.info("Registered connection: \(connectionId) (priority: \(priority.description))")
    }
    
    func unregisterConnection(_ connectionId: String) {
        connectionPriorities.removeValue(forKey: connectionId)
        connectionLastActivity.removeValue(forKey: connectionId)
        connectionRetryCount.removeValue(forKey: connectionId)
        activeConnections.remove(connectionId)
        
        logger.info("Unregistered connection: \(connectionId)")
    }
    
    func recordConnectionActivity(_ connectionId: String) {
        connectionLastActivity[connectionId] = Date()
    }
    
    func recordConnectionFailure(_ connectionId: String) {
        connectionRetryCount[connectionId, default: 0] += 1
        let retryCount = connectionRetryCount[connectionId] ?? 0
        
        logger.warning("Connection failure recorded for \(connectionId) (retry count: \(retryCount))")
        
        // Implement exponential backoff for failed connections
        if retryCount >= 3 {
            logger.warning("Connection \(connectionId) has failed \(retryCount) times, suggesting pause")
            
            NotificationCenter.default.post(
                name: .connectionRepeatedFailure,
                object: self,
                userInfo: ["connectionId": connectionId, "retryCount": retryCount]
            )
        }
    }
    
    func resetConnectionRetryCount(_ connectionId: String) {
        connectionRetryCount[connectionId] = 0
    }
    
    func shouldAllowConnection(_ connectionId: String) -> Bool {
        guard isIntelligentModeEnabled else { return true }
        guard networkStatus != .unavailable else { return false }
        
        guard let priority = connectionPriorities[connectionId] else {
            logger.warning("Unknown connection \(connectionId) - allowing by default")
            return true
        }
        
        // Check if this priority level is allowed under current conditions
        switch networkStatus {
        case .cellular:
            return priority.rawValue <= ConnectionPriority.high.rawValue
        case .wifi, .ethernet:
            switch connectionQuality {
            case .excellent:
                return true
            case .good:
                return priority.rawValue <= ConnectionPriority.medium.rawValue
            case .fair:
                return priority.rawValue <= ConnectionPriority.high.rawValue
            default:
                return priority == .critical
            }
        default:
            return priority == .critical
        }
    }
    
    func getConnectionStatus() -> ConnectionStatus {
        return ConnectionStatus(
            networkStatus: networkStatus,
            connectionQuality: connectionQuality,
            activeConnections: activeConnections.count,
            isIntelligentModeEnabled: isIntelligentModeEnabled
        )
    }
    
    func setIntelligentMode(_ enabled: Bool) {
        isIntelligentModeEnabled = enabled
        logger.info("Intelligent connection management \(enabled ? "enabled" : "disabled")")
        
        if enabled {
            handleNetworkStatusChange()
        }
    }
}

// MARK: - Supporting Types

struct ConnectionStatus {
    let networkStatus: ConnectionManager.NetworkStatus
    let connectionQuality: ConnectionManager.ConnectionQuality
    let activeConnections: Int
    let isIntelligentModeEnabled: Bool
}

// MARK: - Notifications

extension Notification.Name {
    static let optimizeForBackground = Notification.Name("optimizeForBackground")
    static let optimizeForForeground = Notification.Name("optimizeForForeground")
    static let pauseAllConnections = Notification.Name("pauseAllConnections")
    static let optimizeForCellular = Notification.Name("optimizeForCellular")
    static let optimizeForWiFi = Notification.Name("optimizeForWiFi")
    static let useConservativeSettings = Notification.Name("useConservativeSettings")
    static let pauseNonCriticalConnections = Notification.Name("pauseNonCriticalConnections")
    static let pauseSpecificConnections = Notification.Name("pauseSpecificConnections")
    static let connectionHealthCheck = Notification.Name("connectionHealthCheck")
    static let connectionRepeatedFailure = Notification.Name("connectionRepeatedFailure")
}