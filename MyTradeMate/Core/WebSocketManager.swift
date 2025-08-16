import Foundation

// MARK: - Missing Notification Names
extension NSNotification.Name {
    static let pauseSpecificConnections = NSNotification.Name("pauseSpecificConnections")
    static let optimizeForCellular = NSNotification.Name("optimizeForCellular")
    static let optimizeForBackground = NSNotification.Name("optimizeForBackground")
    static let optimizeForForeground = NSNotification.Name("optimizeForForeground")
}

// MARK: - Connection Manager (temporary stub)
@MainActor
final class ConnectionManager {
    static let shared = ConnectionManager()
    private init() {}
    
    func registerConnection(_ name: String, priority: ConnectionPriority) {
        // Stub implementation
    }
    
    func shouldAllowConnection(_ name: String) -> Bool {
        return true // Allow all connections for now
    }
    
    func recordConnectionActivity(_ name: String) {
        // Stub implementation
    }
    
    func recordConnectionFailure(_ name: String) {
        // Stub implementation
    }
    
    func resetConnectionRetryCount(_ name: String) {
        // Stub implementation
    }
}

// MARK: - Connection Priority (temporary definition)
public enum ConnectionPriority: Int, CaseIterable {
    case critical = 0
    case high = 1
    case medium = 2
    case low = 3
}

// MARK: - WebSocket Manager Base Class

@MainActor
public final class WebSocketManager {
    
    // MARK: - Connection State
    @Published public var isConnected: Bool = false
    private var isConnecting = false
    private var shouldReconnect = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    
    // MARK: - WebSocket Task Management
    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    
    // MARK: - Health Monitoring
    private var pingTimer: Timer?
    private var healthCheckTimer: Timer?
    private var lastMessageTime: Date = Date()
    private let healthCheckInterval: TimeInterval = 30.0
    private let maxSilenceDuration: TimeInterval = 60.0
    private let pingInterval: TimeInterval = 30.0
    
    // MARK: - Configuration
    public struct Configuration {
        let url: URL
        let subscribeMessage: String?
        let name: String
        let verboseLogging: Bool
        let priority: ConnectionPriority
        
        public init(url: URL, subscribeMessage: String? = nil, name: String, verboseLogging: Bool = false, priority: ConnectionPriority = .high) {
            self.url = url
            self.subscribeMessage = subscribeMessage
            self.name = name
            self.verboseLogging = verboseLogging
            self.priority = priority
        }
    }
    
    private let configuration: Configuration
    public var onMessage: ((String) -> Void)?
    public var onConnectionStateChange: ((Bool) -> Void)?
    
    // Performance optimization
    private var connectionOptimizationObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    public init(configuration: Configuration) {
        self.configuration = configuration
        setupConnectionOptimization()
    }
    
