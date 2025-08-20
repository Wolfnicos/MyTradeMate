import SwiftUI

/// Compact AI status bar with state, confidence, and timestamps
/// Tapping opens diagnostics log view for troubleshooting
struct AIStatusBar: View {
    @StateObject private var aiStatusStore = AIStatusStore.shared
    @State private var showingDiagnostics = false
    
    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 12) {
                // State icon with animation
                stateIcon
                    .transition(.scale.combined(with: .opacity))
                    .id(aiStatusStore.status.state.displayName) // Force re-render on state change
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        // State label
                        Text(aiStatusStore.status.state.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        // Confidence percentage (if running)
                        if let confidence = aiStatusStore.status.state.confidence {
                            Text("\(Int(confidence * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(aiStatusStore.status.state.statusColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(aiStatusStore.status.state.statusColor.opacity(0.15))
                                )
                        }
                    }
                    
                    // Timestamp and status info
                    HStack(spacing: 4) {
                        Text("Last update")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("·")
                            .font(.caption2)
                            .foregroundColor(.tertiary)
                        
                        Text(aiStatusStore.status.lastUpdateString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        // Next refresh info (if applicable)
                        if let nextRefresh = aiStatusStore.status.nextRefreshString {
                            Text("·")
                                .font(.caption2)
                                .foregroundColor(.tertiary)
                            
                            Text("refresh \(nextRefresh)")
                                .font(.caption2)
                                .foregroundColor(.tertiary)
                        }
                    }
                }
                
                Spacer()
                
                // Action button or state indicator
                actionButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(aiStatusStore.status.accessibilityDescription)
        .accessibilityHint("Tap to view AI diagnostics")
        .animation(.easeInOut(duration: 0.3), value: aiStatusStore.status.state)
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsLogView()
        }
    }
    
    // MARK: - Computed Views
    
    @ViewBuilder
    private var stateIcon: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(aiStatusStore.status.state.statusColor.opacity(0.15))
                .frame(width: 28, height: 28)
            
            // Icon with special handling for updating state
            if case .updating = aiStatusStore.status.state {
                Image(systemName: aiStatusStore.status.state.systemIconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(aiStatusStore.status.state.statusColor)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(
                        .linear(duration: 2.0).repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
            } else {
                Image(systemName: aiStatusStore.status.state.systemIconName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(aiStatusStore.status.state.statusColor)
            }
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch aiStatusStore.status.state {
        case .error:
            // Retry button for error state
            Button("Retry") {
                Task {
                    await aiStatusStore.retry()
                }
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red)
            .cornerRadius(8)
            
        case .paused:
            // Resume button for paused state
            Button("Resume") {
                Task {
                    await aiStatusStore.resume()
                }
            }
            .font(.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
        default:
            // Chevron to indicate tap interaction
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.tertiary)
        }
    }
    
    private var cardBackground: Color {
        switch aiStatusStore.status.state {
        case .error:
            return Color.red.opacity(0.05)
        case .running:
            return Color.green.opacity(0.05)
        default:
            return .ultraThinMaterial
        }
    }
    
    private var borderColor: Color {
        switch aiStatusStore.status.state {
        case .error:
            return Color.red.opacity(0.2)
        case .running:
            return Color.green.opacity(0.2)
        case .updating:
            return Color.blue.opacity(0.2)
        default:
            return Color.gray.opacity(0.2)
        }
    }
    
    @State private var rotationAngle: Double = 0
    
    // MARK: - Actions
    
    private func handleTap() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Show diagnostics
        showingDiagnostics = true
    }
}

/// Compact version for toolbar use
struct CompactAIStatusBar: View {
    @StateObject private var aiStatusStore = AIStatusStore.shared
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                // State icon
                Image(systemName: aiStatusStore.status.state.systemIconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(aiStatusStore.status.state.statusColor)
                
                // Confidence (if running)
                if let confidence = aiStatusStore.status.state.confidence {
                    Text("\(Int(confidence * 100))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

/// AI Status indicator for widget use
struct AIStatusIndicator: View {
    let status: AIStatus
    let size: IndicatorSize
    
    enum IndicatorSize {
        case small, medium, large
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }
        
        var circleSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 28
            case .large: return 36
            }
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(status.state.statusColor.opacity(0.15))
                .frame(width: size.circleSize, height: size.circleSize)
            
            Image(systemName: status.state.systemIconName)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(status.state.statusColor)
        }
    }
}

// MARK: - Diagnostics Log View

struct DiagnosticsLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var logEntries: [DiagnosticsEntry] = []
    
    var body: some View {
        NavigationView {
            List {
                Section("Recent AI Activity") {
                    ForEach(logEntries.prefix(50), id: \.id) { entry in
                        DiagnosticsEntryRow(entry: entry)
                    }
                }
                
                Section("System Info") {
                    SystemInfoRow(title: "AI Engine", value: "SignalManager v2.0")
                    SystemInfoRow(title: "Last Refresh", value: AIStatusStore.shared.status.lastUpdateString)
                    SystemInfoRow(title: "Status", value: AIStatusStore.shared.status.state.displayName)
                }
            }
            .navigationTitle("AI Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadDiagnosticsData()
        }
    }
    
    private func loadDiagnosticsData() {
        // In a real implementation, this would load from a logging system
        // For now, we'll show mock data
        logEntries = [
            DiagnosticsEntry(
                timestamp: Date().addingTimeInterval(-30),
                level: .info,
                message: "AI refresh completed successfully",
                metadata: ["confidence": "0.73", "latency": "245ms"]
            ),
            DiagnosticsEntry(
                timestamp: Date().addingTimeInterval(-120),
                level: .info,
                message: "Timeframe changed to 1H",
                metadata: ["previous": "5M", "new": "1H"]
            ),
            DiagnosticsEntry(
                timestamp: Date().addingTimeInterval(-300),
                level: .warning,
                message: "Low confidence prediction",
                metadata: ["confidence": "0.45", "threshold": "0.60"]
            )
        ]
    }
}

struct DiagnosticsEntry {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let metadata: [String: String]
    
    enum LogLevel {
        case info, warning, error
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            }
        }
    }
}

struct DiagnosticsEntryRow: View {
    let entry: DiagnosticsEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.level.icon)
                .font(.caption)
                .foregroundColor(entry.level.color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.message)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(timeString(from: entry.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !entry.metadata.isEmpty {
                    Text(metadataString(entry.metadata))
                        .font(.caption2)
                        .foregroundColor(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    private func metadataString(_ metadata: [String: String]) -> String {
        return metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
}

struct SystemInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview("AI Status Bar") {
    VStack(spacing: 20) {
        AIStatusBar()
        
        CompactAIStatusBar()
        
        HStack(spacing: 16) {
            AIStatusIndicator(
                status: .running(confidence: 0.73),
                size: .small
            )
            
            AIStatusIndicator(
                status: .updating(),
                size: .medium
            )
            
            AIStatusIndicator(
                status: .error("Network error"),
                size: .large
            )
        }
    }
    .padding()
}