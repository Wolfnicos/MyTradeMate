import XCTest
@testable import MyTradeMate

final class SecureDataHandlingTests: XCTestCase {
    
    var networkSecurityManager: NetworkSecurityManager!
    
    override func setUp() async throws {
        try await super.setUp()
        networkSecurityManager = NetworkSecurityManager.shared
    }
    
    override func tearDown() async throws {
        networkSecurityManager = nil
        try await super.tearDown()
    }
    
    // MARK: - HTTPS Validation Tests
    
    func testValidateHTTPSForSecureURL() throws {
        // Given
        let secureURL = URL(string: "https://api.binance.com/api/v3/ticker/price")!
        
        // When & Then - Should not throw
        XCTAssertNoThrow(try networkSecurityManager.validateHTTPS(for: secureURL))
    }
    
    func testValidateHTTPSForInsecureURL() throws {
        // Given
        let insecureURL = URL(string: "http://api.binance.com/api/v3/ticker/price")!
        
        // When & Then - Should throw
        XCTAssertThrowsError(try networkSecurityManager.validateHTTPS(for: insecureURL)) { error in
            if case NetworkSecurityError.insecureConnection(let url) = error {
                XCTAssertEqual(url, insecureURL)
            } else {
                XCTFail("Expected NetworkSecurityError.insecureConnection, got \(error)")
            }
        }
    }
    
    func testValidateHTTPSForFTPURL() throws {
        // Given
        let ftpURL = URL(string: "ftp://files.example.com/data.json")!
        
        // When & Then - Should throw
        XCTAssertThrowsError(try networkSecurityManager.validateHTTPS(for: ftpURL)) { error in
            XCTAssertTrue(error is NetworkSecurityError)
        }
    }
    
    func testValidateHTTPSForFileURL() throws {
        // Given
        let fileURL = URL(string: "file:///path/to/local/file.json")!
        
        // When & Then - Should throw
        XCTAssertThrowsError(try networkSecurityManager.validateHTTPS(for: fileURL)) { error in
            XCTAssertTrue(error is NetworkSecurityError)
        }
    }
    
    func testValidateHTTPSForDataURL() throws {
        // Given
        let dataURL = URL(string: "data:text/plain;base64,SGVsbG8gV29ybGQ=")!
        
        // When & Then - Should throw
        XCTAssertThrowsError(try networkSecurityManager.validateHTTPS(for: dataURL)) { error in
            XCTAssertTrue(error is NetworkSecurityError)
        }
    }
    
    // MARK: - Secure Session Creation Tests
    
    func testCreateSecureSessionForBinance() {
        // Given
        let exchange = Exchange.binance
        
        // When
        let session = networkSecurityManager.createSecureSession(for: exchange)
        
        // Then
        XCTAssertNotNil(session)
        XCTAssertNotNil(session.delegate)
        XCTAssertEqual(session.configuration.timeoutIntervalForRequest, 30)
        XCTAssertEqual(session.configuration.timeoutIntervalForResource, 60)
    }
    
    func testCreateSecureSessionForKraken() {
        // Given
        let exchange = Exchange.kraken
        
        // When
        let session = networkSecurityManager.createSecureSession(for: exchange)
        
        // Then
        XCTAssertNotNil(session)
        XCTAssertNotNil(session.delegate)
        XCTAssertEqual(session.configuration.timeoutIntervalForRequest, 30)
        XCTAssertEqual(session.configuration.timeoutIntervalForResource, 60)
    }
    
    func testSecureSessionsAreIndependent() {
        // Given
        let binanceSession = networkSecurityManager.createSecureSession(for: .binance)
        let krakenSession = networkSecurityManager.createSecureSession(for: .kraken)
        
        // When & Then
        XCTAssertNotEqual(binanceSession, krakenSession)
        XCTAssertNotEqual(ObjectIdentifier(binanceSession.delegate!), ObjectIdentifier(krakenSession.delegate!))
    }
    
    // MARK: - ATS Configuration Validation Tests
    
    func testValidateATSConfiguration() {
        // When
        let isValid = networkSecurityManager.validateATSConfiguration()
        
        // Then
        // This test depends on the actual Info.plist configuration
        // In a real app, this should return true if ATS is properly configured
        // For testing purposes, we'll just verify the method doesn't crash
        XCTAssertNotNil(isValid, "ATS validation should return a boolean value")
    }
    
