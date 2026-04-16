//
//  UpgradeView.swift
//  ClipForge
//
//  Subscription purchase screen presented via .fullScreenCover from RootView.
//  Uses @Environment(\.dismiss) to close.
//
//  STORY-8.2: UpgradeView (formerly SubscriptionView)
//

import SwiftUI

/// Purchase screen for ClipForge Premium ($9.99/year).
/// Presented via .fullScreenCover; uses @Environment(\.dismiss) to close.
struct UpgradeView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.paddingLarge) {
                Spacer()

                Text("CLIPFORGE PREMIUM")
                    .font(DesignTokens.headingFont(size: 24))
                    .foregroundStyle(DesignTokens.textPrimary)

                VStack(alignment: .leading, spacing: DesignTokens.paddingSmall) {
                    Label {
                        Text("Unlimited GIFs")
                            .font(DesignTokens.bodyFont(size: 16))
                            .foregroundStyle(DesignTokens.textPrimary)
                    } icon: {
                        Image(systemName: "infinity")
                            .foregroundStyle(DesignTokens.vermillion)
                    }
                    Label {
                        Text("No watermark")
                            .font(DesignTokens.bodyFont(size: 16))
                            .foregroundStyle(DesignTokens.textPrimary)
                    } icon: {
                        Image(systemName: "sparkles")
                            .foregroundStyle(DesignTokens.vermillion)
                    }
                    Label {
                        Text("Support indie development")
                            .font(DesignTokens.bodyFont(size: 16))
                            .foregroundStyle(DesignTokens.textPrimary)
                    } icon: {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(DesignTokens.vermillion)
                    }
                }

                Text("$9.99/year")
                    .font(DesignTokens.headingFont(size: 28))
                    .foregroundStyle(DesignTokens.vermillion)

                Button {
                    Task {
                        await SubscriptionManager.shared.purchase()
                        dismiss()
                    }
                } label: {
                    Text("Subscribe")
                        .font(DesignTokens.labelFont(size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusButton)
                                .fill(DesignTokens.vermillion)
                        )
                }
                .padding(.horizontal, DesignTokens.paddingXLarge)

                Button {
                    Task {
                        await SubscriptionManager.shared.restorePurchases()
                        dismiss()
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(DesignTokens.bodyFont(size: 14))
                        .foregroundStyle(DesignTokens.textSecondary)
                }

                Button { dismiss() } label: {
                    Text("Not Now")
                        .font(DesignTokens.bodyFont(size: 14))
                        .foregroundStyle(DesignTokens.textSecondary)
                }

                Spacer()
            }
            .padding(DesignTokens.paddingStandard)
            .background(DesignTokens.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    UpgradeView()
}
