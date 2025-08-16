import SwiftUI
import Security

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
                        Text(testResult.isSuccessful ? "✓ Connection verified" : "✗ Connection failed")
                            .font(.caption2)
                            .foregroundColor(testResult.isSuccessful ? .green : .red)
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





extension Exchange: Identifiable {
    public var id: String { rawValue }
}

#Preview {
    NavigationStack {
        ExchangeKeysView()
    }
}