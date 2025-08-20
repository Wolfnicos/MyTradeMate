# MyTradeMate Developer Guide

This guide provides comprehensive information for developers working on MyTradeMate, including architecture patterns, extending functionality, and best practices.

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Development Environment Setup](#development-environment-setup)
3. [Code Organization](#code-organization)
4. [Extending Trading Strategies](#extending-trading-strategies)
5. [Adding New Services](#adding-new-services)
6. [UI Development Guidelines](#ui-development-guidelines)
7. [Testing Guidelines](#testing-guidelines)
8. [Performance Optimization](#performance-optimization)
9. [Security Best Practices](#security-best-practices)
10. [Debugging and Monitoring](#debugging-and-monitoring)

## 🏗️ Architecture Overview

MyTradeMate follows a modern iOS architecture with clear separation of concerns and dependency injection.

### Core Principles
- **MVVM Pattern**: Views observe ViewModels, ViewModels manage business logic
- **Dependency Injection**: Services are injected via protocols for testability
- **Reactive Programming**: Combine framework for data flow and state management
- **Protocol-Oriented Programming**: Interfaces define contracts, implementations provide functionality
- **Single Responsibility**: Each class/struct has one clear purpose

### Layer Architecture
```
┌─────────────────────────────────────┐
│              Views Layer            │  SwiftUI Views, Navigation
├─────────────────────────────────────┤
│           ViewModels Layer          │  Business Logic, State Management
├─────────────────────────────────────┤
│            Services Layer           │  Data Access, External APIs
├─────────────────────────────────────┤
│             Models Layer            │  Data Structures, Entities
├─────────────────────────────────────┤
│              Core Layer             │  Utilities, Managers, Extensions
└─────────────────────────────────────┘
```

### Dependency Flow
```
Views → ViewModels → Services → Core
  ↓         ↓          ↓        ↓
 UI    Business    Data     Utilities
Logic    Logic    Access
```

## 🛠️ Development Environment Setup

### Prerequisites
1. **Xcode 15.0+** with iOS 17.0+ SDK
2. **Swift 5.9+** language support
3. **Git** for version control
4. **Simulator** or physical iOS device for testing

### Project Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/MyTradeMate.git
cd MyTradeMate

# Open in Xcode
open MyTradeMate.xcodeproj

# Verify build configuration
# Target: iOS 17.0+
# Swift Language Version: 5.9
# Build Configuration: Debug (for development)
```

### Development Tools
- **Xcode Instruments**: For performance profiling
- **Console.app**: For device logging
- **Simulator**: For testing different device configurations
- **Git**: For version control and collaboration

## 📁 Code Organization

### Directory Structure
```
MyTradeMate/
├── Core/                      # Core utilities and managers
│   ├── Performance/           # Performance optimization system
│   ├── Security/             # Security and keychain management
│   ├── Exchange/             # Exchange client implementations
│   ├── AppError.swift        # Centralized error definitions
│   └── ErrorManager.swift    # Error handling coordination
├── Services/                 # Business logic services
│   ├── AI/                   # AI model management
│   │   └── AIModelManager.swift
│   ├── Data/                 # Market data services
│   │   └── MarketDataService.swift
│   └── Trading/              # Trading execution services
├── ViewModels/               # MVVM ViewModels
│   ├── Dashboard/            # Dashboard-related ViewModels
│   ├── Settings/             # Settings ViewModels
│   └── Components/           # Reusable ViewModel components
├── Views/                    # SwiftUI Views
│   ├── Dashboard/            # Main trading interface
│   ├── Settings/             # App configuration
│   ├── Charts/               # Chart components
│   └── Debug/                # Development and debugging views
├── Models/                   # Data models and entities
├── Strategies/               # Trading strategy implementations
├── Themes/                   # UI theming system
├── Tests/                    # Comprehensive test suite
├── UI/                       # Reusable UI components
├── Settings/                 # Settings management
└── AIModels/                 # CoreML model files
```

### Naming Conventions
- **Files**: PascalCase (e.g., `MarketDataService.swift`)
- **Classes/Structs**: PascalCase (e.g., `class MarketDataService`)
- **Variables/Functions**: camelCase (e.g., `func fetchCandles()`)
- **Constants**: camelCase (e.g., `let maxRetryCount`)
- **Protocols**: PascalCase with descriptive suffix (e.g., `TradingStrategyProtocol`)

## 🎯 Extending Trading Strategies

### Strategy Protocol
All trading strategies must conform to the `TradingStrategyProtocol`:

```swift
protocol TradingStrategyProtocol {
    var name: String { get }
    var description: String { get }
    var parameters: [StrategyParameter] { get set }
    
    func generateSignal(from candles: [Candle]) -> TradingSignal
    func updateParameter(_ parameter: StrategyParameter)
    func validateParameters() -> Bool
}
```

### Creating a New Strategy

1. **Create Strategy File**
```swift
// MyTradeMate/Strategies/MyCustomStrategy.swift
import Foundation

final class MyCustomStrategy: TradingStrategyProtocol {
    let name = "My Custom Strategy"
    let description = "Description of what this strategy does"
    
    var parameters: [StrategyParameter] = [
        StrategyParameter(
            name: "threshold",
            displayName: "Signal Threshold",
            value: 0.7,
            range: 0.1...1.0,
            description: "Minimum confidence threshold for signals"
        )
    ]
    
    func generateSignal(from candles: [Candle]) -> TradingSignal {
        // Implement your strategy logic here
        guard candles.count >= 20 else {
            return TradingSignal(action: "HOLD", confidence: 0.0, reason: "Insufficient data")
        }
        
        // Example: Simple price momentum
        let recent = candles.suffix(5)
        let older = candles.dropLast(5).suffix(5)
        
        let recentAvg = recent.map(\.close).reduce(0, +) / Double(recent.count)
        let olderAvg = older.map(\.close).reduce(0, +) / Double(older.count)
        
        let momentum = (recentAvg - olderAvg) / olderAvg
        let threshold = parameters.first { $0.name == "threshold" }?.value ?? 0.7
        
        if momentum > threshold {
            return TradingSignal(action: "BUY", confidence: min(momentum, 1.0), reason: "Positive momentum")
        } else if momentum < -threshold {
            return TradingSignal(action: "SELL", confidence: min(abs(momentum), 1.0), reason: "Negative momentum")
        } else {
            return TradingSignal(action: "HOLD", confidence: 0.5, reason: "Neutral momentum")
        }
    }
    
    func updateParameter(_ parameter: StrategyParameter) {
        if let index = parameters.firstIndex(where: { $0.name == parameter.name }) {
            parameters[index] = parameter
        }
    }
    
    func validateParameters() -> Bool {
        return parameters.allSatisfy { param in
            param.range.contains(param.value)
        }
    }
}
```

2. **Register Strategy**
```swift
// In StrategyManager.swift
private func loadStrategies() {
    strategies = [
        RSIStrategy(),
        MACDStrategy(),
        EMAStrategy(),
        MyCustomStrategy() // Add your strategy here
    ]
}
```

3. **Add Tests**
```swift
// MyTradeMate/Tests/Unit/MyCustomStrategyTests.swift
import XCTest
@testable import MyTradeMate

final class MyCustomStrategyTests: XCTestCase {
    private var strategy: MyCustomStrategy!
    
    override func setUp() {
        super.setUp()
        strategy = MyCustomStrategy()
    }
    
    func testStrategyGeneratesValidSignal() {
        let testCandles = generateTestCandles(count: 50)
        let signal = strategy.generateSignal(from: testCandles)
        
        XCTAssertTrue(["BUY", "SELL", "HOLD"].contains(signal.action))
        XCTAssertGreaterThanOrEqual(signal.confidence, 0.0)
        XCTAssertLessThanOrEqual(signal.confidence, 1.0)
    }
    
    func testParameterValidation() {
        XCTAssertTrue(strategy.validateParameters())
        
        // Test invalid parameter
        strategy.updateParameter(StrategyParameter(
            name: "threshold",
            displayName: "Signal Threshold",
            value: 2.0, // Invalid: outside range
            range: 0.1...1.0,
            description: "Test"
        ))
        
        XCTAssertFalse(strategy.validateParameters())
    }
    
    private func generateTestCandles(count: Int) -> [Candle] {
        // Generate test data for strategy testing
        // Implementation details...
    }
}
```

### Strategy Best Practices
- **Validate Input**: Always check for sufficient data before generating signals
- **Handle Edge Cases**: Gracefully handle missing or invalid data
- **Configurable Parameters**: Make strategy behavior configurable through parameters
- **Clear Reasoning**: Provide clear reasons for signal generation
- **Performance**: Optimize for performance, especially with large datasets
- **Testing**: Write comprehensive tests for all strategy logic

## 🔧 Adding New Services

### Service Protocol Pattern
Follow the protocol-based service pattern for dependency injection:

```swift
// 1. Define Protocol
protocol MyServiceProtocol {
    func performOperation() async throws -> Result
}

// 2. Implement Service
final class MyService: MyServiceProtocol {
    func performOperation() async throws -> Result {
        // Implementation
    }
}

// 3. Register in ServiceContainer (if using DI)
container.register(MyServiceProtocol.self) { _ in
    MyService()
}
```

### Service Guidelines
- **Single Responsibility**: Each service should have one clear purpose
- **Protocol-Based**: Define protocols for all services to enable testing
- **Async/Await**: Use modern concurrency for network and long-running operations
- **Error Handling**: Implement comprehensive error handling with typed errors
- **Thread Safety**: Ensure services are thread-safe, especially shared instances

### Example: Adding a News Service
```swift
// 1. Define Protocol
protocol NewsServiceProtocol {
    func fetchLatestNews() async throws -> [NewsItem]
    func fetchNewsForSymbol(_ symbol: String) async throws -> [NewsItem]
}

// 2. Implement Service
@MainActor
final class NewsService: NewsServiceProtocol, ObservableObject {
    @Published var latestNews: [NewsItem] = []
    
    private let networkClient: NetworkClientProtocol
    private let cache: DataCache<[NewsItem]>
    
    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
        self.cache = DataCacheManager.shared.getCache(for: "news", type: [NewsItem].self)
    }
    
    func fetchLatestNews() async throws -> [NewsItem] {
        // Check cache first
        if let cached = cache.get("latest"), !cached.isEmpty {
            return cached
        }
        
        // Fetch from network
        let news = try await networkClient.fetchNews()
        
        // Cache results
        cache.set("latest", value: news)
        
        // Update published property
        latestNews = news
        
        return news
    }
    
    func fetchNewsForSymbol(_ symbol: String) async throws -> [NewsItem] {
        let cacheKey = "news_\(symbol)"
        
        if let cached = cache.get(cacheKey) {
            return cached
        }
        
        let news = try await networkClient.fetchNewsForSymbol(symbol)
        cache.set(cacheKey, value: news)
        
        return news
    }
}

// 3. Add to ServiceContainer or use directly
// In a ViewModel:
class NewsViewModel: ObservableObject {
    @Published var news: [NewsItem] = []
    
    private let newsService: NewsServiceProtocol
    
    init(newsService: NewsServiceProtocol = NewsService(networkClient: NetworkClient())) {
        self.newsService = newsService
    }
    
    func loadNews() async {
        do {
            news = try await newsService.fetchLatestNews()
        } catch {
            ErrorManager.shared.handle(error)
        }
    }
}
```

## 🎨 UI Development Guidelines

### SwiftUI Best Practices
- **State Management**: Use `@State`, `@StateObject`, `@ObservedObject` appropriately
- **View Composition**: Break complex views into smaller, reusable components
- **Performance**: Use `LazyVStack`/`LazyHStack` for large lists
- **Accessibility**: Always add accessibility labels and hints
- **Navigation**: Use NavigationStack for iOS 17+ compatibility

### View Structure
```swift
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    @State private var showingSheet = false
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("My View")
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: $showingSheet) {
                    sheetContent
                }
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    private var content: some View {
        // Main content implementation
    }
    
    private var toolbarContent: some ToolbarContent {
        // Toolbar implementation
    }
    
    private var sheetContent: some View {
        // Sheet content implementation
    }
}
```

### Accessibility Guidelines
```swift
// Always add accessibility support
Text("Current Price")
    .accessibilityLabel("Current Bitcoin price")
    .accessibilityValue("$45,000")

Button("Buy") {
    // Action
}
.accessibilityHint("Executes a buy order")

Chart(data) { item in
    // Chart implementation
}
.accessibilityLabel("Price chart")
.accessibilityChartDescriptor(chartDescriptor)
```

## 🧪 Testing Guidelines

### Test Structure
```
Tests/
├── Unit/                    # Unit tests for individual components
│   ├── Services/           # Service layer tests
│   ├── ViewModels/         # ViewModel tests
│   ├── Models/             # Model tests
│   └── Strategies/         # Strategy tests
├── Integration/            # Integration tests
│   ├── API/               # API integration tests
│   ├── Database/          # Data persistence tests
│   └── EndToEnd/          # Full flow tests
└── Mocks/                 # Test mocks and utilities
```

### Unit Test Example
```swift
import XCTest
@testable import MyTradeMate

@MainActor
final class MarketDataServiceTests: XCTestCase {
    private var service: MarketDataService!
    private var mockNetworkClient: MockNetworkClient!
    
    override func setUp() async throws {
        try await super.setUp()
        mockNetworkClient = MockNetworkClient()
        service = MarketDataService(networkClient: mockNetworkClient)
    }
    
    override func tearDown() async throws {
        service = nil
        mockNetworkClient = nil
        try await super.tearDown()
    }
    
    func testFetchCandlesSuccess() async throws {
        // Given
        let expectedCandles = generateTestCandles(count: 100)
        mockNetworkClient.candlesResult = .success(expectedCandles)
        
        // When
        let candles = try await service.fetchCandles(symbol: "BTCUSDT", timeframe: .m5)
        
        // Then
        XCTAssertEqual(candles.count, expectedCandles.count)
        XCTAssertEqual(mockNetworkClient.fetchCandlesCallCount, 1)
    }
    
    func testFetchCandlesFailure() async {
        // Given
        mockNetworkClient.candlesResult = .failure(NetworkError.connectionFailed)
        
        // When/Then
        do {
            _ = try await service.fetchCandles(symbol: "BTCUSDT", timeframe: .m5)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}
```

### Testing Best Practices
- **AAA Pattern**: Arrange, Act, Assert
- **Descriptive Names**: Test names should describe what is being tested
- **One Assertion**: Each test should verify one specific behavior
- **Mock Dependencies**: Use mocks to isolate the unit under test
- **Async Testing**: Use async/await for testing asynchronous code
- **Edge Cases**: Test boundary conditions and error scenarios

## ⚡ Performance Optimization

### Memory Management
```swift
// Use weak references in closures
someService.performOperation { [weak self] result in
    self?.handleResult(result)
}

// Implement proper cleanup
deinit {
    cancellables.removeAll()
    timer?.invalidate()
    NotificationCenter.default.removeObserver(self)
}
```

### Efficient Data Loading
```swift
// Use lazy loading for expensive operations
private lazy var expensiveResource: ExpensiveResource = {
    return ExpensiveResource()
}()

// Implement caching for frequently accessed data
private let cache = DataCacheManager.shared.getCache(for: "myData", type: MyDataType.self)

func loadData() async {
    if let cached = cache.get("key") {
        return cached
    }
    
    let data = await fetchFromNetwork()
    cache.set("key", value: data)
    return data
}
```

### Performance Monitoring
```swift
// Use performance logging
let startTime = Date()
await performExpensiveOperation()
Log.performance("Expensive operation completed", duration: Date().timeIntervalSince(startTime))

// Monitor memory usage
let memoryUsage = MemoryPressureManager.shared.getCurrentMemoryUsage()
if memoryUsage.usagePercentage > 80 {
    // Trigger cleanup
    performMemoryCleanup()
}
```

## 🔒 Security Best Practices

### Secure Data Storage
```swift
// Always use Keychain for sensitive data
let keychain = KeychainStore.shared

// Store sensitive data
try keychain.store(apiKey, for: "binance_api_key")

// Retrieve sensitive data
let apiKey = try keychain.retrieve(for: "binance_api_key")

// Delete when no longer needed
try keychain.delete(for: "binance_api_key")
```

### Network Security
```swift
// Use certificate pinning for API calls
let session = URLSession(configuration: .default, delegate: certificatePinner, delegateQueue: nil)

// Validate SSL certificates
func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    // Implement certificate validation
}
```

### Logging Security
```swift
// Never log sensitive data in production
#if DEBUG
Log.debug("API Key: \(apiKey)")
#else
Log.debug("API Key: [REDACTED]")
#endif

// Use secure logging methods
Log.sensitive("Processing user credentials")
```

## 🐛 Debugging and Monitoring

### Debug Views
MyTradeMate includes comprehensive debug views:
- **Performance Monitor**: Real-time performance metrics
- **Validation Suite**: Automated testing interface
- **Network Monitor**: API call monitoring
- **Cache Inspector**: Cache usage and statistics

### Logging System
```swift
// Use structured logging
Log.ai("AI prediction completed: \(signal)")
Log.network("API request: \(endpoint)")
Log.performance("Operation completed", duration: duration)
Log.error(error, context: "Market data fetch")

// Category-specific logging
Log.log("Custom message", category: .trading)
```

### Performance Profiling
```swift
// Use Instruments for detailed profiling
// Time Profiler: CPU usage analysis
// Allocations: Memory usage tracking
// Leaks: Memory leak detection
// Network: Network activity monitoring

// In-app performance monitoring
let optimizer = PerformanceOptimizer.shared
let metrics = optimizer.getDetailedMetrics()
print("Memory usage: \(metrics.memoryUsage.usedMemoryMB)MB")
```

### Error Handling
```swift
// Centralized error handling
ErrorManager.shared.handle(error, context: "User action")

// Custom error types
enum MyServiceError: LocalizedError {
    case invalidInput(String)
    case networkFailure(underlying: Error)
    case dataCorruption
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let input):
            return "Invalid input: \(input)"
        case .networkFailure(let error):
            return "Network error: \(error.localizedDescription)"
        case .dataCorruption:
            return "Data corruption detected"
        }
    }
}
```

## 📚 Additional Resources

### Documentation
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)
- [CoreML Documentation](https://developer.apple.com/documentation/coreml)

### Tools and Libraries
- **Xcode Instruments**: Performance profiling
- **SwiftLint**: Code style enforcement
- **SwiftFormat**: Code formatting
- **Fastlane**: Build automation

### Best Practices
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use [SwiftUI Best Practices](https://developer.apple.com/documentation/swiftui/swiftui-best-practices)
- Implement [iOS Security Best Practices](https://developer.apple.com/documentation/security)
- Follow [Accessibility Guidelines](https://developer.apple.com/accessibility/)

---

This developer guide is a living document. Please update it as the codebase evolves and new patterns emerge.