# Toggle Style Guide

This document outlines the standardized toggle components and their usage throughout the MyTradeMate app.

## Overview

The `StandardToggle` component provides consistent styling and behavior for all toggle controls in the app. It replaces the default SwiftUI `Toggle` to ensure visual consistency and proper haptic feedback.

## Components

### StandardToggle

The base toggle component that all other toggle variants are built upon.

```swift
StandardToggle(
    isOn: $isEnabled,
    style: .default,
    size: .medium,
    isDisabled: false,
    hapticFeedback: true
)
```

### Convenience Components

#### DefaultToggle
Standard toggle for general use cases.
```swift
DefaultToggle(isOn: $isEnabled)
```

#### ProminentToggle
Large, prominent toggle for important settings.
```swift
ProminentToggle(isOn: $isEnabled)
```

#### SuccessToggle
Green toggle for positive actions (e.g., enabling features).
```swift
SuccessToggle(isOn: $isEnabled)
```

#### WarningToggle
Yellow/orange toggle for caution actions (e.g., demo mode).
```swift
WarningToggle(isOn: $isEnabled)
```

#### DangerToggle
Red toggle for dangerous actions (e.g., verbose logging).
```swift
DangerToggle(isOn: $isEnabled)
```

#### MinimalToggle
Small, subtle toggle for less important settings.
```swift
MinimalToggle(isOn: $isEnabled)
```

### StandardToggleRow

Complete toggle row component for settings screens.

```swift
StandardToggleRow(
    title: "Auto Trading",
    description: "Allow AI to place trades automatically",
    helpText: "Detailed explanation...",
    isOn: $settings.autoTrading,
    style: .success,
    isDisabled: false,
    showDivider: true
)
```

## Style Guidelines

### When to Use Each Style

| Style | Use Case | Example |
|-------|----------|---------|
| `.default` | General settings | Haptic Feedback, Live Market Data |
| `.prominent` | Important features | Paper Trading, Key Features |
| `.success` | Positive actions | Auto Trading, Enable Strategy |
| `.warning` | Caution required | Demo Mode, Debug Settings |
| `.danger` | Risky actions | Verbose Logging, Delete Data |
| `.minimal` | Subtle settings | Dark Mode, Minor Preferences |

### Size Guidelines

| Size | Use Case | Dimensions |
|------|----------|------------|
| `.small` | Compact layouts, lists | 40x24pt |
| `.medium` | Standard settings | 50x30pt |
| `.large` | Prominent features | 60x36pt |

## Behavior Standards

### Animation
- All toggles use a consistent 0.2s ease-in-out animation
- Thumb slides smoothly between positions
- Color transitions are animated

### Haptic Feedback
- Medium impact when turning ON
- Light impact when turning OFF
- Can be disabled via `hapticFeedback: false`
- Respects user's haptic settings

### Accessibility
- Proper accessibility role (`.switch`)
- Clear accessibility values ("On"/"Off")
- Support for VoiceOver navigation
- Disabled state properly communicated

### Visual States

#### Enabled State
- Full opacity colors
- Smooth animations
- Responsive to touch

#### Disabled State
- 50% opacity for background
- 70% opacity for thumb
- No interaction or animation
- Grayed out appearance

## Implementation Examples

### Settings Screen
```swift
// Trading settings with appropriate styles
StandardToggleRow(
    title: "Demo Mode",
    description: "Use simulated trading environment",
    isOn: $settings.demoMode,
    style: .warning  // Warning style for demo mode
)

StandardToggleRow(
    title: "Auto Trading",
    description: "Allow AI to place trades automatically",
    isOn: $settings.autoTrading,
    style: .success  // Success style for positive action
)
```

### Strategy List
```swift
// Dynamic style based on state
StandardToggle(
    isOn: $strategy.isEnabled,
    style: strategy.isEnabled ? .success : .default,
    size: .medium
)
```

### Compact Layout
```swift
// Minimal toggle for space-constrained areas
MinimalToggle(isOn: $setting.isEnabled)
```

## Migration Guide

### From SwiftUI Toggle
```swift
// Old
Toggle("Setting", isOn: $isEnabled)
    .labelsHidden()

// New
StandardToggle(isOn: $isEnabled, style: .default)
```

### From Custom Toggle
```swift
// Old
Button(action: { isEnabled.toggle() }) {
    // Custom toggle implementation
}

// New
StandardToggle(
    isOn: $isEnabled,
    style: .default,
    hapticFeedback: true
)
```

## Testing

### Visual Testing
- Test all styles in light and dark mode
- Verify animations are smooth
- Check disabled states
- Ensure proper contrast ratios

### Interaction Testing
- Verify haptic feedback works
- Test accessibility with VoiceOver
- Confirm proper state changes
- Test disabled state behavior

### Performance Testing
- Ensure smooth animations on older devices
- Verify no memory leaks
- Test with large lists of toggles

## Best Practices

1. **Consistent Styling**: Always use the appropriate style for the context
2. **Clear Labels**: Provide descriptive titles and descriptions
3. **Help Text**: Include help text for complex settings
4. **Proper Grouping**: Group related toggles in sections
5. **State Management**: Ensure toggle state reflects actual app state
6. **Accessibility**: Always test with VoiceOver enabled
7. **Performance**: Use appropriate sizes for the context

## Common Patterns

### Settings Section
```swift
Section("Trading") {
    StandardToggleRow(
        title: "Demo Mode",
        description: "Use simulated environment",
        isOn: $settings.demoMode,
        style: .warning
    )
    
    StandardToggleRow(
        title: "Auto Trading",
        description: "Enable automatic trading",
        isOn: $settings.autoTrading,
        style: .success,
        isDisabled: settings.demoMode
    )
}
```

### Strategy Card
```swift
HStack {
    VStack(alignment: .leading) {
        Text(strategy.name)
        Text(strategy.description)
    }
    
    Spacer()
    
    StandardToggle(
        isOn: $strategy.isEnabled,
        style: strategy.isEnabled ? .success : .default
    )
}
```

## Troubleshooting

### Common Issues

1. **Toggle not responding**: Check if `isDisabled` is set correctly
2. **No haptic feedback**: Verify user has haptics enabled in settings
3. **Animation stuttering**: Ensure binding is properly connected
4. **Accessibility issues**: Add proper labels and hints

### Debug Tips

1. Use the preview to test different states
2. Test on actual device for haptic feedback
3. Use Accessibility Inspector for VoiceOver testing
4. Check console for any binding warnings