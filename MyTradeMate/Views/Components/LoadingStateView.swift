import SwiftUI

struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingStateView(message: "Analyzing market...")
        LoadingStateView(message: "Loading signal...")
        LoadingStateView(message: "Calculating performance...")
    }
    .padding()
}