    deinit {
        Task { await disconnect() }
        if let observer = connectionOptimizationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupConnectionOptimization() {
        // Register with connection manager
        ConnectionManager.shared.registerConnection(configuration.name, priority: configuration.priority)
        
        // Listen for optimization notifications
        connectionOptimizationObserver = NotificationCenter.default.addObserver(
            forName: .pauseSpecificConnections,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let connections = notification.userInfo?["connections"] as? Set<String>,
                  connections.contains(self.configuration.name) else { return }
            
            Task { @MainActor in
                await self.handleOptimizationPause()
            }
        }
        
        // Listen for other optimization notifications
        NotificationCenter.default.addObserver(
            forName: .optimizeForCellular,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            Task { @MainActor in
                await self.handleCellularOptimization(notification)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .optimizeForBackground,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            Task { @MainActor in
                await self.handleBackgroundOptimization()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .optimizeForForeground,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            Task { @MainActor in
                await self.handleForegroundOptimization()
            }
        }
    }
    
    private func handleOptimizationPause() async {
        log("Connection paused for optimization")
        shouldReconnect = false
        await cleanup()
    }
    
    private func handleCellularOptimization(_ notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let maxConnections = userInfo["maxConnections"] as? Int,
              let updateInterval = userInfo["updateInterval"] as? TimeInterval else { return }
        
        log("Optimizing for cellular: max connections=\(maxConnections), interval=\(updateInterval)s")
        
        // Reduce ping frequency on cellular
        stopHealthMonitoring()
        startHealthMonitoring(pingInterval: updateInterval, healthCheckInterval: updateInterval * 2)
    }
    
    private func handleBackgroundOptimization() async {
        log("Optimizing for background mode")
        
        // Reduce activity in background
        stopHealthMonitoring()
        startHealthMonitoring(pingInterval: 60.0, healthCheckInterval: 120.0)
    }
    
    private func handleForegroundOptimization() async {
        log("Optimizing for foreground mode")
        
        // Resume normal activity
        stopHealthMonitoring()
        startHealthMonitoring()
    }
    
    // MARK: - Public Methods
    
    public func connect() async {
        guard !isConnecting else { 
            log("Already connecting...")
            return 
        }
        guard !isConnected else { 
            log("Already connected")
            return 
        }
        
        // Check if connection is allowed by connection manager
        guard ConnectionManager.shared.shouldAllowConnection(configuration.name) else {
            log("Connection not allowed by connection manager")
            return
        }
        
        await _connect()
    }
    
    public func disconnect() async {
        shouldReconnect = false
        await cleanup()
        reconnectAttempts = 0
        log("Disconnected")
    }
    
    public func sendMessage(_ message: String) {
        guard isConnected, let task = webSocketTask else {
            log("Cannot send message - not connected")
            return
        }
        
        task.send(.string(message)) { [weak self] error in
            if let error = error {
                self?.log("Failed to send message: \(error)")
            }
        }
    }
    
    // MARK: - Private Implementation
    
    private func _connect() async {
        isConnecting = true
        shouldReconnect = true
        
        // Clean up any existing connection
        await cleanup()
        
        // Validate URL
        guard configuration.url.scheme == "wss" || configuration.url.scheme == "ws",
              configuration.url.host != nil else {
            log("❌ Invalid WebSocket URL: \(configuration.url)")
            isConnecting = false
            return
        }
        
        // Create new WebSocket task
        let session = URLSession(configuration: .default)
        let newTask = session.webSocketTask(with: configuration.url)
        webSocketTask = newTask
        
        // Start connection
        newTask.resume()
        
        // Send subscription message if provided
        if let subscribeMessage = configuration.subscribeMessage {
            newTask.send(.string(subscribeMessage)) { [weak self] error in
                if let error = error {
                    self?.log("Failed to send subscription message: \(error)")
                }
            }
        }
        
        // Update state
        isConnecting = false
        isConnected = true
        reconnectAttempts = 0
        lastMessageTime = Date()
        
        // Start monitoring
        startHealthMonitoring()
        
        // Notify state change
        onConnectionStateChange?(true)
        
        log("✅ Connected successfully")
        
        // Start receive loop
        receiveTask = Task {
            await receiveMessages()
        }
    }
    
    private func receiveMessages() async {
        guard let task = webSocketTask else { return }
        
        while !Task.isCancelled && shouldReconnect {
            do {
                let message = try await task.receive()
                await MainActor.run {
                    self.lastMessageTime = Date()
                    self.handleMessage(message)
                }
            } catch {
                log("Receive error: \(error)")
                if shouldReconnect {
                    await handleConnectionLoss(error: error)
                }
                break
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        // Record connection activity for health monitoring
        ConnectionManager.shared.recordConnectionActivity(configuration.name)
        
        switch message {
        case .string(let text):
            if configuration.verboseLogging {
                log("📨 Received: \(text.prefix(200))")
            }
            
            // Validate message format
            guard !text.isEmpty else {
                ErrorManager.shared.handle(.webSocketInvalidMessage(message: "Empty message"))
                return
            }
            
            onMessage?(text)
            
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                if configuration.verboseLogging {
                    log("📨 Received (data): \(text.prefix(200))")
                }
                
                guard !text.isEmpty else {
                    ErrorManager.shared.handle(.webSocketInvalidMessage(message: "Empty data message"))
                    return
                }
                
                onMessage?(text)
            } else {
                ErrorManager.shared.handle(.webSocketInvalidMessage(message: "Invalid data encoding"))
            }
            
        @unknown default:
            log("Unknown message type received")
            ErrorManager.shared.handle(.webSocketInvalidMessage(message: "Unknown message type"))
        }
    }
    
    private func handleConnectionLoss(error: Error) async {
        isConnected = false
        onConnectionStateChange?(false)
        
        log("🔌 Connection lost: \(error.localizedDescription)")
        
        // Record connection failure for intelligent management
        ConnectionManager.shared.recordConnectionFailure(configuration.name)
        
        // Report error to error manager
        ErrorManager.shared.handle(.webSocketConnectionFailed(reason: error.localizedDescription))
        
        // Check if connection is still allowed before attempting reconnection
        guard ConnectionManager.shared.shouldAllowConnection(configuration.name) else {
            log("❌ Reconnection not allowed by connection manager")
            return
        }
        
        // Check if we should attempt reconnection
        guard shouldReconnect && reconnectAttempts < maxReconnectAttempts else {
            if reconnectAttempts >= maxReconnectAttempts {
                log("❌ Max reconnection attempts reached")
                ErrorManager.shared.handle(.webSocketReconnectionFailed(attempts: reconnectAttempts))
            }
            return
        }
        
        reconnectAttempts += 1
        
        // Calculate exponential backoff with jitter
        let baseDelay = min(pow(2.0, Double(reconnectAttempts)) + 1.0, 60.0)
        let jitter = Double.random(in: 0.7...1.3)
        let delay = baseDelay * jitter
        
        log("🔄 Reconnecting in \(String(format: "%.1f", delay))s (attempt \(reconnectAttempts)/\(maxReconnectAttempts))")
        
        // Wait before reconnecting
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Attempt reconnection
        if shouldReconnect {
            await _connect()
            
            // Reset retry count on successful reconnection
            if isConnected {
                ConnectionManager.shared.resetConnectionRetryCount(configuration.name)
            }
        }
    }
    
    private func startHealthMonitoring(pingInterval: TimeInterval? = nil, healthCheckInterval: TimeInterval? = nil) {
        stopHealthMonitoring()
        
        let actualPingInterval = pingInterval ?? self.pingInterval
        let actualHealthCheckInterval = healthCheckInterval ?? self.healthCheckInterval
        
        // Start ping timer
        pingTimer = Timer.scheduledTimer(withTimeInterval: actualPingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.sendPing()
            }
        }
        
        // Start health check timer
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: actualHealthCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performHealthCheck()
            }
        }
    }
    
    private func stopHealthMonitoring() {
        pingTimer?.invalidate()
        pingTimer = nil
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    private func sendPing() async {
        guard let task = webSocketTask, isConnected else { return }
        
        task.sendPing { [weak self] error in
            if let error = error {
                self?.log("🏓 Ping failed: \(error)")
                Task {
                    await self?.handleConnectionLoss(error: error)
                }
            }
        }
    }
    
    private func performHealthCheck() async {
        let timeSinceLastMessage = Date().timeIntervalSince(lastMessageTime)
        
        if timeSinceLastMessage > maxSilenceDuration {
            log("🩺 Health check failed: No messages for \(String(format: "%.1f", timeSinceLastMessage))s")
            
            if shouldReconnect {
                let healthError = NSError(
                    domain: "WebSocketManager",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Connection health check failed"]
                )
                await handleConnectionLoss(error: healthError)
            }
        }
    }
    
    private func cleanup() async {
        stopHealthMonitoring()
        
        receiveTask?.cancel()
        receiveTask = nil
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        isConnected = false
        isConnecting = false
        onConnectionStateChange?(false)
    }
    
    private func log(_ message: String) {
        if configuration.verboseLogging {
            Log.log("[\(configuration.name)] \(message)", category: .webSocket)
        }
    }
}