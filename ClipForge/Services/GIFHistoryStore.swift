//
//  GIFHistoryStore.swift
//  ClipForge
//
//  Persists GIF creation history in UserDefaults for the Media
//  Library grid. Newest entries first.
//
//  STORY-023: Media Library — GIF History Grid
//

import Foundation

/// Manages the persisted list of created GIFs.
///
/// Backed by UserDefaults with JSON encoding. Thread-safe via
/// @MainActor. The shared singleton is used by both ExportViewModel
/// (to record new entries) and MediaLibraryView (to display history).
@MainActor
final class GIFHistoryStore: ObservableObject {

    static let shared = GIFHistoryStore()

    private static let storageKey = "gifHistory"

    @Published private(set) var entries: [GIFHistoryEntry] = []

    private init() {
        entries = Self.loadEntries()
    }

    /// Adds a new entry at the front of the list and persists.
    func addEntry(_ entry: GIFHistoryEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private static func loadEntries() -> [GIFHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([GIFHistoryEntry].self, from: data) else {
            return []
        }
        return entries
    }
}
