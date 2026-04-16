//
//  CTAButtonView.swift
//  ClipForge
//
//  The CREATE GIF button — a 159pt frosted glass bubble that floats
//  on top of the vermillion gradient. The circle border doubles as
//  a progress ring during video import.
//
//  Figma spec: translucent frosted circle with white highlights,
//  inner shadow at top edge, subtle glow extending ~25% beyond bounds.
//  NOT a vermillion-filled circle.
//
//  STORY-012: HomeView — CTA Button with Progress Ring
//

import SwiftUI

/// The main CTA button on the Home screen.
///
/// 159pt frosted glass bubble with layered depth effects.
/// The outer ring transforms into a progress indicator during import.
struct CTAButtonView: View {

    let importState: ImportState
    let onTap: () -> Void

    /// Indeterminate spinner rotation angle.
    @State private var spinnerRotation: Double = 0

    /// Completion animation scale.
    @State private var completionScale: Double = 1.0

    /// Breathing glow pulse opacity (idle state only).
    @State private var glowOpacity: Double = 0.3

    // MARK: - Layout Constants

    private let size: CGFloat = DesignTokens.ctaSize
    private let strokeWidth: CGFloat = DesignTokens.ctaStrokeWidth

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Layer 1: Ambient glow — blurred vermillion behind the bubble
                Circle()
                    .fill(DesignTokens.vermillion.opacity(0.3))
                    .frame(
                        width: size * (1 + DesignTokens.ctaGlowExtension),
                        height: size * (1 + DesignTokens.ctaGlowExtension)
                    )
                    .blur(radius: 30)

                // Layer 1.5: Breathing white glow pulse (idle only)
                if isIdle {
                    Circle()
                        .fill(Color.white.opacity(glowOpacity))
                        .frame(width: size + 16, height: size + 16)
                        .blur(radius: 18)
                }

                // Layer 2: Outer ring / progress track
                Circle()
                    .stroke(trackStrokeColor, lineWidth: strokeWidth)
                    .frame(width: size, height: size)

                // Layer 3: Progress arc overlay
                progressOverlay

                // Layer 4: Glass body — the frosted translucent circle
                glassBody

                // Layer 5: Inner highlight ring — white gradient at top edge
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                DesignTokens.glassHighlight,
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: size - strokeWidth * 2 - 3, height: size - strokeWidth * 2 - 3)
            }
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
            .scaleEffect(completionScale)
        }
        .disabled(!isInteractive)
        .onAppear {
            startGlowIfIdle()
        }
        .onChange(of: importState) { _, newState in
            handleStateChange(newState)
            if isIdle {
                startGlowIfIdle()
            } else {
                glowOpacity = 0.3
            }
        }
    }

    // MARK: - Glass Body

    /// The frosted glass circle: ultraThinMaterial over the gradient,
    /// with a subtle white fill and border.
    private var glassBody: some View {
        let innerSize = size - strokeWidth * 2

        return ZStack {
            // Material blur backdrop — picks up the gradient behind it
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: innerSize, height: innerSize)

            // White tint overlay for the frosted look
            Circle()
                .fill(DesignTokens.glassBackground)
                .frame(width: innerSize, height: innerSize)

            // Glass border ring
            Circle()
                .stroke(DesignTokens.glassBorder, lineWidth: 1)
                .frame(width: innerSize, height: innerSize)
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
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: strokeWidth + 1, lineCap: .round)
                )
                .frame(width: size, height: size)
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
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: strokeWidth + 1, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.15), value: progress)

        case .success:
            // Full ring — bright white
            Circle()
                .stroke(Color.white, lineWidth: strokeWidth + 1)
                .frame(width: size, height: size)

        default:
            EmptyView()
        }
    }

    // MARK: - State-Derived Properties

    /// Track ring color — fades during progress states.
    private var trackStrokeColor: Color {
        switch importState {
        case .extracting, .downloading:
            return Color.white.opacity(0.15)
        case .success:
            return Color.white
        default:
            return Color.white.opacity(0.25)
        }
    }

    /// Button tappable in idle, urlDetected, and error only.
    private var isInteractive: Bool {
        switch importState {
        case .idle, .urlDetected, .error:
            return true
        default:
            return false
        }
    }

    /// True when the button is in its resting idle state.
    private var isIdle: Bool {
        if case .idle = importState { return true }
        return false
    }

    // MARK: - Animations

    private func handleStateChange(_ newState: ImportState) {
        if case .success = newState {
            withAnimation(.easeInOut(duration: 0.25)) {
                completionScale = 1.06
            }
            withAnimation(.easeInOut(duration: 0.25).delay(0.25)) {
                completionScale = 1.0
            }
        }
    }

    /// Starts the breathing glow pulse when in idle state.
    private func startGlowIfIdle() {
        guard isIdle else { return }
        glowOpacity = 0.3
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }
    }
}

// MARK: - Label Below Button

/// Text label below the CTA button. Changes with ImportState.
struct CTALabelView: View {

    let importState: ImportState

    var body: some View {
        Group {
            switch importState {
            case .idle:
                Text("CREATE GIF")
                    .font(DesignTokens.headingFont(size: DesignTokens.ctaLabelSize))
                    .foregroundStyle(DesignTokens.textBlack)

            case .urlDetected(_, let platform):
                Text("Create from \(platform)")
                    .font(DesignTokens.headingFont(size: DesignTokens.ctaLabelSize))
                    .foregroundStyle(DesignTokens.textBlack)

            case .extracting:
                Text("Preparing your video…")
                    .font(DesignTokens.bodyFont(size: 14))
                    .foregroundStyle(DesignTokens.mutedWarm)

            case .downloading(let progress):
                Text("Importing… \(Int(progress * 100))%")
                    .font(DesignTokens.bodyFont(size: 14))
                    .foregroundStyle(DesignTokens.mutedWarm)

            case .success:
                EmptyView()

            case .youtubeDetected:
                EmptyView()

            case .error:
                EmptyView()
            }
        }
    }
}

#Preview("Idle — on gradient") {
    ZStack {
        DesignTokens.background.ignoresSafeArea()
        LinearGradient(
            stops: [
                .init(color: DesignTokens.vermillion, location: 0),
                .init(color: DesignTokens.vermillion.opacity(0), location: DesignTokens.gradientStop)
            ],
            startPoint: .top,
            endPoint: .bottom
        ).ignoresSafeArea()

        VStack(spacing: DesignTokens.paddingLarge) {
            CTAButtonView(importState: .idle, onTap: {})
            CTALabelView(importState: .idle)
        }
    }
}

#Preview("Extracting") {
    ZStack {
        DesignTokens.background.ignoresSafeArea()
        LinearGradient(
            stops: [
                .init(color: DesignTokens.vermillion, location: 0),
                .init(color: DesignTokens.vermillion.opacity(0), location: DesignTokens.gradientStop)
            ],
            startPoint: .top,
            endPoint: .bottom
        ).ignoresSafeArea()
        CTAButtonView(importState: .extracting, onTap: {})
    }
}

#Preview("Downloading") {
    ZStack {
        DesignTokens.background.ignoresSafeArea()
        CTAButtonView(importState: .downloading(progress: 0.65), onTap: {})
    }
}
