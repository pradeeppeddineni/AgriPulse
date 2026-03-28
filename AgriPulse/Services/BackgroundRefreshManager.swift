import Foundation
import BackgroundTasks
import SwiftData

@MainActor
final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    static let taskIdentifier = "com.agripulse.newsrefresh"

    private init() {}

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            Task { @MainActor in
                await self.handleRefresh(task: refreshTask)
            }
        }
    }

    func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 3600) // Every 2 hours
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Background refresh scheduling failed: \(error)")
        }
    }

    @MainActor
    private func handleRefresh(task: BGAppRefreshTask) async {
        // Schedule next refresh
        scheduleRefresh()

        do {
            let schema = Schema([Commodity.self, NewsItem.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext

            task.expirationHandler = {
                // Clean up if needed
            }

            // Capture articles before refresh to detect new ones
            let beforeDescriptor = FetchDescriptor<NewsItem>()
            let beforeCount = (try? context.fetchCount(beforeDescriptor)) ?? 0

            _ = await NewsService.shared.refreshAll(context: context)

            // Only notify if we actually added new articles
            let afterCount = (try? context.fetchCount(beforeDescriptor)) ?? 0
            if afterCount > beforeCount {
                // Find breaking articles (< 30 min old)
                let thirtyMinAgo = Date().addingTimeInterval(-30 * 60)
                let allDescriptor = FetchDescriptor<NewsItem>(
                    sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
                )
                let allItems = (try? context.fetch(allDescriptor)) ?? []
                let breakingItems = allItems.filter { $0.publishedAt > thirtyMinAgo }

                let notifications = breakingItems.map { item in
                    (title: item.title,
                     source: item.source,
                     commodity: item.commodity?.name ?? "News",
                     link: item.link,
                     publishedAt: item.publishedAt)
                }
                NotificationService.shared.notifyBreakingArticles(notifications)
            }

            // Cleanup old articles
            NewsService.shared.cleanupOldNews(context: context)
            NewsService.shared.unsaveOldArticles(days: 365, context: context)

            task.setTaskCompleted(success: true)
        } catch {
            task.setTaskCompleted(success: false)
        }
    }
}
