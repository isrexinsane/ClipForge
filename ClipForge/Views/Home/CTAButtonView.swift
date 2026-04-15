//
//  CTAButtonView.swift
//  ClipForge
//
//  The CREATE GIF button with integrated progress ring.
//  Visual state is driven entirely by ImportState from HomeViewModel.
//
//  STORY-012: HomeView — CTA Button with Progress Ring
//

import SwiftUI

/// The main CTA button on the Home screen.
///
/// Renders as a circle with a vermillion border that transforms into
/// a progress ring during import. All visual states map 1:1 to
/// `ImportState` from the ViewModel.
struct CTAButtonView: View {

    let importState: ImportState
    let onTap: () -> Void

    /// Indeterminate spinner rotation angle.
    @State private var spinnerRotation: Double = 0

    /// Completion animation scale.
    @State private var completionScale: Double = 1.0

    // MARK: - Layout Constants

    private let buttonSize: CGFloat = 120
    private let strokeWidth: CGFloat = 5

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background track circle (always visible)
                Circle()
                    .stroke(trackColor, lineWidth: strokeWidth)
                    .frame(width: buttonSize, height: buttonSize)

                // Progress overlay
                progressOverlay

                // Inner fill for idle/detected states
                if showInnerFill {
                    Circle()
                        .fill(Color.cfAccent.opacity(innerFillOpacity))
                        .frame(width: buttonSize - strokeWidth * 2,
                               height: buttonSize - strokeWidth * 2)
                }
            }
            .scaleEffect(completionScale)
        }
        .disabled(!isInteractive)
        .onChange(of: importState) { _, newState in
            handleStateChange(newState)
        }
    }

    // MARK: - Progress Overlay

    @ViewBuilder
    private var progressOverlay: some View {
        switch importState {
        case .extracting:
            // Indeterminate: rotating partial arc
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color.cfAccent, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .frame(width: buttonSize, height: buttonSize)
                .rotationEffect(.degrees(spinnerRotation))
                .onAppear {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        spinnerRotation = 360
                    }
                }
                .onDisappear {
                    spinnerRotation = 0
                }

        case .downloading(let progress):
            // Determinate: clockwise fill from 12 o'clock
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.cfAccent, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .frame(width: buttonSize, height: buttonSize)
                .rotationEffect(.degrees(-90)) // Start from 12 o'clock
                .animation(.linear(duration: 0.15), value: progress)

        case .success:
            // Full ring
            Circle()
                .stroke(Color.cfAccent, lineWidth: strokeWidth)
                .frame(width: buttonSize, height: buttonSize)

        default:
            EmptyView()
        }
    }

    // MARK: - State-Derived Properties

    /// Track circle color — lighter when showing progress overlay.
    private var trackColor: Color {
        switch importState {
        case .extracting, .downloading:
            return Color.cfAccent.opacity(0.2)
        case .success:
            return Color.cfAccent
        default:
            return Color.cfAccent
        }
    }

    /// Whether to show the inner filled circle.
    private var showInnerFill: Bool {
        switch importState {
        case .idle, .urlDetected, .youtubeDetected, .error:
            return true
        default:
            return false
        }
    }

    /// Inner fill opacity — brighter when URL detected.
    private var innerFillOpacity: Double {
        switch importState {
        case .urlDetected:
            return 0.15
        default:
            return 0.08
        }
    }

    /// Button tappable in idle and urlDetected only.
    private var isInteractive: Bool {
        switch importState {
        case .idle, .urlDetected, .error:
            return true
        default:
            return false
        }
    }

    // MARK: - Animations

    private func handleStateChange(_ newState: ImportState) {
        if case .success = newState {
            // Brief completion pulse
            withAnimation(.easeInOut(duration: 0.25)) {
                completionScale = 1.08
            }
            withAnimation(.easeInOut(duration: 0.25).delay(0.25)) {
                completionScale = 1.0
            }
        }
    }
}

// MARK: - Label Below Button

/// The text label that appears below the CTA button.
/// Changes based on ImportState.
struct CTALabelView: View {

    let importState: ImportState

    var body: some View {
        Group {
            switch importState {
            case .idle:
                Text("CREATE GIF")
                    .font(CFFont.jetBrainsMono(size: 16))
                    .foregroundStyle(Color.cfTextPrimary)

            case .urlDetected(_, let platform):
                Text("Create from \(platform)")
                    .font(CFFont.jetBrainsMono(size: 16))
                    .foregroundStyle(Color.cfTextPrimary)

            case .extracting:
                Text("Preparing your video…")
                    .font(CFFont.inter(size: 14))
                    .foregroundStyle(Color.cfTextSecondary)

            case .downloading(let progress):
                Text("Importing… \(Int(progress * 100))%")
                    .font(CFFont.inter(size: 14))
                    .foregroundStyle(Color.cfTextSecondary)

            case .success:
                EmptyView()

            case .youtubeDetected:
                EmptyView() // Message shown via error area

            case .error:
                EmptyView() // Message shown via error area
            }
        }
    }
}

#Preview("Idle") {
    CTAButtonView(importState: .idle, onTap: {})
}

#Preview("URL Detected") {
    CTAButtonView(importState: .urlDetected(url: URL(string: "https://x.com/test/status/123")!, platform: "Twitter/X"), onTap: {})
}

#Preview("Extracting") {
    CTAButtonView(importState: .extracting, onTap: {})
}

#Preview("Downloading") {
    CTAButtonView(importState: .downloading(progress: 0.65), onTap: {})
}
