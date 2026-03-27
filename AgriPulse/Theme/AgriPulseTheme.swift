import SwiftUI

enum AgriPulseTheme {
    // Deep Ocean Navy palette — ported from index.css :root
    static let background       = Color(hue: 223/360, saturation: 0.48, brightness: 0.05)
    static let foreground       = Color(hue: 214/360, saturation: 0.40, brightness: 0.95)
    static let card             = Color(hue: 223/360, saturation: 0.40, brightness: 0.08)
    static let cardForeground   = Color(hue: 214/360, saturation: 0.40, brightness: 0.95)
    static let primary          = Color(hue: 210/360, saturation: 1.00, brightness: 0.62)
    static let primaryForeground = Color(hue: 223/360, saturation: 0.55, brightness: 0.10)
    static let secondary        = Color(hue: 223/360, saturation: 0.34, brightness: 0.13)
    static let muted            = Color(hue: 223/360, saturation: 0.34, brightness: 0.11)
    static let mutedForeground  = Color(hue: 214/360, saturation: 0.24, brightness: 0.62)
    static let accent           = Color(hue: 223/360, saturation: 0.34, brightness: 0.14)
    static let destructive      = Color(hue: 0/360,   saturation: 0.72, brightness: 0.55)
    static let border           = Color(hue: 223/360, saturation: 0.30, brightness: 0.17)
    static let sidebar          = Color(hue: 223/360, saturation: 0.48, brightness: 0.04)

    // Age-level accent colors
    static let breakingRed      = Color(red: 0.94, green: 0.26, blue: 0.21)
    static let hotAmber         = Color(red: 0.96, green: 0.68, blue: 0.10)
    static let freshEmerald     = Color(red: 0.20, green: 0.83, blue: 0.50)

    // Category colors (calendar)
    static let harvestGreen     = Color.green
    static let reportBlue       = Color.blue
    static let policyViolet     = Color.purple
    static let tradeOrange      = Color.orange
    static let advisoryAmber    = Color.yellow

    // Badge colors
    static let indiaGreen       = Color(red: 0.20, green: 0.83, blue: 0.50)
    static let globalSky        = Color(red: 0.38, green: 0.65, blue: 0.96)
}

// Age level classification — ported from news-card.tsx
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
        case .old:      return AgriPulseTheme.mutedForeground.opacity(0.5)
        }
    }

    var cardBackground: Color {
        switch self {
        case .breaking: return AgriPulseTheme.breakingRed.opacity(0.08)
        case .hot:      return AgriPulseTheme.hotAmber.opacity(0.06)
        case .fresh:    return AgriPulseTheme.freshEmerald.opacity(0.04)
        case .normal:   return AgriPulseTheme.card
        case .old:      return AgriPulseTheme.card.opacity(0.8)
        }
    }

    var titleOpacity: Double {
        switch self {
        case .breaking: return 1.0
        case .hot:      return 0.95
        case .fresh:    return 0.92
        case .normal:   return 0.88
        case .old:      return 0.72
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
