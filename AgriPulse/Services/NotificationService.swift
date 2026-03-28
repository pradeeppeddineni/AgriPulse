import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    /// Send a local notification for a breaking news article (< 30 min old).
    func notifyIfBreaking(title: String, source: String, commodityName: String, publishedAt: Date) {
        let age = Date().timeIntervalSince(publishedAt)
        // Only notify for articles less than 30 minutes old
        guard age < 30 * 60 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Breaking · \(commodityName)"
        content.body = title
        content.subtitle = source
        content.sound = .default
        content.threadIdentifier = commodityName

        // Use a unique ID based on title hash to avoid duplicate notifications
        let id = "breaking-\(title.hashValue)"

        // Fire immediately
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification failed: \(error)")
            }
        }
    }

    /// Send notifications for multiple new breaking articles found during a refresh.
    func notifyBreakingArticles(_ articles: [(title: String, source: String, commodity: String, publishedAt: Date)]) {
        // Limit to 3 notifications per refresh to avoid spam
        let breaking = articles
            .filter { Date().timeIntervalSince($0.publishedAt) < 30 * 60 }
            .prefix(3)

        for article in breaking {
            notifyIfBreaking(
                title: article.title,
                source: article.source,
                commodityName: article.commodity,
                publishedAt: article.publishedAt
            )
        }
    }
}
