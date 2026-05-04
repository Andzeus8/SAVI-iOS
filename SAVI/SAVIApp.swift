import SwiftUI

@main
struct SAVIApp: App {
    @StateObject private var store = SaviStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}
