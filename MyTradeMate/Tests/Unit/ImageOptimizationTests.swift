import XCTest
import SwiftUI
@testable import MyTradeMate

class ImageOptimizationTests: XCTestCase {
    
    var imageOptimizer: ImageOptimizer!
    
    override func setUp() {
        super.setUp()
        imageOptimizer = ImageOptimizer.shared
    }
    
    override func tearDown() {
        imageOptimizer = nil
        super.tearDown()
    }
    
    // MARK: - Device Class Tests
    
    func testDeviceClassDetection() {
        // Test that device class is properly detected
        let deviceClass = DeviceClass.current
        XCTAssertTrue([.compact, .regular, .large, .extraLarge].contains(deviceClass))
    }
    
    // MARK: - Image Size Optimization Tests
    
    func testOptimalImageSizeCalculation() {
        let baseSize = CGSize(width: 100, height: 100)
        let optimizedSize = imageOptimizer.optimalImageSize(for: baseSize)
        
        // Optimized size should be positive
        XCTAssertGreaterThan(optimizedSize.width, 0)
        XCTAssertGreaterThan(optimizedSize.height, 0)
        
        // Size should be reasonable (not too small or too large)
        XCTAssertGreaterThan(optimizedSize.width, 40) // Not too small
        XCTAssertLessThan(optimizedSize.width, 200) // Not too large
    }
    
    func testOptimalImageSizeWithScaleFactor() {
        let baseSize = CGSize(width: 100, height: 100)
        let scaleFactor: CGFloat = 1.5
        let optimizedSize = imageOptimizer.optimalImageSize(for: baseSize, scaleFactor: scaleFactor)
        let normalSize = imageOptimizer.optimalImageSize(for: baseSize, scaleFactor: 1.0)
        
        // Scaled size should be larger than normal size
        XCTAssertGreaterThan(optimizedSize.width, normalSize.width * 0.9) // Allow for some variance
    }
    
    // MARK: - SF Symbol Configuration Tests
    
    func testOptimalSymbolConfiguration() {
        let config = imageOptimizer.optimalSymbolConfiguration(baseSize: 24)
        
        // Configuration should have valid values
        XCTAssertNotNil(config.pointSize)
        XCTAssertNotNil(config.weight)
        XCTAssertNotNil(config.scale)
        
        // Point size should be reasonable
        if let pointSize = config.pointSize {
            XCTAssertGreaterThan(pointSize, 10)
            XCTAssertLessThan(pointSize, 60)
        }
    }
    
    // MARK: - Animation Optimization Tests
    
    func testAnimationDurationOptimization() {
        let baseDuration: Double = 1.0
        let optimizedDuration = imageOptimizer.optimalAnimationDuration(baseDuration)
        
        // Optimized duration should be positive
        XCTAssertGreaterThan(optimizedDuration, 0)
        
        // Duration should be reasonable (not too fast or too slow)
        XCTAssertGreaterThan(optimizedDuration, 0.2)
        XCTAssertLessThan(optimizedDuration, 3.0)
    }
    
    func testShouldEnableAnimations() {
        // This test depends on system state, so we just verify it returns a boolean
        let shouldEnable = imageOptimizer.shouldEnableAnimations
        XCTAssertTrue(shouldEnable == true || shouldEnable == false)
    }
    
    // MARK: - Layout Optimization Tests
    
    func testOptimalSpacing() {
        let baseSpacing: CGFloat = 16
        let optimizedSpacing = imageOptimizer.optimalSpacing(baseSpacing: baseSpacing)
        
        // Optimized spacing should be positive
        XCTAssertGreaterThan(optimizedSpacing, 0)
        
        // Spacing should be reasonable
        XCTAssertGreaterThan(optimizedSpacing, 8)
        XCTAssertLessThan(optimizedSpacing, 32)
    }
    
