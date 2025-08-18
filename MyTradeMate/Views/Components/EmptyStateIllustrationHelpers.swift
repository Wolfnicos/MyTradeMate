import SwiftUI

// MARK: - Screen Size Optimization

/// Device class detection for better screen size optimization
enum DeviceClass {
    case compact    // iPhone SE, iPhone mini
    case regular    // iPhone standard
    case large      // iPhone Plus, Pro Max
    case extraLarge // iPad
    
    static var current: DeviceClass {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let maxDimension = max(screenWidth, screenHeight)
        
        // iPad detection
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .extraLarge
        }
        
        // iPhone size detection based on screen width
        switch screenWidth {
        case 0..<375:
            return .compact
        case 375..<414:
            return .regular
        case 414..<430:
            return .large
        default:
            return maxDimension > 900 ? .extraLarge : .large
        }
    }
}

extension IllustratedEmptyStateView {
    /// Returns the appropriate illustration size based on device class and screen size
    var optimizedIllustrationSize: CGSize {
        switch DeviceClass.current {
        case .compact:
            return CGSize(width: 80, height: 80)
        case .regular:
            return CGSize(width: 100, height: 100)
        case .large:
            return CGSize(width: 120, height: 120)
        case .extraLarge:
            return CGSize(width: 160, height: 160)
        }
    }
    
    /// Returns optimized spacing based on device class
    var optimizedSpacing: CGFloat {
        switch DeviceClass.current {
        case .compact:
            return 12
        case .regular:
            return 16
        case .large:
            return 24
        case .extraLarge:
            return 32
        }
    }
    
    /// Returns optimized font sizes for different screen sizes
    var optimizedTitleFont: Font {
        switch DeviceClass.current {
        case .compact:
            return .title3.weight(.semibold)
        case .regular:
            return .title2.weight(.semibold)
        case .large:
            return .title2.weight(.semibold)
        case .extraLarge:
            return .title.weight(.semibold)
        }
    }
    
    var optimizedDescriptionFont: Font {
        switch DeviceClass.current {
        case .compact:
            return .callout
        case .regular:
            return .body
        case .large:
            return .body
        case .extraLarge:
            return .title3
        }
    }
}

// MARK: - Dark Mode Support

extension Color {
    /// Colors that adapt properly to dark/light mode for empty state illustrations
    static let emptyStateBlue = Color(light: Color(hex: "007AFF"), dark: Color(hex: "0A84FF"))
    static let emptyStateGreen = Color(light: Color(hex: "34C759"), dark: Color(hex: "30D158"))
    static let emptyStateOrange = Color(light: Color(hex: "FF9500"), dark: Color(hex: "FF9F0A"))
    static let emptyStatePurple = Color(light: Color(hex: "AF52DE"), dark: Color(hex: "BF5AF2"))
    static let emptyStateCyan = Color(light: Color(hex: "32ADE6"), dark: Color(hex: "40C8E0"))
    static let emptyStateRed = Color(light: Color(hex: "FF3B30"), dark: Color(hex: "FF453A"))
    
    /// Background colors for illustrations that work in both modes with proper contrast
    static let emptyStateBackgroundBlue = Color(light: Color(hex: "007AFF").opacity(0.08), dark: Color(hex: "0A84FF").opacity(0.15))
    static let emptyStateBackgroundGreen = Color(light: Color(hex: "34C759").opacity(0.08), dark: Color(hex: "30D158").opacity(0.15))
    static let emptyStateBackgroundOrange = Color(light: Color(hex: "FF9500").opacity(0.08), dark: Color(hex: "FF9F0A").opacity(0.15))
    static let emptyStateBackgroundPurple = Color(light: Color(hex: "AF52DE").opacity(0.08), dark: Color(hex: "BF5AF2").opacity(0.15))
    static let emptyStateBackgroundCyan = Color(light: Color(hex: "32ADE6").opacity(0.08), dark: Color(hex: "40C8E0").opacity(0.15))
    static let emptyStateBackgroundRed = Color(light: Color(hex: "FF3B30").opacity(0.08), dark: Color(hex: "FF453A").opacity(0.15))
    
    /// Neutral colors for empty state elements
    static let emptyStateNeutral = Color(light: Color(hex: "8E8E93"), dark: Color(hex: "98989D"))
    static let emptyStateNeutralBackground = Color(light: Color(hex: "F2F2F7"), dark: Color(hex: "1C1C1E"))
    
    // Using Color(light:dark:) from DesignSystem
    
    // Using Color(hex:) from DesignSystem
}

// MARK: - Performance Optimized Illustrations

/// A performance-optimized version of the chart illustration
struct OptimizedChartEmptyIllustration: View {
    @State private var animateChart = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background circle with proper dark mode support
            Circle()
                .fill(Color.emptyStateBackgroundBlue)
                .frame(width: 120, height: 120)
            
