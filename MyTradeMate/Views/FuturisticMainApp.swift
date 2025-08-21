import SwiftUI

struct FuturisticMainApp: View {
    @State private var selectedTab = 0
    @State private var aiPulse = false
    @State private var showNotifications = false
    @State private var notifications = 3
    @State private var autoTradeEnabled = true
    
    // Environment objects
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    @EnvironmentObject var strategiesVM: RefactoredStrategiesVM
    @EnvironmentObject var tradesVM: TradesVM
    @EnvironmentObject var pnlVM: PnLVM
    @EnvironmentObject var settingsVM: SettingsVM
    @EnvironmentObject var themeManager: ThemeManager
    
    let tabs = [
        (icon: "house.fill", title: "Dashboard", id: 0),
        (icon: "chart.line.uptrend.xyaxis", title: "Trading", id: 1),
        (icon: "brain.head.profile", title: "AI Bots", id: 2),
        (icon: "chart.bar.fill", title: "Analytics", id: 3),
        (icon: "gearshape.fill", title: "Settings", id: 4)
    ]
    
    var body: some View {
        ZStack {
            // Neural Background
            NeuralBackgroundView()
            
            VStack(spacing: 0) {
                // Futuristic Header
                FuturisticHeaderView()
                
                // Content Area
                ZStack {
                    switch selectedTab {
                    case 0:
                        FuturisticDashboardContent()
                    case 1:
                        FuturisticTradingContent()
                    case 2:
                        FuturisticBotsContent()
                    case 3:
                        FuturisticAnalyticsContent()
                    case 4:
                        FuturisticSettingsContent()
                    default:
                        FuturisticDashboardContent()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
            }
            
            // Floating Neural Tab Bar
            VStack {
                Spacer()
                FuturisticTabBarView(selectedTab: $selectedTab, tabs: tabs)
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark) // Force dark mode for neural theme
    }
}

// MARK: - Neural Background with Animated Particles
struct NeuralBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Deep space gradient
            LinearGradient(
                colors: [
                    Color(red: 15/255, green: 23/255, blue: 42/255),
                    Color(red: 30/255, green: 41/255, blue: 59/255),
                    Color(red: 15/255, green: 23/255, blue: 42/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated neural particles
            ForEach(0..<25, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 59/255, green: 130/255, blue: 246/255).opacity(0.4),
                                Color(red: 147/255, green: 51/255, blue: 234/255).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: CGFloat.random(in: 60...120), height: CGFloat.random(in: 60...120))
                    .position(
                        x: animate ? CGFloat.random(in: 50...UIScreen.main.bounds.width-50) : CGFloat.random(in: 50...UIScreen.main.bounds.width-50),
                        y: animate ? CGFloat.random(in: 100...UIScreen.main.bounds.height-100) : CGFloat.random(in: 100...UIScreen.main.bounds.height-100)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 4...8))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: animate
                    )
            }
            
            // Neural network connection lines
            Canvas { context, size in
                for _ in 0..<15 {
                    let startX = CGFloat.random(in: 0...size.width)
                    let startY = CGFloat.random(in: 0...size.height)
                    let endX = CGFloat.random(in: 0...size.width)
                    let endY = CGFloat.random(in: 0...size.height)
                    
                    var path = Path()
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                    
                    context.stroke(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color(red: 59/255, green: 130/255, blue: 246/255).opacity(0.1),
                                Color.clear,
                                Color(red: 147/255, green: 51/255, blue: 234/255).opacity(0.1)
                            ]),
                            startPoint: CGPoint(x: startX, y: startY),
                            endPoint: CGPoint(x: endX, y: endY)
                        ),
                        lineWidth: 1
                    )
                }
            }
            .opacity(animate ? 0.6 : 0.3)
            .animation(
                Animation.easeInOut(duration: 6)
                    .repeatForever(autoreverses: true),
                value: animate
            )
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Futuristic Header
struct FuturisticHeaderView: View {
    @State private var aiPulse = false
    @State private var notifications = 3
    @State private var autoTradeEnabled = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Header
            HStack {
                // Neural Logo
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 59/255, green: 130/255, blue: 246/255),
                                        Color(red: 147/255, green: 51/255, blue: 234/255)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .scaleEffect(aiPulse ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: aiPulse
                            )
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Active AI indicator
                        Circle()
                            .fill(Color(red: 34/255, green: 197/255, blue: 94/255))
                            .frame(width: 8, height: 8)
                            .offset(x: 15, y: -15)
                            .opacity(aiPulse ? 1.0 : 0.7)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("MyTradeMate")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("AI")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 6/255, green: 182/255, blue: 212/255),
                                                    Color(red: 59/255, green: 130/255, blue: 246/255)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                        
                        Text("Neural Trading Platform")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Header Controls
                HStack(spacing: 16) {
                    // Notifications
                    Button(action: {}) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .background(.ultraThinMaterial)
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
                                            .fill(Color(red: 239/255, green: 68/255, blue: 68/255))
                                    )
                                    .offset(x: 12, y: -12)
                            }
                        }
                    }
                    
                    // User Avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 59/255, green: 130/255, blue: 246/255),
                                    Color(red: 147/255, green: 51/255, blue: 234/255)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // AI Status Bar
            HStack(spacing: 20) {
                // AI Systems Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(red: 34/255, green: 197/255, blue: 94/255))
                        .frame(width: 8, height: 8)
                        .scaleEffect(aiPulse ? 1.3 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: aiPulse
                        )
                    
                    Text("AI Systems:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Online")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 34/255, green: 197/255, blue: 94/255))
                }
                
                // Neural Processing
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255))
                    
                    Text("Neural: 94.2%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Processing Speed
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 245/255, green: 158/255, blue: 11/255))
                    
                    Text("0.003ms")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Auto Trade Toggle
                HStack(spacing: 8) {
                    Text("Auto Trade")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button(action: { 
                        withAnimation(.spring()) {
                            autoTradeEnabled.toggle()
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(autoTradeEnabled ? Color(red: 34/255, green: 197/255, blue: 94/255) : Color.gray.opacity(0.5))
                                .frame(width: 48, height: 24)
                            
                            Circle()
                                .fill(.white)
                                .frame(width: 20, height: 20)
                                .offset(x: autoTradeEnabled ? 12 : -12)
                                .animation(.spring(), value: autoTradeEnabled)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .background(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .background(.ultraThinMaterial)
        )
        .onAppear {
            aiPulse = true
        }
    }
}

// MARK: - Futuristic Tab Bar
struct FuturisticTabBarView: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, title: String, id: Int)]
    @State private var tabAnimation = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.id) { tab in
                FuturisticTabItem(
                    icon: tab.icon,
                    title: tab.title,
                    isSelected: selectedTab == tab.id
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        selectedTab = tab.id
                        tabAnimation.toggle()
                    }
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.4))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
    }
}

