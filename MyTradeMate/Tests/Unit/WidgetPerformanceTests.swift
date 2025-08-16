import XCTest
import WidgetKit
@testable import MyTradeMate

final class WidgetPerformanceTests: XCTestCase {
    
    var widgetDataManager: WidgetDataManager!
    var performanceMetrics: WidgetPerformanceMetrics!
    
    override func setUp() {
        super.setUp()
        widgetDataManager = WidgetDataManager.shared
        performanceMetrics = WidgetPerformanceMetrics()
        
        // Clear any existing data
        if let userDefaults = UserDefaults(suiteName: "group.com.mytrademate.app") {
            userDefaults.removeObject(forKey: "widget_trading_data")
            userDefaults.removeObject(forKey: "widget_configuration")
        }
    }
    
    override func tearDown() {
        performanceMetrics.reset()
        widgetDataManager.stopAllRefresh()
        super.tearDown()
    }
    
    // MARK: - Data Serialization Performance Tests
    
    func testWidgetDataEncodingPerformance() {
        let testData = createLargeWidgetData()
        
        measure {
            for _ in 0..<1000 {
                _ = try? JSONEncoder().encode(testData)
            }
        }
    }
    
    func testWidgetDataDecodingPerformance() {
        let testData = createLargeWidgetData()
        let encodedData = try! JSONEncoder().encode(testData)
        
        measure {
            for _ in 0..<1000 {
                _ = try? JSONDecoder().decode(WidgetData.self, from: encodedData)
            }
        }
    }
    
    func testWidgetDataSavePerformance() {
        let testData = createLargeWidgetData()
        
        measure {
            for _ in 0..<100 {
                widgetDataManager.saveWidgetData(testData)
            }
        }
    }
    
    func testWidgetDataLoadPerformance() {
        let testData = createLargeWidgetData()
        widgetDataManager.saveWidgetData(testData)
        
        measure {
            for _ in 0..<100 {
                _ = widgetDataManager.loadWidgetData()
            }
        }
    }
    
    // MARK: - Memory Usage Tests
    
