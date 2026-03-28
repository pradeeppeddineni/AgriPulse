import Foundation
import SwiftData
import WidgetKit

@MainActor
final class NewsService {
    static let shared = NewsService()

    private init() {}

    /// Default article age: 30 days
    private static let maxArticleAgeDays = 30

    /// Wheat gets special 365-day retention
    private static let wheatRetentionDays = 365

    /// Commodity-specific retention (days)
    private static func retentionDays(for name: String) -> Int {
        switch name {
        case "Wheat": return wheatRetentionDays
        case "DGFT Updates": return 90
        case "PIB Updates": return 60
        case "IMD / Advisories": return 60
        default: return maxArticleAgeDays
        }
    }

    /// Fetch and filter news for a single commodity, inserting new items into SwiftData
    func refreshNews(for commodity: Commodity, context: ModelContext) async -> Int {
        let queries = commodity.searchQueries
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let indiaOnly = NewsFilterEngine.isIndiaOnly(commodity.name)
        let isGlobal = queries.contains { NewsFilterEngine.isGlobalQuery($0) }

        let articles = await RSSFetcher.shared.fetchMultipleQueries(queries, isGlobal: isGlobal)

        // Age cutoff: commodity-specific retention
        let retDays = Self.retentionDays(for: commodity.name)
        let ageCutoff = Calendar.current.date(byAdding: .day, value: -retDays, to: Date()) ?? Date()

        var insertedCount = 0
        for article in articles {
            // Skip articles that are too old
            if article.publishedAt < ageCutoff { continue }

            let fullText = "\(article.title) \(article.snippet)"
            // Article-level India detection overrides query-level Global flag
            let mentionsIndia = NewsFilterEngine.mentionsIndia(fullText)
            let articleIsGlobal = !mentionsIndia

            // India-only filter
            if indiaOnly && articleIsGlobal { continue }

            // Relevance filter
            if !NewsFilterEngine.isRelevant(commodityName: commodity.name, title: article.title) {
                continue
            }

            // Dedup by link
            let linkToCheck = article.link
            let linkPredicate = #Predicate<NewsItem> { $0.link == linkToCheck }
            let linkDescriptor = FetchDescriptor<NewsItem>(predicate: linkPredicate)
            let existingByLink = (try? context.fetchCount(linkDescriptor)) ?? 0
            if existingByLink > 0 { continue }

            // Dedup by normalized title (same commodity) — catches Google News redirect URL variants
            let normalizedTitle = article.title
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let commodityName = commodity.name
            let titlePredicate = #Predicate<NewsItem> { $0.commodity?.name == commodityName }
            var titleDescriptor = FetchDescriptor<NewsItem>(predicate: titlePredicate)
            titleDescriptor.fetchLimit = 500
            let sameCommodityItems = (try? context.fetch(titleDescriptor)) ?? []
            let titleDuplicate = sameCommodityItems.contains { existing in
                existing.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalizedTitle
            }
            if titleDuplicate { continue }

            let newsItem = NewsItem(
                title: article.title,
                link: article.link,
                source: article.source,
                snippet: article.snippet,
                publishedAt: article.publishedAt,
                isGlobal: articleIsGlobal,
                commodity: commodity
            )
            context.insert(newsItem)
            insertedCount += 1
        }

        try? context.save()
        UserDefaults.standard.set(Date(), forKey: "lastSyncedAt")
        return insertedCount
    }

    /// Refresh news for all commodities
    func refreshAll(context: ModelContext) async -> Int {
        let descriptor = FetchDescriptor<Commodity>(sortBy: [SortDescriptor(\.sortOrder)])
        guard let commodities = try? context.fetch(descriptor) else { return 0 }

        var total = 0
        // Process in batches of 5 to avoid rate-limiting
        let batchSize = 5
        for startIndex in stride(from: 0, to: commodities.count, by: batchSize) {
            let end = min(startIndex + batchSize, commodities.count)
            let batch = Array(commodities[startIndex..<end])

            // Run batch commodities concurrently
            await withTaskGroup(of: Int.self) { group in
                for commodity in batch {
                    group.addTask { @MainActor in
                        if commodity.name == "PIB Updates" {
                            return await PIBService.shared.refreshPIBNews(for: commodity, context: context)
                        }
                        return await self.refreshNews(for: commodity, context: context)
                    }
                }
                for await count in group {
                    total += count
                }
            }
        }

        // Update widget data
        updateWidgetData(context: context)

        return total
    }

    /// Write latest breaking articles to shared UserDefaults for the widget
    func updateWidgetData(context: ModelContext) {
        let descriptor = FetchDescriptor<NewsItem>(
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
        )
        let allItems = (try? context.fetch(descriptor)) ?? []
        let recent = allItems.prefix(10)

        struct WidgetArticle: Codable {
            let title: String
            let commodity: String
            let source: String
            let age: String
        }

        let articles = recent.map { item -> WidgetArticle in
            let diff = Date().timeIntervalSince(item.publishedAt)
            let minutes = Int(diff / 60)
            let hours = Int(diff / 3600)
            let days = Int(diff / 86400)
            let age: String
            if days >= 1 { age = "\(days)D AGO" }
            else if hours >= 1 { age = "\(hours)H AGO" }
            else { age = "\(minutes)M AGO" }

            return WidgetArticle(
                title: item.title,
                commodity: item.commodity?.name ?? "News",
                source: item.source,
                age: age
            )
        }

        if let data = try? JSONEncoder().encode(Array(articles)) {
            let defaults = UserDefaults(suiteName: "group.com.agripulse.app") ?? UserDefaults.standard
            defaults.set(data, forKey: "widgetArticles")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Clean up news using commodity-specific retention periods
    func cleanupOldNews(context: ModelContext) {
        let descriptor = FetchDescriptor<NewsItem>()
        guard let allItems = try? context.fetch(descriptor) else { return }

        for item in allItems {
            guard !item.isSaved else { continue }
            let name = item.commodity?.name ?? ""
            let retDays = Self.retentionDays(for: name)
            let cutoff = Calendar.current.date(byAdding: .day, value: -retDays, to: Date()) ?? Date()
            if item.publishedAt < cutoff {
                context.delete(item)
            }
        }

        try? context.save()
    }

    /// Un-save saved articles older than N days
    func unsaveOldArticles(days: Int, context: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<NewsItem> { $0.publishedAt < cutoff && $0.isSaved }
        let descriptor = FetchDescriptor<NewsItem>(predicate: predicate)
        guard let old = try? context.fetch(descriptor) else { return }
        for item in old {
            item.isSaved = false
        }
        try? context.save()
    }
}
