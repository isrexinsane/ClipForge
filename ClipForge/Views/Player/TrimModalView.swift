//
//  TrimModalView.swift
//  ClipForge
//
//  Full-screen modal for video playback, trimming, encoding progress,
//  and export success. Houses the entire create-GIF flow as in-modal
//  state transitions.
//
//  STORY-013: VideoPlayerManager + Trim Modal Shell
//  STORY-016: TrimBarView integration
//  STORY-017: Duration Readout and Color Warnings
//  STORY-020: ExportViewModel integration — encoding progress ring
//  STORY-022: Export success state — GIF preview, share, done
//

import SwiftUI
import AVKit
import AVFoundation

/// Full-screen modal presented after a successful video import.
///
/// Displays the video player edge-to-edge on a black background,
/// with volume toggle (top-left), cancel button (top-right),
/// trim bar with filmstrip thumbnails, duration readout with
/// color warnings, CREATE button, encoding progress, and export
/// success state.
struct TrimModalView: View {

    @StateObject private var playerManager: VideoPlayerManager
    @StateObject private var filmstripGenerator = FilmstripGenerator()
    @StateObject private var exportViewModel = ExportViewModel()
    @ObservedObject private var gatekeeper: FreemiumGatekeeper
    let videoURL: URL
    let onDismiss: () -> Void

    // TrimViewModel created once playerManager.duration is available
    @State private var trimViewModel: TrimViewModel?

    // Share sheet presentation
    @State private var showShareSheet = false
    @State private var shareFileURL: URL?

    // Freemium gate prompt
    @State private var showFreemiumGate = false

    /// Creates the Trim Modal for a given local video file.
    ///
    /// - Parameters:
    ///   - videoURL: Local file URL in the Caches directory.
    ///   - onDismiss: Called when the user taps Cancel.
    init(videoURL: URL, onDismiss: @escaping () -> Void) {
        self.videoURL = videoURL
        self._playerManager = StateObject(wrappedValue: VideoPlayerManager(videoURL: videoURL))
        self._gatekeeper = ObservedObject(wrappedValue: FreemiumGatekeeper.shared)
        self.onDismiss = onDismiss
    }

    var body: some View {
        trimModalContent
    }

