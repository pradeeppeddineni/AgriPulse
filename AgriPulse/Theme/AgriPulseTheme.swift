import SwiftUI
import UIKit

// MARK: - Adaptive Color Helper

private func adaptive(light: UIColor, dark: UIColor) -> Color {
    Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? dark : light
    })
}

private func hsbColor(h: CGFloat, s: CGFloat, b: CGFloat) -> UIColor {
    UIColor(hue: h / 360, saturation: s, brightness: b, alpha: 1)
}

// MARK: - Theme

enum AgriPulseTheme {

    // ── Core surfaces ──────────────────────────────────────────────

    /// Main background
    static let background = adaptive(
        light: UIColor.systemGroupedBackground,                     // #F2F2F7
        dark:  hsbColor(h: 223, s: 0.48, b: 0.05)                  // Deep navy
    )

    /// Card / elevated surface
    static let card = adaptive(
        light: .white,
        dark:  hsbColor(h: 223, s: 0.40, b: 0.08)
    )

    /// Sidebar background
    static let sidebar = adaptive(
        light: UIColor.secondarySystemGroupedBackground,
        dark:  hsbColor(h: 223, s: 0.48, b: 0.04)
    )

    /// Secondary surface (slightly raised)
    static let secondary = adaptive(
        light: UIColor(white: 0.95, alpha: 1),                     // Very light gray
        dark:  hsbColor(h: 223, s: 0.34, b: 0.13)
    )

    /// Muted surface
    static let muted = adaptive(
        light: UIColor(white: 0.93, alpha: 1),
        dark:  hsbColor(h: 223, s: 0.34, b: 0.11)
    )

    /// Accent surface
    static let accent = adaptive(
        light: UIColor(white: 0.92, alpha: 1),
        dark:  hsbColor(h: 223, s: 0.34, b: 0.14)
    )

    // ── Text ───────────────────────────────────────────────────────

    /// Primary text
    static let foreground = adaptive(
        light: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1), // #1C1C1E
        dark:  hsbColor(h: 214, s: 0.40, b: 0.95)
    )

    /// Card text (same as foreground)
    static let cardForeground = adaptive(
        light: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1),
        dark:  hsbColor(h: 214, s: 0.40, b: 0.95)
    )

    /// Muted / secondary text
    static let mutedForeground = adaptive(
        light: UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1), // #8E8E93
        dark:  hsbColor(h: 214, s: 0.14, b: 0.78)
    )

    // ── Interactive ────────────────────────────────────────────────

    /// Primary action / accent  (Apple system blue)
    static let primary = adaptive(
        light: UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1),   // #007AFF
        dark:  hsbColor(h: 210, s: 1.0, b: 0.62)
    )

    /// Text on primary backgrounds
    static let primaryForeground = adaptive(
        light: .white,
        dark:  hsbColor(h: 223, s: 0.55, b: 0.10)
    )

    /// Destructive action
    static let destructive = adaptive(
        light: UIColor.systemRed,
        dark:  UIColor(hue: 0, saturation: 0.72, brightness: 0.55, alpha: 1)
    )

    // ── Borders & dividers ─────────────────────────────────────────

    static let border = adaptive(
        light: UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1), // #E5E5EA
        dark:  hsbColor(h: 223, s: 0.30, b: 0.17)
    )

    // ── Age-level accent colors ────────────────────────────────────
    // These stay vivid in both modes — they're small accents

    static let breakingRed  = Color(red: 0.94, green: 0.26, blue: 0.21)
    static let hotAmber     = Color(red: 0.96, green: 0.68, blue: 0.10)
    static let freshEmerald = Color(red: 0.20, green: 0.83, blue: 0.50)

    // ── Category colors (calendar) ─────────────────────────────────

    static let harvestGreen  = Color.green
    static let reportBlue    = Color.blue
    static let policyViolet  = Color.purple
    static let tradeOrange   = Color.orange
    static let advisoryAmber = Color.yellow

    // ── Badge colors ───────────────────────────────────────────────

    static let indiaGreen = adaptive(
        light: UIColor(red: 0.13, green: 0.70, blue: 0.40, alpha: 1), // Slightly deeper for white bg
        dark:  UIColor(red: 0.20, green: 0.83, blue: 0.50, alpha: 1)
    )

    static let globalSky = adaptive(
        light: UIColor(red: 0.25, green: 0.52, blue: 0.90, alpha: 1), // Deeper for white bg
        dark:  UIColor(red: 0.38, green: 0.65, blue: 0.96, alpha: 1)
    )

    // ── Card shadow (light mode only) ──────────────────────────────

    static let cardShadowColor = adaptive(
        light: UIColor(white: 0, alpha: 0.06),
        dark:  UIColor.clear
    )

    static let cardShadowRadius: CGFloat = 8
}

// MARK: - Age Level

enum AgeLevel: String {
    case breaking, hot, fresh, normal, old

    var label: String {
        switch self {
        case .breaking: return "BREAKING"
        case .hot:      return "HOT"
        case .fresh:    return "FRESH"
        case .normal:   return ""
        case .old:      return ""
        }
    }

    var prefix: String {
        switch self {
        case .breaking: return "⚡ "
        case .hot:      return "🔥 "
        default:        return ""
        }
    }

    var accentColor: Color {
        switch self {
        case .breaking: return AgriPulseTheme.breakingRed
        case .hot:      return AgriPulseTheme.hotAmber
        case .fresh:    return AgriPulseTheme.freshEmerald
        case .normal:   return AgriPulseTheme.mutedForeground
        case .old:      return AgriPulseTheme.mutedForeground.opacity(0.7)
        }
    }

    var cardBackground: Color {
        switch self {
        case .breaking: return AgriPulseTheme.breakingRed.opacity(0.04)
        case .hot:      return AgriPulseTheme.hotAmber.opacity(0.03)
        case .fresh:    return AgriPulseTheme.freshEmerald.opacity(0.02)
        case .normal:   return AgriPulseTheme.card
        case .old:      return AgriPulseTheme.card.opacity(0.8)
        }
    }

    var titleOpacity: Double {
        switch self {
        case .breaking: return 1.0
        case .hot:      return 0.95
        case .fresh:    return 0.92
        case .normal:   return 0.95
        case .old:      return 0.85
        }
    }

    static func from(publishedAt: Date) -> (level: AgeLevel, label: String) {
        let diff = Date().timeIntervalSince(publishedAt)
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        let days = Int(diff / 86400)

        if days >= 1   { return (.old,      "\(days)d ago") }
        if hours >= 8  { return (.normal,   "\(hours)h ago") }
        if hours >= 2  { return (.fresh,    "\(hours)h ago") }
        if minutes >= 60 { return (.hot,    "\(hours)h ago") }
        return (.breaking, "\(minutes)m ago")
    }
}

extension EventCategory {
    var color: Color {
        switch self {
        case .harvest:  return AgriPulseTheme.harvestGreen
        case .report:   return AgriPulseTheme.reportBlue
        case .policy:   return AgriPulseTheme.policyViolet
        case .trade:    return AgriPulseTheme.tradeOrange
        case .advisory: return AgriPulseTheme.advisoryAmber
        }
    }
}
