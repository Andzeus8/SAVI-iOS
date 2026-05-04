import SwiftUI
import UniformTypeIdentifiers
import WebKit
import QuickLook
import UIKit
import SafariServices
import PhotosUI
import LocalAuthentication
import LinkPresentation
import Network
import CloudKit
import AuthenticationServices
#if canImport(FoundationModels)
import FoundationModels
#endif

struct ExploreScreen: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Color.clear
                            .frame(height: 0)
                            .id("explore-top")

                        ExploreLibraryView(seed: $store.exploreSeed)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
                }
                .scrollContentBackground(.hidden)
                .background(SaviTheme.background.ignoresSafeArea())
                .onChange(of: store.exploreScope) { _ in
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                        proxy.scrollTo("explore-top", anchor: .top)
                    }
                }
            }
        }
    }
}
