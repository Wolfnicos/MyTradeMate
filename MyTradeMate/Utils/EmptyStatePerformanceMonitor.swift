import SwiftUI
import Combine

/// Performance monitoring utility specifically for empty state illustrations
class EmptyStatePerformanceMonitor: ObservableObject {
    static let shared = EmptyStatePerformanceMonitor()
    
    @Published var metrics: PerformanceMetrics = PerformanceMetrics()
    
    private var renderingTimes: [String: [TimeInterval]] = [:]
    private var memorySnapshots: [String: Double] = [:]
    private var animationFrameDrops: [String: Int] = [:]
    
    private init() {}
    
    // MARK: - Performance Metrics Structure
    
    struct PerformanceMetrics {
        var averageRenderingTime: TimeInterval = 0
        var peakMemoryUsage: Double = 0
        var totalFrameDrops: Int = 0
        var cacheHitRate: Double = 0
        var animationPerformanceScore: Double = 100.0
        var overallHealthScore: Double = 100.0
        
        var isHealthy: Bool {
            overallHealthScore > 80.0
        }
        
        var needsOptimization: Bool {
            averageRenderingTime > 0.016 || // More than one frame at 60fps
            peakMemoryUsage > 50.0 || // More than 50MB
            totalFrameDrops > 10 ||
            animationPerformanceScore < 70.0
        }
    }
    
    // MARK: - Monitoring Methods
    
    /// Start monitoring rendering performance for a specific empty state type
    func startRenderingMonitoring(for type: String) -> PerformanceToken {
        let startTime = CFAbsoluteTimeGetCurrent()
        let initialMemory = getCurrentMemoryUsage()
        
        return PerformanceToken(
            type: type,
            startTime: startTime,
            initialMemory: initialMemory,
            monitor: self
        )
    }
    
    /// Record rendering completion
    func recordRenderingCompletion(token: PerformanceToken) {
        let endTime = CFAbsoluteTimeGetCurrent()
        let renderingTime = endTime - token.startTime
        let finalMemory = getCurrentMemoryUsage()
        let memoryDelta = finalMemory - token.initialMemory
        
        // Store rendering time
        if renderingTimes[token.type] == nil {
            renderingTimes[token.type] = []
        }
        renderingTimes[token.type]?.append(renderingTime)
        
        // Keep only last 100 measurements
        if renderingTimes[token.type]?.count ?? 0 > 100 {
            renderingTimes[token.type]?.removeFirst()
        }
        
        // Update memory tracking
        memorySnapshots[token.type] = max(memorySnapshots[token.type] ?? 0, finalMemory)
        
        // Update metrics
        updateMetrics()
        
        // Log performance warnings
        if renderingTime > 0.016 {
            print("⚠️ EmptyStatePerformanceMonitor: \(token.type) rendering took \(String(format: "%.3f", renderingTime))s (may cause frame drops)")
        }
        
        if memoryDelta > 5.0 {
            print("⚠️ EmptyStatePerformanceMonitor: \(token.type) used \(String(format: "%.2f", memoryDelta))MB memory")
        }
    }
    
    /// Record animation frame drop
    func recordFrameDrop(for type: String) {
        animationFrameDrops[type, default: 0] += 1
        updateMetrics()
    }
    
    /// Get detailed performance report
    func getDetailedReport() -> PerformanceReport {
        return PerformanceReport(
            renderingTimes: renderingTimes,
            memorySnapshots: memorySnapshots,
            frameDrops: animationFrameDrops,
            cacheStats: SFSymbolCache.shared.getStats(),
            recommendations: generateRecommendations()
        )
    }
    
    /// Reset all performance data
    func resetMetrics() {
        renderingTimes.removeAll()
        memorySnapshots.removeAll()
        animationFrameDrops.removeAll()
        metrics = PerformanceMetrics()
    }
    
    // MARK: - Private Methods
    
    private func updateMetrics() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Calculate average rendering time
            let allTimes = self.renderingTimes.values.flatMap { $0 }
            self.metrics.averageRenderingTime = allTimes.isEmpty ? 0 : allTimes.reduce(0, +) / Double(allTimes.count)
            
            // Calculate peak memory usage
            self.metrics.peakMemoryUsage = self.memorySnapshots.values.max() ?? 0
            
