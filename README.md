# MyTradeMate iOS App

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0+-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

MyTradeMate is a sophisticated iOS trading application that combines artificial intelligence, technical analysis, and modern iOS features to provide an intelligent trading experience. The app supports multiple trading modes (Demo, Paper, Live) and integrates with major cryptocurrency exchanges.

## 🚀 Features

### Core Trading Features
- **AI-Powered Predictions**: Advanced CoreML models for market analysis and signal generation
- **Multiple Trading Strategies**: RSI, MACD, EMA Crossover with configurable parameters
- **Real-time Market Data**: Live price feeds and candlestick charts with volume display
- **Multi-Exchange Support**: Binance and Kraken integration with secure API management
- **Risk Management**: Comprehensive position tracking and P&L monitoring

### Modern iOS Features
- **iOS 17+ Interactive Widget**: Real-time P&L and position monitoring from home screen
- **SwiftUI Navigation**: Modern NavigationStack with deep linking support
- **Performance Optimization**: Intelligent memory management and battery optimization
- **Dark Mode Support**: Adaptive theming with system integration
- **Accessibility**: Full VoiceOver and accessibility support

### Trading Modes
- **Demo Mode**: Risk-free trading with simulated data for learning and testing
- **Paper Trading**: Real market data with virtual portfolio for strategy validation
- **Live Trading**: Real trading with comprehensive safety measures and confirmations

### Security & Privacy
- **Keychain Integration**: Secure storage of API credentials and sensitive data
- **Certificate Pinning**: Enhanced network security for exchange communications
- **Privacy First**: No sensitive data logging in production builds
- **Biometric Authentication**: Touch ID/Face ID support for app access

## 📱 Requirements

- **iOS**: 17.0 or later
- **Device**: iPhone (optimized for iPhone 16 Pro Max)
- **Xcode**: 15.0 or later (for development)
- **Swift**: 5.9 or later

## 🏗️ Architecture

MyTradeMate follows modern iOS architecture patterns with a focus on maintainability, testability, and performance.

### Core Architecture
- **MVVM Pattern**: SwiftUI views with dedicated ViewModels
- **Dependency Injection**: Protocol-based service injection for testability
- **Reactive Programming**: Combine framework for data flow and state management
- **Modular Design**: Feature-based code organization with clear separation of concerns

### Key Components
- **Services Layer**: Market data, AI models, exchange clients, and performance optimization
- **ViewModels Layer**: Business logic and state management for UI components
- **Views Layer**: SwiftUI views with modern navigation and accessibility
- **Security Layer**: Keychain management and secure data handling
- **Performance Layer**: Memory management, caching, and optimization systems

## 🛠️ Installation & Setup

### Prerequisites
1. Install Xcode 15.0 or later
2. Ensure iOS 17.0+ deployment target
3. Clone the repository

### Build Instructions
```bash
# Clone the repository
git clone https://github.com/yourusername/MyTradeMate.git
cd MyTradeMate

# Open in Xcode
open MyTradeMate.xcodeproj

# Build and run
# Select your target device/simulator and press Cmd+R
```

### Configuration
1. **Demo Mode**: No additional setup required - works out of the box
2. **Paper/Live Trading**: Configure exchange API credentials in Settings
3. **Widget**: Enable widget from iOS home screen customization

## 🔧 Development

### Project Structure
```
MyTradeMate/
├── Core/                   # Core utilities and managers
│   ├── Performance/        # Performance optimization system
│   ├── Security/          # Security and keychain management
│   └── Exchange/          # Exchange client implementations
├── Services/              # Business logic services
│   ├── AI/               # AI model management
│   ├── Data/             # Market data services
│   └── Trading/          # Trading execution services
├── ViewModels/           # MVVM ViewModels
│   ├── Dashboard/        # Dashboard-related ViewModels
│   ├── Settings/         # Settings ViewModels
│   └── Components/       # Reusable ViewModel components
├── Views/                # SwiftUI Views
│   ├── Dashboard/        # Main trading interface
│   ├── Settings/         # App configuration
│   ├── Charts/           # Chart components
│   └── Debug/            # Development and debugging views
├── Models/               # Data models and entities
├── Strategies/           # Trading strategy implementations
├── Themes/               # UI theming system
├── Tests/                # Comprehensive test suite
│   ├── Unit/            # Unit tests
│   ├── Integration/     # Integration tests
│   └── Mocks/           # Test mocks and utilities
├── UI/                   # Reusable UI components
├── Settings/             # Settings management
└── AIModels/             # CoreML model files
```

### Key Design Patterns
- **Dependency Injection**: Services are injected via protocols for testability
- **Observer Pattern**: Combine publishers for reactive data flow
- **Strategy Pattern**: Pluggable trading strategies with common interface
- **Factory Pattern**: Service creation and configuration
- **Singleton Pattern**: Shared managers (with dependency injection support)

### Performance Optimization
The app includes a comprehensive performance optimization system:
- **Memory Pressure Management**: Automatic cleanup during low memory conditions
- **AI Inference Throttling**: Battery-aware AI prediction frequency
- **Intelligent Connection Management**: Network-aware WebSocket optimization
- **Efficient Data Caching**: Memory-aware caching with automatic eviction

## 🧪 Testing

MyTradeMate includes a comprehensive test suite with 65+ tests covering all functionality.

### Test Categories
- **Unit Tests**: Core logic, calculations, and individual components
- **Integration Tests**: Service interactions and data flow
- **Security Tests**: Keychain operations and secure data handling
- **AI/ML Tests**: Model loading, predictions, and fallback handling
- **Performance Tests**: Memory usage, optimization, and benchmarks

