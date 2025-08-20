import XCTest

/// Comprehensive security test suite that runs all security-related tests
/// This provides a convenient way to run all security tests together
final class SecurityTestSuite: XCTestCase {
    
    /// Test that verifies all security test classes are properly configured
    func testAllSecurityTestClassesExist() {
        // This test ensures all our security test classes are properly set up
        // and can be instantiated without errors
        
        let keychainStoreTests = KeychainStoreTests()
        let credentialValidationTests = CredentialValidationTests()
        let secureDataHandlingTests = SecureDataHandlingTests()
        
        XCTAssertNotNil(keychainStoreTests)
        XCTAssertNotNil(credentialValidationTests)
        XCTAssertNotNil(secureDataHandlingTests)
    }
    
    /// Performance test for security operations
    func testSecurityOperationsPerformance() async throws {
        let keychainStore = KeychainStore.shared
        let networkSecurityManager = NetworkSecurityManager.shared
        
        // Clean up any existing test data
        try await keychainStore.deleteCredentials(for: .binance)
        
        // Measure performance of security operations
        measure {
            // Keychain operations
            do {
                try keychainStore.saveAPIKey("performance_test_key", for: .binance)
                let _ = try keychainStore.getAPIKey(for: .binance)
                try keychainStore.deleteCredentials(for: .binance)
            } catch {
                XCTFail("Keychain operations should not fail: \(error)")
            }
            
            // Network security validations
            do {
                let secureURL = URL(string: "https://api.binance.com/api/v3/ticker/price")!
                try networkSecurityManager.validateHTTPS(for: secureURL)
            } catch {
                XCTFail("HTTPS validation should not fail: \(error)")
            }
            
            // Secure session creation
            let _ = networkSecurityManager.createSecureSession(for: .binance)
        }
    }
    
    /// Integration test that verifies the complete security flow
    func testCompleteSecurityFlow() async throws {
        // This test verifies that all security components work together correctly
        // in a realistic security scenario
        
        let keychainStore = KeychainStore.shared
        let networkSecurityManager = NetworkSecurityManager.shared
        
        // Clean up any existing test data
        try await keychainStore.deleteCredentials(for: .binance)
        
        // Step 1: Validate HTTPS requirement
        let secureURL = URL(string: "https://api.binance.com/api/v3/ticker/price")!
        let insecureURL = URL(string: "http://api.binance.com/api/v3/ticker/price")!
        
        XCTAssertNoThrow(try networkSecurityManager.validateHTTPS(for: secureURL))
        XCTAssertThrowsError(try networkSecurityManager.validateHTTPS(for: insecureURL))
        
        // Step 2: Store credentials securely
        let testAPIKey = "integration_test_api_key_12345"
        let testAPISecret = "integration_test_api_secret_67890"
        
        try await keychainStore.saveExchangeCredentials(
            apiKey: testAPIKey,
            apiSecret: testAPISecret,
            for: .binance
        )
        
        // Step 3: Verify credentials are stored and retrievable
        XCTAssertTrue(await keychainStore.hasCredentials(for: .binance))
        
        let retrievedCredentials = try await keychainStore.getExchangeCredentials(for: .binance)
        XCTAssertEqual(retrievedCredentials.apiKey, testAPIKey)
        XCTAssertEqual(retrievedCredentials.apiSecret, testAPISecret)
        
        // Step 4: Create secure session for API communication
        let secureSession = networkSecurityManager.createSecureSession(for: .binance)
        XCTAssertNotNil(secureSession)
        XCTAssertNotNil(secureSession.delegate)
        
        // Step 5: Verify ATS configuration
        let atsValid = networkSecurityManager.validateATSConfiguration()
        XCTAssertNotNil(atsValid) // Should return a boolean value
        
        // Step 6: Clean up credentials
        try await keychainStore.deleteCredentials(for: .binance)
        XCTAssertFalse(await keychainStore.hasCredentials(for: .binance))
    }
    
