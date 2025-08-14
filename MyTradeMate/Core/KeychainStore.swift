import Foundation
import Security

actor KeychainStore {
    static let shared = KeychainStore()
    
    private init() {}
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case unexpectedStatus(OSStatus)
    }
    
    // MARK: - API Key Management
    
    func saveAPIKey(_ key: String, for exchange: Exchange) throws {
        try saveItem(key, service: "apiKey.\(exchange.rawValue)")
    }
    
    func saveAPISecret(_ secret: String, for exchange: Exchange) throws {
        try saveItem(secret, service: "apiSecret.\(exchange.rawValue)")
    }
    
    func getAPIKey(for exchange: Exchange) throws -> String {
        try getString(service: "apiKey.\(exchange.rawValue)")
    }
    
    func getAPISecret(for exchange: Exchange) throws -> String {
        try getString(service: "apiSecret.\(exchange.rawValue)")
    }
    
    func deleteCredentials(for exchange: Exchange) throws {
        try delete(service: "apiKey.\(exchange.rawValue)")
        try delete(service: "apiSecret.\(exchange.rawValue)")
    }
    
    // MARK: - Private Methods
    
    private func saveItem(_ value: String, service: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedStatus(errSecParam)
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service
            ]
            
            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(
                updateQuery as CFDictionary,
                attributes as CFDictionary
            )
            
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    private func getString(service: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedStatus(errSecInternalError)
        }
        
        return string
    }
    
    private func delete(service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}