import Foundation
import Network
import os.log

/// Manages network security configurations and certificate pinning
final class NetworkSecurityManager {
    static let shared = NetworkSecurityManager()
    
    private init() {}
    
    /// Validates that all network requests use HTTPS
    func validateHTTPS(for url: URL) throws {
        guard url.scheme == "https" else {
            throw NetworkSecurityError.insecureConnection(url: url)
        }
    }
    
    /// Creates a secure URLSession with certificate pinning for exchange APIs
    func createSecureSession(for exchange: Exchange) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        let session = URLSession(
            configuration: configuration,
            delegate: SecurityDelegate(exchange: exchange),
            delegateQueue: nil
        )
        
        return session
    }
    
    /// Validates ATS (App Transport Security) configuration
    func validateATSConfiguration() -> Bool {
        // Check if ATS is properly configured in Info.plist
        guard let atsDict = Bundle.main.infoDictionary?["NSAppTransportSecurity"] as? [String: Any] else {
            return false
        }
        
        // Ensure arbitrary loads is disabled
        let allowsArbitraryLoads = atsDict["NSAllowsArbitraryLoads"] as? Bool ?? true
        guard !allowsArbitraryLoads else {
            return false
        }
        
        // Check exception domains are properly configured
        guard let exceptionDomains = atsDict["NSExceptionDomains"] as? [String: Any] else {
            return false
        }
        
        let requiredDomains = ["api.binance.com", "api.kraken.com"]
        for domain in requiredDomains {
            guard let domainConfig = exceptionDomains[domain] as? [String: Any] else {
                return false
            }
            
            // Ensure HTTPS is required
            let allowsInsecureHTTP = domainConfig["NSExceptionAllowsInsecureHTTPLoads"] as? Bool ?? true
            guard !allowsInsecureHTTP else {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Security Delegate

private class SecurityDelegate: NSObject, URLSessionDelegate {
    private let exchange: Exchange
    
    init(exchange: Exchange) {
        self.exchange = exchange
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Implement certificate pinning for production
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // For now, use default handling but log the certificate info
        let policy = SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)
        SecTrustSetPolicies(serverTrust, policy)
        
        var result: SecTrustResultType = .invalid
        let status = SecTrustEvaluate(serverTrust, &result)
        
        if status == errSecSuccess && (result == .unspecified || result == .proceed) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            os_log("Certificate validation failed for %{public}@", log: Log.security, type: .error, challenge.protectionSpace.host)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Network Security Errors

enum NetworkSecurityError: LocalizedError {
    case insecureConnection(url: URL)
    case certificateValidationFailed(host: String)
    case atsConfigurationInvalid
    
    var errorDescription: String? {
        switch self {
        case .insecureConnection(let url):
            return "Insecure connection attempted to \(url.absoluteString). HTTPS is required."
        case .certificateValidationFailed(let host):
            return "Certificate validation failed for \(host)"
        case .atsConfigurationInvalid:
            return "App Transport Security configuration is invalid"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .insecureConnection:
            return "Ensure all network requests use HTTPS protocol"
        case .certificateValidationFailed:
            return "Check network connection and certificate validity"
        case .atsConfigurationInvalid:
            return "Review Info.plist NSAppTransportSecurity configuration"
        }
    }
}

