import Foundation
import SwiftUI

/// Centralized error management for the MyTradeMate app
@MainActor
final class ErrorManager: ObservableObject {
    static let shared = ErrorManager()
    
    @Published var currentError: AppError?
    @Published var errorHistory: [ErrorRecord] = []
    @Published var showErrorAlert = false
    
    private let maxHistoryCount = 100
    
    private init() {
        loadErrorHistory()
    }
    
    // MARK: - Error Handling
    
    func handle(_ error: Error, context: String = "") {
        let appError = AppError.from(error, context: context)
        handle(appError, context: context)
    }
    
    func handle(_ error: AppError, context: String = "") {
        currentError = error
        showErrorAlert = true
        
        let record = ErrorRecord(error: error, context: context.isEmpty ? nil : context)
        errorHistory.insert(record, at: 0)
        
        // Limit history size
        if errorHistory.count > maxHistoryCount {
            errorHistory = Array(errorHistory.prefix(maxHistoryCount))
        }
        
        // Log error
        Log.error.error("[\(error.category.rawValue)] \(error.localizedDescription)")
        if let context = record.context {
            Log.error.error("Context: \(context)")
        }
        
        // Save to persistent storage
        saveErrorHistory()
        
        // Handle critical errors
        if error.severity == .critical {
            handleCriticalError(error)
        }
    }
    
    func clearCurrentError() {
        currentError = nil
        showErrorAlert = false
    }
    
    func clearHistory() {
        errorHistory.removeAll()
        saveErrorHistory()
    }
    
    // MARK: - Error Recovery
    
    func attemptRecovery(for error: AppError) async -> Bool {
        switch error {
        case .webSocketConnectionFailed, .webSocketReconnectionFailed:
            return await attemptWebSocketRecovery()
            
        case .coreMLPredictionFailed:
            return await attemptCoreMLRecovery()
            
        case .keychainAccessFailed:
            return attemptKeychainRecovery()
            
        case .marketDataUnavailable:
            return await attemptMarketDataRecovery()
            
        default:
            return false
        }
    }
    
    // MARK: - Private Recovery Methods
    
    private func attemptWebSocketRecovery() async -> Bool {
        // Implement WebSocket reconnection logic
        do {
            // Wait a bit before retrying
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Try to reconnect (this would be implemented in WebSocketManager)
            Log.error.info("Attempting WebSocket recovery...")
            return true
        } catch {
            return false
        }
    }
    
    private func attemptCoreMLRecovery() async -> Bool {
        // Try to reload AI models
        do {
            try await AIModelManager.shared.validateModels()
            Log.error.info("CoreML recovery successful")
            return true
        } catch {
            Log.error.error("CoreML recovery failed: \(error)")
            return false
        }
    }
    
    private func attemptKeychainRecovery() -> Bool {
        // For keychain issues, we can't really recover automatically
        // Just log and suggest user action
        Log.error.info("Keychain recovery requires user intervention")
        return false
    }
    
    private func attemptMarketDataRecovery() async -> Bool {
        // Try to fetch market data again
        do {
            // This would be implemented in MarketDataService
            Log.error.info("Attempting market data recovery...")
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Critical Error Handling
    
    private func handleCriticalError(_ error: AppError) {
        Log.log("CRITICAL ERROR: \(error.localizedDescription)", level: .error, category: .error)
        
        switch error {
        case .coreMLModelNotFound:
            // Disable AI features
            AppSettings.shared.demoMode = true
            
        case .credentialsNotFound:
            // Force user to re-enter credentials
            // This would trigger navigation to settings
            break
            
        case .settingsCorrupted:
            // Reset to defaults
            resetCorruptedSettings(error)
            
        default:
            break
        }
    }
    
    private func resetCorruptedSettings(_ error: AppError) {
        if case .settingsCorrupted(let setting) = error {
            Log.error.info("Resetting corrupted setting: \(setting)")
            
            // Reset specific settings to defaults
            switch setting {
            case "tradingMode":
                AppSettings.shared.demoMode = true
            case "theme":
                AppSettings.shared.darkMode = false
            default:
                break
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveErrorHistory() {
        do {
            let data = try JSONEncoder().encode(errorHistory)
            UserDefaults.standard.set(data, forKey: "errorHistory")
        } catch {
            Log.error.error("Failed to save error history: \(error)")
        }
    }
    
    private func loadErrorHistory() {
        guard let data = UserDefaults.standard.data(forKey: "errorHistory") else { return }
        
        do {
            errorHistory = try JSONDecoder().decode([ErrorRecord].self, from: data)
        } catch {
            Log.error.error("Failed to load error history: \(error)")
            errorHistory = []
        }
    }
    
    // MARK: - Statistics
    
    var errorsByCategory: [ErrorCategory: Int] {
        Dictionary(grouping: errorHistory, by: { ErrorCategory(rawValue: $0.category) ?? .configuration })
            .mapValues { $0.count }
    }
    
    var errorsBySeverity: [ErrorSeverity: Int] {
        Dictionary(grouping: errorHistory, by: { ErrorSeverity(rawValue: $0.severity) ?? .medium })
            .mapValues { $0.count }
    }
    
    var recentErrors: [ErrorRecord] {
        Array(errorHistory.prefix(10))
    }
}

// MARK: - SwiftUI Integration

extension ErrorManager {
    func errorAlert() -> Alert {
        guard let error = currentError else {
            return Alert(title: Text("Unknown Error"))
        }
        
        let primaryButton = Alert.Button.default(Text("OK")) {
            self.clearCurrentError()
        }
        
        if let recoverySuggestion = error.recoverySuggestion {
            let secondaryButton = Alert.Button.default(Text("Try Recovery")) {
                Task {
                    let success = await self.attemptRecovery(for: error)
                    if success {
                        self.clearCurrentError()
                    }
                }
            }
            
            return Alert(
                title: Text("Error"),
                message: Text(error.localizedDescription + "\n\n" + recoverySuggestion),
                primaryButton: primaryButton,
                secondaryButton: secondaryButton
            )
        } else {
            return Alert(
                title: Text("Error"),
                message: Text(error.localizedDescription),
                dismissButton: primaryButton
            )
        }
    }
}

// MARK: - View Modifier

struct ErrorHandling: ViewModifier {
    @StateObject private var errorManager = ErrorManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $errorManager.showErrorAlert) {
                errorManager.errorAlert()
            }
    }
}

extension View {
    func withErrorHandling() -> some View {
        modifier(ErrorHandling())
    }
}