    func testWidgetDataMemoryFootprint() {
        let initialMemory = getMemoryUsage()
        
        // Create and store multiple widget data instances
        var widgetDataArray: [WidgetData] = []
        for i in 0..<1000 {
            let data = createWidgetDataWithIndex(i)
            widgetDataArray.append(data)
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (less than 10MB for 1000 instances)
        XCTAssertLessThan(memoryIncrease, 10 * 1024 * 1024, "Memory usage too high: \(memoryIncrease) bytes")
        
        performanceMetrics.recordMemoryUsage(memoryIncrease)
    }
    
    func testPnLHistoryMemoryImpact() {
        let baseData = createBasicWidgetData()
        let baseMemory = getMemoryUsage()
        
        // Test with increasing P&L history sizes
        let historySizes = [10, 50, 100, 500, 1000]
        
        for size in historySizes {
            let dataWithHistory = createWidgetDataWithPnLHistory(size: size)
            widgetDataManager.saveWidgetData(dataWithHistory)
            
            let currentMemory = getMemoryUsage()
            let memoryDiff = currentMemory - baseMemory
            
            performanceMetrics.recordPnLHistoryMemory(size: size, memory: memoryDiff)
            
            // Memory should scale reasonably with history size
            let expectedMaxMemory = size * 100 // ~100 bytes per data point
            XCTAssertLessThan(memoryDiff, expectedMaxMemory, 
                             "Memory usage for \(size) history points too high: \(memoryDiff) bytes")
        }
    }
    
    // MARK: - Refresh Performance Tests
    
    func testRefreshRateLimitingPerformance() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Attempt multiple rapid refreshes
        for _ in 0..<100 {
            widgetDataManager.refreshWidgets()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Rate limiting should prevent excessive processing
        XCTAssertLessThan(duration, 1.0, "Rate limiting not effective, took \(duration) seconds")
        
        performanceMetrics.recordRefreshDuration(duration)
    }
    
    func testManualRefreshPerformance() {
        measure {
            widgetDataManager.manualRefresh()
        }
    }
    
    func testAutomaticRefreshSchedulingPerformance() {
        measure {
            widgetDataManager.startAutomaticRefresh()
            widgetDataManager.stopAllRefresh()
        }
    }
    
    // MARK: - Configuration Performance Tests
    
    func testConfigurationSaveLoadPerformance() {
        let config = WidgetConfiguration(
            displayMode: "detailed",
            primarySymbol: "BTC/USDT",
            showDemoMode: true,
            colorTheme: "vibrant",
            updateFrequency: "fast"
        )
        
        measure {
            for _ in 0..<100 {
                widgetDataManager.saveWidgetConfiguration(config)
                _ = widgetDataManager.loadWidgetConfiguration()
            }
        }
    }
    
    // MARK: - Widget Timeline Performance Tests
    
    func testTimelineProviderPerformance() {
        let provider = TradingProvider()
        let context = MockWidgetContext()
        
        measure {
            let expectation = self.expectation(description: "Timeline completion")
            
            provider.getTimeline(in: context) { timeline in
                XCTAssertFalse(timeline.entries.isEmpty)
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 1.0)
        }
    }
    
    func testPlaceholderPerformance() {
        let provider = TradingProvider()
        let context = MockWidgetContext()
        
        measure {
            for _ in 0..<1000 {
                _ = provider.placeholder(in: context)
            }
        }
    }
    
    func testSnapshotPerformance() {
        let provider = TradingProvider()
        let context = MockWidgetContext()
        
        measure {
            let expectation = self.expectation(description: "Snapshot completion")
            
            provider.getSnapshot(in: context) { entry in
                XCTAssertNotNil(entry)
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 1.0)
        }
    }
    
    // MARK: - Battery Impact Simulation Tests
    
    func testBatteryImpactOfFrequentUpdates() {
        let batteryMonitor = BatteryImpactMonitor()
        batteryMonitor.startMonitoring()
        
        // Simulate frequent updates for 30 seconds
        let endTime = Date().addingTimeInterval(30)
        var updateCount = 0
        
        while Date() < endTime {
            widgetDataManager.refreshWidgets(force: true)
            updateCount += 1
            Thread.sleep(forTimeInterval: 0.1) // 10 updates per second
        }
        
        let batteryImpact = batteryMonitor.stopMonitoring()
        
        performanceMetrics.recordBatteryImpact(
            updates: updateCount,
            duration: 30,
            impact: batteryImpact
        )
        
        // Battery impact should be minimal for widget updates
        XCTAssertLessThan(batteryImpact.cpuUsage, 5.0, "CPU usage too high: \(batteryImpact.cpuUsage)%")
        XCTAssertLessThan(batteryImpact.memoryPressure, 0.3, "Memory pressure too high: \(batteryImpact.memoryPressure)")
    }
    
    func testBatteryImpactOfDifferentUpdateFrequencies() {
        let frequencies = ["fast", "normal", "slow", "manual"]
        
        for frequency in frequencies {
            let config = WidgetConfiguration(
                displayMode: "balanced",
                primarySymbol: "BTC/USDT",
                showDemoMode: true,
                colorTheme: "standard",
                updateFrequency: frequency
            )
            
            widgetDataManager.saveWidgetConfiguration(config)
            
            let batteryMonitor = BatteryImpactMonitor()
            batteryMonitor.startMonitoring()
            
            // Run for 60 seconds with this configuration
            widgetDataManager.startAutomaticRefresh()
            Thread.sleep(forTimeInterval: 60)
            widgetDataManager.stopAllRefresh()
            
            let batteryImpact = batteryMonitor.stopMonitoring()
            
            performanceMetrics.recordFrequencyBatteryImpact(
                frequency: frequency,
                impact: batteryImpact
            )
            
            // Verify battery impact scales with frequency
            let expectedMaxCPU = frequency == "fast" ? 2.0 : 1.0
            XCTAssertLessThan(batteryImpact.cpuUsage, expectedMaxCPU, 
                             "CPU usage too high for \(frequency): \(batteryImpact.cpuUsage)%")
        }
    }
    
    // MARK: - Background Task Performance Tests
    
    func testBackgroundRefreshPerformance() {
        let backgroundTaskMonitor = BackgroundTaskMonitor()
        backgroundTaskMonitor.startMonitoring()
        
        // Simulate background refresh
        widgetDataManager.startAutomaticRefresh()
        
        // Wait for background task to complete
        let expectation = self.expectation(description: "Background refresh")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10)
        
        let taskMetrics = backgroundTaskMonitor.stopMonitoring()
        
        performanceMetrics.recordBackgroundTaskMetrics(taskMetrics)
        
        // Background tasks should complete quickly
        XCTAssertLessThan(taskMetrics.executionTime, 5.0, 
                         "Background task too slow: \(taskMetrics.executionTime)s")
        XCTAssertLessThan(taskMetrics.memoryUsage, 5 * 1024 * 1024, 
                         "Background task memory usage too high: \(taskMetrics.memoryUsage) bytes")
        
        widgetDataManager.stopAllRefresh()
    }
    
