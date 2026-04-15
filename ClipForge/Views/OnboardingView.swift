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
    @State private var currentPage = 0

    /// The three onboarding steps — icon, headline, and body text.
    private let pages: [(icon: String, headline: String, body: String)] = [
        ("link", "Paste a Link", "Copy a link from your favorite social app"),
        ("scissors", "Trim the Moment", "Trim to the perfect moment"),
        ("sparkles", "Create Your GIF", "Export a GIF in seconds")
    ]

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.cfBackground
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
                    body: pages[index].body
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
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.cfAccent : Color.cfTextSecondary.opacity(0.4))
                    .frame(width: 8, height: 8)
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
                .font(CFFont.jetBrainsMono(size: 15, weight: .medium))
                .foregroundStyle(Color.cfTextSecondary)
        }
        .padding(.top, 16)
        .padding(.trailing, 24)
    }

    /// "Get Started" button — shown only on the final page.
    private var getStartedButton: some View {
        Button {
            completeOnboarding()
        } label: {
            Text("Get Started")
                .font(CFFont.jetBrainsMono(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.cfAccent)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Actions

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

// MARK: - Single Onboarding Page

/// A single onboarding page: large SF Symbol, headline, and body text.
/// Extracted as its own struct to keep the parent body simple for the
/// Swift type checker.
private struct OnboardingPageView: View {

    let icon: String
    let headline: String
    let body: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Color.cfAccent)

            Text(headline)
                .font(CFFont.jetBrainsMono(size: 24, weight: .bold))
                .foregroundStyle(Color.cfTextPrimary)

            Text(body)
                .font(CFFont.inter(size: 17, weight: .regular))
                .foregroundStyle(Color.cfTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
