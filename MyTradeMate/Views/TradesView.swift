import SwiftUI

struct TradesView: View {
    @StateObject private var vm = TradesVM()
    @State private var showCloseAllConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summarySection
                
                if vm.hasOpenPositions {
                    openPositionsSection
                }
                
                recentFillsSection
            }
            .padding()
        }
        .background(Bg.primary)
        .navigationTitle("Trades")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if vm.hasOpenPositions {
                    Button("Close All") {
                        showCloseAllConfirmation = true
                    }
                    .foregroundColor(Accent.red)
                }
            }
        }
        .alert("Close All Positions", isPresented: $showCloseAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Close All", role: .destructive) {
                vm.closeAllPositions()
            }
        } message: {
            Text("Are you sure you want to close all open positions?")
        }
        .onAppear {
            vm.refreshData()
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        Card {
            VStack(spacing: 12) {
                HStack {
                    Text("Total P&L")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                    
                    Spacer()
                }
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text(vm.totalPnLString)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(vm.totalPnLColor)
                    
                    Text("(\(String(format: "%.2f", vm.totalPnLPercent))%)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(vm.totalPnLColor.opacity(0.8))
                        .padding(.bottom, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open Positions")
                            .font(.system(size: 12))
                            .foregroundColor(TextColor.secondary)
                        
                        Text("\(vm.openPositions.count)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(TextColor.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Fills")
                            .font(.system(size: 12))
                            .foregroundColor(TextColor.secondary)
                        
                        Text("\(vm.recentFills.count)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(TextColor.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Open Positions Section
    private var openPositionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Open Positions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(TextColor.primary)
                .padding(.horizontal)
            
            ForEach(vm.openPositions) { position in
                PositionCard(position: position) {
                    vm.closePosition(position)
                }
            }
        }
    }
    
    // MARK: - Recent Fills Section
    private var recentFillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Fills")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(TextColor.primary)
                .padding(.horizontal)
            
            if vm.recentFills.isEmpty {
                Card {
                    Text("No recent fills")
                        .font(.system(size: 14))
                        .foregroundColor(TextColor.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                }
            } else {
                ForEach(vm.recentFills) { fill in
                    FillRow(fill: fill)
                }
            }
        }
    }
}

// MARK: - Position Card
struct PositionCard: View {
    let position: Trade
    let onClose: () -> Void
    
    var body: some View {
        Card {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text(position.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(TextColor.primary)
                    
                    Pill(text: position.side.displayName, color: position.side.color)
                    
                    if position.leverage > 1 {
                        Pill(text: "\(position.leverage)x", color: Brand.blue)
                    }
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(TextColor.secondary)
                    }
                }
                
                // Details
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Size")
                            .font(.system(size: 12))
                            .foregroundColor(TextColor.secondary)
                        
                        Text(position.sizeString)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(TextColor.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Entry")
                            .font(.system(size: 12))
                            .foregroundColor(TextColor.secondary)
                        
                        Text(position.entryPriceString)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(TextColor.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current")
                            .font(.system(size: 12))
                            .foregroundColor(TextColor.secondary)
                        
                        Text(position.currentPriceString)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(TextColor.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(position.pnlString)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(position.pnl >= 0 ? Accent.green : Accent.red)
                        
                        Text(position.pnlPercentString)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(position.pnl >= 0 ? Accent.green : Accent.red)
                            .opacity(0.8)
                    }
                }
            }
        }
    }
}

// MARK: - Fill Row
struct FillRow: View {
    let fill: Fill
    
    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(fill.symbol)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(TextColor.primary)
                        
                        Pill(text: fill.side.displayName, color: fill.side.color)
                    }
                    
                    HStack(spacing: 8) {
                        Text(fill.sizeString)
                            .font(.system(size: 12))
                            .foregroundColor(TextColor.secondary)
                        
                        Text("@")
                            .font(.system(size: 12))
                            .foregroundColor(TextColor.secondary)
                        
                        Text(fill.priceString)
                            .font(.system(size: 12))
                            .foregroundColor(TextColor.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(fill.timeString)
                        .font(.system(size: 12))
                        .foregroundColor(TextColor.secondary)
                    
                    Text("Fee: \(fill.feeString)")
                        .font(.system(size: 11))
                        .foregroundColor(TextColor.tertiary)
                }
            }
        }
    }
}

// MARK: - Preview
struct TradesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TradesView()
        }
    }
}
