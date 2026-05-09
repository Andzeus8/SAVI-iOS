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
import AuthenticationServices
#if DEBUG && canImport(FoundationModels)
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
            NSLog("[SAVI Native] root task starting bootstrap perfTier=%@", SaviPerformancePolicy.current.rawValue)
            await store.bootstrap()
            NSLog("[SAVI Native] root task finished bootstrap")
        }
        .onOpenURL { url in
            NSLog("[SAVI Native] received deep link %@", url.absoluteString)
            Task {
                await store.importSharedDeepLink(url)
            }
        }
    }
}
