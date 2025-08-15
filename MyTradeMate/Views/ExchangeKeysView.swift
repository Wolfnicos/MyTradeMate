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
                        }
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exchange.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(hasKeys ? "Keys configured" : "No keys")
                    .font(.caption2)
                    .foregroundColor(hasKeys ? .green : .secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
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
        NavigationView {
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
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
        let keychain = ExchangeKeychainManager.shared
        if let keys = keychain.getKeys(for: exchange) {
            apiKey = keys.apiKey
            secretKey = keys.secretKey
        }
    }
}

@MainActor
class ExchangeKeysViewModel: ObservableObject {
    @Published var editingExchange: Exchange?
    private let keychain = ExchangeKeychainManager.shared
    
    func hasKeys(for exchange: Exchange) -> Bool {
        return keychain.getKeys(for: exchange) != nil
    }
    
    func editKeys(for exchange: Exchange) {
        editingExchange = exchange
    }
    
    func saveKeys(for exchange: Exchange, apiKey: String, secretKey: String) {
        keychain.saveKeys(for: exchange, apiKey: apiKey, secretKey: secretKey)
        editingExchange = nil
    }
    
    func deleteKeys(for exchange: Exchange) {
        keychain.deleteKeys(for: exchange)
    }
}

class ExchangeKeychainManager {
    static let shared = ExchangeKeychainManager()
    private init() {}
    
    struct APIKeys {
        let apiKey: String
        let secretKey: String
    }
    
    func saveKeys(for exchange: Exchange, apiKey: String, secretKey: String) {
        let apiKeyService = "MyTradeMate-\(exchange.rawValue)-API"
        let secretKeyService = "MyTradeMate-\(exchange.rawValue)-SECRET"
        
        // Save API key
        save(value: apiKey, service: apiKeyService, account: "apikey")
        
        // Save secret key
        save(value: secretKey, service: secretKeyService, account: "secretkey")
    }
    
    func getKeys(for exchange: Exchange) -> APIKeys? {
        let apiKeyService = "MyTradeMate-\(exchange.rawValue)-API"
        let secretKeyService = "MyTradeMate-\(exchange.rawValue)-SECRET"
        
        guard let apiKey = get(service: apiKeyService, account: "apikey"),
              let secretKey = get(service: secretKeyService, account: "secretkey") else {
            return nil
        }
        
        return APIKeys(apiKey: apiKey, secretKey: secretKey)
    }
    
    func deleteKeys(for exchange: Exchange) {
        let apiKeyService = "MyTradeMate-\(exchange.rawValue)-API"
        let secretKeyService = "MyTradeMate-\(exchange.rawValue)-SECRET"
        
        delete(service: apiKeyService, account: "apikey")
        delete(service: secretKeyService, account: "secretkey")
    }
    
    private func save(value: String, service: String, account: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("❌ Failed to save to keychain: \(status)")
        }
    }
    
    private func get(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    private func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

extension Exchange: Identifiable {
    public var id: String { rawValue }
}

#Preview {
    NavigationView {
        ExchangeKeysView()
    }
}