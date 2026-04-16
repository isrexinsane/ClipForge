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

    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var showShareError = false

    var body: some View {
        // Background gradient handled by ContentView — this view is transparent.
        VStack(spacing: 0) {
                // Top bar: "GALLERY" title
                galleryTopBar
                    .padding(.horizontal, DesignTokens.paddingStandard)
                    .padding(.top, 31)

                if historyStore.entries.isEmpty {
                    ScrollView {
                        placeholderGrid
                            .padding(.horizontal, DesignTokens.paddingStandard)
                            .padding(.top, DesignTokens.paddingStandard)
                            .padding(.bottom, DesignTokens.paddingXLarge)
                    }
                } else {
                    ScrollView {
                        masonryGrid
                            .padding(.horizontal, DesignTokens.paddingStandard)
                            .padding(.top, DesignTokens.paddingStandard)
                            .padding(.bottom, DesignTokens.paddingXLarge)
                    }
                }

                // Reserve space for page dots
                Spacer()
                    .frame(height: DesignTokens.paddingXLarge + DesignTokens.paddingSmall)
            }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareItems)
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

    // MARK: - Masonry Grid

    /// Alternating masonry layout: odd rows have a tall card left + 2 short
    /// cards stacked right; even rows invert. Cards fade in opacity by row.
    private var masonryGrid: some View {
        let entries = historyStore.entries
        let pairs = stride(from: 0, to: entries.count, by: 3).map { startIdx in
            let end = min(startIdx + 3, entries.count)
            return Array(entries[startIdx..<end])
        }

        return VStack(spacing: DesignTokens.paddingSmall) {
            ForEach(Array(pairs.enumerated()), id: \.offset) { rowIndex, group in
                masonryRow(group: group, rowIndex: rowIndex)
                    .opacity(opacityForRow(rowIndex))
            }
        }
    }

    /// Builds one masonry row from up to 3 entries.
    /// Even rows: tall left, 2-stack right. Odd rows: 2-stack left, tall right.
    @ViewBuilder
    private func masonryRow(group: [GIFHistoryEntry], rowIndex: Int) -> some View {
        let tallHeight: CGFloat = 270
        let shortHeight: CGFloat = 128
        let gap: CGFloat = 11

        if group.count >= 3 {
            if rowIndex.isMultiple(of: 2) {
                // Tall left, 2-stack right
                HStack(spacing: DesignTokens.paddingSmall) {
                    GIFGlassCard(entry: group[0], height: tallHeight) {
                        fetchAndShare(identifier: group[0].localAssetIdentifier)
                    }
                    VStack(spacing: gap) {
                        GIFGlassCard(entry: group[1], height: shortHeight) {
                            fetchAndShare(identifier: group[1].localAssetIdentifier)
                        }
                        GIFGlassCard(entry: group[2], height: shortHeight) {
                            fetchAndShare(identifier: group[2].localAssetIdentifier)
                        }
                    }
                }
                .frame(height: tallHeight)
            } else {
                // 2-stack left, tall right
                HStack(spacing: DesignTokens.paddingSmall) {
                    VStack(spacing: gap) {
                        GIFGlassCard(entry: group[0], height: shortHeight) {
                            fetchAndShare(identifier: group[0].localAssetIdentifier)
                        }
                        GIFGlassCard(entry: group[1], height: shortHeight) {
                            fetchAndShare(identifier: group[1].localAssetIdentifier)
                        }
                    }
                    GIFGlassCard(entry: group[2], height: tallHeight) {
                        fetchAndShare(identifier: group[2].localAssetIdentifier)
                    }
                }
                .frame(height: tallHeight)
            }
        } else if group.count == 2 {
            HStack(spacing: DesignTokens.paddingSmall) {
                GIFGlassCard(entry: group[0], height: shortHeight) {
                    fetchAndShare(identifier: group[0].localAssetIdentifier)
                }
                GIFGlassCard(entry: group[1], height: shortHeight) {
                    fetchAndShare(identifier: group[1].localAssetIdentifier)
                }
            }
        } else if group.count == 1 {
            GIFGlassCard(entry: group[0], height: shortHeight) {
                fetchAndShare(identifier: group[0].localAssetIdentifier)
            }
        }
    }

    /// Cards fade as they go further down the page.
    private func opacityForRow(_ index: Int) -> Double {
        switch index {
        case 0: return 1.0
        case 1: return 0.5
        case 2: return 0.4
        default: return 0.35
        }
    }

    // MARK: - Placeholder Grid (Empty State)

    /// Shows 9 empty frosted glass cards in the same masonry pattern
    /// so the gallery feels alive even before any GIFs are created.
    private var placeholderGrid: some View {
        let placeholderCount = 9 // 3 rows × 3 cards each
        let groups = stride(from: 0, to: placeholderCount, by: 3).map { start in
            min(start + 3, placeholderCount) - start
        }

        return VStack(spacing: DesignTokens.paddingSmall) {
            ForEach(Array(groups.enumerated()), id: \.offset) { rowIndex, count in
                placeholderRow(count: count, rowIndex: rowIndex)
                    .opacity(opacityForRow(rowIndex))
            }
        }
    }

    /// Builds one placeholder masonry row with the same tall/short alternation.
    @ViewBuilder
    private func placeholderRow(count: Int, rowIndex: Int) -> some View {
        let tallHeight: CGFloat = 270
        let shortHeight: CGFloat = 128
        let gap: CGFloat = 11

        if count >= 3 {
            if rowIndex.isMultiple(of: 2) {
                // Tall left, 2-stack right
                HStack(spacing: DesignTokens.paddingSmall) {
                    PlaceholderGlassCard(height: tallHeight)
                    VStack(spacing: gap) {
                        PlaceholderGlassCard(height: shortHeight)
                        PlaceholderGlassCard(height: shortHeight)
                    }
                }
                .frame(height: tallHeight)
            } else {
                // 2-stack left, tall right
                HStack(spacing: DesignTokens.paddingSmall) {
                    VStack(spacing: gap) {
                        PlaceholderGlassCard(height: shortHeight)
                        PlaceholderGlassCard(height: shortHeight)
                    }
                    PlaceholderGlassCard(height: tallHeight)
                }
                .frame(height: tallHeight)
            }
        } else if count == 2 {
            HStack(spacing: DesignTokens.paddingSmall) {
                PlaceholderGlassCard(height: shortHeight)
                PlaceholderGlassCard(height: shortHeight)
            }
        } else if count == 1 {
            PlaceholderGlassCard(height: shortHeight)
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
        let results = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = results.firstObject else {
            showShareError = true
            return
        }

        // Find the GIF resource (photo resource with .GIF uniform type)
        let resources = PHAssetResource.assetResources(for: asset)
        guard let gifResource = resources.first(where: {
            $0.uniformTypeIdentifier == "com.compuserve.gif"
        }) ?? resources.first else {
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
                    if error == nil, !gifData.isEmpty {
                        shareItems = [gifData]
                        showShareSheet = true
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
        Button(action: onTap) {
            ZStack {
                // Glass card background — visible around edges and through
                // the thumbnail's rounded corners.
                RoundedRectangle(cornerRadius: corner)
                    .fill(.ultraThinMaterial)

                RoundedRectangle(cornerRadius: corner)
                    .fill(DesignTokens.glassBackground)

                // Thumbnail — fills the card but clipped to rounded rect
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: corner))
                } else {
                    ProgressView()
                        .tint(DesignTokens.mutedWarm)
                }

                // Glass border — always on top of thumbnail
                RoundedRectangle(cornerRadius: corner)
                    .stroke(DesignTokens.glassBorder, lineWidth: 1)

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
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: corner))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .task {
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
