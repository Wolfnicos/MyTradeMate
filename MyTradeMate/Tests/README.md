# MyTradeMate Test Suite

This directory contains comprehensive tests for the MyTradeMate iOS trading application.

## Test Structure

```
Tests/
├── Unit/                        # Unit tests for individual components
│   ├── OrderExecutionTests.swift      # Order execution logic tests
│   ├── RiskManagementTests.swift      # Risk management calculations
│   ├── PositionTrackingTests.swift    # Position tracking functionality
│   ├── CoreTradingLogicTestSuite.swift # Complete test suite runner
│   ├── KeychainStoreTests.swift       # Keychain security tests
│   ├── CredentialValidationTests.swift # Credential validation tests
│   ├── SecureDataHandlingTests.swift  # Secure data handling tests
│   ├── SecurityTestSuite.swift        # Security test suite runner
│   ├── CoreMLModelTests.swift         # CoreML model loading tests
│   ├── FeaturePreparationTests.swift  # Feature preparation tests
│   ├── PredictionHandlingTests.swift  # Prediction handling tests
│   └── AIMLTestSuite.swift            # AI/ML test suite runner
├── Integration/                 # Integration tests for system components
│   ├── WebSocketIntegrationTests.swift # WebSocket connectivity tests
│   ├── BinanceIntegrationTests.swift  # Binance API integration tests
│   ├── KrakenIntegrationTests.swift   # Kraken API integration tests
│   ├── IntegrationTestSuite.swift     # Complete integration test suite
│   └── README.md                      # Integration test documentation
├── Mocks/                      # Mock implementations
│   └── MockServices.swift      # Service mocks for testing
├── UI/                         # UI tests (future)
└── README.md                   # This file
```

## Test Categories

### Core Trading Logic Tests

The core trading logic tests cover the three main areas specified in the requirements:

### Security Tests

The security tests cover comprehensive security functionality as specified in the requirements:

### AI/ML Tests

The AI/ML tests cover comprehensive CoreML functionality as specified in the requirements:

### Integration Tests

The integration tests verify system-wide functionality and component interaction as specified in the requirements:

### 1. Order Execution Logic Tests (`OrderExecutionTests.swift`)

Tests the `TradeManager` class functionality:

- ✅ **Successful market buy orders**
- ✅ **Successful market sell orders** 
- ✅ **Complete position closure**
- ✅ **Short position execution**
- ✅ **Order rejection when risk limits reached**
- ✅ **Multiple orders updating positions correctly**
- ✅ **Fill recording and tracking**

**Key Test Scenarios:**
```swift
func testSuccessfulMarketBuyOrder() async throws
func testSuccessfulMarketSellOrder() async throws  
func testCompletePositionClose() async throws
func testShortPositionExecution() async throws
func testOrderRejectionWhenRiskLimitReached() async throws
```

### 2. Risk Management Calculations (`RiskManagementTests.swift`)

Tests the `RiskManager` class functionality:

- ✅ **Daily loss limit enforcement**
- ✅ **Position sizing calculations**
- ✅ **Default stop loss calculations**
- ✅ **Default take profit calculations**
- ✅ **Risk parameter management**
- ✅ **Edge case handling**

**Key Test Scenarios:**
```swift
func testCanTradeWhenNoDailyLoss()
func testCannotTradeWhenDailyLossLimitExceeded()
func testPositionSizingBasicCalculation()
func testDefaultStopLossForBuyOrder()
func testDefaultTakeProfitForBuyOrder()
```

### 3. Position Tracking Functionality (`PositionTrackingTests.swift`)

Tests position management and P&L calculations:

- ✅ **Position model functionality**
- ✅ **Unrealized P&L calculations**
- ✅ **PnL Manager snapshot generation**
- ✅ **Realized P&L tracking**
- ✅ **Trade store operations**

**Key Test Scenarios:**
```swift
func testUnrealizedPnLForLongPosition()
func testUnrealizedPnLForShortPosition()
func testSnapshotWithLongPosition()
func testAddRealizedProfit()
func testTradesOrderedNewestFirst()
```

### 4. Security Tests

#### KeychainStore Operations (`KeychainStoreTests.swift`)

Tests the `KeychainStore` class functionality:

