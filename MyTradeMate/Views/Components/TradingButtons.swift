import SwiftUI

struct BuyButton: View {
    let isDisabled: Bool
    let isDemoMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title3)
                
                Text("BUY")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: isDisabled ? [.gray, .gray] : [.green, .green.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDemoMode ? .orange.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .disabled(isDisabled)
        .buttonStyle(TradingButtonStyle())
    }
}

struct SellButton: View {
    let isDisabled: Bool
    let isDemoMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title3)
                
                Text("SELL")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: isDisabled ? [.gray, .gray] : [.red, .red.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDemoMode ? .orange.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .disabled(isDisabled)
        .buttonStyle(TradingButtonStyle())
    }
}

struct TradingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            BuyButton(isDisabled: false, isDemoMode: false) {}
            SellButton(isDisabled: false, isDemoMode: false) {}
        }
        
        HStack(spacing: 12) {
            BuyButton(isDisabled: false, isDemoMode: true) {}
            SellButton(isDisabled: false, isDemoMode: true) {}
        }
        
        LoadingStateView(message: "Submitting order...")
    }
    .padding()
}