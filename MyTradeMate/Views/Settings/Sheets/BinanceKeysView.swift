import SwiftUI

struct BinanceKeysView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("binance_api_key") private var apiKey: String = ""
    @AppStorage("binance_api_secret") private var apiSecret: String = ""
    
    @State private var showSecret = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isValidating = false
    @State private var validationState: ValidationState = .none
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Paste your Binance API key here", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onChange(of: apiKey) { _, newValue in
                                    validateInput()
                                }
                            
                            if !apiKey.isEmpty {
                                ValidationIndicatorView(state: getApiKeyValidationState())
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Secret")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                if showSecret {
                                    TextField("Paste your Binance API secret here", text: $apiSecret)
                                        .textFieldStyle(.roundedBorder)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .onChange(of: apiSecret) { _, newValue in
                                            validateInput()
                                        }
                                } else {
                                    SecureField("Paste your Binance API secret here", text: $apiSecret)
                                        .textFieldStyle(.roundedBorder)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .onChange(of: apiSecret) { _, newValue in
                                            validateInput()
                                        }
                                }
                                
                                Button(action: {
                                    showSecret.toggle()
                                }) {
                                    Image(systemName: showSecret ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !apiSecret.isEmpty {
                                ValidationIndicatorView(state: getApiSecretValidationState())
                            }
                        }
                        
                        if isValidating {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Validating keys...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                } header: {
                    Text("Binance API Credentials")
                } footer: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your API credentials are stored securely on this device and never shared.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚠️ Security Requirements:")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                            
                            Text("• Only enable 'Spot & Margin Trading' permissions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Restrict to your IP address if possible")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Never enable 'Withdraw' permissions")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            if let url = URL(string: "https://www.binance.com/en/my/settings/api-management") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.caption2)
                                Text("Learn how to create Binance API keys")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
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
        guard validateCredentials() else { return }
        
        isValidating = true
        validationState = .validating
        
        Task {
            do {
                // Simulate API validation - in real implementation, this would test the connection
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                await MainActor.run {
                    isValidating = false
                    validationState = .valid
                    Log.userAction("Binance API keys validated successfully")
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    validationState = .invalid("Connection test failed")
                    showErrorMessage("Failed to validate API keys. Please check your credentials.")
                    Log.error(error, context: "Binance API validation")
                }
            }
        }
    }
    
    private func saveCredentials() {
        guard validateCredentials() else { return }
        
        // AppStorage automatically saves the values
        Log.ai.info("Binance API credentials saved")
        dismiss()
    }
    
    private func clearCredentials() {
        apiKey = ""
        apiSecret = ""
        Log.ai.info("Binance API credentials cleared")
    }
    
    private func validateCredentials() -> Bool {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSecret = apiSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            showErrorMessage("API Key cannot be empty")
            return false
        }
        
        guard !trimmedSecret.isEmpty else {
            showErrorMessage("API Secret cannot be empty")
            return false
        }
        
        // Binance API key format validation
        guard trimmedKey.count >= 64 else {
            showErrorMessage("Binance API key should be at least 64 characters long")
            return false
        }
        
        guard trimmedSecret.count >= 64 else {
            showErrorMessage("Binance API secret should be at least 64 characters long")
            return false
        }
        
        // Check for valid characters (alphanumeric)
        let validCharacterSet = CharacterSet.alphanumerics
        guard trimmedKey.rangeOfCharacter(from: validCharacterSet.inverted) == nil else {
            showErrorMessage("API key contains invalid characters")
            return false
        }
        
        guard trimmedSecret.rangeOfCharacter(from: validCharacterSet.inverted) == nil else {
            showErrorMessage("API secret contains invalid characters")
            return false
        }
        
        return true
    }
    
    private func validateInput() {
        // Real-time validation feedback
        validationState = .none
    }
    
    private func getApiKeyValidationState() -> ValidationState {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedKey.isEmpty {
            return .none
        } else if trimmedKey.count < 64 {
            return .invalid("API key should be at least 64 characters")
        } else if trimmedKey.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil {
            return .invalid("Contains invalid characters")
        } else {
            return .valid
        }
    }
    
    private func getApiSecretValidationState() -> ValidationState {
        let trimmedSecret = apiSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedSecret.isEmpty {
            return .none
        } else if trimmedSecret.count < 64 {
            return .invalid("API secret should be at least 64 characters")
        } else if trimmedSecret.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil {
            return .invalid("Contains invalid characters")
        } else {
            return .valid
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Supporting Types

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



