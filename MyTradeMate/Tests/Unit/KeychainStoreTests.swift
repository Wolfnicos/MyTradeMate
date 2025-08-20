import XCTest
@testable import MyTradeMate

final class KeychainStoreTests: XCTestCase {
    
    var keychainStore: KeychainStore!
    
    override func setUp() async throws {
        try await super.setUp()
        keychainStore = KeychainStore.shared
        
        // Clean up any existing test data
        try await cleanupTestData()
    }
    
    override func tearDown() async throws {
        // Clean up test data
        try await cleanupTestData()
        keychainStore = nil
        try await super.tearDown()
    }
    
    // MARK: - API Key Storage Tests
    
    func testSaveAndRetrieveAPIKey() async throws {
        // Given
        let exchange = Exchange.binance
        let testAPIKey = "test_api_key_12345"
        
        // When
        try await keychainStore.saveAPIKey(testAPIKey, for: exchange)
        let retrievedKey = try await keychainStore.getAPIKey(for: exchange)
        
        // Then
        XCTAssertEqual(retrievedKey, testAPIKey)
    }
    
    func testSaveAndRetrieveAPISecret() async throws {
        // Given
        let exchange = Exchange.binance
        let testAPISecret = "test_api_secret_67890"
        
        // When
        try await keychainStore.saveAPISecret(testAPISecret, for: exchange)
        let retrievedSecret = try await keychainStore.getAPISecret(for: exchange)
        
        // Then
        XCTAssertEqual(retrievedSecret, testAPISecret)
    }
    
    func testSaveAndRetrieveExchangeCredentials() async throws {
        // Given
        let exchange = Exchange.kraken
        let testAPIKey = "kraken_api_key_test"
        let testAPISecret = "kraken_api_secret_test"
        
        // When
        try await keychainStore.saveExchangeCredentials(
            apiKey: testAPIKey,
            apiSecret: testAPISecret,
            for: exchange
        )
        let credentials = try await keychainStore.getExchangeCredentials(for: exchange)
        
        // Then
        XCTAssertEqual(credentials.apiKey, testAPIKey)
        XCTAssertEqual(credentials.apiSecret, testAPISecret)
    }
    
    func testUpdateExistingAPIKey() async throws {
        // Given
        let exchange = Exchange.binance
        let originalKey = "original_api_key"
        let updatedKey = "updated_api_key"
        
        // When - Save original key
        try await keychainStore.saveAPIKey(originalKey, for: exchange)
        let firstRetrieved = try await keychainStore.getAPIKey(for: exchange)
        
        // Then - Verify original key
        XCTAssertEqual(firstRetrieved, originalKey)
        
        // When - Update with new key
        try await keychainStore.saveAPIKey(updatedKey, for: exchange)
        let secondRetrieved = try await keychainStore.getAPIKey(for: exchange)
        
        // Then - Verify updated key
        XCTAssertEqual(secondRetrieved, updatedKey)
        XCTAssertNotEqual(secondRetrieved, originalKey)
    }
    
    func testMultipleExchangeCredentials() async throws {
        // Given
        let binanceKey = "binance_key"
        let binanceSecret = "binance_secret"
        let krakenKey = "kraken_key"
        let krakenSecret = "kraken_secret"
        
        // When
        try await keychainStore.saveExchangeCredentials(
            apiKey: binanceKey,
            apiSecret: binanceSecret,
            for: .binance
        )
        try await keychainStore.saveExchangeCredentials(
            apiKey: krakenKey,
            apiSecret: krakenSecret,
            for: .kraken
        )
        
        // Then
        let binanceCredentials = try await keychainStore.getExchangeCredentials(for: .binance)
        let krakenCredentials = try await keychainStore.getExchangeCredentials(for: .kraken)
        
        XCTAssertEqual(binanceCredentials.apiKey, binanceKey)
        XCTAssertEqual(binanceCredentials.apiSecret, binanceSecret)
        XCTAssertEqual(krakenCredentials.apiKey, krakenKey)
        XCTAssertEqual(krakenCredentials.apiSecret, krakenSecret)
        
        // Verify they don't interfere with each other
        XCTAssertNotEqual(binanceCredentials.apiKey, krakenCredentials.apiKey)
        XCTAssertNotEqual(binanceCredentials.apiSecret, krakenCredentials.apiSecret)
    }
    
