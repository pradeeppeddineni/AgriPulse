import SwiftUI

struct CommodityCalendarView: View {
    @State private var viewModel = CalendarViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Category filter chips
                filterChips

                // Calendar grid
                calendarGrid

                // Legend
                legend

                // Selected day events
                if let _ = viewModel.selectedDate {
                    selectedDayPanel
                }

                // Upcoming events
                upcomingPanel
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AgriPulseTheme.background)
        .navigationTitle("Commodity Calendar")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EventCategory.allCases) { category in
                    let active = viewModel.activeFilters.contains(category)
                    Button {
                        viewModel.toggleFilter(category)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: category.systemImage)
                                .font(.system(size: 11))
                            Text(category.label)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(active ? category.color.opacity(0.15) : Color.clear)
                        .foregroundStyle(active ? category.color : AgriPulseTheme.mutedForeground.opacity(0.4))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(active ? category.color.opacity(0.3) : AgriPulseTheme.border.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Month navigator
            HStack {
                Button { viewModel.previousMonth() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AgriPulseTheme.foreground)
                }

                Spacer()

                Text(viewModel.monthTitle)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AgriPulseTheme.foreground)

                Spacer()

                Button { viewModel.nextMonth() } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AgriPulseTheme.foreground)
                }
            }
            .padding(.horizontal, 4)

            // Day headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar cells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                // Leading padding
                ForEach(0..<viewModel.startPadding, id: \.self) { _ in
                    Color.clear
                        .frame(minHeight: 52)
                }

                ForEach(viewModel.daysInMonth, id: \.self) { day in
                    let dots = viewModel.categoryDots(for: day)
                    let isToday = viewModel.isToday(day)
                    let isSelected = viewModel.isSelected(day)

                    Button {
                        viewModel.selectedDate = day
                    } label: {
                        VStack(spacing: 4) {
                            if isToday {
                                Text("\(Calendar.current.component(.day, from: day))")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(width: 24, height: 24)
                                    .background(AgriPulseTheme.primary)
                                    .foregroundStyle(AgriPulseTheme.primaryForeground)
                                    .clipShape(Circle())
                            } else {
                                Text("\(Calendar.current.component(.day, from: day))")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(isSelected ? AgriPulseTheme.primary : AgriPulseTheme.foreground.opacity(0.8))
                            }

                            if !dots.isEmpty {
                                HStack(spacing: 2) {
                                    ForEach(dots) { cat in
                                        Circle()
                                            .fill(cat.color)
                                            .frame(width: 5, height: 5)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            isSelected
                                ? AgriPulseTheme.primary.opacity(0.15)
                                : isToday
                                    ? AgriPulseTheme.primary.opacity(0.06)
                                    : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    isSelected
                                        ? AgriPulseTheme.primary.opacity(0.5)
                                        : isToday
                                            ? AgriPulseTheme.primary.opacity(0.3)
                                            : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 12) {
            ForEach(EventCategory.allCases) { cat in
                HStack(spacing: 4) {
                    Circle()
                        .fill(cat.color)
                        .frame(width: 6, height: 6)
                    Text(cat.label)
                        .font(.system(size: 10))
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Selected Day Panel

    private var selectedDayPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isToday(viewModel.selectedDate ?? Date()) ? "Today" : "Selected")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(1)

                    if let date = viewModel.selectedDate {
                        Text(date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(AgriPulseTheme.foreground)
                    }
                }

                Spacer()

                if viewModel.selectedDateEvents.count > 0 {
                    Text("\(viewModel.selectedDateEvents.count) event\(viewModel.selectedDateEvents.count > 1 ? "s" : "")")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AgriPulseTheme.primary.opacity(0.15))
                        .foregroundStyle(AgriPulseTheme.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(16)

            Divider().overlay(AgriPulseTheme.border.opacity(0.4))

            if viewModel.selectedDateEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 32))
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.2))
                    Text("No events on this day")
                        .font(.subheadline)
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(viewModel.selectedDateEvents) { event in
                    eventRow(event)
                    if event.id != viewModel.selectedDateEvents.last?.id {
                        Divider().overlay(AgriPulseTheme.border.opacity(0.3))
                    }
                }
            }
        }
        .background(AgriPulseTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AgriPulseTheme.border.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Upcoming Panel

    private var upcomingPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(AgriPulseTheme.primary)
                Text("Upcoming Events")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AgriPulseTheme.foreground)
            }
            .padding(16)

            Divider().overlay(AgriPulseTheme.border.opacity(0.4))

            if viewModel.upcomingEvents.isEmpty {
                Text("No upcoming events")
                    .font(.subheadline)
                    .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(viewModel.upcomingEvents) { event in
                    Button {
                        viewModel.navigateTo(event: event)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: event.category.systemImage)
                                .font(.system(size: 11))
                                .padding(6)
                                .background(event.category.color.opacity(0.15))
                                .foregroundStyle(event.category.color)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AgriPulseTheme.foreground)
                                    .lineLimit(1)

                                if let commodity = event.commodity {
                                    Text(commodity)
                                        .font(.system(size: 10))
                                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))
                                }
                            }

                            Spacer()

                            Text(formatEventDate(event))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(event.category.color)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    if event.id != viewModel.upcomingEvents.last?.id {
                        Divider().overlay(AgriPulseTheme.border.opacity(0.2)).padding(.leading, 44)
                    }
                }
            }
        }
        .background(AgriPulseTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AgriPulseTheme.border.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: event.category.systemImage)
                .font(.system(size: 12))
                .padding(7)
                .background(event.category.color.opacity(0.15))
                .foregroundStyle(event.category.color)
                .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    CategoryBadge(category: event.category)
                    if let commodity = event.commodity {
                        CommodityPill(name: commodity)
                    }
                }

                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AgriPulseTheme.foreground)

                Text(event.description)
                    .font(.system(size: 12))
                    .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.7))
                    .lineSpacing(2)

                HStack(spacing: 12) {
                    if let source = event.source {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin")
                                .font(.system(size: 8))
                            Text(source)
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))
                    }

                    if event.isRange, let start = event.startDate, let end = event.endDate {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 8))
                            Text("\(start, format: .dateTime.day().month(.abbreviated)) – \(end, format: .dateTime.day().month(.abbreviated))")
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
    }

    private func formatEventDate(_ event: CalendarEvent) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        if let date = event.date {
            return formatter.string(from: date)
        }
        if let start = event.startDate {
            return "\(formatter.string(from: start)) →"
        }
        return ""
    }
}