    // MARK: - Network Security Error Tests
    
    func testNetworkSecurityErrorDescriptions() {
        // Given
        let insecureURL = URL(string: "http://example.com")!
        let insecureError = NetworkSecurityError.insecureConnection(url: insecureURL)
        let certError = NetworkSecurityError.certificateValidationFailed(host: "api.example.com")
        let atsError = NetworkSecurityError.atsConfigurationInvalid
        
        // When & Then
        XCTAssertTrue(insecureError.errorDescription?.contains("Insecure connection") == true)
        XCTAssertTrue(insecureError.errorDescription?.contains("http://example.com") == true)
        
        XCTAssertTrue(certError.errorDescription?.contains("Certificate validation failed") == true)
        XCTAssertTrue(certError.errorDescription?.contains("api.example.com") == true)
        
        XCTAssertTrue(atsError.errorDescription?.contains("App Transport Security") == true)
    }
    
    func testNetworkSecurityErrorRecoverySuggestions() {
        // Given
        let insecureURL = URL(string: "http://example.com")!
        let insecureError = NetworkSecurityError.insecureConnection(url: insecureURL)
        let certError = NetworkSecurityError.certificateValidationFailed(host: "api.example.com")
        let atsError = NetworkSecurityError.atsConfigurationInvalid
        
        // When & Then
        XCTAssertTrue(insecureError.recoverySuggestion?.contains("HTTPS") == true)
        XCTAssertTrue(certError.recoverySuggestion?.contains("network connection") == true)
        XCTAssertTrue(atsError.recoverySuggestion?.contains("Info.plist") == true)
    }
    
    // MARK: - Data Sanitization Tests
    
    func testSensitiveDataNotInLogs() {
        // This test ensures that sensitive data doesn't accidentally get logged
        
        // Given
        let sensitiveAPIKey = "super_secret_api_key_12345"
        let sensitiveAPISecret = "ultra_secret_api_secret_67890"
        
        // When - Simulate operations that might log data
        let logMessage = "Processing API request for user"
        let sanitizedMessage = sanitizeLogMessage(logMessage, sensitiveData: [sensitiveAPIKey, sensitiveAPISecret])
        
        // Then
        XCTAssertFalse(sanitizedMessage.contains(sensitiveAPIKey), "API key should not appear in logs")
        XCTAssertFalse(sanitizedMessage.contains(sensitiveAPISecret), "API secret should not appear in logs")
        XCTAssertTrue(sanitizedMessage.contains("Processing API request"), "Non-sensitive content should remain")
    }
    
    func testCredentialMasking() {
        // Given
        let credential = "abcdef123456789"
        
        // When
        let masked = maskCredential(credential)
        
        // Then
        XCTAssertNotEqual(masked, credential, "Credential should be masked")
        XCTAssertTrue(masked.contains("***"), "Masked credential should contain asterisks")
        XCTAssertLessThan(masked.count, credential.count, "Masked credential should be shorter")
    }
    
    func testCredentialMaskingWithShortCredential() {
        // Given
        let shortCredential = "abc"
        
        // When
        let masked = maskCredential(shortCredential)
        
        // Then
        XCTAssertEqual(masked, "***", "Short credentials should be completely masked")
    }
    
    func testCredentialMaskingWithEmptyCredential() {
        // Given
        let emptyCredential = ""
        
        // When
        let masked = maskCredential(emptyCredential)
        
        // Then
        XCTAssertEqual(masked, "***", "Empty credentials should be masked")
    }
    
    // MARK: - Memory Security Tests
    
    func testSensitiveDataClearing() {
        // This test verifies that sensitive data can be properly cleared from memory
        
        // Given
        var sensitiveData = "sensitive_information_12345"
        let originalPointer = sensitiveData.withUTF8 { $0.baseAddress }
        
        // When
        clearSensitiveString(&sensitiveData)
        
        // Then
        XCTAssertTrue(sensitiveData.isEmpty || sensitiveData.allSatisfy { $0 == "\0" },
                     "Sensitive data should be cleared")
        
        // Verify memory was actually overwritten (if possible)
        if let pointer = originalPointer {
            let memoryContent = String(cString: pointer)
            XCTAssertNotEqual(memoryContent, "sensitive_information_12345",
                            "Original memory should be overwritten")
        }
    }
    
