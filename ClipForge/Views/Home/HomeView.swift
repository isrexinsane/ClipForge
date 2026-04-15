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

    // Subscription sheet + restore feedback
    @State private var showSubscription = false
    @State private var restoreFeedback: String?
    @State private var showRestoreFeedback = false

    #if DEBUG
    @State private var debugURLText = ""
    #endif

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

                #if DEBUG
                // TEMPORARY: Manual URL input for Simulator testing.
                // Pasteboard sync is broken — bypasses ClipboardMonitor.
                // Remove before TestFlight / App Store builds.
                debugURLInput
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                #endif

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
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
        .overlay(alignment: .bottom) {
            if showRestoreFeedback, let message = restoreFeedback {
                Text(message)
                    .font(CFFont.jetBrainsMono(size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.cfDarkBase))
                    .padding(.bottom, 60)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.3), value: showRestoreFeedback)
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

            // Menu button (STORY-8.4)
            Menu {
                Button("Restore Purchase") {
                    Task {
                        let found = await SubscriptionManager.shared.restorePurchases()
                        restoreFeedback = found
                            ? "Purchase restored!"
                            : "No active subscription found"
                        showRestoreFeedback = true

                        try? await Task.sleep(for: .seconds(2.5))
                        showRestoreFeedback = false
                    }
                }
                Button("Privacy Policy") {
                    if let url = URL(string: "https://clipforge.app/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
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

    // MARK: - Debug URL Input

    #if DEBUG
    private var debugURLInput: some View {
        VStack(spacing: 6) {
            Text("DEBUG: Simulator clipboard workaround")
                .font(.system(size: 10))
                .foregroundStyle(.gray)

            HStack(spacing: 8) {
                TextField("Paste URL here for testing", text: $debugURLText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)

                Button {
                    let trimmed = debugURLText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let url = URL(string: trimmed),
                          (url.scheme == "http" || url.scheme == "https") else {
                        print("DEBUG: invalid URL — \"\(debugURLText)\"")
                        return
                    }

                    // Replicate the production handoff:
                    // ClipboardMonitor sets detectedURL/detectedPlatform →
                    // Combine sink sets importState → user taps CTA → startImport().
                    // We set importState directly (ClipboardMonitor props are private(set))
                    // then call startImport() — same performImport() code path.
                    let platform = SupportedPlatform.platform(forURL: url)?.displayName ?? "Unknown"
                    print("DEBUG: injecting URL into pipeline — \(url.absoluteString) (\(platform))")
                    viewModel.importState = .urlDetected(url: url, platform: platform)
                    viewModel.startImport()
                } label: {
                    Text("Test Import")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
        }
    }
    #endif

    // MARK: - Helpers

    private var isURLDetected: Bool {
        if case .urlDetected = viewModel.importState { return true }
        return false
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel())
}