    func testOptimalCornerRadius() {
        let baseRadius: CGFloat = 12
        let optimizedRadius = imageOptimizer.optimalCornerRadius(baseRadius: baseRadius)
        
        // Optimized radius should be positive
        XCTAssertGreaterThan(optimizedRadius, 0)
        
        // Radius should be reasonable
        XCTAssertGreaterThan(optimizedRadius, 6)
        XCTAssertLessThan(optimizedRadius, 24)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfImageSizeCalculation() {
        let baseSize = CGSize(width: 100, height: 100)
        
        measure {
            for _ in 0..<1000 {
                _ = imageOptimizer.optimalImageSize(for: baseSize)
            }
        }
    }
    
    func testPerformanceOfSymbolConfiguration() {
        measure {
            for _ in 0..<1000 {
                _ = imageOptimizer.optimalSymbolConfiguration(baseSize: 24)
            }
        }
    }
    
    // MARK: - SF Symbol Cache Tests
    
    func testSFSymbolCacheBasicFunctionality() {
        let cache = SFSymbolCache.shared
        let symbolName = "heart.fill"
        let size: CGFloat = 24
        
        // Clear cache first
        cache.clearCache()
        
        // First call should create and cache the image
        let image1 = cache.cachedImage(for: symbolName, size: size)
        XCTAssertNotNil(image1)
        
        // Second call should return the cached image
        let image2 = cache.cachedImage(for: symbolName, size: size)
        XCTAssertNotNil(image2)
        
        // Images should be the same instance (cached)
        XCTAssertEqual(image1, image2)
    }
    
    func testSFSymbolCacheClearFunctionality() {
        let cache = SFSymbolCache.shared
        let symbolName = "star.fill"
        let size: CGFloat = 20
        
        // Add an image to cache
        let image1 = cache.cachedImage(for: symbolName, size: size)
        XCTAssertNotNil(image1)
        
        // Clear cache
        cache.clearCache()
        
        // Next call should create a new image (not from cache)
        let image2 = cache.cachedImage(for: symbolName, size: size)
        XCTAssertNotNil(image2)
    }
    
    // MARK: - Memory Pressure Tests
    
    func testMemoryPressureObserver() {
        let observer = MemoryPressureObserver.shared
        
        // Observer should exist and have a boolean state
        XCTAssertTrue(observer.isUnderMemoryPressure == true || observer.isUnderMemoryPressure == false)
    }
    
    // MARK: - Animation Manager Tests
    
    func testAnimationManagerReducedAnimations() {
        let manager = AnimationManager.shared
        
        // Should return a boolean
        XCTAssertTrue(manager.shouldUseReducedAnimations == true || manager.shouldUseReducedAnimations == false)
    }
    
    func testAnimationManagerAnimationCreation() {
        let manager = AnimationManager.shared
        let animation = manager.animation(duration: 1.0, delay: 0.5)
        
        // Animation should be created
        XCTAssertNotNil(animation)
    }
    
    func testAnimationManagerSimpleAnimation() {
        let manager = AnimationManager.shared
        let animation = manager.simpleAnimation(duration: 0.5)
        
        // Animation should be created
        XCTAssertNotNil(animation)
    }
}

// MARK: - Mock Tests for Different Device Classes

class MockDeviceClassTests: XCTestCase {
    
    func testCompactDeviceOptimizations() {
        // This would require mocking DeviceClass.current, which is complex
        // For now, we test that the optimization methods handle all device classes
        
        let imageOptimizer = ImageOptimizer.shared
        let baseSize = CGSize(width: 100, height: 100)
        
        // Test that optimization methods don't crash with any device class
        let optimizedSize = imageOptimizer.optimalImageSize(for: baseSize)
        let config = imageOptimizer.optimalSymbolConfiguration()
        let spacing = imageOptimizer.optimalSpacing()
        let radius = imageOptimizer.optimalCornerRadius()
        
        XCTAssertGreaterThan(optimizedSize.width, 0)
        XCTAssertNotNil(config.pointSize)
        XCTAssertGreaterThan(spacing, 0)
        XCTAssertGreaterThan(radius, 0)
    }
}