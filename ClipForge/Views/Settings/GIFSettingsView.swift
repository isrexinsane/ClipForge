//
//  GIFSettingsView.swift
//  ClipForge
//
//  Placeholder for GIF quality/preset selection.
//  Will be replaced with preset picker and preview in Epic 5.
//

import SwiftUI

struct GIFSettingsView: View {

    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("GIF Settings Screen")
                .font(.title)
                .fontWeight(.semibold)

            Text("Quality presets and encoding options will appear here.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                navigationPath.append(AppRoute.exportSuccess)
            } label: {
                Text("Create GIF")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)

            Spacer()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GIFSettingsView(navigationPath: .constant(NavigationPath()))
    }
}
