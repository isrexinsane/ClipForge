//
//  MediaLibraryView.swift
//  ClipForge
//
//  Media Library page — the second swipeable page. Same gradient
//  background as Home. Masonry-style 2-column grid with Liquid Glass
//  card tiles that fade in opacity further down the page.
//
//  Figma spec: alternating tall/short card pattern, glass card style
//  (white 10% fill, white 39% border, 12pt corners, backdrop blur,
//  inner shadow highlight). Cards fade from 1.0 → 0.5 → 0.4 → 0.35.
//
//  STORY-023: Media Library — GIF History Grid
//

import SwiftUI
import Photos
import PhotosUI

/// Displays a masonry-style 2-column grid of previously created GIFs
/// with Liquid Glass card styling and opacity fade.
struct MediaLibraryView: View {

    @ObservedObject var historyStore: GIFHistoryStore

    @State private var shareURL: URL?
    @State private var showShareError = false
    @State private var isLoadingShare = false

    var body: some View {
        // Background gradient handled by ContentView — this view is transparent.
        VStack(spacing: 0) {
                // Top bar: "GALLERY" title
                galleryTopBar
                    .padding(.horizontal, DesignTokens.paddingStandard)
                    .padding(.top, 31)

                ScrollView {
                    unifiedMasonryGrid(entries: historyStore.entries)
                        .padding(.top, DesignTokens.paddingStandard)
                        .padding(.bottom, DesignTokens.paddingXLarge)
                }
                .mask(
                    VStack(spacing: 0) {
                        Color.black          // fully visible region
                        LinearGradient(
                            colors: [.black, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)  // fade zone at bottom of visible area
                    }
                )

                // Reserve space for page dots
                Spacer()
                    .frame(height: DesignTokens.paddingXLarge + DesignTokens.paddingSmall)
            }
        .sheet(item: $shareURL) { url in
            ShareSheet(activityItems: [url])
        }
        .alert("GIF Unavailable", isPresented: $showShareError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This GIF could not be loaded from your photo library. It may have been deleted.")
        }
    }

    // MARK: - Top Bar

    private var galleryTopBar: some View {
        HStack {
            Text("GALLERY")
                .font(DesignTokens.headingFont(size: DesignTokens.titleSize))
                .foregroundStyle(DesignTokens.textOnGradient)
            Spacer()
        }
    }

    // MARK: - Unified Masonry Grid

    /// Always renders 9 slots (3 rows × 3 per row) in the masonry pattern.
    /// Slots with GIF entries show a GIFGlassCard; remaining slots show a
    /// PlaceholderGlassCard. This handles both the empty state and the
    /// partially-filled state with one code path.
    ///
    /// Layout per row (repeating):
    /// - Even rows (0, 2): TALL left, SHORT right-top, SHORT right-bottom
    /// - Odd rows (1): SHORT left-top, SHORT left-bottom, TALL right
    private func unifiedMasonryGrid(entries: [GIFHistoryEntry]) -> some View {
        let totalSlots = 9
        let tallHeight: CGFloat = 270
        let shortHeight: CGFloat = 128
        let gap: CGFloat = 11

        return VStack(spacing: gap) {
            ForEach(0..<3, id: \.self) { rowIndex in
                let base = rowIndex * 3

                HStack(spacing: DesignTokens.paddingSmall) {
                    if rowIndex.isMultiple(of: 2) {
                        // Even row: tall left, two short stacked right
                        slotView(index: base, entries: entries, height: tallHeight)
                        VStack(spacing: gap) {
                            slotView(index: base + 1, entries: entries, height: shortHeight)
                            slotView(index: base + 2, entries: entries, height: shortHeight)
                        }
                    } else {
                        // Odd row: two short stacked left, tall right
                        VStack(spacing: gap) {
                            slotView(index: base, entries: entries, height: shortHeight)
                            slotView(index: base + 1, entries: entries, height: shortHeight)
                        }
                        slotView(index: base + 2, entries: entries, height: tallHeight)
                    }
                }
                .frame(height: tallHeight)
            }
        }
        .padding(.horizontal, DesignTokens.paddingStandard)
    }

    /// Returns either a GIF-filled glass card or an empty placeholder,
    /// depending on whether an entry exists at the given index.
    @ViewBuilder
    private func slotView(index: Int, entries: [GIFHistoryEntry], height: CGFloat) -> some View {
        if index < entries.count {
            GIFGlassCard(entry: entries[index], height: height) {
                #if DEBUG
                print("DEBUG: gallery tap on index \(index), entry: \(entries[index].localAssetIdentifier)")
                #endif
                fetchAndShare(identifier: entries[index].localAssetIdentifier)
            }
        } else {
            PlaceholderGlassCard(height: height)
        }
    }

    // MARK: - Fetch & Share

    /// Fetches the original GIF data from the Photos library using
    /// PHAssetResource, then presents the share sheet.
    ///
    /// PHAssetResourceManager preserves the original GIF file bytes
    /// (including animation frames), unlike PHImageManager which may
    /// return a single-frame image representation.
    private func fetchAndShare(identifier: String) {
        // Prevent double-tap while already loading
        guard !isLoadingShare else { return }
        isLoadingShare = true

        #if DEBUG
        print("DEBUG: Gallery fetchAndShare tapped for asset: \(identifier)")
        #endif

        // Clean up any previous temp file
        if let oldURL = shareURL {
            try? FileManager.default.removeItem(at: oldURL)
            shareURL = nil
        }

        let results = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = results.firstObject else {
            isLoadingShare = false
            showShareError = true
            return
        }

        // Find the GIF resource (photo resource with .GIF uniform type)
        let resources = PHAssetResource.assetResources(for: asset)
        guard let gifResource = resources.first(where: {
            $0.uniformTypeIdentifier == "com.compuserve.gif"
        }) ?? resources.first else {
            isLoadingShare = false
            showShareError = true
            return
        }

        // Collect the raw bytes via PHAssetResourceManager
        var gifData = Data()
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true

        PHAssetResourceManager.default().requestData(
            for: gifResource,
            options: options,
            dataReceivedHandler: { chunk in
                gifData.append(chunk)
            },
            completionHandler: { error in
                Task { @MainActor in
                    isLoadingShare = false
                    if error == nil, !gifData.isEmpty {
                        // Write to temp file with .gif extension so receiving
                        // apps recognize animated GIF (raw Data pastes as still image).
                        // Setting shareURL triggers .sheet(item:) presentation.
                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent("ClipForge-\(UUID().uuidString).gif")
                        do {
                            try gifData.write(to: tempURL)
                            shareURL = tempURL
                            #if DEBUG
                            print("DEBUG: wrote GIF to temp file for share: \(tempURL.lastPathComponent)")
                            #endif
                        } catch {
                            #if DEBUG
                            print("DEBUG: failed to write GIF temp file: \(error)")
                            #endif
                            showShareError = true
                        }
                    } else {
                        showShareError = true
                    }
                }
            }
        )
    }
}

// MARK: - Glass Card Tile

/// A single Liquid Glass tile in the Media Library grid.
///
/// Layers (bottom to top):
/// 1. ultraThinMaterial backdrop (picks up parent gradient)
/// 2. White 10% tint (glassBackground)
/// 3. GIF thumbnail — clipped to rounded rect so glass edges show through
/// 4. White 39% border stroke (glassBorder)
/// 5. Inner highlight gradient stroke at top edge
///
/// The thumbnail is inset slightly and clipped to the rounded shape so
/// the glass border and highlight are always visible around the edges,
/// giving populated cards the same Liquid Glass look as empty placeholders.
struct GIFGlassCard: View {

