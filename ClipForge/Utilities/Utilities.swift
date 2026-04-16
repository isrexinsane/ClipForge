// Utilities: Shared helpers, extensions, and constants that don't belong in Models, Views, or Services.

import Foundation

// MARK: - App-wide Notification Names

extension Notification.Name {
    /// Posted by TrimModalView's freemium gate to request subscription presentation.
    /// ContentView listens and presents SubscriptionView via .fullScreenCover.
    static let showSubscription = Notification.Name("showSubscription")
}
