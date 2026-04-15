//
//  FreemiumGatekeeper.swift
//  ClipForge
//
//  Manages the free-tier daily export limit. Tracks how many GIFs
//  the user has created today and whether they hold a premium
//  subscription. UserDefaults-backed — no server state needed.
//
//  STORY-7.1: FreemiumGatekeeper Service
//

import Foundation

/// Controls daily export limits for free-tier users and tracks premium status.
///
/// Free tier: 1 GIF per calendar day. Premium: unlimited, no watermark.
/// The counter resets automatically at midnight (device local time).
@MainActor
final class FreemiumGatekeeper: ObservableObject {

    // MARK: - Singleton

    static let shared = FreemiumGatekeeper()

    // MARK: - Published State

    @Published private(set) var dailyExportCount: Int
    @Published var isPremium: Bool {
        didSet { defaults.set(isPremium, forKey: Keys.isPremium) }
    }

    // MARK: - Constants

    let dailyLimit = 1

    // MARK: - Private

    private let defaults = UserDefaults.standard
    private var dailyExportDate: String {
        get { defaults.string(forKey: Keys.dailyExportDate) ?? "" }
        set { defaults.set(newValue, forKey: Keys.dailyExportDate) }
    }

    private enum Keys {
        static let dailyExportCount = "dailyExportCount"
        static let dailyExportDate = "dailyExportDate"
        static let isPremium = "isPremium"
    }

    // MARK: - Init

    private init() {
        self.dailyExportCount = defaults.integer(forKey: Keys.dailyExportCount)
        self.isPremium = defaults.bool(forKey: Keys.isPremium)
        checkAndResetIfNewDay()
    }

    // MARK: - Computed Properties

    /// Whether the user can create a GIF right now.
    /// Premium users always can. Free users must be under the daily limit.
    var canExport: Bool {
        checkAndResetIfNewDay()
        return isPremium || dailyExportCount < dailyLimit
    }

    /// How many free exports remain today. Clamped to 0.
    var remainingExports: Int {
        checkAndResetIfNewDay()
        return max(dailyLimit - dailyExportCount, 0)
    }

    // MARK: - Methods

    /// Call after a successful GIF export to consume one daily use.
    func incrementExportCount() {
        checkAndResetIfNewDay()
        dailyExportCount += 1
        defaults.set(dailyExportCount, forKey: Keys.dailyExportCount)
    }

    /// Resets the counter if the calendar day has changed since the last export.
    @discardableResult
    func checkAndResetIfNewDay() -> Bool {
        let today = Self.todayString()
        guard dailyExportDate != today else { return false }
        dailyExportCount = 0
        defaults.set(0, forKey: Keys.dailyExportCount)
        dailyExportDate = today
        return true
    }

    // MARK: - Helpers

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
}