    // MARK: - Stress Tests
    
    func testConcurrentWidgetDataAccess() {
        let concurrentQueue = DispatchQueue(label: "widget.test", attributes: .concurrent)
        let group = DispatchGroup()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate concurrent access from multiple sources
        for i in 0..<100 {
            group.enter()
            concurrentQueue.async {
                let data = self.createWidgetDataWithIndex(i)
                self.widgetDataManager.saveWidgetData(data)
                _ = self.widgetDataManager.loadWidgetData()
                group.leave()
            }
        }
        
        group.wait()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        performanceMetrics.recordConcurrentAccessDuration(duration)
        
        // Concurrent access should be handled efficiently
        XCTAssertLessThan(duration, 5.0, "Concurrent access too slow: \(duration)s")
    }
    
    func testLargeDataSetHandling() {
        // Test with very large P&L history
        let largeHistoryData = createWidgetDataWithPnLHistory(size: 10000)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        widgetDataManager.saveWidgetData(largeHistoryData)
        let loadedData = widgetDataManager.loadWidgetData()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        performanceMetrics.recordLargeDataHandling(
            dataSize: largeHistoryData.pnlHistory?.count ?? 0,
            duration: duration
        )
        
        // Large data should still be handled reasonably
        XCTAssertLessThan(duration, 2.0, "Large data handling too slow: \(duration)s")
        XCTAssertEqual(loadedData.pnlHistory?.count, largeHistoryData.pnlHistory?.count)
    }
    
    // MARK: - Performance Reporting
    
    func testGeneratePerformanceReport() {
        // Run a subset of performance tests to gather data
        testWidgetDataEncodingPerformance()
        testWidgetDataMemoryFootprint()
        testRefreshRateLimitingPerformance()
        
        let report = performanceMetrics.generateReport()
        
        XCTAssertFalse(report.isEmpty, "Performance report should not be empty")
        XCTAssertTrue(report.contains("Widget Performance Report"), "Report should have proper header")
        
        // Save report for analysis
        savePerformanceReport(report)
    }
    
    // MARK: - Helper Methods
    
    private func createBasicWidgetData() -> WidgetData {
        return WidgetData(
            pnl: 1000.0,
            pnlPercentage: 10.0,
            todayPnL: 100.0,
            unrealizedPnL: 50.0,
            equity: 11000.0,
            openPositions: 2,
            lastPrice: 45000.0,
            priceChange: 2.5,
            isDemoMode: true,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT"
        )
    }
    
