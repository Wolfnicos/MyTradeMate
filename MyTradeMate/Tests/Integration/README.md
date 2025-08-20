# Integration Tests

This directory contains comprehensive integration tests for the MyTradeMate iOS application. These tests verify that different system components work together correctly and handle real-world scenarios.

## Test Structure

### WebSocketIntegrationTests.swift
Tests WebSocket connectivity, reconnection logic, and message handling in demo mode.

**Key Test Areas:**
- WebSocket connection establishment and teardown
- Automatic reconnection with exponential backoff
- Health monitoring and ping/pong functionality
- Message sending and receiving
- Error handling and recovery
- Concurrent operations
- Memory management and cleanup

**Requirements Covered:** 5.4 - WebSocket reconnection logic in demo mode

### BinanceIntegrationTests.swift
Tests Binance API client functionality including REST API calls and WebSocket streams.

**Key Test Areas:**
- Client initialization and configuration
- Symbol normalization (BTCUSDT format)
- Best price retrieval from REST API
- Market order placement (paper trading)
- WebSocket ticker stream subscription
- Multi-symbol subscriptions
- Connection resilience and reconnection
- Rate limit handling
- Data validation and error handling

**Requirements Covered:** 5.4 - Binance API client functionality

### KrakenIntegrationTests.swift
Tests Kraken API client functionality including REST API calls and WebSocket streams.

**Key Test Areas:**
- Client initialization and configuration
- Symbol normalization (XBT/USD format conversion)
- Best price retrieval from REST API
- Market order placement (paper trading)
- WebSocket ticker stream subscription
- Multi-symbol subscriptions
- Connection resilience and reconnection
- Rate limit handling (stricter than Binance)
- Data validation and error handling
- Message parsing and connection stability

**Requirements Covered:** 5.4 - Kraken API client functionality

### IntegrationTestSuite.swift
Comprehensive test suite that verifies system-wide integration and provides convenient test execution.

**Key Test Areas:**
- Complete system pipeline testing
- Cross-component data flow validation
- System resilience under failure conditions
- Error propagation across system boundaries
- Performance testing with concurrent operations
- Memory management under load
- End-to-end integration scenarios

## Running Integration Tests

### Prerequisites
- Network connectivity (tests use real API endpoints)
- iOS 17+ simulator or device
- Xcode 15+

### Running All Integration Tests
```bash
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:MyTradeMateTests/IntegrationTestSuite
```

### Running Specific Test Classes
```bash
# WebSocket tests only
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:MyTradeMateTests/WebSocketIntegrationTests

# Binance tests only
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:MyTradeMateTests/BinanceIntegrationTests

# Kraken tests only
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:MyTradeMateTests/KrakenIntegrationTests
```

### Running Individual Tests
```bash
# Specific WebSocket test
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:MyTradeMateTests/WebSocketIntegrationTests/testWebSocketReconnectionLogic

# Specific Binance test
xcodebuild test -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' -only-testing:MyTradeMateTests/BinanceIntegrationTests/testBinanceWebSocketTickerStream
```

## Test Configuration

### Network Dependencies
These tests require network connectivity to:
- `wss://echo.websocket.org` - WebSocket echo server for testing
- `https://api.binance.com` - Binance REST API
- `wss://stream.binance.com` - Binance WebSocket API
- `https://api.kraken.com` - Kraken REST API
- `wss://ws.kraken.com` - Kraken WebSocket API

### Test Timeouts
- WebSocket connection tests: 10-15 seconds
- API response tests: 5-10 seconds
- Multi-symbol subscription tests: 30-60 seconds
- Reconnection tests: 15-30 seconds

### Rate Limiting
- Binance: More permissive rate limits
- Kraken: Stricter rate limits (tests include delays)

## Test Data and Mocking

### Real API Usage
These integration tests use real API endpoints to ensure authentic behavior. However, they:
- Use small quantities for order tests (0.001 BTC)
- Only test paper trading functionality
- Include proper error handling for network issues
- Skip tests when network is unavailable

### Test Symbols
- Primary: BTCUSDT (Bitcoin/Tether)
- Secondary: ETHUSDT (Ethereum/Tether)
- Additional: ADAUSDT, DOTUSDT (for multi-symbol tests)

## Error Handling

### Network Errors
Tests gracefully handle:
- Connection timeouts
- DNS resolution failures
- Rate limiting responses
- Invalid API responses

### Test Skipping
Tests automatically skip when:
- Network connectivity is unavailable
- API endpoints are unreachable
- Rate limits are exceeded

### Error Validation
Tests verify that:
- Errors are properly propagated
- Error messages are meaningful
- Recovery mechanisms work correctly
- System remains stable after errors

## Performance Considerations

### Concurrent Operations
Tests verify that the system can handle:
- Multiple simultaneous WebSocket connections
- Concurrent API requests
- Parallel ticker subscriptions
- Simultaneous connect/disconnect operations

### Memory Management
Tests ensure:
- Proper cleanup of WebSocket connections
- No memory leaks in long-running operations
- Correct deallocation of client instances
- Stable performance under repeated operations

## Debugging Integration Tests

### Verbose Logging
Enable verbose logging in WebSocket tests by setting `verboseLogging: true` in test configurations.

### Network Debugging
Use network debugging tools to monitor:
- WebSocket connection establishment
- API request/response cycles
- Connection failures and retries

### Test Isolation
Each test class properly cleans up resources to ensure test isolation and prevent interference between tests.

## Continuous Integration

### CI Considerations
- Tests may be flaky due to network dependencies
- Consider running integration tests separately from unit tests
- Implement retry mechanisms for network-dependent tests
- Monitor test execution times and adjust timeouts as needed

### Test Reliability
- Tests include proper cleanup in tearDown methods
- Network errors are handled gracefully
- Tests use realistic timeouts
- Concurrent operations are properly synchronized

## Contributing

When adding new integration tests:

1. Follow the existing test structure and naming conventions
2. Include proper setup and tearDown methods
3. Handle network errors gracefully with XCTSkip when appropriate
4. Use realistic test data and scenarios
5. Include performance and memory management considerations
6. Document any new network dependencies
7. Ensure tests are isolated and don't interfere with each other

## Troubleshooting

### Common Issues

**Tests timing out:**
- Check network connectivity
- Verify API endpoints are accessible
- Increase timeout values if needed

**WebSocket connection failures:**
- Ensure firewall allows WebSocket connections
- Check if corporate network blocks WebSocket traffic
- Verify echo server is accessible

**API rate limiting:**
- Add delays between requests
- Reduce number of concurrent requests
- Implement exponential backoff

**Memory issues:**
- Ensure proper cleanup in tearDown
- Check for retain cycles in async operations
- Monitor memory usage during long-running tests