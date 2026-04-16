import SwiftUI

struct RootView: View {
    @StateObject private var router = SubscriptionRouter.shared

    var body: some View {
        ContentView()
            .fullScreenCover(
                isPresented: $router.showSubscription,
                onDismiss: nil,
                content: {
                    UpgradeView()
                }
            )
    }
}