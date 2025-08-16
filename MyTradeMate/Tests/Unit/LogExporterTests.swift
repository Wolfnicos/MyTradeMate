import XCTest
@testable import MyTradeMate

class LogExporterTests: XCTestCase {
    
    func testExportDiagnosticLogs() async throws {
        // Test that the log export functionality creates a file
        let url = try await LogExporter.exportDiagnosticLogs()
        
        // Verify the file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        
        // Verify the file has content
        let data = try Data(contentsOf: url)
        XCTAssertGreaterThan(data.count, 0)
        
        // Verify the content contains expected headers
        let content = String(data: data, encoding: .utf8)
        XCTAssertNotNil(content)
        XCTAssertTrue(content!.contains("MyTradeMate Diagnostic Logs"))
        XCTAssertTrue(content!.contains("App Version:"))
        XCTAssertTrue(content!.contains("Build Number:"))
        XCTAssertTrue(content!.contains("iOS Version:"))
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
    
    func testLogExportError() async {
        // Test error handling by creating a scenario where export might fail
        // This is a basic test - in a real scenario you might mock file system operations
        
        do {
            let _ = try await LogExporter.exportDiagnosticLogs()
            // If we get here, the export succeeded (which is expected in normal conditions)
        } catch {
            // If we get an error, verify it's the expected type
            XCTAssertTrue(error is LogExportError)
        }
    }
    
    func testLogExportFileNaming() async throws {
        // Test that exported files have proper naming
        let url = try await LogExporter.exportDiagnosticLogs()
        
        let fileName = url.lastPathComponent
        XCTAssertTrue(fileName.hasPrefix("MyTradeMate_Logs_"))
        XCTAssertTrue(fileName.hasSuffix(".txt"))
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
}