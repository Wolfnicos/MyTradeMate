# MyTradeMate Project Structure

This document outlines the organized directory structure of the MyTradeMate iOS application, following clean architecture principles and separation of concerns.

## Root Structure

```
MyTradeMate/
├── AI/                          # AI and Machine Learning components
├── AIModels/                    # CoreML model files
├── Core/                        # Core application infrastructure
├── Diagnostics/                 # Debugging and diagnostic tools
├── Managers/                    # Business logic managers
├── Models/                      # Data models and entities
├── Security/                    # Security-related components
├── Services/                    # External service integrations
├── Settings/                    # Application configuration
├── Strategies/                  # Trading strategy implementations
├── Tests/                       # Test files and mocks
├── Themes/                      # UI theming and styling
├── UI/                          # Reusable UI components
├── Utils/                       # Utility functions and helpers
├── ViewModels/                  # MVVM ViewModels
├── Views/                       # SwiftUI Views
├── Info.plist                   # App configuration
└── MyTradeMateApp.swift         # App entry point
```

## Detailed Directory Structure

### AI/ - Artificial Intelligence
```
AI/
├── StrategyEngine/              # AI-powered trading strategies
│   ├── StrategyManager.swift    # Strategy coordination
│   └── RSIStrategy.swift        # RSI implementation
└── FeatureBuilder.swift         # ML feature preparation
```

**Purpose**: Contains AI and machine learning components for trading signal generation.

### AIModels/ - CoreML Models
```
AIModels/
├── BitcoinAI_1h_enhanced.mlmodel
├── BitcoinAI_5m_enhanced.mlmodel
└── BTC_4H_Model.mlmodel
```

**Purpose**: Stores trained CoreML models for different timeframes.

### Core/ - Core Infrastructure
```
Core/
├── Data/                        # Data layer components
├── DependencyInjection/         # DI container and protocols
│   ├── ServiceContainer.swift   # Main DI container
│   ├── ServiceProtocols.swift   # Service interfaces
│   └── ViewModelFactory.swift   # ViewModel creation
├── Exchange/                    # Exchange client implementations
├── Trading/                     # Core trading logic
├── AppError.swift               # Error definitions
├── ErrorManager.swift           # Error handling
├── Logger.swift                 # Logging utilities
├── NavigationCoordinator.swift  # Navigation management
└── TrialManager.swift           # Trial/subscription logic
```

**Purpose**: Core application infrastructure, dependency injection, error handling, and foundational services.

### Diagnostics/ - Debugging Tools
```
Diagnostics/
├── Audit.swift                  # System audit functionality
├── CoreMLInspector.swift        # ML model inspection
└── Log.swift                    # Logging framework
```

**Purpose**: Debugging, diagnostics, and system health monitoring tools.

### Managers/ - Business Logic
```
Managers/
├── MarketPriceCache.swift       # Price caching
├── PnLManager.swift             # P&L calculations
├── RiskManager.swift            # Risk management
├── StopMonitor.swift            # Stop loss monitoring
└── TradeManager.swift           # Trade execution
```

**Purpose**: Business logic managers that coordinate between services and ViewModels.

### Models/ - Data Models
```
Models/
├── Account.swift                # Account data model
├── Candle.swift                 # OHLCV candle data
├── Exchange.swift               # Exchange enumeration
├── Order.swift                  # Order data model
├── OrderSide.swift              # Buy/Sell enumeration
├── OrderTypes.swift             # Order type definitions
├── Position.swift               # Trading position model
├── PriceTick.swift              # Price tick data
├── RiskModels.swift             # Risk management models
├── Signal.swift                 # Trading signal model
├── Symbol.swift                 # Trading symbol model
├── Ticker.swift                 # Market ticker data
├── Timeframe.swift              # Chart timeframe enum
└── TradingMode.swift            # Trading mode enum
```

**Purpose**: Data models and entities used throughout the application.

### Security/ - Security Components
```
Security/
├── KeychainStore.swift          # Secure credential storage
└── NetworkSecurityManager.swift # Network security
```

**Purpose**: Security-related functionality including credential management and network security.

### Services/ - External Services
```
Services/
├── AI/                          # AI service integrations
├── Data/                        # Data service providers
└── Exchange/                    # Exchange API clients
```

**Purpose**: External service integrations and API clients.

### Settings/ - Configuration
```
Settings/
├── AppSettings.swift            # Application settings
├── AppConfig.swift              # Configuration constants
└── SettingsValidator.swift      # Settings validation
```

**Purpose**: Application configuration, settings management, and validation.

### Strategies/ - Trading Strategies
```
Strategies/
├── Implementations/             # Concrete strategy implementations
├── Protocols/                   # Strategy interfaces
└── LegacyStrategy.swift         # Legacy strategy support
```

**Purpose**: Trading strategy implementations and protocols.

### Tests/ - Testing
```
Tests/
├── Integration/                 # Integration tests
├── Mocks/                       # Mock implementations
│   └── MockServices.swift       # Service mocks
├── UI/                          # UI tests
└── Unit/                        # Unit tests
```

**Purpose**: Test files, mocks, and testing utilities.

### Themes/ - UI Theming
```
Themes/
└── ThemeManager.swift           # Theme management
```

**Purpose**: UI theming, color schemes, and visual styling.

