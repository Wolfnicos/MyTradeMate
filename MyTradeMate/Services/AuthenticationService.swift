import Foundation
import Combine
import Security
import OSLog

// MARK: - Authentication Service

@MainActor
public final class AuthenticationService: ObservableObject {
    public static let shared = AuthenticationService()
    
    @Published public var isAuthenticated = false
    @Published public var currentUser: User?
    @Published public var authenticationStatus: AuthStatus = .unauthenticated
    
    private let logger = os.Logger(subsystem: "com.mytrademate", category: "Auth")
    private let keychain = KeychainManager()
    
    private init() {
        checkExistingAuthentication()
    }
    
    // MARK: - Authentication Methods
    
    public func authenticate(email: String, password: String) async throws {
        logger.info("Attempting authentication for user: \(email)")
        authenticationStatus = .authenticating
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Demo authentication - accept any email/password
        if !email.isEmpty && !password.isEmpty {
            let user = User(
                id: UUID().uuidString,
                email: email,
                name: email.components(separatedBy: "@").first ?? "User",
                createdAt: Date()
            )
            
            currentUser = user
            isAuthenticated = true
            authenticationStatus = .authenticated
            
            // Store credentials securely
            try keychain.store(password, for: "user_password")
            try keychain.store(email, for: "user_email")
            
            logger.info("Authentication successful")
        } else {
            authenticationStatus = .failed("Invalid credentials")
            throw AuthError.invalidCredentials
        }
    }
    
    public func signOut() {
        logger.info("Signing out user")
        
        currentUser = nil
        isAuthenticated = false
        authenticationStatus = .unauthenticated
        
        // Clear stored credentials
        try? keychain.delete("user_password")
        try? keychain.delete("user_email")
    }
    
    public func deleteAccount() async throws {
        logger.info("Deleting user account")
        
        // Simulate account deletion
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Clear all data
        signOut()
        
        // Clear all keychain data
        try keychain.deleteAll()
        
        logger.info("Account deleted successfully")
    }
    
    // MARK: - Biometric Authentication
    
    public func authenticateWithBiometrics() async throws {
        logger.info("Attempting biometric authentication")
        
        // Simulate biometric authentication
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Check if we have stored credentials
        guard let email = try? keychain.retrieve("user_email"),
              let password = try? keychain.retrieve("user_password") else {
            throw AuthError.noStoredCredentials
        }
        
        try await authenticate(email: email, password: password)
    }
    
    // MARK: - Private Methods
    
    private func checkExistingAuthentication() {
        // Check if user was previously authenticated
        if let email = try? keychain.retrieve("user_email"),
           let _ = try? keychain.retrieve("user_password") {
            
            let user = User(
                id: UUID().uuidString,
                email: email,
                name: email.components(separatedBy: "@").first ?? "User",
                createdAt: Date()
            )
            
            currentUser = user
            isAuthenticated = true
            authenticationStatus = .authenticated
            
            logger.info("Restored previous authentication")
        }
    }
}

// MARK: - Supporting Types

public struct User: Identifiable, Codable {
    public let id: String
    public let email: String
    public let name: String
    public let createdAt: Date
    
    public init(id: String, email: String, name: String, createdAt: Date) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
    }
}

public enum AuthStatus {
    case unauthenticated
    case authenticating
    case authenticated
    case failed(String)
}

public enum AuthError: LocalizedError {
    case invalidCredentials
    case noStoredCredentials
    case keychainError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .noStoredCredentials:
            return "No stored credentials found"
        case .keychainError(let message):
            return "Keychain error: \(message)"
        }
    }
}

// MARK: - Keychain Manager

private class KeychainManager {
    private let service = "com.mytrademate.keychain"
    
    func store(_ value: String, for key: String) throws {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.keychainError("Failed to store item: \(status)")
        }
    }
    
    func retrieve(_ key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw AuthError.keychainError("Failed to retrieve item: \(status)")
        }
        
        return string
    }
    
    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthError.keychainError("Failed to delete item: \(status)")
        }
    }
    
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthError.keychainError("Failed to delete all items: \(status)")
        }
    }
}