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
            
            Section(header: Text("Setup Instructions")) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("1. Create API keys on your exchange")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Text("Visit your exchange's API management page to generate new keys")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("2. Configure permissions carefully")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Text("• Binance: Enable 'Spot & Margin Trading' only")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("• Kraken: Enable 'Query Funds' and 'Query Open Orders' only")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("3. Enhance security")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Text("• Restrict to your IP address if possible")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("• Never enable withdrawal permissions")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("4. Keep your keys secure")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                        
                        Text("Never share your API keys with anyone or store them in unsecured locations")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Quick Links")) {
                VStack(spacing: 8) {
                    Button(action: {
                        if let url = URL(string: "https://www.binance.com/en/my/settings/api-management") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            Text("Binance API Management")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://support.kraken.com/hc/en-us/articles/360000919966-How-to-generate-an-API-key-pair-") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                            Text("Kraken API Setup Guide")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
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





// MARK: - Validation Components

enum ValidationState: Equatable {
    case none
    case validating
    case valid
    case invalid(String)
}

struct ValidationIndicatorView: View {
    let state: ValidationState
    
    var body: some View {
        HStack(spacing: 6) {
            switch state {
            case .none:
                EmptyView()
            case .validating:
                ProgressView()
                    .scaleEffect(0.7)
                Text("Validating...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            case .valid:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("Valid format")
                    .font(.caption2)
                    .foregroundColor(.green)
            case .invalid(let message):
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state)
    }
}

struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
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