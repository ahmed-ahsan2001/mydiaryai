import SwiftUI

struct AppTheme {
    static let background = Color(red: 0.97, green: 0.98, blue: 1.0)
    static let accent = Color(red: 0.57, green: 0.74, blue: 0.98)
    static let secondary = Color(red: 0.90, green: 0.81, blue: 0.97)
    static let lightPink = Color(red: 0.98, green: 0.85, blue: 0.92)
    static let lightGreen = Color(red: 0.85, green: 0.96, blue: 0.89)
    static let lightYellow = Color(red: 1.0, green: 0.98, blue: 0.82)
    static let text = Color(red: 0.25, green: 0.28, blue: 0.36)
}

extension ShapeStyle where Self == Color {
    static var appBackground: Color { AppTheme.background }
    static var appAccent: Color { AppTheme.accent }
    static var appSecondary: Color { AppTheme.secondary }
    static var appText: Color { AppTheme.text }
}


