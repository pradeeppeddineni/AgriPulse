import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct BreakingNewsProvider: TimelineProvider {
    func placeholder(in context: Context) -> BreakingNewsEntry {
        BreakingNewsEntry(
            date: Date(),
            articles: [
                .init(title: "Wheat procurement begins in Punjab", commodity: "Wheat", source: "NDTV", age: "2H AGO"),
                .init(title: "Sugar prices surge amid export restrictions", commodity: "Sugar", source: "Business Standard", age: "45M AGO"),
                .init(title: "Mustard oil demand rises in northern states", commodity: "Mustard", source: "Economic Times", age: "1H AGO"),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BreakingNewsEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BreakingNewsEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> BreakingNewsEntry {
        // Read from shared UserDefaults (App Group)
        let defaults = UserDefaults(suiteName: "group.com.agripulse.app") ?? UserDefaults.standard

        if let data = defaults.data(forKey: "widgetArticles"),
           let articles = try? JSONDecoder().decode([WidgetArticle].self, from: data) {
            return BreakingNewsEntry(date: Date(), articles: Array(articles.prefix(4)))
        }

        // Fallback: show placeholder data
        return BreakingNewsEntry(
            date: Date(),
            articles: [
                .init(title: "Open AgriPulse to see latest news", commodity: "News", source: "AgriPulse", age: "Now")
            ]
        )
    }
}

// MARK: - Data Models

struct WidgetArticle: Codable, Identifiable {
    var id: String { title }
    let title: String
    let commodity: String
    let source: String
    let age: String
}

struct BreakingNewsEntry: TimelineEntry {
    let date: Date
    let articles: [WidgetArticle]
}

// MARK: - Widget Views

struct BreakingNewsWidgetEntryView: View {
    var entry: BreakingNewsProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.blue)
                Text("AgriPulse")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            if let article = entry.articles.first {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(article.commodity)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 3))

                        Text(article.age)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Text(article.title)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(3)

                    Text(article.source)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(hue: 223/360, saturation: 0.48, brightness: 0.08)
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.blue)
                    Text("AgriPulse")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("BREAKING")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.red)
                }
                Spacer()
                Text("Updated \(entry.date.formatted(.dateTime.hour().minute()))")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Divider().overlay(Color.white.opacity(0.1))

            ForEach(Array(entry.articles.prefix(3).enumerated()), id: \.element.id) { index, article in
                HStack(alignment: .top, spacing: 8) {
                    Text(article.commodity)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.blue)
                        .frame(width: 50, alignment: .leading)
                        .lineLimit(1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(article.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Text(article.source)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text(article.age)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if index < min(entry.articles.count, 3) - 1 {
                    Divider().overlay(Color.white.opacity(0.05))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(hue: 223/360, saturation: 0.48, brightness: 0.08)
        }
    }
}

// MARK: - Widget Configuration

struct BreakingNewsWidget: Widget {
    let kind: String = "BreakingNewsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BreakingNewsProvider()) { entry in
            BreakingNewsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Breaking News")
        .description("Latest breaking commodity news from AgriPulse")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    BreakingNewsWidget()
} timeline: {
    BreakingNewsEntry(date: .now, articles: [
        .init(title: "Wheat procurement begins across Punjab mandis", commodity: "Wheat", source: "NDTV", age: "15M AGO"),
    ])
}

#Preview(as: .systemMedium) {
    BreakingNewsWidget()
} timeline: {
    BreakingNewsEntry(date: .now, articles: [
        .init(title: "Wheat procurement begins across Punjab mandis", commodity: "Wheat", source: "NDTV", age: "15M AGO"),
        .init(title: "Sugar prices surge amid new export restrictions", commodity: "Sugar", source: "Business Standard", age: "45M AGO"),
        .init(title: "Mustard oil demand rises in northern states", commodity: "Mustard", source: "Economic Times", age: "1H AGO"),
    ])
}
