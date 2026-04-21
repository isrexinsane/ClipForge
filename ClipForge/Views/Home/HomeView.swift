//
//  HomeView.swift
//  ClipForge
//
//  The app's landing screen. Full-screen warm off-white base with
//  a bold vermillion gradient (100% at top → 0% at 52.25% down).
//  159pt glass bubble CTA, "CLIPFORGE" in warm white, "+" menu button.
//
//  Figma layout: title top-left, + button top-right, glass CTA centered,
//  "CREATE GIF" label 20px bold black, platform list 14px bold muted,
//  page dots at bottom (rendered by ContentView).
//
//  STORY-012: HomeView — CTA Button with Progress Ring
//

import SwiftUI

struct HomeView: View {

    @ObservedObject var viewModel: HomeViewModel

    // Restore feedback
    @State private var restoreFeedback: String?
    @State private var showRestoreFeedback = false

    #if DEBUG
    @State private var debugURLText = ""
    #endif

    var body: some View {
        // Background gradient handled by ContentView — this view is transparent.
        VStack(spacing: 0) {
                // Top bar: title + menu
                topBar
                    .padding(.horizontal, DesignTokens.paddingStandard)
                    .padding(.top, 31)

                Spacer()

                // CTA section: glass bubble + label + platform list
                ctaSection

                Spacer()

                // Error / YouTube message area
                errorArea
                    .padding(.horizontal, DesignTokens.paddingXLarge)

                // Free GIF counter — subtle, above page dots
                freeGIFCounter
                    .padding(.top, DesignTokens.paddingSmall)

                #if DEBUG
                debugURLInput
                    .padding(.horizontal, DesignTokens.paddingStandard)
                    .padding(.top, DesignTokens.paddingXSmall)
                #endif

                // Reserve space for page dots rendered by ContentView
                Spacer()
                    .frame(height: DesignTokens.paddingXLarge + DesignTokens.paddingSmall)
            }
        .fullScreenCover(isPresented: $viewModel.showTrimModal) {
            if case .success(let videoURL, _) = viewModel.importState {
                TrimModalView(
                    videoURL: videoURL,
                    onDismiss: { viewModel.resetAfterExport() }
                )
            }
        }
        .overlay(alignment: .bottom) {
            restoreFeedbackToast
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Title — JetBrains Mono Bold 24px, warm white
            Text("CLIPFORGE")
                .font(DesignTokens.headingFont(size: DesignTokens.titleSize))
                .foregroundStyle(DesignTokens.textOnGradient)

            Spacer()

            // "+" menu button — 39.5pt glass circle
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
                ZStack {
                    // Glass circle backdrop
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: DesignTokens.menuButtonSize, height: DesignTokens.menuButtonSize)

                    Circle()
                        .fill(DesignTokens.glassBackground)
                        .frame(width: DesignTokens.menuButtonSize, height: DesignTokens.menuButtonSize)

                    Circle()
                        .stroke(DesignTokens.glassBorder, lineWidth: 1)
                        .frame(width: DesignTokens.menuButtonSize, height: DesignTokens.menuButtonSize)

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: DesignTokens.paddingLarge) {
            // Glass bubble CTA
            CTAButtonView(
                importState: viewModel.importState,
                onTap: { viewModel.startImport() }
            )
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: isURLDetected)

            // "CREATE GIF" label — 20px bold black
            CTALabelView(importState: viewModel.importState)
                .animation(.easeInOut(duration: 0.2), value: viewModel.importState)

            // Platform list — Inter Bold 14px, muted warm
            Text("X · Instagram · TikTok · Twitch")
                .font(DesignTokens.bodyFontBold(size: DesignTokens.platformListSize))
                .foregroundStyle(DesignTokens.mutedWarm)
        }
    }

    // MARK: - Free GIF Counter

    private var freeGIFCounter: some View {
        // TESTFLIGHT OVERRIDE — hide counter entirely
        EmptyView()
    }

    // MARK: - Error Area

    @ViewBuilder
    private var errorArea: some View {
        if let message = viewModel.errorMessage {
            Text(message)
                .font(DesignTokens.bodyFont(size: 14))
                .foregroundStyle(DesignTokens.mutedWarm)
                .multilineTextAlignment(.center)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.3), value: viewModel.importState)

            if case .error = viewModel.importState {
                Button {
                    viewModel.retry()
                } label: {
                    Text("Try Again")
                        .font(DesignTokens.labelFont(size: 14))
                        .foregroundStyle(DesignTokens.vermillion)
                }
                .padding(.top, DesignTokens.paddingXSmall)
            }
        }
    }

    // MARK: - Restore Feedback Toast

    @ViewBuilder
    private var restoreFeedbackToast: some View {
        if showRestoreFeedback, let message = restoreFeedback {
            Text(message)
                .font(DesignTokens.labelFont(size: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, DesignTokens.paddingLarge)
                .padding(.vertical, DesignTokens.paddingSmall)
                .background(Capsule().fill(DesignTokens.darkSurface))
                .padding(.bottom, 60)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.3), value: showRestoreFeedback)
        }
    }

    // MARK: - Debug URL Input

    #if DEBUG
    private var debugURLInput: some View {
        VStack(spacing: 4) {
            Text("DEBUG: Simulator paste workaround")
                .font(.system(size: 9))
                .foregroundStyle(DesignTokens.mutedWarm.opacity(0.6))

            HStack(spacing: 6) {
                TextField("Paste URL here", text: $debugURLText)
                    .font(.system(size: 11, design: .monospaced))
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
                    let platform = SupportedPlatform.platform(forURL: url)?.displayName ?? "Unknown"
                    print("DEBUG: injecting URL — \(url.absoluteString) (\(platform))")
                    viewModel.importState = .urlDetected(url: url, platform: platform)
                    viewModel.startImport()
                } label: {
                    Text("Go")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, DesignTokens.paddingXSmall)
                        .padding(.vertical, 4)
                        .background(DesignTokens.mutedWarm.opacity(0.5), in: Capsule())
                }
            }
        }
        .padding(DesignTokens.paddingXSmall)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.paddingXSmall)
                .fill(DesignTokens.surface.opacity(0.4))
        )
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
