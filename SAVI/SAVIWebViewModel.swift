import Foundation
import SwiftUI
import UIKit
import WebKit

private struct NativeImportMetadata {
    let title: String?
    let description: String?
    let imageURL: String?
    let provider: String?
    let tags: [String]
}

private enum NativeImportMetadataResult {
    case metadata(NativeImportMetadata)
    case empty
    case timedOut
}

private struct NativeOEmbedResponse: Decodable {
    let title: String?
    let authorName: String?
    let providerName: String?
    let thumbnailURL: String?

    enum CodingKeys: String, CodingKey {
        case title
        case authorName = "author_name"
        case providerName = "provider_name"
        case thumbnailURL = "thumbnail_url"
    }
}

final class SAVIWebViewModel: NSObject, ObservableObject {
    let webView: WKWebView

    private let shareStore = PendingShareStore.shared
    private var didLoadInitialPage = false
    private var pageReady = false
    private var importInFlight = false
    private var didAttemptRemoteFallback = false

    override init() {
        let contentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.userContentController = contentController
        configuration.websiteDataStore = .default()

        self.webView = WKWebView(frame: .zero, configuration: configuration)

        super.init()

        contentController.add(self, name: "savi")
        contentController.addUserScript(
            WKUserScript(
                source: Self.bridgeScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
        )

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForegroundTransition),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "savi")
        NotificationCenter.default.removeObserver(self)
    }

    func loadIfNeeded() {
        guard !didLoadInitialPage else { return }
        didLoadInitialPage = true
        loadPrimaryPage()
    }

    private func loadPrimaryPage() {
        loadBundledPage()
    }

    private func loadBundledPage() {
        let bundledIndexURL =
            Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources") ??
            Bundle.main.url(forResource: "index", withExtension: "html")

        guard let indexURL = bundledIndexURL else {
            return
        }

        webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
    }

    private func fallbackToRemotePageIfNeeded() {
        guard !didAttemptRemoteFallback,
              let remoteURL = URL(string: "https://andzeus8.github.io/Savi-/")
        else { return }
        didAttemptRemoteFallback = true
        var request = URLRequest(url: remoteURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        webView.load(request)
    }

    @objc private func handleForegroundTransition() {
        importPendingSharesIfPossible()
    }

    private func importPendingSharesIfPossible() {
        guard pageReady, !importInFlight else { return }

        let rawShares = shareStore.loadPendingShares()
        guard !rawShares.isEmpty else { return }

        importInFlight = true
        Task {
            let shares = await withTaskGroup(of: PendingShare.self) { group in
                for share in rawShares {
                    group.addTask { [weak self] in
                        await self?.enrichForImportIfNeeded(share) ?? share
                    }
                }
                var enriched: [PendingShare] = []
                for await share in group {
                    enriched.append(share)
                }
                return enriched.sorted { $0.timestamp < $1.timestamp }
            }

            guard let data = try? JSONEncoder().encode(shares),
                  let json = String(data: data, encoding: .utf8) else {
                await MainActor.run { self.importInFlight = false }
                return
            }

            let script = """
            (function() {
              if (!window.SAVINative || typeof window.SAVINative.importShares !== 'function') { return 0; }
              return window.SAVINative.importShares(\(json));
            })();
            """

            await MainActor.run {
                self.webView.evaluateJavaScript(script) { [weak self] _, _ in
                    guard let self else { return }
                    rawShares.forEach(self.shareStore.remove(_:))
                    self.importInFlight = false
                    self.webView.reload()
                }
            }
        }
    }

    private func enrichForWebImport(_ share: PendingShare) -> PendingShare {
        guard let filePath = share.filePath, !filePath.isEmpty else { return share }
        let fileURL = URL(fileURLWithPath: filePath)

        if share.thumbnail == nil, share.type.lowercased() == "image",
           let data = try? Data(contentsOf: fileURL) {
            let dataURL = "data:\(share.mimeType ?? "image/jpeg");base64,\(data.base64EncodedString())"
            return PendingShare(
                id: share.id,
                url: share.url,
                title: share.title,
                type: share.type,
                thumbnail: dataURL,
                timestamp: share.timestamp,
                sourceApp: share.sourceApp,
                text: share.text,
                fileName: share.fileName,
                filePath: share.filePath,
                mimeType: share.mimeType,
                itemDescription: share.itemDescription,
                folderId: share.folderId,
                tags: share.tags
            )
        }

        return share
    }

    private func enrichForImportIfNeeded(_ share: PendingShare) async -> PendingShare {
        var enriched = enrichForWebImport(share)
        guard let urlString = enriched.url,
              !urlString.isEmpty,
              let url = URL(string: urlString),
              url.scheme?.hasPrefix("http") == true
        else {
            return enriched
        }

        let title = enriched.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let needsRemoteEnrichment =
            enriched.thumbnail?.nilIfEmpty == nil ||
            enriched.itemDescription?.nilIfEmpty == nil ||
            title.isEmpty ||
            title == "shared item" ||
            title == "youtube video" ||
            title.hasPrefix("http") ||
            title.hasSuffix(" save")

        guard needsRemoteEnrichment else { return enriched }
        guard let metadata = await fetchImportMetadata(for: url) else { return enriched }

        if shouldReplaceImportTitle(current: enriched.title, with: metadata.title) {
            enriched.title = metadata.title ?? enriched.title
        }
        if enriched.itemDescription?.nilIfEmpty == nil,
           let description = metadata.description?.nilIfEmpty {
            enriched.itemDescription = description
        }
        if enriched.thumbnail?.nilIfEmpty == nil,
           let imageURL = metadata.imageURL?.nilIfEmpty {
            enriched.thumbnail = imageURL
        }
        if enriched.sourceApp.isEmpty || enriched.sourceApp == "Share Extension",
           let provider = metadata.provider?.nilIfEmpty {
            enriched.sourceApp = provider
        }
        enriched.tags = dedupeImportTags((enriched.tags ?? []) + metadata.tags)
        return enriched
    }
}

