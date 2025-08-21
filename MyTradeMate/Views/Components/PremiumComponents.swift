import SwiftUI

// MARK: - Premium AI Confidence Indicator
struct PremiumAIConfidenceView: View {
    let confidence: Double
    @State private var animatePulse = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 100, height: 100)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: confidence / 100)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.purple,
                            Color.blue,
                            Color.cyan,
                            Color.purple
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: confidence)
                .shadow(color: .blue, radius: 10)
            
            // Center text
            VStack(spacing: 2) {
                Text("\(Int(confidence))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("AI CONFIDENCE")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .overlay(
            // Pulse animation
            Circle()
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                .scaleEffect(animatePulse ? 1.2 : 1.0)
                .opacity(animatePulse ? 0 : 1)
                .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: animatePulse)
        )
        .onAppear {
            animatePulse = true
        }
    }
}

// MARK: - Premium Price Display
struct PremiumPriceDisplay: View {
    let price: String
    let change: Double
    let timeframe: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("$")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(price.components(separatedBy: ".").first ?? price)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.3), radius: 10)
                
                if let decimal = price.components(separatedBy: ".").last, 
                   price.contains(".") {
                    Text(".\(decimal)")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            // Change indicator
            HStack(spacing: 6) {
                Image(systemName: change > 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .foregroundColor(change > 0 ? PremiumTheme.Colors.green : PremiumTheme.Colors.red)
                    .font(.system(size: 14))
                
                Text("\(change > 0 ? "+" : "")\(change, specifier: "%.2f")%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(change > 0 ? PremiumTheme.Colors.green : PremiumTheme.Colors.red)
                
                Text(timeframe)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Premium Live Indicator
struct PremiumLiveIndicator: View {
    @State private var animatePulse = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(PremiumTheme.Colors.green)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(PremiumTheme.Colors.green.opacity(0.3), lineWidth: 8)
                        .scaleEffect(animatePulse ? 2 : 1)
                        .opacity(animatePulse ? 0 : 1)
                        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: animatePulse)
                )
            
            Text("LIVE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(PremiumTheme.Colors.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(PremiumTheme.Colors.green.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(PremiumTheme.Colors.green.opacity(0.5), lineWidth: 1)
                )
        )
        .onAppear {
            animatePulse = true
        }
    }
}

// MARK: - Premium Status Badge
struct PremiumStatusBadge: View {
    let text: String
    let isActive: Bool
    @State private var animatePulse = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? PremiumTheme.Colors.green : Color.gray)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(isActive ? PremiumTheme.Colors.green.opacity(0.3) : Color.clear, lineWidth: 8)
                        .scaleEffect(animatePulse && isActive ? 2 : 1)
                        .opacity((animatePulse && isActive) ? 0 : 1)
                        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: animatePulse)
                )
            
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isActive ? PremiumTheme.Colors.green : .gray)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
        .onAppear {
            if isActive {
                animatePulse = true
            }
        }
    }
}

// MARK: - Premium Buy/Sell Buttons
struct PremiumBuyButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                Text("Buy")
                    .fontWeight(.bold)
            }
        }
        .buttonStyle(PremiumButtonStyle(
            gradient: PremiumTheme.Colors.successGradient,
            glowColor: PremiumTheme.Colors.green
        ))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .pressAnimation(isPressed)
    }
}

struct PremiumSellButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 20))
                Text("Sell")
                    .fontWeight(.bold)
            }
        }
        .buttonStyle(PremiumButtonStyle(
            gradient: PremiumTheme.Colors.dangerGradient,
            glowColor: PremiumTheme.Colors.red
        ))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .pressAnimation(isPressed)
    }
}

// MARK: - Premium Strategy Card
struct PremiumStrategyCard: View {
    let strategyName: String
    let description: String
    let performance: Double
    let isActive: Bool
    @State private var animatePulse = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [PremiumTheme.Colors.blue.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "brain")
                        .font(.system(size: 24))
                        .foregroundColor(PremiumTheme.Colors.blue)
                }
                
                Spacer()
                
                // Status indicator
                PremiumStatusBadge(
                    text: isActive ? "Active" : "Paused",
                    isActive: isActive
                )
            }
            
            Text(strategyName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .lineLimit(2)
            
            // Performance badge
            HStack {
                Label("Performance", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("+\(performance, specifier: "%.1f")%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(PremiumTheme.Colors.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(PremiumTheme.Colors.green.opacity(0.2))
                    )
            }
        }
        .padding(20)
        .premiumCard()
    }
}

// MARK: - Premium Chart Loading Placeholder
struct PremiumChartLoadingView: View {
    @State private var animateLoading = false
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
            
            // Animated bars
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<10, id: \.self) { i in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    PremiumTheme.Colors.blue.opacity(0.3),
                                    PremiumTheme.Colors.purple.opacity(0.2)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 30, height: animateLoading ? CGFloat.random(in: 50...150) : 50)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1),
                            value: animateLoading
                        )
                }
            }
            .padding()
            
            // Loading text
            Text("Chart Loading...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
        }
        .onAppear {
            animateLoading = true
        }
    }
}

// MARK: - Premium Tab Bar Item
struct PremiumTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? PremiumTheme.Colors.blue : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(), value: isSelected)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? PremiumTheme.Colors.blue : .gray)
                
                // Selection indicator
                if isSelected {
                    Circle()
                        .fill(PremiumTheme.Colors.blue)
                        .frame(width: 4, height: 4)
                        .transition(.scale)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}