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

        // Create a temporary model container for background work
        do {
            let schema = Schema([Commodity.self, NewsItem.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = container.mainContext

            task.expirationHandler = {
                // Clean up if needed
            }

            _ = await NewsService.shared.refreshAll(context: context)

            // Cleanup old articles (365-day rolling window)
            NewsService.shared.cleanupOldNews(days: 365, context: context)
            NewsService.shared.unsaveOldArticles(days: 365, context: context)

            task.setTaskCompleted(success: true)
        } catch {
            task.setTaskCompleted(success: false)
        }
    }
}
