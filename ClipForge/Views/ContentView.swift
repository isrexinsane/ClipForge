//
//  ContentView.swift
//  ClipForge
//
//  Root view that owns the NavigationStack and NavigationPath.
//  All screen transitions flow through here. Individual views
//  append to the path to navigate forward; ExportSuccessView
//  clears the path to pop back to HomeView.
//

import SwiftUI

/// Route cases for the app's linear navigation flow.
/// Used with `navigationDestination(for:)` to drive the NavigationStack.
enum AppRoute: Hashable {
    case player
    case gifSettings
    case exportSuccess
}

struct ContentView: View {

    /// The navigation path driving the stack. Clearing this pops to root.
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView(navigationPath: $navigationPath)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .player:
                        PlayerView(navigationPath: $navigationPath)
                    case .gifSettings:
                        GIFSettingsView(navigationPath: $navigationPath)
                    case .exportSuccess:
                        ExportSuccessView(navigationPath: $navigationPath)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
