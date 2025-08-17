import Foundation
import Combine

/// Foreign exchange service for USD/EUR conversion
@MainActor
public final class FXService: ObservableObject {
    public static let shared = FXService()
    
    @Published public private(set) var rates: [String: Double] = [:]
    @Published public private(set) var lastUpdated: Date?
    @Published public private(set) var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let cacheKey = "FXService.rates"
    private let lastUpdatedKey = "FXService.lastUpdated"
    
    // Mock/static rates for now - in production, fetch from real API
    private let mockRates: [String: Double] = [
        "USD/EUR": 0.85,    // 1 USD = 0.85 EUR
        "EUR/USD": 1.18,    // 1 EUR = 1.18 USD
        "USD/USD": 1.0,     // Identity
        "EUR/EUR": 1.0      // Identity
    ]
    
    private init() {
        loadCachedRates()
        Task { await refreshRates() }
        
        // Auto-refresh every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refreshRates() }
            }
            .store(in: &cancellables)
    }
    
    /// Convert value from one currency to another
    public func convert(_ value: Double, from: QuoteCurrency, to: QuoteCurrency) -> Double {
        // Same currency - no conversion needed
        if from == to {
            return value
        }
        
        let rateKey = "\(from.rawValue)/\(to.rawValue)"
        guard let rate = rates[rateKey] else {
            Log.error(NSError(domain: "FXService", code: 1, userInfo: [NSLocalizedDescriptionKey: "❌ FX rate not found for \(rateKey), using 1.0"]), context: "FX conversion", category: .network)
            return value
        }
        
        let converted = value * rate
        Log.verbose("💱 FX convert: \(String(format: "%.2f", value)) \(from.rawValue) → \(String(format: "%.2f", converted)) \(to.rawValue) (rate: \(String(format: "%.4f", rate)))", category: .data)
        
        return converted
    }
    
    /// Get exchange rate between two currencies
    public func getRate(from: QuoteCurrency, to: QuoteCurrency) -> Double {
        if from == to { return 1.0 }
        
        let rateKey = "\(from.rawValue)/\(to.rawValue)"
        return rates[rateKey] ?? 1.0
    }
    
    /// Format currency value with proper symbol
    public func formatValue(_ value: Double, currency: QuoteCurrency) -> String {
        return "\(currency.symbol)\(String(format: "%.2f", value))"
    }
    
    /// Refresh exchange rates
    public func refreshRates() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // In production, fetch from real FX API (e.g., exchangerate-api.com, fixer.io)
            // For now, use mock rates with slight randomization to simulate real data
            let simulatedRates = simulateRateVariation()
            
            rates = simulatedRates
            lastUpdated = Date()
            
            // Cache the rates
            cacheRates()
            
            Log.app.info("💱 FX rates updated: USD/EUR=\(String(format: "%.4f", rates["USD/EUR"] ?? 0)), EUR/USD=\(String(format: "%.4f", rates["EUR/USD"] ?? 0))")
            
        } catch {
            Log.error(error, context: "FX rates refresh", category: .network)
        }
    }
    
    /// Simulate rate variation for demo purposes
    private func simulateRateVariation() -> [String: Double] {
        var simulatedRates = mockRates
        
        // Add small random variation (±2%) to simulate real market movement
        for (key, baseRate) in mockRates {
            if key != "USD/USD" && key != "EUR/EUR" {
                let variation = Double.random(in: 0.98...1.02)
                simulatedRates[key] = baseRate * variation
            }
        }
        
        return simulatedRates
    }
    
    /// Load cached rates from UserDefaults
    private func loadCachedRates() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cachedRates = try? JSONDecoder().decode([String: Double].self, from: data) {
            self.rates = cachedRates
        } else {
            // Use mock rates as fallback
            self.rates = mockRates
        }
        
        if let timestamp = UserDefaults.standard.object(forKey: lastUpdatedKey) as? Date {
            self.lastUpdated = timestamp
        }
        
        Log.app.debug("💱 Loaded cached FX rates: \(rates.count) pairs")
    }
    
    /// Cache rates to UserDefaults
    private func cacheRates() {
        if let data = try? JSONEncoder().encode(rates) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
        
        if let lastUpdated = lastUpdated {
            UserDefaults.standard.set(lastUpdated, forKey: lastUpdatedKey)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    /// Get formatted rate display string
    public func getRateDisplayString(from: QuoteCurrency, to: QuoteCurrency) -> String {
        let rate = getRate(from: from, to: to)
        return "1 \(from.rawValue) = \(String(format: "%.4f", rate)) \(to.rawValue)"
    }
    
    /// Check if rates are stale (older than 4 hours)
    public var ratesAreStale: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > 14400 // 4 hours
    }
}

// MARK: - Production FX API Integration (commented out for now)

extension FXService {
    /// Fetch rates from real FX API (implementation example)
    private func fetchLiveRates() async throws -> [String: Double] {
        // Example implementation for production use:
        /*
        let url = URL(string: "https://api.exchangerate-api.com/v4/latest/USD")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct FXResponse: Codable {
            let rates: [String: Double]
        }
        
        let response = try JSONDecoder().decode(FXResponse.self, from: data)
        
        // Extract only the rates we need
        var filteredRates: [String: Double] = [:]
        filteredRates["USD/EUR"] = response.rates["EUR"] ?? 0.85
        filteredRates["EUR/USD"] = 1.0 / (response.rates["EUR"] ?? 0.85)
        filteredRates["USD/USD"] = 1.0
        filteredRates["EUR/EUR"] = 1.0
        
        return filteredRates
        */
        
        // For now, return mock rates
        return mockRates
    }
}

// MARK: - Convenience Extensions

extension Double {
    /// Convert this value from one currency to another
    @MainActor
    func converted(from: QuoteCurrency, to: QuoteCurrency) -> Double {
        return FXService.shared.convert(self, from: from, to: to)
    }
    
    /// Format as currency value
    @MainActor
    func formatted(as currency: QuoteCurrency) -> String {
        return FXService.shared.formatValue(self, currency: currency)
    }
}