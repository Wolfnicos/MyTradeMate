# Performance Optimization System

This directory contains the comprehensive performance optimization system for MyTradeMate, designed to provide intelligent resource management, battery optimization, and responsive user experience across different device conditions.

## Overview

The performance optimization system consists of five main components that work together to provide intelligent resource management:

1. **PerformanceOptimizer** - Central coordinator that manages all optimization systems
2. **MemoryPressureManager** - Handles memory pressure events and cleanup
3. **InferenceThrottler** - Manages AI inference frequency for battery optimization
4. **ConnectionManager** - Intelligent WebSocket connection management
5. **DataCacheManager** - Efficient data caching with memory-aware eviction

## Components

### PerformanceOptimizer

The central coordinator that monitors system conditions and adjusts optimization levels automatically.

**Key Features:**
- Automatic optimization level adjustment based on battery, thermal state, and memory pressure
- Four optimization levels: Performance, Balanced, Battery, Aggressive
- Real-time performance metrics collection
- Manual optimization controls

**Usage:**
```swift
// Enable automatic optimization
PerformanceOptimizer.shared.enableOptimization(true)

// Set manual optimization level
PerformanceOptimizer.shared.setOptimizationLevel(.battery)

// Get detailed metrics
let metrics = PerformanceOptimizer.shared.getDetailedMetrics()
```

### MemoryPressureManager

Monitors system memory pressure and performs intelligent cleanup when needed.

**Key Features:**
- Real-time memory pressure monitoring
- Automatic cleanup on memory warnings
- Configurable cleanup strategies for different pressure levels
- Memory usage tracking and reporting

**Usage:**
```swift
// Get current memory usage
let usage = MemoryPressureManager.shared.getCurrentMemoryUsage()

// Request manual cleanup
MemoryPressureManager.shared.requestMemoryCleanup()

// Check if memory pressure is high
if MemoryPressureManager.shared.isMemoryPressureHigh() {
    // Reduce memory usage
}
```

### InferenceThrottler

Manages AI inference frequency to optimize battery life and performance.

**Key Features:**
- Five throttle levels: Realtime, Responsive, Normal, Conservative, Aggressive
- Adaptive throttling based on system conditions
- Inference rate monitoring and statistics
- Battery and thermal state awareness

**Usage:**
```swift
// Check if inference is allowed
if InferenceThrottler.shared.shouldAllowInference() {
    // Perform AI inference
    InferenceThrottler.shared.recordInference()
}

// Set manual throttle level
InferenceThrottler.shared.setThrottleLevel(.conservative)

// Get throttle status
let status = InferenceThrottler.shared.getThrottleStatus()
```

### ConnectionManager

Intelligent WebSocket connection management based on network conditions and app state.

**Key Features:**
- Network quality assessment (WiFi, Cellular, Ethernet)
- Connection priority management (Critical, High, Medium, Low)
- Automatic optimization for cellular networks
- Background/foreground state awareness
- Connection health monitoring

**Usage:**
```swift
// Register a connection with priority
ConnectionManager.shared.registerConnection("market_data", priority: .high)

// Check if connection is allowed
if ConnectionManager.shared.shouldAllowConnection("market_data") {
    // Establish connection
}

// Record connection activity
ConnectionManager.shared.recordConnectionActivity("market_data")
```

### DataCacheManager

Efficient data caching system with memory pressure awareness and intelligent eviction.

**Key Features:**
- Type-safe caching with generic support
- Memory pressure aware eviction
- Configurable cache sizes and TTL
- Cache statistics and monitoring
- Automatic cleanup of expired items

**Usage:**
```swift
// Get a typed cache
let cache = DataCacheManager.shared.getCache(for: "candles", type: [Candle].self)

// Store and retrieve data
cache.set("BTCUSDT-5m", value: candles)
let cachedCandles = cache.get("BTCUSDT-5m")

// Get cache statistics
let stats = DataCacheManager.shared.cacheStats
```

## Integration Guide

### For Service Classes

Services should integrate with the performance system to optimize their behavior:

```swift
@MainActor
final class MyService: ObservableObject {
    private init() {
        // Listen for optimization notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryPressure),
            name: .memoryPressureChanged,
            object: nil
        )
    }
    
    @objc private func handleMemoryPressure(_ notification: Notification) {
        guard let level = notification.userInfo?["level"] as? MemoryPressureManager.MemoryPressureLevel else { return }
        
        switch level {
        case .warning:
            // Reduce memory usage
            clearNonEssentialData()
        case .critical:
            // Aggressive cleanup
            clearAllNonEssentialData()
        case .normal:
            break
        }
    }
}
```

### For AI/ML Operations

AI operations should check throttling before performing inference:

