import Foundation

/// Centralized error handling for the MyTradeMate app
enum AppError: LocalizedError, Equatable {
    // MARK: - CoreML Errors
    case coreMLPredictionFailed(underlying: String)
    case coreMLModelNotFound(modelName: String)
    case coreMLInvalidInput(reason: String)
    
    // MARK: - WebSocket Errors
    case webSocketConnectionFailed(reason: String)
    case webSocketReconnectionFailed(attempts: Int)
    case webSocketInvalidMessage(message: String)
    
    // MARK: - Trading Errors
    case tradeExecutionFailed(details: String)
    case insufficientBalance(required: Double, available: Double)
    case invalidOrderParameters(reason: String)
    case riskLimitExceeded(limit: String)
    
    // MARK: - Security Errors
    case keychainAccessFailed(operation: String)
    case credentialsNotFound(exchange: String)
    case networkSecurityFailed(reason: String)
    
    // MARK: - Data Errors
    case marketDataUnavailable(symbol: String)
    case invalidTimeframe(timeframe: String)
    case insufficientData(required: Int, available: Int)
    
    // MARK: - Configuration Errors
    case invalidConfiguration(component: String)
    case settingsCorrupted(setting: String)
    
    // MARK: - LocalizedError Implementation
    
    var errorDescription: String? {
        switch self {
        case .coreMLPredictionFailed(let underlying):
            return "AI prediction failed: \(underlying)"
        case .coreMLModelNotFound(let modelName):
            return "AI model '\(modelName)' not found"
        case .coreMLInvalidInput(let reason):
            return "Invalid AI model input: \(reason)"
            
        case .webSocketConnectionFailed(let reason):
            return "WebSocket connection failed: \(reason)"
        case .webSocketReconnectionFailed(let attempts):
            return "Failed to reconnect after \(attempts) attempts"
        case .webSocketInvalidMessage(let message):
            return "Invalid WebSocket message: \(message)"
            
        case .tradeExecutionFailed(let details):
            return "Trade execution failed: \(details)"
        case .insufficientBalance(let required, let available):
            return "Insufficient balance: need \(required), have \(available)"
        case .invalidOrderParameters(let reason):
            return "Invalid order parameters: \(reason)"
        case .riskLimitExceeded(let limit):
            return "Risk limit exceeded: \(limit)"
            
        case .keychainAccessFailed(let operation):
            return "Keychain access failed during \(operation)"
        case .credentialsNotFound(let exchange):
            return "No credentials found for \(exchange)"
        case .networkSecurityFailed(let reason):
            return "Network security validation failed: \(reason)"
            
        case .marketDataUnavailable(let symbol):
            return "Market data unavailable for \(symbol)"
        case .invalidTimeframe(let timeframe):
            return "Invalid timeframe: \(timeframe)"
        case .insufficientData(let required, let available):
            return "Insufficient data: need \(required), have \(available)"
            
        case .invalidConfiguration(let component):
            return "Invalid configuration for \(component)"
        case .settingsCorrupted(let setting):
            return "Settings corrupted: \(setting)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .coreMLPredictionFailed, .coreMLModelNotFound, .coreMLInvalidInput:
            return "Try switching to demo mode or restart the app"
            
        case .webSocketConnectionFailed, .webSocketReconnectionFailed:
            return "Check your internet connection and try again"
        case .webSocketInvalidMessage:
            return "This is likely a temporary issue, please wait"
            
        case .tradeExecutionFailed:
            return "Review your order parameters and try again"
        case .insufficientBalance:
            return "Add funds to your account or reduce order size"
        case .invalidOrderParameters:
            return "Check your order size, price, and symbol"
        case .riskLimitExceeded:
            return "Reduce position size or adjust risk settings"
            
        case .keychainAccessFailed:
            return "Restart the app or check device security settings"
        case .credentialsNotFound:
            return "Add your API keys in Settings > Exchange Keys"
        case .networkSecurityFailed:
            return "Check your network connection and security settings"
            
        case .marketDataUnavailable:
            return "Try a different symbol or check your connection"
        case .invalidTimeframe:
            return "Select a valid timeframe (5m, 1h, 4h)"
        case .insufficientData:
            return "Wait for more market data to be collected"
            
        case .invalidConfiguration:
            return "Reset app settings or reinstall the app"
        case .settingsCorrupted:
            return "Reset this setting to default value"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .coreMLPredictionFailed:
            return "The AI model encountered an error during prediction"
        case .webSocketConnectionFailed:
            return "Unable to establish real-time market data connection"
        case .tradeExecutionFailed:
            return "The trading system could not execute your order"
        case .keychainAccessFailed:
            return "Unable to access secure credential storage"
        case .marketDataUnavailable:
            return "Real-time market data is currently unavailable"
        default:
            return nil
        }
    }
    
    // MARK: - Error Categories
    
    var category: ErrorCategory {
        switch self {
        case .coreMLPredictionFailed, .coreMLModelNotFound, .coreMLInvalidInput:
            return .ai
        case .webSocketConnectionFailed, .webSocketReconnectionFailed, .webSocketInvalidMessage:
            return .network
        case .tradeExecutionFailed, .insufficientBalance, .invalidOrderParameters, .riskLimitExceeded:
            return .trading
        case .keychainAccessFailed, .credentialsNotFound, .networkSecurityFailed:
            return .security
        case .marketDataUnavailable, .invalidTimeframe, .insufficientData:
            return .data
        case .invalidConfiguration, .settingsCorrupted:
            return .configuration
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .coreMLModelNotFound, .credentialsNotFound, .settingsCorrupted:
            return .critical
        case .webSocketReconnectionFailed, .tradeExecutionFailed, .keychainAccessFailed:
            return .high
        case .coreMLPredictionFailed, .webSocketConnectionFailed, .insufficientBalance:
            return .medium
        case .webSocketInvalidMessage, .invalidTimeframe, .insufficientData:
            return .low
        default:
            return .medium
        }
    }
    
    // MARK: - Convenience Methods
    
    static func from(_ error: Error, context: String) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // Convert common errors to AppError
        if let urlError = error as? URLError {
            return .webSocketConnectionFailed(reason: urlError.localizedDescription)
        }
        
        if error.localizedDescription.contains("CoreML") {
            return .coreMLPredictionFailed(underlying: error.localizedDescription)
        }
        
        if error.localizedDescription.contains("keychain") {
            return .keychainAccessFailed(operation: context)
        }
        
        // Default fallback
        return .invalidConfiguration(component: context)
    }
}

// MARK: - Supporting Types

enum ErrorCategory: String, CaseIterable {
    case ai = "AI/ML"
    case network = "Network"
    case trading = "Trading"
    case security = "Security"
    case data = "Data"
    case configuration = "Configuration"
}

enum ErrorSeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var priority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

// MARK: - Error Record

struct ErrorRecord: Identifiable, Codable {
    let id = UUID()
    let error: String
    let category: String
    let severity: String
    let timestamp: Date
    let context: String?
    
    init(error: AppError, context: String? = nil) {
        self.error = error.localizedDescription
        self.category = error.category.rawValue
        self.severity = error.severity.rawValue
        self.timestamp = Date()
        self.context = context
    }
}