    private func createLargeWidgetData() -> WidgetData {
        let pnlHistory = (0..<1000).map { i in
            PnLDataPoint(
                timestamp: Date().addingTimeInterval(-Double(i * 60)),
                value: Double.random(in: -1000...2000),
                percentage: Double.random(in: -10...20)
            )
        }
        
        return WidgetData(
            pnl: 1500.75,
            pnlPercentage: 15.0,
            todayPnL: 250.30,
            unrealizedPnL: 125.45,
            equity: 11500.75,
            openPositions: 5,
            lastPrice: 47250.80,
            priceChange: 3.2,
            isDemoMode: false,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT",
            signalDirection: "BUY",
            signalConfidence: 0.85,
            signalReason: "Strong bullish momentum detected",
            signalTimestamp: Date().addingTimeInterval(-300),
            signalModelName: "AI-1h-Enhanced",
            pnlHistory: pnlHistory
        )
    }
    
    private func createWidgetDataWithIndex(_ index: Int) -> WidgetData {
        return WidgetData(
            pnl: Double(index * 10),
            pnlPercentage: Double(index),
            todayPnL: Double(index * 2),
            unrealizedPnL: Double(index),
            equity: 10000.0 + Double(index * 10),
            openPositions: index % 5,
            lastPrice: 45000.0 + Double(index),
            priceChange: Double(index % 10),
            isDemoMode: index % 2 == 0,
            connectionStatus: index % 2 == 0 ? "connected" : "disconnected",
            lastUpdated: Date(),
            symbol: "BTC/USDT"
        )
    }
    
    private func createWidgetDataWithPnLHistory(size: Int) -> WidgetData {
        let pnlHistory = (0..<size).map { i in
            PnLDataPoint(
                timestamp: Date().addingTimeInterval(-Double(i * 60)),
                value: Double.random(in: -500...1500),
                percentage: Double.random(in: -5...15)
            )
        }
        
        var data = createBasicWidgetData()
        return WidgetData(
            pnl: data.pnl,
            pnlPercentage: data.pnlPercentage,
            todayPnL: data.todayPnL,
            unrealizedPnL: data.unrealizedPnL,
            equity: data.equity,
            openPositions: data.openPositions,
            lastPrice: data.lastPrice,
            priceChange: data.priceChange,
            isDemoMode: data.isDemoMode,
            connectionStatus: data.connectionStatus,
            lastUpdated: data.lastUpdated,
            symbol: data.symbol,
            pnlHistory: pnlHistory
        )
    }
    
    private func getMemoryUsage() -> Int {
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
            return Int(info.resident_size)
        } else {
            return 0
        }
    }
    
    private func savePerformanceReport(_ report: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        let reportURL = documentsPath.appendingPathComponent("widget_performance_report.txt")
        
        do {
            try report.write(to: reportURL, atomically: true, encoding: .utf8)
            print("Performance report saved to: \(reportURL.path)")
        } catch {
            print("Failed to save performance report: \(error)")
        }
    }
}

// MARK: - Mock Classes

class MockWidgetContext: TimelineProviderContext {
    var family: WidgetFamily = .systemSmall
    var isPreview: Bool = false
    var displaySize: CGSize = CGSize(width: 155, height: 155)
    var environmentVariants: [String] = []
}

// MARK: - Performance Monitoring Classes

class WidgetPerformanceMetrics {
    private var memoryUsages: [Int] = []
    private var refreshDurations: [Double] = []
    private var batteryImpacts: [BatteryImpact] = []
    private var pnlHistoryMemory: [(size: Int, memory: Int)] = []
    private var frequencyBatteryImpacts: [(frequency: String, impact: BatteryImpact)] = []
    private var backgroundTaskMetrics: [BackgroundTaskMetrics] = []
    private var concurrentAccessDurations: [Double] = []
    private var largeDataHandling: [(size: Int, duration: Double)] = []
    
    func recordMemoryUsage(_ usage: Int) {
        memoryUsages.append(usage)
    }
    
    func recordRefreshDuration(_ duration: Double) {
        refreshDurations.append(duration)
    }
    
