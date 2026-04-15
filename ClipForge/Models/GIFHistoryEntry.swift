//
//  GIFHistoryEntry.swift
//  ClipForge
//
//  Data model for a single GIF in the creation history.
//  Persisted as JSON in UserDefaults.
//
//  STORY-023: Media Library — GIF History Grid
//

import Foundation

/// Represents one GIF the user created, stored in the history for
/// the Media Library grid.
struct GIFHistoryEntry: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let fileSize: Int
    let width: Int
    let height: Int

    /// The Photos library local identifier for the saved asset.
    /// Used to fetch thumbnails via PHImageManager.
    let localAssetIdentifier: String
}
