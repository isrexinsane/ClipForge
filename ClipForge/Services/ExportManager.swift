//
//  ExportManager.swift
//  ClipForge
//
//  Handles saving GIF data to the iOS Photos library via
//  PHPhotoLibrary. Manages permission requests and provides
//  the saved asset's local identifier for Media Library tracking.
//
//  STORY-021: Camera Roll Save — PHPhotoLibrary Integration
//

import Photos

/// Saves encoded GIF data to the user's photo library.
///
/// Uses `.addOnly` authorization — ClipForge only needs to write,
/// not read the full library. Returns the saved asset's local
/// identifier for use in the Media Library grid (STORY-023).
enum ExportManager {

    /// Saves GIF data to the Photos library.
    ///
    /// - Parameter gifData: Raw animated GIF data from the encoder.
    /// - Returns: The local asset identifier of the saved photo asset.
    /// - Throws: `ClipForgeError.photoLibraryDenied` if permission is denied,
    ///   or a generic error if the save operation fails.
    static func saveGIFToPhotos(_ gifData: Data) async throws -> String {
        // Check / request permission
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .notDetermined:
            let granted = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard granted == .authorized || granted == .limited else {
                throw ClipForgeError.photoLibraryDenied
            }
        case .authorized, .limited:
            break
        case .denied, .restricted:
            throw ClipForgeError.photoLibraryDenied
        @unknown default:
            throw ClipForgeError.photoLibraryDenied
        }

        // Save to Photos
        var localIdentifier: String?

        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: gifData, options: nil)
            localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
        }

        guard let identifier = localIdentifier else {
            throw ClipForgeError.unknown(
                NSError(domain: "ExportManager", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Could not retrieve saved asset identifier."])
            )
        }

        return identifier
    }
}
