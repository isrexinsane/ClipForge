//
//  OnboardingView.swift
//  ClipForge
//
//  Three-screen onboarding walkthrough shown on first launch only.
//  Uses TabView with page style for horizontal swiping.
//
//  STORY-9.1: Epic 9 — Onboarding Flow
//
//  Design: warm off-white background, vermillion icons, JetBrains Mono text.
//  Dismissal sets @AppStorage("hasCompletedOnboarding") = true so it
//  never appears again.
//

import SwiftUI

struct OnboardingView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    /// The three onboarding steps — icon, headline, and subtitle text.
    private let pages: [(icon: String, headline: String, subtitle: String)] = [
        ("link", "Paste a Link", "Copy a link from your favorite social app"),
        ("scissors", "Trim the Moment", "Trim to the perfect moment"),
        ("sparkles", "Create Your GIF", "Export a GIF in seconds")
    ]

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DesignTokens.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                pageContent
                bottomSection
            }

            skipButton
        }
    }

    // MARK: - Extracted Subviews

    /// Horizontally paged content area — one page per onboarding step.
    private var pageContent: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<pages.count, id: \.self) { index in
                OnboardingPageView(
                    icon: pages[index].icon,
                    headline: pages[index].headline,
                    subtitle: pages[index].subtitle
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxHeight: .infinity)
    }

    /// Bottom area: page dots + "Get Started" button on the last page.
    private var bottomSection: some View {
        VStack(spacing: 20) {
            pageDots

            if currentPage == pages.count - 1 {
                getStartedButton
            }
        }
        .padding(.bottom, 48)
        .animation(.easeInOut(duration: 0.2), value: currentPage)
    }

    /// CAVA-style page indicator dots.
    private var pageDots: some View {
        HStack(spacing: DesignTokens.paddingXSmall) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? DesignTokens.vermillion : DesignTokens.textSecondary.opacity(0.4))
                    .frame(width: DesignTokens.paddingXSmall, height: DesignTokens.paddingXSmall)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    /// "Skip" button — top-right, visible on every page.
    private var skipButton: some View {
        Button {
            completeOnboarding()
        } label: {
            Text("Skip")
                .font(DesignTokens.labelFont(size: 15))
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(.top, DesignTokens.paddingStandard)
        .padding(.trailing, DesignTokens.paddingLarge)
    }

    /// "Get Started" button — shown only on the final page.
    private var getStartedButton: some View {
        Button {
            completeOnboarding()
        } label: {
            Text("Get Started")
                .font(DesignTokens.headingFont(size: 17))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.paddingStandard)
                .background(DesignTokens.vermillion)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusButton))
        }
        .padding(.horizontal, DesignTokens.paddingXLarge)
    }

    // MARK: - Actions

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Single Onboarding Page

/// A single onboarding page: large SF Symbol, headline, and body text.
/// Extracted as its own struct to keep the parent body simple for the
/// Swift type checker.
private struct OnboardingPageView: View {

    let icon: String
    let headline: String
    let subtitle: String

    var body: some View {
        VStack(spacing: DesignTokens.paddingLarge) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(DesignTokens.vermillion)

            Text(headline)
                .font(DesignTokens.headingFont(size: 24))
                .foregroundStyle(DesignTokens.textPrimary)

            Text(subtitle)
                .font(DesignTokens.bodyFont(size: 17))
                .foregroundStyle(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.paddingXLarge)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
