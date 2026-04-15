//
//  HomeView.swift
//  ClipForge
//
//  The app's landing screen. Displays the CTA button with progress
//  ring, platform list, and error messaging. Clipboard detection
//  drives button state automatically.
//
//  STORY-012: HomeView — CTA Button with Progress Ring
//

import SwiftUI

struct HomeView: View {

    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Background: warm off-white with vermillion gradient from top
            Color.cfBackground
                .ignoresSafeArea()

            LinearGradient(
                colors: [Color.cfAccent.opacity(0.15), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                // CTA button + label
                ctaSection

                Spacer()

                // Platform list
                platformList
                    .padding(.bottom, 8)

                // Error / YouTube message area
                errorArea
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            // Initial clipboard check on first launch — scenePhase
            // starts as .active so onChange won't fire until a transition.
            viewModel.clipboardMonitor.checkClipboard()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.clipboardMonitor.checkClipboard()
            }
        }
        .fullScreenCover(isPresented: $viewModel.showTrimModal) {
            if case .success(let videoURL, _) = viewModel.importState {
                TrimModalView(
                    videoURL: videoURL,
                    onDismiss: { viewModel.resetAfterExport() }
                )
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("CLIPFORGE")
                .font(CFFont.jetBrainsMono(size: 18))
                .foregroundStyle(Color.cfTextPrimary)

            Spacer()

            // Menu button — placeholder for Epic 1 menu story
            Menu {
                Button("Restore Purchase") { }
                Button("Privacy Policy") { }
                Button("About ClipForge") { }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(Color.cfTextSecondary)
            }
        }
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 16) {
            // Pulse animation for urlDetected state
            CTAButtonView(
                importState: viewModel.importState,
                onTap: { viewModel.startImport() }
            )
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: isURLDetected)

            CTALabelView(importState: viewModel.importState)
                .animation(.easeInOut(duration: 0.2), value: viewModel.importState)
        }
    }

    // MARK: - Platform List

    private var platformList: some View {
        Text("X · Instagram · Reddit · TikTok · Twitch")
            .font(CFFont.inter(size: 13))
            .foregroundStyle(Color.cfTextSecondary)
    }

    // MARK: - Error Area

    @ViewBuilder
    private var errorArea: some View {
        if let message = viewModel.errorMessage {
            Text(message)
                .font(CFFont.inter(size: 14))
                .foregroundStyle(Color.cfTextSecondary)
                .multilineTextAlignment(.center)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.3), value: viewModel.importState)

            if case .error = viewModel.importState {
                Button {
                    viewModel.retry()
                } label: {
                    Text("Try Again")
                        .font(CFFont.jetBrainsMono(size: 14))
                        .foregroundStyle(Color.cfAccent)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Helpers

    private var isURLDetected: Bool {
        if case .urlDetected = viewModel.importState { return true }
        return false
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