### UI/ - Reusable Components
```
UI/
├── Candles/                     # Candlestick UI components
└── Charts/                      # Chart components
    └── CandlestickChart.swift   # Main chart implementation
```

**Purpose**: Reusable UI components and custom controls.

### Utils/ - Utilities
```
Utils/
├── BackgroundExporter.swift     # Background export functionality
├── CSVExporter.swift            # CSV export utilities
├── CSVExporter+PnLMetrics.swift # P&L CSV extensions
├── DateFormatter+Extensions.swift # Date formatting
├── Haptics.swift                # Haptic feedback
├── JSONExporter.swift           # JSON export utilities
├── KeychainHelper.swift         # Keychain utilities
├── PnLAggregator.swift          # P&L aggregation
├── PnLCSVExporter.swift         # P&L CSV export
├── PnLMetrics.swift             # P&L calculations
└── SafeTask.swift               # Safe async task utilities
```

**Purpose**: Utility functions, extensions, and helper classes.

### ViewModels/ - MVVM ViewModels
```
ViewModels/
├── Components/                  # Reusable ViewModel components
│   ├── MarketDataManager.swift  # Market data management
│   ├── SignalManager.swift      # Signal generation
│   ├── TradingManager.swift     # Trading operations
│   ├── StrategyConfigurationManager.swift # Strategy config
│   └── RegimeDetectionManager.swift # Market regime detection
├── Dashboard/                   # Dashboard ViewModels
│   ├── DashboardVM.swift        # Legacy dashboard ViewModel
│   └── RefactoredDashboardVM.swift # Refactored dashboard
├── Settings/                    # Settings ViewModels
│   ├── ExchangeKeysViewModel.swift # API key management
│   └── SettingsVM.swift         # Settings management
├── Strategies/                  # Strategy ViewModels
│   ├── StrategiesVM.swift       # Legacy strategies ViewModel
│   ├── StrategiesViewModel.swift # Modern strategies ViewModel
│   └── RefactoredStrategiesVM.swift # Refactored strategies
├── Trading/                     # Trading ViewModels
│   ├── PnLVM.swift              # P&L ViewModel
│   ├── TradeHistoryVM.swift     # Trade history
│   └── TradesVM.swift           # Active trades
└── ViewModelMigrationGuide.md   # Migration documentation
```

**Purpose**: MVVM ViewModels organized by feature area with reusable components.

### Views/ - SwiftUI Views
```
Views/
├── Components/                  # Reusable view components
│   └── PnLWidget.swift          # P&L widget component
├── Dashboard/                   # Dashboard views
│   └── DashboardView.swift      # Main dashboard
├── Settings/                    # Settings views
│   ├── Sections/                # Settings sections
│   ├── Sheets/                  # Settings modal sheets
│   ├── SettingsView.swift       # Main settings view
│   └── ExchangeKeysView.swift   # API key management
├── Shared/                      # Shared view components
│   └── ShareSheet.swift         # System share sheet
├── Strategies/                  # Strategy views
│   └── StrategiesView.swift     # Strategy management
├── Trading/                     # Trading views
│   ├── TradesView.swift         # Active trades
│   ├── TradeHistoryView.swift   # Trade history
│   └── PnLDetailView.swift      # P&L details
├── DesignSystem.swift           # Design system components
└── RootTabs.swift               # Main tab navigation
```

**Purpose**: SwiftUI views organized by feature area.

## Architecture Principles

### 1. Separation of Concerns
- **Models**: Pure data structures
- **ViewModels**: Business logic and state management
- **Views**: UI presentation only
- **Services**: External integrations
- **Managers**: Coordinate between layers

### 2. Dependency Injection
- All services use protocol-based dependency injection
- Easy testing with mock implementations
- Centralized service registration

### 3. Feature-Based Organization
- Related files grouped by feature (Dashboard, Trading, Settings, etc.)
- Shared components in dedicated directories
- Clear boundaries between features

### 4. Clean Architecture
- Core business logic independent of UI
- External dependencies abstracted behind protocols
- Testable components with clear interfaces

## File Naming Conventions

### ViewModels
- `FeatureVM.swift` - Legacy ViewModels
- `FeatureViewModel.swift` - Modern ViewModels
- `RefactoredFeatureVM.swift` - Refactored ViewModels
- `FeatureManager.swift` - Component managers

### Views
- `FeatureView.swift` - Main feature views
- `FeatureDetailView.swift` - Detail views
- `FeatureSheet.swift` - Modal presentations

### Services
- `FeatureService.swift` - Service implementations
- `FeatureClient.swift` - API clients
- `FeatureManager.swift` - Service managers

### Models
- `Feature.swift` - Main model
- `FeatureModels.swift` - Related models
- `FeatureTypes.swift` - Enums and types

## Migration Notes

This structure represents the organized state after refactoring. Key improvements:

1. **Moved security files** to `Security/` directory
2. **Organized ViewModels** by feature with reusable components
3. **Structured Views** by feature area
4. **Centralized configuration** in `Settings/`
5. **Proper test organization** with mocks and categories
6. **Clear separation** between business logic and presentation

The structure supports:
- Easy navigation and file discovery
- Clear separation of concerns
- Testable architecture
- Future feature additions
- Team collaboration