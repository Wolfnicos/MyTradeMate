# Widget Implementation Guide

## Overview

The MyTradeMate app includes iOS widgets that display current P&L information directly on the user's home screen. This document outlines the implementation details and usage of the widget system.

## Architecture

### Components

1. **WidgetDataManager** - Manages data sharing between the main app and widgets
2. **TradingWidget** - The main widget implementation
3. **WidgetData** - Shared data model for widget information
4. **TradingProvider** - Timeline provider for widget updates

### Data Flow

```
Main App (PnLVM) → WidgetDataManager → Shared UserDefaults → Widget
```

## Widget Sizes

### Small Widget (systemSmall)
- **Primary Display**: Total P&L with percentage
- **Secondary Info**: Today's P&L, connection status, demo mode indicator
- **Bottom Info**: Current symbol and open positions count
- **Update Frequency**: Every 2 minutes

### Medium Widget (systemMedium)
- **Left Side**: Portfolio overview with total P&L, today's P&L, positions, and connection status
- **Right Side**: Current price information, 24h change, and unrealized P&L
- **Update Frequency**: Every 2 minutes

## Data Sharing

### App Groups
The app uses App Groups to share data between the main app and widget extension:
- **Group ID**: `group.com.mytrademate.app`
- **Storage**: UserDefaults with suite name

### Shared Data Model
```swift
struct WidgetData: Codable {
    let pnl: Double              // Total P&L
    let pnlPercentage: Double    // P&L as percentage
    let todayPnL: Double         // Today's realized P&L
    let unrealizedPnL: Double    // Current unrealized P&L
    let equity: Double           // Total account equity
    let openPositions: Int       // Number of open positions
    let lastPrice: Double        // Current market price
    let priceChange: Double      // 24h price change percentage
    let isDemoMode: Bool         // Trading mode indicator
    let connectionStatus: String // Connection status
    let lastUpdated: Date        // Last update timestamp
    let symbol: String           // Current trading symbol
}
```

## Integration Points

### PnLVM Integration
The P&L view model automatically updates widget data when:
- P&L values change
- New trades are executed
- Connection status changes
- Trading mode switches

```swift
// Automatic widget updates in PnLVM.refresh()
private func updateWidgetData() {
    Task {
        let widgetData = WidgetDataManager.shared.createWidgetData(
            from: self,
            tradeManager: TradeManager.shared,
            marketPrice: marketPrice,
            priceChange: priceChange,
            isDemoMode: isDemoMode,
            isConnected: isConnected
        )
        
        WidgetDataManager.shared.updateWidgetData(widgetData)
    }
}
```

## Widget Features

### Visual Indicators
- **P&L Colors**: Green for positive, red for negative
- **Demo Mode Badge**: Orange badge when in demo mode
- **Connection Status**: Icon showing connection state
- **Position Count**: Shows number of open positions

### Refresh Functionality
- **Manual Refresh**: User-triggered refresh via settings
- **Automatic Refresh**: Configurable intervals (1min, 2min, 5min, manual)
- **Rate Limiting**: Prevents excessive refresh calls (30-second minimum)
- **Background Refresh**: Scheduled background updates
- **Status Tracking**: Monitors refresh success/failure states
- **Smart Scheduling**: Respects user configuration and battery life

### Error Handling
- **No Data**: Falls back to default values
- **Stale Data**: Shows last known values
- **Connection Issues**: Displays appropriate status
- **Refresh Failures**: Tracked and displayed in settings

## Testing

### Unit Tests
- Widget data encoding/decoding
- Data manager functionality
- Default value handling
- Singleton pattern verification

### Manual Testing
1. Add widget to home screen
2. Verify data updates when app is used
3. Test in both demo and live modes
4. Verify connection status changes
5. Test with different P&L scenarios

## Performance Considerations

### Update Frequency
- **Timeline Policy**: Updates every 2 minutes
- **Battery Impact**: Minimal due to infrequent updates
- **Data Size**: Small JSON payload (~200 bytes)

### Memory Usage
- **Shared Data**: Stored in UserDefaults
- **Widget Memory**: Minimal SwiftUI views
- **Background Processing**: None required

## Troubleshooting

### Common Issues

1. **Widget Not Updating**
   - Check App Group configuration
   - Verify UserDefaults suite name
   - Ensure WidgetCenter.reloadTimelines is called

2. **Incorrect Data Display**
   - Verify data encoding/decoding
   - Check default value fallbacks
   - Validate data transformation logic

3. **Performance Issues**
   - Monitor update frequency
   - Check for memory leaks
   - Verify background task completion

### Debug Steps
1. Check widget timeline in Xcode debugger
2. Verify shared UserDefaults data
3. Monitor widget refresh calls
4. Test with different data scenarios

## Refresh System Architecture

### Components
- **WidgetRefreshStatus**: Enum tracking refresh states (idle, refreshing, success, failed)
- **Rate Limiting**: 30-second minimum interval between refreshes
- **Background Tasks**: BGAppRefreshTask integration for background updates
- **Timer Management**: Automatic refresh scheduling based on configuration
- **Status Persistence**: Refresh statistics saved to UserDefaults

### Refresh Methods
```swift
// Manual refresh (bypasses rate limiting)
WidgetDataManager.shared.manualRefresh()

// Automatic refresh (respects rate limiting)
WidgetDataManager.shared.refreshWidgets()

// Force refresh (bypasses rate limiting)
WidgetDataManager.shared.refreshWidgets(force: true)

// Full refresh with current app state
WidgetDataManager.shared.forceFullRefresh()
```

### Configuration Integration
- **Fast Mode**: 1-minute intervals
- **Normal Mode**: 2-minute intervals (default)
- **Slow Mode**: 5-minute intervals
- **Manual Mode**: No automatic refresh

## Future Enhancements

### Planned Features
- ✅ Large widget with P&L chart
- ✅ Interactive buttons (iOS 17+)
- ✅ Multiple symbol support
- ✅ Customizable update intervals
- Dark mode optimizations

### Technical Improvements
- Real-time price change calculation
- Enhanced error handling
- Accessibility improvements
- Localization support
- ✅ Comprehensive refresh system

## Configuration

### Xcode Project Setup
1. Add App Group capability to both targets
2. Configure widget extension bundle ID
3. Set up shared UserDefaults access
4. Add WidgetKit framework

### Deployment
1. Test on physical device
2. Verify App Store Connect configuration
3. Include widget screenshots
4. Update app description with widget features