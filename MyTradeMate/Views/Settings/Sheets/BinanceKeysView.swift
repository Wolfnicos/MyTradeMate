import SwiftUI

struct BinanceKeysView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("binance_api_key") private var apiKey: String = ""
    @AppStorage("binance_api_secret") private var apiSecret: String = ""
    
    @State private var showSecret = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter your Binance API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Secret")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if showSecret {
                                TextField("Enter your Binance API Secret", text: $apiSecret)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("Enter your Binance API Secret", text: $apiSecret)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            
                            Button(action: {
                                showSecret.toggle()
                            }) {
                                Image(systemName: showSecret ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Binance API Credentials")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your API credentials are stored securely on this device and never shared.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("⚠️ For security, only enable 'Read' permissions for these keys.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Section {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(apiKey.isEmpty || apiSecret.isEmpty)
                    
                    Button("Clear Credentials", role: .destructive) {
                        clearCredentials()
                    }
                    .disabled(apiKey.isEmpty && apiSecret.isEmpty)
                }
            }
            .navigationTitle("Binance API Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCredentials()
                    }
                    .disabled(apiKey.isEmpty || apiSecret.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func testConnection() {
        // Simple validation
        guard !apiKey.isEmpty, !apiSecret.isEmpty else {
            showErrorMessage("Please enter both API key and secret")
            return
        }
        
        guard apiKey.count > 10, apiSecret.count > 10 else {
            showErrorMessage("API credentials appear to be invalid")
            return
        }
        
        // TODO: Implement actual connection test
        showErrorMessage("Connection test not yet implemented")
    }
    
    private func saveCredentials() {
        guard validateCredentials() else { return }
        
        // AppStorage automatically saves the values
        Log.ai("Binance API credentials saved")
        dismiss()
    }
    
    private func clearCredentials() {
        apiKey = ""
        apiSecret = ""
        Log.ai("Binance API credentials cleared")
    }
    
    private func validateCredentials() -> Bool {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showErrorMessage("API Key cannot be empty")
            return false
        }
        
        guard !apiSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showErrorMessage("API Secret cannot be empty")
            return false
        }
        
        return true
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}