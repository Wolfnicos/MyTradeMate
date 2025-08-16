# MyTradeMate Typography Guide

## Overview

This guide defines the standardized typography system for MyTradeMate to ensure consistent text styling, readability, and visual hierarchy across all views and components.

## Typography System

### Font Hierarchy

The typography system follows iOS Human Interface Guidelines with custom adaptations for trading app requirements:

```swift
// Primary Typography Styles
Typography.largeTitle    // 34pt, Bold, Rounded - Major headings, price displays
Typography.title1        // 28pt, Semibold, Rounded - Section titles
Typography.title2        // 22pt, Semibold, Rounded - Subsection titles
Typography.title3        // 20pt, Medium, Rounded - Card titles
Typography.headline      // 17pt, Semibold, Default - Important labels
Typography.body          // 17pt, Regular, Default - Body text
Typography.bodyMedium    // 17pt, Medium, Default - Emphasized body text
Typography.callout       // 16pt, Regular, Default - Secondary content
Typography.calloutMedium // 16pt, Medium, Default - Emphasized secondary content
Typography.subheadline   // 15pt, Regular, Default - Supporting text
Typography.subheadlineMedium // 15pt, Medium, Default - Emphasized supporting text
Typography.footnote      // 13pt, Regular, Default - Fine print
Typography.footnoteMedium // 13pt, Medium, Default - Emphasized fine print
Typography.caption1      // 12pt, Regular, Default - Captions
Typography.caption1Medium // 12pt, Medium, Default - Emphasized captions
Typography.caption2      // 11pt, Regular, Default - Small text
Typography.caption2Medium // 11pt, Medium, Default - Emphasized small text
```

### View Modifiers

Use these view modifiers for consistent styling:

```swift
Text("Large Title")
    .largeTitleStyle()

Text("Section Title")
    .title1Style()

Text("Card Title")
    .title3Style()

Text("Body Text")
    .bodyStyle()

Text("Caption")
    .caption1Style()
```

## Usage Guidelines

### 1. Navigation Titles

Use system navigation title styles for consistency:

```swift
.navigationTitle("Dashboard")
.navigationBarTitleDisplayMode(.large)
```

### 2. Price Displays

Use `largeTitleStyle()` for main price displays:

```swift
Text("$\(price)")
    .largeTitleStyle()
```

### 3. Section Headers

Use `title3Style()` or `headlineStyle()` for section headers:

```swift
Text("Open Positions")
    .title3Style()
```

### 4. Labels and Descriptions

Use appropriate hierarchy:

```swift
VStack(alignment: .leading, spacing: 4) {
    Text("Field Label")
        .footnoteMediumStyle()
    
    Text("Field Description")
        .caption1Style()
}
```

### 5. Status Indicators

Use `caption1MediumStyle()` or `caption2MediumStyle()` for status badges:

```swift
Text("DEMO")
    .caption1MediumStyle()
    .foregroundColor(.orange)
```

## Component-Specific Guidelines

### Empty States

```swift
VStack(spacing: 16) {
    Image(systemName: icon)
        .font(.system(size: 48))
    
    Text(title)
        .headlineStyle()
    
    Text(description)
        .bodyStyle()
        .multilineTextAlignment(.center)
}
```

### Toast Notifications

```swift
VStack(alignment: .leading, spacing: 4) {
    Text(title)
        .footnoteMediumStyle()
    
    Text(message)
        .caption1Style()
}
```

### Chart Labels

```swift
VStack(alignment: .leading, spacing: 2) {
    Text("Chart Title")
        .calloutMediumStyle()
    
    Text("Chart Description")
        .caption1Style()
}
```

### Settings Rows

```swift
VStack(alignment: .leading, spacing: 2) {
    Text("Setting Title")
        .bodyStyle()
    
    Text("Setting Description")
        .caption1Style()
}
```

### Trading Buttons

```swift
// Button text uses system button styles
Button("BUY") { }
    .font(.system(size: 17, weight: .bold))
```

## Color Pairing

Typography styles automatically use appropriate colors from the design system:

- Primary text: `TextColor.primary`
- Secondary text: `TextColor.secondary`
- Tertiary text: `TextColor.tertiary`

Override colors only when necessary for semantic meaning (success, error, warning).

## Accessibility

### Dynamic Type Support

All typography styles support Dynamic Type scaling. Test with different text sizes:

1. Settings > Accessibility > Display & Text Size > Larger Text
2. Enable "Larger Accessibility Sizes"
3. Test with various sizes

### VoiceOver Support

Ensure proper accessibility labels:

```swift
Text("$1,234.56")
    .largeTitleStyle()
    .accessibilityLabel("Price: One thousand two hundred thirty four dollars and fifty six cents")
```

## Migration Checklist

When updating existing components:

- [ ] Replace hardcoded font sizes with Typography constants
- [ ] Replace hardcoded font weights with Typography styles
- [ ] Use view modifiers instead of inline font modifiers
- [ ] Ensure proper color pairing with TextColor system
- [ ] Test with Dynamic Type sizes
- [ ] Verify accessibility labels

## Common Patterns

### Card Header
```swift
VStack(alignment: .leading, spacing: 4) {
    Text("Card Title")
        .title3Style()
    
    Text("Card Subtitle")
        .caption1Style()
}
```

### Form Field
```swift
VStack(alignment: .leading, spacing: 4) {
    Text("Field Label")
        .footnoteMediumStyle()
    
    TextField("Placeholder", text: $value)
        .bodyStyle()
    
    Text("Helper text")
        .caption1Style()
}
```

### Status Display
```swift
HStack(spacing: 8) {
    Circle()
        .fill(.green)
        .frame(width: 8, height: 8)
    
    Text("Connected")
        .caption1MediumStyle()
        .foregroundColor(.green)
}
```

### Price Change
```swift
HStack(spacing: 8) {
    Text("$1,234.56")
        .headlineStyle()
        .foregroundColor(.green)
    
    Text("(+2.34%)")
        .footnoteStyle()
        .foregroundColor(.green.opacity(0.8))
}
```

## Best Practices

1. **Consistency**: Always use the typography system instead of custom font definitions
2. **Hierarchy**: Maintain clear visual hierarchy with appropriate font sizes
3. **Readability**: Ensure sufficient contrast and appropriate line spacing
4. **Accessibility**: Support Dynamic Type and VoiceOver
5. **Performance**: Use view modifiers for better SwiftUI performance

## Tools and Testing

- Use Xcode's preview canvas to verify typography
- Test with different Dynamic Type sizes
- Use Accessibility Inspector to verify text rendering
- Test on different device sizes and orientations

## Future Considerations

- Monitor typography effectiveness through user testing
- Consider adding responsive typography for different screen sizes
- Evaluate font choices for trading-specific readability requirements
- Consider adding custom font families if needed for branding