private extension SAVIWebViewModel {
    func fetchImportMetadata(for url: URL) async -> NativeImportMetadata? {
        let startedAt = Date()
        return await withTaskGroup(of: NativeImportMetadataResult.self) { group in
            if isYouTubeImportURL(url) {
                group.addTask { [self] in
                    guard let metadata = try? await self.fetchYouTubeImportMetadata(for: url) else { return .empty }
                    return .metadata(metadata)
                }
            }
            group.addTask { [self] in
                guard let metadata = try? await self.fetchNoembedImportMetadata(for: url) else { return .empty }
                return .metadata(metadata)
            }
            group.addTask { [self] in
                guard let metadata = try? await self.fetchHTMLImportMetadata(for: url) else { return .empty }
                return .metadata(metadata)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                return .timedOut
            }

            var candidates: [NativeImportMetadata] = []
            while let result = await group.next() {
                switch result {
                case .metadata(let metadata):
                    candidates.append(metadata)
                    if importMetadataLooksComplete(metadata) {
                        group.cancelAll()
                        NSLog("[SAVIWeb] import metadata ready in %.2fs for %@", Date().timeIntervalSince(startedAt), url.absoluteString)
                        return mergeImportMetadata(candidates)
                    }
                case .empty:
                    continue
                case .timedOut:
                    group.cancelAll()
                    NSLog("[SAVIWeb] import metadata timed out after %.2fs for %@", Date().timeIntervalSince(startedAt), url.absoluteString)
                    return candidates.isEmpty ? nil : mergeImportMetadata(candidates)
                }
            }

            return candidates.isEmpty ? nil : mergeImportMetadata(candidates)
        }
    }

    func fetchYouTubeImportMetadata(for url: URL) async throws -> NativeImportMetadata {
        let canonicalURL = canonicalYouTubeImportURL(from: url)
        let endpoint = "https://www.youtube.com/oembed?url=\(canonicalURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? canonicalURL.absoluteString)&format=json"
        let decoded = try JSONDecoder().decode(NativeOEmbedResponse.self, from: try await fetchImportData(from: endpoint))
        let author = decoded.authorName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        return NativeImportMetadata(
            title: cleanedImportTitle(decoded.title, for: canonicalURL),
            description: author.map { "\($0) via YouTube" } ?? "YouTube video",
            imageURL: decoded.thumbnailURL ?? youtubeImportThumbnailURL(for: canonicalURL),
            provider: decoded.providerName ?? "YouTube",
            tags: ["youtube", "video"]
        )
    }

