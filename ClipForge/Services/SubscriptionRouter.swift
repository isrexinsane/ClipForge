import SwiftUI

final class SubscriptionRouter: ObservableObject {
    static let shared = SubscriptionRouter()
    @Published var showSubscription = false
    private init() {}
}