    let entry: GIFHistoryEntry
    let height: CGFloat
    let onTap: () -> Void

    @State private var thumbnail: UIImage?

    private let corner = DesignTokens.glassCornerRadius

    var body: some View {
        ZStack {
            // Glass card background — visible around edges and through
            // the thumbnail's rounded corners.
            RoundedRectangle(cornerRadius: corner)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: corner)
                .fill(DesignTokens.glassBackground)

            // Thumbnail — fills the card but clipped to rounded rect
            if let thumbnail {
                GeometryReader { geo in
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: corner))
                .allowsHitTesting(false)
            } else {
                ProgressView()
                    .tint(DesignTokens.mutedWarm)
            }

            // Glass border — always on top of thumbnail
            RoundedRectangle(cornerRadius: corner)
                .stroke(DesignTokens.glassBorder, lineWidth: 1)
                .allowsHitTesting(false)

            // Inner highlight — top edge glow
            RoundedRectangle(cornerRadius: corner)
                .stroke(
                    LinearGradient(
                        colors: [DesignTokens.glassHighlight, Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
                .padding(1)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: corner))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .task(id: entry.localAssetIdentifier) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        let results = PHAsset.fetchAssets(
            withLocalIdentifiers: [entry.localAssetIdentifier],
            options: nil
        )
        guard let asset = results.firstObject else { return }

        let size = CGSize(width: 300, height: 300)
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            Task { @MainActor in
                if let image {
                    thumbnail = image
                }
            }
        }
    }
}

// MARK: - Placeholder Glass Card (Empty State)

/// An empty Liquid Glass tile used in the placeholder grid when no GIFs exist.
/// Same visual treatment as GIFGlassCard but with no thumbnail or tap action.
struct PlaceholderGlassCard: View {

    let height: CGFloat

    var body: some View {
        ZStack {
            // Glass card background
            RoundedRectangle(cornerRadius: DesignTokens.glassCornerRadius)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: DesignTokens.glassCornerRadius)
                .fill(DesignTokens.glassBackground)

            // Glass border
            RoundedRectangle(cornerRadius: DesignTokens.glassCornerRadius)
                .stroke(DesignTokens.glassBorder, lineWidth: 1)

            // Inner highlight — top edge glow
            RoundedRectangle(cornerRadius: DesignTokens.glassCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [DesignTokens.glassHighlight, Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
                .padding(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.glassCornerRadius))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}
