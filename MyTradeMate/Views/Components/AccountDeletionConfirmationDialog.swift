import SwiftUI

// MARK: - Account Deletion Confirmation Dialog
struct AccountDeletionConfirmationDialog: View {
    let isExecuting: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ConfirmationDialog(
            title: "Delete Account",
            message: "This action cannot be undone. All your data will be permanently deleted.",
            icon: "exclamationmark.triangle.fill",
            iconColor: .red,
            confirmButtonText: "Delete Account",
            confirmButtonColor: .red,
            cancelButtonText: "Cancel",
            isDestructive: true,
            isExecuting: isExecuting,
            onConfirm: onConfirm,
            onCancel: onCancel,
            content: {
                AnyView(deletionWarningView)
            }
        )
    }
    
    private var deletionWarningView: some View {
        VStack(spacing: 16) {
            // What will be deleted
            VStack(alignment: .leading, spacing: 12) {
                Text("The following data will be permanently deleted:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    deletionItem(icon: "key.fill", text: "All API keys and credentials")
                    deletionItem(icon: "chart.line.uptrend.xyaxis", text: "Trading history and performance data")
                    deletionItem(icon: "brain.head.profile", text: "AI strategy configurations")
                    deletionItem(icon: "gearshape.fill", text: "App settings and preferences")
                    deletionItem(icon: "folder.fill", text: "All exported data and logs")
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Final warning
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Final Warning")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    
                    Text("This action is irreversible. Make sure you have exported any important data before proceeding.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(.red.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func deletionItem(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .font(.system(size: 12))
                .frame(width: 16)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Data Export Confirmation Dialog
struct DataExportConfirmationDialog: View {
    let exportType: ExportType
    let isExecuting: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ConfirmationDialog(
            title: "Export \(exportType.displayName)",
            message: "Your \(exportType.displayName.lowercased()) will be exported to a file that you can save or share.",
            icon: "square.and.arrow.up.fill",
            iconColor: .blue,
            confirmButtonText: "Export",
            confirmButtonColor: .blue,
            cancelButtonText: "Cancel",
            isDestructive: false,
            isExecuting: isExecuting,
            onConfirm: onConfirm,
            onCancel: onCancel,
            content: {
                AnyView(exportDetailsView)
            }
        )
    }
    
    private var exportDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export will include:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(exportType.includedData, id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
            
            if !exportType.excludedData.isEmpty {
                Divider()
                
                Text("Not included:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(exportType.excludedData, id: \.self) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            
                            Text(item)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Export Type
enum ExportType {
    case logs
    case tradingData
    case allData
    
    var displayName: String {
        switch self {
        case .logs:
            return "Diagnostic Logs"
        case .tradingData:
            return "Trading Data"
        case .allData:
            return "All Data"
        }
    }
    
    var includedData: [String] {
        switch self {
        case .logs:
            return [
                "Application logs",
                "Error reports",
                "Performance metrics",
                "System information"
            ]
        case .tradingData:
            return [
                "Trade history",
                "P&L data",
                "Strategy performance",
                "Market data cache"
            ]
        case .allData:
            return [
                "All trading data",
                "Strategy configurations",
                "App settings",
                "Diagnostic logs",
                "Performance history"
            ]
        }
    }
    
    var excludedData: [String] {
        switch self {
        case .logs:
            return [
                "API keys and secrets",
                "Personal trading data",
                "Strategy configurations"
            ]
        case .tradingData:
            return [
                "API keys and secrets",
                "Diagnostic logs",
                "System information"
            ]
        case .allData:
            return [
                "API keys and secrets (for security)"
            ]
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AccountDeletionConfirmationDialog(
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
        
        DataExportConfirmationDialog(
            exportType: .logs,
            isExecuting: false,
            onConfirm: {},
            onCancel: {}
        )
    }
    .padding()
    .background(Color.black.opacity(0.3))
}