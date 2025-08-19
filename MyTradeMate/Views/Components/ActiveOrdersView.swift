import SwiftUI
import UIKit

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

// MARK: - Order Status Update View (Modernized)
struct OrderStatusUpdateView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let update: OrderStatusUpdate
    
    // Modern 2025 UI State
    @State private var isVisible = false
    @State private var showDetails = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(themeManager.defaultAnimation) {
                showDetails.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // Modern status indicator with glow
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                        .shadow(color: statusColor.opacity(0.5), radius: 4, x: 0, y: 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order \(String(update.orderId.prefix(8)))")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(TextColor.primary)
                    
                    HStack(spacing: 8) {
                        Text(update.status.rawValue.capitalized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(statusColor.opacity(0.1))
                            )
                        
                        if showDetails {
                            Text(update.message ?? "No message")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(TextColor.secondary)
                                .lineLimit(2)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(timeAgo(from: update.timestamp))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TextColor.secondary)
                    
                    // Animated chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(TextColor.secondary)
                        .rotationEffect(.degrees(showDetails ? 90 : 0))
                        .animation(themeManager.defaultAnimation, value: showDetails)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                themeManager.neumorphicCardBackground()
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(statusColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .animation(themeManager.defaultAnimation.delay(0.1), value: isVisible)
        .onAppear {
            withAnimation(themeManager.defaultAnimation.delay(0.1)) {
                isVisible = true
            }
        }
    }
    
    private var statusColor: Color {
        switch update.status {
        case .pending: return themeManager.primaryColor
        case .filled: return themeManager.successColor
        case .cancelled, .rejected: return themeManager.errorColor
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

// MARK: - Active Orders View (Modernized)
struct ActiveOrdersView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var orderTracker = OrderStatusTracker.shared
    @State private var showingAllOrders = false
    
    // Modern 2025 UI State
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Modern header
            modernHeaderView
            
            // Active orders list
            if orderTracker.activeOrders.isEmpty {
                modernEmptyStateView
            } else {
                modernActiveOrdersList
            }
        }
        .padding(20)
        .background(
            themeManager.neumorphicCardBackground()
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $showingAllOrders) {
            OrderStatusListView()
        }
        .refreshable {
            await refreshWithHaptics()
        }
    }
    
    // MARK: - Modern Header
    
    private var modernHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeManager.primaryColor)
                    
                    Text("Active Orders")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(TextColor.primary)
                }
                
                Text("\(orderTracker.activeOrders.count) pending orders")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(TextColor.secondary)
            }
            
            Spacer()
            
            if !orderTracker.activeOrders.isEmpty {
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingAllOrders = true
                }) {
                    HStack(spacing: 6) {
                        Text("View All")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.primaryColor)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeManager.primaryColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        themeManager.primaryColor.opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Modern Active Orders List
    
    private var modernActiveOrdersList: some View {
        VStack(spacing: 12) {
            ForEach(Array(orderTracker.activeOrders.values.prefix(3))) { order in
                OrderStatusUpdateView(update: order)
            }
            
            // Show more indicator if there are more than 3 orders
            if orderTracker.activeOrders.count > 3 {
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingAllOrders = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.accentColor)
                        
                        Text("View \(orderTracker.activeOrders.count - 3) more orders")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.accentColor)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        themeManager.accentColor.opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Modern Empty State
    
    private var modernEmptyStateView: some View {
        VStack(spacing: 16) {
            // Modern icon with gradient
            ZStack {
                Circle()
                    .fill(themeManager.primaryColor.opacity(0.1))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(themeManager.primaryColor)
            }
            
            VStack(spacing: 8) {
                Text("No active orders")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(TextColor.primary)
                
                Text("Orders will appear here when you place them")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(TextColor.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func refreshWithHaptics() async {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

// MARK: - Order Statistics Widget (Modernized)
struct OrderStatisticsWidget: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var orderTracker = OrderStatusTracker.shared
    @State private var statistics: SimpleOrderStatistics? = nil
    
    // Modern 2025 UI State
    @State private var isVisible = false
    @State private var animateValues = false

struct OrderStatistics {
    let totalOrders: Int
    let successfulOrders: Int
    let failedOrders: Int
    let averageExecutionTime: TimeInterval
}
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Modern header
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.accentColor)
                
                Text("Order Statistics")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(TextColor.primary)
            }
            
            if let stats = statistics {
                modernStatisticsContent(stats)
            } else {
                modernLoadingView
            }
        }
        .padding(20)
        .background(
            themeManager.neumorphicCardBackground()
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(themeManager.defaultAnimation.delay(0.2), value: isVisible)
        .onAppear {
            withAnimation(themeManager.defaultAnimation.delay(0.2)) {
                isVisible = true
            }
            updateStatistics()
        }
        .onReceive(orderTracker.$activeOrders) { _ in
            updateStatistics()
        }
        .onReceive(orderTracker.$orderHistory) { _ in
            updateStatistics()
        }
    }
    
    private func modernStatisticsContent(_ stats: SimpleOrderStatistics) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ModernStatisticItem(
                    title: "Total Orders",
                    value: "\(stats.totalOrders)",
                    color: themeManager.primaryColor,
                    icon: "number.circle.fill"
                )
                
                Spacer()
                
                ModernStatisticItem(
                    title: "Success Rate",
                    value: stats.successRatePercentage,
                    color: themeManager.successColor,
                    icon: "checkmark.circle.fill"
                )
            }
            
            HStack(spacing: 16) {
                ModernStatisticItem(
                    title: "Active",
                    value: "\(stats.activeOrders)",
                    color: themeManager.primaryColor,
                    icon: "clock.fill"
                )
                
                Spacer()
                
                ModernStatisticItem(
                    title: "Avg. Time",
                    value: stats.averageExecutionTimeFormatted,
                    color: themeManager.warningColor,
                    icon: "timer"
                )
            }
        }
        .opacity(animateValues ? 1 : 0)
        .animation(themeManager.defaultAnimation.delay(0.3), value: animateValues)
        .onAppear {
            withAnimation(themeManager.defaultAnimation.delay(0.3)) {
                animateValues = true
            }
        }
    }
    
    private var modernLoadingView: some View {
        HStack(spacing: 16) {
            // Modern animated progress indicator
            ZStack {
                Circle()
                    .stroke(themeManager.primaryColor.opacity(0.2), lineWidth: 3)
                    .frame(width: 32, height: 32)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [themeManager.primaryColor, themeManager.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(animateValues ? 360 : 0))
                    .animation(
                        themeManager.slowAnimation.repeatForever(autoreverses: false),
                        value: animateValues
                    )
            }
            
            Text("Loading statistics...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(TextColor.secondary)
        }
        .onAppear {
            animateValues = true
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

// MARK: - Modern Statistic Item
struct ModernStatisticItem: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    // Modern 2025 UI State
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(TextColor.secondary)
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            color.opacity(0.05)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .animation(themeManager.defaultAnimation.delay(0.1), value: isVisible)
        .onAppear {
            withAnimation(themeManager.defaultAnimation.delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Legacy Statistic Item (Enhanced)
struct StatisticItem: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(TextColor.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Recent Order Updates View (Modernized)
struct RecentOrderUpdatesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var orderTracker = OrderStatusTracker.shared
    @State private var showingAllUpdates = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Modern header
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeManager.accentColor)
                
                Text("Recent Activity")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(TextColor.primary)
                
                Spacer()
                
                if !Array(orderTracker.orderHistory.suffix(10)).isEmpty {
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showingAllUpdates = true
                    }) {
                        HStack(spacing: 6) {
                            Text("View All")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.accentColor)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(themeManager.accentColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            themeManager.accentColor.opacity(0.1)
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            
            // Recent updates
            if Array(orderTracker.orderHistory.suffix(10)).isEmpty {
                modernEmptyActivityView
            } else {
                modernRecentUpdatesList
            }
        }
        .padding(20)
        .background(
            themeManager.neumorphicCardBackground()
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .sheet(isPresented: $showingAllUpdates) {
            RecentUpdatesListView()
        }
    }
    
    private var modernRecentUpdatesList: some View {
        VStack(spacing: 12) {
            ForEach(Array(Array(orderTracker.orderHistory.suffix(10)).prefix(5))) { update in
                ModernRecentUpdateRow(update: update)
            }
            
            if Array(orderTracker.orderHistory.suffix(10)).count > 5 {
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    showingAllUpdates = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.accentColor)
                        
                        Text("View \(Array(orderTracker.orderHistory.suffix(10)).count - 5) more updates")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.accentColor)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        themeManager.accentColor.opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    private var modernEmptyActivityView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(themeManager.accentColor.opacity(0.6))
            
            Text("No recent activity")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(TextColor.secondary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Modern Recent Update Row
struct ModernRecentUpdateRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    let update: OrderStatusUpdate
    
    // Modern 2025 UI State
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Modern status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 20, height: 20)
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: statusColor.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            
            // Update message
            Text(update.message ?? update.status.rawValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(TextColor.primary)
                .lineLimit(1)
            
            Spacer()
            
            // Timestamp
            Text(formatTimestamp(update.timestamp))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(TextColor.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    themeManager.primaryColor.opacity(0.1)
                )
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            themeManager.primaryColor.opacity(0.02)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -10)
        .animation(themeManager.defaultAnimation.delay(0.1), value: isVisible)
        .onAppear {
            withAnimation(themeManager.defaultAnimation.delay(0.1)) {
                isVisible = true
            }
        }
    }
    
    private var statusColor: Color {
        switch update.status {
        case .pending:
            return themeManager.primaryColor
        case .filled:
            return themeManager.successColor
        case .cancelled:
            return themeManager.warningColor
        case .rejected:
            return themeManager.errorColor
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Recent Updates List View (Enhanced)
struct RecentUpdatesListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var orderTracker = OrderStatusTracker.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(orderTracker.orderHistory.suffix(10))) { update in
                        ModernRecentUpdateRow(update: update)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(themeManager.backgroundGradient)
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
    .background(ThemeManager.shared.backgroundGradient)
    .environmentObject(ThemeManager.shared)
}