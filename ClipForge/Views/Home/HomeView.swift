//
//  HomeView.swift
//  ClipForge
//
//  The app's landing screen. In the final product this will contain
//  the clipboard monitor and link paste field. For now it's a
//  placeholder with a "Next" button to test navigation.
//

import SwiftUI

struct HomeView: View {

    @Binding var navigationPath: NavigationPath

    /// Placeholder text field value (non-functional in this story).
    @State private var linkText = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("ClipForge")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Paste a link", text: $linkText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 32)

            Button {
                navigationPath.append(AppRoute.player)
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)

            Spacer()
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HomeView(navigationPath: .constant(NavigationPath()))
    }
}