    // MARK: - Credential Existence Tests
    
    func testHasCredentialsWhenBothExist() async throws {
        // Given
        let exchange = Exchange.binance
        try await keychainStore.saveAPIKey("test_key", for: exchange)
        try await keychainStore.saveAPISecret("test_secret", for: exchange)
        
        // When
        let hasCredentials = await keychainStore.hasCredentials(for: exchange)
        
        // Then
        XCTAssertTrue(hasCredentials)
    }
    
    func testHasCredentialsWhenOnlyKeyExists() async throws {
        // Given
        let exchange = Exchange.binance
        try await keychainStore.saveAPIKey("test_key", for: exchange)
        // Note: Not saving API secret
        
        // When
        let hasCredentials = await keychainStore.hasCredentials(for: exchange)
        
        // Then
        XCTAssertFalse(hasCredentials, "Should return false when only API key exists")
    }
    
    func testHasCredentialsWhenOnlySecretExists() async throws {
        // Given
        let exchange = Exchange.binance
        try await keychainStore.saveAPISecret("test_secret", for: exchange)
        // Note: Not saving API key
        
        // When
        let hasCredentials = await keychainStore.hasCredentials(for: exchange)
        
        // Then
        XCTAssertFalse(hasCredentials, "Should return false when only API secret exists")
    }
    
    func testHasCredentialsWhenNoneExist() async throws {
        // Given
        let exchange = Exchange.binance
        // Note: Not saving any credentials
        
        // When
        let hasCredentials = await keychainStore.hasCredentials(for: exchange)
        
        // Then
        XCTAssertFalse(hasCredentials)
    }
    
    // MARK: - Deletion Tests
    
    func testDeleteCredentials() async throws {
        // Given
        let exchange = Exchange.binance
        try await keychainStore.saveExchangeCredentials(
            apiKey: "test_key",
            apiSecret: "test_secret",
            for: exchange
        )
        
        // Verify credentials exist
        XCTAssertTrue(await keychainStore.hasCredentials(for: exchange))
        
        // When
        try await keychainStore.deleteCredentials(for: exchange)
        
        // Then
        XCTAssertFalse(await keychainStore.hasCredentials(for: exchange))
        
        // Verify individual retrieval throws errors
        do {
            _ = try await keychainStore.getAPIKey(for: exchange)
            XCTFail("Should throw error when API key doesn't exist")
        } catch KeychainStore.KeychainError.itemNotFound {
            // Expected
        }
        
        do {
            _ = try await keychainStore.getAPISecret(for: exchange)
            XCTFail("Should throw error when API secret doesn't exist")
        } catch KeychainStore.KeychainError.itemNotFound {
            // Expected
        }
    }
    
    func testDeleteNonExistentCredentials() async throws {
        // Given
        let exchange = Exchange.binance
        // Note: No credentials saved
        
        // When & Then - Should not throw error
        try await keychainStore.deleteCredentials(for: exchange)
    }
    
    // MARK: - Error Handling Tests
    
    func testGetNonExistentAPIKey() async throws {
        // Given
        let exchange = Exchange.binance
        
        // When & Then
        do {
            _ = try await keychainStore.getAPIKey(for: exchange)
            XCTFail("Should throw itemNotFound error")
        } catch KeychainStore.KeychainError.itemNotFound {
            // Expected
        } catch {
            XCTFail("Should throw KeychainError.itemNotFound, got \(error)")
        }
    }
    
