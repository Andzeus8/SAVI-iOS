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

struct ContentView: View {
    @ObservedObject var store: SaviStore

    var body: some View {
        ZStack {
            NativeSaviRootView()
                .environmentObject(store)

            if store.shouldRunLegacyMigration {
                LegacyMigrationHost { payload in
                    Task { await store.finishLegacyMigration(payload) }
                }
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityHidden(true)
            }
        }
        .preferredColorScheme(store.preferredColorScheme)
        .task {
            await store.bootstrap()
        }
        .onOpenURL { url in
            NSLog("[SAVI Native] received deep link %@", url.absoluteString)
            Task {
                await store.importSharedDeepLink(url)
            }
        }
    }
}
