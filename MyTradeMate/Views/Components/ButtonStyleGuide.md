# Button Style Guide

This document outlines the standardized button system implemented in MyTradeMate to ensure consistent UI/UX across the entire application.

## Overview

The standardized button system provides:
- Consistent visual appearance across all buttons
- Standardized sizes and spacing
- Proper accessibility support
- Haptic feedback integration
- Loading and disabled states
- Trading-specific button variants

## Button Styles

### Primary Buttons
Use for main actions and primary calls-to-action.

```swift
PrimaryButton("Save Changes", icon: "checkmark", action: { /* action */ })
```

**When to use:**
- Save/Submit actions
- Primary navigation actions
- Main feature actions

### Secondary Buttons
Use for secondary actions and alternative options.

```swift
SecondaryButton("Cancel", action: { /* action */ })
```

**When to use:**
- Cancel actions
- Secondary navigation
- Alternative options

### Destructive Buttons
Use for dangerous actions that cannot be undone.

```swift
DestructiveButton("Delete Account", icon: "trash", action: { /* action */ })
```

**When to use:**
- Delete operations
- Account removal
- Irreversible actions

### Success Buttons
Use for positive actions and confirmations.

```swift
SuccessButton("Confirm", icon: "checkmark.circle", action: { /* action */ })
```

**When to use:**
- Confirmation actions
- Positive outcomes
- Success states

### Warning Buttons
Use for caution actions that require attention.

```swift
WarningButton("Proceed with Caution", icon: "exclamationmark.triangle", action: { /* action */ })
```

**When to use:**
- Warning actions
- Caution required
- Risk acknowledgment

### Ghost Buttons
Use for subtle actions and minimal interfaces.

```swift
GhostButton("Learn More", icon: "info.circle", action: { /* action */ })
```

**When to use:**
- Subtle actions
- Minimal interfaces
- Secondary information

### Outline Buttons
Use for secondary actions with more emphasis than ghost buttons.

```swift
OutlineButton("Export", icon: "square.and.arrow.up", action: { /* action */ })
```

**When to use:**
- Secondary actions
- Export/import functions
- Alternative options

## Trading-Specific Buttons

### Buy Button
Specialized button for buy trading actions.

```swift
BuyButton(
    isDisabled: false,
    isDemoMode: AppSettings.shared.demoMode,
    action: { /* buy action */ }
)
```

**Features:**
- Green color scheme
- Demo mode indicator
- Trading-specific styling

### Sell Button
Specialized button for sell trading actions.

```swift
SellButton(
    isDisabled: false,
    isDemoMode: AppSettings.shared.demoMode,
    action: { /* sell action */ }
)
```

**Features:**
- Red color scheme
- Demo mode indicator
- Trading-specific styling

## Button Sizes

### Available Sizes
- `.small` - 32pt height, for compact interfaces
- `.medium` - 44pt height, for standard interfaces
- `.large` - 50pt height, for primary actions (default)
- `.extraLarge` - 56pt height, for prominent actions

```swift
PrimaryButton("Small", size: .small, action: { /* action */ })
PrimaryButton("Medium", size: .medium, action: { /* action */ })
PrimaryButton("Large", size: .large, action: { /* action */ })
PrimaryButton("Extra Large", size: .extraLarge, action: { /* action */ })
```

## Button States

### Loading State
Show loading indicator while processing.

```swift
PrimaryButton(
    "Processing...",
    isLoading: true,
    action: { /* action */ }
)
```

### Disabled State
Disable button when action is not available.

```swift
PrimaryButton(
    "Save",
    isDisabled: !isFormValid,
    action: { /* action */ }
)
```

### Full Width
Make button expand to full container width.

```swift
PrimaryButton(
    "Continue",
    fullWidth: true,
    action: { /* action */ }
)
```

## Standard Button Component

For custom styling needs, use the `StandardButton` component:

```swift
StandardButton(
    "Custom Button",
    icon: "star.fill",
    style: .primary,
    size: .large,
    isDisabled: false,
    isLoading: false,
    fullWidth: true,
    action: { /* action */ }
)
```

## Accessibility Features

All buttons include:
- Proper accessibility labels
- VoiceOver support
- Dynamic Type support
- High contrast support
- Loading state announcements

## Haptic Feedback

Buttons automatically provide haptic feedback when:
- AppSettings.shared.haptics is enabled
- Button is tapped (not disabled or loading)
- Different intensities for different button types

## Migration from Legacy Buttons

### Before (Legacy)
```swift
Button(action: {
    // action
}) {
    Text("Save")
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(.blue)
        .cornerRadius(12)
}
```

### After (Standardized)
```swift
PrimaryButton("Save", action: {
    // action
})
```

## Best Practices

### Do's
- Use appropriate button styles for their intended purpose
- Provide clear, action-oriented labels
- Use icons to enhance understanding
- Consider button hierarchy in your layouts
- Test with different accessibility settings

### Don'ts
- Don't mix legacy button styles with standardized ones
- Don't use destructive style for non-destructive actions
- Don't create custom button styles without good reason
- Don't forget to handle loading and disabled states
- Don't ignore accessibility requirements

## Examples

### Settings Screen
```swift
VStack(spacing: 16) {
    PrimaryButton("Save Settings", icon: "checkmark", action: saveSettings)
    SecondaryButton("Reset to Defaults", action: resetSettings)
    DestructiveButton("Delete Account", icon: "trash", action: deleteAccount)
}
```

### Trading Interface
```swift
HStack(spacing: 12) {
    BuyButton(
        isDisabled: !canTrade,
        isDemoMode: AppSettings.shared.demoMode,
        action: executeBuy
    )
    
    SellButton(
        isDisabled: !canTrade,
        isDemoMode: AppSettings.shared.demoMode,
        action: executeSell
    )
}
```

### Form Actions
```swift
HStack(spacing: 12) {
    SecondaryButton("Cancel", action: dismiss)
    PrimaryButton(
        "Submit",
        isDisabled: !isFormValid,
        isLoading: isSubmitting,
        action: submitForm
    )
}
```

## Testing

Use the `ButtonStylePreview` component to test all button styles:

```swift
ButtonStylePreview()
```

This preview includes:
- All button styles and sizes
- Loading and disabled state toggles
- Interactive examples
- Trading-specific buttons

## Implementation Notes

- All buttons are built on the `StandardButton` base component
- Colors automatically adapt to light/dark mode
- Button styles follow iOS Human Interface Guidelines
- Performance optimized with minimal re-renders
- Fully compatible with SwiftUI navigation and sheets