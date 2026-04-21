import UserNotifications
import Foundation

// ── MARK: NotificationService ─────────────────────────────────────
// Schedules a single "Theodore has something to say" nudge when the user
// accumulates 10+ new photos since their last chapter.
//
// Design principles:
// — Never more than one pending notification at a time
// — Fires at a quiet hour (9:00 AM local) the next available day
// — Respects system Do Not Disturb automatically (UNUserNotificationCenter handles this)
// — Minimal: one notification ID, re-scheduled each time new photos are detected

@MainActor
final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    static let nudgePhotoThreshold = 10
    private let notificationID = "theodore.newphotos.nudge"

    // ── MARK: Authorization ───────────────────────────────────

    /// Call once (e.g. after onboarding) to request permission.
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted ?? false
        default:
            return false
        }
    }

    // ── MARK: Schedule Nudge ──────────────────────────────────

    /// Call this when you detect ≥ threshold new photos.
    /// Re-scheduling replaces any existing pending notification.
    func scheduleNudge(newPhotoCount: Int) async {
        guard newPhotoCount >= Self.nudgePhotoThreshold else { return }

        let authorized = await requestAuthorization()
        guard authorized else { return }

        let center = UNUserNotificationCenter.current()

        // Cancel any existing nudge before re-scheduling
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])

        let content = UNMutableNotificationContent()
        content.title = "Theodore has something to say."
        content.body = nudgeBody(for: newPhotoCount)
        content.sound = .default
        content.badge = 1

        // Fire at 9:00 AM tomorrow
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    /// Call on app foreground to clear the badge counter.
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }

    /// Cancel the scheduled nudge (e.g. after user creates a new chapter).
    func cancelNudge() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID])
        clearBadge()
    }

    // ── MARK: Helpers ─────────────────────────────────────────

    private func nudgeBody(for count: Int) -> String {
        let copies = [
            "\(count) new photos. Another chapter is waiting.",
            "You've been living. Theodore's ready to write about it.",
            "\(count) moments since your last chapter. Theodore sees them.",
            "A few weeks have passed. Time to add to your autobiography.",
        ]
        return copies[count % copies.count]
    }
}
