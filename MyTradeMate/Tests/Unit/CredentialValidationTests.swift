import XCTest
@testable import MyTradeMate

@MainActor
final class CredentialValidationTests: XCTestCase {
    
    var exchangeKeysViewModel: ExchangeKeysViewModel!
    var mockKeychainStore: MockKeychainStore!
    var mockErrorManager: MockErrorManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up mocks
        mockKeychainStore = MockKeychainStore()
        mockErrorManager = MockErrorManager()
        
        // Create ViewModel with mocked dependencies
        exchangeKeysViewModel = ExchangeKeysViewModel(
            keychainStore: mockKeychainStore,
            errorManager: mockErrorManager
        )
    }
    
    override func tearDown() async throws {
        exchangeKeysViewModel = nil
        mockKeychainStore = nil
        mockErrorManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Input Validation Tests
    
    func testSaveKeysWithValidCredentials() {
        // Given
        let exchange = Exchange.binance
        let validAPIKey = "valid_api_key_12345"
        let validAPISecret = "valid_api_secret_67890"
        
        // When
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: validAPIKey, secretKey: validAPISecret)
        
        // Then
        XCTAssertFalse(mockErrorManager.hasError, "Should not have error for valid credentials")
        XCTAssertTrue(mockKeychainStore.saveCredentialsCalled, "Should call save credentials")
        XCTAssertEqual(mockKeychainStore.lastSavedAPIKey, validAPIKey)
        XCTAssertEqual(mockKeychainStore.lastSavedAPISecret, validAPISecret)
        XCTAssertEqual(mockKeychainStore.lastSavedExchange, exchange)
    }
    
    func testSaveKeysWithEmptyAPIKey() {
        // Given
        let exchange = Exchange.binance
        let emptyAPIKey = ""
        let validAPISecret = "valid_api_secret_67890"
        
        // When
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: emptyAPIKey, secretKey: validAPISecret)
        
        // Then
        XCTAssertTrue(mockErrorManager.hasError, "Should have error for empty API key")
        XCTAssertFalse(mockKeychainStore.saveCredentialsCalled, "Should not call save credentials")
        
        if case .validation(let message) = mockErrorManager.lastError {
            XCTAssertTrue(message.contains("API key and secret cannot be empty"))
        } else {
            XCTFail("Expected validation error")
        }
    }
    
    func testSaveKeysWithEmptyAPISecret() {
        // Given
        let exchange = Exchange.binance
        let validAPIKey = "valid_api_key_12345"
        let emptyAPISecret = ""
        
        // When
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: validAPIKey, secretKey: emptyAPISecret)
        
        // Then
        XCTAssertTrue(mockErrorManager.hasError, "Should have error for empty API secret")
        XCTAssertFalse(mockKeychainStore.saveCredentialsCalled, "Should not call save credentials")
        
        if case .validation(let message) = mockErrorManager.lastError {
            XCTAssertTrue(message.contains("API key and secret cannot be empty"))
        } else {
            XCTFail("Expected validation error")
        }
    }
    
    func testSaveKeysWithBothEmpty() {
        // Given
        let exchange = Exchange.binance
        let emptyAPIKey = ""
        let emptyAPISecret = ""
        
        // When
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: emptyAPIKey, secretKey: emptyAPISecret)
        
        // Then
        XCTAssertTrue(mockErrorManager.hasError, "Should have error for both empty")
        XCTAssertFalse(mockKeychainStore.saveCredentialsCalled, "Should not call save credentials")
    }
    
    func testSaveKeysWithWhitespaceOnlyCredentials() {
        // Given
        let exchange = Exchange.binance
        let whitespaceAPIKey = "   "
        let whitespaceAPISecret = "\t\n  "
        
        // When
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: whitespaceAPIKey, secretKey: whitespaceAPISecret)
        
        // Then
        // Note: Current implementation doesn't trim whitespace, so these are considered valid
        // This test documents current behavior - consider if trimming should be added
        XCTAssertFalse(mockErrorManager.hasError, "Current implementation allows whitespace-only strings")
        XCTAssertTrue(mockKeychainStore.saveCredentialsCalled, "Should call save credentials")
    }
    
    // MARK: - API Key Format Validation Tests
    
    func testValidateAPIKeyFormat() {
        // Test various API key formats that exchanges might use
        let validFormats = [
            "ABCD1234567890EFGH",           // Alphanumeric
            "abcd-1234-5678-90ef-gh",       // With hyphens
            "ABCD_1234_5678_90EF_GH",       // With underscores
            "AbCd1234567890EfGh",           // Mixed case
            "1234567890ABCDEFGH",           // Numbers first
            "A1B2C3D4E5F6G7H8I9J0",         // Alternating
        ]
        
        for (index, apiKey) in validFormats.enumerated() {
            // Given
            let exchange = Exchange.binance
            let apiSecret = "valid_secret_\(index)"
            
            // Reset mock
            mockKeychainStore.reset()
            mockErrorManager.reset()
            
            // When
            exchangeKeysViewModel.saveKeys(for: exchange, apiKey: apiKey, secretKey: apiSecret)
            
            // Then
            XCTAssertFalse(mockErrorManager.hasError, "Should accept valid format: \(apiKey)")
            XCTAssertTrue(mockKeychainStore.saveCredentialsCalled, "Should save valid format: \(apiKey)")
        }
    }
    
    func testValidateAPISecretFormat() {
        // Test various API secret formats
        let validFormats = [
            "abcdefghijklmnopqrstuvwxyz1234567890",  // Long alphanumeric
            "ABC123def456GHI789jkl012MNO345pqr678",  // Mixed case long
            "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8",  // Pattern
            "ZYXWVUTSRQPONMLKJIHGFEDCBA9876543210",  // Reverse alphabet
        ]
        
        for (index, apiSecret) in validFormats.enumerated() {
            // Given
            let exchange = Exchange.kraken
            let apiKey = "valid_key_\(index)"
            
            // Reset mock
            mockKeychainStore.reset()
            mockErrorManager.reset()
            
            // When
            exchangeKeysViewModel.saveKeys(for: exchange, apiKey: apiKey, secretKey: apiSecret)
            
            // Then
            XCTAssertFalse(mockErrorManager.hasError, "Should accept valid secret format: \(apiSecret)")
            XCTAssertTrue(mockKeychainStore.saveCredentialsCalled, "Should save valid secret format: \(apiSecret)")
        }
    }
    
    // MARK: - Credential Length Validation Tests
    
    func testVeryShortCredentials() {
        // Given
        let exchange = Exchange.binance
        let shortAPIKey = "A"
        let shortAPISecret = "B"
        
        // When
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: shortAPIKey, secretKey: shortAPISecret)
        
        // Then
        // Current implementation allows any non-empty string
        XCTAssertFalse(mockErrorManager.hasError, "Current implementation allows very short credentials")
        XCTAssertTrue(mockKeychainStore.saveCredentialsCalled)
    }
    
    func testVeryLongCredentials() {
        // Given
        let exchange = Exchange.binance
        let longAPIKey = String(repeating: "A", count: 1000)
        let longAPISecret = String(repeating: "B", count: 1000)
        
        // When
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: longAPIKey, secretKey: longAPISecret)
        
        // Then
        XCTAssertFalse(mockErrorManager.hasError, "Should handle very long credentials")
        XCTAssertTrue(mockKeychainStore.saveCredentialsCalled)
        XCTAssertEqual(mockKeychainStore.lastSavedAPIKey, longAPIKey)
        XCTAssertEqual(mockKeychainStore.lastSavedAPISecret, longAPISecret)
    }
    
    // MARK: - Special Character Validation Tests
    
    func testCredentialsWithSpecialCharacters() {
        let specialCharacterTests = [
            ("key+with+plus", "secret/with/slash"),
            ("key=with=equals", "secret&with&ampersand"),
            ("key%with%percent", "secret#with#hash"),
            ("key@with@at", "secret!with!exclamation"),
            ("key*with*asterisk", "secret?with?question"),
            ("key(with)parentheses", "secret[with]brackets"),
            ("key{with}braces", "secret<with>angles"),
            ("key|with|pipe", "secret\\with\\backslash"),
            ("key\"with\"quotes", "secret'with'apostrophes"),
            ("key~with~tilde", "secret`with`backtick"),
        ]
        
        for (index, (apiKey, apiSecret)) in specialCharacterTests.enumerated() {
            // Given
            let exchange = Exchange.binance
            
            // Reset mock
            mockKeychainStore.reset()
            mockErrorManager.reset()
            
            // When
            exchangeKeysViewModel.saveKeys(for: exchange, apiKey: apiKey, secretKey: apiSecret)
            
            // Then
            XCTAssertFalse(mockErrorManager.hasError, "Should handle special characters in test \(index): \(apiKey)")
            XCTAssertTrue(mockKeychainStore.saveCredentialsCalled, "Should save credentials with special characters")
        }
    }
    
    func testCredentialsWithUnicodeCharacters() {
        // Given
        let exchange = Exchange.binance
        let unicodeAPIKey = "key_with_unicode_测试_🔑"
        let unicodeAPISecret = "secret_with_unicode_密码_🔐"
        
        // When
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: unicodeAPIKey, secretKey: unicodeAPISecret)
        
        // Then
        XCTAssertFalse(mockErrorManager.hasError, "Should handle unicode characters")
        XCTAssertTrue(mockKeychainStore.saveCredentialsCalled)
        XCTAssertEqual(mockKeychainStore.lastSavedAPIKey, unicodeAPIKey)
        XCTAssertEqual(mockKeychainStore.lastSavedAPISecret, unicodeAPISecret)
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleKeychainSaveError() {
        // Given
        let exchange = Exchange.binance
        let validAPIKey = "valid_key"
        let validAPISecret = "valid_secret"
        
        // Configure mock to throw error
        mockKeychainStore.shouldThrowError = true
        mockKeychainStore.errorToThrow = KeychainStore.KeychainError.unexpectedStatus(errSecDuplicateItem)
        
        // When
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: validAPIKey, secretKey: validAPISecret)
        
        // Then
        // The error should be handled asynchronously, so we need to wait
        let expectation = XCTestExpectation(description: "Error handling")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockErrorManager.hasError, "Should handle keychain error")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - State Management Tests
    
    func testLoadingStateManagement() {
        // Given
        let exchange = Exchange.binance
        let validAPIKey = "valid_key"
        let validAPISecret = "valid_secret"
        
        // When
        XCTAssertFalse(exchangeKeysViewModel.isLoading, "Should not be loading initially")
        
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: validAPIKey, secretKey: validAPISecret)
        
        // Then
        // Loading state is managed asynchronously
        let expectation = XCTestExpectation(description: "Loading state")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // After async operation completes, loading should be false
            XCTAssertFalse(self.exchangeKeysViewModel.isLoading, "Should not be loading after completion")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testKeyStatusesUpdate() {
        // Given
        let exchange = Exchange.binance
        let validAPIKey = "valid_key"
        let validAPISecret = "valid_secret"
        
        // Initially should not have keys
        XCTAssertFalse(exchangeKeysViewModel.hasKeys(for: exchange))
        
        // When
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: validAPIKey, secretKey: validAPISecret)
        
        // Then
        let expectation = XCTestExpectation(description: "Key status update")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.exchangeKeysViewModel.hasKeys(for: exchange), "Should have keys after saving")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteCredentialFlow() {
        // Given
        let exchange = Exchange.binance
        let apiKey = "integration_test_key"
        let apiSecret = "integration_test_secret"
        
        // When - Save credentials
        exchangeKeysViewModel.saveKeys(for: exchange, apiKey: apiKey, secretKey: apiSecret)
        
        // Then - Verify save operation
        let saveExpectation = XCTestExpectation(description: "Save completion")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.exchangeKeysViewModel.hasKeys(for: exchange))
            XCTAssertFalse(self.mockErrorManager.hasError)
            XCTAssertTrue(self.mockKeychainStore.saveCredentialsCalled)
            saveExpectation.fulfill()
        }
        
        wait(for: [saveExpectation], timeout: 1.0)
        
        // When - Delete credentials
        exchangeKeysViewModel.deleteKeys(for: exchange)
        
        // Then - Verify delete operation
        let deleteExpectation = XCTestExpectation(description: "Delete completion")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.exchangeKeysViewModel.hasKeys(for: exchange))
            XCTAssertTrue(self.mockKeychainStore.deleteCredentialsCalled)
            deleteExpectation.fulfill()
        }
        
        wait(for: [deleteExpectation], timeout: 1.0)
    }
}

