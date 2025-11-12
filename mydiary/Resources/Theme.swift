import SwiftUI

struct AppTheme {
    // Primary palette (hex: 213555, 3E5879, D8C4B6, F5EFE7)
    static let deepNavy = Color(hex: 0x213555)
    static let slateBlue = Color(hex: 0x3E5879)
    static let warmCream = Color(hex: 0xD8C4B6)
    static let softLinen = Color(hex: 0xF5EFE7)

    // Semantic aliases
    static let background = softLinen
    static let accent = slateBlue
    static let secondary = warmCream
    static let highlight = deepNavy
    static let text = Color(hex: 0x1B2B3A)
}

extension ShapeStyle where Self == Color {
    static var appBackground: Color { AppTheme.background }
    static var appAccent: Color { AppTheme.accent }
    static var appSecondary: Color { AppTheme.secondary }
    static var appText: Color { AppTheme.text }
    static var appHighlight: Color { AppTheme.highlight }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}