            // Simplified chart representation for better performance
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(0..<6, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.emptyStateBlue.opacity(0.7))
                            .frame(width: 3, height: chartBarHeight(for: index))
                            .scaleEffect(y: animateChart ? 1.1 : 0.9)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                                value: animateChart
                            )
                    }
                }
                
                // X-axis line
                Rectangle()
                    .fill(Color.secondary.opacity(colorScheme == .dark ? 0.4 : 0.3))
                    .frame(width: 30, height: 1)
            }
        }
        .onAppear {
            withAnimation {
                animateChart = true
            }
        }
        .onDisappear {
            animateChart = false
        }
    }
    
    private func chartBarHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [12, 18, 8, 22, 15, 10]
        return heights[index % heights.count]
    }
}

// MARK: - Accessibility Improvements

extension IllustratedEmptyStateView {
    /// Enhanced accessibility version with better labels and hints
    func withAccessibility() -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
            .accessibilityAddTraits(.isStaticText)
    }
    
    private var accessibilityLabel: String {
        switch illustration {
        case .chartNoData:
            return "Chart empty state. \(title). \(description)"
        case .pnlNoData:
            return "Profit and loss empty state. \(title). \(description)"
        case .tradesNoData:
            return "Trades list empty state. \(title). \(description)"
        case .strategiesNoData:
            return "Strategies empty state. \(title). \(description)"
        case .aiSignalNoData:
            return "AI signal empty state. \(title). \(description)"
        }
    }
    
    private var accessibilityHint: String {
        if actionButton != nil {
            return "Double tap to take action"
        } else {
            return "This area will show content when available"
        }
    }
}

// MARK: - Animation Performance Helpers

/// A helper struct to manage animation performance
struct AnimationManager {
    static let shared = AnimationManager()
    
    private init() {}
    
    /// Reduces animations on low-power mode or older devices
    var shouldUseReducedAnimations: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled ||
        UIAccessibility.isReduceMotionEnabled ||
        isLowPerformanceDevice
    }
    
    /// Detects if the device has limited performance capabilities
    private var isLowPerformanceDevice: Bool {
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        // Check for older devices or iOS versions
        if let majorVersion = Int(systemVersion.components(separatedBy: ".").first ?? "0") {
            return majorVersion < 15 // iOS versions older than 15
        }
        
        return false
    }
    
    /// Returns an appropriate animation based on system preferences and device capabilities
    func animation(duration: Double, delay: Double = 0) -> Animation {
        if shouldUseReducedAnimations {
            return .easeInOut(duration: duration * 0.5).delay(delay)
        } else {
            return .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
                .delay(delay)
        }
    }
    
    /// Returns a simple animation for reduced motion scenarios
    func simpleAnimation(duration: Double = 0.3) -> Animation {
        if shouldUseReducedAnimations {
            return .easeInOut(duration: duration * 0.5)
        } else {
            return .easeInOut(duration: duration)
        }
    }
    
    /// Returns a subtle breathing animation for backgrounds
    func subtleBreathingAnimation(duration: Double = 4.0) -> Animation {
        if shouldUseReducedAnimations {
            return .easeInOut(duration: duration * 0.3)
        } else {
            return .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
        }
    }
    
    /// Returns a gentle floating animation
    func floatingAnimation(duration: Double = 3.0, delay: Double = 0) -> Animation {
        if shouldUseReducedAnimations {
            return .easeInOut(duration: duration * 0.4).delay(delay)
        } else {
            return .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
                .delay(delay)
        }
    }
    
    /// Returns a subtle shimmer animation
    func shimmerAnimation(duration: Double = 2.0, delay: Double = 0) -> Animation {
        if shouldUseReducedAnimations {
            return .linear(duration: duration * 0.5).delay(delay)
        } else {
            return .linear(duration: duration)
                .repeatForever(autoreverses: false)
                .delay(delay)
        }
    }
    
    /// Returns a gentle rotation animation
    func gentleRotationAnimation(duration: Double = 8.0, delay: Double = 0) -> Animation {
        if shouldUseReducedAnimations {
            return .linear(duration: duration * 0.3).delay(delay)
        } else {
            return .linear(duration: duration)
                .repeatForever(autoreverses: false)
                .delay(delay)
        }
    }
}

// MARK: - Memory Management

/// Memory pressure observer for optimizing illustrations
class MemoryPressureObserver: ObservableObject {
    static let shared = MemoryPressureObserver()
    @Published var isUnderMemoryPressure = false
    
    private let source: DispatchSourceMemoryPressure
    
    private init() {
        source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: .main)
        
        source.setEventHandler { [weak self] in
            let event = self?.source.mask
            self?.isUnderMemoryPressure = event?.contains(.critical) == true || event?.contains(.warning) == true
            
            // Clear caches when under memory pressure
            if self?.isUnderMemoryPressure == true {
                SFSymbolCache.shared.clearCache()
            }
        }
        
        source.resume()
    }
    
    deinit {
        source.cancel()
    }
}