// MARK: - Mock Implementations

class MockKeychainStore: KeychainStoreProtocol {
    var saveCredentialsCalled = false
    var deleteCredentialsCalled = false
    var lastSavedAPIKey: String?
    var lastSavedAPISecret: String?
    var lastSavedExchange: Exchange?
    
    var shouldThrowError = false
    var errorToThrow: Error?
    
    private var storage: [String: String] = [:]
    
    func saveAPIKey(_ key: String, for exchange: Exchange) throws {
        if shouldThrowError, let error = errorToThrow {
            throw error
        }
        storage["apiKey.\(exchange.rawValue)"] = key
    }
    
    func saveAPISecret(_ secret: String, for exchange: Exchange) throws {
        if shouldThrowError, let error = errorToThrow {
            throw error
        }
        storage["apiSecret.\(exchange.rawValue)"] = secret
    }
    
    func getAPIKey(for exchange: Exchange) throws -> String {
        guard let key = storage["apiKey.\(exchange.rawValue)"] else {
            throw KeychainStore.KeychainError.itemNotFound
        }
        return key
    }
    
    func getAPISecret(for exchange: Exchange) throws -> String {
        guard let secret = storage["apiSecret.\(exchange.rawValue)"] else {
            throw KeychainStore.KeychainError.itemNotFound
        }
        return secret
    }
    
