import SwiftUI

@main
struct SAVIMacApp: App {
    var body: some Scene {
        WindowGroup {
            SAVIMacRootView()
                .frame(minWidth: 1040, minHeight: 680)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
