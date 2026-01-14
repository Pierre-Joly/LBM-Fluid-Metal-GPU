import SwiftUI

enum ThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct AppTheme {
    let backgroundTop: Color
    let backgroundMid: Color
    let backgroundBottom: Color
    let accent: Color
    let accentSoft: Color
    let surface: Color
    let surfaceSecondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let border: Color
    let shadow: Color

    static func current(_ scheme: ColorScheme) -> AppTheme {
        switch scheme {
        case .dark:
            return AppTheme(
                backgroundTop: Color(red: 0.08, green: 0.1, blue: 0.14),
                backgroundMid: Color(red: 0.06, green: 0.09, blue: 0.12),
                backgroundBottom: Color(red: 0.04, green: 0.08, blue: 0.1),
                accent: Color(red: 0.35, green: 0.6, blue: 1.0),
                accentSoft: Color(red: 0.2, green: 0.45, blue: 0.95).opacity(0.22),
                surface: Color.white.opacity(0.06),
                surfaceSecondary: Color.white.opacity(0.1),
                textPrimary: Color.white.opacity(0.9),
                textSecondary: Color.white.opacity(0.7),
                textTertiary: Color.white.opacity(0.5),
                border: Color.white.opacity(0.12),
                shadow: Color.black.opacity(0.5)
            )
        default:
            return AppTheme(
                backgroundTop: Color(red: 0.97, green: 0.97, blue: 0.99),
                backgroundMid: Color(red: 0.94, green: 0.95, blue: 0.98),
                backgroundBottom: Color(red: 0.92, green: 0.95, blue: 0.97),
                accent: Color(red: 0.22, green: 0.52, blue: 0.96),
                accentSoft: Color(red: 0.25, green: 0.58, blue: 0.98).opacity(0.12),
                surface: Color.white.opacity(0.85),
                surfaceSecondary: Color.white.opacity(0.7),
                textPrimary: Color.black.opacity(0.88),
                textSecondary: Color.black.opacity(0.6),
                textTertiary: Color.black.opacity(0.45),
                border: Color.black.opacity(0.06),
                shadow: Color.black.opacity(0.12)
            )
        }
    }
}