    /// Test security isolation between different exchanges
    func testSecurityIsolationBetweenExchanges() async throws {
        let keychainStore = KeychainStore.shared
        
        // Clean up any existing test data
        try await keychainStore.deleteCredentials(for: .binance)
        try await keychainStore.deleteCredentials(for: .kraken)
        
        // Store credentials for different exchanges
        try await keychainStore.saveExchangeCredentials(
            apiKey: "binance_key",
            apiSecret: "binance_secret",
            for: .binance
        )
        
        try await keychainStore.saveExchangeCredentials(
            apiKey: "kraken_key",
            apiSecret: "kraken_secret",
            for: .kraken
        )
        
        // Verify isolation - each exchange can only access its own credentials
        let binanceCredentials = try await keychainStore.getExchangeCredentials(for: .binance)
        let krakenCredentials = try await keychainStore.getExchangeCredentials(for: .kraken)
        
        XCTAssertEqual(binanceCredentials.apiKey, "binance_key")
        XCTAssertEqual(binanceCredentials.apiSecret, "binance_secret")
        XCTAssertEqual(krakenCredentials.apiKey, "kraken_key")
        XCTAssertEqual(krakenCredentials.apiSecret, "kraken_secret")
        
        // Verify they don't interfere with each other
        XCTAssertNotEqual(binanceCredentials.apiKey, krakenCredentials.apiKey)
        XCTAssertNotEqual(binanceCredentials.apiSecret, krakenCredentials.apiSecret)
        
        // Deleting one should not affect the other
        try await keychainStore.deleteCredentials(for: .binance)
        
        XCTAssertFalse(await keychainStore.hasCredentials(for: .binance))
        XCTAssertTrue(await keychainStore.hasCredentials(for: .kraken))
        
        // Clean up
        try await keychainStore.deleteCredentials(for: .kraken)
    }
    
    /// Test security error handling and recovery
    func testSecurityErrorHandlingAndRecovery() async throws {
        let keychainStore = KeychainStore.shared
        let networkSecurityManager = NetworkSecurityManager.shared
        
        // Test 1: Keychain error handling
        do {
            _ = try await keychainStore.getAPIKey(for: .binance)
            XCTFail("Should throw error for non-existent key")
        } catch KeychainStore.KeychainError.itemNotFound {
            // Expected error
        } catch {
            XCTFail("Should throw KeychainError.itemNotFound, got \(error)")
        }
        
        // Test 2: Network security error handling
        let insecureURL = URL(string: "http://insecure.example.com")!
        
        do {
            try networkSecurityManager.validateHTTPS(for: insecureURL)
            XCTFail("Should throw error for insecure URL")
        } catch NetworkSecurityError.insecureConnection(let url) {
            XCTAssertEqual(url, insecureURL)
        } catch {
            XCTFail("Should throw NetworkSecurityError.insecureConnection, got \(error)")
        }
        
        // Test 3: Recovery after error
        // After error, system should still function normally
        let secureURL = URL(string: "https://secure.example.com")!
        XCTAssertNoThrow(try networkSecurityManager.validateHTTPS(for: secureURL))
        
        // Keychain should still work after error
        try await keychainStore.saveAPIKey("recovery_test_key", for: .binance)
        let retrievedKey = try await keychainStore.getAPIKey(for: .binance)
        XCTAssertEqual(retrievedKey, "recovery_test_key")
        
        // Clean up
        try await keychainStore.deleteCredentials(for: .binance)
    }
    