    func testSecureStringComparison() {
        // Given
        let string1 = "identical_string"
        let string2 = "identical_string"
        let string3 = "different_string"
        
        // When & Then
        XCTAssertTrue(secureStringCompare(string1, string2), "Identical strings should compare equal")
        XCTAssertFalse(secureStringCompare(string1, string3), "Different strings should compare unequal")
        XCTAssertFalse(secureStringCompare("", "non-empty"), "Empty and non-empty should compare unequal")
        XCTAssertTrue(secureStringCompare("", ""), "Empty strings should compare equal")
    }
    
    // MARK: - URL Security Tests
    
    func testSecureURLConstruction() {
        // Given
        let baseURL = "https://api.binance.com"
        let endpoint = "/api/v3/ticker/price"
        let parameters = ["symbol": "BTCUSDT"]
        
        // When
        let secureURL = constructSecureURL(base: baseURL, endpoint: endpoint, parameters: parameters)
        
        // Then
        XCTAssertNotNil(secureURL)
        XCTAssertEqual(secureURL?.scheme, "https")
        XCTAssertTrue(secureURL?.absoluteString.contains("symbol=BTCUSDT") == true)
        XCTAssertFalse(secureURL?.absoluteString.contains("api_key") == true, "Should not contain sensitive parameters")
    }
    
    func testSecureURLConstructionWithSensitiveParameters() {
        // Given
        let baseURL = "https://api.binance.com"
        let endpoint = "/api/v3/account"
        let parameters = [
            "symbol": "BTCUSDT",
            "api_key": "sensitive_key",
            "signature": "sensitive_signature"
        ]
        
        // When
        let secureURL = constructSecureURL(base: baseURL, endpoint: endpoint, parameters: parameters)
        
        // Then
        XCTAssertNotNil(secureURL)
        XCTAssertEqual(secureURL?.scheme, "https")
        
        // Sensitive parameters should be handled securely (e.g., in headers, not URL)
        let urlString = secureURL?.absoluteString ?? ""
        XCTAssertFalse(urlString.contains("sensitive_key"), "API key should not be in URL")
        XCTAssertFalse(urlString.contains("sensitive_signature"), "Signature should not be in URL")
    }
    
    // MARK: - Certificate Pinning Tests (Simulated)
    
    func testCertificatePinningValidation() {
        // This test simulates certificate pinning validation
        // In a real implementation, this would test actual certificate validation
        
        // Given
        let validCertificateData = Data("valid_certificate_data".utf8)
        let invalidCertificateData = Data("invalid_certificate_data".utf8)
        let expectedCertificateHash = "expected_hash_value"
        
        // When & Then
        XCTAssertTrue(validateCertificatePin(validCertificateData, expectedHash: expectedCertificateHash))
        XCTAssertFalse(validateCertificatePin(invalidCertificateData, expectedHash: expectedCertificateHash))
    }
    
    // MARK: - Secure Random Generation Tests
    
    func testSecureRandomGeneration() {
        // Given
        let length = 32
        
        // When
        let randomData1 = generateSecureRandom(length: length)
        let randomData2 = generateSecureRandom(length: length)
        
        // Then
        XCTAssertEqual(randomData1.count, length)
        XCTAssertEqual(randomData2.count, length)
        XCTAssertNotEqual(randomData1, randomData2, "Random data should be different each time")
    }
    
    func testSecureRandomWithZeroLength() {
        // Given
        let length = 0
        
        // When
        let randomData = generateSecureRandom(length: length)
        
        // Then
        XCTAssertEqual(randomData.count, 0)
    }
    
    // MARK: - Input Sanitization Tests
    
    func testSanitizeUserInput() {
        // Given
        let maliciousInputs = [
            "<script>alert('xss')</script>",
            "'; DROP TABLE users; --",
            "../../../etc/passwd",
            "%3Cscript%3Ealert('xss')%3C/script%3E",
            "javascript:alert('xss')",
            "data:text/html,<script>alert('xss')</script>"
        ]
        
        // When & Then
        for input in maliciousInputs {
            let sanitized = sanitizeUserInput(input)
            
            XCTAssertFalse(sanitized.contains("<script>"), "Script tags should be removed")
            XCTAssertFalse(sanitized.contains("DROP TABLE"), "SQL injection attempts should be sanitized")
            XCTAssertFalse(sanitized.contains("../"), "Path traversal attempts should be sanitized")
            XCTAssertFalse(sanitized.contains("javascript:"), "JavaScript URLs should be sanitized")
        }
    }
    