- ✅ **API key and secret storage/retrieval**
- ✅ **Exchange credential management**
- ✅ **Credential existence checking**
- ✅ **Secure deletion of credentials**
- ✅ **Error handling for missing items**
- ✅ **Data integrity and isolation**
- ✅ **Concurrent access safety**

**Key Test Scenarios:**
```swift
func testSaveAndRetrieveAPIKey() async throws
func testMultipleExchangeCredentials() async throws
func testDeleteCredentials() async throws
func testConcurrentSaveAndRetrieve() async throws
```

#### Credential Validation (`CredentialValidationTests.swift`)

Tests credential validation and input handling:

- ✅ **Input validation for empty credentials**
- ✅ **API key format validation**
- ✅ **Special character handling**
- ✅ **Length validation (short/long credentials)**
- ✅ **Unicode character support**
- ✅ **Error handling and state management**

**Key Test Scenarios:**
```swift
func testSaveKeysWithValidCredentials()
func testSaveKeysWithEmptyAPIKey()
func testValidateAPIKeyFormat()
func testCredentialsWithSpecialCharacters()
```

#### Secure Data Handling (`SecureDataHandlingTests.swift`)

Tests secure data handling and network security:

- ✅ **HTTPS enforcement and validation**
- ✅ **Secure URLSession creation**
- ✅ **ATS configuration validation**
- ✅ **Data sanitization and masking**
- ✅ **Memory security and clearing**
- ✅ **Certificate pinning simulation**
- ✅ **Input sanitization**

**Key Test Scenarios:**
```swift
func testValidateHTTPSForSecureURL()
func testCreateSecureSessionForBinance()
func testSensitiveDataNotInLogs()
func testSecureRandomGeneration()
```

## Running the Tests

### Using Xcode

1. Open the MyTradeMate project in Xcode
2. Press `Cmd+U` to run all tests
3. Or use `Cmd+6` to open the Test Navigator and run specific test classes

### Using Command Line

```bash
# Run all tests
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'

# Run only unit tests
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:MyTradeMateTests/Unit

# Run only integration tests
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:MyTradeMateTests/Integration

# Run specific test class
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:MyTradeMateTests/OrderExecutionTests

# Run integration test suite
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:MyTradeMateTests/IntegrationTestSuite
```

### Test Suite Runner

Use the `CoreTradingLogicTestSuite` to run all core trading tests together:

```swift
// This runs all core trading logic tests as a group
let testSuite = CoreTradingLogicTestSuite()
```

## Test Coverage

The tests provide comprehensive coverage of:

### Order Execution (TradeManager)
- ✅ Market order execution (buy/sell)
- ✅ Position creation and updates
- ✅ Average price calculations
- ✅ Realized P&L calculations
- ✅ Risk limit enforcement
- ✅ Fill tracking and recording

### Risk Management (RiskManager)
- ✅ Daily loss limit tracking
- ✅ Position sizing based on risk percentage
- ✅ Stop loss and take profit calculations
- ✅ Risk parameter validation
- ✅ Edge cases (zero/negative equity)

### Position Tracking
- ✅ Position state management (flat/long/short)
- ✅ Unrealized P&L calculations
- ✅ P&L snapshot generation
- ✅ Realized P&L accumulation
- ✅ Trade history storage and retrieval

## Mock Objects

The test suite includes comprehensive mock implementations:

### MockExchangeClient
- Simulates exchange API responses
- Configurable success/failure scenarios
- Order fill simulation
- Account information mocking

### Test Utilities
- `TradingTestUtilities`: Common test setup and validation
- `TestOrderBuilder`: Builder pattern for test orders
- `TestFillBuilder`: Builder pattern for test fills

## Test Data and Scenarios

### Realistic Trading Scenarios
- Long position entry and exit
- Short position management
- Partial position closure
- Multiple order execution
- Risk limit enforcement

### Edge Cases
- Zero quantity positions
- Negative equity handling
- Very small price movements
- Large position sizes
- Extreme market conditions

### Performance Tests
- Core operation performance measurement
- Memory usage validation
- Concurrent operation testing

## Best Practices

### Test Organization
- Each test class focuses on a single component
- Tests are grouped by functionality
- Clear test naming conventions
- Comprehensive setup and teardown

