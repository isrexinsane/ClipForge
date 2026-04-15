//
//  SubscriptionView.swift
//  ClipForge
//
//  Subscription purchase screen. Presented as a sheet from the
//  freemium gate or from anywhere the user taps "Upgrade."
//  Shows features, price, purchase button, and restore option.
//
//  STORY-8.2: SubscriptionView
//

import SwiftUI

/// Full subscription purchase screen for ClipForge Premium.
///
/// Loads the StoreKit product on appear, displays the real price
/// from the App Store, and handles purchase/restore flows.
/// Gracefully handles the Simulator case where no product is available.
struct SubscriptionView: View {

    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss

    // Restore feedback
    @State private var restoreMessage: String?
    @State private var showRestoreMessage = false

    var body: some View {
        ZStack {
            // Background matches the app's warm off-white
            Color.cfBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Dismiss handle
                dismissHandle
                    .padding(.top, 12)

                Spacer()

                // Content
                VStack(spacing: 24) {
                    // Title
                    Text("CLIPFORGE PREMIUM")
                        .font(CFFont.jetBrainsMono(size: 24, weight: .bold))
                        .foregroundStyle(Color.cfTextPrimary)

                    // Features
                    featuresList

                    // Price
                    priceText

                    // Purchase button
                    purchaseButton

                    // Restore
                    restoreButton

                    // Legal links
                    legalLinks
                }
                .padding(.horizontal, 32)

                Spacer()

                // Not Now
                Button {
                    dismiss()
                } label: {
                    Text("Not Now")
                        .font(CFFont.inter(size: 16, weight: .medium))
                        .foregroundStyle(Color.cfTextSecondary)
                }
                .padding(.bottom, 32)
            }
        }
        .task {
            await subscriptionManager.loadProduct()
        }
        .onChange(of: subscriptionManager.purchaseState) { _, newState in
            if case .success = newState {
                // Dismiss after brief delay so user sees the checkmark
                Task {
                    try? await Task.sleep(for: .seconds(1.0))
                    dismiss()
                }
            }
        }
        .overlay {
            if showRestoreMessage, let message = restoreMessage {
                restoreFeedbackOverlay(message: message)
            }
        }
    }

    // MARK: - Dismiss Handle

    private var dismissHandle: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.cfTextSecondary.opacity(0.4))
            .frame(width: 36, height: 4)
    }

    // MARK: - Features List

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "infinity", text: "Unlimited GIFs")
            featureRow(icon: "sparkles", text: "No watermark")
            featureRow(icon: "heart.fill", text: "Support indie development")
        }
        .padding(.vertical, 16)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.cfAccent)
                .frame(width: 28)

            Text(text)
                .font(CFFont.inter(size: 17))
                .foregroundStyle(Color.cfTextPrimary)
        }
    }

    // MARK: - Price

    private var priceText: some View {
        Group {
            if let product = subscriptionManager.product {
                Text("\(product.displayPrice)/year")
                    .font(CFFont.jetBrainsMono(size: 20, weight: .bold))
                    .foregroundStyle(Color.cfTextPrimary)
            } else {
                Text("$9.99/year")
                    .font(CFFont.jetBrainsMono(size: 20, weight: .bold))
                    .foregroundStyle(Color.cfTextPrimary)
            }
        }
    }

    // MARK: - Purchase Button

    @ViewBuilder
    private var purchaseButton: some View {
        switch subscriptionManager.purchaseState {
        case .purchasing:
            ProgressView()
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(Color.cfAccent.opacity(0.6))
                )

        case .success:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                Text("You're Premium!")
                    .font(CFFont.jetBrainsMono(size: 16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color.green)
            )

        case .failed(let message):
            VStack(spacing: 8) {
                Button {
                    Task { await subscriptionManager.purchase() }
                } label: {
                    Text("Subscribe")
                        .font(CFFont.jetBrainsMono(size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(Color.cfAccent)
                        )
                }

                Text(message)
                    .font(CFFont.inter(size: 13))
                    .foregroundStyle(Color.cfError)
                    .multilineTextAlignment(.center)
            }

        case .idle:
            Button {
                Task { await subscriptionManager.purchase() }
            } label: {
                Text("Subscribe")
                    .font(CFFont.jetBrainsMono(size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 26)
                            .fill(Color.cfAccent)
                    )
            }
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task {
                let found = await subscriptionManager.restorePurchases()
                restoreMessage = found
                    ? "Purchase restored!"
                    : "No active subscription found"
                showRestoreMessage = true

                // Auto-dismiss feedback after 2 seconds
                try? await Task.sleep(for: .seconds(2.0))
                showRestoreMessage = false

                if found {
                    try? await Task.sleep(for: .seconds(0.5))
                    dismiss()
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(CFFont.inter(size: 14))
                .foregroundStyle(Color.cfAccent)
        }
    }

    // MARK: - Legal Links

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link("Privacy Policy", destination: URL(string: "https://clipforge.app/privacy")!)
                .font(CFFont.inter(size: 12))
                .foregroundStyle(Color.cfTextSecondary)

            Text("·")
                .foregroundStyle(Color.cfTextSecondary)

            Link("Terms of Service", destination: URL(string: "https://clipforge.app/terms")!)
                .font(CFFont.inter(size: 12))
                .foregroundStyle(Color.cfTextSecondary)
        }
    }

    // MARK: - Restore Feedback Overlay

    private func restoreFeedbackOverlay(message: String) -> some View {
        Text(message)
            .font(CFFont.jetBrainsMono(size: 14))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.cfDarkBase)
            )
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .animation(.easeInOut(duration: 0.3), value: showRestoreMessage)
    }
}

#Preview {
    SubscriptionView()
}
