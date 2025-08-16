import XCTest
import WidgetKit
@testable import MyTradeMate

final class WidgetBatteryImpactIntegrationTests: XCTestCase {
    
    var widgetDataManager: WidgetDataManager!
    var batteryAnalyzer: WidgetBatteryAnalyzer!
    
    override func setUp() {
        super.setUp()
        widgetDataManager = WidgetDataManager.shared
        batteryAnalyzer = WidgetBatteryAnalyzer()
        
        // Reset to clean state
        widgetDataManager.stopAllRefresh()
        
        // Clear any existing data
        if let userDefaults = UserDefaults(suiteName: "group.com.mytrademate.app") {
            userDefaults.removeObject(forKey: "widget_trading_data")
            userDefaults.removeObject(forKey: "widget_configuration")
        }
    }
    
    override func tearDown() {
        widgetDataManager.stopAllRefresh()
        batteryAnalyzer.stopAllMonitoring()
        super.tearDown()
    }
    
    // MARK: - Real-world Battery Impact Tests
    
    func testRealWorldBatteryImpactLightUsage() {
        // Simulate light usage: updates every 5 minutes for 1 hour
        let config = WidgetConfiguration(
            displayMode: "minimal",
            primarySymbol: "BTC/USDT",
            showDemoMode: true,
            colorTheme: "standard",
            updateFrequency: "slow"
        )
        
        widgetDataManager.saveWidgetConfiguration(config)
        
        let testDuration: TimeInterval = 60 // 1 minute for testing (scaled down)
        let expectedUpdates = Int(testDuration / config.updateInterval) + 1
        
        batteryAnalyzer.startLongTermMonitoring(duration: testDuration)
        widgetDataManager.startAutomaticRefresh()
        
        // Wait for test duration
        let expectation = self.expectation(description: "Light usage test")
        DispatchQueue.main.asyncAfter(deadline: .now() + testDuration) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: testDuration + 10)
        
        widgetDataManager.stopAllRefresh()
        let batteryReport = batteryAnalyzer.stopLongTermMonitoring()
        
        // Verify battery impact is minimal for light usage
        XCTAssertLessThan(batteryReport.averageCPUUsage, 1.0, 
                         "CPU usage too high for light usage: \(batteryReport.averageCPUUsage)%")
        XCTAssertLessThan(batteryReport.peakMemoryIncrease, 5 * 1024 * 1024, 
                         "Memory increase too high: \(batteryReport.peakMemoryIncrease) bytes")
        XCTAssertLessThanOrEqual(batteryReport.totalRefreshes, expectedUpdates + 2, 
                                "Too many refreshes: \(batteryReport.totalRefreshes)")
        
