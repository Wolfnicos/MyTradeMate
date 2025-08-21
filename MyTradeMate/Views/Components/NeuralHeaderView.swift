import SwiftUI

struct NeuralHeaderView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var aiManager = AIModelManager.shared
    @State private var aiPulse = false
    @State private var showNotifications = false
    @State private var notifications = 3
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Header
            HStack {
                // Logo Section
                HStack(spacing: 12) {
                    // Neural Brain Icon with Pulse
                    ZStack {
                        Circle()
                            .fill(FuturisticTheme.Gradients.neuralPrimary)
                            .frame(width: 40, height: 40)
                            .scaleEffect(aiPulse ? 1.1 : 1.0)
                            .animation(FuturisticTheme.Animation.pulse, value: aiPulse)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Active indicator
                        Circle()
                            .fill(FuturisticTheme.Colors.success)
                            .frame(width: 8, height: 8)
                            .offset(x: 15, y: -15)
                            .opacity(aiPulse ? 1.0 : 0.7)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("MyTradeMate")
                                .font(FuturisticTheme.Typography.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            // AI Badge
                            Text("AI")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(FuturisticTheme.Gradients.neuralSecondary)
                                )
                        }
                        
                        Text("Neural Trading Platform")
                            .font(FuturisticTheme.Typography.small)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Right Controls
                HStack(spacing: 16) {
                    // Notifications
                    Button(action: { showNotifications.toggle() }) {
                        ZStack {
                            Circle()
                                .fill(FuturisticTheme.Colors.glassDark)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            if notifications > 0 {
                                Text("\(notifications)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(
                                        Circle()
                                            .fill(FuturisticTheme.Colors.danger)
                                    )
                                    .offset(x: 12, y: -12)
                            }
                        }
                    }
                    
                    // Dark Mode Toggle
                    Button(action: { themeManager.toggleTheme() }) {
                        Circle()
                            .fill(FuturisticTheme.Colors.glassDark)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .overlay(
                                Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // User Avatar
                    Circle()
                        .fill(FuturisticTheme.Gradients.neuralPrimary)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                // Glassmorphism background
                Rectangle()
                    .fill(FuturisticTheme.Colors.glassDark)
                    .background(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            
            // AI Status Bar
            AIStatusBar()
        }
        .onAppear {
            aiPulse = true
        }
    }
}

struct AIStatusBar: View {
    @StateObject private var aiManager = AIModelManager.shared
    @State private var processingAnimation = false
    @State private var autoTradeEnabled = true
    
    var body: some View {
        HStack(spacing: 20) {
            // AI Systems Status
            HStack(spacing: 8) {
                Circle()
                    .fill(FuturisticTheme.Colors.success)
                    .frame(width: 8, height: 8)
                    .scaleEffect(processingAnimation ? 1.2 : 1.0)
                    .animation(FuturisticTheme.Animation.pulse, value: processingAnimation)
                
                Text("AI Systems:")
                    .font(FuturisticTheme.Typography.small)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Online")
                    .font(FuturisticTheme.Typography.small)
                    .fontWeight(.bold)
                    .foregroundColor(FuturisticTheme.Colors.success)
            }
            
            // Neural Processing
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.system(size: 12))
                    .foregroundColor(FuturisticTheme.Colors.neuralBlue)
                
                Text("Neural Processing:")
                    .font(FuturisticTheme.Typography.small)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("94.2%")
                    .font(FuturisticTheme.Typography.small)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Processing Speed
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12))
                    .foregroundColor(FuturisticTheme.Colors.warning)
                
                Text("Speed:")
                    .font(FuturisticTheme.Typography.small)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("0.003ms")
                    .font(FuturisticTheme.Typography.small)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Auto Trade Toggle
            HStack(spacing: 8) {
                Text("Auto Trade")
                    .font(FuturisticTheme.Typography.small)
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: { 
                    withAnimation(FuturisticTheme.Animation.spring) {
                        autoTradeEnabled.toggle()
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(autoTradeEnabled ? FuturisticTheme.Colors.success : Color.gray.opacity(0.5))
                            .frame(width: 48, height: 24)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .offset(x: autoTradeEnabled ? 12 : -12)
                            .animation(FuturisticTheme.Animation.spring, value: autoTradeEnabled)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(FuturisticTheme.Colors.backgroundCard.opacity(0.3))
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            processingAnimation = true
        }
    }
}

#Preview {
    ZStack {
        FuturisticTheme.Colors.backgroundPrimary
            .ignoresSafeArea()
        
        VStack {
            NeuralHeaderView()
            Spacer()
        }
    }
}