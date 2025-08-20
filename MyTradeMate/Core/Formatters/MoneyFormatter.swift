import Foundation
import SwiftUI

/// Locale-aware money formatter with compact notation and semantic coloring
/// Handles different quote currencies with appropriate decimal precision
final class MoneyFormatter {
    
    // MARK: - Singleton
    static let shared = MoneyFormatter()
    
    // MARK: - Configuration
    
    private let currencyConfig: [String: CurrencyConfig] = [
        "USD": CurrencyConfig(symbol: "$", position: .prefix, decimals: 2, locale: Locale(identifier: "en_US")),
        "USDT": CurrencyConfig(symbol: "₮", position: .prefix, decimals: 2, locale: Locale(identifier: "en_US")),
        "USDC": CurrencyConfig(symbol: "USDC", position: .suffix, decimals: 2, locale: Locale(identifier: "en_US")),
        "EUR": CurrencyConfig(symbol: "€", position: .prefix, decimals: 2, locale: Locale(identifier: "de_DE")),
        "GBP": CurrencyConfig(symbol: "£", position: .prefix, decimals: 2, locale: Locale(identifier: "en_GB")),
        "JPY": CurrencyConfig(symbol: "¥", position: .prefix, decimals: 0, locale: Locale(identifier: "ja_JP")),
        "BTC": CurrencyConfig(symbol: "₿", position: .prefix, decimals: 8, locale: Locale(identifier: "en_US")),
        "ETH": CurrencyConfig(symbol: "Ξ", position: .prefix, decimals: 6, locale: Locale(identifier: "en_US")),
        "ADA": CurrencyConfig(symbol: "₳", position: .prefix, decimals: 6, locale: Locale(identifier: "en_US")),
        "SOL": CurrencyConfig(symbol: "◎", position: .prefix, decimals: 6, locale: Locale(identifier: "en_US"))
    ]
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Format currency value with locale-aware formatting and compact notation
    func format(
        value: Double,
        currency: String,
        style: FormatStyle = .standard,
        showChange: Bool = false,
        changeValue: Double? = nil
    ) -> FormattedMoney {
        let config = currencyConfig[currency.uppercased()] ?? defaultConfig(for: currency)
        let formatter = createFormatter(for: config, style: style)
        
        let absValue = abs(value)
        let formattedValue: String
        let compactSuffix: String
        
        // Apply compact notation based on style and value
        switch style {
        case .standard:
            if absValue >= 1_000_000_000 {
                formattedValue = formatter.string(from: NSNumber(value: value / 1_000_000_000)) ?? "\(value)"
                compactSuffix = "B"
            } else if absValue >= 1_000_000 {
                formattedValue = formatter.string(from: NSNumber(value: value / 1_000_000)) ?? "\(value)"
                compactSuffix = "M"
            } else if absValue >= 1_000 {
                formattedValue = formatter.string(from: NSNumber(value: value / 1_000)) ?? "\(value)"
                compactSuffix = "K"
            } else {
                formattedValue = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
                compactSuffix = ""
            }
            
        case .compact:
            if absValue >= 1_000_000_000 {
                formattedValue = String(format: "%.1f", value / 1_000_000_000)
                compactSuffix = "B"
            } else if absValue >= 1_000_000 {
                formattedValue = String(format: "%.1f", value / 1_000_000)
                compactSuffix = "M"
            } else if absValue >= 1_000 {
                formattedValue = String(format: "%.1f", value / 1_000)
                compactSuffix = "K"
            } else {
                formattedValue = String(format: "%.2f", value)
                compactSuffix = ""
            }
            
        case .exact:
            formattedValue = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
            compactSuffix = ""
            
        case .minimal:
            formattedValue = String(format: "%.0f", value)
            compactSuffix = ""
        }
        
        // Construct final string
        let finalValue = formattedValue + compactSuffix
        let displayString = buildDisplayString(value: finalValue, config: config, originalValue: value)
        
        // Calculate change if provided
        let changeFormatted = showChange ? formatChange(changeValue ?? 0, currency: currency) : nil
        
        return FormattedMoney(
            displayString: displayString,
            value: value,
            currency: currency,
            isPositive: value >= 0,
            changeFormatted: changeFormatted,
            semanticColor: semanticColor(for: value, showChange: showChange, changeValue: changeValue)
        )
    }
    
