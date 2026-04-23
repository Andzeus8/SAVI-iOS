import SwiftUI

struct ContentView: View {
    @StateObject private var model = SAVIWebViewModel()

    var body: some View {
        SAVIWebView(model: model)
            .ignoresSafeArea()
            .onAppear {
                model.loadIfNeeded()
            }
    }
}
