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
        VStack(spacing: DesignTokens.paddingLarge) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(DesignTokens.vermillion)

            Text("GIF Created!")
                .font(DesignTokens.headingFont(size: 28))
                .foregroundStyle(DesignTokens.textPrimary)

            Text("Your GIF has been saved.")
                .font(DesignTokens.bodyFont(size: 16))
                .foregroundStyle(DesignTokens.textSecondary)

            Button {
                // Pop to root by clearing the entire navigation path.
                navigationPath = NavigationPath()
            } label: {
                Text("Done")
                    .font(DesignTokens.labelFont(size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusButton)
                            .fill(DesignTokens.vermillion)
                    )
            }
            .padding(.horizontal, DesignTokens.paddingXLarge)

            Spacer()
        }
        .background(DesignTokens.background.ignoresSafeArea())
        .navigationTitle("Complete")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ExportSuccessView(navigationPath: .constant(NavigationPath()))
    }
}
