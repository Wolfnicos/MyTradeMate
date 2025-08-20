import SwiftUI

/// Demo view showing how to use the ToastView system
struct ToastDemoView: View {
    @EnvironmentObject var toastManager: ToastManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Toast Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Button("Show Success Toast") {
                    toastManager.showSuccess(
                        title: "Success!",
                        message: "Operation completed successfully"
                    )
                }
                .buttonStyle(.borderedProminent)
                
                Button("Show Error Toast") {
                    toastManager.showError(
                        title: "Error Occurred",
                        message: "Something went wrong"
                    )
                }
                .buttonStyle(.bordered)
                
                Button("Show Trade Success") {
                    toastManager.showTradeExecuted(symbol: "BTC/USD", side: "buy")
                }
                .buttonStyle(.borderedProminent)
                
                Button("Show Settings Saved") {
                    toastManager.showSettingsSaved()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

#Preview {
    ToastDemoView()
        .withToasts()
}