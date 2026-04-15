//
//  MediaLibraryView.swift
//  ClipForge
//
//  Media Library page — the second swipeable page showing a grid
//  of previously created GIFs. Tap a tile to open the iOS share sheet.
//
//  STORY-023: Media Library — GIF History Grid
//

import SwiftUI
import Photos

/// Displays a 2-column grid of previously created GIFs with
/// thumbnails loaded from the Photos library.
struct MediaLibraryView: View {

    @ObservedObject var historyStore: GIFHistoryStore

    @State private var shareData: Data?
    @State private var showShareSheet = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color.cfBackground.ignoresSafeArea()

            if historyStore.entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(historyStore.entries) { entry in
                            GIFTileView(entry: entry) {
                                fetchAndShare(identifier: entry.localAssetIdentifier)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Your GIFs")
        .sheet(isPresented: $showShareSheet) {
            if let data = shareData {
                ShareSheet(activityItems: [data])
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(Color.cfTextSecondary)

            Text("Your GIFs will appear here")
                .font(CFFont.inter(size: 16))
                .foregroundStyle(Color.cfTextSecondary)
        }
    }

    // MARK: - Fetch & Share

    /// Loads the full GIF data from Photos and presents the share sheet.
    private func fetchAndShare(identifier: String) {
        let results = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = results.firstObject else { return }

        let options = PHImageRequestOptions()
        options.version = .original
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            Task { @MainActor in
                if let data {
                    shareData = data
                    showShareSheet = true
                }
            }
        }
    }
}

// MARK: - Tile View

/// A single tile in the Media Library grid showing a thumbnail
/// from the Photos library.
struct GIFTileView: View {

    let entry: GIFHistoryEntry
    let onTap: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cfDarkBase.opacity(0.1))

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                } else {
                    ProgressView()
                        .tint(Color.cfTextSecondary)
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .task {
            await loadThumbnail()
        }
    }

    /// Loads thumbnail from Photos using the stored asset identifier.
    private func loadThumbnail() async {
        let results = PHAsset.fetchAssets(
            withLocalIdentifiers: [entry.localAssetIdentifier],
            options: nil
        )
        guard let asset = results.firstObject else { return }

        let size = CGSize(width: 200, height: 200)
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