// MARK: - Image Optimization

/// Optimized SF Symbol cache for better performance
class SFSymbolCache {
    static let shared = SFSymbolCache()
    private var cache: [String: UIImage] = [:]
    private let queue = DispatchQueue(label: "sf-symbol-cache", qos: .utility)
    
    private init() {}
    
    func cachedImage(for symbolName: String, size: CGFloat, weight: UIImage.SymbolWeight = .medium) -> UIImage? {
        let key = "\(symbolName)-\(size)-\(weight.rawValue)"
        
        return queue.sync {
            if let cachedImage = cache[key] {
                return cachedImage
            }
            
            let config = UIImage.SymbolConfiguration(pointSize: size, weight: weight, scale: .default)
            let image = UIImage(systemName: symbolName, withConfiguration: config)
            
            if let image = image {
                cache[key] = image
                
                // Limit cache size to prevent memory issues
                if cache.count > 50 {
                    let oldestKey = cache.keys.first
                    if let key = oldestKey {
                        cache.removeValue(forKey: key)
                    }
                }
            }
            
            return image
        }
    }
    
    func clearCache() {
        queue.async {
            self.cache.removeAll()
        }
    }
}

extension Image {
    /// Creates an optimized SF Symbol for empty states with caching
    static func emptyStateSymbol(_ name: String, size: CGFloat = 24, weight: UIImage.SymbolWeight = .medium) -> some View {
        Group {
            if let cachedImage = SFSymbolCache.shared.cachedImage(for: name, size: size, weight: weight) {
                Image(uiImage: cachedImage)
                    .symbolRenderingMode(.hierarchical)
            } else {
                Image(systemName: name)
                    .font(.system(size: size, weight: Font.Weight(weight), design: .rounded))
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }
    
    /// Creates a size-optimized SF Symbol based on device class
    static func adaptiveEmptyStateSymbol(_ name: String) -> some View {
        let size: CGFloat
        let weight: UIImage.SymbolWeight
        
        switch DeviceClass.current {
        case .compact:
            size = 20
            weight = .medium
        case .regular:
            size = 24
            weight = .medium
        case .large:
            size = 28
            weight = .medium
        case .extraLarge:
            size = 36
            weight = .semibold
        }
        
        return emptyStateSymbol(name, size: size, weight: weight)
    }
}

// Using Font.Weight extension from ImageOptimizer

// MARK: - Responsive Layout Helpers

// Using optimalPadding from ImageOptimizer

extension ImageOptimizer {
    /// Returns optimal spacing for empty state components based on device class
    static func optimalSpacing(baseSpacing: CGFloat) -> CGFloat {
        switch DeviceClass.current {
        case .compact:
            return baseSpacing * 0.8
        case .regular:
            return baseSpacing
        case .large:
            return baseSpacing * 1.2
        case .extraLarge:
            return baseSpacing * 1.5
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct EmptyStateIllustrationPreviews: View {
    @State private var colorScheme: ColorScheme = .light
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text("Empty State Illustrations - Dark Mode Test")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(colorScheme == .light ? "Switch to Dark" : "Switch to Light") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            colorScheme = colorScheme == .light ? .dark : .light
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                Text("Current mode: \(colorScheme == .light ? "Light" : "Dark")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(EmptyStateIllustration.allCases, id: \.self) { illustration in
                        VStack(spacing: 8) {
                            illustration.view
                                .frame(width: 120, height: 120)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            
                            Text(illustration.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Test with different background colors
                VStack(spacing: 16) {
                    Text("Background Color Tests")
                        .font(.headline)
                        .padding(.top)
                    
                    HStack(spacing: 16) {
                        ForEach([Color.clear, Color(.systemGray6), Color(.systemBackground)], id: \.self) { bgColor in
                            VStack {
                                EmptyStateIllustration.chartNoData.view
                                    .frame(width: 80, height: 80)
                                    .background(bgColor)
                                    .cornerRadius(8)
                                
                                Text(bgColor == .clear ? "Clear" : bgColor == Color(.systemGray6) ? "Gray6" : "Background")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .preferredColorScheme(colorScheme)
        .background(Color(.systemBackground))
    }
}

extension EmptyStateIllustration: CaseIterable {
    static var allCases: [EmptyStateIllustration] {
        [.chartNoData, .pnlNoData, .tradesNoData, .strategiesNoData, .aiSignalNoData]
    }
    
    var name: String {
        switch self {
        case .chartNoData: return "Chart"
        case .pnlNoData: return "P&L"
        case .tradesNoData: return "Trades"
        case .strategiesNoData: return "Strategies"
        case .aiSignalNoData: return "AI Signal"
        }
    }
}

#Preview("Dark Mode Test") {
    EmptyStateIllustrationPreviews()
}

#Preview("Light Mode") {
    EmptyStateIllustrationPreviews()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    EmptyStateIllustrationPreviews()
        .preferredColorScheme(.dark)
}
#endif