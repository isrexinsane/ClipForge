//
//  ContentView.swift
//  ClipForge
//
//  Root view that manages the two-page layout (Home ↔ Gallery)
//  and creates the shared HomeViewModel.
//
//  Navigation model: two swipeable pages + full-screen modal sheets.
//  See Design_Decisions §2.1.
//
//  Page indicator: CAVA-style morphing capsule. An underdamped spring
//  slides the active dot to the new position with a natural overshoot
//  bounce, giving a fluid "stretch and settle" feel without needing
//  continuous GeometryReader offset tracking.
//
//  STORY-023: Added TabView with Home and Media Library pages.
//  STORY-9.1: Onboarding fullScreenCover on first launch.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var historyStore = GIFHistoryStore.shared
    @State private var selectedPage = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            // Layer 1: Warm off-white base — extends behind Dynamic Island and home indicator
            DesignTokens.background
                .ignoresSafeArea()

            // Layer 2: Vermillion gradient — extends edge-to-edge behind everything
            LinearGradient(
                stops: [
                    .init(color: Color(red: 239/255, green: 51/255, blue: 64/255), location: 0),
                    .init(color: Color(red: 239/255, green: 51/255, blue: 64/255).opacity(0), location: 0.5225)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Layer 3: TabView with transparent page backgrounds
            TabView(selection: $selectedPage) {
                HomeView(viewModel: homeViewModel)
                    .tag(0)

                MediaLibraryView(historyStore: historyStore)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // CAVA-style morphing page indicator
            MorphingPageIndicator(currentPage: selectedPage)
                .padding(.bottom, DesignTokens.paddingSmall)
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active
                && selectedPage == 0
                && !showOnboarding
                && hasCompletedOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    homeViewModel.clipboardMonitor.startPolling()
                }
            } else if newPhase != .active {
                homeViewModel.clipboardMonitor.stopPolling()
            }
        }
        .onChange(of: selectedPage) { _, newPage in
            // Always stop immediately when leaving Home
            if newPage != 0 {
                homeViewModel.clipboardMonitor.stopPolling()
            } else {
                // Delay before starting — selectedPage can briefly
                // hit 0 during a swipe gesture before settling
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if selectedPage == 0
                        && scenePhase == .active
                        && hasCompletedOnboarding {
                        homeViewModel.clipboardMonitor.startPolling()
                    }
                }
            }
        }
        .onChange(of: showOnboarding) { _, isShowing in
            if !isShowing && hasCompletedOnboarding {
                // Onboarding just dismissed — now safe to poll
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    homeViewModel.clipboardMonitor.startPolling()
                }
            }
        }
    }
}

// MARK: - Morphing Page Indicator

/// CAVA-style page indicator with a three-phase morph animation:
///
/// 1. **STRETCH** (0ms, 120ms duration) — capsule widens from 16pt → 36pt
/// 2. **SLIDE** (80ms, spring) — capsule moves to new position (overlaps
///    with stretch ending to create "reaching toward target" look)
/// 3. **CONTRACT** (280ms, 150ms duration) — capsule shrinks back to 16pt
///
/// The spring slide has 0.7 damping for a subtle bounce at arrival.
struct MorphingPageIndicator: View {

    /// Discrete page index: 0 = Home, 1 = Gallery.
    let currentPage: Int

    // Animated state — driven by the phased onChange handler.
    @State private var indicatorOffset: CGFloat = 0
    @State private var indicatorWidth: CGFloat = DesignTokens.pageDotActive
    @State private var displayedPage: Int = 0

    // Layout constants
    private let dotSpacing: CGFloat = 24   // center-to-center
    private let restWidth: CGFloat = DesignTokens.pageDotActive    // 16pt
    private let stretchWidth: CGFloat = 36
    private let dotHeight: CGFloat = DesignTokens.pageDotInactive  // 10pt
    private let inactiveDotSize: CGFloat = DesignTokens.pageDotInactive  // 10pt

    var body: some View {
        ZStack {
            // Inactive dot at position 0 (Home / left)
            Circle()
                .fill(DesignTokens.mutedWarm)
                .frame(width: inactiveDotSize, height: inactiveDotSize)
                .offset(x: -dotSpacing / 2)
                .opacity(displayedPage == 0 ? 0 : 0.5)

            // Inactive dot at position 1 (Gallery / right)
            Circle()
                .fill(DesignTokens.mutedWarm)
                .frame(width: inactiveDotSize, height: inactiveDotSize)
                .offset(x: dotSpacing / 2)
                .opacity(displayedPage == 1 ? 0 : 0.5)

            // Active morphing capsule
            Capsule()
                .fill(DesignTokens.textBlack)
                .frame(width: indicatorWidth, height: dotHeight)
                .offset(x: indicatorOffset)
        }
        .frame(height: DesignTokens.pageDotActive) // Vertical space for largest element
        .onAppear {
            // Set initial position without animation
            displayedPage = currentPage
            indicatorOffset = currentPage == 0 ? -dotSpacing / 2 : dotSpacing / 2
            indicatorWidth = restWidth
        }
        .onChange(of: currentPage) { _, newValue in
            // Phase 1: STRETCH — fast expand (0ms start, 120ms duration)
            withAnimation(.easeOut(duration: 0.12)) {
                indicatorWidth = stretchWidth
            }

            // Phase 2: SLIDE — spring to new position (80ms start, overlaps stretch ending)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    indicatorOffset = newValue == 0 ? -dotSpacing / 2 : dotSpacing / 2
                    displayedPage = newValue
                }
            }

            // Phase 3: CONTRACT — shrink back to dot (280ms start, 150ms duration)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                withAnimation(.easeIn(duration: 0.15)) {
                    indicatorWidth = restWidth
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