    func fetchNoembedImportMetadata(for url: URL) async throws -> NativeImportMetadata {
        let endpoint = "https://noembed.com/embed?url=\(url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url.absoluteString)"
        let decoded = try JSONDecoder().decode(NativeOEmbedResponse.self, from: try await fetchImportData(from: endpoint))
        let author = decoded.authorName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let provider = decoded.providerName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        return NativeImportMetadata(
            title: cleanedImportTitle(decoded.title, for: url),
            description: author.map { author in
                provider.map { "\(author) via \($0)" } ?? author
            } ?? provider,
            imageURL: decoded.thumbnailURL,
            provider: provider,
            tags: dedupeImportTags([decoded.providerName, decoded.title].compactMap { $0 }.flatMap { value in
                ["youtube", "instagram", "tiktok", "reddit", "spotify", "video", "post"].filter { value.lowercased().contains($0) }
            })
        )
    }

    func fetchHTMLImportMetadata(for url: URL) async throws -> NativeImportMetadata {
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<400).contains(http.statusCode),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode)
        else {
            throw URLError(.badServerResponse)
        }

        let title = cleanedImportTitle(firstHTMLMetaContent(in: html, keys: ["og:title", "twitter:title"]) ?? htmlTitle(in: html), for: url)
        let description = firstHTMLMetaContent(in: html, keys: ["og:description", "description", "twitter:description"])
        let image = firstHTMLMetaContent(in: html, keys: ["og:image", "twitter:image"]).flatMap { resolveImportURL($0, relativeTo: url) }
        let provider = firstHTMLMetaContent(in: html, keys: ["og:site_name", "application-name"]) ?? hostDisplayName(for: url)
        return NativeImportMetadata(title: title, description: description, imageURL: image, provider: provider, tags: [])
    }

    func fetchImportData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    func mergeImportMetadata(_ candidates: [NativeImportMetadata]) -> NativeImportMetadata {
        NativeImportMetadata(
            title: candidates.first(where: { $0.title?.nilIfEmpty != nil })?.title,
            description: candidates.compactMap(\.description).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.max(by: { $0.count < $1.count }),
            imageURL: candidates.first(where: { $0.imageURL?.nilIfEmpty != nil })?.imageURL,
            provider: candidates.first(where: { $0.provider?.nilIfEmpty != nil })?.provider,
            tags: dedupeImportTags(candidates.flatMap(\.tags))
        )
    }

    func importMetadataLooksComplete(_ metadata: NativeImportMetadata) -> Bool {
        guard metadata.title?.nilIfEmpty != nil else { return false }
        return metadata.description?.nilIfEmpty != nil || metadata.imageURL?.nilIfEmpty != nil || metadata.provider?.nilIfEmpty != nil
    }

    func shouldReplaceImportTitle(current: String, with fetched: String?) -> Bool {
        guard let fetched = fetched?.nilIfEmpty else { return false }
        let normalized = current.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ||
            normalized == "shared item" ||
            normalized == "youtube video" ||
            normalized.hasPrefix("http") ||
            normalized.hasSuffix(" save") ||
            fetched.count > current.count + 8
    }

    func dedupeImportTags(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().replacingOccurrences(of: " ", with: "-") }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    func isYouTubeImportURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("youtube.com") || host.contains("youtu.be") || host.contains("youtube-nocookie.com")
    }

    func canonicalYouTubeImportURL(from url: URL) -> URL {
        guard let id = youtubeImportVideoID(from: url) else { return url }
        return URL(string: "https://www.youtube.com/watch?v=\(id)") ?? url
    }

    func youtubeImportVideoID(from url: URL) -> String? {
        let host = url.host?.lowercased() ?? ""
        if host.contains("youtu.be") {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.isEmpty ? nil : id
        }
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let id = components.queryItems?.first(where: { $0.name == "v" })?.value,
           !id.isEmpty {
            return id
        }
        let parts = url.path.split(separator: "/")
        if let marker = parts.firstIndex(where: { ["shorts", "embed", "live"].contains(String($0).lowercased()) }),
           parts.indices.contains(parts.index(after: marker)) {
            return String(parts[parts.index(after: marker)])
        }
        return nil
    }

    func youtubeImportThumbnailURL(for url: URL) -> String? {
        guard let id = youtubeImportVideoID(from: url) else { return nil }
        return "https://i.ytimg.com/vi/\(id)/hqdefault.jpg"
    }

    func cleanedImportTitle(_ value: String?, for url: URL) -> String? {
        guard var title = value?.decodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            return nil
        }
        if isYouTubeImportURL(url) {
            title = title.replacingOccurrences(of: #"(?i)\s*-\s*youtube$"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"(?i)^watch\s*-\s*"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ["youtube", "watch"].contains(title.lowercased()) ? nil : title
    }

    func firstHTMLMetaContent(in html: String, keys: [String]) -> String? {
        for key in keys {
            let escapedKey = NSRegularExpression.escapedPattern(for: key)
            let patterns = [
                #"<meta[^>]+(?:property|name)=["']"# + escapedKey + #"["'][^>]+content=["']([^"']+)["'][^>]*>"#,
                #"<meta[^>]+content=["']([^"']+)["'][^>]+(?:property|name)=["']"# + escapedKey + #"["'][^>]*>"#
            ]
            for pattern in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                guard let match = regex.firstMatch(in: html, range: range),
                      match.numberOfRanges > 1,
                      let valueRange = Range(match.range(at: 1), in: html)
                else { continue }
                let value = String(html[valueRange]).decodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty { return value }
            }
        }
        return nil
    }

    func htmlTitle(in html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"<title[^>]*>(.*?)</title>"#, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: html)
        else { return nil }
        let value = String(html[valueRange]).decodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    func hostDisplayName(for url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        let cleaned = host.replacingOccurrences(of: "www.", with: "")
        return cleaned.split(separator: ".").first.map { String($0).capitalized }
    }

    func resolveImportURL(_ value: String, relativeTo baseURL: URL) -> String? {
        if let absolute = URL(string: value), absolute.scheme != nil {
            return absolute.absoluteString
        }
        return URL(string: value, relativeTo: baseURL)?.absoluteURL.absoluteString
    }
}

