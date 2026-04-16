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
//  Page dots: active = 16pt dark/black, inactive = 10pt #968C83.
//  Home page: left dot active. Gallery page: right dot active.
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

            // Asymmetric page dots — 16pt active, 10pt inactive
            HStack(spacing: DesignTokens.paddingSmall) {
                // Home dot
                Circle()
                    .fill(selectedPage == 0 ? DesignTokens.textBlack : DesignTokens.mutedWarm)
                    .frame(
                        width: selectedPage == 0 ? DesignTokens.pageDotActive : DesignTokens.pageDotInactive,
                        height: selectedPage == 0 ? DesignTokens.pageDotActive : DesignTokens.pageDotInactive
                    )
                    .animation(.easeInOut(duration: 0.25), value: selectedPage)

                // Gallery dot
                Circle()
                    .fill(selectedPage == 1 ? DesignTokens.textBlack : DesignTokens.mutedWarm)
                    .frame(
                        width: selectedPage == 1 ? DesignTokens.pageDotActive : DesignTokens.pageDotInactive,
                        height: selectedPage == 1 ? DesignTokens.pageDotActive : DesignTokens.pageDotInactive
                    )
                    .animation(.easeInOut(duration: 0.25), value: selectedPage)
            }
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
    }
}

#Preview {
    ContentView()
}
