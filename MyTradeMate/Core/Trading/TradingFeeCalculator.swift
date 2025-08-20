import Foundation

/// Trading fee calculator with configurable rates and comprehensive testing
/// Handles maker/taker fees, volume discounts, and fee cap scenarios
struct TradingFeeCalculator {
    
    // MARK: - Configuration
    
    struct FeeConfiguration {
        let makerFeeBps: Double       // Basis points (0.1% = 10 bps)
        let takerFeeBps: Double       // Basis points (0.1% = 10 bps)  
        let minimumFee: Double        // Minimum fee in quote currency
        let maximumFee: Double?       // Optional fee cap
        let volumeDiscountTiers: [VolumeDiscountTier]
        
        static let binanceSpot = FeeConfiguration(
            makerFeeBps: 10,          // 0.1%
            takerFeeBps: 10,          // 0.1%
            minimumFee: 0.00001,      // 1 satoshi equivalent
            maximumFee: nil,
            volumeDiscountTiers: [
                VolumeDiscountTier(monthlyVolumeThreshold: 0, discountBps: 0),
                VolumeDiscountTier(monthlyVolumeThreshold: 50000, discountBps: 5),    // VIP 1: 25% discount
                VolumeDiscountTier(monthlyVolumeThreshold: 500000, discountBps: 10)   // VIP 2: 50% discount
            ]
        )
        
        static let kraken = FeeConfiguration(
            makerFeeBps: 16,          // 0.16%
            takerFeeBps: 26,          // 0.26%
            minimumFee: 0.0001,
            maximumFee: nil,
            volumeDiscountTiers: []
        )
        
        static let paperTrading = FeeConfiguration(
            makerFeeBps: 5,           // Slightly optimistic for backtesting
            takerFeeBps: 8,
            minimumFee: 0.00001,
            maximumFee: nil,
            volumeDiscountTiers: []
        )
    }
    
    struct VolumeDiscountTier {
        let monthlyVolumeThreshold: Double  // USD volume
        let discountBps: Double            // Discount in basis points
    }
    
    // MARK: - Properties
    
    private let configuration: FeeConfiguration
    private let userMonthlyVolume: Double
    
    init(configuration: FeeConfiguration = .binanceSpot, userMonthlyVolume: Double = 0) {
        self.configuration = configuration
        self.userMonthlyVolume = userMonthlyVolume
    }
    
    // MARK: - Fee Calculation
    
    /// Calculate trading fee for a given order
    func calculateFee(
        notionalAmount: Double,
        orderType: OrderType,
        userVolumeUSD: Double = 0
    ) -> TradingFeeResult {
        
        // Determine base fee rate
        let baseFeeRate = orderType == .maker ? configuration.makerFeeBps : configuration.takerFeeBps
        
        // Apply volume discount
        let discountedFeeRate = applyVolumeDiscount(
            baseFeeRate: baseFeeRate, 
            userVolumeUSD: userVolumeUSD
        )
        
        // Calculate fee amount
        let feeAmount = (notionalAmount * discountedFeeRate) / 10000.0 // Convert from bps
        
        // Apply minimum/maximum constraints
        let constrainedFee = applyFeeConstraints(feeAmount)
        
        // Calculate effective fee percentage
        let effectiveFeeBps = (constrainedFee / notionalAmount) * 10000.0
        
        return TradingFeeResult(
            feeAmount: constrainedFee,
            feePercentage: effectiveFeeBps / 100.0, // Convert to percentage
            feeBasisPoints: effectiveFeeBps,
            baseFeeRate: baseFeeRate,
            discountApplied: baseFeeRate - discountedFeeRate,
            orderType: orderType,
            notionalAmount: notionalAmount
        )
    }
    