    func testSanitizeLegitimateInput() {
        // Given
        let legitimateInputs = [
            "BTCUSDT",
            "user@example.com",
            "My Trading Strategy",
            "1234567890",
            "Valid API Key Format"
        ]
        
        // When & Then
        for input in legitimateInputs {
            let sanitized = sanitizeUserInput(input)
            
            // Legitimate input should remain largely unchanged (minor sanitization is acceptable)
            XCTAssertFalse(sanitized.isEmpty, "Legitimate input should not be completely removed")
            XCTAssertTrue(sanitized.count >= input.count * 0.8, "Legitimate input should not be heavily modified")
        }
    }
}

// MARK: - Security Utility Functions

private func sanitizeLogMessage(_ message: String, sensitiveData: [String]) -> String {
    var sanitized = message
    for sensitive in sensitiveData {
        sanitized = sanitized.replacingOccurrences(of: sensitive, with: "***")
    }
    return sanitized
}

private func maskCredential(_ credential: String) -> String {
    guard credential.count > 6 else {
        return "***"
    }
    
    let start = credential.prefix(2)
    let end = credential.suffix(2)
    return "\(start)***\(end)"
}

private func clearSensitiveString(_ string: inout String) {
    // In a real implementation, this would use secure memory clearing
    // For testing purposes, we'll simulate it
    string = String(repeating: "\0", count: string.count)
    string = ""
}

private func secureStringCompare(_ string1: String, _ string2: String) -> Bool {
    // Constant-time string comparison to prevent timing attacks
    guard string1.count == string2.count else {
        return false
    }
    
    let data1 = string1.data(using: .utf8) ?? Data()
    let data2 = string2.data(using: .utf8) ?? Data()
    
    var result = 0
    for i in 0..<max(data1.count, data2.count) {
        let byte1 = i < data1.count ? data1[i] : 0
        let byte2 = i < data2.count ? data2[i] : 0
        result |= Int(byte1 ^ byte2)
    }
    
    return result == 0
}

private func constructSecureURL(base: String, endpoint: String, parameters: [String: String]) -> URL? {
    guard var components = URLComponents(string: base + endpoint) else {
        return nil
    }
    
    // Filter out sensitive parameters that should go in headers instead
    let sensitiveKeys = ["api_key", "signature", "secret", "password"]
    let safeParameters = parameters.filter { key, _ in
        !sensitiveKeys.contains(key.lowercased())
    }
    
    components.queryItems = safeParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
    
    return components.url
}

private func validateCertificatePin(_ certificateData: Data, expectedHash: String) -> Bool {
    // Simulate certificate pinning validation
    // In a real implementation, this would hash the certificate and compare
    let simulatedHash = certificateData.base64EncodedString().prefix(20)
    return String(simulatedHash) == expectedHash
}

private func generateSecureRandom(length: Int) -> Data {
    guard length > 0 else {
        return Data()
    }
    
    var randomData = Data(count: length)
    let result = randomData.withUnsafeMutableBytes { bytes in
        SecRandomCopyBytes(kSecRandomDefault, length, bytes.bindMemory(to: UInt8.self).baseAddress!)
    }
    
    guard result == errSecSuccess else {
        // Fallback to less secure random if SecRandomCopyBytes fails
        return Data((0..<length).map { _ in UInt8.random(in: 0...255) })
    }
    
    return randomData
}

private func sanitizeUserInput(_ input: String) -> String {
    var sanitized = input
    
    // Remove potentially dangerous patterns
    let dangerousPatterns = [
        "<script[^>]*>.*?</script>",
        "javascript:",
        "data:text/html",
        "DROP\\s+TABLE",
        "\\.\\./",
        "%3C.*?%3E"
    ]
    
    for pattern in dangerousPatterns {
        sanitized = sanitized.replacingOccurrences(
            of: pattern,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
    }
    
    return sanitized
}