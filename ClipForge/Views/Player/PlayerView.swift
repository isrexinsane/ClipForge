//
//  PlayerView.swift
//  ClipForge
//
//  Placeholder for the video player and trim interface.
//  Will be replaced with AVPlayer and trim handles in Epic 4.
//

import SwiftUI

struct PlayerView: View {

    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Player / Trim Screen")
                .font(.title)
                .fontWeight(.semibold)

            Text("Video playback and trim controls will appear here.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                navigationPath.append(AppRoute.gifSettings)
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)

            Spacer()
        }
        .navigationTitle("Trim")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PlayerView(navigationPath: .constant(NavigationPath()))
    }
}
