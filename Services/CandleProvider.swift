import Foundation

public protocol CandleProvider {
    /// Returns candles for the given symbol and timeframe.
    /// - Parameters:
    ///   - symbol: unified trading symbol, e.g. "BTCUSDT"
    ///   - timeframe: enum used in the app (m1, m5, h1, h4, d1)
    ///   - since: optional start date (UTC)
    ///   - until: optional end date (UTC). If nil, use Date()
    ///   - limit: max number of candles to return (cap at exchange limits)
    func fetchCandles(
        symbol: String,
        timeframe: Timeframe,
        since: Date?,
        until: Date?,
        limit: Int
    ) async throws -> [Candle]
}