        saveBatteryReport(batteryReport, testName: "LightUsage")
    }
    
    func testRealWorldBatteryImpactHeavyUsage() {
        // Simulate heavy usage: updates every minute with large data
        let config = WidgetConfiguration(
            displayMode: "detailed",
            primarySymbol: "BTC/USDT",
            showDemoMode: true,
            colorTheme: "vibrant",
            updateFrequency: "fast"
        )
        
        widgetDataManager.saveWidgetConfiguration(config)
        
        let testDuration: TimeInterval = 60 // 1 minute for testing
        let expectedUpdates = Int(testDuration / config.updateInterval) + 1
        
        batteryAnalyzer.startLongTermMonitoring(duration: testDuration)
        widgetDataManager.startAutomaticRefresh()
        
        // Simulate heavy data updates
        let updateTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            let heavyData = self.createHeavyWidgetData()
            self.widgetDataManager.updateWidgetData(heavyData)
        }
        
        // Wait for test duration
        let expectation = self.expectation(description: "Heavy usage test")
        DispatchQueue.main.asyncAfter(deadline: .now() + testDuration) {
            updateTimer.invalidate()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: testDuration + 10)
        
        widgetDataManager.stopAllRefresh()
        let batteryReport = batteryAnalyzer.stopLongTermMonitoring()
        
        // Verify battery impact is reasonable even for heavy usage
        XCTAssertLessThan(batteryReport.averageCPUUsage, 5.0, 
                         "CPU usage too high for heavy usage: \(batteryReport.averageCPUUsage)%")
        XCTAssertLessThan(batteryReport.peakMemoryIncrease, 20 * 1024 * 1024, 
                         "Memory increase too high: \(batteryReport.peakMemoryIncrease) bytes")
        XCTAssertLessThan(batteryReport.averageMemoryPressure, 0.5, 
                         "Memory pressure too high: \(batteryReport.averageMemoryPressure)")
        
        saveBatteryReport(batteryReport, testName: "HeavyUsage")
    }
    
    func testBatteryImpactAcrossAllWidgetSizes() {
        let widgetSizes = ["small", "medium", "large"]
        var batteryReports: [String: WidgetBatteryReport] = [:]
        
        for size in widgetSizes {
            let config = WidgetConfiguration(
                displayMode: size == "small" ? "minimal" : (size == "medium" ? "balanced" : "detailed"),
                primarySymbol: "BTC/USDT",
                showDemoMode: true,
                colorTheme: "standard",
                updateFrequency: "normal"
            )
            
            widgetDataManager.saveWidgetConfiguration(config)
            
            let testDuration: TimeInterval = 30
            
            batteryAnalyzer.startLongTermMonitoring(duration: testDuration)
            widgetDataManager.startAutomaticRefresh()
            
            // Simulate widget updates for this size
            for i in 0..<5 {
                let data = createWidgetDataForSize(size, iteration: i)
                widgetDataManager.updateWidgetData(data)
                Thread.sleep(forTimeInterval: testDuration / 5)
            }
            
            widgetDataManager.stopAllRefresh()
            let batteryReport = batteryAnalyzer.stopLongTermMonitoring()
            batteryReports[size] = batteryReport
            
            // Each size should have reasonable battery impact
            XCTAssertLessThan(batteryReport.averageCPUUsage, 3.0, 
                             "CPU usage too high for \(size) widget: \(batteryReport.averageCPUUsage)%")
            
            saveBatteryReport(batteryReport, testName: "\(size.capitalized)Widget")
        }
        
        // Compare battery impact across sizes
        let smallReport = batteryReports["small"]!
        let mediumReport = batteryReports["medium"]!
        let largeReport = batteryReports["large"]!
        
        // Large widgets should use more resources than small ones, but not excessively
        XCTAssertGreaterThanOrEqual(largeReport.averageCPUUsage, smallReport.averageCPUUsage)
        XCTAssertLessThan(largeReport.averageCPUUsage, smallReport.averageCPUUsage * 3, 
                         "Large widget CPU usage disproportionately high")
        
        generateComparativeReport(batteryReports)
    }
    
    func testBatteryImpactWithBackgroundAppRefresh() {
        // Test battery impact when app is backgrounded
        let config = WidgetConfiguration(
            displayMode: "balanced",
            primarySymbol: "BTC/USDT",
            showDemoMode: true,
            colorTheme: "standard",
            updateFrequency: "normal"
        )
        
        widgetDataManager.saveWidgetConfiguration(config)
        
        let testDuration: TimeInterval = 120 // 2 minutes
        
        batteryAnalyzer.startBackgroundMonitoring()
        widgetDataManager.startAutomaticRefresh()
        
        // Simulate app going to background
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Wait for background operations
        let expectation = self.expectation(description: "Background refresh test")
        DispatchQueue.main.asyncAfter(deadline: .now() + testDuration) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: testDuration + 10)
        
        // Simulate app returning to foreground
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        widgetDataManager.stopAllRefresh()
        let batteryReport = batteryAnalyzer.stopBackgroundMonitoring()
        
        // Background operations should have minimal battery impact
        XCTAssertLessThan(batteryReport.backgroundCPUUsage, 2.0, 
                         "Background CPU usage too high: \(batteryReport.backgroundCPUUsage)%")
        XCTAssertLessThan(batteryReport.backgroundMemoryIncrease, 10 * 1024 * 1024, 
                         "Background memory increase too high: \(batteryReport.backgroundMemoryIncrease) bytes")
        
        saveBatteryReport(batteryReport, testName: "BackgroundRefresh")
    }
    
    func testBatteryImpactWithNetworkFailures() {
        // Test battery impact when network requests fail
        let config = WidgetConfiguration(
            displayMode: "balanced",
            primarySymbol: "BTC/USDT",
            showDemoMode: false, // Live mode to trigger network requests
            colorTheme: "standard",
            updateFrequency: "fast"
        )
        
        widgetDataManager.saveWidgetConfiguration(config)
        
        let testDuration: TimeInterval = 60
        
        batteryAnalyzer.startNetworkFailureMonitoring()
        widgetDataManager.startAutomaticRefresh()
        
        // Simulate network failures by providing stale data
        let failureTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            let staleData = self.createStaleWidgetData()
            self.widgetDataManager.updateWidgetData(staleData)
        }
        
        let expectation = self.expectation(description: "Network failure test")
        DispatchQueue.main.asyncAfter(deadline: .now() + testDuration) {
            failureTimer.invalidate()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: testDuration + 10)
        
        widgetDataManager.stopAllRefresh()
        let batteryReport = batteryAnalyzer.stopNetworkFailureMonitoring()
        
        // Network failures shouldn't cause excessive battery drain
        XCTAssertLessThan(batteryReport.failureRecoveryCPU, 3.0, 
                         "Failure recovery CPU usage too high: \(batteryReport.failureRecoveryCPU)%")
        XCTAssertLessThan(batteryReport.retryAttempts, 10, 
                         "Too many retry attempts: \(batteryReport.retryAttempts)")
        
        saveBatteryReport(batteryReport, testName: "NetworkFailures")
    }
    
    func testLongTermBatteryImpact24Hours() {
        // Simulate 24-hour usage pattern (scaled down to 5 minutes for testing)
        let config = WidgetConfiguration(
            displayMode: "balanced",
            primarySymbol: "BTC/USDT",
            showDemoMode: true,
            colorTheme: "standard",
            updateFrequency: "normal"
        )
        
        widgetDataManager.saveWidgetConfiguration(config)
        
        let testDuration: TimeInterval = 300 // 5 minutes representing 24 hours
        let scaleFactor = 24 * 60 * 60 / testDuration // Scale factor for 24 hours
        
        batteryAnalyzer.startLongTermMonitoring(duration: testDuration)
        widgetDataManager.startAutomaticRefresh()
        
        // Simulate varying usage patterns throughout the "day"
        let patternTimer = Timer.scheduledTimer(withTimeInterval: testDuration / 24, repeats: true) { timer in
            let hour = Int(timer.fireDate.timeIntervalSince(Date()) / (testDuration / 24))
            let data = self.createWidgetDataForHour(hour)
            self.widgetDataManager.updateWidgetData(data)
        }
        
        let expectation = self.expectation(description: "24-hour simulation")
        DispatchQueue.main.asyncAfter(deadline: .now() + testDuration) {
            patternTimer.invalidate()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: testDuration + 30)
        
        widgetDataManager.stopAllRefresh()
        let batteryReport = batteryAnalyzer.stopLongTermMonitoring()
        
        // Scale up the results to 24-hour equivalent
        let scaledReport = batteryReport.scaledTo24Hours(scaleFactor: scaleFactor)
        
        // 24-hour battery impact should be acceptable
        XCTAssertLessThan(scaledReport.projectedBatteryDrain, 5.0, 
                         "24-hour battery drain too high: \(scaledReport.projectedBatteryDrain)%")
        XCTAssertLessThan(scaledReport.averageCPUUsage, 1.0, 
                         "Average CPU usage too high: \(scaledReport.averageCPUUsage)%")
        
        saveBatteryReport(scaledReport, testName: "24HourSimulation")
    }
    
    func testBatteryImpactOptimizations() {
        // Test various optimization strategies
        let optimizations = [
            ("baseline", "normal", "standard"),
            ("reduced_frequency", "slow", "standard"),
            ("minimal_display", "normal", "minimal"),
            ("manual_updates", "manual", "standard")
        ]
        
        var optimizationReports: [String: WidgetBatteryReport] = [:]
        
        for (name, frequency, displayMode) in optimizations {
            let config = WidgetConfiguration(
                displayMode: displayMode == "minimal" ? "minimal" : "balanced",
                primarySymbol: "BTC/USDT",
                showDemoMode: true,
                colorTheme: "standard",
                updateFrequency: frequency
            )
            
            widgetDataManager.saveWidgetConfiguration(config)
            
            let testDuration: TimeInterval = 60
            
            batteryAnalyzer.startLongTermMonitoring(duration: testDuration)
            widgetDataManager.startAutomaticRefresh()
            
            // Run optimization test
            for i in 0..<6 {
                let data = createOptimizedWidgetData(optimization: name, iteration: i)
                widgetDataManager.updateWidgetData(data)
                Thread.sleep(forTimeInterval: testDuration / 6)
            }
            
            widgetDataManager.stopAllRefresh()
            let batteryReport = batteryAnalyzer.stopLongTermMonitoring()
            optimizationReports[name] = batteryReport
            
            saveBatteryReport(batteryReport, testName: "Optimization_\(name)")
        }
        
        // Verify optimizations actually reduce battery usage
        let baseline = optimizationReports["baseline"]!
        let reducedFreq = optimizationReports["reduced_frequency"]!
        let minimal = optimizationReports["minimal_display"]!
        let manual = optimizationReports["manual_updates"]!
        
        XCTAssertLessThan(reducedFreq.averageCPUUsage, baseline.averageCPUUsage, 
                         "Reduced frequency should use less CPU")
        XCTAssertLessThan(minimal.averageMemoryUsage, baseline.averageMemoryUsage, 
                         "Minimal display should use less memory")
        XCTAssertLessThan(manual.totalRefreshes, baseline.totalRefreshes, 
                         "Manual updates should refresh less frequently")
        
        generateOptimizationReport(optimizationReports)
    }
    
    // MARK: - Helper Methods
    
    private func createHeavyWidgetData() -> WidgetData {
        let largeHistory = (0..<1000).map { i in
            PnLDataPoint(
                timestamp: Date().addingTimeInterval(-Double(i * 60)),
                value: Double.random(in: -2000...3000),
                percentage: Double.random(in: -20...30)
            )
        }
        
        return WidgetData(
            pnl: Double.random(in: -1000...5000),
            pnlPercentage: Double.random(in: -10...50),
            todayPnL: Double.random(in: -500...1000),
            unrealizedPnL: Double.random(in: -200...500),
            equity: Double.random(in: 8000...15000),
            openPositions: Int.random(in: 0...10),
            lastPrice: Double.random(in: 40000...50000),
            priceChange: Double.random(in: -5...5),
            isDemoMode: Bool.random(),
            connectionStatus: ["connected", "disconnected", "error"].randomElement()!,
            lastUpdated: Date(),
            symbol: "BTC/USDT",
            signalDirection: ["BUY", "SELL", "HOLD"].randomElement(),
            signalConfidence: Double.random(in: 0...1),
            signalReason: "Heavy data test signal",
            signalTimestamp: Date().addingTimeInterval(-Double.random(in: 0...3600)),
            signalModelName: "AI-Heavy-Test",
            pnlHistory: largeHistory
        )
    }
    
    private func createWidgetDataForSize(_ size: String, iteration: Int) -> WidgetData {
        let historySize = size == "large" ? 100 : (size == "medium" ? 50 : 10)
        
        let history = (0..<historySize).map { i in
            PnLDataPoint(
                timestamp: Date().addingTimeInterval(-Double(i * 300)),
                value: Double(iteration * 100 + i),
                percentage: Double(iteration + i) / 10.0
            )
        }
        
        return WidgetData(
            pnl: Double(iteration * 100),
            pnlPercentage: Double(iteration),
            todayPnL: Double(iteration * 10),
            unrealizedPnL: Double(iteration * 5),
            equity: 10000 + Double(iteration * 100),
            openPositions: iteration % 5,
            lastPrice: 45000 + Double(iteration * 100),
            priceChange: Double(iteration % 10) - 5,
            isDemoMode: true,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT",
            pnlHistory: size == "small" ? nil : history
        )
    }
    
    private func createStaleWidgetData() -> WidgetData {
        return WidgetData(
            pnl: 1000.0,
            pnlPercentage: 10.0,
            todayPnL: 100.0,
            unrealizedPnL: 50.0,
            equity: 11000.0,
            openPositions: 2,
            lastPrice: 45000.0,
            priceChange: 0.0,
            isDemoMode: false,
            connectionStatus: "error",
            lastUpdated: Date().addingTimeInterval(-3600), // 1 hour old
            symbol: "BTC/USDT"
        )
    }
    
    private func createWidgetDataForHour(_ hour: Int) -> WidgetData {
        // Simulate different activity levels throughout the day
        let activityMultiplier = hour < 6 || hour > 22 ? 0.1 : (hour > 8 && hour < 18 ? 1.0 : 0.5)
        
        return WidgetData(
            pnl: Double.random(in: -500...2000) * activityMultiplier,
            pnlPercentage: Double.random(in: -5...20) * activityMultiplier,
            todayPnL: Double.random(in: -100...500) * activityMultiplier,
            unrealizedPnL: Double.random(in: -50...200) * activityMultiplier,
            equity: 10000 + Double.random(in: -1000...3000) * activityMultiplier,
            openPositions: Int(Double.random(in: 0...5) * activityMultiplier),
            lastPrice: 45000 + Double.random(in: -2000...2000) * activityMultiplier,
            priceChange: Double.random(in: -3...3) * activityMultiplier,
            isDemoMode: true,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT"
        )
    }
    
    private func createOptimizedWidgetData(optimization: String, iteration: Int) -> WidgetData {
        let baseData = WidgetData(
            pnl: Double(iteration * 50),
            pnlPercentage: Double(iteration),
            todayPnL: Double(iteration * 5),
            unrealizedPnL: Double(iteration * 2),
            equity: 10000 + Double(iteration * 50),
            openPositions: iteration % 3,
            lastPrice: 45000 + Double(iteration * 50),
            priceChange: Double(iteration % 6) - 3,
            isDemoMode: true,
            connectionStatus: "connected",
            lastUpdated: Date(),
            symbol: "BTC/USDT"
        )
        
        switch optimization {
        case "minimal_display":
            // Minimal data for minimal display
            return baseData
        case "reduced_frequency":
            // Same data but will be updated less frequently
            return baseData
        case "manual_updates":
            // Data that would only update on manual refresh
            return baseData
        default:
            // Baseline with some P&L history
            let history = (0..<20).map { i in
                PnLDataPoint(
                    timestamp: Date().addingTimeInterval(-Double(i * 300)),
                    value: Double(iteration * 10 + i),
                    percentage: Double(iteration + i) / 20.0
                )
            }
            
            return WidgetData(
                pnl: baseData.pnl,
                pnlPercentage: baseData.pnlPercentage,
                todayPnL: baseData.todayPnL,
                unrealizedPnL: baseData.unrealizedPnL,
                equity: baseData.equity,
                openPositions: baseData.openPositions,
                lastPrice: baseData.lastPrice,
                priceChange: baseData.priceChange,
                isDemoMode: baseData.isDemoMode,
                connectionStatus: baseData.connectionStatus,
                lastUpdated: baseData.lastUpdated,
                symbol: baseData.symbol,
                pnlHistory: history
            )
        }
    }
    
    private func saveBatteryReport(_ report: WidgetBatteryReport, testName: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        let reportURL = documentsPath.appendingPathComponent("battery_report_\(testName).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(report)
            try data.write(to: reportURL)
            print("Battery report saved: \(reportURL.path)")
        } catch {
            print("Failed to save battery report: \(error)")
        }
    }
    
    private func generateComparativeReport(_ reports: [String: WidgetBatteryReport]) {
        var comparison = "Widget Size Battery Impact Comparison\n"
        comparison += "=====================================\n\n"
        
        for (size, report) in reports.sorted(by: { $0.key < $1.key }) {
            comparison += "\(size.capitalized) Widget:\n"
            comparison += "  Average CPU: \(String(format: "%.2f", report.averageCPUUsage))%\n"
            comparison += "  Peak Memory: \(formatBytes(report.peakMemoryIncrease))\n"
            comparison += "  Total Refreshes: \(report.totalRefreshes)\n"
            comparison += "  Memory Pressure: \(String(format: "%.2f", report.averageMemoryPressure))\n\n"
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        let reportURL = documentsPath.appendingPathComponent("widget_size_comparison.txt")
        
        do {
            try comparison.write(to: reportURL, atomically: true, encoding: .utf8)
            print("Comparative report saved: \(reportURL.path)")
        } catch {
            print("Failed to save comparative report: \(error)")
        }
    }
    
    private func generateOptimizationReport(_ reports: [String: WidgetBatteryReport]) {
        var optimization = "Widget Optimization Battery Impact Analysis\n"
        optimization += "==========================================\n\n"
        
        let baseline = reports["baseline"]!
        
        for (name, report) in reports.sorted(by: { $0.key < $1.key }) {
            let cpuImprovement = ((baseline.averageCPUUsage - report.averageCPUUsage) / baseline.averageCPUUsage) * 100
            let memoryImprovement = ((baseline.averageMemoryUsage - report.averageMemoryUsage) / Double(baseline.averageMemoryUsage)) * 100
            
            optimization += "\(name.replacingOccurrences(of: "_", with: " ").capitalized):\n"
            optimization += "  CPU Usage: \(String(format: "%.2f", report.averageCPUUsage))% "
            optimization += "(\(cpuImprovement >= 0 ? "+" : "")\(String(format: "%.1f", cpuImprovement))%)\n"
            optimization += "  Memory Usage: \(formatBytes(report.averageMemoryUsage)) "
            optimization += "(\(memoryImprovement >= 0 ? "+" : "")\(String(format: "%.1f", memoryImprovement))%)\n"
            optimization += "  Refreshes: \(report.totalRefreshes)\n\n"
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        let reportURL = documentsPath.appendingPathComponent("widget_optimization_analysis.txt")
        
        do {
            try optimization.write(to: reportURL, atomically: true, encoding: .utf8)
            print("Optimization report saved: \(reportURL.path)")
        } catch {
            print("Failed to save optimization report: \(error)")
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Battery Analysis Classes

class WidgetBatteryAnalyzer {
    private var longTermMonitor: LongTermBatteryMonitor?
    private var backgroundMonitor: BackgroundBatteryMonitor?
    private var networkFailureMonitor: NetworkFailureBatteryMonitor?
    
    func startLongTermMonitoring(duration: TimeInterval) {
        longTermMonitor = LongTermBatteryMonitor(duration: duration)
        longTermMonitor?.start()
    }
    
    func stopLongTermMonitoring() -> WidgetBatteryReport {
        guard let monitor = longTermMonitor else {
            return WidgetBatteryReport.empty
        }
        let report = monitor.stop()
        longTermMonitor = nil
        return report
    }
    
    func startBackgroundMonitoring() {
        backgroundMonitor = BackgroundBatteryMonitor()
        backgroundMonitor?.start()
    }
    
    func stopBackgroundMonitoring() -> WidgetBatteryReport {
        guard let monitor = backgroundMonitor else {
            return WidgetBatteryReport.empty
        }
        let report = monitor.stop()
        backgroundMonitor = nil
        return report
    }
    
    func startNetworkFailureMonitoring() {
        networkFailureMonitor = NetworkFailureBatteryMonitor()
        networkFailureMonitor?.start()
    }
    
    func stopNetworkFailureMonitoring() -> WidgetBatteryReport {
        guard let monitor = networkFailureMonitor else {
            return WidgetBatteryReport.empty
        }
        let report = monitor.stop()
        networkFailureMonitor = nil
        return report
    }
    
    func stopAllMonitoring() {
        longTermMonitor?.stop()
        backgroundMonitor?.stop()
        networkFailureMonitor?.stop()
        longTermMonitor = nil
        backgroundMonitor = nil
        networkFailureMonitor = nil
    }
}

struct WidgetBatteryReport: Codable {
    let testName: String
    let duration: TimeInterval
    let averageCPUUsage: Double
    let peakCPUUsage: Double
    let averageMemoryUsage: Int
    let peakMemoryIncrease: Int
    let averageMemoryPressure: Double
    let totalRefreshes: Int
    let refreshFailures: Int
    let backgroundCPUUsage: Double
    let backgroundMemoryIncrease: Int
    let failureRecoveryCPU: Double
    let retryAttempts: Int
    let projectedBatteryDrain: Double
    let timestamp: Date
    
    static let empty = WidgetBatteryReport(
        testName: "Empty",
        duration: 0,
        averageCPUUsage: 0,
        peakCPUUsage: 0,
        averageMemoryUsage: 0,
        peakMemoryIncrease: 0,
        averageMemoryPressure: 0,
        totalRefreshes: 0,
        refreshFailures: 0,
        backgroundCPUUsage: 0,
        backgroundMemoryIncrease: 0,
        failureRecoveryCPU: 0,
        retryAttempts: 0,
        projectedBatteryDrain: 0,
        timestamp: Date()
    )
    
    func scaledTo24Hours(scaleFactor: Double) -> WidgetBatteryReport {
        return WidgetBatteryReport(
            testName: testName + "_24h_scaled",
            duration: 24 * 60 * 60,
            averageCPUUsage: averageCPUUsage,
            peakCPUUsage: peakCPUUsage,
            averageMemoryUsage: averageMemoryUsage,
            peakMemoryIncrease: peakMemoryIncrease,
            averageMemoryPressure: averageMemoryPressure,
            totalRefreshes: Int(Double(totalRefreshes) * scaleFactor),
            refreshFailures: Int(Double(refreshFailures) * scaleFactor),
            backgroundCPUUsage: backgroundCPUUsage,
            backgroundMemoryIncrease: backgroundMemoryIncrease,
            failureRecoveryCPU: failureRecoveryCPU,
            retryAttempts: Int(Double(retryAttempts) * scaleFactor),
            projectedBatteryDrain: projectedBatteryDrain * scaleFactor,
            timestamp: timestamp
        )
    }
}

class LongTermBatteryMonitor {
    private let duration: TimeInterval
    private var startTime: Date?
    private var startCPU: Double = 0
    private var startMemory: Int = 0
    private var cpuSamples: [Double] = []
    private var memorySamples: [Int] = []
    private var refreshCount = 0
    private var sampleTimer: Timer?
    
    init(duration: TimeInterval) {
        self.duration = duration
    }
    
    func start() {
        startTime = Date()
        startCPU = getCurrentCPUUsage()
        startMemory = getCurrentMemoryUsage()
        
        // Sample every 5 seconds
        sampleTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.takeSample()
        }
        
        // Monitor widget refreshes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WidgetRefreshed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshCount += 1
        }
    }
    
    func stop() -> WidgetBatteryReport {
        sampleTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        
        let endTime = Date()
        let actualDuration = endTime.timeIntervalSince(startTime ?? endTime)
        
        let avgCPU = cpuSamples.isEmpty ? 0 : cpuSamples.reduce(0, +) / Double(cpuSamples.count)
        let peakCPU = cpuSamples.max() ?? 0
        let avgMemory = memorySamples.isEmpty ? 0 : memorySamples.reduce(0, +) / memorySamples.count
        let peakMemory = (memorySamples.max() ?? 0) - startMemory
        
        let memoryPressure = startMemory > 0 ? Double(peakMemory) / Double(startMemory) : 0
        let projectedDrain = calculateProjectedBatteryDrain(avgCPU: avgCPU, duration: actualDuration)
        
        return WidgetBatteryReport(
            testName: "LongTerm",
            duration: actualDuration,
            averageCPUUsage: avgCPU,
            peakCPUUsage: peakCPU,
            averageMemoryUsage: avgMemory,
            peakMemoryIncrease: peakMemory,
            averageMemoryPressure: memoryPressure,
            totalRefreshes: refreshCount,
            refreshFailures: 0,
            backgroundCPUUsage: 0,
            backgroundMemoryIncrease: 0,
            failureRecoveryCPU: 0,
            retryAttempts: 0,
            projectedBatteryDrain: projectedDrain,
            timestamp: Date()
        )
    }
    
    private func takeSample() {
        let cpu = getCurrentCPUUsage()
        let memory = getCurrentMemoryUsage()
        
        cpuSamples.append(cpu)
        memorySamples.append(memory)
        
        // Keep only recent samples to avoid memory bloat
        if cpuSamples.count > 1000 {
            cpuSamples.removeFirst(100)
            memorySamples.removeFirst(100)
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
    
    private func calculateProjectedBatteryDrain(avgCPU: Double, duration: TimeInterval) -> Double {
        // Rough estimation: 1% CPU usage for 1 hour = ~0.1% battery drain
        let hoursEquivalent = duration / 3600
        return avgCPU * hoursEquivalent * 0.1
    }
}

class BackgroundBatteryMonitor {
    private var backgroundStartTime: Date?
    private var backgroundStartCPU: Double = 0
    private var backgroundStartMemory: Int = 0
    private var isInBackground = false
    
    func start() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.enterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.enterForeground()
        }
    }
    
    func stop() -> WidgetBatteryReport {
        NotificationCenter.default.removeObserver(self)
        
        let backgroundCPU = isInBackground ? getCurrentCPUUsage() - backgroundStartCPU : 0
        let backgroundMemory = isInBackground ? getCurrentMemoryUsage() - backgroundStartMemory : 0
        
        return WidgetBatteryReport(
            testName: "Background",
            duration: backgroundStartTime?.timeIntervalSinceNow ?? 0,
            averageCPUUsage: 0,
            peakCPUUsage: 0,
            averageMemoryUsage: 0,
            peakMemoryIncrease: 0,
            averageMemoryPressure: 0,
            totalRefreshes: 0,
            refreshFailures: 0,
            backgroundCPUUsage: backgroundCPU,
            backgroundMemoryIncrease: backgroundMemory,
            failureRecoveryCPU: 0,
            retryAttempts: 0,
            projectedBatteryDrain: backgroundCPU * 0.05, // Background usage has less impact
            timestamp: Date()
        )
    }
    
    private func enterBackground() {
        backgroundStartTime = Date()
        backgroundStartCPU = getCurrentCPUUsage()
        backgroundStartMemory = getCurrentMemoryUsage()
        isInBackground = true
    }
    
    private func enterForeground() {
        isInBackground = false
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

class NetworkFailureBatteryMonitor {
    private var failureStartTime: Date?
    private var failureStartCPU: Double = 0
    private var retryCount = 0
    
    func start() {
        failureStartTime = Date()
        failureStartCPU = getCurrentCPUUsage()
        
        // Monitor for network-related notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NetworkRequestFailed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.retryCount += 1
        }
    }
    
    func stop() -> WidgetBatteryReport {
        NotificationCenter.default.removeObserver(self)
        
        let failureRecoveryCPU = getCurrentCPUUsage() - failureStartCPU
        
        return WidgetBatteryReport(
            testName: "NetworkFailure",
            duration: failureStartTime?.timeIntervalSinceNow ?? 0,
            averageCPUUsage: 0,
            peakCPUUsage: 0,
            averageMemoryUsage: 0,
            peakMemoryIncrease: 0,
            averageMemoryPressure: 0,
            totalRefreshes: 0,
            refreshFailures: retryCount,
            backgroundCPUUsage: 0,
            backgroundMemoryIncrease: 0,
            failureRecoveryCPU: failureRecoveryCPU,
            retryAttempts: retryCount,
            projectedBatteryDrain: failureRecoveryCPU * 0.2, // Failures can be more expensive
            timestamp: Date()
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
}