```swift
func performInference() async -> PredictionResult {
    // Check if inference is allowed
    guard InferenceThrottler.shared.shouldAllowInference() else {
        return cachedOrDefaultPrediction()
    }
    
    // Record inference
    InferenceThrottler.shared.recordInference()
    
    // Perform actual inference
    let result = await actualInference()
    
    // Log performance
    Log.performance("AI inference completed")
    
    return result
}
```

### For WebSocket Connections

WebSocket connections should register with the connection manager:

```swift
final class MyWebSocketManager {
    private let connectionId = "my_websocket"
    
    init() {
        // Register with connection manager
        ConnectionManager.shared.registerConnection(connectionId, priority: .high)
        
        // Listen for optimization notifications
        setupOptimizationListeners()
    }
    
    func connect() async {
        // Check if connection is allowed
        guard ConnectionManager.shared.shouldAllowConnection(connectionId) else {
            return
        }
        
        // Establish connection
        await establishConnection()
        
        // Record activity
        ConnectionManager.shared.recordConnectionActivity(connectionId)
    }
}
```

### For Data Caching

Use the centralized cache manager for efficient data storage:

```swift
final class DataService {
    private lazy var cache = DataCacheManager.shared.getCache(for: "my_data", type: MyDataType.self)
    
    func getData(key: String) async -> MyDataType? {
        // Check cache first
        if let cached = cache.get(key) {
            return cached
        }
        
        // Fetch from network
        let data = await fetchFromNetwork(key)
        
        // Cache the result
        cache.set(key, value: data)
        
        return data
    }
}
```

## Monitoring and Debugging

### Performance Monitor View

The app includes a comprehensive performance monitoring view accessible through the debug menu:

- Real-time memory usage and pressure levels
- AI inference throttling status and statistics
- Network connection status and optimization
- Cache usage and statistics
- Manual optimization controls

### Logging

All performance operations are logged using the unified logging system:

```swift
// Performance logging
Log.performance("Operation completed", duration: 0.123)

// Memory pressure logging
Log.log("Memory pressure detected", category: .performance)

// Cache operations
Log.debug("Cache hit for key: \(key)", category: .data)
```

### Notifications

The system uses notifications to coordinate between components:

- `.memoryPressureChanged` - Memory pressure level changes
- `.pauseNonEssentialOperations` - Pause non-critical operations
- `.optimizeForCellular` - Optimize for cellular network
- `.optimizeForBackground` - Optimize for background mode

## Best Practices

### Memory Management

1. **Listen for memory pressure notifications** and respond appropriately
2. **Use weak references** in closures to prevent retain cycles
3. **Clear caches** when memory pressure is high
4. **Avoid large object allocations** during memory pressure

### Battery Optimization

1. **Check inference throttling** before AI operations
2. **Reduce background activity** when battery is low
3. **Use connection priorities** to maintain only essential connections
4. **Cache data efficiently** to reduce network requests

### Network Optimization

1. **Register connections** with appropriate priorities
2. **Handle cellular network optimization** by reducing update frequencies
3. **Implement connection health monitoring** with automatic reconnection
4. **Use intelligent buffering** to reduce connection overhead

### Cache Management

1. **Use appropriate cache sizes** based on data importance
2. **Set reasonable TTL values** to balance freshness and efficiency
3. **Monitor cache statistics** to optimize cache configuration
4. **Clear expired items** regularly to prevent memory bloat

## Testing

The performance optimization system includes comprehensive integration tests:

- Memory pressure handling
- Inference throttling behavior
- Connection management optimization
- Cache performance and cleanup
- End-to-end optimization scenarios

Run tests with:
```bash
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Configuration

### Default Settings

The system uses sensible defaults that work well for most scenarios:

- **Memory pressure thresholds**: Warning at 60%, Critical at 80%
- **Inference throttling**: Adaptive based on battery and thermal state
- **Cache limits**: 50MB total across all caches
- **Connection priorities**: Critical > High > Medium > Low

### Customization

Settings can be customized through the performance optimizer:

```swift
// Customize optimization behavior
PerformanceOptimizer.shared.setOptimizationLevel(.battery)

// Override throttling
InferenceThrottler.shared.setThrottleLevel(.conservative)

// Configure connection management
ConnectionManager.shared.setIntelligentMode(true)
```

## Troubleshooting

### Common Issues

1. **High memory usage**: Check cache statistics and clear if necessary
2. **Slow AI inference**: Verify throttling settings and system conditions
3. **Connection drops**: Check network status and connection priorities
4. **Battery drain**: Review optimization level and background activity

### Debug Tools

1. **Performance Monitor View**: Real-time system status
2. **Console Logging**: Detailed operation logs
3. **Memory Profiler**: Xcode Instruments integration
4. **Network Monitor**: Connection status and optimization

For more detailed troubleshooting, enable verbose logging:

```swift
// Enable verbose performance logging
AppSettings.shared.verbosePerformanceLogs = true
```