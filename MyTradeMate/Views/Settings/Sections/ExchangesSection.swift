import SwiftUI

struct ExchangesSection: View {
    @State private var showBinanceKeys = false
    @State private var showKrakenKeys = false
    
    var body: some View {
        Section {
            Button("Binance API Keys") {
                showBinanceKeys = true
            }
            .foregroundColor(.blue)
            
            Button("Kraken API Keys") {
                showKrakenKeys = true
            }
            .foregroundColor(.blue)
        }
        .sheet(isPresented: $showBinanceKeys) {
            BinanceKeysView()
        }
        .sheet(isPresented: $showKrakenKeys) {
            KrakenKeysView()
        }
    }
}