            // Calculate total frame drops
            self.metrics.totalFrameDrops = self.animationFrameDrops.values.reduce(0, +)
            
            // Calculate cache hit rate
            let cacheStats = SFSymbolCache.shared.getStats()
            self.metrics.cacheHitRate = cacheStats.totalRequests > 0 ? 
                Double(cacheStats.cacheHits) / Double(cacheStats.totalRequests) * 100.0 : 0
            
            // Calculate animation performance score
            self.metrics.animationPerformanceScore = self.calculateAnimationScore()
            
            // Calculate overall health score
            self.metrics.overallHealthScore = self.calculateOverallScore()
        }
    }
    
    private func calculateAnimationScore() -> Double {
        let baseScore = 100.0
        let frameDropPenalty = Double(metrics.totalFrameDrops) * 2.0
        let renderingPenalty = max(0, (metrics.averageRenderingTime - 0.016) * 1000.0)
        
        return max(0, baseScore - frameDropPenalty - renderingPenalty)
    }
    
    private func calculateOverallScore() -> Double {
        let renderingScore = metrics.averageRenderingTime <= 0.016 ? 100.0 : max(0, 100.0 - (metrics.averageRenderingTime - 0.016) * 2000.0)
        let memoryScore = metrics.peakMemoryUsage <= 20.0 ? 100.0 : max(0, 100.0 - (metrics.peakMemoryUsage - 20.0) * 2.0)
        let animationScore = metrics.animationPerformanceScore
        let cacheScore = metrics.cacheHitRate
        
        return (renderingScore + memoryScore + animationScore + cacheScore) / 4.0
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if metrics.averageRenderingTime > 0.016 {
            recommendations.append("Consider reducing animation complexity or enabling reduced motion")
        }
        
        if metrics.peakMemoryUsage > 30.0 {
            recommendations.append("Memory usage is high - consider implementing more aggressive caching cleanup")
        }
        
        if metrics.totalFrameDrops > 5 {
            recommendations.append("Frame drops detected - consider simplifying animations or reducing concurrent animations")
        }
        
        if metrics.cacheHitRate < 70.0 {
            recommendations.append("Low cache hit rate - consider preloading common symbols or increasing cache size")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Performance is optimal")
        }
        
        return recommendations
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
}

// MARK: - Performance Token

class PerformanceToken {
    let type: String
    let startTime: TimeInterval
    let initialMemory: Double
    weak var monitor: EmptyStatePerformanceMonitor?
    
    init(type: String, startTime: TimeInterval, initialMemory: Double, monitor: EmptyStatePerformanceMonitor) {
        self.type = type
        self.startTime = startTime
        self.initialMemory = initialMemory
        self.monitor = monitor
    }
    
    deinit {
        monitor?.recordRenderingCompletion(token: self)
    }
}

// MARK: - Performance Report

struct PerformanceReport {
    let renderingTimes: [String: [TimeInterval]]
    let memorySnapshots: [String: Double]
    let frameDrops: [String: Int]
    let cacheStats: SFSymbolCacheStats
    let recommendations: [String]
    
    var summary: String {
        let avgRendering = renderingTimes.values.flatMap { $0 }.reduce(0, +) / Double(renderingTimes.values.flatMap { $0 }.count)
        let peakMemory = memorySnapshots.values.max() ?? 0
        let totalDrops = frameDrops.values.reduce(0, +)
        
        return """
        Empty State Performance Report:
        - Average Rendering Time: \(String(format: "%.3f", avgRendering))s
        - Peak Memory Usage: \(String(format: "%.2f", peakMemory))MB
        - Total Frame Drops: \(totalDrops)
        - Cache Hit Rate: \(String(format: "%.1f", cacheStats.hitRate))%
        - Recommendations: \(recommendations.joined(separator: ", "))
        """
    }
}

// MARK: - SF Symbol Cache Stats

struct SFSymbolCacheStats {
    let totalRequests: Int
    let cacheHits: Int
    let cacheMisses: Int
    let cacheSize: Int
    let memoryUsage: Double
    
    var hitRate: Double {
        totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) * 100.0 : 0
    }
}

// MARK: - SF Symbol Cache Extension

extension SFSymbolCache {
    private static var requestCount = 0
    private static var hitCount = 0
    
