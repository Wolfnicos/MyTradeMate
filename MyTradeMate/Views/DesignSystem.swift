import SwiftUI

// MARK: - Colors
public struct Brand {
    static let blue = Color(light: Color(hex: "007AFF"), dark: Color(hex: "0A84FF"))
}

public struct Accent {
    static let green = Color(light: Color(hex: "34C759"), dark: Color(hex: "30D158"))
    static let red = Color(light: Color(hex: "FF3B30"), dark: Color(hex: "FF453A"))
    static let yellow = Color(light: Color(hex: "FFCC00"), dark: Color(hex: "FFD60A"))
}

public struct Bg {
    static let primary = Color(light: Color.white, dark: Color(hex: "000000"))
    static let card = Color(light: Color(hex: "F2F2F7"), dark: Color(hex: "1C1C1E"))
    static let secondary = Color(light: Color(hex: "F7F7F7"), dark: Color(hex: "2C2C2E"))
}

public struct TextColor {
    static let primary = Color(light: Color.black, dark: Color.white)
    static let secondary = Color(light: Color(hex: "8E8E93"), dark: Color(hex: "98989D"))
    static let tertiary = Color(light: Color(hex: "C7C7CC"), dark: Color(hex: "48484A"))
}

// MARK: - Typography
struct HeadingXL: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 34, weight: .bold, design: .rounded))
    }
}

struct HeadingL: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 28, weight: .semibold, design: .rounded))
    }
}

struct HeadingM: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 22, weight: .semibold, design: .rounded))
    }
}

struct BodyText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .regular, design: .default))
    }
}

struct Caption: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .regular, design: .default))
            .foregroundColor(TextColor.secondary)
    }
}

extension View {
    func headingXL() -> some View { modifier(HeadingXL()) }
    func headingL() -> some View { modifier(HeadingL()) }
    func headingM() -> some View { modifier(HeadingM()) }
    func bodyStyle() -> some View { modifier(BodyText()) }
    func captionStyle() -> some View { modifier(Caption()) }
}

// MARK: - Components

// Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Brand.blue)
                .cornerRadius(12)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
    }
}

// Danger Button
struct DangerButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Accent.red)
                .cornerRadius(12)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
    }
}

// Card Component
struct Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Bg.card)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

// Pill Component
struct Pill: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(20)
    }
}

// Segmented Pill
struct SegmentedPill<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let options: [(label: String, value: SelectionValue)]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.value) { option in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option.value
                        Haptics.playImpact(.light)
                    }
                }) {
                    Text(option.label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selection == option.value ? .white : TextColor.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selection == option.value ? Brand.blue : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Bg.secondary)
        .cornerRadius(20)
    }
}

// Status Badge
struct StatusBadge: View {
    enum Status {
        case live, demo, paper
        
        var color: Color {
            switch self {
            case .live: return Accent.green
            case .demo: return Accent.yellow
            case .paper: return Brand.blue
            }
        }
        
        var icon: String {
            switch self {
            case .live: return "circle.fill"
            case .demo: return "play.circle.fill"
            case .paper: return "doc.text.fill"
            }
        }
        
        var text: String {
            switch self {
            case .live: return "LIVE"
            case .demo: return "DEMO"
            case .paper: return "PAPER"
            }
        }
    }
    
    let status: Status
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 10))
            Text(status.text)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color)
        .cornerRadius(8)
    }
}

// Auto Switch
struct AutoSwitch: View {
    @Binding var isAuto: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAuto = false
                    Haptics.playImpact(.medium)
                }
            }) {
                Text("Manual")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(!isAuto ? .white : TextColor.primary)
                    .frame(width: 70, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(!isAuto ? Brand.blue : Color.clear)
                    )
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAuto = true
                    Haptics.playImpact(.medium)
                }
            }) {
                Text("Auto")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isAuto ? .white : TextColor.primary)
                    .frame(width: 70, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isAuto ? Accent.green : Color.clear)
                    )
            }
        }
        .padding(3)
        .background(Bg.secondary)
        .cornerRadius(17)
    }
}

// Key Value Row
struct KeyValueRow: View {
    let title: String
    let subtitle: String?
    let trailing: AnyView?
    
    init(title: String, subtitle: String? = nil, trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(TextColor.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(TextColor.secondary)
                }
            }
            
            Spacer()
            
            if let trailing = trailing {
                trailing
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    init(light: Color, dark: Color) {
        self = Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
