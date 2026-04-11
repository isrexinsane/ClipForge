//
//  ExportSuccessView.swift
//  ClipForge
//
//  Placeholder for the export success / share screen.
//  Will be replaced with GIF preview and share options in Epic 5.
//

import SwiftUI

struct ExportSuccessView: View {

    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Export Complete!")
                .font(.title)
                .fontWeight(.semibold)

            Text("Your GIF has been saved.")
                .foregroundStyle(.secondary)

            Button {
                // Pop to root by clearing the entire navigation path.
                navigationPath = NavigationPath()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)

            Spacer()
        }
        .navigationTitle("Complete")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ExportSuccessView(navigationPath: .constant(NavigationPath()))
    }
}
