# ToastView System Usage Guide

## Overview
The ToastView system provides a comprehensive toast notification solution for MyTradeMate with success, error, info, and warning variants.

## Components
- `ToastView`: The main toast component
- `ToastManager`: Observable object for managing toasts
- `ToastType`: Enum defining toast variants
- `Toast`: Data model for individual toasts

## Basic Usage

### 1. Add Toast Support to Your View
```swift
struct MyView: View {
    var body: some View {
        // Your view content
        VStack {
            // ... your content
        }
        .withToasts() // Add this modifier
    }
}
```

### 2. Use ToastManager in Your View
```swift
struct MyView: View {
    @EnvironmentObject var toastManager: ToastManager
    
    var body: some View {
        Button("Save Settings") {
            // Your save logic
            toastManager.showSettingsSaved()
        }
    }
}
```

## Available Toast Methods

### Generic Methods
- `showSuccess(title:message:duration:)`
- `showError(title:message:duration:)`
- `showInfo(title:message:duration:)`
- `showWarning(title:message:duration:)`

### Predefined Methods
- `showTradeExecuted(symbol:side:)`
- `showTradeExecutionFailed(error:)`
- `showSettingsSaved()`
- `showAPIKeysValidated(exchange:)`
- `showAPIKeyValidationFailed(exchange:error:)`
- `showStrategyChanged(strategy:enabled:)`
- `showDataExported(type:)`
- `showDataExportFailed(type:error:)`

## Features
- Auto-dismiss functionality (configurable duration)
- Manual dismiss with close button
- Smooth animations
- Accessibility support
- Multiple toast stacking
- Consistent styling with app theme

## Integration Examples

### Trade Execution
```swift
// Success
toastManager.showTradeExecuted(symbol: "BTC/USD", side: "buy")

// Error
toastManager.showTradeExecutionFailed(error: "Insufficient funds")
```

### Settings Changes
```swift
toastManager.showSettingsSaved()
```

### API Key Validation
```swift
// Success
toastManager.showAPIKeysValidated(exchange: "Binance")

// Error
toastManager.showAPIKeyValidationFailed(
    exchange: "Binance", 
    error: "Invalid API key format"
)
```