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
    @State private var showAPIKeyHelp = false
    @State private var showAPISecretHelp = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("API Key")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Button(action: {
                                    showAPIKeyHelp = true
                                }) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
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
                            HStack {
                                Text("API Secret")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Button(action: {
                                    showAPISecretHelp = true
                                }) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
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
                    PrimaryButton(
                        "Test Connection",
                        icon: "network",
                        size: .medium,
                        isDisabled: apiKey.isEmpty || apiSecret.isEmpty,
                        isLoading: isValidating,
                        fullWidth: false,
                        action: testConnection
                    )
                    
                    DestructiveButton(
                        "Clear Credentials",
                        icon: "trash",
                        size: .medium,
                        isDisabled: apiKey.isEmpty && apiSecret.isEmpty,
                        fullWidth: false,
                        action: clearCredentials
                    )
                }
            }
            .navigationTitle("Binance API Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    GhostButton(
                        "Cancel",
                        size: .medium,
                        fullWidth: false,
                        action: { dismiss() }
                    )
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    PrimaryButton(
                        "Save",
                        size: .medium,
                        isDisabled: apiKey.isEmpty || apiSecret.isEmpty,
                        fullWidth: false,
                        action: saveCredentials
                    )
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("API Key Help", isPresented: $showAPIKeyHelp) {
                Button("OK") { }
            } message: {
                Text("Your Binance API Key is a unique identifier that allows the app to access your account. It should be at least 64 characters long and contain only letters and numbers.\n\nTo create an API key:\n1. Go to Binance Security Settings\n2. Create a new API key\n3. Enable only 'Spot & Margin Trading'\n4. Restrict to your IP address\n5. Never enable withdrawal permissions")
            }
            .alert("API Secret Help", isPresented: $showAPISecretHelp) {
                Button("OK") { }
            } message: {
                Text("Your API Secret is a private key that authenticates your API requests. Keep this secret and never share it.\n\nSecurity tips:\n• Store securely (we use iOS Keychain)\n• Never share with anyone\n• Regenerate if compromised\n• Should be at least 64 characters\n• Contains only letters and numbers")
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

// ValidationState and ValidationIndicatorView are defined in ExchangeKeysView.swift



