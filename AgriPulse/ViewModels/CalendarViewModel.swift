import Foundation
import SwiftUI

@MainActor
@Observable
final class CalendarViewModel {
    var viewDate = Date()
    var selectedDate: Date? = Date()
    var activeFilters: Set<EventCategory> = Set(EventCategory.allCases)

    var filteredEvents: [CalendarEvent] {
        CalendarEvents.all.filter { activeFilters.contains($0.category) }
    }

    var selectedDateEvents: [CalendarEvent] {
        guard let date = selectedDate else { return [] }
        return filteredEvents.filter { $0.occursOn(date) }
    }

    var upcomingEvents: [CalendarEvent] {
        let now = Date()
        return filteredEvents
            .filter { $0.effectiveDate >= now }
            .sorted { $0.effectiveDate < $1.effectiveDate }
            .prefix(8)
            .map { $0 }
    }

    // Calendar grid
    var monthStart: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: viewDate)) ?? viewDate
    }

    var daysInMonth: [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: monthStart) else { return [] }
        return range.compactMap { Calendar.current.date(byAdding: .day, value: $0 - 1, to: monthStart) }
    }

    var startPadding: Int {
        Calendar.current.component(.weekday, from: monthStart) - 1 // Sunday = 0
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: viewDate)
    }

    func previousMonth() {
        viewDate = Calendar.current.date(byAdding: .month, value: -1, to: viewDate) ?? viewDate
    }

    func nextMonth() {
        viewDate = Calendar.current.date(byAdding: .month, value: 1, to: viewDate) ?? viewDate
    }

    func toggleFilter(_ category: EventCategory) {
        if activeFilters.contains(category) {
            if activeFilters.count > 1 {
                activeFilters.remove(category)
            }
        } else {
            activeFilters.insert(category)
        }
    }

    func categoryDots(for date: Date) -> [EventCategory] {
        let categories = Set(filteredEvents.filter { $0.occursOn(date) }.map { $0.category })
        return Array(categories).prefix(3).map { $0 }
    }

    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    func isSameMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: viewDate, toGranularity: .month)
    }

    func isSelected(_ date: Date) -> Bool {
        guard let selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    func navigateTo(event: CalendarEvent) {
        let d = event.date ?? event.startDate
        if let d {
            viewDate = d
            selectedDate = d
        }
    }
}