    func deleteCredentials(for exchange: Exchange) throws {
        deleteCredentialsCalled = true
        storage.removeValue(forKey: "apiKey.\(exchange.rawValue)")
        storage.removeValue(forKey: "apiSecret.\(exchange.rawValue)")
    }
    
    func hasCredentials(for exchange: Exchange) async -> Bool {
        return storage["apiKey.\(exchange.rawValue)"] != nil && 
               storage["apiSecret.\(exchange.rawValue)"] != nil
    }
    
    func getExchangeCredentials(for exchange: Exchange) async throws -> ExchangeCredentials {
        let apiKey = try getAPIKey(for: exchange)
        let apiSecret = try getAPISecret(for: exchange)
        return ExchangeCredentials(apiKey: apiKey, apiSecret: apiSecret)
    }
    
    func saveExchangeCredentials(apiKey: String, apiSecret: String, for exchange: Exchange) async throws {
        saveCredentialsCalled = true
        lastSavedAPIKey = apiKey
        lastSavedAPISecret = apiSecret
        lastSavedExchange = exchange
        
        try saveAPIKey(apiKey, for: exchange)
        try saveAPISecret(apiSecret, for: exchange)
    }
    
    func reset() {
        saveCredentialsCalled = false
        deleteCredentialsCalled = false
        lastSavedAPIKey = nil
        lastSavedAPISecret = nil
        lastSavedExchange = nil
        shouldThrowError = false
        errorToThrow = nil
        storage.removeAll()
    }
}

class MockErrorManager: ErrorManagerProtocol {
    @Published var currentError: AppError?
    @Published var errorHistory: [ErrorRecord] = []
    @Published var showErrorAlert = false
    
    var hasError: Bool { currentError != nil }
    var lastError: AppError? { currentError }
    
    func handle(_ error: Error, context: String = "") {
        let appError = AppError.from(error, context: context)
        handle(appError, context: context)
    }
    
    func handle(_ error: AppError, context: String = "") {
        currentError = error
        showErrorAlert = true
        errorHistory.append(ErrorRecord(error: error, context: context))
    }
    
    func clearError() {
        currentError = nil
        showErrorAlert = false
    }
    
    func clearHistory() {
        errorHistory.removeAll()
    }
    
    func reset() {
        currentError = nil
        errorHistory.removeAll()
        showErrorAlert = false
    }
}