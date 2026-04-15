//
//  SubscriptionView.swift
//  ClipForge
//
//  Subscription purchase screen. Currently standalone — will be
//  presented from TrimModalView once the type-checker issue is
//  resolved in a dedicated wrapper view.
//
//  STORY-8.2: SubscriptionView
//

import SwiftUI

/// Purchase screen for ClipForge Premium ($9.99/year).
struct SubscriptionView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("CLIPFORGE PREMIUM")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 12) {
                    Label("Unlimited GIFs", systemImage: "infinity")
                    Label("No watermark", systemImage: "sparkles")
                    Label("Support indie development", systemImage: "heart.fill")
                }

                Text("$9.99/year")
                    .font(.title3.bold())

                Button("Subscribe") {
                    Task { await SubscriptionManager.shared.purchase() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button("Restore Purchases") {
                    Task { await SubscriptionManager.shared.restorePurchases() }
                }
                .font(.footnote)

                Button("Not Now") { dismiss() }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SubscriptionView()
}
