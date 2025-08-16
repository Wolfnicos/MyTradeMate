import Foundation

/// Generates comprehensive test reports for MyTradeMate validation
struct TestReportGenerator {
    
    struct TestReport {
        let timestamp: Date
        let appVersion: String
        let buildNumber: String
        let testResults: [TestSuiteResult]
        let overallStatus: TestStatus
        let totalDuration: TimeInterval
        let deviceInfo: DeviceInfo
        
        enum TestStatus {
            case passed
            case failed
            case partiallyPassed
            
            var description: String {
                switch self {
                case .passed: return "PASSED"
                case .failed: return "FAILED"
                case .partiallyPassed: return "PARTIALLY PASSED"
                }
            }
        }
    }
    
    struct TestSuiteResult {
        let suiteName: String
        let tests: [TestResult]
        let duration: TimeInterval
        let status: TestReport.TestStatus
        
        var passedCount: Int { tests.filter { $0.status == .passed }.count }
        var failedCount: Int { tests.filter { $0.status == .failed }.count }
        var skippedCount: Int { tests.filter { $0.status == .skipped }.count }
    }
    
    struct TestResult {
        let testName: String
        let status: TestStatus
        let message: String
        let duration: TimeInterval
        let stackTrace: String?
        
        enum TestStatus {
            case passed
            case failed
            case skipped
        }
    }
    
    struct DeviceInfo {
        let deviceModel: String
        let osVersion: String
        let appVersion: String
        let buildConfiguration: String
        let memoryInfo: MemoryInfo
        
        struct MemoryInfo {
            let totalMemoryMB: Double
            let availableMemoryMB: Double
            let usedMemoryMB: Double
        }
    }
    
    // MARK: - Report Generation
    
    func generateReport(from validationResults: [ValidationSuite.ValidationResult]) -> TestReport {
        let deviceInfo = collectDeviceInfo()
        let testResults = convertValidationResults(validationResults)
        let overallStatus = calculateOverallStatus(from: testResults)
        let totalDuration = testResults.reduce(0) { $0 + $1.duration }
        
        return TestReport(
            timestamp: Date(),
            appVersion: getAppVersion(),
            buildNumber: getBuildNumber(),
            testResults: [TestSuiteResult(
                suiteName: "MyTradeMate Validation Suite",
                tests: testResults,
                duration: totalDuration,
                status: overallStatus
            )],
            overallStatus: overallStatus,
            totalDuration: totalDuration,
            deviceInfo: deviceInfo
        )
    }
    
