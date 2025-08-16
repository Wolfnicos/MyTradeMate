# MyTradeMate Spacing & Layout Guide

## Overview

This guide defines the standardized spacing and layout system for MyTradeMate to ensure consistent visual hierarchy and improved user experience across all views and components.

## Spacing System

### Base Spacing Values

```swift
struct Spacing {
    static let xxs: CGFloat = 2    // Minimal spacing for tight layouts
    static let xs: CGFloat = 4     // Extra small spacing for compact elements
    static let sm: CGFloat = 8     // Small spacing for related elements
    static let md: CGFloat = 12    // Medium-small spacing for component internal spacing
    static let lg: CGFloat = 16    // Standard spacing for most UI elements
    static let xl: CGFloat = 20    // Large spacing for section separation
    static let xxl: CGFloat = 24   // Extra large spacing for major sections
    static let xxxl: CGFloat = 32  // Maximum spacing for major layout separation
    static let huge: CGFloat = 48  // Exceptional spacing for major visual breaks
}
```

### Semantic Spacing

```swift
struct Spacing {
    // Semantic spacing for specific use cases
    static let cardPadding: CGFloat = lg        // Standard padding for cards and containers
    static let sectionSpacing: CGFloat = xl     // Standard spacing between sections
    static let elementSpacing: CGFloat = md     // Standard spacing between related elements
    static let buttonPadding: CGFloat = lg      // Standard spacing for button internal padding
    static let formSpacing: CGFloat = md        // Standard spacing for form elements
    static let listItemSpacing: CGFloat = sm    // Standard spacing for list items
}
```

## Corner Radius System

### Base Corner Radius Values

```swift
struct CornerRadius {
    static let xs: CGFloat = 4     // Small radius for compact elements
    static let sm: CGFloat = 6     // Small-medium radius for buttons and small cards
    static let md: CGFloat = 8     // Standard radius for most UI elements
    static let lg: CGFloat = 12    // Large radius for cards and containers
    static let xl: CGFloat = 16    // Extra large radius for prominent elements
    static let xxl: CGFloat = 20   // Maximum radius for special elements
}
```

## Usage Guidelines

### 1. Component Internal Spacing

Use `Spacing.md` (12pt) for internal component spacing:

```swift
VStack(spacing: Spacing.md) {
    Text("Title")
    Text("Description")
}
```

### 2. Section Separation

Use `Spacing.sectionSpacing` (20pt) for separating major sections:

```swift
VStack(spacing: Spacing.sectionSpacing) {
    headerSection
    contentSection
    footerSection
}
```

### 3. Card and Container Padding

Use `Spacing.cardPadding` (16pt) for card and container internal padding:

```swift
VStack {
    content
}
.padding(Spacing.cardPadding)
.background(Color.card)
.cornerRadius(CornerRadius.lg)
```

### 4. Form Elements

Use `Spacing.formSpacing` (12pt) for form element spacing:

```swift
VStack(spacing: Spacing.formSpacing) {
    TextField("Name", text: $name)
    TextField("Email", text: $email)
    Button("Submit") { }
}
```

### 5. List Items

Use `Spacing.listItemSpacing` (8pt) for list item internal spacing:

```swift
HStack(spacing: Spacing.listItemSpacing) {
    Image(systemName: "star")
    Text("Item")
}
```

## Component-Specific Guidelines

### Empty States

```swift
VStack(spacing: Spacing.lg) {
    Image(systemName: icon)
        .font(.system(size: 48))
    
    VStack(spacing: Spacing.sm) {
        Text(title)
        Text(description)
    }
}
.padding(Spacing.lg)
```

### Toast Notifications

```swift
HStack(spacing: Spacing.md) {
    Image(systemName: type.icon)
    
    VStack(alignment: .leading, spacing: Spacing.xs) {
        Text(title)
        Text(message)
    }
}
.padding(.horizontal, Spacing.lg)
.padding(.vertical, Spacing.md)
.cornerRadius(CornerRadius.md)
```

### Dashboard Sections

```swift
ScrollView {
    VStack(spacing: Spacing.sectionSpacing) {
        headerSection
        priceSection
        chartSection
        controlsSection
    }
    .padding(Spacing.lg)
}
```

### Settings Rows

```swift
VStack(alignment: .leading, spacing: Spacing.xs) {
    Text(title)
    Text(description)
}
.padding(.vertical, Spacing.xs)
```

## Migration Checklist

When updating existing components to use the standardized spacing system:

- [ ] Replace hardcoded spacing values with Spacing constants
- [ ] Replace hardcoded corner radius values with CornerRadius constants
- [ ] Use semantic spacing constants where appropriate
- [ ] Ensure consistent spacing hierarchy (smaller values for related elements, larger for sections)
- [ ] Test on different screen sizes to ensure proper scaling
- [ ] Verify accessibility with Dynamic Type sizes

## Common Patterns

### Card Layout
```swift
VStack(spacing: Spacing.md) {
    // Card content
}
.padding(Spacing.cardPadding)
.background(Color.card)
.cornerRadius(CornerRadius.lg)
```

### Section Header
```swift
HStack {
    VStack(alignment: .leading, spacing: Spacing.xs) {
        Text("Section Title")
        Text("Section Description")
    }
    Spacer()
}
.padding(.horizontal, Spacing.lg)
```

### Button Group
```swift
HStack(spacing: Spacing.md) {
    Button("Cancel") { }
    Button("Confirm") { }
}
```

### Form Field
```swift
VStack(alignment: .leading, spacing: Spacing.xs) {
    Text("Field Label")
    TextField("Placeholder", text: $value)
    Text("Helper text")
}
```

## Benefits

1. **Consistency**: All components use the same spacing values
2. **Maintainability**: Easy to update spacing across the entire app
3. **Accessibility**: Proper spacing improves readability and touch targets
4. **Visual Hierarchy**: Clear distinction between related and unrelated elements
5. **Responsive Design**: Consistent spacing scales well across different screen sizes

## Tools and Resources

- Use Xcode's preview canvas to verify spacing
- Test with different Dynamic Type sizes
- Use accessibility inspector to verify touch target sizes
- Consider using SwiftUI's built-in spacing modifiers where appropriate

## Future Considerations

- Consider adding responsive spacing for different screen sizes
- Evaluate spacing effectiveness through user testing
- Monitor accessibility compliance with spacing guidelines
- Consider animation timing that matches spacing rhythm