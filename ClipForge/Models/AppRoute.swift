//
//  AppRoute.swift
//  ClipForge
//
//  Navigation route enum from Sprint 1 scaffolding.
//  Retained so placeholder views (PlayerView, GIFSettingsView,
//  ExportSuccessView) continue to compile. Will be removed when
//  those views are rewritten in their respective epics.
//

import Foundation

/// Route cases for Sprint 1's NavigationStack placeholder flow.
/// The production navigation model uses swipeable pages + modal sheets
/// (see Design_Decisions §2.1), but these routes keep the scaffolding
/// views compiling until they're replaced.
enum AppRoute: Hashable {
    case player
    case gifSettings
    case exportSuccess
}
