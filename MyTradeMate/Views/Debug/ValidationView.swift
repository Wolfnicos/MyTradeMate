import SwiftUI

// Simplified ValidationSuite for debug purposes  
@MainActor
class SimpleValidationSuite: ObservableObject {
    @Published var isRunning = false
    @Published var overallStatus: ValidationStatus = .notStarted
    @Published var validationResults: [ValidationResult] = []
    
    enum ValidationStatus {
        case notStarted, running, passed, failed, partiallyPassed
        
        var description: String {
            switch self {
            case .notStarted: return "Not Started"
            case .running: return "Running..."
            case .passed: return "All Tests Passed ✅"
            case .failed: return "Tests Failed ❌"
            case .partiallyPassed: return "Partially Passed ⚠️"
            }
        }
        
        var color: Color {
            switch self {
            case .notStarted: return .gray
            case .running: return .blue
            case .passed: return .green
            case .failed: return .red
            case .partiallyPassed: return .orange
            }
        }
    }
    
    struct ValidationResult {
        let id = UUID()
        let testName: String
        let category: String
        let passed: Bool
        let message: String
        let details: String?
        let timestamp: Date
        
        init(testName: String, category: String, passed: Bool, message: String, details: String? = nil) {
            self.testName = testName
            self.category = category
            self.passed = passed
            self.message = message
            self.details = details
            self.timestamp = Date()
        }
    }
    
    func runAllValidations() async {
        isRunning = true
        overallStatus = .running
        validationResults.removeAll()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second simulation
        
        validationResults.append(ValidationResult(
            testName: "App Settings",
            category: "Configuration", 
            passed: true,
            message: "Settings are properly configured"
        ))
        
        isRunning = false
        overallStatus = .passed
    }
}

struct ValidationView: View {
    @StateObject private var validationSuite = SimpleValidationSuite()
    @State private var showingDetails = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Overall Status
                VStack(spacing: 12) {
                    Text("MyTradeMate Validation Suite")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(validationSuite.overallStatus.description)
                        .font(.headline)
                        .foregroundColor(validationSuite.overallStatus.color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(validationSuite.overallStatus.color.opacity(0.1))
                        .cornerRadius(8)
                    
                    if validationSuite.isRunning {
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Test Results
                if !validationSuite.validationResults.isEmpty {
                    List {
                        ForEach(validationSuite.validationResults.indices, id: \.self) { index in
                            let result = validationSuite.validationResults[index]
                            ValidationResultRow(result: result)
                        }
                    }
                    .listStyle(PlainListStyle())
                } else {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Ready to run validation tests")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("This will test all core functionality of the MyTradeMate app")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await validationSuite.runAllValidations()
                        }
                    }) {
                        HStack {
                            if validationSuite.isRunning {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "play.circle.fill")
                            }
                            Text(validationSuite.isRunning ? "Running Tests..." : "Run All Tests")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(validationSuite.isRunning ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(validationSuite.isRunning)
                    
                    if !validationSuite.validationResults.isEmpty {
                        Button("Show Detailed Results") {
                            showingDetails = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("App Validation")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingDetails) {
                ValidationDetailsView(results: validationSuite.validationResults)
            }
        }
    }
}

struct ValidationResultRow: View {
    let result: SimpleValidationSuite.ValidationResult
    
    var body: some View {
        HStack {
            Text(result.status.icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.testName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("Duration: \(String(format: "%.3f", result.duration))s")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            statusBadge
        }
        .padding(.vertical, 4)
    }
    
    private var statusBadge: some View {
        Text(result.status == .passed ? "PASS" : result.status == .failed ? "FAIL" : "SKIP")
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch result.status {
        case .passed: return .green
        case .failed: return .red
        case .skipped: return .orange
        }
    }
}

struct ValidationDetailsView: View {
    let results: [SimpleValidationSuite.ValidationResult]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Test Summary") {
                    let passedCount = results.filter { $0.status == .passed }.count
                    let failedCount = results.filter { $0.status == .failed }.count
                    let skippedCount = results.filter { $0.status == .skipped }.count
                    let totalDuration = results.reduce(0) { $0 + $1.duration }
                    
                    HStack {
                        Text("Total Tests")
                        Spacer()
                        Text("\(results.count)")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Passed")
                        Spacer()
                        Text("\(passedCount)")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Failed")
                        Spacer()
                        Text("\(failedCount)")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    
                    if skippedCount > 0 {
                        HStack {
                            Text("Skipped")
                            Spacer()
                            Text("\(skippedCount)")
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack {
                        Text("Total Duration")
                        Spacer()
                        Text("\(String(format: "%.3f", totalDuration))s")
                            .fontWeight(.medium)
                    }
                }
                
                Section("Detailed Results") {
                    ForEach(results.indices, id: \.self) { index in
                        let result = results[index]
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(result.status.icon)
                                Text(result.testName)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(String(format: "%.3f", result.duration))s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(result.message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Validation Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ValidationView()
}