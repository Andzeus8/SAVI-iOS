import SwiftUI
import WebKit

struct SAVIWebView: UIViewRepresentable {
    @ObservedObject var model: SAVIWebViewModel

    func makeUIView(context: Context) -> WKWebView {
        model.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