struct FuturisticTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 59/255, green: 130/255, blue: 246/255),
                                    Color(red: 147/255, green: 51/255, blue: 234/255)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(
                            color: Color(red: 59/255, green: 130/255, blue: 246/255).opacity(0.5),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                        .scaleEffect(iconScale)
                        .animation(.spring(), value: isSelected)
                }
                
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 20 : 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .scaleEffect(iconScale)
                    .animation(.spring(), value: isSelected)
            }
            
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .animation(.easeInOut(duration: 0.3), value: isSelected)
        }
        .onChange(of: isSelected) { newValue in
            if newValue {
                withAnimation(.spring()) {
                    iconScale = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring()) {
                        iconScale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Content Views (Placeholder implementations using existing views)
struct FuturisticDashboardContent: View {
    @EnvironmentObject var dashboardVM: RefactoredDashboardVM
    
    var body: some View {
        DashboardView()
            .environmentObject(dashboardVM)
    }
}

struct FuturisticTradingContent: View {
    @EnvironmentObject var tradesVM: TradesVM
    
    var body: some View {
        TradesView()
            .environmentObject(tradesVM)
    }
}

struct FuturisticBotsContent: View {
    @EnvironmentObject var strategiesVM: RefactoredStrategiesVM
    
    var body: some View {
        StrategiesView()
            .environmentObject(strategiesVM)
    }
}

struct FuturisticAnalyticsContent: View {
    @EnvironmentObject var pnlVM: PnLVM
    
    var body: some View {
        PnLDetailView()
            .environmentObject(pnlVM)
    }
}

struct FuturisticSettingsContent: View {
    @EnvironmentObject var settingsVM: SettingsVM
    
    var body: some View {
        SettingsView()
            .environmentObject(settingsVM)
    }
}

#Preview {
    FuturisticMainApp()
}