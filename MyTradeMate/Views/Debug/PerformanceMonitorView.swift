import SwiftUI

struct PerformanceMonitorView: View {
    @StateObject private var memoryManager = MemoryPressureManager.shared
    @StateObject private var inferenceThrottler = InferenceThrottler.shared
    @StateObject private var connectionManager = ConnectionManager.shared
    @StateObject private var cacheManager = DataCacheManager.shared
    
    @State private var memoryUsage = MemoryUsage(usedMemoryMB: 0, totalMemoryMB: 0, usagePercentage: 0)
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationStack {
            List {
                memorySection
                inferenceSection
                connectionSection
                cacheSection
                actionsSection
            }
            .navigationTitle("Performance Monitor")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                startRefreshTimer()
            }
            .onDisappear {
                stopRefreshTimer()
            }
        }
    }
    
    private var memorySection: some View {
        Section("Memory Management") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Memory Usage")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(String(format: "%.1f", memoryUsage.usedMemoryMB))MB / \(String(format: "%.1f", memoryUsage.totalMemoryMB))MB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: memoryUsage.usagePercentage / 100.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: memoryUsage.usagePercentage > 80 ? .red : memoryUsage.usagePercentage > 60 ? .orange : .green))
                
                HStack {
                    Text("Pressure Level")
                        .font(.caption)
                    Spacer()
                    Text(memoryManager.memoryPressureLevel.description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(memoryPressureColor)
                }
                
                if memoryManager.isMemoryWarningActive {
                    Label("Memory Warning Active", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var inferenceSection: some View {
        Section("AI Inference") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Throttle Level")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(inferenceThrottler.currentThrottleLevel.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total Inferences")
                        .font(.caption)
                    Spacer()
                    Text("\(inferenceThrottler.inferenceCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Inference Rate")
                        .font(.caption)
                    Spacer()
                    Text("\(String(format: "%.1f", inferenceThrottler.getInferenceRate()))/min")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                let throttleStatus = inferenceThrottler.getThrottleStatus()
                if !throttleStatus.canInferNow {
                    HStack {
                        Text("Next Inference")
                            .font(.caption)
                        Spacer()
                        Text("\(String(format: "%.1f", throttleStatus.nextInferenceIn))s")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var connectionSection: some View {
        Section("Network Connections") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Network Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(connectionManager.networkStatus.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Connection Quality")
                        .font(.caption)
                    Spacer()
                    Text(connectionManager.connectionQuality.description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(connectionQualityColor)
                }
                
                HStack {
                    Text("Active Connections")
                        .font(.caption)
                    Spacer()
                    Text("\(connectionManager.activeConnections.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Intelligent Mode")
                        .font(.caption)
                    Spacer()
                    Text(connectionManager.isIntelligentModeEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(connectionManager.isIntelligentModeEnabled ? .green : .orange)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var cacheSection: some View {
        Section("Data Caching") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Caches")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(cacheManager.cacheStats.totalCaches)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Cached Items")
                        .font(.caption)
                    Spacer()
                    Text("\(cacheManager.cacheStats.totalItems)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Cache Memory")
                        .font(.caption)
                    Spacer()
                    Text("\(String(format: "%.1f", cacheManager.cacheStats.totalMemoryMB))MB")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Memory Usage")
                        .font(.caption)
                    Spacer()
                    Text("\(String(format: "%.1f", cacheManager.cacheStats.memoryUsagePercent))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(cacheManager.cacheStats.memoryUsagePercent > 80 ? .red : .primary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private var actionsSection: some View {
        Section("Actions") {
            VStack(spacing: 12) {
                Button("Clear All Caches") {
                    cacheManager.clearAllCaches()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Request Memory Cleanup") {
                    memoryManager.requestMemoryCleanup()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Reset Inference Stats") {
                    inferenceThrottler.resetStatistics()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Log Memory Usage") {
                    memoryManager.logMemoryUsage()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var memoryPressureColor: Color {
        switch memoryManager.memoryPressureLevel {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    private var connectionQualityColor: Color {
        switch connectionManager.connectionQuality {
        case .excellent: return .green
        case .good: return .green
        case .fair: return .orange
        case .poor: return .red
        case .unknown: return .gray
        }
    }
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            memoryUsage = memoryManager.getCurrentMemoryUsage()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

#Preview {
    PerformanceMonitorView()
}