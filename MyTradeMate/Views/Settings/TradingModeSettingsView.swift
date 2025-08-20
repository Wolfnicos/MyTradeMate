import SwiftUI

/// The ONLY place where trading mode can be changed
/// Provides validation, requirements checking, and error handling
struct TradingModeSettingsView: View {
    @StateObject private var tradingModeStore = TradingModeStore.shared
    @State private var showingRequirements = false
    @State private var selectedMode: TradingMode?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundColor(.blue)
                
                Text("Trading Mode")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Current mode indicator
                ModernTradingModeChip(mode: tradingModeStore.currentMode)
            }
            
            // Description
            Text("Choose how your trading orders will be executed")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Mode options
            VStack(spacing: 12) {
                ForEach(TradingMode.allCases, id: \.self) { mode in
                    TradingModeRow(
                        mode: mode,
                        isSelected: tradingModeStore.currentMode == mode,
                        isEnabled: tradingModeStore.canChangeTo(mode),
                        onTap: { handleModeSelection(mode) }
                    )
                }
            }
            
            // Error message
            if let errorMessage = tradingModeStore.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 8)
            }
            
            // Loading indicator
            if tradingModeStore.isChangingMode {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Changing trading mode...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showingRequirements) {
            if let mode = selectedMode {
                TradingModeRequirementsSheet(
                    mode: mode,
                    requirements: tradingModeStore.requirementsFor(mode),
                    onProceed: {
                        Task {
                            await tradingModeStore.changeTo(mode)
                        }
                        showingRequirements = false
                    },
                    onCancel: {
                        showingRequirements = false
                    }
                )
            }
        }
    }
    
    private func handleModeSelection(_ mode: TradingMode) {
        guard mode != tradingModeStore.currentMode else { return }
        
        selectedMode = mode
        
        // Check if mode has requirements
        let requirements = tradingModeStore.requirementsFor(mode)
        let unmetRequirements = requirements.filter { !$0.isMet }
        
        if !unmetRequirements.isEmpty {
            // Show requirements sheet
            showingRequirements = true
        } else {
            // Change mode directly
            Task {
                await tradingModeStore.changeTo(mode)
            }
        }
    }
}

struct TradingModeRow: View {
    let mode: TradingMode
    let isSelected: Bool
    let isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.system(size: 20))
            
            // Mode info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mode.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                    
                    if mode.requiresAPIKeys {
                        Image(systemName: "key.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(mode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Status indicator
            if !isEnabled {
                Text("Requires Setup")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEnabled {
                onTap()
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct TradingModeRequirementsSheet: View {
    let mode: TradingMode
    let requirements: [ValidationRequirement]
    let onProceed: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Switch to \(mode.title) Mode")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("The following requirements must be met before switching to \(mode.title.lowercased()) mode:")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Requirements list
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(requirements) { requirement in
                        RequirementRow(requirement: requirement)
                    }
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    if allRequirementsMet {
                        Button("Switch to \(mode.title) Mode") {
                            onProceed()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    } else {
                        Button("Go to Settings") {
                            // TODO: Navigate to Exchange Keys settings
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private var allRequirementsMet: Bool {
        requirements.allSatisfy { $0.isMet }
    }
}

struct RequirementRow: View {
    let requirement: ValidationRequirement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(requirement.isMet ? .green : .red)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(requirement.title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(requirement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}


#Preview {
    TradingModeSettingsView()
        .padding()
}