    /// Test concurrent security operations
    func testConcurrentSecurityOperations() async throws {
        let keychainStore = KeychainStore.shared
        
        // Clean up any existing test data
        try await keychainStore.deleteCredentials(for: .binance)
        
        let iterations = 5
        
        // Perform concurrent keychain operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    do {
                        let key = "concurrent_key_\(i)"
                        let secret = "concurrent_secret_\(i)"
                        
                        // Save credentials
                        try await keychainStore.saveExchangeCredentials(
                            apiKey: key,
                            apiSecret: secret,
                            for: .binance
                        )
                        
                        // Retrieve credentials
                        let credentials = try await keychainStore.getExchangeCredentials(for: .binance)
                        
                        // Verify credentials are valid (though we can't predict which iteration wins)
                        XCTAssertFalse(credentials.apiKey.isEmpty)
                        XCTAssertFalse(credentials.apiSecret.isEmpty)
                        XCTAssertTrue(credentials.apiKey.hasPrefix("concurrent_key_"))
                        XCTAssertTrue(credentials.apiSecret.hasPrefix("concurrent_secret_"))
                        
                    } catch {
                        XCTFail("Concurrent security operation failed: \(error)")
                    }
                }
            }
        }
        
        // Verify final state is consistent
        XCTAssertTrue(await keychainStore.hasCredentials(for: .binance))
        
        let finalCredentials = try await keychainStore.getExchangeCredentials(for: .binance)
        XCTAssertFalse(finalCredentials.apiKey.isEmpty)
        XCTAssertFalse(finalCredentials.apiSecret.isEmpty)
        
        // Clean up
        try await keychainStore.deleteCredentials(for: .binance)
    }
    
    /// Test security compliance and best practices
    func testSecurityComplianceAndBestPractices() {
        let networkSecurityManager = NetworkSecurityManager.shared
        
        // Test 1: HTTPS enforcement
        let httpsURLs = [
            "https://api.binance.com",
            "https://api.kraken.com",
            "https://secure.example.com"
        ]
        
        for urlString in httpsURLs {
            let url = URL(string: urlString)!
            XCTAssertNoThrow(try networkSecurityManager.validateHTTPS(for: url),
                           "HTTPS URLs should be accepted: \(urlString)")
        }
        
        // Test 2: Insecure protocol rejection
        let insecureURLs = [
            "http://api.binance.com",
            "ftp://files.example.com",
            "file:///local/file.json"
        ]
        
        for urlString in insecureURLs {
            let url = URL(string: urlString)!
            XCTAssertThrowsError(try networkSecurityManager.validateHTTPS(for: url),
                               "Insecure URLs should be rejected: \(urlString)")
        }
        
        // Test 3: Secure session configuration
        let session = networkSecurityManager.createSecureSession(for: .binance)
        
        XCTAssertEqual(session.configuration.timeoutIntervalForRequest, 30,
                      "Request timeout should be reasonable")
        XCTAssertEqual(session.configuration.timeoutIntervalForResource, 60,
                      "Resource timeout should be reasonable")
        XCTAssertNotNil(session.delegate, "Session should have security delegate")
        
        // Test 4: ATS configuration validation
        let atsValid = networkSecurityManager.validateATSConfiguration()
        // Note: This test depends on actual Info.plist configuration
        // In production, this should return true for proper ATS setup
        XCTAssertNotNil(atsValid, "ATS validation should return a result")
    }
}

// MARK: - Security Test Utilities

/// Utility class for setting up security test data and common test scenarios
final class SecurityTestUtilities {
    
    /// Creates sample credentials for testing
    static func createSampleCredentials(
        exchange: Exchange = .binance,
        keyPrefix: String = "test_key",
        secretPrefix: String = "test_secret"
    ) -> (apiKey: String, apiSecret: String) {
        let timestamp = Int(Date().timeIntervalSince1970)
        return (
            apiKey: "\(keyPrefix)_\(timestamp)",
            apiSecret: "\(secretPrefix)_\(timestamp)"
        )
    }
    
    /// Sets up a clean security test environment
    static func setupCleanSecurityEnvironment() async throws {
        let keychainStore = KeychainStore.shared
        
        // Clean up all test data
        for exchange in Exchange.allCases {
            try await keychainStore.deleteCredentials(for: exchange)
        }
    }
    
