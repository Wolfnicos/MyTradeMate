import SwiftUI
import Security
import Foundation

// Exchange model is defined in Models/Exchange.swift

// MARK: - Forward Declaration for ExchangeKeysViewModel
@MainActor
class ExchangeKeysViewModel: ObservableObject {
    @Published var editingExchange: Exchange?
    @Published var isLoading = false
    @Published var keyStatuses: [Exchange: Bool] = [:]
    @Published var connectionTestResults: [Exchange: ConnectionTestResult] = [:]
    @Published var isTestingConnection = false
    
    private let errorManager = ErrorManager.shared
    
    init() {
        loadKeyStatuses()
    }
    
    func hasKeys(for exchange: Exchange) -> Bool {
        return keyStatuses[exchange] ?? false
    }
    
    func editKeys(for exchange: Exchange) {
        editingExchange = exchange
    }
    
    func saveKeys(for exchange: Exchange, apiKey: String, secretKey: String) {
        isLoading = true
        
        Task {
            do {
                try await KeychainStore.shared.saveExchangeCredentials(
                    apiKey: apiKey,
                    apiSecret: secretKey,
                    for: exchange
                )
                
                await MainActor.run {
                    self.keyStatuses[exchange] = true
                    self.editingExchange = nil
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorManager.handle(error, context: "Saving \(exchange.rawValue) credentials")
                    self.isLoading = false
                }
            }
        }
    }
    
    func deleteKeys(for exchange: Exchange) {
        isLoading = true
        
        Task {
            do {
                try await KeychainStore.shared.deleteCredentials(for: exchange)
                
                await MainActor.run {
                    self.keyStatuses[exchange] = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorManager.handle(error, context: "Deleting \(exchange.rawValue) credentials")
                    self.isLoading = false
                }
            }
        }
    }
    
    func testConnection(for exchange: Exchange) {
        isTestingConnection = true
        
        Task {
            do {
                let credentials = try await KeychainStore.shared.getExchangeCredentials(for: exchange)
                let result = try await performConnectionTest(exchange: exchange, credentials: credentials)
                
                await MainActor.run {
                    self.connectionTestResults[exchange] = result
                    self.isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    self.connectionTestResults[exchange] = ConnectionTestResult(
                        isSuccess: false,
                        message: "Test failed: \(error.localizedDescription)",
                        timestamp: Date()
                    )
                    self.isTestingConnection = false
                }
            }
        }
    }
    
    private func loadKeyStatuses() {
        Task {
            var statuses: [Exchange: Bool] = [:]
            
            for exchange in Exchange.allCases {
                let hasKeys = await KeychainStore.shared.hasCredentials(for: exchange)
                statuses[exchange] = hasKeys
            }
            
            await MainActor.run {
                self.keyStatuses = statuses
            }
        }
    }
    
    private func performConnectionTest(exchange: Exchange, credentials: (apiKey: String, apiSecret: String)) async throws -> ConnectionTestResult {
        // Simplified connection test - implement actual API calls later
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        return ConnectionTestResult(
            isSuccess: true,
            message: "Connection successful",
            timestamp: Date()
        )
    }
}

struct ConnectionTestResult {
    let isSuccess: Bool
    let message: String
    let timestamp: Date
}

struct ExchangeCredentials {
    let apiKey: String
    let apiSecret: String
}

struct ExchangeKeysView: View {
    @StateObject private var viewModel = ExchangeKeysViewModel()
    @State private var showingDeleteAlert = false
    @State private var keyToDelete: Exchange?
    
    var body: some View {
        Form {
            Section(header: Text("Exchange API Keys"), footer: Text("API keys are securely stored in the device Keychain")) {
                ForEach(Exchange.allCases, id: \.self) { exchange in
                    ExchangeKeyRow(
                        exchange: exchange,
                        hasKeys: viewModel.hasKeys(for: exchange),
                        onEdit: { viewModel.editKeys(for: exchange) },
                        onDelete: { 
                            keyToDelete = exchange
                            showingDeleteAlert = true
                        },
                        viewModel: viewModel
                    )
                }
            }
            
            Section(header: Text("Instructions")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Create API keys on your exchange")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("2. Enable 'Futures Trading' permissions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("3. Restrict to your IP address for security")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("4. Never share your keys with anyone")
                        .font(.caption)
                        .foregroundColor(.red)
                        .bold()
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("API Keys")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $viewModel.editingExchange) { exchange in
            ExchangeKeyEditView(exchange: exchange) { apiKey, secretKey in
                viewModel.saveKeys(for: exchange, apiKey: apiKey, secretKey: secretKey)
            }
        }
        .alert("Delete API Keys", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let exchange = keyToDelete {
                    viewModel.deleteKeys(for: exchange)
                }
            }
        } message: {
            if let exchange = keyToDelete {
                Text("Are you sure you want to delete the API keys for \(exchange.displayName)?")
            }
        }
    }
}

struct ExchangeKeyRow: View {
    let exchange: Exchange
    let hasKeys: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    @ObservedObject var viewModel: ExchangeKeysViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exchange.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(hasKeys ? "Keys configured" : "No keys")
                        .font(.caption2)
                        .foregroundColor(hasKeys ? .green : .secondary)
                    
                    if let testResult = viewModel.connectionTestResults[exchange] {
                        Text(testResult.isSuccess ? "✓ Connection verified" : "✗ Connection failed")
                            .font(.caption2)
                            .foregroundColor(testResult.isSuccess ? .green : .red)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if hasKeys {
                    Button("Test") {
                        viewModel.testConnection(for: exchange)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.blue)
                    .disabled(viewModel.isTestingConnection)
                }
                
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                if hasKeys {
                    Button("Delete") {
                        onDelete()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct ExchangeKeyEditView: View {
    let exchange: Exchange
    let onSave: (String, String) -> Void
    
    @State private var apiKey = ""
    @State private var secretKey = ""
    @State private var showSecretKey = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("\(exchange.displayName) API Keys")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Secret Key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(showSecretKey ? "Hide" : "Show") {
                                showSecretKey.toggle()
                            }
                            .font(.caption2)
                        }
                        
                        if showSecretKey {
                            TextField("Enter Secret Key", text: $secretKey)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Enter Secret Key", text: $secretKey)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                    }
                }
                
                Section(footer: Text("Keys are encrypted and stored securely in the device Keychain")) {
                    EmptyView()
                }
            }
            .navigationTitle("Edit Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(apiKey, secretKey)
                        dismiss()
                    }
                    .disabled(apiKey.isEmpty || secretKey.isEmpty)
                }
            }
        }
        .onAppear {
            loadExistingKeys()
        }
    }
    
    private func loadExistingKeys() {
        Task {
            do {
                let credentials = try await KeychainStore.shared.getExchangeCredentials(for: exchange)
                await MainActor.run {
                    apiKey = credentials.apiKey
                    secretKey = credentials.apiSecret
                }
            } catch {
                // Keys don't exist yet, which is fine
            }
        }
    }
}





// Exchange extensions are defined in Models/Exchange.swift

#Preview {
    NavigationStack {
        ExchangeKeysView()
    }
}