extension SAVIWebViewModel: WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pageReady = true
        importPendingSharesIfPossible()
        logWebViewState(after: 0.25)
        logWebViewState(after: 1.5)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           !url.isFileURL {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("[SAVIWeb] navigation failed: \(error.localizedDescription)")
        fallbackToRemotePageIfNeeded()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("[SAVIWeb] provisional navigation failed: \(error.localizedDescription)")
        fallbackToRemotePageIfNeeded()
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            UIApplication.shared.open(url)
        }
        return nil
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "savi" else { return }
        if let body = message.body as? [String: Any],
           let type = body["type"] as? String {
            if type == "requestPendingImports" {
                importPendingSharesIfPossible()
                return
            }

            if type == "console",
               let level = body["level"] as? String,
               let message = body["message"] as? String {
                NSLog("[SAVIWeb] \(level): \(message)")
                return
            }

            if type == "syncFolders",
               let payload = body["payload"] as? [String: Any] {
                syncFoldersFromWeb(payload)
                return
            }

            if type == "share",
               let payload = body["payload"] as? [String: Any] {
                presentShareSheet(payload)
            }
        }
    }
}

private extension String {
    var decodedHTMLString: String {
        guard let data = data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        return (try? NSAttributedString(data: data, options: options, documentAttributes: nil).string) ?? self
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private extension SAVIWebViewModel {
    func syncFoldersFromWeb(_ payload: [String: Any]) {
        guard let folders = payload["folders"] as? [[String: Any]] else { return }

        let normalized: [SharedFolder] = folders.enumerated().compactMap { index, raw in
            guard let id = raw["id"] as? String, !id.isEmpty,
                  let name = raw["name"] as? String, !name.isEmpty
            else {
                return nil
            }

            let system = (raw["system"] as? Bool) ?? false
            if id == "f-all" { return nil }

            let color = raw["color"] as? String
            let symbolName = folderSymbolName(for: id, name: name, system: system)

            return SharedFolder(
                id: id,
                name: name,
                color: color,
                system: system,
                symbolName: symbolName,
                order: index,
                isPublic: (raw["isPublic"] as? Bool) ?? (raw["is_public"] as? Bool) ?? false
            )
        }

        guard !normalized.isEmpty else { return }
        try? shareStore.saveFolders(normalized)
    }

    func folderSymbolName(for id: String, name: String, system: Bool) -> String {
        let key = "\(id) \(name)".lowercased()
        if key.contains("vault") || key.contains("private") || key.contains("passport") || key.contains("insurance") { return "lock.fill" }
        if key.contains("growth") || key.contains("career") || key.contains("business") || key.contains("productivity") || key.contains("ai hack") { return "bolt.fill" }
        if key.contains("wtf") || key.contains("wild") || key.contains("favorites") || key.contains("science stuff") { return "atom" }
        if key.contains("tinfoil") || key.contains("conspiracy") || key.contains("alien") { return "eye.fill" }
        if key.contains("lmao") || key.contains("lulz") || key.contains("meme") || key.contains("funny") || key.contains("lol") { return "theatermasks.fill" }
        if key.contains("health") || key.contains("fitness") || key.contains("wellness") { return "heart.fill" }
        if key.contains("recipe") || key.contains("food") || key.contains("cook") { return "fork.knife" }
        if key.contains("travel") || key.contains("place") || key.contains("map") || key.contains("trip") || key.contains("gps") { return "mappin.and.ellipse" }
        if key.contains("design") || key.contains("inspo") || key.contains("brand") || key.contains("ui") || key.contains("ux") { return "paintpalette.fill" }
        if key.contains("research") || key.contains("study") || key.contains("paper") { return "magnifyingglass" }
        if key.contains("must") || key.contains("later") || key.contains("watch") || key.contains("read") { return "bookmark.fill" }
        if key.contains("random") || key.contains("misc") { return "shuffle" }
        return system ? "folder.fill" : "folder"
    }

    func presentShareSheet(_ payload: [String: Any]) {
        DispatchQueue.main.async {
            var activityItems: [Any] = []

            if let text = payload["text"] as? String, !text.isEmpty {
                activityItems.append(text)
            } else if let title = payload["title"] as? String, !title.isEmpty {
                activityItems.append(title)
            }

            if let urlString = payload["url"] as? String,
               let url = URL(string: urlString) {
                activityItems.append(url)
            }

            guard !activityItems.isEmpty,
                  let presenter = self.topViewController()
            else {
                return
            }

            let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            if let popover = controller.popoverPresentationController {
                popover.sourceView = presenter.view
                popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.maxY - 44, width: 1, height: 1)
            }
            presenter.present(controller, animated: true)
        }
    }

    func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController

        if let navigation = root as? UINavigationController {
            return topViewController(base: navigation.visibleViewController)
        }

        if let tab = root as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }

        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }

        return root
    }

    static let bridgeScript = """
    window.SAVINative = window.SAVINative || {};
    window.SAVINative.postMessage = function(type, payload) {
      try {
        window.webkit.messageHandlers.savi.postMessage({ type: type, payload: payload || {} });
      } catch (error) {}
    };
    window.addEventListener('error', function(event) {
      var message = event && event.message ? String(event.message) : 'Unknown error';
      var source = event && event.filename ? String(event.filename) : '';
      var line = event && event.lineno ? ':' + String(event.lineno) : '';
      var column = event && event.colno ? ':' + String(event.colno) : '';
      window.SAVINative.postMessage('console', { level: 'error', message: message + ' ' + source + line + column });
    });
    window.addEventListener('unhandledrejection', function(event) {
      var reason = event && event.reason ? String(event.reason) : 'Unknown rejection';
      window.SAVINative.postMessage('console', { level: 'error', message: 'Unhandled rejection: ' + reason });
    });
    (function() {
      var levels = ['log', 'info', 'warn', 'error'];
      levels.forEach(function(level) {
        var original = console[level];
        console[level] = function() {
          try {
            var message = Array.prototype.slice.call(arguments).map(function(part) {
              if (typeof part === 'string') { return part; }
              try { return JSON.stringify(part); } catch (error) { return String(part); }
            }).join(' ');
            window.SAVINative.postMessage('console', { level: level, message: message });
          } catch (error) {}
          if (original) { original.apply(console, arguments); }
        };
      });
    })();
    window.SAVINative.publishFolders = function() {
      var STORAGE_KEY = 'savi_v1';
      var state;
      try { state = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}') || {}; } catch (error) { state = {}; }
      var folders = Array.isArray(state.folders) ? state.folders.filter(function(folder) {
        return folder && folder.id && folder.id !== 'f-all';
      }).map(function(folder) {
        return {
          id: folder.id || '',
          name: folder.name || '',
          color: folder.color || '',
          system: Boolean(folder.system)
        };
      }) : [];
      if (folders.length) {
        window.SAVINative.postMessage('syncFolders', { folders: folders });
      }
      return folders.length;
    };

    (function() {
      var originalSetItem = localStorage.setItem.bind(localStorage);
      localStorage.setItem = function(key, value) {
        originalSetItem(key, value);
        if (key === 'savi_v1') {
          try { window.SAVINative.publishFolders(); } catch (error) {}
        }
      };

      var queuePublish = function() {
        try { window.SAVINative.publishFolders(); } catch (error) {}
      };

      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
          setTimeout(queuePublish, 50);
        });
      } else {
        setTimeout(queuePublish, 50);
      }

      window.addEventListener('savi:native-import', queuePublish);
    })();

    window.SAVINative.importShares = function(shares) {
      var STORAGE_KEY = 'savi_v1';
      var ONBOARDED_KEY = 'savi_onboarded';
      var folderColors = {
        'f-private-vault': '#6C63FF',
        'f-growth': '#FF8A3D',
        'f-wtf-favorites': '#5875FF',
        'f-tinfoil': '#4C3D91',
        'f-lmao': '#FF4D6D',
        'f-health': '#25C48C',
        'f-recipes': '#FF9F43',
        'f-travel': '#18B7A0',
        'f-design': '#F15BB5',
        'f-research': '#6E68FF',
        'f-must-see': '#F7C948',
        'f-random': '#9AA5B1'
      };

      var state;
      try { state = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}') || {}; } catch (error) { state = {}; }
      if (!Array.isArray(state.folders)) { state.folders = []; }
      if (!Array.isArray(state.items)) { state.items = []; }

      var existing = new Set(state.items.map(function(item) {
        if (item.url) { return 'url:' + item.url; }
        return 'title:' + (item.title || '') + ':' + String(item.savedAt || '');
      }));

      var inferType = function(share) {
        var type = (share.type || '').toLowerCase();
        if ((type === 'url' || type === 'text') && share.url) {
          var value = share.url.toLowerCase();
          if (value.indexOf('youtube.com') >= 0 || value.indexOf('youtu.be') >= 0) { return 'video'; }
          if (value.indexOf('maps.google') >= 0 || value.indexOf('google.com/maps') >= 0 || value.indexOf('goo.gl/maps') >= 0) { return 'place'; }
          return 'link';
        }
        if (type === 'pdf') { return 'file'; }
        if (type === 'image') { return 'image'; }
        if (type === 'text') { return 'article'; }
        if (type === 'file') { return 'file'; }
        return type || 'link';
      };

      var inferFolder = function(share, type) {
        if (share.folder_id && String(share.folder_id).length) { return share.folder_id; }
        var source = (share.source_app || '').toLowerCase();
        var title = (share.title || '').toLowerCase();
        var text = (share.description || share.text || '').toLowerCase();
        var haystack = [source, title, text, share.url || ''].join(' ');
        if (type === 'image' || type === 'file') { return 'f-private-vault'; }
        if (type === 'place') { return 'f-travel'; }
        if (/health|parasite|parasites|wellness|fitness|doctor|medical/.test(haystack)) { return 'f-health'; }
        if (/recipe|cook|food|pasta|restaurant/.test(haystack)) { return 'f-recipes'; }
        if (/claude|chatgpt|prompt|automation|workflow|productivity|career|business|startup|negotiation|resume|ai /.test(haystack)) { return 'f-growth'; }
        if (/science|space|nasa|jwst|mars|quantum|discovery/.test(haystack)) { return 'f-wtf-favorites'; }
        if (/research|paper|analysis|report|study/.test(haystack)) { return 'f-research'; }
        if (/design|figma|dribbble|awwwards/.test(haystack)) { return 'f-design'; }
        if (/funny|meme|viral|lulz|rickroll|comedy/.test(haystack)) { return 'f-lmao'; }
        return 'f-random';
      };

      var inferSource = function(share) {
        if (share.source_app && share.source_app.length) { return share.source_app; }
        if (!share.url) { return 'Device'; }
        try {
          var host = new URL(share.url).hostname.replace(/^www\\./, '');
          if (host.indexOf('youtube') >= 0 || host.indexOf('youtu.be') >= 0) { return 'YouTube'; }
          if (host.indexOf('instagram') >= 0) { return 'Instagram'; }
          if (host.indexOf('tiktok') >= 0) { return 'TikTok'; }
          if (host.indexOf('reddit') >= 0) { return 'Reddit'; }
          if (host.indexOf('spotify') >= 0) { return 'Spotify'; }
          if (host.indexOf('google.com') >= 0 && share.url.indexOf('/maps') >= 0) { return 'Google Maps'; }
          return host.split('.')[0].replace(/\\b\\w/g, function(char) { return char.toUpperCase(); });
        } catch (error) {
          return 'Web';
        }
      };

      var imported = 0;
      (shares || []).forEach(function(share, index) {
        var type = inferType(share);
        var source = inferSource(share);
        var folderId = inferFolder(share, type);
        var uniqueKey = share.url ? 'url:' + share.url : 'title:' + (share.title || 'Shared item') + ':' + String(share.timestamp || index);
        if (existing.has(uniqueKey)) { return; }

        var tags = Array.isArray(share.tags) ? share.tags.slice() : [];
        if (type === 'place') { tags.push('location'); }
        if (source) { tags.push(String(source).toLowerCase().replace(/\\s+/g, '-')); }
        if (share.file_name) { tags.push('shared-file'); }

        state.items.unshift({
          id: 'native-' + String(share.timestamp || Date.now()) + '-' + String(index),
          title: share.title || 'Shared item',
          description: share.description || share.text || ((type === 'place') ? ('Saved place from ' + source + '.') : ('Shared from ' + source + '.')),
          url: share.url || '',
          source: source,
          type: type,
          folderId: folderId,
          tags: Array.from(new Set(tags.filter(Boolean))),
          color: folderColors[folderId] || '#6D7CFF',
          thumbnail: share.thumbnail || '',
          savedAt: Number(share.timestamp || Date.now())
        });

        existing.add(uniqueKey);
        imported += 1;
      });

      if (imported > 0) {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
        localStorage.setItem(ONBOARDED_KEY, 'true');
        window.dispatchEvent(new CustomEvent('savi:native-import', { detail: { count: imported } }));
      }

      return imported;
    };
    """
}

