import SwiftUI

// MARK: - Order Status View
struct OrderStatusView: View {
    let trackedOrder: TrackedOrder
    let showDetails: Bool
    
    init(trackedOrder: TrackedOrder, showDetails: Bool = false) {
        self.trackedOrder = trackedOrder
        self.showDetails = showDetails
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with order info
            orderHeaderView
            
            // Status indicator
            statusIndicatorView
            
            // Details if requested
            if showDetails {
                orderDetailsView
            }
            
            // Error message if any
            if let errorMessage = trackedOrder.errorMessage {
                errorMessageView(errorMessage)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Header View
    
    private var orderHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(trackedOrder.originalRequest.symbol)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(trackedOrder.originalRequest.side.rawValue.capitalized) • \(formatAmount(trackedOrder.originalRequest.amount))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(trackedOrder.currentStatus.displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
                
                Text(formatDuration(trackedOrder.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicatorView: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIconView
            
            // Progress bar for active orders
            if trackedOrder.isActive {
                progressBarView
            } else {
                // Final status text
                Text(trackedOrder.currentStatus.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
            }
            
            Spacer()
        }
    }
    
    private var statusIconView: some View {
        Group {
            if trackedOrder.isActive {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(statusColor)
            } else if trackedOrder.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 16))
            } else if trackedOrder.isFailed {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            } else {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
            }
        }
    }
    
    private var progressBarView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(trackedOrder.currentStatus.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                Text("\(Int(trackedOrder.currentStatus.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: trackedOrder.currentStatus.progress)
                .tint(statusColor)
                .scaleEffect(y: 0.8)
        }
    }
    
    // MARK: - Order Details
    
    private var orderDetailsView: some View {
        VStack(spacing: 8) {
            Divider()
            
            VStack(spacing: 6) {
                DetailRow(label: "Order ID", value: String(trackedOrder.id.prefix(8)))
                DetailRow(label: "Created", value: formatTimestamp(trackedOrder.createdAt))
                DetailRow(label: "Trading Mode", value: trackedOrder.originalRequest.displayMode)
                
                if let orderFill = trackedOrder.orderFill {
                    DetailRow(label: "Fill Price", value: "$\(orderFill.price, specifier: "%.2f")")
                    DetailRow(label: "Fill Time", value: formatTimestamp(orderFill.timestamp))
                }
                
                if let estimatedCompletion = trackedOrder.estimatedCompletion,
                   trackedOrder.isActive {
                    DetailRow(label: "Est. Completion", value: formatTimestamp(estimatedCompletion))
                }
            }
            
            // Status history
            if !trackedOrder.statusHistory.isEmpty {
                statusHistoryView
            }
        }
    }
    
    private var statusHistoryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            Text("Status History")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                ForEach(trackedOrder.statusHistory.reversed()) { update in
                    HStack {
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 4, height: 4)
                        
                        Text(update.message ?? update.status.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatTimestamp(update.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Error Message
    
    private func errorMessageView(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 14))
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .lineLimit(3)
            
            Spacer()
        }
        .padding(8)
        .background(.red.opacity(0.1))
        .cornerRadius(6)
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        if trackedOrder.isActive {
            return .blue
        } else if trackedOrder.isCompleted {
            return .green
        } else if trackedOrder.isFailed {
            return .red
        } else {
            return .orange
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatAmount(_ amount: Double) -> String {
        if amount >= 1.0 {
            return String(format: "%.4f", amount)
        } else if amount >= 0.001 {
            return String(format: "%.6f", amount)
        } else {
            return String(format: "%.8f", amount)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.0fs", duration)
        } else if duration < 3600 {
            return String(format: "%.0fm", duration / 60)
        } else {
            return String(format: "%.1fh", duration / 3600)
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Order Status List View
struct OrderStatusListView: View {
    @StateObject private var orderTracker = OrderStatusTracker.shared
    @State private var showingActiveOnly = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter toggle
                filterToggleView
                
                // Orders list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredOrders) { order in
                            OrderStatusView(trackedOrder: order, showDetails: true)
                        }
                    }
                    .padding()
                }
                
                // Empty state
                if filteredOrders.isEmpty {
                    emptyStateView
                }
            }
            .navigationTitle("Order Status")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var filterToggleView: some View {
        HStack {
            Picker("Filter", selection: $showingActiveOnly) {
                Text("Active").tag(true)
                Text("All").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 200)
            
            Spacer()
            
            Text("\(filteredOrders.count) orders")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var filteredOrders: [TrackedOrder] {
        if showingActiveOnly {
            return orderTracker.activeOrders
        } else {
            return orderTracker.getRecentOrders()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(showingActiveOnly ? "No Active Orders" : "No Recent Orders")
                .font(.headline)
            
            Text(showingActiveOnly ? 
                 "Orders will appear here when you place them" :
                 "Your order history will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Compact Order Status View
struct CompactOrderStatusView: View {
    let trackedOrder: TrackedOrder
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Group {
                if trackedOrder.isActive {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.blue)
                } else if trackedOrder.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .frame(width: 16, height: 16)
            
            // Order info
            VStack(alignment: .leading, spacing: 2) {
                Text("\(trackedOrder.originalRequest.side.rawValue.capitalized) \(trackedOrder.originalRequest.symbol)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(trackedOrder.currentStatus.displayText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Duration
            Text(formatDuration(trackedOrder.duration))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.0fs", duration)
        } else {
            return String(format: "%.0fm", duration / 60)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Active order
        OrderStatusView(
            trackedOrder: TrackedOrder(
                originalRequest: TradeRequest(
                    symbol: "BTC/USDT",
                    side: .buy,
                    amount: 0.001,
                    price: 45000.0,
                    mode: .manual,
                    isDemo: false
                ),
                currentStatus: .pending
            ),
            showDetails: true
        )
        
        // Completed order
        OrderStatusView(
            trackedOrder: {
                var order = TrackedOrder(
                    originalRequest: TradeRequest(
                        symbol: "ETH/USDT",
                        side: .sell,
                        amount: 0.5,
                        price: 3200.0,
                        mode: .live,
                        isDemo: true
                    ),
                    currentStatus: .filled
                )
                order.updateStatus(.filled, message: "Order executed successfully")
                return order
            }(),
            showDetails: false
        )
        
        Spacer()
    }
    .padding()
    .background(Color(.systemBackground))
}