### Running Tests
```bash
# Run all tests
xcodebuild test -project MyTradeMate.xcodeproj -scheme MyTradeMate -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run specific test suite
xcodebuild test -project MyTradeMate.xcodeproj -scheme MyTradeMate -only-testing:MyTradeMateTests/CoreTradingLogicTestSuite

# Run validation suite (in-app)
# Navigate to Settings > Debug > Validation Suite
```

### Test Coverage
- Core Trading Logic: 15+ tests
- Security: 12+ tests
- AI/ML: 10+ tests
- Integration: 8+ tests
- Performance: 15+ tests
- UI/Navigation: 5+ tests

## 📊 Performance Monitoring

The app includes built-in performance monitoring accessible through Settings > Debug:

### Performance Monitor
- Real-time memory usage tracking
- AI inference throttling status
- Network connection optimization
- Cache usage statistics
- Battery optimization metrics

### Validation Suite
- Automated testing of all core functionality
- Performance benchmarking
- Memory leak detection
- Security validation

## 🔒 Security

MyTradeMate implements comprehensive security measures:

### Data Protection
- **Keychain Storage**: All sensitive data stored in iOS Keychain
- **Certificate Pinning**: Exchange API communications secured with certificate pinning
- **No Sensitive Logging**: Production builds never log sensitive information
- **Biometric Authentication**: Optional Touch ID/Face ID protection

### API Security
- **Secure Credential Storage**: Exchange API keys encrypted in Keychain
- **Request Signing**: Proper API request authentication and signing
- **Network Security**: HTTPS enforcement with App Transport Security
- **Credential Validation**: Real-time validation of API credentials

### Best Practices
- Regular security audits and updates
- Minimal permission requests
- Secure coding practices throughout
- Privacy-first design principles

## 🎯 Trading Strategies

MyTradeMate supports multiple configurable trading strategies:

### Available Strategies
1. **RSI Strategy**: Relative Strength Index with overbought/oversold signals
2. **MACD Strategy**: Moving Average Convergence Divergence with trend analysis
3. **EMA Crossover**: Exponential Moving Average crossover signals
4. **AI Ensemble**: Machine learning predictions with confidence scoring

### Strategy Configuration
- Adjustable parameters for each strategy
- Backtesting capabilities (coming soon)
- Performance metrics and analytics
- Custom strategy development framework

## 🤖 AI & Machine Learning

### CoreML Integration
- **Multiple Models**: 5-minute, 1-hour, and 4-hour prediction models
- **Ensemble Predictions**: Combined model outputs for improved accuracy
- **Performance Optimization**: Intelligent inference throttling for battery life
- **Fallback Handling**: Graceful degradation when models are unavailable

### Model Management
- Automatic model loading and validation
- Memory-efficient model caching
- Performance monitoring and optimization
- Easy model updates and deployment

## 📱 Widget Support

MyTradeMate includes an iOS 17+ interactive widget:

### Widget Features
- Real-time P&L display
- Current position summary
- Connection status indicator
- Deep linking to app sections
- Demo mode indication

### Widget Configuration
1. Long press on home screen
2. Tap "+" to add widget
3. Search for "MyTradeMate"
4. Select widget size and configuration

## 🌐 Exchange Integration

### Supported Exchanges
- **Binance**: Spot trading with full API support
- **Kraken**: Spot trading with comprehensive integration
- **Paper Trading**: Simulated trading with real market data

### API Configuration
1. Create API keys on your chosen exchange
2. Navigate to Settings > Exchange Keys
3. Enter API credentials (stored securely in Keychain)
4. Test connection and enable trading

### Security Notes
- API keys are stored encrypted in iOS Keychain
- Keys are never transmitted or logged
- Recommend read-only keys for market data
- Use restricted keys with minimal permissions for trading

## 🚀 Deployment

### App Store Preparation
1. Update version numbers in project settings
2. Run comprehensive validation suite
3. Test on physical device
4. Verify App Store compliance
5. Submit for review

### Build Configurations
- **Debug**: Full logging and debugging features enabled
- **Release**: Optimized build with minimal logging
- **Production**: App Store ready with all optimizations

## 🤝 Contributing

We welcome contributions to MyTradeMate! Please follow these guidelines:

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Follow the existing code style and architecture
4. Add tests for new functionality
5. Run the validation suite before submitting

### Code Standards
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Maintain test coverage above 80%
- Document public APIs
- Follow security best practices

### Pull Request Process
1. Ensure all tests pass
2. Update documentation as needed
3. Add changelog entry
4. Request review from maintainers

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Apple for iOS development frameworks
- CoreML for machine learning capabilities
- Binance and Kraken for API access
- The Swift community for excellent libraries and tools

## 📞 Support

For support, questions, or feature requests:
- Create an issue on GitHub
- Check the documentation in the `/docs` folder
- Review the in-app help and tutorials

## 🔄 Changelog

### Version 2.0.0 (Current)
- iOS 17+ compatibility with modern SwiftUI navigation
- Interactive widget with real-time updates
- Comprehensive performance optimization system
- Enhanced security with certificate pinning
- AI-powered trading strategies
- Multi-exchange support (Binance, Kraken)
- Comprehensive test suite (65+ tests)
- Modern architecture with dependency injection
- Dark mode and accessibility support

### Previous Versions
See [CHANGELOG.md](CHANGELOG.md) for complete version history.

---

**Disclaimer**: Trading cryptocurrencies involves substantial risk and may not be suitable for all investors. Past performance does not guarantee future results. Please trade responsibly and never invest more than you can afford to lose.