    func getStats() -> SFSymbolCacheStats {
        return SFSymbolCacheStats(
            totalRequests: Self.requestCount,
            cacheHits: Self.hitCount,
            cacheMisses: Self.requestCount - Self.hitCount,
            cacheSize: 0,
            memoryUsage: estimateMemoryUsage()
        )
    }
    
    private func estimateMemoryUsage() -> Double {
        // Rough estimate: each cached image uses about 50KB on average
        return 0.0 // MB
    }
    
    func recordRequest(hit: Bool) {
        Self.requestCount += 1
        if hit {
            Self.hitCount += 1
        }
    }
}

// MARK: - SwiftUI Performance Extensions

extension View {
    /// Wraps a view with performance monitoring
    func monitorEmptyStatePerformance(type: String) -> some View {
        self.onAppear {
            let token = EmptyStatePerformanceMonitor.shared.startRenderingMonitoring(for: type)
            // Token will automatically complete monitoring when deallocated
        }
    }
    
    /// Adds frame drop detection to animations
    func detectFrameDrops(for type: String) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .frameDropDetected)) { notification in
            if let frameType = notification.userInfo?["type"] as? String, frameType == type {
                EmptyStatePerformanceMonitor.shared.recordFrameDrop(for: type)
            }
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let frameDropDetected = Notification.Name("frameDropDetected")
    // Using memoryPressureChanged from MemoryPressureManager
}

// MARK: - Performance Optimized Empty State Views

extension EmptyStateView {
    /// Creates a performance-monitored version of the empty state
    func withPerformanceMonitoring() -> some View {
        self
            .monitorEmptyStatePerformance(type: "EmptyStateView")
            .detectFrameDrops(for: "EmptyStateView")
    }
}

extension IllustratedEmptyStateView {
    /// Creates a performance-monitored version of the illustrated empty state
    func withPerformanceMonitoring() -> some View {
        self
            .monitorEmptyStatePerformance(type: "IllustratedEmptyStateView")
            .detectFrameDrops(for: "IllustratedEmptyStateView")
    }
}

// MARK: - Debug Performance View

#if DEBUG
struct EmptyStatePerformanceDebugView: View {
    @StateObject private var monitor = EmptyStatePerformanceMonitor.shared
    @State private var showingReport = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Empty State Performance")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Health Score:")
                    Spacer()
                    Text("\(String(format: "%.1f", monitor.metrics.overallHealthScore))%")
                        .foregroundColor(healthScoreColor)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Avg Rendering:")
                    Spacer()
                    Text("\(String(format: "%.3f", monitor.metrics.averageRenderingTime))s")
                        .foregroundColor(monitor.metrics.averageRenderingTime > 0.016 ? .red : .green)
                }
                
                HStack {
                    Text("Peak Memory:")
                    Spacer()
                    Text("\(String(format: "%.2f", monitor.metrics.peakMemoryUsage))MB")
                        .foregroundColor(monitor.metrics.peakMemoryUsage > 30 ? .red : .green)
                }
                
                HStack {
                    Text("Frame Drops:")
                    Spacer()
                    Text("\(monitor.metrics.totalFrameDrops)")
                        .foregroundColor(monitor.metrics.totalFrameDrops > 5 ? .red : .green)
                }
                
                HStack {
                    Text("Cache Hit Rate:")
                    Spacer()
                    Text("\(String(format: "%.1f", monitor.metrics.cacheHitRate))%")
                        .foregroundColor(monitor.metrics.cacheHitRate < 70 ? .orange : .green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            HStack {
                Button("Reset Metrics") {
                    monitor.resetMetrics()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("View Report") {
                    showingReport = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            if monitor.metrics.needsOptimization {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⚠️ Performance Issues Detected")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Consider enabling performance optimizations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .sheet(isPresented: $showingReport) {
            NavigationView {
                ScrollView {
                    Text(monitor.getDetailedReport().summary)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                .navigationTitle("Performance Report")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingReport = false
                        }
                    }
                }
            }
        }
    }
    
    private var healthScoreColor: Color {
        switch monitor.metrics.overallHealthScore {
        case 90...100:
            return .green
        case 70..<90:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    EmptyStatePerformanceDebugView()
}
#endif