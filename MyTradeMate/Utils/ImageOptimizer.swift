import SwiftUI
import UIKit

/// Comprehensive image optimization utility for different screen sizes and device capabilities
class ImageOptimizer {
    static let shared = ImageOptimizer()
    
    private init() {}
    
    // MARK: - Screen Size Detection
    
    /// Determines the optimal image size based on screen characteristics
    func optimalImageSize(for baseSize: CGSize, scaleFactor: CGFloat = 1.0) -> CGSize {
        let deviceClass = DeviceClass.current
        let screenScale = UIScreen.main.scale
        let memoryPressure = MemoryPressureObserver.shared.isUnderMemoryPressure
        
        var multiplier: CGFloat
        
        switch deviceClass {
        case .compact:
            multiplier = memoryPressure ? 0.6 : 0.8
        case .regular:
            multiplier = memoryPressure ? 0.8 : 1.0
        case .large:
            multiplier = memoryPressure ? 1.0 : 1.2
        case .extraLarge:
            multiplier = memoryPressure ? 1.2 : 1.6
        }
        
        // Adjust for screen scale to prevent over-rendering
        let scaleAdjustment = min(screenScale, 2.0) / 2.0
        multiplier *= scaleAdjustment * scaleFactor
        
        return CGSize(
            width: baseSize.width * multiplier,
            height: baseSize.height * multiplier
        )
    }
    
    // MARK: - SF Symbol Optimization
    
    /// Returns optimal SF Symbol configuration for current device
    func optimalSymbolConfiguration(baseSize: CGFloat = 24) -> UIImage.SymbolConfiguration {
        let deviceClass = DeviceClass.current
        let memoryPressure = MemoryPressureObserver.shared.isUnderMemoryPressure
        
        let size: CGFloat
        let weight: UIImage.SymbolWeight
        let scale: UIImage.SymbolScale
        
        switch deviceClass {
        case .compact:
            size = memoryPressure ? baseSize * 0.7 : baseSize * 0.8
            weight = .medium
            scale = .small
        case .regular:
            size = memoryPressure ? baseSize * 0.8 : baseSize
            weight = .medium
            scale = .medium
        case .large:
            size = memoryPressure ? baseSize : baseSize * 1.2
            weight = .medium
            scale = .medium
        case .extraLarge:
            size = memoryPressure ? baseSize * 1.2 : baseSize * 1.5
            weight = .semibold
            scale = .large
        }
        
        return UIImage.SymbolConfiguration(pointSize: size, weight: weight, scale: scale)
    }
    
    // MARK: - Animation Optimization
    
    /// Determines if animations should be enabled based on device capabilities
    var shouldEnableAnimations: Bool {
        !AnimationManager.shared.shouldUseReducedAnimations &&
        !MemoryPressureObserver.shared.isUnderMemoryPressure &&
        ProcessInfo.processInfo.thermalState != .critical
    }
    
    /// Returns optimal animation duration based on device performance
    func optimalAnimationDuration(_ baseDuration: Double) -> Double {
        let deviceClass = DeviceClass.current
        let memoryPressure = MemoryPressureObserver.shared.isUnderMemoryPressure
        
        var multiplier: Double = 1.0
        
        switch deviceClass {
        case .compact:
            multiplier = memoryPressure ? 0.5 : 0.7
        case .regular:
            multiplier = memoryPressure ? 0.7 : 1.0
        case .large:
            multiplier = memoryPressure ? 0.8 : 1.0
        case .extraLarge:
            multiplier = memoryPressure ? 1.0 : 1.2
        }
        
        return baseDuration * multiplier
    }
    
    // MARK: - Layout Optimization
    
    /// Returns optimal spacing for current device
    func optimalSpacing(baseSpacing: CGFloat = 16) -> CGFloat {
        let deviceClass = DeviceClass.current
        
        switch deviceClass {
        case .compact:
            return baseSpacing * 0.75
        case .regular:
            return baseSpacing
        case .large:
            return baseSpacing * 1.25
        case .extraLarge:
            return baseSpacing * 1.5
        }
    }
    
    /// Returns optimal corner radius for current device
    func optimalCornerRadius(baseRadius: CGFloat = 12) -> CGFloat {
        let deviceClass = DeviceClass.current
        
        switch deviceClass {
        case .compact:
            return baseRadius * 0.8
        case .regular:
            return baseRadius
        case .large:
            return baseRadius * 1.1
        case .extraLarge:
            return baseRadius * 1.3
        }
    }
    
    // MARK: - Performance Monitoring
    
    /// Monitors and logs performance metrics for optimization
    func logPerformanceMetrics(for operation: String, duration: TimeInterval) {
        #if DEBUG
        if duration > 0.016 { // More than one frame at 60fps
            print("⚠️ ImageOptimizer: \(operation) took \(String(format: "%.3f", duration))s (may cause frame drops)")
        }
        #endif
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Applies optimal corner radius based on device class
    func optimalCornerRadius(_ baseRadius: CGFloat = 12) -> some View {
        self.cornerRadius(ImageOptimizer.shared.optimalCornerRadius(baseRadius: baseRadius))
    }
    
    /// Applies optimal padding based on device class
    func optimalPadding(_ basePadding: CGFloat = 16) -> some View {
        self.padding(ImageOptimizer.shared.optimalSpacing(baseSpacing: basePadding))
    }
    
    /// Conditionally applies animations based on device performance
    func performanceOptimizedAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        if ImageOptimizer.shared.shouldEnableAnimations {
            return self.animation(animation, value: value)
        } else {
            return self.animation(nil, value: value)
        }
    }
}

// MARK: - Image Extensions

extension Image {
    /// Creates a performance-optimized SF Symbol
    static func optimizedSymbol(
        _ name: String,
        baseSize: CGFloat = 24
    ) -> some View {
        let config = ImageOptimizer.shared.optimalSymbolConfiguration(baseSize: baseSize)
        
        if let cachedImage = SFSymbolCache.shared.cachedImage(
            for: name,
            size: baseSize,
            weight: .medium
        ) {
            return AnyView(Image(uiImage: cachedImage)
                .symbolRenderingMode(.hierarchical))
        } else {
            return AnyView(Image(systemName: name)
                .font(.system(size: baseSize, weight: .medium))
                .symbolRenderingMode(.hierarchical))
        }
    }
}

// MARK: - Font Weight Extension

extension Font.Weight {
    init(_ symbolWeight: UIImage.SymbolWeight) {
        switch symbolWeight {
        case .ultraLight: self = .ultraLight
        case .thin: self = .thin
        case .light: self = .light
        case .regular: self = .regular
        case .medium: self = .medium
        case .semibold: self = .semibold
        case .bold: self = .bold
        case .heavy: self = .heavy
        case .black: self = .black
        default: self = .medium
        }
    }
}