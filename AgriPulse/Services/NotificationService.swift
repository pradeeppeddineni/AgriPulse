import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private static let categoryBreaking = "BREAKING_NEWS"
    private static let actionRead = "READ_ACTION"
    private static let actionSave = "SAVE_ACTION"

    private override init() {
        super.init()
    }

    // MARK: - Setup

    /// Register notification categories and set delegate. Call once at app launch.
    func setup() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let readAction = UNNotificationAction(
            identifier: Self.actionRead,
            title: "Read Article",
            options: [.foreground]
        )
        let saveAction = UNNotificationAction(
            identifier: Self.actionSave,
            title: "Save for Later",
            options: []
        )

        let breakingCategory = UNNotificationCategory(
            identifier: Self.categoryBreaking,
            actions: [readAction, saveAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "%u breaking alerts",
            options: []
        )

        center.setNotificationCategories([breakingCategory])
    }

    /// Request provisional authorization (quiet notifications, no prompt).
    /// Call on first launch — user sees notifications silently in Notification Center
    /// and can choose to "Keep" or "Turn Off".
    func requestProvisionalPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge, .provisional]
        ) { _, error in
            if let error = error {
                print("Provisional notification permission error: \(error)")
            }
        }
    }

    /// Request full permission (shows system prompt). Call after user engagement,
    /// e.g. after they tap a "Get Breaking Alerts" button or after 5th session.
    func requestFullPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    /// Upgrade from provisional to full after user shows engagement.
    /// Call after N sessions or explicit user action.
    func upgradePermissionIfNeeded() {
        let key = "notificationUpgradePrompted"
        let sessionKey = "appSessionCount"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let sessions = UserDefaults.standard.integer(forKey: sessionKey)
        guard sessions >= 3 else { return }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            // Only upgrade if currently provisional
            if settings.authorizationStatus == .provisional {
                Task { @MainActor in
                    self.requestFullPermission()
                    UserDefaults.standard.set(true, forKey: key)
                }
            }
        }
    }

    // MARK: - Sending Notifications

    /// Send a local notification for a breaking news article (< 30 min old).
    func notifyIfBreaking(title: String, source: String, commodityName: String, articleLink: String, publishedAt: Date) {
        let age = Date().timeIntervalSince(publishedAt)
        guard age < 30 * 60 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Breaking · \(commodityName)"
        content.body = title
        content.subtitle = source
        content.sound = .default
        content.categoryIdentifier = Self.categoryBreaking
        content.threadIdentifier = "commodity-\(commodityName)"
        content.userInfo = [
            "articleLink": articleLink,
            "commodityName": commodityName
        ]

        // Deterministic ID based on article link to prevent duplicates
        let id = "breaking-\(articleLink.hash)"

        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification failed: \(error)")
            }
        }
    }

    /// Send notifications for new breaking articles found during a refresh.
    /// Limits to 3 per refresh to avoid spam.
    func notifyBreakingArticles(_ articles: [(title: String, source: String, commodity: String, link: String, publishedAt: Date)]) {
        let breaking = articles
            .filter { Date().timeIntervalSince($0.publishedAt) < 30 * 60 }
            .prefix(3)

        for article in breaking {
            notifyIfBreaking(
                title: article.title,
                source: article.source,
                commodityName: article.commodity,
                articleLink: article.link,
                publishedAt: article.publishedAt
            )
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notification tap and actions
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let articleLink = userInfo["articleLink"] as? String

        switch response.actionIdentifier {
        case Self.actionRead, UNNotificationDefaultActionIdentifier:
            // Open the article
            if let link = articleLink, let url = URL(string: link) {
                Task { @MainActor in
                    UIApplication.shared.open(url)
                }
            }
        case Self.actionSave:
            // Post notification for the app to save the article
            if let link = articleLink {
                NotificationCenter.default.post(
                    name: .saveArticleFromNotification,
                    object: nil,
                    userInfo: ["articleLink": link]
                )
            }
        default:
            break
        }

        completionHandler()
    }

    /// Show notifications even when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

extension Notification.Name {
    static let saveArticleFromNotification = Notification.Name("saveArticleFromNotification")
}
