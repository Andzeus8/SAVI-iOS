import Foundation
import SwiftUI
import UIKit
import WebKit

final class SAVIWebViewModel: NSObject, ObservableObject {
    let webView: WKWebView

    private let shareStore = PendingShareStore.shared
    private var didLoadInitialPage = false
    private var pageReady = false
    private var importInFlight = false

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

        let bundledIndexURL =
            Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources") ??
            Bundle.main.url(forResource: "index", withExtension: "html")

        guard let indexURL = bundledIndexURL else {
            return
        }

        webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
    }

    @objc private func handleForegroundTransition() {
        importPendingSharesIfPossible()
    }

    private func importPendingSharesIfPossible() {
        guard pageReady, !importInFlight else { return }

        let rawShares = shareStore.loadPendingShares()
        guard !rawShares.isEmpty else { return }

        importInFlight = true
        Task { [weak self] in
            guard let self else { return }

            let shares = rawShares
                .map { self.enrichForWebImport($0) }
                .sorted { lhs, rhs in lhs.timestamp < rhs.timestamp }

            guard let data = try? JSONEncoder().encode(shares),
                  let json = String(data: data, encoding: .utf8) else {
                self.importInFlight = false
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

}

extension SAVIWebViewModel: WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pageReady = true
        importPendingSharesIfPossible()
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
            let image = raw["image"] as? String
            let symbolName = folderSymbolName(for: id, name: name, system: system)

            return SharedFolder(
                id: id,
                name: name,
                color: color,
                image: image,
                system: system,
                symbolName: symbolName,
                order: index
            )
        }

        guard !normalized.isEmpty else { return }
        try? shareStore.saveFolders(normalized)

        if let recentRaw = payload["recentFolders"] as? [[String: Any]] {
            let recentFolders = recentRaw.compactMap { raw -> RecentFolder? in
                guard let id = raw["id"] as? String, !id.isEmpty,
                      let name = raw["name"] as? String, !name.isEmpty
                else { return nil }

                let fallback = normalized.first(where: { $0.id == id })
                return RecentFolder(
                    id: id,
                    name: name,
                    color: (raw["color"] as? String) ?? fallback?.color,
                    image: (raw["image"] as? String) ?? fallback?.image,
                    symbolName: (raw["symbol_name"] as? String) ?? fallback?.symbolName ?? folderSymbolName(for: id, name: name, system: false),
                    lastUsedAt: raw["last_used_at"] as? Double ?? Date().timeIntervalSince1970 * 1000
                )
            }
            if !recentFolders.isEmpty {
                try? shareStore.saveRecentFolders(recentFolders)
            }
        }
    }

    func folderSymbolName(for id: String, name: String, system: Bool) -> String {
        let key = "\(id) \(name)".lowercased()
        if key.contains("vault") || key.contains("private") || key.contains("passport") || key.contains("insurance") { return "lock.fill" }
        if key.contains("growth") || key.contains("career") || key.contains("business") || key.contains("productivity") { return "bolt.fill" }
        if key.contains("wtf") || key.contains("wild") || key.contains("favorites") { return "sparkles" }
        if key.contains("tinfoil") || key.contains("conspiracy") || key.contains("alien") { return "eye.fill" }
        if key.contains("lmao") || key.contains("meme") || key.contains("funny") || key.contains("lol") { return "theatermasks.fill" }
        if key.contains("health") || key.contains("fitness") || key.contains("wellness") { return "heart.fill" }
        if key.contains("recipe") || key.contains("food") || key.contains("cook") { return "fork.knife" }
        if key.contains("travel") || key.contains("place") || key.contains("map") || key.contains("trip") { return "airplane" }
        if key.contains("design") || key.contains("inspo") || key.contains("brand") || key.contains("ui") || key.contains("ux") { return "paintpalette.fill" }
        if key.contains("research") || key.contains("study") || key.contains("paper") { return "magnifyingglass" }
        if key.contains("must") || key.contains("later") || key.contains("watch") || key.contains("read") { return "bookmark.fill" }
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
    window.SAVINative.publishFolders = function() {
      var STORAGE_KEY = 'savi_v1';
      var state;
      try { state = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}') || {}; } catch (error) { state = {}; }
      var items = Array.isArray(state.items) ? state.items.slice() : [];
      var folders = Array.isArray(state.folders) ? state.folders.filter(function(folder) {
        return folder && folder.id && folder.id !== 'f-all';
      }).map(function(folder) {
        return {
          id: folder.id || '',
          name: folder.name || '',
          color: folder.color || '',
          image: folder.image || '',
          system: Boolean(folder.system)
        };
      }) : [];

      var recentFolderIds = [];
      var recentFolders = [];
      items
        .slice()
        .sort(function(a, b) { return Number(b.savedAt || 0) - Number(a.savedAt || 0); })
        .forEach(function(item) {
          if (!item || !item.folderId || recentFolderIds.indexOf(item.folderId) >= 0) { return; }
          var folder = folders.find(function(entry) { return entry.id === item.folderId; });
          if (!folder) { return; }
          recentFolderIds.push(item.folderId);
          recentFolders.push({
            id: folder.id,
            name: folder.name,
            color: folder.color || '',
            image: folder.image || '',
            last_used_at: Number(item.savedAt || Date.now())
          });
        });

      if (folders.length) {
        window.SAVINative.postMessage('syncFolders', { folders: folders, recentFolders: recentFolders.slice(0, 5) });
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
          setTimeout(function() {
            try { window.SAVINative.processPendingMetadata(); } catch (error) {}
          }, 250);
        });
      } else {
        setTimeout(queuePublish, 50);
        setTimeout(function() {
          try { window.SAVINative.processPendingMetadata(); } catch (error) {}
        }, 250);
      }

      window.addEventListener('savi:native-import', function() {
        queuePublish();
        setTimeout(function() {
          try { window.SAVINative.processPendingMetadata(); } catch (error) {}
        }, 200);
      });
    })();

    window.SAVINative.processPendingMetadata = async function() {
      var STORAGE_KEY = 'savi_v1';
      var state;
      try { state = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}') || {}; } catch (error) { state = {}; }
      if (!Array.isArray(state.items)) { return 0; }
      if (!Array.isArray(state.folders)) { state.folders = []; }
      if (typeof fetchLinkMetadata !== 'function') { return 0; }

      var pendingItems = state.items.filter(function(item) {
        return item && item.pendingMetadata && item.url && /^https?:/i.test(item.url);
      });
      if (!pendingItems.length) { return 0; }

      var processed = 0;
      for (var i = 0; i < pendingItems.length; i += 1) {
        var item = pendingItems[i];
        try {
          var metadata = await fetchLinkMetadata(item.url, state.folders);
          if (metadata) {
            item.title = metadata.title || item.title || item.url;
            item.description = metadata.description || item.description || '';
            item.thumbnail = metadata.thumbnail || item.thumbnail || '';
            item.type = metadata.type || item.type || 'link';
            item.source = metadata.source || item.source || 'Web';
            if (Array.isArray(metadata.tags) && metadata.tags.length) {
              item.tags = Array.from(new Set([].concat(item.tags || [], metadata.tags))).filter(Boolean);
            }
            if (!item.folderId && metadata.folderId) {
              item.folderId = metadata.folderId;
            }
            item.pendingMetadata = false;
            processed += 1;
          }
        } catch (error) {}
      }

      if (processed > 0) {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
        window.dispatchEvent(new CustomEvent('savi:native-metadata-updated', { detail: { count: processed } }));
      }

      return processed;
    };

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
        'f-must-see': '#F7C948'
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
        if (/recipe|cook|food|pasta|restaurant/.test(haystack)) { return 'f-recipes'; }
        if (/research|paper|gpt|claude|ai|science/.test(haystack)) { return 'f-research'; }
        if (/design|figma|dribbble|awwwards/.test(haystack)) { return 'f-design'; }
        return 'f-must-see';
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
          savedAt: Number(share.timestamp || Date.now()),
          pendingMetadata: Boolean(share.needs_metadata)
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