    func generateHTMLReport(_ report: TestReport) -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>MyTradeMate Test Report</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f7; }
                .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
                .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 12px 12px 0 0; }
                .header h1 { margin: 0; font-size: 2.5em; font-weight: 300; }
                .header .subtitle { opacity: 0.9; margin-top: 10px; font-size: 1.1em; }
                .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; padding: 30px; }
                .summary-card { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; }
                .summary-card h3 { margin: 0 0 10px 0; color: #333; }
                .summary-card .value { font-size: 2em; font-weight: bold; margin: 10px 0; }
                .passed { color: #28a745; }
                .failed { color: #dc3545; }
                .skipped { color: #ffc107; }
                .test-results { padding: 0 30px 30px 30px; }
                .test-suite { margin-bottom: 30px; }
                .test-suite h2 { color: #333; border-bottom: 2px solid #eee; padding-bottom: 10px; }
                .test-item { display: flex; align-items: center; padding: 15px; margin: 10px 0; border-radius: 8px; background: #f8f9fa; }
                .test-item.passed { border-left: 4px solid #28a745; }
                .test-item.failed { border-left: 4px solid #dc3545; }
                .test-item.skipped { border-left: 4px solid #ffc107; }
                .test-icon { font-size: 1.5em; margin-right: 15px; }
                .test-details { flex: 1; }
                .test-name { font-weight: 600; color: #333; }
                .test-message { color: #666; margin-top: 5px; font-size: 0.9em; }
                .test-duration { color: #999; font-size: 0.8em; margin-left: auto; }
                .device-info { background: #f8f9fa; padding: 20px; margin: 20px 30px; border-radius: 8px; }
                .device-info h3 { margin-top: 0; color: #333; }
                .info-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
                .info-item { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
                .footer { text-align: center; padding: 20px; color: #666; font-size: 0.9em; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>MyTradeMate Test Report</h1>
                    <div class="subtitle">
                        Generated on \(formatDate(report.timestamp)) • 
                        Version \(report.appVersion) (\(report.buildNumber)) • 
                        Status: \(report.overallStatus.description)
                    </div>
                </div>
                
                <div class="summary">
                    <div class="summary-card">
                        <h3>Total Tests</h3>
                        <div class="value">\(getTotalTestCount(report))</div>
                    </div>
                    <div class="summary-card">
                        <h3>Passed</h3>
                        <div class="value passed">\(getPassedTestCount(report))</div>
                    </div>
                    <div class="summary-card">
                        <h3>Failed</h3>
                        <div class="value failed">\(getFailedTestCount(report))</div>
                    </div>
                    <div class="summary-card">
                        <h3>Duration</h3>
                        <div class="value">\(String(format: "%.2f", report.totalDuration))s</div>
                    </div>
                </div>
                
                <div class="device-info">
                    <h3>Device Information</h3>
                    <div class="info-grid">
                        <div class="info-item">
                            <span>Device Model:</span>
                            <span>\(report.deviceInfo.deviceModel)</span>
                        </div>
                        <div class="info-item">
                            <span>OS Version:</span>
                            <span>\(report.deviceInfo.osVersion)</span>
                        </div>
                        <div class="info-item">
                            <span>Build Configuration:</span>
                            <span>\(report.deviceInfo.buildConfiguration)</span>
                        </div>
                        <div class="info-item">
                            <span>Total Memory:</span>
                            <span>\(String(format: "%.0f", report.deviceInfo.memoryInfo.totalMemoryMB))MB</span>
                        </div>
                        <div class="info-item">
                            <span>Available Memory:</span>
                            <span>\(String(format: "%.0f", report.deviceInfo.memoryInfo.availableMemoryMB))MB</span>
                        </div>
                        <div class="info-item">
                            <span>Used Memory:</span>
                            <span>\(String(format: "%.0f", report.deviceInfo.memoryInfo.usedMemoryMB))MB</span>
                        </div>
                    </div>
                </div>
                
                <div class="test-results">
                    \(generateTestSuitesHTML(report.testResults))
                </div>
                
                <div class="footer">
                    Report generated by MyTradeMate Test Suite • \(formatDate(report.timestamp))
                </div>
            </div>
        </body>
        </html>
        """
    }
    
    func generateJSONReport(_ report: TestReport) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(report)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return """
            {
                "error": "Failed to encode test report: \(error.localizedDescription)",
                "timestamp": "\(ISO8601DateFormatter().string(from: report.timestamp))"
            }
            """
        }
    }
    
    func generateMarkdownReport(_ report: TestReport) -> String {
        let passedCount = getPassedTestCount(report)
        let failedCount = getFailedTestCount(report)
        let totalCount = getTotalTestCount(report)
        let successRate = totalCount > 0 ? Int((Double(passedCount) / Double(totalCount)) * 100) : 0
        
        return """
        # MyTradeMate Test Report
        
        **Generated:** \(formatDate(report.timestamp))  
        **Version:** \(report.appVersion) (\(report.buildNumber))  
        **Status:** \(report.overallStatus.description)  
        **Duration:** \(String(format: "%.2f", report.totalDuration))s
        
        ## Summary
        
        | Metric | Value |
        |--------|-------|
        | Total Tests | \(totalCount) |
        | Passed | \(passedCount) ✅ |
        | Failed | \(failedCount) ❌ |
        | Success Rate | \(successRate)% |
        
        ## Device Information
        
        | Property | Value |
        |----------|-------|
        | Device Model | \(report.deviceInfo.deviceModel) |
        | OS Version | \(report.deviceInfo.osVersion) |
        | Build Configuration | \(report.deviceInfo.buildConfiguration) |
        | Total Memory | \(String(format: "%.0f", report.deviceInfo.memoryInfo.totalMemoryMB))MB |
        | Available Memory | \(String(format: "%.0f", report.deviceInfo.memoryInfo.availableMemoryMB))MB |
        | Used Memory | \(String(format: "%.0f", report.deviceInfo.memoryInfo.usedMemoryMB))MB |
        
        ## Test Results
        
        \(generateMarkdownTestResults(report.testResults))
        
        ---
        *Report generated by MyTradeMate Test Suite*
        """
    }
    
    // MARK: - Private Helper Methods
    
    private func convertValidationResults(_ results: [ValidationSuite.ValidationResult]) -> [TestResult] {
        return results.map { result in
            let status: TestResult.TestStatus
            switch result.status {
            case .passed: status = .passed
            case .failed: status = .failed
            case .skipped: status = .skipped
            }
            
            return TestResult(
                testName: result.testName,
                status: status,
                message: result.message,
                duration: result.duration,
                stackTrace: nil
            )
        }
    }
    
    private func calculateOverallStatus(from results: [TestResult]) -> TestReport.TestStatus {
        let failedCount = results.filter { $0.status == .failed }.count
        let passedCount = results.filter { $0.status == .passed }.count
        
        if failedCount == 0 {
            return .passed
        } else if passedCount > 0 {
            return .partiallyPassed
        } else {
            return .failed
        }
    }
    
    private func collectDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        let processInfo = ProcessInfo.processInfo
        
        // Get memory info
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let totalMemoryMB = Double(processInfo.physicalMemory) / 1024.0 / 1024.0
        var usedMemoryMB = 0.0
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            usedMemoryMB = Double(info.resident_size) / 1024.0 / 1024.0
        }
        
        let availableMemoryMB = totalMemoryMB - usedMemoryMB
        
        return DeviceInfo(
            deviceModel: device.model,
            osVersion: device.systemVersion,
            appVersion: getAppVersion(),
            buildConfiguration: getBuildConfiguration(),
            memoryInfo: DeviceInfo.MemoryInfo(
                totalMemoryMB: totalMemoryMB,
                availableMemoryMB: availableMemoryMB,
                usedMemoryMB: usedMemoryMB
            )
        )
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private func getBuildConfiguration() -> String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func getTotalTestCount(_ report: TestReport) -> Int {
        return report.testResults.reduce(0) { $0 + $1.tests.count }
    }
    
    private func getPassedTestCount(_ report: TestReport) -> Int {
        return report.testResults.reduce(0) { $0 + $1.passedCount }
    }
    
    private func getFailedTestCount(_ report: TestReport) -> Int {
        return report.testResults.reduce(0) { $0 + $1.failedCount }
    }
    
    private func generateTestSuitesHTML(_ testSuites: [TestSuiteResult]) -> String {
        return testSuites.map { suite in
            let testsHTML = suite.tests.map { test in
                let statusClass = test.status == .passed ? "passed" : test.status == .failed ? "failed" : "skipped"
                let icon = test.status == .passed ? "✅" : test.status == .failed ? "❌" : "⏭️"
                
                return """
                <div class="test-item \(statusClass)">
                    <div class="test-icon">\(icon)</div>
                    <div class="test-details">
                        <div class="test-name">\(test.testName)</div>
                        <div class="test-message">\(test.message)</div>
                    </div>
                    <div class="test-duration">\(String(format: "%.3f", test.duration))s</div>
                </div>
                """
            }.joined()
            
            return """
            <div class="test-suite">
                <h2>\(suite.suiteName)</h2>
                \(testsHTML)
            </div>
            """
        }.joined()
    }
    
    private func generateMarkdownTestResults(_ testSuites: [TestSuiteResult]) -> String {
        return testSuites.map { suite in
            let testsMarkdown = suite.tests.map { test in
                let icon = test.status == .passed ? "✅" : test.status == .failed ? "❌" : "⏭️"
                return "| \(icon) | \(test.testName) | \(test.message) | \(String(format: "%.3f", test.duration))s |"
            }.joined(separator: "\n")
            
            return """
            ### \(suite.suiteName)
            
            | Status | Test Name | Message | Duration |
            |--------|-----------|---------|----------|
            \(testsMarkdown)
            """
        }.joined(separator: "\n\n")
    }
}

// MARK: - Codable Extensions

extension TestReportGenerator.TestReport: Codable {}
extension TestReportGenerator.TestSuiteResult: Codable {}
extension TestReportGenerator.TestResult: Codable {}
extension TestReportGenerator.DeviceInfo: Codable {}
extension TestReportGenerator.DeviceInfo.MemoryInfo: Codable {}
extension TestReportGenerator.TestReport.TestStatus: Codable {}
extension TestReportGenerator.TestResult.TestStatus: Codable {}