import SwiftUI
internal import Combine

// MARK: - Theme Definition

enum AppThemeType: String, Codable, CaseIterable, Identifiable {
    case classic = "classic"
    case lightBlue = "lightBlue"
    case pink = "pink"
    case green = "green"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .lightBlue: return "Light Blue"
        case .pink: return "Pink"
        case .green: return "Green"
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .classic: return false
        case .lightBlue: return false
        case .pink: return true
        case .green: return true
        }
    }
    
    var scenicImageName: String {
        switch self {
        case .classic: return "scenicview"
        case .lightBlue: return "lightblue"
        case .pink: return "pink"
        case .green: return "lightgreen"
        }
    }
    
    var colorPalette: ThemeColorPalette {
        switch self {
        case .classic:
            return ThemeColorPalette(
                deepNavy: Color(hex: 0x213555),
                slateBlue: Color(hex: 0x3E5879),
                warmCream: Color(hex: 0xD8C4B6),
                softLinen: Color(hex: 0xF5EFE7),
                text: Color(hex: 0x1B2B3A)
            )
        case .lightBlue:
            return ThemeColorPalette(
                deepNavy: Color(hex: 0x1E3A5F),
                slateBlue: Color(hex: 0x4A90E2),
                warmCream: Color(hex: 0xB8D4E3),
                softLinen: Color(hex: 0xE8F4F8),
                text: Color(hex: 0x1A2B3C)
            )
        case .pink:
            return ThemeColorPalette(
                deepNavy: Color(hex: 0x6B2C5E),
                slateBlue: Color(hex: 0xD67AB1),
                warmCream: Color(hex: 0xF4C2D7),
                softLinen: Color(hex: 0xFCE4EC),
                text: Color(hex: 0x4A1A3D)
            )
        case .green:
            return ThemeColorPalette(
                deepNavy: Color(hex: 0x2D5016),
                slateBlue: Color(hex: 0x5A9F4F),
                warmCream: Color(hex: 0xB8E6B8),
                softLinen: Color(hex: 0xE8F5E8),
                text: Color(hex: 0x1A3A0F)
            )
        }
    }
}

struct ThemeColorPalette {
    let deepNavy: Color
    let slateBlue: Color
    let warmCream: Color
    let softLinen: Color
    let text: Color
    
    var background: Color { softLinen }
    var accent: Color { slateBlue }
    var secondary: Color { warmCream }
    var highlight: Color { deepNavy }
}

// MARK: - Theme Manager

@MainActor
final class ThemeManager: ObservableObject {
    @Published var currentTheme: AppThemeType {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selected_theme")
        }
    }
    
    private let subscriptionService: SubscriptionService
    private let themeKey = "selected_theme"
    
    var palette: ThemeColorPalette {
        currentTheme.colorPalette
    }
    
    init(subscriptionService: SubscriptionService) {
        self.subscriptionService = subscriptionService
        
        if let saved = UserDefaults.standard.string(forKey: "selected_theme"),
           let theme = AppThemeType(rawValue: saved) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .classic
        }
    }
    
    func canUseTheme(_ theme: AppThemeType) -> Bool {
        if !theme.isPremium {
            return true
        }
        return subscriptionService.isSubscribed || subscriptionService.isTrialActive
    }
    
    func setTheme(_ theme: AppThemeType) -> Bool {
        guard canUseTheme(theme) else {
            return false
        }
        currentTheme = theme
        return true
    }
}

// MARK: - Environment Key

struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue: ThemeManager? = nil
}

extension EnvironmentValues {
    var themeManager: ThemeManager? {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - Global Theme Manager Access

private var globalThemeManager: ThemeManager?

extension ThemeManager {
    static func setGlobal(_ manager: ThemeManager?) {
        globalThemeManager = manager
    }
    
    static var global: ThemeManager? {
        globalThemeManager
    }
}

// MARK: - Color Extensions

extension ShapeStyle where Self == Color {
    static var appBackground: Color {
        ThemeManager.global?.palette.background ?? AppThemeType.classic.colorPalette.background
    }
    
    static var appAccent: Color {
        ThemeManager.global?.palette.accent ?? AppThemeType.classic.colorPalette.accent
    }
    
    static var appSecondary: Color {
        ThemeManager.global?.palette.secondary ?? AppThemeType.classic.colorPalette.secondary
    }
    
    static var appText: Color {
        ThemeManager.global?.palette.text ?? AppThemeType.classic.colorPalette.text
    }
    
    static var appHighlight: Color {
        ThemeManager.global?.palette.highlight ?? AppThemeType.classic.colorPalette.highlight
    }
}

// Legacy support - keeping for backward compatibility
struct AppTheme {
    static var background: Color { .appBackground }
    static var accent: Color { .appAccent }
    static var secondary: Color { .appSecondary }
    static var highlight: Color { .appHighlight }
    static var text: Color { .appText }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}