    /// Format percentage change with appropriate colors
    func formatPercentageChange(_ value: Double) -> FormattedChange {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = "+"
        
        let formatted = formatter.string(from: NSNumber(value: value / 100)) ?? "\(value)%"
        
        return FormattedChange(
            displayString: formatted,
            value: value,
            isPositive: value >= 0,
            semanticColor: value >= 0 ? .green : .red
        )
    }
    
    /// Format raw change value
    func formatChange(_ value: Double, currency: String) -> FormattedChange {
        let config = currencyConfig[currency.uppercased()] ?? defaultConfig(for: currency)
        let formatter = createFormatter(for: config, style: .standard)
        
        let prefix = value >= 0 ? "+" : ""
        let absValue = abs(value)
        
        let formattedValue: String
        if absValue >= 1_000_000 {
            formattedValue = String(format: "%.1fM", value / 1_000_000)
        } else if absValue >= 1_000 {
            formattedValue = String(format: "%.1fK", value / 1_000)
        } else {
            formattedValue = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        }
        
        let displayString = buildDisplayString(
            value: prefix + formattedValue,
            config: config,
            originalValue: value
        )
        
        return FormattedChange(
            displayString: displayString,
            value: value,
            isPositive: value >= 0,
            semanticColor: value >= 0 ? .green : .red
        )
    }
    
    // MARK: - Private Methods
    
    private func createFormatter(for config: CurrencyConfig, style: FormatStyle) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = config.locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = style != .minimal
        formatter.minimumFractionDigits = style == .minimal ? 0 : min(config.decimals, 2)
        formatter.maximumFractionDigits = style == .exact ? config.decimals : min(config.decimals, 2)
        
        return formatter
    }
    
    private func buildDisplayString(value: String, config: CurrencyConfig, originalValue: Double) -> String {
        switch config.position {
        case .prefix:
            return "\(config.symbol)\(value)"
        case .suffix:
            return "\(value) \(config.symbol)"
        }
    }
    
    private func defaultConfig(for currency: String) -> CurrencyConfig {
        CurrencyConfig(
            symbol: currency.uppercased(),
            position: .suffix,
            decimals: 2,
            locale: Locale.current
        )
    }
    
    private func semanticColor(for value: Double, showChange: Bool, changeValue: Double?) -> Color {
        if showChange, let change = changeValue {
            return change >= 0 ? DesignTokens.Colors.success : DesignTokens.Colors.error
        } else {
            return value >= 0 ? DesignTokens.Colors.onSurface : DesignTokens.Colors.error
        }
    }
}

// MARK: - Supporting Types

/// Currency configuration for locale-aware formatting
struct CurrencyConfig {
    let symbol: String
    let position: SymbolPosition
    let decimals: Int
    let locale: Locale
    
    enum SymbolPosition {
        case prefix, suffix
    }
}

/// Money formatting style options
enum FormatStyle {
    case standard   // $1.23K with locale formatting
    case compact    // $1.2K minimal formatting
    case exact      // $1,234.56789 full precision
    case minimal    // $1234 no decimals or separators
}

/// Formatted money result with semantic information
struct FormattedMoney {
    let displayString: String
    let value: Double
    let currency: String
    let isPositive: Bool
    let changeFormatted: FormattedChange?
    let semanticColor: Color
}

/// Formatted change result with semantic information
struct FormattedChange {
    let displayString: String
    let value: Double
    let isPositive: Bool
    let semanticColor: Color
}

// MARK: - SwiftUI Integration

extension View {
    /// Apply semantic coloring based on formatted money result
    func moneyColor(_ formattedMoney: FormattedMoney) -> some View {
        self.foregroundColor(formattedMoney.semanticColor)
    }
    
    /// Apply semantic coloring based on formatted change result
    func changeColor(_ formattedChange: FormattedChange) -> some View {
        self.foregroundColor(formattedChange.semanticColor)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension MoneyFormatter {
    static let preview = MoneyFormatter.shared
    
    static var sampleValues: [(Double, String)] {
        [
            (1234.56, "USD"),
            (1234567.89, "EUR"),
            (0.00012345, "BTC"),
            (1.23456789, "ETH"),
            (-500.25, "USDT"),
            (1_500_000_000, "USD"),
            (999.99, "GBP"),
            (0, "USD")
        ]
    }
}
#endif