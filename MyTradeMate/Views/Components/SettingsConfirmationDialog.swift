import SwiftUI

// MARK: - Settings Confirmation Dialog
struct SettingsConfirmationDialog: View {
    let title: String
    let changes: [SettingChange]
    let isExecuting: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ConfirmationDialog(
            title: title,
            message: "The following settings will be changed:",
            icon: "gearshape.fill",
            iconColor: .blue,
            confirmButtonText: "Apply Changes",
            confirmButtonColor: .blue,
            cancelButtonText: "Cancel",
            isDestructive: false,
            isExecuting: isExecuting,
            onConfirm: onConfirm,
            onCancel: onCancel,
            content: {
                AnyView(settingsChangesView)
            }
        )
    }
    
    private var settingsChangesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(changes, id: \.id) { change in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(change.settingName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if change.requiresRestart {
                            Text("Restart Required")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.orange.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text("From:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(change.oldValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .strikethrough()
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("To:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(change.newValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    if let warning = change.warning {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text(warning)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                if change != changes.last {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Setting Change Model
struct SettingChange: Equatable {
    let id = UUID()
    let settingName: String
    let oldValue: String
    let newValue: String
    let requiresRestart: Bool
    let warning: String?
    
    init(
        settingName: String,
        oldValue: String,
        newValue: String,
        requiresRestart: Bool = false,
        warning: String? = nil
    ) {
        self.settingName = settingName
        self.oldValue = oldValue
        self.newValue = newValue
        self.requiresRestart = requiresRestart
        self.warning = warning
    }
    
    static func == (lhs: SettingChange, rhs: SettingChange) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Auto Trading Confirmation Dialog
struct AutoTradingConfirmationDialog: View {
    let isEnabling: Bool
    let isExecuting: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ConfirmationDialog(
            title: isEnabling ? "Enable Auto Trading" : "Disable Auto Trading",
            message: isEnabling ? 
                "Auto trading will allow AI strategies to place real trades automatically. Make sure you understand the risks." :
                "Auto trading will be disabled. All active strategies will stop placing new trades.",
            icon: isEnabling ? "play.circle.fill" : "pause.circle.fill",
            iconColor: isEnabling ? .green : .orange,
            confirmButtonText: isEnabling ? "Enable Auto Trading" : "Disable Auto Trading",
            confirmButtonColor: isEnabling ? .green : .orange,
            cancelButtonText: "Cancel",
            isDestructive: false,
            isExecuting: isExecuting,
            onConfirm: onConfirm,
            onCancel: onCancel,
            content: {
                AnyView(
                    VStack(spacing: 12) {
                        if isEnabling {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Risk Warning")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                    
                                    Text("Auto trading involves financial risk. Only enable if you understand and accept the potential losses.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                )
            }
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SettingsConfirmationDialog(
            title: "Apply Settings Changes",
            changes: [
                SettingChange(
                    settingName: "Auto Trading",
                    oldValue: "Disabled",
                    newValue: "Enabled",
                    requiresRestart: false,
                    warning: "This will allow AI to place real trades"
                ),
                SettingChange(
                    settingName: "API Endpoint",
                    oldValue: "Testnet",
                    newValue: "Production",
                    requiresRestart: true,
                    warning: "This will switch to live trading"
                )
            ],
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        AutoTradingConfirmationDialog(
            isEnabling: true,
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
    }
    .padding()
    .background(Color.black.opacity(0.3))
}