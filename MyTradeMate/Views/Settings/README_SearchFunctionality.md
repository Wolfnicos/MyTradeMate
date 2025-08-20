# Settings Search Functionality

## Overview
The Settings view now includes a comprehensive search/filter functionality that allows users to quickly find specific settings across all sections.

## Implementation Details

### Search Bar
- Added using SwiftUI's `.searchable()` modifier
- Prompt text: "Search settings..."
- Bound to `@State private var searchText = ""`

### Data Structure
The settings are now organized using structured data types:

#### SettingsSection
```swift
struct SettingsSection {
    let title: String
    let icon: String
    let footer: String
    let items: [SettingsItem]
}
```

#### SettingsItem
```swift
struct SettingsItem {
    let title: String
    let description: String
    let view: AnyView
}
```

### Filtering Logic
The search functionality filters settings based on:
1. **Setting title** - matches against the main setting name
2. **Setting description** - matches against the help text/description
3. **Section title** - matches against section names (Trading, Security, Diagnostics)

### Search Features
- **Case-insensitive search** - "demo" matches "Demo Mode"
- **Partial matching** - "trade" matches "Auto Trading"
- **Multi-field search** - searches across titles, descriptions, and section names
- **Real-time filtering** - results update as you type
- **Empty state handling** - shows all settings when search is empty

### Sections Included
1. **Trading Section**
   - Current Mode, Demo Mode, Auto Trading, Confirm Trades
   - Paper Trading, Live Market Data, Default Symbol/Timeframe
   - Strategy Configuration

2. **Security Section**
   - API Keys Management, Binance/Kraken Configuration
   - Dark Mode, Haptic Feedback

3. **Diagnostics Section**
   - App Version, Build Number, AI Debug Mode
   - Verbose AI Logs, PnL Demo Mode, Export Logs, System Check

### Usage Examples
- Search "demo" → Shows Demo Mode, PnL Demo Mode
- Search "api" → Shows API Keys, Binance Configuration, Kraken Configuration
- Search "trading" → Shows Trading section items like Auto Trading
- Search "dark" → Shows Dark Mode setting
- Search "export" → Shows Export Logs functionality

## Benefits
1. **Improved UX** - Users can quickly find settings without scrolling
2. **Accessibility** - Easier navigation for users with many settings
3. **Efficiency** - Reduces time to locate specific configurations
4. **Scalability** - Easy to add new settings without cluttering the interface

## Technical Notes
- Uses `localizedCaseInsensitiveContains()` for robust string matching
- Maintains original section structure when no search is active
- Preserves all original functionality while adding search capability
- No performance impact on the settings interface