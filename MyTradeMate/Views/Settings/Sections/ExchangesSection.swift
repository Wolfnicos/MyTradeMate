import SwiftUI

struct ExchangesSection: View {
    @State private var showBinanceKeys = false
    @State private var showKrakenKeys = false
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Button("Binance API Keys") {
                    showBinanceKeys = true
                }
                .foregroundColor(.blue)
                Text("Configure Binance API credentials for live trading and real-time market data access.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Button("Kraken API Keys") {
                    showKrakenKeys = true
                }
                .foregroundColor(.blue)
                Text("Configure Kraken API credentials for live trading and real-time market data access.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showBinanceKeys) {
            BinanceKeysView()
        }
        .sheet(isPresented: $showKrakenKeys) {
            KrakenKeysView()
        }
    }
}