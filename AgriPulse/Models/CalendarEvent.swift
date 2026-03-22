import Foundation

enum EventCategory: String, CaseIterable, Identifiable {
    case harvest
    case report
    case policy
    case trade
    case advisory

    var id: String { rawValue }

    var label: String {
        switch self {
        case .harvest:  return "Harvest Season"
        case .report:   return "Trade Report"
        case .policy:   return "Policy Event"
        case .trade:    return "Market Event"
        case .advisory: return "IMD / Advisory"
        }
    }

    var systemImage: String {
        switch self {
        case .harvest:  return "leaf.fill"
        case .report:   return "chart.bar.fill"
        case .policy:   return "scroll.fill"
        case .trade:    return "arrow.up.right"
        case .advisory: return "cloud.sun.fill"
        }
    }
}

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let date: Date?
    let startDate: Date?
    let endDate: Date?
    let category: EventCategory
    let commodity: String?
    let description: String
    let source: String?

    var effectiveDate: Date {
        date ?? startDate ?? Date()
    }

    var isRange: Bool {
        startDate != nil && endDate != nil
    }

    func occursOn(_ day: Date) -> Bool {
        let calendar = Calendar.current
        if let date {
            return calendar.isDate(date, inSameDayAs: day)
        }
        if let start = startDate, let end = endDate {
            return day >= calendar.startOfDay(for: start) && day <= calendar.startOfDay(for: end)
        }
        return false
    }
}
