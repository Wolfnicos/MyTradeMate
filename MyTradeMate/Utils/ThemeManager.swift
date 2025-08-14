import SwiftUI

final class ThemeManager: ObservableObject {
    @Published var useDark: Bool = false
    var colorScheme: ColorScheme? { useDark ? .dark : .light }
    var accent: Color { .blue }
}