    func testGetNonExistentAPISecret() async throws {
        // Given
        let exchange = Exchange.binance
        
        // When & Then
        do {
            _ = try await keychainStore.getAPISecret(for: exchange)
            XCTFail("Should throw itemNotFound error")
        } catch KeychainStore.KeychainError.itemNotFound {
            // Expected
        } catch {
            XCTFail("Should throw KeychainError.itemNotFound, got \(error)")
        }
    }
    
    func testGetNonExistentExchangeCredentials() async throws {
        // Given
        let exchange = Exchange.binance
        
        // When & Then
        do {
            _ = try await keychainStore.getExchangeCredentials(for: exchange)
            XCTFail("Should throw itemNotFound error")
        } catch KeychainStore.KeychainError.itemNotFound {
            // Expected
        } catch {
            XCTFail("Should throw KeychainError.itemNotFound, got \(error)")
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testEmptyStringStorage() async throws {
        // Given
        let exchange = Exchange.binance
        let emptyKey = ""
        let emptySecret = ""
        
        // When
        try await keychainStore.saveAPIKey(emptyKey, for: exchange)
        try await keychainStore.saveAPISecret(emptySecret, for: exchange)
        
        // Then
        let retrievedKey = try await keychainStore.getAPIKey(for: exchange)
        let retrievedSecret = try await keychainStore.getAPISecret(for: exchange)
        
        XCTAssertEqual(retrievedKey, emptyKey)
        XCTAssertEqual(retrievedSecret, emptySecret)
    }
    
    func testUnicodeStringStorage() async throws {
        // Given
        let exchange = Exchange.binance
        let unicodeKey = "🔑test_key_with_emoji🔐"
        let unicodeSecret = "🔒secret_with_unicode_测试🔓"
        
        // When
        try await keychainStore.saveAPIKey(unicodeKey, for: exchange)
        try await keychainStore.saveAPISecret(unicodeSecret, for: exchange)
        
        // Then
        let retrievedKey = try await keychainStore.getAPIKey(for: exchange)
        let retrievedSecret = try await keychainStore.getAPISecret(for: exchange)
        
        XCTAssertEqual(retrievedKey, unicodeKey)
        XCTAssertEqual(retrievedSecret, unicodeSecret)
    }
    
    func testLongStringStorage() async throws {
        // Given
        let exchange = Exchange.binance
        let longKey = String(repeating: "a", count: 1000)
        let longSecret = String(repeating: "b", count: 1000)
        
        // When
        try await keychainStore.saveAPIKey(longKey, for: exchange)
        try await keychainStore.saveAPISecret(longSecret, for: exchange)
        
        // Then
        let retrievedKey = try await keychainStore.getAPIKey(for: exchange)
        let retrievedSecret = try await keychainStore.getAPISecret(for: exchange)
        
        XCTAssertEqual(retrievedKey, longKey)
        XCTAssertEqual(retrievedSecret, longSecret)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentSaveAndRetrieve() async throws {
        // Given
        let exchange = Exchange.binance
        let iterations = 10
        
        // When - Perform concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    do {
                        let key = "concurrent_key_\(i)"
                        let secret = "concurrent_secret_\(i)"
                        
                        try await self.keychainStore.saveExchangeCredentials(
                            apiKey: key,
                            apiSecret: secret,
                            for: exchange
                        )
                        
                        let credentials = try await self.keychainStore.getExchangeCredentials(for: exchange)
                        
                        // The final values should be consistent (though we can't predict which iteration wins)
                        XCTAssertFalse(credentials.apiKey.isEmpty)
                        XCTAssertFalse(credentials.apiSecret.isEmpty)
                        XCTAssertTrue(credentials.apiKey.hasPrefix("concurrent_key_"))
                        XCTAssertTrue(credentials.apiSecret.hasPrefix("concurrent_secret_"))
                    } catch {
                        XCTFail("Concurrent operation failed: \(error)")
                    }
                }
            }
        }
        