### Test Data
- Use realistic market prices and quantities
- Test both profit and loss scenarios
- Include edge cases and boundary conditions
- Use builder patterns for complex test data

### Assertions
- Use appropriate accuracy for floating-point comparisons
- Test both positive and negative cases
- Verify state changes and side effects
- Include performance assertions where relevant

### 5. Integration Tests

#### WebSocket Integration (`WebSocketIntegrationTests.swift`)

Tests WebSocket connectivity and reconnection logic:

- ✅ **Connection establishment and teardown**
- ✅ **Automatic reconnection with exponential backoff**
- ✅ **Health monitoring and ping/pong functionality**
- ✅ **Message sending and receiving**
- ✅ **Error handling and recovery**
- ✅ **Concurrent operations**
- ✅ **Memory management and cleanup**

#### Binance API Integration (`BinanceIntegrationTests.swift`)

Tests Binance API client functionality:

- ✅ **Client initialization and configuration**
- ✅ **Symbol normalization (BTCUSDT format)**
- ✅ **Best price retrieval from REST API**
- ✅ **Market order placement (paper trading)**
- ✅ **WebSocket ticker stream subscription**
- ✅ **Multi-symbol subscriptions**
- ✅ **Connection resilience and reconnection**
- ✅ **Rate limit handling**
- ✅ **Data validation and error handling**

#### Kraken API Integration (`KrakenIntegrationTests.swift`)

Tests Kraken API client functionality:

- ✅ **Client initialization and configuration**
- ✅ **Symbol normalization (XBT/USD format conversion)**
- ✅ **Best price retrieval from REST API**
- ✅ **Market order placement (paper trading)**
- ✅ **WebSocket ticker stream subscription**
- ✅ **Multi-symbol subscriptions**
- ✅ **Connection resilience and reconnection**
- ✅ **Rate limit handling (stricter than Binance)**
- ✅ **Data validation and error handling**
- ✅ **Message parsing and connection stability**

**Key Test Scenarios:**
```swift
func testWebSocketReconnectionLogic() async throws
func testBinanceWebSocketTickerStream() async throws
func testKrakenWebSocketReconnection() async throws
func testCompleteSystemIntegration() async throws
```

## Future Enhancements

### UI Tests
- Trading interface interactions
- Settings configuration
- Error handling displays
- Performance monitoring

### Load Tests
- High-frequency trading simulation
- Memory pressure testing
- Concurrent user scenarios
- Market data processing

## Troubleshooting

### Common Issues

**Test Failures Due to Timing**
- Use `async/await` properly for asynchronous operations
- Add appropriate delays for state changes
- Use XCTest expectations for async operations

**Floating Point Precision**
- Use `accuracy` parameter in XCTAssertEqual for Double comparisons
- Be aware of cumulative rounding errors
- Test with realistic precision requirements

**Mock Configuration**
- Ensure mocks are properly reset between tests
- Configure mock responses before test execution
- Verify mock interactions in tests

### Debugging Tests

1. Use breakpoints in test methods
2. Check test logs for detailed error information
3. Verify mock object configurations
4. Validate test data setup

## Contributing

When adding new tests:

1. Follow existing naming conventions
2. Include both positive and negative test cases
3. Add appropriate documentation
4. Update this README if adding new test categories
5. Ensure tests are deterministic and repeatable

## Requirements Compliance

These tests fulfill the requirements specified in the upgrade specification:

- ✅ **Requirement 5.1**: Unit tests cover order execution, risk management, and position tracking
- ✅ **Requirement 5.2**: Unit tests verify KeychainStore operations and secure data handling
- ✅ **Requirement 5.3**: Unit tests cover CoreML model loading, feature preparation, and prediction handling
- ✅ **Requirement 5.4**: Integration tests verify WebSocket reconnection logic and API client functionality
- ✅ **Comprehensive coverage**: All critical system components tested
- ✅ **Realistic scenarios**: Tests use actual trading scenarios and edge cases
- ✅ **Performance validation**: Core operations and integration performance measured
- ✅ **Error handling**: Risk limits, security, and network error conditions tested
- ✅ **System integration**: End-to-end workflows and component interaction verified