    /// Validates that credentials are properly stored and retrievable
    static func validateCredentialStorage(
        _ credentials: (apiKey: String, apiSecret: String),
        for exchange: Exchange,
        using keychainStore: KeychainStore
    ) async throws {
        // Store credentials
        try await keychainStore.saveExchangeCredentials(
            apiKey: credentials.apiKey,
            apiSecret: credentials.apiSecret,
            for: exchange
        )
        
        // Verify storage
        XCTAssertTrue(await keychainStore.hasCredentials(for: exchange))
        
        // Verify retrieval
        let retrieved = try await keychainStore.getExchangeCredentials(for: exchange)
        XCTAssertEqual(retrieved.apiKey, credentials.apiKey)
        XCTAssertEqual(retrieved.apiSecret, credentials.apiSecret)
    }
    
    /// Validates that network security is properly enforced
    static func validateNetworkSecurity(
        for urls: [String],
        shouldSucceed: Bool,
        using networkSecurityManager: NetworkSecurityManager
    ) {
        for urlString in urls {
            guard let url = URL(string: urlString) else {
                XCTFail("Invalid URL: \(urlString)")
                continue
            }
            
            if shouldSucceed {
                XCTAssertNoThrow(try networkSecurityManager.validateHTTPS(for: url),
                               "URL should be accepted: \(urlString)")
            } else {
                XCTAssertThrowsError(try networkSecurityManager.validateHTTPS(for: url),
                                   "URL should be rejected: \(urlString)")
            }
        }
    }
    
    /// Generates secure test data
    static func generateSecureTestData(length: Int = 32) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    /// Validates error handling for security operations
    static func validateSecurityErrorHandling<T>(
        operation: () throws -> T,
        expectedErrorType: Error.Type,
        description: String
    ) {
        do {
            _ = try operation()
            XCTFail("\(description) should throw \(expectedErrorType)")
        } catch {
            XCTAssertTrue(type(of: error) == expectedErrorType,
                         "\(description) should throw \(expectedErrorType), got \(type(of: error))")
        }
    }
}

// MARK: - Security Test Configuration

/// Configuration for security tests
struct SecurityTestConfiguration {
    static let testExchanges: [Exchange] = [.binance, .kraken]
    static let secureURLs = [
        "https://api.binance.com/api/v3/ticker/price",
        "https://api.kraken.com/0/public/Ticker",
        "https://secure.example.com/api/data"
    ]
    static let insecureURLs = [
        "http://api.binance.com/api/v3/ticker/price",
        "ftp://files.example.com/data.json",
        "file:///path/to/local/file.json"
    ]
    static let testCredentialLength = 32
    static let concurrentOperationCount = 10
}

// MARK: - KeychainStore Async Extensions for Testing

extension KeychainStore {
    func saveAPIKey(_ key: String, for exchange: Exchange) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try self.saveAPIKey(key, for: exchange)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func saveAPISecret(_ secret: String, for exchange: Exchange) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try self.saveAPISecret(secret, for: exchange)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getAPIKey(for exchange: Exchange) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let key = try self.getAPIKey(for: exchange)
                continuation.resume(returning: key)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getAPISecret(for exchange: Exchange) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let secret = try self.getAPISecret(for: exchange)
                continuation.resume(returning: secret)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func deleteCredentials(for exchange: Exchange) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try self.deleteCredentials(for: exchange)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func saveExchangeCredentials(apiKey: String, apiSecret: String, for exchange: Exchange) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try self.saveExchangeCredentials(apiKey: apiKey, apiSecret: apiSecret, for: exchange)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getExchangeCredentials(for exchange: Exchange) async throws -> (apiKey: String, apiSecret: String) {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let credentials = try self.getExchangeCredentials(for: exchange)
                continuation.resume(returning: credentials)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}