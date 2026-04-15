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
            TabView(selection: $selectedPage) {
                HomeView(viewModel: homeViewModel)
                    .tag(0)

                MediaLibraryView(historyStore: historyStore)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // CAVA-style page dots
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .fill(index == selectedPage ? Color.cfAccent : Color.cfTextSecondary.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: selectedPage)
                }
            }
            .padding(.bottom, 8)
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
