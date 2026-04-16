//
//  ClipForgeApp.swift
//  ClipForge
//
//  Created by Rex — Ronin Art House
//  Social media video-to-GIF creation app for iOS
//

import SwiftUI

/// The main entry point for ClipForge.
/// Uses SwiftUI's App lifecycle — no UIKit AppDelegate needed.
///
/// On launch, checks StoreKit entitlements to sync premium status.
/// RootView handles subscription presentation via SubscriptionRouter.
@main
struct ClipForgeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    // Check subscription entitlements on app launch (STORY-8.3)
                    await SubscriptionManager.shared.checkEntitlements()
                }
        }
    }
}
