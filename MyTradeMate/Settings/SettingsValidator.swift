import Foundation

/// Validates and enforces safety checks for app settings
struct SettingsValidator {
    
    // MARK: - Trading Mode Validation
    
    static func validateTradingModeTransition(from currentMode: TradingMode, to newMode: TradingMode) -> ValidationResult {
        switch (currentMode, newMode) {
        case (.demo, .paper):
            return .success("Switching to paper trading mode")
            
        case (.demo, .live):
            return .warning("Switching directly from demo to live trading. Consider paper trading first.")
            
        case (.paper, .live):
            return .requiresConfirmation("Are you sure you want to enable live trading? This will use real money.")
            
        case (.live, .demo), (.live, .paper):
            return .success("Switching to safer trading mode")
            
        case (.paper, .demo):
            return .success("Switching to demo mode")
            
        default:
            return .success("No mode change")
        }
    }
    
    // MARK: - Risk Parameter Validation
    
    static func validateRiskParameters(
        maxPositionSize: Double,
        stopLoss: Double,
        takeProfit: Double,
        dailyLossLimit: Double
    ) -> ValidationResult {
        
        var warnings: [String] = []
        var errors: [String] = []
        
        // Position size validation
        if maxPositionSize > 0.25 { // 25%
            warnings.append("Position size above 25% is very risky")
        }
        if maxPositionSize > 0.5 { // 50%
            errors.append("Position size cannot exceed 50%")
        }
        if maxPositionSize <= 0 {
            errors.append("Position size must be greater than 0")
        }
        
        // Stop loss validation
        if stopLoss > 0.1 { // 10%
            warnings.append("Stop loss above 10% may result in large losses")
        }
        if stopLoss <= 0 {
            errors.append("Stop loss must be greater than 0")
        }
        
        // Take profit validation
        if takeProfit < stopLoss {
            warnings.append("Take profit is less than stop loss (poor risk/reward ratio)")
        }
        if takeProfit <= 0 {
            errors.append("Take profit must be greater than 0")
        }
        
        // Daily loss limit validation
        if dailyLossLimit > 0.2 { // 20%
            warnings.append("Daily loss limit above 20% is very risky")
        }
        if dailyLossLimit <= 0 {
            errors.append("Daily loss limit must be greater than 0")
        }
        
        // Return result
        if !errors.isEmpty {
            return .error(errors.joined(separator: "; "))
        } else if !warnings.isEmpty {
            return .warning(warnings.joined(separator: "; "))
        } else {
            return .success("Risk parameters are valid")
        }
    }
    
    // MARK: - API Key Validation
    
    static func validateAPIKeys(apiKey: String, secretKey: String, exchange: Exchange) -> ValidationResult {
        var errors: [String] = []
        
        // Basic format validation
        if apiKey.isEmpty {
            errors.append("API key cannot be empty")
        }
        if secretKey.isEmpty {
            errors.append("Secret key cannot be empty")
        }
        
        // Exchange-specific validation
        switch exchange {
        case .binance:
            if !apiKey.hasPrefix("BINANCE") && apiKey.count < 20 {
                errors.append("Invalid Binance API key format")
            }
            if secretKey.count < 20 {
                errors.append("Invalid Binance secret key format")
            }
            
        case .kraken:
            if apiKey.count < 20 {
                errors.append("Invalid Kraken API key format")
            }
            if secretKey.count < 20 {
                errors.append("Invalid Kraken secret key format")
            }
        }
        
        // Security checks
        if apiKey.contains(" ") || secretKey.contains(" ") {
            errors.append("API keys should not contain spaces")
        }
        
        if !errors.isEmpty {
            return .error(errors.joined(separator: "; "))
        } else {
            return .success("API keys format is valid")
        }
    }
    
    // MARK: - Settings Integrity Check
    
    @MainActor
    static func validateSettingsIntegrity() -> ValidationResult {
        let settings = AppSettings.shared
        var warnings: [String] = []
        var errors: [String] = []
        
        // Check for conflicting settings
        if settings.demoMode && settings.autoTrading {
            warnings.append("Auto trading is enabled in demo mode")
        }
        
        if !settings.demoMode && !settings.paperTrading {
            // Live trading mode - extra checks
            if settings.autoTrading {
                warnings.append("Auto trading is enabled in live mode - ensure you have proper risk management")
            }
        }
        
        // Check timeframe validity
        let validTimeframes = ["5m", "15m", "1h", "4h", "1d"]
        if !validTimeframes.contains(settings.defaultTimeframe) {
            errors.append("Invalid default timeframe: \(settings.defaultTimeframe)")
        }
        
        // Check symbol validity
        if settings.defaultSymbol.isEmpty {
            errors.append("Default symbol cannot be empty")
        }
        
        if !errors.isEmpty {
            return .error(errors.joined(separator: "; "))
        } else if !warnings.isEmpty {
            return .warning(warnings.joined(separator: "; "))
        } else {
            return .success("Settings integrity check passed")
        }
    }
    
    // MARK: - Auto-Correction
    
    @MainActor
    static func autoCorrectSettings() {
        let settings = AppSettings.shared
        var corrected = false
        
        // Correct invalid timeframe
        let validTimeframes = ["5m", "15m", "1h", "4h", "1d"]
        if !validTimeframes.contains(settings.defaultTimeframe) {
            settings.defaultTimeframe = "5m"
            corrected = true
            Log.warning("Auto-corrected invalid timeframe to 5m", category: .app)
        }
        
        // Correct empty symbol
        if settings.defaultSymbol.isEmpty {
            settings.defaultSymbol = "BTC/USDT"
            corrected = true
            Log.warning("Auto-corrected empty symbol to BTC/USDT", category: .app)
        }
        
        // Safety check: disable auto trading if no credentials
        if settings.autoTrading && !settings.demoMode && !settings.paperTrading {
            // For safety, disable auto trading in live mode if not explicitly validated
            settings.autoTrading = false
            corrected = true
            Log.warning("Auto-corrected: disabled auto trading in live mode for safety", category: .app)
        }
        
        if corrected {
            Log.app.info("Settings auto-correction completed")
        }
    }
}

// MARK: - Validation Result

enum ValidationResult {
    case success(String)
    case warning(String)
    case error(String)
    case requiresConfirmation(String)
    
    var isValid: Bool {
        switch self {
        case .success, .warning:
            return true
        case .error, .requiresConfirmation:
            return false
        }
    }
    
    var message: String {
        switch self {
        case .success(let msg), .warning(let msg), .error(let msg), .requiresConfirmation(let msg):
            return msg
        }
    }
    
    var severity: ValidationSeverity {
        switch self {
        case .success:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .requiresConfirmation:
            return .confirmation
        }
    }
}

enum ValidationSeverity {
    case info
    case warning
    case error
    case confirmation
}

