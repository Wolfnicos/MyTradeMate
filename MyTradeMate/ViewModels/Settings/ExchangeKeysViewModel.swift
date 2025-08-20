import Foundation
import SwiftUI
import CryptoKit
import CommonCrypto

// MARK: - Supporting Types
struct ExchangeCredentials {
    let apiKey: String
    let apiSecret: String
}

@MainActor
final class ExchangeKeysViewModel: ObservableObject {
    // MARK: - Dependencies
    private let errorManager = ErrorManager.shared
    // Note: KeychainStore access will be handled with await since it's an actor
    
    // MARK: - Published Properties
    @Published var editingExchange: Exchange?
    @Published var isLoading = false
    @Published var keyStatuses: [Exchange: Bool] = [:]
    @Published var connectionTestResults: [Exchange: ConnectionTestResult] = [:]
    @Published var isTestingConnection = false
    
    // MARK: - Initialization
    init() {
        loadKeyStatuses()
    }
    
    // MARK: - Public Methods
    
    func hasKeys(for exchange: Exchange) -> Bool {
        return keyStatuses[exchange] ?? false
    }
    
    func editKeys(for exchange: Exchange) {
        editingExchange = exchange
        Log.userAction("Started editing keys for \(exchange.displayName)")
    }
    
    func saveKeys(for exchange: Exchange, apiKey: String, secretKey: String) {
        guard !apiKey.isEmpty && !secretKey.isEmpty else {
            errorManager.handle(AppError.invalidOrderParameters(reason: "API key and secret cannot be empty"), context: "Save Keys")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await KeychainStore.shared.saveExchangeCredentials(
                    apiKey: apiKey,
                    apiSecret: secretKey,
                    for: exchange
                )
                
                await MainActor.run {
                    self.editingExchange = nil
                    self.keyStatuses[exchange] = true
                    self.isLoading = false
                }
                
                Log.userAction("Successfully saved keys for \(exchange.displayName)")
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                
                errorManager.handle(error, context: "Save Keys for \(exchange.displayName)")
                Log.error(error, context: "Save keys for \(exchange.displayName)")
            }
        }
    }
    
    func deleteKeys(for exchange: Exchange) {
        isLoading = true
        
        Task {
            do {
                try await KeychainStore.shared.deleteCredentials(for: exchange)
                
                await MainActor.run {
                    self.keyStatuses[exchange] = false
                    self.isLoading = false
                }
                
                Log.userAction("Successfully deleted keys for \(exchange.displayName)")
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                
                errorManager.handle(error, context: "Delete Keys for \(exchange.displayName)")
                Log.error(error, context: "Delete keys for \(exchange.displayName)")
            }
        }
    }
    
    func refreshKeyStatuses() {
        loadKeyStatuses()
    }
    
    func testConnection(for exchange: Exchange) {
        guard !isTestingConnection else { return }
        
        isTestingConnection = true
        
        Task {
            do {
                let credentials = try await KeychainStore.shared.getExchangeCredentials(for: exchange)
                let result = try await performConnectionTest(exchange: exchange, credentials: ExchangeCredentials(apiKey: credentials.apiKey, apiSecret: credentials.apiSecret))
                
                await MainActor.run {
                    self.connectionTestResults[exchange] = result
                    self.isTestingConnection = false
                }
                
                Log.userAction("Connection test for \(exchange.displayName): \(result.isSuccessful ? "SUCCESS" : "FAILED")")
                
            } catch {
                await MainActor.run {
                    self.connectionTestResults[exchange] = ConnectionTestResult(
                        isSuccessful: false,
                        message: "Failed to retrieve credentials: \(error.localizedDescription)",
                        timestamp: Date()
                    )
                    self.isTestingConnection = false
                }
                
                errorManager.handle(error, context: "Test Connection for \(exchange.displayName)")
                Log.error(error, context: "Test connection for \(exchange.displayName)")
            }
        }
    }
    
    private func performConnectionTest(exchange: Exchange, credentials: ExchangeCredentials) async throws -> ConnectionTestResult {
        switch exchange {
        case .binance:
            return try await testBinanceConnection(credentials: credentials)
        case .kraken:
            return try await testKrakenConnection(credentials: credentials)
        }
    }
    
    private func testBinanceConnection(credentials: ExchangeCredentials) async throws -> ConnectionTestResult {
        // Test Binance API connection by fetching account info
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let queryString = "timestamp=\(timestamp)"
        
        // Create signature
        let signature = try createBinanceSignature(queryString: queryString, secretKey: credentials.apiSecret)
        let fullQueryString = "\(queryString)&signature=\(signature)"
        
        guard let url = URL(string: "https://api.binance.com/api/v3/account?\(fullQueryString)") else {
            throw ConnectionTestError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(credentials.apiKey, forHTTPHeaderField: "X-MBX-APIKEY")
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConnectionTestError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            // Parse response to verify it's valid account data
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["balances"] != nil {
                return ConnectionTestResult(
                    isSuccessful: true,
                    message: "Connection successful! Account data retrieved.",
                    timestamp: Date()
                )
            } else {
                return ConnectionTestResult(
                    isSuccessful: false,
                    message: "Invalid response format from Binance API",
                    timestamp: Date()
                )
            }
        } else {
            // Parse error message
            var errorMessage = "HTTP \(httpResponse.statusCode)"
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["msg"] as? String {
                errorMessage = msg
            }
            
            return ConnectionTestResult(
                isSuccessful: false,
                message: "Binance API Error: \(errorMessage)",
                timestamp: Date()
            )
        }
    }
    
    private func testKrakenConnection(credentials: ExchangeCredentials) async throws -> ConnectionTestResult {
        // Test Kraken API connection by fetching account balance
        let nonce = String(Int(Date().timeIntervalSince1970 * 1000000))
        let postData = "nonce=\(nonce)"
        
        // Create signature
        let signature = try createKrakenSignature(
            path: "/0/private/Balance",
            postData: postData,
            secretKey: credentials.apiSecret,
            nonce: nonce
        )
        
        guard let url = URL(string: "https://api.kraken.com/0/private/Balance") else {
            throw ConnectionTestError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(credentials.apiKey, forHTTPHeaderField: "API-Key")
        request.setValue(signature, forHTTPHeaderField: "API-Sign")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = postData.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConnectionTestError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            // Parse Kraken response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String],
               error.isEmpty,
               let result = json["result"] as? [String: Any] {
                return ConnectionTestResult(
                    isSuccessful: true,
                    message: "Connection successful! Account balance retrieved.",
                    timestamp: Date()
                )
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let errors = json["error"] as? [String],
                      !errors.isEmpty {
                return ConnectionTestResult(
                    isSuccessful: false,
                    message: "Kraken API Error: \(errors.joined(separator: ", "))",
                    timestamp: Date()
                )
            } else {
                return ConnectionTestResult(
                    isSuccessful: false,
                    message: "Invalid response format from Kraken API",
                    timestamp: Date()
                )
            }
        } else {
            return ConnectionTestResult(
                isSuccessful: false,
                message: "HTTP Error \(httpResponse.statusCode)",
                timestamp: Date()
            )
        }
    }
    
    private func createBinanceSignature(queryString: String, secretKey: String) throws -> String {
        guard let keyData = secretKey.data(using: .utf8),
              let messageData = queryString.data(using: .utf8) else {
            throw ConnectionTestError.signatureError
        }
        
        let signature = HMAC.sha256(key: keyData, message: messageData)
        return signature.hexString
    }
    
    private func createKrakenSignature(path: String, postData: String, secretKey: String, nonce: String) throws -> String {
        guard let secretData = Data(base64Encoded: secretKey),
              let nonceData = nonce.data(using: .utf8),
              let postDataData = postData.data(using: .utf8) else {
            throw ConnectionTestError.signatureError
        }
        
        // SHA256 hash of nonce + postData
        let sha256Hash = SHA256.hash(data: nonceData + postDataData)
        
        // Path + SHA256 hash
        guard let pathData = path.data(using: .utf8) else {
            throw ConnectionTestError.signatureError
        }
        
        let message = pathData + Data(sha256Hash)
        
        // HMAC-SHA512
        let signature = HMAC.sha512(key: secretData, message: message)
        return signature.base64EncodedString()
    }
    
    // MARK: - Private Methods
    
    private func loadKeyStatuses() {
        Task {
            var statuses: [Exchange: Bool] = [:]
            
            for exchange in Exchange.allCases {
                let hasKeys = await KeychainStore.shared.hasCredentials(for: exchange)
                statuses[exchange] = hasKeys
            }
            
            await MainActor.run {
                self.keyStatuses = statuses
            }
        }
    }
}

// MARK: - Supporting Types

struct ConnectionTestResult {
    let isSuccessful: Bool
    let message: String
    let timestamp: Date
}

enum ConnectionTestError: LocalizedError {
    case invalidURL
    case invalidResponse
    case signatureError
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid API response"
        case .signatureError:
            return "Failed to create API signature"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Crypto Utilities

private struct HMAC {
    static func sha256(key: Data, message: Data) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        key.withUnsafeBytes { keyBytes in
            message.withUnsafeBytes { messageBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, key.count, messageBytes.baseAddress, message.count, &digest)
            }
        }
        return Data(digest)
    }
    
    static func sha512(key: Data, message: Data) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        key.withUnsafeBytes { keyBytes in
            message.withUnsafeBytes { messageBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA512), keyBytes.baseAddress, key.count, messageBytes.baseAddress, message.count, &digest)
            }
        }
        return Data(digest)
    }
}

private struct SHA256 {
    static func hash(data: Data) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data(digest)
    }
}

private extension Data {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

// MARK: - Testing Support
// Testing support would be added here when needed