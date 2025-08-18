import SwiftUI

// MARK: - Simple Order Statistics
struct SimpleOrderStatistics {
    let totalOrders: Int
    let activeOrders: Int
    let completedOrders: Int
    let failedOrders: Int
    
    var successRatePercentage: String {
        let total = completedOrders + failedOrders
        if total == 0 { return "0%" }
        let rate = Double(completedOrders) / Double(total) * 100
        return String(format: "%.1f%%", rate)
    }
    
    var averageExecutionTimeFormatted: String {
        // Simple placeholder since we don't track execution time
        return "N/A"
    }
}

// MARK: - Order Status Update View
struct OrderStatusUpdateView: View {
    let update: OrderStatusUpdate
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Order \(String(update.orderId.prefix(8)))")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(update.status.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timeAgo(from: update.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch update.status {
        case .pending: return .blue
        case .filled: return .green
        case .cancelled, .rejected: return .red
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval/60))m ago"
        } else {
            return "\(Int(interval/3600))h ago"
        }
    }
}

// MARK: - Active Orders View
struct ActiveOrdersView: View {
    @StateObject private var orderTracker = OrderStatusTracker.shared
    @State private var showingAllOrders = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            headerView
            
            // Active orders list
            if orderTracker.activeOrders.isEmpty {
                emptyStateView
            } else {
                activeOrdersList
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingAllOrders) {
            OrderStatusListView()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Active Orders")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(orderTracker.activeOrders.count) pending")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !orderTracker.activeOrders.isEmpty {
                Button("View All") {
                    showingAllOrders = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Active Orders List
    
    private var activeOrdersList: some View {
        VStack(spacing: 8) {
            ForEach(Array(orderTracker.activeOrders.values.prefix(3))) { order in
                OrderStatusUpdateView(update: order)
            }
            
            // Show more indicator if there are more than 3 orders
            if orderTracker.activeOrders.count > 3 {
                Button("View \(orderTracker.activeOrders.count - 3) more orders") {
                    showingAllOrders = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            
            Text("No active orders")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Orders will appear here when you place them")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Order Statistics Widget
struct OrderStatisticsWidget: View {
    @StateObject private var orderTracker = OrderStatusTracker.shared
    @State private var statistics: SimpleOrderStatistics? = nil

struct OrderStatistics {
    let totalOrders: Int
    let successfulOrders: Int
    let failedOrders: Int
    let averageExecutionTime: TimeInterval
}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let stats = statistics {
                statisticsContent(stats)
            } else {
                loadingView
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            updateStatistics()
        }
        .onReceive(orderTracker.$activeOrders) { _ in
            updateStatistics()
        }
        .onReceive(orderTracker.$orderHistory) { _ in
            updateStatistics()
        }
    }
    
    private func statisticsContent(_ stats: SimpleOrderStatistics) -> some View {
        VStack(spacing: 8) {
            HStack {
                StatisticItem(
                    title: "Total Orders",
                    value: "\(stats.totalOrders)",
                    color: .primary
                )
                
                Spacer()
                
                StatisticItem(
                    title: "Success Rate",
                    value: stats.successRatePercentage,
                    color: .green
                )
            }
            
            HStack {
                StatisticItem(
                    title: "Active",
                    value: "\(stats.activeOrders)",
                    color: .blue
                )
                
                Spacer()
                
                StatisticItem(
                    title: "Avg. Time",
                    value: stats.averageExecutionTimeFormatted,
                    color: .orange
                )
            }
        }
    }
    
    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Loading statistics...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func updateStatistics() {
        let completed = orderTracker.orderHistory.filter { $0.status == .filled }.count
        let failed = orderTracker.orderHistory.filter { $0.status == .cancelled || $0.status == .rejected }.count
        
        statistics = SimpleOrderStatistics(
            totalOrders: orderTracker.orderHistory.count,
            activeOrders: orderTracker.activeOrders.count,
            completedOrders: completed,
            failedOrders: failed
        )
    }
}

// MARK: - Statistic Item
struct StatisticItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Recent Order Updates View
struct RecentOrderUpdatesView: View {
    @StateObject private var orderTracker = OrderStatusTracker.shared
    @State private var showingAllUpdates = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !Array(orderTracker.orderHistory.suffix(10)).isEmpty {
                    Button("View All") {
                        showingAllUpdates = true
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
            
            // Recent updates
            if Array(orderTracker.orderHistory.suffix(10)).isEmpty {
                emptyActivityView
            } else {
                recentUpdatesList
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingAllUpdates) {
            RecentUpdatesListView()
        }
    }
    
    private var recentUpdatesList: some View {
        VStack(spacing: 6) {
            ForEach(Array(Array(orderTracker.orderHistory.suffix(10)).prefix(5))) { update in
                RecentUpdateRow(update: update)
            }
            
            if Array(orderTracker.orderHistory.suffix(10)).count > 5 {
                Button("View \(Array(orderTracker.orderHistory.suffix(10)).count - 5) more updates") {
                    showingAllUpdates = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 4)
            }
        }
    }
    
    private var emptyActivityView: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
            
            Text("No recent activity")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recent Update Row
struct RecentUpdateRow: View {
    let update: OrderStatusUpdate
    
    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            // Update message
            Text(update.message ?? update.status.rawValue)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
            
            // Timestamp
            Text(formatTimestamp(update.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
    
    private var statusColor: Color {
        switch update.status {
        case .pending:
            return .blue
        case .filled:
            return .green
        case .cancelled:
            return .orange
        case .rejected:
            return .red
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Recent Updates List View
struct RecentUpdatesListView: View {
    @StateObject private var orderTracker = OrderStatusTracker.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(orderTracker.orderHistory.suffix(10))) { update in
                        RecentUpdateRow(update: update)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Recent Activity")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ActiveOrdersView()
        OrderStatisticsWidget()
        RecentOrderUpdatesView()
        Spacer()
    }
    .padding()
    .background(Color(.systemBackground))
}