        // Then - Verify final state is consistent
        let finalCredentials = try await keychainStore.getExchangeCredentials(for: exchange)
        XCTAssertFalse(finalCredentials.apiKey.isEmpty)
        XCTAssertFalse(finalCredentials.apiSecret.isEmpty)
    }
    
    // MARK: - Security Tests
    
    func testCredentialsAreNotAccessibleAfterAppRestart() async throws {
        // This test simulates app restart by creating a new KeychainStore instance
        // In a real scenario, keychain data should persist across app launches
        
        // Given
        let exchange = Exchange.binance
        let testKey = "persistent_key"
        let testSecret = "persistent_secret"
        
        // When - Save with current instance
        try await keychainStore.saveExchangeCredentials(
            apiKey: testKey,
            apiSecret: testSecret,
            for: exchange
        )
        
        // Simulate app restart by using the shared instance (keychain data persists)
        let newKeychainStore = KeychainStore.shared
        
        // Then - Data should still be accessible
        let credentials = try await newKeychainStore.getExchangeCredentials(for: exchange)
        XCTAssertEqual(credentials.apiKey, testKey)
        XCTAssertEqual(credentials.apiSecret, testSecret)
    }
    
    func testKeychainIsolationBetweenExchanges() async throws {
        // Given
        let binanceKey = "binance_isolated_key"
        let krakenKey = "kraken_isolated_key"
        
        // When
        try await keychainStore.saveAPIKey(binanceKey, for: .binance)
        try await keychainStore.saveAPIKey(krakenKey, for: .kraken)
        
        // Then - Each exchange should only access its own data
        let retrievedBinanceKey = try await keychainStore.getAPIKey(for: .binance)
        let retrievedKrakenKey = try await keychainStore.getAPIKey(for: .kraken)
        
        XCTAssertEqual(retrievedBinanceKey, binanceKey)
        XCTAssertEqual(retrievedKrakenKey, krakenKey)
        XCTAssertNotEqual(retrievedBinanceKey, retrievedKrakenKey)
        
        // Deleting one should not affect the other
        try await keychainStore.deleteCredentials(for: .binance)
        
        XCTAssertFalse(await keychainStore.hasCredentials(for: .binance))
        XCTAssertTrue(await keychainStore.hasCredentials(for: .kraken))
    }
    
    // MARK: - Helper Methods
    
    private func cleanupTestData() async throws {
        // Clean up test data for all exchanges
        for exchange in Exchange.allCases {
            try await keychainStore.deleteCredentials(for: exchange)
        }
    }
}

// MARK: - KeychainStore Protocol Async Extensions

extension KeychainStore {
    func saveAPIKey(_ key: String, for exchange: Exchange) async throws {
        try await Task {
            try self.saveAPIKey(key, for: exchange)
        }.value
    }
    
    func saveAPISecret(_ secret: String, for exchange: Exchange) async throws {
        try await Task {
            try self.saveAPISecret(secret, for: exchange)
        }.value
    }
    
    func getAPIKey(for exchange: Exchange) async throws -> String {
        try await Task {
            try self.getAPIKey(for: exchange)
        }.value
    }
    
    func getAPISecret(for exchange: Exchange) async throws -> String {
        try await Task {
            try self.getAPISecret(for: exchange)
        }.value
    }
    
    func deleteCredentials(for exchange: Exchange) async throws {
        try await Task {
            try self.deleteCredentials(for: exchange)
        }.value
    }
    
    func saveExchangeCredentials(apiKey: String, apiSecret: String, for exchange: Exchange) async throws {
        try await Task {
            try self.saveExchangeCredentials(apiKey: apiKey, apiSecret: apiSecret, for: exchange)
        }.value
    }
    
    func getExchangeCredentials(for exchange: Exchange) async throws -> (apiKey: String, apiSecret: String) {
        try await Task {
            try self.getExchangeCredentials(for: exchange)
        }.value
    }
}