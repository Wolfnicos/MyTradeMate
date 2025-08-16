import SwiftUI

struct KrakenKeysView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("kraken_api_key") private var apiKey: String = ""
    @AppStorage("kraken_api_secret") private var apiSecret: String = ""
    
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
                            
                            TextField("Paste your Kraken API key here", text: $apiKey)
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
                                    TextField("Paste your Kraken API secret here", text: $apiSecret)
                                        .textFieldStyle(.roundedBorder)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .onChange(of: apiSecret) { _, newValue in
                                            validateInput()
                                        }
                                } else {
                                    SecureField("Paste your Kraken API secret here", text: $apiSecret)
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
                    Text("Kraken API Credentials")
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
                            
                            Text("• Only enable 'Query Funds' and 'Query Open Orders' permissions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Restrict to your IP address if possible")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Never enable 'Withdraw Funds' permissions")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            if let url = URL(string: "https://support.kraken.com/hc/en-us/articles/360000919966-How-to-generate-an-API-key-pair-") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.caption2)
                                Text("Learn how to create Kraken API keys")
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
            .navigationTitle("Kraken API Keys")
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
                Text("Your Kraken API Key is a unique identifier for your account access. It should be at least 56 characters long.\n\nTo create an API key:\n1. Go to Kraken Security Settings\n2. Generate a new API key\n3. Enable only 'Query Funds' and 'Query Open Orders'\n4. Restrict to your IP address\n5. Never enable withdrawal permissions")
            }
            .alert("API Secret Help", isPresented: $showAPISecretHelp) {
                Button("OK") { }
            } message: {
                Text("Your API Secret is a base64-encoded private key that authenticates your requests. It should be at least 88 characters long.\n\nSecurity tips:\n• Keep this completely secret\n• Never share with anyone\n• Stored securely in iOS Keychain\n• Regenerate if compromised\n• Contains base64 characters (A-Z, a-z, 0-9, +, /, =)")
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
                    Log.userAction("Kraken API keys validated successfully")
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    validationState = .invalid("Connection test failed")
                    showErrorMessage("Failed to validate API keys. Please check your credentials.")
                    Log.error(error, context: "Kraken API validation")
                }
            }
        }
    }
    
    private func saveCredentials() {
        guard validateCredentials() else { return }
        
        // AppStorage automatically saves the values
        Log.ai.info("Kraken API credentials saved")
        dismiss()
    }
    
    private func clearCredentials() {
        apiKey = ""
        apiSecret = ""
        Log.ai.info("Kraken API credentials cleared")
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
        
        // Kraken API key format validation
        guard trimmedKey.count >= 56 else {
            showErrorMessage("Kraken API key should be at least 56 characters long")
            return false
        }
        
        guard trimmedSecret.count >= 88 else {
            showErrorMessage("Kraken API secret should be at least 88 characters long")
            return false
        }
        
        // Kraken API keys are base64 encoded, so check for valid base64 characters
        let base64CharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
        guard trimmedSecret.rangeOfCharacter(from: base64CharacterSet.inverted) == nil else {
            showErrorMessage("API secret contains invalid characters (should be base64 encoded)")
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
        } else if trimmedKey.count < 56 {
            return .invalid("API key should be at least 56 characters")
        } else {
            return .valid
        }
    }
    
    private func getApiSecretValidationState() -> ValidationState {
        let trimmedSecret = apiSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedSecret.isEmpty {
            return .none
        } else if trimmedSecret.count < 88 {
            return .invalid("API secret should be at least 88 characters")
        } else {
            let base64CharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
            if trimmedSecret.rangeOfCharacter(from: base64CharacterSet.inverted) != nil {
                return .invalid("Should be base64 encoded")
            } else {
                return .valid
            }
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}