private extension SAVIWebViewModel {
    func logWebViewState(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            let script = """
            (function() {
              var root = document.getElementById('root');
              return JSON.stringify({
                readyState: document.readyState,
                title: document.title || '',
                rootLength: root ? root.innerHTML.length : -1,
                bodyLength: document.body ? document.body.innerText.length : -1,
                bg: document.body ? getComputedStyle(document.body).backgroundColor : '',
                reactType: typeof React,
                reactDomType: typeof ReactDOM,
                babelType: typeof Babel,
                bundleStarted: !!window.__saviBundleStarted,
                bundleExecuted: !!window.__saviBundleExecuted,
                bundleError: window.__saviBundleError || '',
                scriptCount: document.scripts ? document.scripts.length : -1,
                lastScriptType: document.scripts && document.scripts.length ? (document.scripts[document.scripts.length - 1].type || '') : '',
                lastScriptSrc: document.scripts && document.scripts.length ? (document.scripts[document.scripts.length - 1].src || '') : ''
              });
            })();
            """
            self.webView.evaluateJavaScript(script) { result, error in
                if let error {
                    NSLog("[SAVIWeb] eval error: \(error.localizedDescription)")
                    return
                }
                if let text = result as? String {
                    NSLog("[SAVIWeb] state: \(text)")
                } else {
                    NSLog("[SAVIWeb] state: \(String(describing: result))")
                }
            }
        }
    }
}
