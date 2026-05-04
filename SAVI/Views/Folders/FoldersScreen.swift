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

struct FoldersScreen: View {
    @EnvironmentObject private var store: SaviStore

    private var folderViewMode: SaviFolderViewMode {
        SaviFolderViewMode(rawValue: store.prefs.folderViewMode) ?? .grid
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HeaderBlock(
                        eyebrow: "Folders",
                        title: "Folders",
                        subtitle: "Your folders, organized your way.",
                        titleSize: 32
                    )

                    FolderLibraryView(viewMode: folderViewMode)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
        }
    }
}