    /// The full trim modal — extracted to keep `body` minimal and
    /// avoid SwiftUI type-checker cascades.
    private var trimModalContent: some View {
        ZStack {
            // Pure black background, edge-to-edge
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, DesignTokens.paddingStandard)
                    .padding(.top, DesignTokens.paddingXSmall)

                Spacer()

                // Video player area — shows video during trim, GIF preview on success
                videoArea

                Spacer()

                // Bottom area: depends on export state
                bottomSection
                    .padding(.horizontal, DesignTokens.paddingStandard)
                    .padding(.bottom, DesignTokens.paddingStandard)
            }

        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onChange(of: playerManager.duration) { _, newDuration in
            guard newDuration > 0, trimViewModel == nil else { return }
            initializeTrimInterface(duration: newDuration)
        }
        .sheet(isPresented: $showShareSheet, onDismiss: {
            // Clean up temp file after share sheet closes
            if let url = shareFileURL {
                try? FileManager.default.removeItem(at: url)
                shareFileURL = nil
            }
        }) {
            if let url = shareFileURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Volume toggle — hidden during encoding/success
            if case .idle = exportViewModel.exportState {
                Button {
                    playerManager.toggleMute()
                } label: {
                    Image(systemName: playerManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
            } else if case .error = exportViewModel.exportState {
                Button {
                    playerManager.toggleMute()
                } label: {
                    Image(systemName: playerManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }

            Spacer()

            // Cancel / Done button — Liquid Glass Text pill
            Button {
                handleDismiss()
            } label: {
                Text(dismissButtonTitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DesignTokens.glassButtonText)
                    .padding(.horizontal, DesignTokens.paddingStandard)
                    .padding(.vertical, DesignTokens.paddingXSmall)
                    .background {
                        Capsule()
                            .fill(DesignTokens.glassButtonBase)
                        Capsule()
                            .fill(DesignTokens.glassButtonBurn.opacity(0.3))
                        Capsule()
                            .fill(DesignTokens.glassButtonDarken.opacity(0.2))
                    }
                    .clipShape(Capsule())
            }
        }
    }

    /// Cancel during trim/error, Done during success.
    private var dismissButtonTitle: String {
        if case .success = exportViewModel.exportState { return "Done" }
        return "Cancel"
    }

    private func handleDismiss() {
        switch exportViewModel.exportState {
        case .encoding, .saving:
            exportViewModel.cancelExport()
        default:
            trimViewModel?.stopPreviewLoop()
            playerManager.pause()
            onDismiss()
        }
    }

    // MARK: - Video Area

    @ViewBuilder
    private var videoArea: some View {
        if case .success(let gifData, _, _) = exportViewModel.exportState {
            // GIF preview — looping animated image, constrained to max 50%
            // of screen height so Share/Done buttons stay visible even for
            // tall portrait GIFs (e.g., 1080×1920 Instagram Reels).
            GIFPreviewView(gifData: gifData)
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, DesignTokens.paddingStandard)
        } else {
            // Live video player
            VideoPlayer(player: playerManager.player)
                .disabled(true)
                .aspectRatio(contentMode: .fit)
                .onTapGesture {
                    if let vm = trimViewModel {
                        vm.togglePreviewLoop()
                    } else {
                        playerManager.togglePlayback()
                    }
                }
        }
    }

    // MARK: - Bottom Section

    @ViewBuilder
    private var bottomSection: some View {
        switch exportViewModel.exportState {
        case .idle, .error:
            trimSection
        case .encoding(let progress):
            encodingSection(progress: progress)
        case .saving:
            savingSection
        case .success:
            successSection
        }
    }

    // MARK: - Trim Section (idle / error)

    @ViewBuilder
    private var trimSection: some View {
        if let trimVM = trimViewModel {
            VStack(spacing: DesignTokens.paddingSmall) {
                // Error message with retry
                if case .error(let message) = exportViewModel.exportState {
                    VStack(spacing: 8) {
                        Text(message)
                            .font(DesignTokens.bodyFont(size: 14))
                            .foregroundStyle(DesignTokens.error)
                            .multilineTextAlignment(.center)

                        Button {
                            exportViewModel.resetToIdle()
                        } label: {
                            Text("Try Again")
                                .font(DesignTokens.labelFont(size: 14))
                                .foregroundStyle(DesignTokens.vermillion)
                        }
                    }
                    .padding(.bottom, 4)
                }

                // Trim bar
                TrimBarView(
                    trimViewModel: trimVM,
                    playerManager: playerManager,
                    filmstripGenerator: filmstripGenerator
                )

                // Duration readout
                durationReadout(trimVM: trimVM)

                // CREATE button
                createButton(trimVM: trimVM)
            }
        } else {
            ProgressView()
                .tint(.white)
        }
    }

    // MARK: - Encoding Progress (STORY-020)

    private func encodingSection(progress: Double) -> some View {
        VStack(spacing: DesignTokens.paddingStandard) {
            // Trim bar remains visible during encoding
            if let trimVM = trimViewModel {
                TrimBarView(
                    trimViewModel: trimVM,
                    playerManager: playerManager,
                    filmstripGenerator: filmstripGenerator
                )
                .allowsHitTesting(false)
                .opacity(0.5)

                durationReadout(trimVM: trimVM)
                    .opacity(0.5)
            }

            // Progress ring
            ZStack {
                // Track
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)

                // Vermillion progress stroke
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(DesignTokens.vermillion, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: progress)

                // Percentage text
                Text("\(Int(progress * 100))%")
                    .font(DesignTokens.headingFont(size: 18))
                    .foregroundStyle(.white)
            }

            Text("Creating your GIF...")
                .font(DesignTokens.labelFont(size: 14))
                .foregroundStyle(DesignTokens.textSecondary)

            // Cancel encoding
            Button {
                exportViewModel.cancelExport()
            } label: {
                Text("Cancel")
                    .font(DesignTokens.labelFont(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Saving State

    private var savingSection: some View {
        VStack(spacing: DesignTokens.paddingStandard) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: 1.0)
                    .stroke(DesignTokens.vermillion, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                Text("100%")
                    .font(DesignTokens.headingFont(size: 18))
                    .foregroundStyle(.white)
            }

            Text("Saving...")
                .font(DesignTokens.labelFont(size: 14))
                .foregroundStyle(DesignTokens.textSecondary)
        }
    }

    // MARK: - Success State (STORY-022)

    private var successSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DesignTokens.paddingStandard) {
                // File info line
                if let info = exportViewModel.fileInfoText {
                    Text(info)
                        .font(DesignTokens.labelFont(size: 14))
                        .foregroundStyle(.white)
                }

                // Oversize warning
                if let warning = exportViewModel.oversizeWarning {
                    Text(warning)
                        .font(DesignTokens.labelFont(size: 13))
                        .foregroundStyle(DesignTokens.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Action buttons
                HStack(spacing: DesignTokens.paddingStandard) {
                    // Share button — vermillion fill
                    Button {
                        if case .success(let gifData, _, _) = exportViewModel.exportState {
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent("ClipForge-\(UUID().uuidString).gif")
                            do {
                                try gifData.write(to: tempURL)
                                shareFileURL = tempURL
                                showShareSheet = true
                                #if DEBUG
                                print("DEBUG: wrote GIF to temp file for share: \(tempURL.lastPathComponent)")
                                #endif
                            } catch {
                                #if DEBUG
                                print("DEBUG: failed to write GIF temp file: \(error)")
                                #endif
                            }
                        }
                    } label: {
                        Text("SHARE")
                            .font(DesignTokens.labelFont(size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusButton)
                                    .fill(DesignTokens.vermillion)
                            )
                    }

                    // Done button — ghost pill
                    Button {
                        handleDismiss()
                    } label: {
                        Text("DONE")
                            .font(DesignTokens.labelFont(size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusButton)
                                    .stroke(.white, lineWidth: 1)
                            )
                    }
                }

                // Free tier counter — hidden for premium users (STORY-7.4)
                if !gatekeeper.isPremium {
                    Text("\(gatekeeper.remainingExports) of \(gatekeeper.dailyLimit) free GIFs remaining today")
                        .font(DesignTokens.labelFont(size: 13))
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }
        }
    }

    // MARK: - Duration Readout (STORY-017)

    private func durationReadout(trimVM: TrimViewModel) -> some View {
        VStack(spacing: 4) {
            Text(trimVM.durationText)
                .font(DesignTokens.headingFont(size: 32))
                .foregroundStyle(durationTextColor(trimVM.durationColor))

            if trimVM.durationColor == .danger {
                Text("Long clips produce large files")
                    .font(DesignTokens.labelFont(size: 14))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: trimVM.durationColor)
            }
        }
    }

    private func durationTextColor(_ color: DurationColor) -> Color {
        switch color {
        case .normal:  return .white
        case .warning: return Color(hex: 0xFF9500)
        case .danger:  return Color(hex: 0xFF3B30)
        }
    }

    // MARK: - CREATE Button (STORY-018 / STORY-020 / STORY-7.3)

    private func createButton(trimVM: TrimViewModel) -> some View {
        VStack(spacing: DesignTokens.paddingSmall) {
            if showFreemiumGate {
                // Upgrade prompt — shown when daily limit reached
                freemiumGatePrompt
            } else {
                Button {
                    if gatekeeper.canExport {
                        trimVM.stopPreviewLoop()
                        playerManager.pause()
                        let asset = AVURLAsset(url: videoURL)
                        exportViewModel.startExport(
                            asset: asset,
                            startTime: trimVM.startTime,
                            endTime: trimVM.endTime,
                            isPremium: gatekeeper.isPremium
                        )
                    } else {
                        showFreemiumGate = true
                    }
                } label: {
                    Text("CREATE")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(DesignTokens.glassButtonText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background {
                            RoundedRectangle(cornerRadius: 1000)
                                .fill(DesignTokens.glassButtonBase)
                            RoundedRectangle(cornerRadius: 1000)
                                .fill(DesignTokens.glassButtonBurn.opacity(0.3))
                            RoundedRectangle(cornerRadius: 1000)
                                .fill(DesignTokens.glassButtonDarken.opacity(0.2))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 1000))
                }
                .disabled(!trimVM.isNextEnabled)
                .opacity(trimVM.isNextEnabled ? 1.0 : 0.4)
            }
        }
    }

    // MARK: - Freemium Gate Prompt (STORY-7.3)

    private var freemiumGatePrompt: some View {
        VStack(spacing: DesignTokens.paddingSmall) {
            Text("You've used your free GIF for today")
                .font(DesignTokens.headingFont(size: 16))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Upgrade to ClipForge Premium for unlimited GIFs")
                .font(DesignTokens.bodyFont(size: 14))
                .foregroundStyle(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                SubscriptionRouter.shared.showSubscription = true
            } label: {
                Text("Upgrade — $9.99/year")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DesignTokens.glassButtonText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background {
                        RoundedRectangle(cornerRadius: 1000)
                            .fill(DesignTokens.glassButtonBase)
                        RoundedRectangle(cornerRadius: 1000)
                            .fill(DesignTokens.glassButtonBurn.opacity(0.3))
                        RoundedRectangle(cornerRadius: 1000)
                            .fill(DesignTokens.glassButtonDarken.opacity(0.2))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 1000))
            }

            Button {
                showFreemiumGate = false
            } label: {
                Text("Maybe Later")
                    .font(DesignTokens.labelFont(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Setup

    private func initializeTrimInterface(duration: Double) {
        let vm = TrimViewModel(playerManager: playerManager, videoDuration: duration)
        trimViewModel = vm

        let asset = AVURLAsset(url: videoURL)
        filmstripGenerator.generate(from: asset)
    }
}

// MARK: - GIF Preview (STORY-022)

/// Displays a looping animated GIF using UIImageView.
struct GIFPreviewView: UIViewRepresentable {
    let gifData: Data

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear

        if let source = CGImageSourceCreateWithData(gifData as CFData, nil) {
            let count = CGImageSourceGetCount(source)
            var images: [UIImage] = []
            var totalDuration: Double = 0

            for i in 0..<count {
                if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(UIImage(cgImage: cgImage))
                }
                // Read frame delay
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifDict = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let delay = gifDict[kCGImagePropertyGIFDelayTime as String] as? Double {
                    totalDuration += delay
                }
            }

            imageView.animationImages = images
            imageView.animationDuration = totalDuration
            imageView.animationRepeatCount = 0 // Infinite loop
            imageView.startAnimating()
        }

        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

// MARK: - Share Sheet (STORY-022)

/// UIActivityViewController wrapped for SwiftUI presentation.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    TrimModalView(
        videoURL: URL(fileURLWithPath: "/dev/null"),
        onDismiss: {}
    )
}