    func recordBatteryImpact(updates: Int, duration: Double, impact: BatteryImpact) {
        batteryImpacts.append(impact)
    }
    
    func recordPnLHistoryMemory(size: Int, memory: Int) {
        pnlHistoryMemory.append((size: size, memory: memory))
    }
    
    func recordFrequencyBatteryImpact(frequency: String, impact: BatteryImpact) {
        frequencyBatteryImpacts.append((frequency: frequency, impact: impact))
    }
    
    func recordBackgroundTaskMetrics(_ metrics: BackgroundTaskMetrics) {
        backgroundTaskMetrics.append(metrics)
    }
    
    func recordConcurrentAccessDuration(_ duration: Double) {
        concurrentAccessDurations.append(duration)
    }
    
    func recordLargeDataHandling(dataSize: Int, duration: Double) {
        largeDataHandling.append((size: dataSize, duration: duration))
    }
    
    func reset() {
        memoryUsages.removeAll()
        refreshDurations.removeAll()
        batteryImpacts.removeAll()
        pnlHistoryMemory.removeAll()
        frequencyBatteryImpacts.removeAll()
        backgroundTaskMetrics.removeAll()
        concurrentAccessDurations.removeAll()
        largeDataHandling.removeAll()
    }
    
    func generateReport() -> String {
        var report = "Widget Performance Report\n"
        report += "========================\n\n"
        
        // Memory Usage Analysis
        if !memoryUsages.isEmpty {
            let avgMemory = memoryUsages.reduce(0, +) / memoryUsages.count
            let maxMemory = memoryUsages.max() ?? 0
            report += "Memory Usage:\n"
            report += "  Average: \(formatBytes(avgMemory))\n"
            report += "  Maximum: \(formatBytes(maxMemory))\n\n"
        }
        
        // Refresh Performance
        if !refreshDurations.isEmpty {
            let avgRefresh = refreshDurations.reduce(0, +) / Double(refreshDurations.count)
            let maxRefresh = refreshDurations.max() ?? 0
            report += "Refresh Performance:\n"
            report += "  Average Duration: \(String(format: "%.3f", avgRefresh))s\n"
            report += "  Maximum Duration: \(String(format: "%.3f", maxRefresh))s\n\n"
        }
        
        // Battery Impact Analysis
        if !batteryImpacts.isEmpty {
            let avgCPU = batteryImpacts.map { $0.cpuUsage }.reduce(0, +) / Double(batteryImpacts.count)
            let avgMemoryPressure = batteryImpacts.map { $0.memoryPressure }.reduce(0, +) / Double(batteryImpacts.count)
            report += "Battery Impact:\n"
            report += "  Average CPU Usage: \(String(format: "%.2f", avgCPU))%\n"
            report += "  Average Memory Pressure: \(String(format: "%.2f", avgMemoryPressure))\n\n"
        }
        
        // P&L History Memory Impact
        if !pnlHistoryMemory.isEmpty {
            report += "P&L History Memory Impact:\n"
            for (size, memory) in pnlHistoryMemory {
                let bytesPerPoint = memory / size
                report += "  \(size) points: \(formatBytes(memory)) (\(bytesPerPoint) bytes/point)\n"
            }
            report += "\n"
        }
        
        // Frequency-based Battery Impact
        if !frequencyBatteryImpacts.isEmpty {
            report += "Update Frequency Battery Impact:\n"
            for (frequency, impact) in frequencyBatteryImpacts {
                report += "  \(frequency): CPU \(String(format: "%.2f", impact.cpuUsage))%, Memory Pressure \(String(format: "%.2f", impact.memoryPressure))\n"
            }
            report += "\n"
        }
        
        // Background Task Performance
        if !backgroundTaskMetrics.isEmpty {
            let avgExecution = backgroundTaskMetrics.map { $0.executionTime }.reduce(0, +) / Double(backgroundTaskMetrics.count)
            let avgMemory = backgroundTaskMetrics.map { $0.memoryUsage }.reduce(0, +) / backgroundTaskMetrics.count
            report += "Background Task Performance:\n"
            report += "  Average Execution Time: \(String(format: "%.3f", avgExecution))s\n"
            report += "  Average Memory Usage: \(formatBytes(avgMemory))\n\n"
        }
        
        // Concurrent Access Performance
        if !concurrentAccessDurations.isEmpty {
            let avgConcurrent = concurrentAccessDurations.reduce(0, +) / Double(concurrentAccessDurations.count)
            let maxConcurrent = concurrentAccessDurations.max() ?? 0
            report += "Concurrent Access Performance:\n"
            report += "  Average Duration: \(String(format: "%.3f", avgConcurrent))s\n"
            report += "  Maximum Duration: \(String(format: "%.3f", maxConcurrent))s\n\n"
        }
        
        // Large Data Handling
        if !largeDataHandling.isEmpty {
            report += "Large Data Handling:\n"
            for (size, duration) in largeDataHandling {
                let pointsPerSecond = Double(size) / duration
                report += "  \(size) points: \(String(format: "%.3f", duration))s (\(String(format: "%.0f", pointsPerSecond)) points/s)\n"
            }
            report += "\n"
        }
        
        report += "Report generated: \(Date())\n"
        
        return report
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct BatteryImpact {
    let cpuUsage: Double
    let memoryPressure: Double
    let networkActivity: Double
    let diskActivity: Double
}

struct BackgroundTaskMetrics {
    let executionTime: Double
    let memoryUsage: Int
    let cpuUsage: Double
    let success: Bool
}

class BatteryImpactMonitor {
    private var startTime: Date?
    private var startCPU: Double = 0
    private var startMemory: Int = 0
    
    func startMonitoring() {
        startTime = Date()
        startCPU = getCurrentCPUUsage()
        startMemory = getCurrentMemoryUsage()
    }
    
    func stopMonitoring() -> BatteryImpact {
        let endCPU = getCurrentCPUUsage()
        let endMemory = getCurrentMemoryUsage()
        
        let cpuDiff = endCPU - startCPU
        let memoryPressure = Double(endMemory - startMemory) / Double(startMemory)
        
        return BatteryImpact(
            cpuUsage: max(0, cpuDiff),
            memoryPressure: max(0, memoryPressure),
            networkActivity: 0.1, // Minimal for widget updates
            diskActivity: 0.1     // Minimal for UserDefaults
        )
    }
    
    private func getCurrentCPUUsage() -> Double {
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
            return Double(info.user_time.seconds + info.system_time.seconds)
        } else {
            return 0
        }
    }
    
    private func getCurrentMemoryUsage() -> Int {
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
            return Int(info.resident_size)
        } else {
            return 0
        }
    }
}

class BackgroundTaskMonitor {
    private var startTime: Date?
    private var startMemory: Int = 0
    private var startCPU: Double = 0
    
    func startMonitoring() {
        startTime = Date()
        startMemory = getCurrentMemoryUsage()
        startCPU = getCurrentCPUUsage()
    }
    
    func stopMonitoring() -> BackgroundTaskMetrics {
        let endTime = Date()
        let endMemory = getCurrentMemoryUsage()
        let endCPU = getCurrentCPUUsage()
        
        let executionTime = endTime.timeIntervalSince(startTime ?? endTime)
        let memoryUsage = endMemory - startMemory
        let cpuUsage = endCPU - startCPU
        
        return BackgroundTaskMetrics(
            executionTime: executionTime,
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            success: true
        )
    }
    
    private func getCurrentMemoryUsage() -> Int {
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
            return Int(info.resident_size)
        } else {
            return 0
        }
    }
    
    private func getCurrentCPUUsage() -> Double {
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
            return Double(info.user_time.seconds + info.system_time.seconds)
        } else {
            return 0
        }
    }
}