    /// Calculate round-trip fee (buy + sell)
    func calculateRoundTripFee(
        notionalAmount: Double,
        userVolumeUSD: Double = 0
    ) -> TradingFeeResult {
        let buyFee = calculateFee(notionalAmount: notionalAmount, orderType: .taker, userVolumeUSD: userVolumeUSD)
        let sellFee = calculateFee(notionalAmount: notionalAmount, orderType: .taker, userVolumeUSD: userVolumeUSD)
        
        let totalFee = buyFee.feeAmount + sellFee.feeAmount
        let totalFeeBps = (totalFee / notionalAmount) * 10000.0
        
        return TradingFeeResult(
            feeAmount: totalFee,
            feePercentage: totalFeeBps / 100.0,
            feeBasisPoints: totalFeeBps,
            baseFeeRate: buyFee.baseFeeRate + sellFee.baseFeeRate,
            discountApplied: buyFee.discountApplied + sellFee.discountApplied,
            orderType: .roundTrip,
            notionalAmount: notionalAmount
        )
    }
    
    /// Estimate breakeven price change needed to cover fees
    func breakevenPriceChange(
        entryPrice: Double,
        notionalAmount: Double,
        userVolumeUSD: Double = 0
    ) -> Double {
        let roundTripFee = calculateRoundTripFee(notionalAmount: notionalAmount, userVolumeUSD: userVolumeUSD)
        return roundTripFee.feePercentage // Percentage price change needed
    }
    
    // MARK: - Private Methods
    
    private func applyVolumeDiscount(baseFeeRate: Double, userVolumeUSD: Double) -> Double {
        let applicableTier = configuration.volumeDiscountTiers
            .filter { userVolumeUSD >= $0.monthlyVolumeThreshold }
            .max { $0.monthlyVolumeThreshold < $1.monthlyVolumeThreshold }
        
        guard let tier = applicableTier else {
            return baseFeeRate
        }
        
        return max(0, baseFeeRate - tier.discountBps)
    }
    
    private func applyFeeConstraints(_ feeAmount: Double) -> Double {
        var constrainedFee = max(feeAmount, configuration.minimumFee)
        
        if let maxFee = configuration.maximumFee {
            constrainedFee = min(constrainedFee, maxFee)
        }
        
        return constrainedFee
    }
}

// MARK: - Supporting Types

enum OrderType {
    case maker      // Limit order that adds liquidity
    case taker      // Market order that removes liquidity
    case roundTrip  // Buy + sell combination
}

struct TradingFeeResult {
    let feeAmount: Double           // Absolute fee in quote currency
    let feePercentage: Double       // Fee as percentage (0.1% = 0.1)
    let feeBasisPoints: Double      // Fee in basis points (0.1% = 10 bps)
    let baseFeeRate: Double         // Original fee rate before discounts
    let discountApplied: Double     // Discount in basis points
    let orderType: OrderType        // Type of order
    let notionalAmount: Double      // Trade size in quote currency
    
    var formattedFeePercentage: String {
        return String(format: "%.3f%%", feePercentage)
    }
    
    var formattedFeeAmount: String {
        return String(format: "%.8f", feeAmount)
    }
    
    /// Check if fee is within acceptable range (< 0.5% for most retail trading)
    var isReasonable: Bool {
        return feePercentage < 0.5
    }
}

// MARK: - Validation

extension TradingFeeCalculator {
    
    /// Validate fee calculation against known benchmarks
    static func validateFeeCalculation() -> Bool {
        let calculator = TradingFeeCalculator(configuration: .binanceSpot)
        
        // Test 1: $1000 taker order should be ~$1.00 fee (0.1%)
        let result1 = calculator.calculateFee(notionalAmount: 1000, orderType: .taker)
        let expected1 = 1.0
        guard abs(result1.feeAmount - expected1) < 0.01 else {
            print("❌ Fee validation failed: Expected ~\(expected1), got \(result1.feeAmount)")
            return false
        }
        
        // Test 2: Round trip should be ~2x single fee
        let roundTrip = calculator.calculateRoundTripFee(notionalAmount: 1000)
        guard abs(roundTrip.feeAmount - (result1.feeAmount * 2)) < 0.01 else {
            print("❌ Round trip validation failed")
            return false
        }
        
        // Test 3: Fee should never exceed 10% (sanity check)
        let largeOrder = calculator.calculateFee(notionalAmount: 100, orderType: .taker)
        guard largeOrder.feePercentage < 10.0 else {
            print("❌ Sanity check failed: Fee percentage too high")
            return false
        }
        
        print("✅ Fee calculation validation passed")
        return true
    }
}