import Foundation
import SwiftData

@MainActor
final class NewsService {
    static let shared = NewsService()

    private init() {}

    /// Maximum article age: articles older than 30 days are skipped on fetch
    private static let maxArticleAgeDays = 30

    /// Wheat gets special 365-day retention
    private static let wheatRetentionDays = 365

    /// Fetch and filter news for a single commodity, inserting new items into SwiftData
    func refreshNews(for commodity: Commodity, context: ModelContext) async -> Int {
        let queries = commodity.searchQueries
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let indiaOnly = NewsFilterEngine.isIndiaOnly(commodity.name)
        let isGlobal = queries.contains { NewsFilterEngine.isGlobalQuery($0) }

        let articles = await RSSFetcher.shared.fetchMultipleQueries(queries, isGlobal: isGlobal)

        // Age cutoff: skip articles older than 30 days
        let ageCutoff = Calendar.current.date(byAdding: .day, value: -Self.maxArticleAgeDays, to: Date()) ?? Date()

        var insertedCount = 0
        for article in articles {
            // Skip articles that are too old
            if article.publishedAt < ageCutoff { continue }

            let fullText = "\(article.title) \(article.snippet)"
            let articleIsGlobal = !NewsFilterEngine.mentionsIndia(fullText)

            // India-only filter
            if indiaOnly && articleIsGlobal { continue }

            // Relevance filter
            if !NewsFilterEngine.isRelevant(commodityName: commodity.name, title: article.title) {
                continue
            }

            // Dedup by link
            let linkToCheck = article.link
            let linkPredicate = #Predicate<NewsItem> { $0.link == linkToCheck }
            let descriptor = FetchDescriptor<NewsItem>(predicate: linkPredicate)
            let existing = (try? context.fetchCount(descriptor)) ?? 0
            if existing > 0 { continue }

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

        return total
    }

    /// Clean up news older than 30 days (default), with Wheat getting 365-day retention
    func cleanupOldNews(context: ModelContext) {
        // General cleanup: 30 days for all non-Wheat commodities
        let cutoff30 = Calendar.current.date(byAdding: .day, value: -Self.maxArticleAgeDays, to: Date()) ?? Date()
        let generalPredicate = #Predicate<NewsItem> { $0.publishedAt < cutoff30 && !$0.isSaved }
        let generalDescriptor = FetchDescriptor<NewsItem>(predicate: generalPredicate)
        if let old = try? context.fetch(generalDescriptor) {
            for item in old {
                // Skip Wheat articles — they get longer retention
                if item.commodity?.name == "Wheat" { continue }
                context.delete(item)
            }
        }

        // Wheat-specific cleanup: 365 days
        let cutoff365 = Calendar.current.date(byAdding: .day, value: -Self.wheatRetentionDays, to: Date()) ?? Date()
        let wheatPredicate = #Predicate<NewsItem> { $0.publishedAt < cutoff365 && !$0.isSaved }
        let wheatDescriptor = FetchDescriptor<NewsItem>(predicate: wheatPredicate)
        if let old = try? context.fetch(wheatDescriptor) {
            for item in old {
                if item.commodity?.name == "Wheat" {
                    context.delete(item)
                }
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
