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

struct LegacyMigrationHost: UIViewRepresentable {
    let onComplete: (LegacyMigrationPayload) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "saviMigration")
        controller.addUserScript(WKUserScript(
            source: Self.disableClipboardScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        ))
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.websiteDataStore = .default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        if let indexURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources") ??
            Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
        } else {
            DispatchQueue.main.async {
                onComplete(LegacyMigrationPayload(storageJSON: nil, seedStorageJSON: nil, uiPrefsJSON: nil, onboarded: false, demoSuppressed: false, assets: [], error: "legacy_bundle_missing"))
            }
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private static let disableClipboardScript = """
    (function() {
      function blockedClipboardPromise() {
        return Promise.reject(new Error('SAVI migration disables clipboard access.'));
      }
      try {
        if (navigator.clipboard) {
          navigator.clipboard.read = blockedClipboardPromise;
          navigator.clipboard.readText = blockedClipboardPromise;
        }
      } catch (_) {}
    })();
    """

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        private let onComplete: (LegacyMigrationPayload) -> Void
        private var didComplete = false

        init(onComplete: @escaping (LegacyMigrationPayload) -> Void) {
            self.onComplete = onComplete
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !didComplete else { return }
            let script = """
            void (async function() {
              const payload = {
                storage: null,
                seedStorage: null,
                uiPrefs: null,
                onboarded: false,
                demoSuppressed: false,
                assets: [],
                error: null
              };
              try {
                payload.storage = localStorage.getItem('savi_v1');
                if (typeof SEED_FOLDERS !== 'undefined' && typeof SEED_ITEMS !== 'undefined') {
                  payload.seedStorage = JSON.stringify({ folders: SEED_FOLDERS, items: SEED_ITEMS });
                }
                payload.uiPrefs = localStorage.getItem('savi_ui_v1');
                payload.onboarded = localStorage.getItem('savi_onboarded') === 'true';
                payload.demoSuppressed = localStorage.getItem('savi_demo_suppressed') === 'true';
                if ('indexedDB' in window) {
                  payload.assets = await new Promise((resolve) => {
                    const request = indexedDB.open('savi_assets', 1);
                    request.onerror = () => resolve([]);
                    request.onsuccess = () => {
                      const db = request.result;
                      if (!db.objectStoreNames.contains('assets')) { resolve([]); return; }
                      const tx = db.transaction('assets', 'readonly');
                      const store = tx.objectStore('assets');
                      const getAll = store.getAll();
                      getAll.onerror = () => resolve([]);
                      getAll.onsuccess = async () => {
                        const rows = getAll.result || [];
                        const converted = await Promise.all(rows.map((row) => new Promise((resolveRow) => {
                          if (!row || !row.blob) { resolveRow(null); return; }
                          const reader = new FileReader();
                          reader.onerror = () => resolveRow(null);
                          reader.onload = () => resolveRow({
                            id: row.id,
                            name: row.name || '',
                            type: row.type || row.blob.type || 'application/octet-stream',
                            size: typeof row.size === 'number' ? row.size : row.blob.size,
                            dataUrl: reader.result
                          });
                          reader.readAsDataURL(row.blob);
                        })));
                        resolve(converted.filter(Boolean));
                      };
                    };
                  });
                }
              } catch (error) {
                payload.error = String(error && error.message ? error.message : error);
              }
              window.webkit.messageHandlers.saviMigration.postMessage(JSON.stringify(payload));
            })();
            """
            webView.evaluateJavaScript(script) { _, error in
                if let error {
                    self.finish(LegacyMigrationPayload(storageJSON: nil, seedStorageJSON: nil, uiPrefsJSON: nil, onboarded: false, demoSuppressed: false, assets: [], error: error.localizedDescription))
                }
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "saviMigration",
                  let json = message.body as? String,
                  let data = json.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                finish(LegacyMigrationPayload(storageJSON: nil, seedStorageJSON: nil, uiPrefsJSON: nil, onboarded: false, demoSuppressed: false, assets: [], error: "migration_payload_invalid"))
                return
            }

            let assets: [SaviBackupAsset] = (object["assets"] as? [[String: Any]] ?? []).compactMap { row in
                guard let id = row["id"] as? String,
                      let dataUrl = row["dataUrl"] as? String
                else { return nil }
                return SaviBackupAsset(
                    id: id,
                    name: row["name"] as? String ?? "",
                    type: row["type"] as? String ?? "application/octet-stream",
                    size: Int64((row["size"] as? NSNumber)?.int64Value ?? 0),
                    dataUrl: dataUrl
                )
            }
            finish(
                LegacyMigrationPayload(
                    storageJSON: object["storage"] as? String,
                    seedStorageJSON: object["seedStorage"] as? String,
                    uiPrefsJSON: object["uiPrefs"] as? String,
                    onboarded: object["onboarded"] as? Bool ?? false,
                    demoSuppressed: object["demoSuppressed"] as? Bool ?? false,
                    assets: assets,
                    error: object["error"] as? String
                )
            )
        }

        private func finish(_ payload: LegacyMigrationPayload) {
            guard !didComplete else { return }
            didComplete = true
            DispatchQueue.main.async {
                self.onComplete(payload)
            }
        }
    }
}

// MARK: - QuickLook

struct AssetPreviewURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct WebPreviewURL: Identifiable {
    let url: URL

    var id: String {
        url.absoluteString
    }
}

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

struct SafariLinkPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.dismissButtonStyle = .done
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Seeds

enum SaviSeeds {
    static let folders: [SaviFolder] = [
        .init(id: "f-must-see", name: "Watch / Read Later", color: "#7A35E8", image: nil, system: false, symbolName: "bookmark.fill", order: 0),
        .init(id: "f-growth", name: "AI & Work", color: "#F47A3B", image: nil, system: false, symbolName: "bolt.fill", order: 1),
        .init(id: "f-lmao", name: "Memes & Laughs", color: "#D6F83A", image: nil, system: false, symbolName: "theatermasks.fill", order: 2),
        .init(id: "f-travel", name: "Places & Trips", color: "#68C6E8", image: nil, system: false, symbolName: "mappin.and.ellipse", order: 3),
        .init(id: "f-recipes", name: "Recipes & Food", color: "#FFB978", image: nil, system: false, symbolName: "fork.knife", order: 4),
        .init(id: "f-paste-bin", name: "Notes & Clips", color: "#9286A8", image: nil, system: false, symbolName: "clipboard.fill", order: 5),
        .init(id: "f-private-vault", name: "Private Vault", color: "#171026", image: nil, system: false, symbolName: "lock.fill", order: 6, locked: true),
        .init(id: "f-research", name: "Research & PDFs", color: "#5ADDCB", image: nil, system: false, symbolName: "magnifyingglass", order: 7),
        .init(id: "f-design", name: "Design Inspo", color: "#DE5B98", image: nil, system: false, symbolName: "paintpalette.fill", order: 8),
        .init(id: "f-health", name: "Health", color: "#70D59B", image: nil, system: false, symbolName: "heart.fill", order: 9),
        .init(id: "f-wtf-favorites", name: "Science Finds", color: "#73CDED", image: nil, system: false, symbolName: "atom", order: 10),
        .init(id: "f-tinfoil", name: "Rabbit Holes", color: "#7B3FE4", image: nil, system: false, symbolName: "eye.fill", order: 11),
        .init(id: "f-random", name: "Everything Else", color: "#FFE16A", image: nil, system: false, symbolName: "shuffle", order: 12),
        .init(id: "f-all", name: "All Saves", color: "#D6F83A", image: nil, system: true, symbolName: "sparkles", order: 13)
    ]

    static let legacyFolderColors: [String: String] = [
        "f-must-see": "#4C1D95",
        "f-paste-bin": "#8A7CA8",
        "f-wtf-favorites": "#C4B5FD",
        "f-growth": "#A78BFA",
        "f-lmao": "#D8FF3C",
        "f-private-vault": "#0A0614",
        "f-travel": "#B8D4F5",
        "f-recipes": "#F4C6A5",
        "f-health": "#C4E8D4",
        "f-design": "#E8DCF5",
        "f-research": "#DDD1F3",
        "f-tinfoil": "#6D28D9",
        "f-random": "#FFE066",
        "f-all": "#D8FF3C"
    ]

    static func picsumThumb(_ seed: String, width: Int = 900, height: Int = 1100) -> String {
        "https://picsum.photos/seed/\(seed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? seed)/\(width)/\(height)"
    }

    static func youtubeThumb(_ videoId: String) -> String {
        "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
    }

    private static let sampleColors: [String: String] = Dictionary(uniqueKeysWithValues: folders.map { ($0.id, $0.color) })

    private static func hoursAgo(_ value: Double) -> Double {
        Date().timeIntervalSince1970 * 1000 - value * 3_600_000
    }

    private static func item(
        id: String,
        title: String,
        description: String,
        url: String? = nil,
        source: String,
        type: SaviItemType,
        folderId: String,
        tags: [String],
        thumbnailSeed: String? = nil,
        hoursAgo: Double,
        assetName: String? = nil,
        assetMime: String? = nil,
        assetSize: Int64? = nil
    ) -> SaviItem {
        SaviItem(
            id: id,
            title: title,
            itemDescription: description,
            url: url,
            source: source,
            type: type,
            folderId: folderId,
            tags: tags,
            thumbnail: thumbnailSeed.map { picsumThumb($0, width: 720, height: 720) },
            savedAt: Self.hoursAgo(hoursAgo),
            color: sampleColors[folderId],
            assetName: assetName,
            assetMime: assetMime,
            assetSize: assetSize,
            demo: true
        )
    }

    static let items: [SaviItem] = [
        item(id: "sample-watch-claude", title: "How to use Claude like a thinking partner", description: "A practical setup for long-context productivity and better saved research.", url: "https://example.com/savi-samples/claude-thinking-partner", source: "Web", type: .article, folderId: "f-must-see", tags: ["read-later", "ai", "productivity"], thumbnailSeed: "savi-claude-thinking", hoursAgo: 2),
        item(id: "sample-ai-prompts", title: "Prompt checklist for messy projects", description: "A quick note for turning vague ideas into useful instructions.", source: "Paste", type: .text, folderId: "f-growth", tags: ["prompt", "ai", "checklist"], hoursAgo: 4),
        item(id: "sample-meme-goyo", title: "Goyo goyo with lyrics", description: "A funny video save that shows how memes land in SAVI.", url: "https://youtube.com/watch?v=savi-goyo-sample", source: "YouTube", type: .video, folderId: "f-lmao", tags: ["meme", "funny", "youtube"], thumbnailSeed: "savi-goyo-lyrics", hoursAgo: 6),
        item(id: "sample-place-ramen", title: "Tokyo ramen map pin", description: "A restaurant idea saved from Maps for a future trip.", url: "https://maps.apple.com/?q=Tokyo%20ramen", source: "Maps", type: .place, folderId: "f-travel", tags: ["maps", "tokyo", "food"], thumbnailSeed: "savi-tokyo-ramen", hoursAgo: 8),
        item(id: "sample-food-pasta", title: "Late-night pasta formula", description: "A fast dinner idea you would otherwise lose in a scroll.", url: "https://example.com/savi-samples/late-night-pasta", source: "Web", type: .article, folderId: "f-recipes", tags: ["recipe", "dinner", "pasta"], thumbnailSeed: "savi-late-pasta", hoursAgo: 12),
        item(id: "sample-note-launch", title: "Paste: launch checklist", description: "Export backup, smoke-test the share sheet, verify search, then send the build.", source: "Paste", type: .text, folderId: "f-paste-bin", tags: ["note", "checklist", "work"], hoursAgo: 16),
        item(id: "sample-research-constitutional-ai", title: "Constitutional AI notes", description: "An important research save on model behavior and safety methods.", url: "https://example.com/savi-samples/constitutional-ai", source: "Research", type: .article, folderId: "f-research", tags: ["paper", "ai", "research"], thumbnailSeed: "savi-constitutional-ai", hoursAgo: 20),
        item(id: "sample-design-mobile-nav", title: "Brutalist mobile nav inspiration", description: "A compact visual reference for thumb-first interface ideas.", url: "https://example.com/savi-samples/mobile-nav-inspo", source: "Behance", type: .image, folderId: "f-design", tags: ["design", "mobile", "ui"], thumbnailSeed: "savi-mobile-nav", hoursAgo: 24),
        item(id: "sample-health-recovery", title: "Workout recovery protocol", description: "Sleep, mobility, hydration, and protein notes for busy weeks.", url: "https://example.com/savi-samples/recovery-protocol", source: "Web", type: .article, folderId: "f-health", tags: ["health", "fitness", "recovery"], thumbnailSeed: "savi-recovery", hoursAgo: 28),
        item(id: "sample-science-webb", title: "NASA Webb image explainer", description: "A space discovery save for the science things worth revisiting.", url: "https://example.com/savi-samples/webb-image", source: "NASA", type: .article, folderId: "f-wtf-favorites", tags: ["space", "nasa", "science"], thumbnailSeed: "savi-webb-space", hoursAgo: 32),
        item(id: "sample-rabbit-tinfoil", title: "Tinfoil hat origin story", description: "A weird internet rabbit hole saved for later fact-checking.", url: "https://example.com/savi-samples/tinfoil-origin", source: "Web", type: .article, folderId: "f-tinfoil", tags: ["rabbit-hole", "history", "internet"], thumbnailSeed: "savi-tinfoil", hoursAgo: 36),
        item(id: "sample-random-thing", title: "Thing I could not classify", description: "A mystery save that shows where leftovers go until you sort them.", url: "https://example.com/savi-samples/mystery-save", source: "Web", type: .link, folderId: "f-random", tags: ["misc", "unsorted"], thumbnailSeed: "savi-mystery-save", hoursAgo: 40),
        item(id: "sample-private-passport", title: "Sample passport checklist", description: "Fake private note: renewal date, scan reminder, and travel document checklist.", source: "SAVI", type: .text, folderId: "f-private-vault", tags: ["sample", "private", "passport"], hoursAgo: 44),

        item(id: "sample-watch-numa", title: "Numa Numa explained", description: "Gary Brolsma's webcam lip-sync artifact, saved as an internet-history video.", url: "https://youtube.com/watch?v=savi-numa-sample", source: "YouTube", type: .video, folderId: "f-must-see", tags: ["video", "youtube", "internet-history"], thumbnailSeed: "savi-numa-numa", hoursAgo: 52),
        item(id: "sample-watch-wwdc", title: "Apple WWDC recap", description: "A short conference recap to watch when you have ten quiet minutes.", url: "https://example.com/savi-samples/wwdc-recap", source: "YouTube", type: .video, folderId: "f-must-see", tags: ["video", "apple", "tech"], thumbnailSeed: "savi-wwdc-recap", hoursAgo: 62),
        item(id: "sample-watch-extension", title: "The browser extension I keep using", description: "A practical link about one tool that keeps saving tiny bits of time.", url: "https://example.com/savi-samples/browser-extension", source: "Web", type: .article, folderId: "f-must-see", tags: ["read-later", "tools"], thumbnailSeed: "savi-browser-extension", hoursAgo: 74),
        item(id: "sample-watch-coffee-tech", title: "Japan's quiet coffee tech", description: "A calm video about vending machines, craft, and delightful little systems.", url: "https://youtube.com/watch?v=savi-coffee-tech", source: "YouTube", type: .video, folderId: "f-must-see", tags: ["video", "japan", "tech"], thumbnailSeed: "savi-coffee-tech", hoursAgo: 91),

        item(id: "sample-ai-automation", title: "AI automation starter pack", description: "Batch renaming, scraping, reminders, exports, and tiny scripts that pay rent.", url: "https://example.com/savi-samples/ai-automation", source: "Web", type: .article, folderId: "f-growth", tags: ["ai", "automation", "productivity"], thumbnailSeed: "savi-ai-automation", hoursAgo: 104),
        item(id: "sample-ai-workspace", title: "Claude workspace setup", description: "Folders, long context, and prompts arranged so the work stays findable.", url: "https://example.com/savi-samples/claude-workspace", source: "Web", type: .article, folderId: "f-growth", tags: ["claude", "workspace", "ai"], thumbnailSeed: "savi-workspace", hoursAgo: 117),
        item(id: "sample-ai-inbox-zero", title: "Inbox zero with shortcuts", description: "A workflow for turning emails into reminders, notes, and SAVI saves.", url: "https://example.com/savi-samples/inbox-zero", source: "Web", type: .article, folderId: "f-growth", tags: ["workflow", "shortcuts", "productivity"], thumbnailSeed: "savi-inbox-zero", hoursAgo: 132),
        item(id: "sample-ai-meeting-tasks", title: "Meeting notes to tasks workflow", description: "A reusable checklist for converting messy notes into a real plan.", source: "Paste", type: .text, folderId: "f-growth", tags: ["meeting", "workflow", "tasks"], hoursAgo: 149),

        item(id: "sample-meme-cursed", title: "Perfectly cursed screenshot", description: "An internet moment that belongs exactly where it is.", source: "Device", type: .image, folderId: "f-lmao", tags: ["meme", "screenshot", "funny"], thumbnailSeed: "savi-cursed-screenshot", hoursAgo: 166),
        item(id: "sample-meme-group-chat", title: "Group chat reaction image", description: "The reaction image you will absolutely need again.", source: "Photos", type: .image, folderId: "f-lmao", tags: ["reaction", "meme", "image"], thumbnailSeed: "savi-reaction-image", hoursAgo: 184),
        item(id: "sample-meme-typo", title: "A+ accidental typo", description: "A tiny screenshot save with extremely specific future usefulness.", source: "Device", type: .image, folderId: "f-lmao", tags: ["screenshot", "funny"], thumbnailSeed: "savi-accidental-typo", hoursAgo: 202),
        item(id: "sample-meme-review", title: "The funniest product review", description: "A saved review that somehow became the whole joke.", url: "https://example.com/savi-samples/funny-review", source: "Web", type: .link, folderId: "f-lmao", tags: ["funny", "review", "web"], thumbnailSeed: "savi-funny-review", hoursAgo: 221),

        item(id: "sample-place-museum", title: "Weekend museum idea", description: "A place save for the kind of Saturday that starts with coffee.", url: "https://maps.apple.com/?q=museum", source: "Maps", type: .place, folderId: "f-travel", tags: ["maps", "museum", "weekend"], thumbnailSeed: "savi-museum", hoursAgo: 240),
        item(id: "sample-place-airport-coffee", title: "Best airport coffee backup", description: "A useful pin for the next time your gate changes twice.", url: "https://maps.apple.com/?q=airport%20coffee", source: "Maps", type: .place, folderId: "f-travel", tags: ["maps", "coffee", "travel"], thumbnailSeed: "savi-airport-coffee", hoursAgo: 262),
        item(id: "sample-place-hotel", title: "Tiny hotel with great reviews", description: "A stay idea saved before it disappears into browser tabs.", url: "https://example.com/savi-samples/tiny-hotel", source: "Web", type: .place, folderId: "f-travel", tags: ["hotel", "trip", "travel"], thumbnailSeed: "savi-tiny-hotel", hoursAgo: 284),
        item(id: "sample-place-walk", title: "Walking route for a lazy Sunday", description: "A route save with snacks, shade, and one perfect bookstore stop.", url: "https://maps.apple.com/?q=walking%20route", source: "Maps", type: .place, folderId: "f-travel", tags: ["route", "maps", "weekend"], thumbnailSeed: "savi-sunday-walk", hoursAgo: 306),

        item(id: "sample-food-salmon", title: "Crispy salmon bowl", description: "A dinner recipe with crunchy rice, cucumbers, and sauce worth keeping.", url: "https://example.com/savi-samples/salmon-bowl", source: "Web", type: .article, folderId: "f-recipes", tags: ["recipe", "salmon", "dinner"], thumbnailSeed: "savi-salmon-bowl", hoursAgo: 330),
        item(id: "sample-food-wrap", title: "3-minute breakfast wrap", description: "A quick food save for mornings that got away from you.", url: "https://example.com/savi-samples/breakfast-wrap", source: "TikTok", type: .video, folderId: "f-recipes", tags: ["recipe", "breakfast", "tiktok"], thumbnailSeed: "savi-breakfast-wrap", hoursAgo: 354),
        item(id: "sample-food-shopping", title: "Dinner party shopping list", description: "A pasted grocery list that is much easier to find here than in Notes.", source: "Paste", type: .text, folderId: "f-recipes", tags: ["groceries", "dinner", "list"], hoursAgo: 378),
        item(id: "sample-food-taco-sauce", title: "The taco sauce worth saving", description: "A tiny recipe link with huge future leftovers energy.", url: "https://example.com/savi-samples/taco-sauce", source: "Web", type: .article, folderId: "f-recipes", tags: ["recipe", "tacos", "sauce"], thumbnailSeed: "savi-taco-sauce", hoursAgo: 402),

        item(id: "sample-note-gifts", title: "Gift ideas note", description: "Dad: good flashlight. Mia: ceramic mug. Save before December panic.", source: "Paste", type: .text, folderId: "f-paste-bin", tags: ["note", "gifts"], hoursAgo: 426),
        item(id: "sample-note-packing", title: "Packing list snippet", description: "Charger, passport, headphones, sunscreen, tiny umbrella, patience.", source: "Clipboard", type: .text, folderId: "f-paste-bin", tags: ["packing", "travel", "note"], hoursAgo: 450),
        item(id: "sample-note-email", title: "Reusable email reply", description: "Thanks for sending this over. I will review it and get back to you by Friday.", source: "Paste", type: .text, folderId: "f-paste-bin", tags: ["template", "email"], hoursAgo: 474),
        item(id: "sample-note-quote", title: "Random quote to keep", description: "A line that made sense at 1:12 AM and may make sense again later.", source: "Clipboard", type: .text, folderId: "f-paste-bin", tags: ["quote", "note"], hoursAgo: 498),

        item(id: "sample-private-insurance", title: "Sample insurance note", description: "Fake private note: policy number placeholder, renewal month, support phone.", source: "SAVI", type: .text, folderId: "f-private-vault", tags: ["sample", "private", "insurance"], hoursAgo: 522),
        item(id: "sample-private-receipt", title: "Sample return receipt PDF", description: "Fake receipt sample that demonstrates protected document saves.", source: "Device", type: .file, folderId: "f-private-vault", tags: ["sample", "receipt", "pdf"], thumbnailSeed: "savi-sample-receipt", hoursAgo: 546, assetName: "sample-return-receipt.pdf", assetMime: "application/pdf", assetSize: 142_000),
        item(id: "sample-private-wifi", title: "Sample Wi-Fi password note", description: "Fake password sample: network name, guest code placeholder, router note.", source: "SAVI", type: .text, folderId: "f-private-vault", tags: ["sample", "private", "password"], hoursAgo: 570),
        item(id: "sample-private-doctor", title: "Sample doctor appointment note", description: "Fake private note: appointment time, questions to ask, follow-up reminder.", source: "SAVI", type: .text, folderId: "f-private-vault", tags: ["sample", "medical", "private"], hoursAgo: 594),

        item(id: "sample-research-climate", title: "Climate report PDF", description: "A saved PDF-style report for testing document search and filters.", source: "Device", type: .file, folderId: "f-research", tags: ["pdf", "report", "climate"], thumbnailSeed: "savi-climate-report", hoursAgo: 618, assetName: "sample-climate-report.pdf", assetMime: "application/pdf", assetSize: 920_000),
        item(id: "sample-research-sleep", title: "Sleep study summary", description: "A research summary about light, recovery, and better bedtime routines.", url: "https://example.com/savi-samples/sleep-study", source: "PubMed", type: .article, folderId: "f-research", tags: ["study", "sleep", "health"], thumbnailSeed: "savi-sleep-study", hoursAgo: 642),
        item(id: "sample-research-market", title: "Market sizing spreadsheet", description: "A spreadsheet save for testing docs, work research, and file search.", source: "Device", type: .file, folderId: "f-research", tags: ["spreadsheet", "market", "research"], thumbnailSeed: "savi-market-sheet", hoursAgo: 666, assetName: "sample-market-sizing.xlsx", assetMime: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", assetSize: 286_000),
        item(id: "sample-research-paper", title: "Academic paper to revisit", description: "A dense paper that belongs in research, not the read-later pile.", url: "https://example.com/savi-samples/academic-paper", source: "arXiv", type: .article, folderId: "f-research", tags: ["paper", "arxiv", "pdf"], thumbnailSeed: "savi-academic-paper", hoursAgo: 690),

        item(id: "sample-design-palette", title: "Color palette screenshot", description: "A screenshot save for the next time a project needs a mood fast.", source: "Device", type: .image, folderId: "f-design", tags: ["color", "screenshot", "design"], thumbnailSeed: "savi-color-palette", hoursAgo: 714),
        item(id: "sample-design-spacing", title: "Landing page spacing idea", description: "A layout reference for card rhythm, margins, and readable sections.", url: "https://example.com/savi-samples/spacing", source: "Dribbble", type: .image, folderId: "f-design", tags: ["layout", "web", "design"], thumbnailSeed: "savi-spacing", hoursAgo: 738),
        item(id: "sample-design-type", title: "Type pairing reference", description: "A typography idea saved because the right font changes the whole mood.", url: "https://example.com/savi-samples/type-pairing", source: "Web", type: .article, folderId: "f-design", tags: ["typography", "font", "design"], thumbnailSeed: "savi-type-pairing", hoursAgo: 762),
        item(id: "sample-design-empty-state", title: "Beautiful empty state", description: "A friendly screen that explains what to do without shouting.", url: "https://example.com/savi-samples/empty-state", source: "Web", type: .image, folderId: "f-design", tags: ["ui", "empty-state", "design"], thumbnailSeed: "savi-empty-state", hoursAgo: 786),

        item(id: "sample-health-stretch", title: "Stretch routine video", description: "A simple mobility video for the stiff-neck future version of you.", url: "https://youtube.com/watch?v=savi-stretch-routine", source: "YouTube", type: .video, folderId: "f-health", tags: ["fitness", "mobility", "youtube"], thumbnailSeed: "savi-stretch", hoursAgo: 810),
        item(id: "sample-health-protein", title: "Protein snack list", description: "A quick note for better snacks between calls.", source: "Paste", type: .text, folderId: "f-health", tags: ["nutrition", "protein", "note"], hoursAgo: 834),
        item(id: "sample-health-dentist", title: "Dental appointment reminder", description: "A practical health save that proves not everything is a link.", source: "SAVI", type: .text, folderId: "f-health", tags: ["appointment", "health"], hoursAgo: 858),
        item(id: "sample-health-sleep", title: "Sleep hygiene article", description: "A readable guide for light, screens, caffeine, and actually resting.", url: "https://example.com/savi-samples/sleep-hygiene", source: "Web", type: .article, folderId: "f-health", tags: ["sleep", "wellness", "article"], thumbnailSeed: "savi-sleep-hygiene", hoursAgo: 882),

        item(id: "sample-science-math", title: "Beautiful math thread", description: "A visual explanation of prime numbers and patterns worth keeping.", url: "https://example.com/savi-samples/beautiful-math", source: "Web", type: .article, folderId: "f-wtf-favorites", tags: ["math", "science", "thread"], thumbnailSeed: "savi-beautiful-math", hoursAgo: 906),
        item(id: "sample-science-sea", title: "Deep sea creature article", description: "A strange biology save from the part of Earth that looks imaginary.", url: "https://example.com/savi-samples/deep-sea", source: "Science", type: .article, folderId: "f-wtf-favorites", tags: ["biology", "deep-sea", "science"], thumbnailSeed: "savi-deep-sea", hoursAgo: 930),
        item(id: "sample-science-robot", title: "Tiny robot research clip", description: "A robotics video that belongs with real discoveries, not random tech noise.", url: "https://youtube.com/watch?v=savi-tiny-robot", source: "YouTube", type: .video, folderId: "f-wtf-favorites", tags: ["robotics", "science", "video"], thumbnailSeed: "savi-tiny-robot", hoursAgo: 954),
        item(id: "sample-science-volcano", title: "Volcano camera feed", description: "A live science link for the dramatic rocks department.", url: "https://example.com/savi-samples/volcano-feed", source: "Web", type: .link, folderId: "f-wtf-favorites", tags: ["volcano", "science", "nature"], thumbnailSeed: "savi-volcano", hoursAgo: 978),

        item(id: "sample-rabbit-lost-media", title: "Lost media rabbit hole", description: "A weird media-history dive to enjoy when curiosity wins.", url: "https://example.com/savi-samples/lost-media", source: "Reddit", type: .link, folderId: "f-tinfoil", tags: ["rabbit-hole", "lost-media", "reddit"], thumbnailSeed: "savi-lost-media", hoursAgo: 1002),
        item(id: "sample-rabbit-map", title: "Ancient map mystery", description: "A mystery article saved for later, with just enough skepticism.", url: "https://example.com/savi-samples/ancient-map", source: "Web", type: .article, folderId: "f-tinfoil", tags: ["mystery", "history", "map"], thumbnailSeed: "savi-ancient-map", hoursAgo: 1026),
        item(id: "sample-rabbit-ufo", title: "UFO article to fact-check", description: "A fringe story kept as a rabbit hole, not confused for science.", url: "https://example.com/savi-samples/ufo-fact-check", source: "Web", type: .article, folderId: "f-tinfoil", tags: ["ufo", "fact-check", "rabbit-hole"], thumbnailSeed: "savi-ufo-fact-check", hoursAgo: 1050),
        item(id: "sample-rabbit-folklore", title: "Internet folklore timeline", description: "A chronology of strange web stories and the screenshots that survived.", url: "https://example.com/savi-samples/internet-folklore", source: "Web", type: .article, folderId: "f-tinfoil", tags: ["internet", "folklore", "history"], thumbnailSeed: "savi-folklore", hoursAgo: 1074),

        item(id: "sample-random-later", title: "Maybe useful later", description: "A save that has no obvious home yet, which is exactly the point.", url: "https://example.com/savi-samples/maybe-useful", source: "Web", type: .link, folderId: "f-random", tags: ["misc", "later"], thumbnailSeed: "savi-maybe-useful", hoursAgo: 1098),
        item(id: "sample-random-product", title: "Random product page", description: "A product link saved before the tab pile eats it.", url: "https://example.com/savi-samples/random-product", source: "Web", type: .link, folderId: "f-random", tags: ["product", "misc"], thumbnailSeed: "savi-random-product", hoursAgo: 1122),
        item(id: "sample-random-screenshot", title: "Mystery screenshot", description: "A screenshot with no context, lovingly contained.", source: "Device", type: .image, folderId: "f-random", tags: ["screenshot", "misc"], thumbnailSeed: "savi-mystery-screenshot", hoursAgo: 1146),
        item(id: "sample-random-untitled", title: "Untitled link rescue", description: "A generic link that SAVI keeps reachable until metadata improves.", url: "https://example.com/savi-samples/untitled", source: "Web", type: .link, folderId: "f-random", tags: ["link", "unsorted"], thumbnailSeed: "savi-untitled-rescue", hoursAgo: 1170)
    ]

    static func withSeedDefaults(_ folders: [SaviFolder]) -> [SaviFolder] {
        var byId = Dictionary(uniqueKeysWithValues: folders.map { ($0.id, $0) })
        for seed in Self.folders where byId[seed.id] == nil {
            byId[seed.id] = seed
        }
        return byId.values.sorted { lhs, rhs in
            if lhs.order == rhs.order { return lhs.name < rhs.name }
            return lhs.order < rhs.order
        }
    }

    static func refreshingDefaultFolderColors(_ folders: [SaviFolder]) -> [SaviFolder] {
        folders.map { folder in
            guard let seed = Self.folders.first(where: { $0.id == folder.id }),
                  let oldColor = legacyFolderColors[folder.id],
                  folder.color.caseInsensitiveCompare(oldColor) == .orderedSame
            else { return folder }

            var next = folder
            next.color = seed.color
            return next
        }
    }

    static func refreshingDefaultFolderPresentation(_ folders: [SaviFolder]) -> [SaviFolder] {
        let previousNames: [String: Set<String>] = [
            "f-paste-bin": ["Paste Bin", "Notes & Clips"],
            "f-wtf-favorites": ["Science Stuff", "Science Finds"],
            "f-growth": ["AI Hacks", "AI & Work"],
            "f-lmao": ["LULZ", "Memes & Laughs"],
            "f-travel": ["Places", "Places & Trips"],
            "f-health": ["Health Hacks", "Health"],
            "f-research": ["Research", "Research & PDFs"],
            "f-tinfoil": ["Tinfoil Hat Club", "Rabbit Holes"],
            "f-random": ["Random AF", "Everything Else"]
        ]
        let previousOrders: [String: Int] = [
            "f-must-see": 0,
            "f-paste-bin": 1,
            "f-wtf-favorites": 2,
            "f-growth": 3,
            "f-lmao": 4,
            "f-private-vault": 5,
            "f-travel": 6,
            "f-recipes": 7,
            "f-health": 8,
            "f-design": 9,
            "f-research": 10,
            "f-tinfoil": 11,
            "f-random": 12,
            "f-all": 13
        ]

        return folders.map { folder in
            guard let seed = Self.folders.first(where: { $0.id == folder.id }) else { return folder }
            var next = folder
            let knownNames = previousNames[folder.id, default: [seed.name]]
            if knownNames.contains(folder.name) {
                next.name = seed.name
            }
            if let previousOrder = previousOrders[folder.id], folder.order == previousOrder {
                next.order = seed.order
            }
            if folder.symbolName == seed.symbolName {
                next.symbolName = seed.symbolName
            }
            if folder.color.caseInsensitiveCompare(seed.color) == .orderedSame ||
                legacyFolderColors[folder.id].map({ folder.color.caseInsensitiveCompare($0) == .orderedSame }) == true {
                next.color = seed.color
            }
            return next
        }
        .sorted { lhs, rhs in
            if lhs.order == rhs.order { return lhs.name < rhs.name }
            return lhs.order < rhs.order
        }
    }

    static func defaultOrder(for id: String) -> Int {
        folders.first(where: { $0.id == id })?.order ?? 99
    }
}

// MARK: - Utilities

enum SaviImageCache {
    private static let dataURLImages: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 80
        cache.totalCostLimit = 32 * 1024 * 1024
        return cache
    }()

    static func image(fromDataURL value: String) -> UIImage? {
        let key = value as NSString
        if let image = dataURLImages.object(forKey: key) {
            return image
        }
        guard let image = SaviText.imageFromDataURL(value) else {
            return nil
        }
        let cost = Int(image.size.width * image.size.height * max(image.scale, 1) * max(image.scale, 1) * 4)
        dataURLImages.setObject(image, forKey: key, cost: max(cost, 1))
        return image
    }
}

@MainActor
final class SaviRemoteImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    private var task: Task<Void, Never>?
    private var currentURL: URL?

    deinit {
        task?.cancel()
    }

    func load(_ url: URL) {
        guard currentURL != url || image == nil else { return }
        currentURL = url
        task?.cancel()

        if let cached = SaviRemoteImageCache.memoryImage(for: url) {
            image = cached
            return
        }

        image = nil
        task = Task {
            let loaded = await SaviRemoteImageCache.image(for: url)
            guard !Task.isCancelled, currentURL == url else { return }
            image = loaded
        }
    }
}

struct SaviCachedRemoteImage<Placeholder: View>: View {
    let url: URL
    @ViewBuilder let placeholder: () -> Placeholder
    @StateObject private var loader = SaviRemoteImageLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .onAppear {
            loader.load(url)
        }
        .onChange(of: url) { value in
            loader.load(value)
        }
    }
}

enum SaviRemoteImageCache {
    private static let memory: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 220
        cache.totalCostLimit = 64 * 1024 * 1024
        return cache
    }()

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache(
            memoryCapacity: 24 * 1024 * 1024,
            diskCapacity: 96 * 1024 * 1024,
            diskPath: "savi-remote-thumbnails-urlcache"
        )
        configuration.timeoutIntervalForRequest = 14
        configuration.timeoutIntervalForResource = 20
        return URLSession(configuration: configuration)
    }()

    static func memoryImage(for url: URL) -> UIImage? {
        memory.object(forKey: url as NSURL)
    }

    static func image(for url: URL) async -> UIImage? {
        if let cached = memoryImage(for: url) {
            return cached
        }
        if let diskImage = await diskImage(for: url) {
            store(diskImage, for: url)
            return diskImage
        }

        do {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 14)
            let (data, response) = try await session.data(for: request)
            if let status = (response as? HTTPURLResponse)?.statusCode,
               !(200..<300).contains(status) {
                return nil
            }
            guard data.count <= 12 * 1024 * 1024,
                  let image = UIImage(data: data)
            else { return nil }
            store(image, for: url)
            await write(data, for: url)
            return image
        } catch {
            return nil
        }
    }

    private static func store(_ image: UIImage, for url: URL) {
        let scale = max(image.scale, 1)
        let cost = Int(image.size.width * image.size.height * scale * scale * 4)
        memory.setObject(image, forKey: url as NSURL, cost: max(cost, 1))
    }

    private static func diskImage(for url: URL) async -> UIImage? {
        await Task.detached(priority: .utility) {
            guard let data = try? Data(contentsOf: cacheFileURL(for: url)),
                  data.count <= 12 * 1024 * 1024
            else { return nil }
            return UIImage(data: data)
        }.value
    }

    private static func write(_ data: Data, for url: URL) async {
        await Task.detached(priority: .utility) {
            do {
                let directory = try cacheDirectoryURL()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try data.write(to: cacheFileURL(for: url), options: [.atomic])
            } catch {
                // Cache writes are opportunistic; a miss should never affect the UI.
            }
        }.value
    }

    private static func cacheDirectoryURL() throws -> URL {
        try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("savi-remote-thumbnails", isDirectory: true)
    }

    private static func cacheFileURL(for url: URL) -> URL {
        let directory = (try? cacheDirectoryURL()) ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return directory.appendingPathComponent(cacheKey(for: url)).appendingPathExtension("img")
    }

    private static func cacheKey(for url: URL) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in url.absoluteString.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}

enum SaviText {
    static func dedupeTags(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values
            .flatMap { $0.split(separator: ",").map(String.init) }
            .compactMap(cleanSearchTag)
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    static func cleanSearchTag(_ value: String) -> String? {
        let cleaned = value
            .lowercased()
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "[^a-z0-9\\s_-]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-_ ").union(.whitespacesAndNewlines))
        guard cleaned.count >= 2, cleaned.count <= 32 else { return nil }
        return cleaned
    }

    static func normalizedURL(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        if trimmed.contains("://") { return trimmed }
        return "https://\(trimmed)"
    }

    static func inferredType(for value: String) -> SaviItemType {
        let normalized = normalizedURL(value).lowercased()
        if isMapsString(normalized) { return .place }
        if normalized.range(of: #"\.(png|jpe?g|gif|webp|svg)(\?|$)"#, options: .regularExpression) != nil { return .image }
        if normalized.range(of: #"\.(pdf|docx?|pptx?|xlsx?)(\?|$)"#, options: .regularExpression) != nil { return .file }
        if normalized.range(of: #"\.(mp4|mov|m4v|webm)(\?|$)"#, options: .regularExpression) != nil { return .video }
        if normalized.contains("youtube.com") ||
            normalized.contains("youtu.be") ||
            normalized.contains("vimeo.com") ||
            normalized.contains("tiktok.com") ||
            normalized.contains("instagram.com/reel/") {
            return .video
        }
        if normalized.contains("pinterest.") { return .image }
        if normalized.contains("facebook.com/watch") || normalized.contains("fb.watch") { return .video }
        if normalized.contains("spotify.com") || normalized.contains("spotify.link") || normalized.contains("soundcloud.com") {
            return .link
        }
        return .article
    }

    static func itemType(forSharedType rawType: String, url: String?, fileName: String?, mimeType: String?) -> SaviItemType {
        let type = rawType.lowercased()
        if let parsed = SaviItemType(rawValue: type) { return parsed }
        if ["pdf", "document", "data", "public.data", "com.adobe.pdf"].contains(type) {
            return typeForAsset(name: fileName ?? "", mimeType: mimeType ?? "")
        }
        if type.contains("image") { return .image }
        if type.contains("video") { return .video }
        if type.contains("text") { return .text }
        if let fileName, fileName.nilIfBlank != nil {
            return typeForAsset(name: fileName, mimeType: mimeType ?? "")
        }
        return inferredType(for: url ?? "")
    }

    static func inferredTags(type: SaviItemType, url: String?, title: String, description: String) -> [String] {
        let haystack = [url ?? "", title, description].joined(separator: " ").lowercased()
        var tags = [type.rawValue]
        if type == .file { tags.append("document") }
        if type == .place { tags += ["place", "location"] }
        if type == .text { tags.append("note") }
        if haystack.contains("pdf") || haystack.range(of: #"\.pdf(\?|$|\s)"#, options: .regularExpression) != nil { tags += ["pdf", "document"] }
        if haystack.contains("screenshot") || haystack.contains("screen shot") { tags += ["screenshot", "image"] }
        if haystack.contains("youtube") || haystack.contains("youtu.be") { tags += ["youtube", "video"] }
        if haystack.contains("instagram") {
            tags.append("instagram")
            if haystack.contains("/reel/") { tags += ["reel", "video"] }
        }
        if haystack.contains("tiktok") { tags += ["tiktok", "video"] }
        if haystack.contains("twitter.com") || haystack.contains("x.com/") { tags += ["x", "twitter", "post"] }
        if haystack.contains("reddit") { tags.append("reddit") }
        if haystack.contains("vimeo") { tags += ["vimeo", "video"] }
        if haystack.contains("spotify") { tags += ["spotify", "music"] }
        if haystack.contains("soundcloud") { tags += ["soundcloud", "music"] }
        if haystack.contains("pinterest") { tags += ["pinterest", "image"] }
        if haystack.contains("facebook") || haystack.contains("fb.watch") { tags += ["facebook", "post"] }
        if haystack.contains("threads.net") || haystack.contains("threads.com") { tags += ["threads", "post"] }
        if haystack.contains("bsky.app") || haystack.contains("bluesky") { tags += ["bluesky", "post"] }
        if haystack.contains("linkedin") { tags += ["linkedin", "post"] }
        if haystack.contains("maps") { tags += ["place", "map"] }
        if haystack.contains("ai") || haystack.contains("llm") || haystack.contains("chatgpt") || haystack.contains("claude") { tags.append("ai") }
        if haystack.contains("prompt") { tags.append("prompt") }
        if haystack.contains("recipe") || haystack.contains("ingredients") { tags.append("recipe") }
        if haystack.contains("figma") || haystack.contains("typography") || haystack.contains("design") { tags.append("design") }
        if haystack.contains("research") || haystack.contains("arxiv") || haystack.contains("study") { tags.append("research") }
        if haystack.contains("todo") || haystack.contains("checklist") { tags.append("checklist") }
        return dedupeTags(tags)
    }

    static func sourceKey(for value: String, fallback: String) -> String {
        let label = sourceLabel(for: value, fallback: fallback)
        return label.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    static func sourceLabel(for value: String, fallback: String) -> String {
        let haystack = "\(value) \(fallback)".lowercased()
        if haystack.contains("device") { return "Device" }
        if haystack.contains("paste") { return "Paste" }
        if isMapsString(haystack) { return "Maps" }
        if haystack.contains("youtube") || haystack.contains("youtu.be") { return "YouTube" }
        if haystack.contains("instagram") { return "Instagram" }
        if haystack.contains("tiktok") { return "TikTok" }
        if haystack.contains("twitter.com") || haystack.contains("x.com") { return "X" }
        if haystack.contains("reddit") { return "Reddit" }
        if haystack.contains("vimeo") { return "Vimeo" }
        if haystack.contains("spotify") { return "Spotify" }
        if haystack.contains("soundcloud") { return "SoundCloud" }
        if haystack.contains("pinterest") { return "Pinterest" }
        if haystack.contains("facebook") || haystack.contains("fb.watch") { return "Facebook" }
        if haystack.contains("threads.net") || haystack.contains("threads.com") { return "Threads" }
        if haystack.contains("bsky.app") || haystack.contains("bluesky") { return "Bluesky" }
        if haystack.contains("linkedin") { return "LinkedIn" }
        if let url = URL(string: normalizedURL(value)), let host = url.host?.replacingOccurrences(of: "www.", with: "") {
            return host.split(separator: ".").first.map { String($0).capitalized } ?? fallback.nilIfBlank ?? "Web"
        }
        return fallback.nilIfBlank ?? "Web"
    }

    static func titleFromPlainText(_ text: String) -> String {
        if looksSensitive(text) { return "Pasted text" }
        let first = text.split(separator: "\n").map(String.init).first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? "Pasted text"
        let trimmed = first.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 90 { return "Pasted text" }
        return trimmed
    }

    static func tagsFromPlainText(_ text: String) -> [String] {
        var tags = ["text"]
        let lower = text.lowercased()
        if looksSensitive(lower) { tags.append("sensitive") }
        if lower.contains("http") || lower.contains("www.") { tags.append("link") }
        if lower.contains("todo") || lower.contains("remember") || lower.contains("later") { tags += ["note", "checklist"] }
        if lower.contains("prompt") || lower.contains("chatgpt") || lower.contains("claude") { tags += ["prompt", "ai"] }
        if lower.range(of: #"\b(function|class|struct|import|const|let|var|select \*|curl|json|yaml)\b"#, options: .regularExpression) != nil {
            tags.append("code")
        }
        tags += lower
            .replacingOccurrences(of: #"https?:\/\/\S+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[^a-z0-9\s_-]"#, with: " ", options: .regularExpression)
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count >= 4 }
            .prefix(5)
        return dedupeTags(tags)
    }

    static func looksSensitive(_ text: String) -> Bool {
        SAVIFolderClassifier.looksSensitive(text) || SAVIFolderClassifier.looksPrivateDocument(text)
    }

    static func looksPrivateDocument(_ text: String) -> Bool {
        SAVIFolderClassifier.looksPrivateDocument(text)
    }

    static func fallbackTitle(for value: String) -> String {
        guard let url = URL(string: normalizedURL(value)),
              let host = url.host?.replacingOccurrences(of: "www.", with: "")
        else { return "Saved link" }
        if isYouTube(url) { return "YouTube video" }
        if isTikTok(url) { return "TikTok video" }
        if isInstagramReel(url) { return "Instagram Reel" }
        if isInstagram(url) { return "Instagram Post" }
        if isTwitterX(url) { return "X post" }
        if isReddit(url) { return "Reddit post" }
        if isVimeo(url) { return "Vimeo video" }
        if isSpotify(url) { return "Spotify save" }
        if isSoundCloud(url) { return "SoundCloud save" }
        if isPinterest(url) { return "Pinterest pin" }
        if isFacebook(url) { return "Facebook post" }
        if isThreads(url) { return "Threads post" }
        if isBluesky(url) { return "Bluesky post" }
        if isLinkedIn(url) { return "LinkedIn save" }
        return host
    }

    static func shouldReplaceTitle(current: String, fetched: String?) -> Bool {
        guard let fetched = fetched?.nilIfBlank else { return false }
        guard !isGenericFetchedTitle(fetched) else { return false }
        let normalized = current.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ||
            isGenericFetchedTitle(normalized) ||
            normalized == "saved link" ||
            normalized == "shared item" ||
            normalized == "youtube video" ||
            normalized == "tiktok video" ||
            normalized == "instagram reel" ||
            normalized == "instagram post" ||
            normalized == "x post" ||
            normalized == "twitter post" ||
            normalized == "reddit post" ||
            normalized == "vimeo video" ||
            normalized == "spotify save" ||
            normalized == "soundcloud save" ||
            normalized == "pinterest pin" ||
            normalized == "facebook post" ||
            normalized == "threads post" ||
            normalized == "bluesky post" ||
            normalized == "linkedin save" ||
            normalized == "reddit - please wait for verification" ||
            normalized.hasPrefix("http") ||
            fetched.count > current.count + 8
    }

    static func typeForAsset(name: String, mimeType: String) -> SaviItemType {
        let lower = "\(name) \(mimeType)".lowercased()
        if lower.contains("image/") || lower.range(of: #"\.(png|jpe?g|gif|webp|heic)"#, options: .regularExpression) != nil { return .image }
        if lower.contains("video/") { return .video }
        return .file
    }

    static func titleFromFilename(_ name: String) -> String {
        let base = URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
        let cleaned = base.replacingOccurrences(of: #"[_-]+"#, with: " ", options: .regularExpression)
        return cleaned.split(separator: " ").map { $0.capitalized }.joined(separator: " ").nilIfBlank ?? "Untitled file"
    }

    static func fileKind(name: String, mimeType: String) -> String {
        if mimeType == "application/pdf" || name.lowercased().hasSuffix(".pdf") { return "PDF document" }
        if mimeType.hasPrefix("image/") { return "\(mimeType.replacingOccurrences(of: "image/", with: "").uppercased()) image" }
        if mimeType.hasPrefix("video/") { return "\(mimeType.replacingOccurrences(of: "video/", with: "").uppercased()) video" }
        return URL(fileURLWithPath: name).pathExtension.uppercased().nilIfBlank ?? "File"
    }

    static func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 KB" }
        let units = ["B", "KB", "MB", "GB"]
        var value = Double(bytes)
        var index = 0
        while value >= 1024, index < units.count - 1 {
            value /= 1024
            index += 1
        }
        return "\(value >= 10 || index == 0 ? String(format: "%.0f", value) : String(format: "%.1f", value)) \(units[index])"
    }

    static func relativeSavedTime(_ timestamp: Double, now: Date = Date()) -> String {
        guard timestamp.isFinite else { return "Just now" }

        let seconds = timestamp > 10_000_000_000 ? timestamp / 1000 : timestamp
        let date = Date(timeIntervalSince1970: seconds)
        let interval = max(0, now.timeIntervalSince(date))
        let minute: TimeInterval = 60
        let hour: TimeInterval = 60 * minute
        let day: TimeInterval = 24 * hour
        let week: TimeInterval = 7 * day

        if interval < 45 { return "Just now" }
        if interval < 90 { return "1 min ago" }
        if interval < hour { return "\(Int(interval / minute)) min ago" }
        if interval < 1.5 * hour { return "1 hr ago" }
        if interval < day { return "\(Int(interval / hour)) hr ago" }
        if interval < 2 * day { return "Yesterday" }
        if interval < week { return "\(Int(interval / day)) days ago" }
        if interval < 6 * week {
            let weeks = max(1, Int(interval / week))
            return "\(weeks) wk\(weeks == 1 ? "" : "s") ago"
        }

        let formatter = DateFormatter()
        let calendar = Calendar.current
        formatter.dateFormat = calendar.component(.year, from: date) == calendar.component(.year, from: now) ? "MMM d" : "MMM d, yyyy"
        return formatter.string(from: date)
    }

    static func compactRelativeSavedTime(_ timestamp: Double, now: Date = Date()) -> String {
        guard timestamp.isFinite else { return "now" }

        let seconds = timestamp > 10_000_000_000 ? timestamp / 1000 : timestamp
        let date = Date(timeIntervalSince1970: seconds)
        let interval = max(0, now.timeIntervalSince(date))
        let minute: TimeInterval = 60
        let hour: TimeInterval = 60 * minute
        let day: TimeInterval = 24 * hour
        let week: TimeInterval = 7 * day

        if interval < 45 { return "now" }
        if interval < 90 { return "1m" }
        if interval < hour { return "\(Int(interval / minute))m" }
        if interval < 1.5 * hour { return "1h" }
        if interval < day { return "\(Int(interval / hour))h" }
        if interval < 2 * day { return "Yesterday" }
        if interval < week { return "\(Int(interval / day))d" }
        if interval < 6 * week {
            let weeks = max(1, Int(interval / week))
            return "\(weeks)w"
        }

        let formatter = DateFormatter()
        let calendar = Calendar.current
        formatter.dateFormat = calendar.component(.year, from: date) == calendar.component(.year, from: now) ? "MMM d" : "MMM d, yyyy"
        return formatter.string(from: date)
    }

    static func mimeType(forExtension pathExtension: String) -> String {
        UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }

    static func fileExtension(forMimeType mimeType: String) -> String {
        UTType(mimeType: mimeType)?.preferredFilenameExtension ?? "bin"
    }

    static func decodeDataURL(_ value: String) throws -> (mimeType: String, data: Data) {
        guard let comma = value.firstIndex(of: ",") else { throw URLError(.badURL) }
        let header = String(value[..<comma])
        let payload = String(value[value.index(after: comma)...])
        let mime = header
            .replacingOccurrences(of: "data:", with: "")
            .replacingOccurrences(of: ";base64", with: "")
            .nilIfBlank ?? "application/octet-stream"
        guard let data = Data(base64Encoded: payload) else { throw URLError(.cannotDecodeRawData) }
        return (mime, data)
    }

    static func imageFromDataURL(_ value: String) -> UIImage? {
        guard value.lowercased().hasPrefix("data:image/"),
              !isSVGDataURL(value),
              let comma = value.firstIndex(of: ",")
        else { return nil }

        let header = String(value[..<comma]).lowercased()
        let payload = String(value[value.index(after: comma)...])
        let data: Data?
        if header.contains(";base64") {
            data = Data(base64Encoded: payload)
        } else {
            data = payload.removingPercentEncoding?.data(using: .utf8)
        }
        return data.flatMap(UIImage.init(data:))
    }

    static func isSVGDataURL(_ value: String) -> Bool {
        value.lowercased().hasPrefix("data:image/svg+xml")
    }

    static func isMapsString(_ value: String) -> Bool {
        value.contains("google.com/maps") || value.contains("maps.google.com") || value.contains("maps.apple.com") || value.contains("maps.app.goo.gl") || value.contains("goo.gl/maps")
    }

    static func isYouTube(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("youtube.com") || host.contains("youtu.be") || host.contains("youtube-nocookie.com")
    }

    static func isTikTok(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("tiktok.com") || host.contains("vm.tiktok.com")
    }

    static func isInstagram(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("instagram.com")
    }

    static func isInstagramReel(_ url: URL) -> Bool {
        isInstagram(url) && url.path.lowercased().contains("/reel/")
    }

    static func isTwitterX(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host == "x.com" || host.hasSuffix(".x.com") || host.contains("twitter.com")
    }

    static func isReddit(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("reddit.com") || host.contains("redd.it")
    }

    static func isVimeo(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("vimeo.com")
    }

    static func isSpotify(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("spotify.com") || host.contains("spotify.link")
    }

    static func isSoundCloud(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("soundcloud.com")
    }

    static func isPinterest(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("pinterest.") || host.contains("pin.it")
    }

    static func isFacebook(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("facebook.com") || host == "fb.watch" || host.hasSuffix(".fb.watch")
    }

    static func isThreads(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("threads.net") || host.contains("threads.com")
    }

    static func isBluesky(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("bsky.app") || host.contains("bsky.social")
    }

    static func isLinkedIn(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("linkedin.com")
    }

    static func canonicalYouTubeURL(from url: URL) -> URL {
        guard let id = youtubeVideoID(from: url) else { return url }
        return URL(string: "https://www.youtube.com/watch?v=\(id)") ?? url
    }

    static func youtubeVideoID(from url: URL) -> String? {
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

    static func youtubeThumbnailURL(for url: URL) -> String? {
        guard let id = youtubeVideoID(from: url) else { return nil }
        return "https://i.ytimg.com/vi/\(id)/hqdefault.jpg"
    }

    static func providerDisplayName(_ value: String?, fallback: String) -> String {
        let trimmed = value?.saviDecodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ?? fallback
        let normalized = trimmed.lowercased()
        if normalized == "twitter" || normalized == "x.com" || normalized == "twitter.com" { return "X" }
        if normalized == "reddit" { return "Reddit" }
        if normalized == "spotify" { return "Spotify" }
        if normalized == "vimeo" { return "Vimeo" }
        if normalized == "pinterest" { return "Pinterest" }
        if normalized == "soundcloud" { return "SoundCloud" }
        if normalized == "facebook" { return "Facebook" }
        if normalized == "threads" { return "Threads" }
        if normalized == "linkedin" || normalized == "linkedin.com" { return "LinkedIn" }
        if normalized == "bsky" || normalized.contains("bluesky") { return "Bluesky" }
        return trimmed
    }

    static func cleanedMetadataDescription(_ value: String?) -> String? {
        guard let value = value?.nilIfBlank else { return nil }
        let cleaned = value
            .replacingOccurrences(of: #"(?is)<script[^>]*>.*?</script>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"(?is)<style[^>]*>.*?</style>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"(?is)<[^>]+>"#, with: " ", options: .regularExpression)
            .saviDecodedHTMLString
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.nilIfBlank
    }

    static func oEmbedPrimaryText(from html: String?) -> String? {
        guard let html = html?.nilIfBlank else { return nil }
        let paragraph = firstHTMLCapture(in: html, pattern: #"(?is)<p[^>]*>(.*?)</p>"#) ?? html
        let withoutScripts = paragraph
            .replacingOccurrences(of: #"(?is)<script[^>]*>.*?</script>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"(?is)<style[^>]*>.*?</style>"#, with: " ", options: .regularExpression)
        let stripped = withoutScripts
            .replacingOccurrences(of: #"(?is)<[^>]+>"#, with: " ", options: .regularExpression)
            .saviDecodedHTMLString
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isGenericMetadataDescription(stripped) else { return nil }
        return stripped.nilIfBlank
    }

    static func firstHTMLCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: text)
        else { return nil }
        return String(text[valueRange])
    }

    static func cleanedTitle(_ value: String?, for url: URL) -> String? {
        guard var title = value?.saviDecodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            return nil
        }
        if isYouTube(url) {
            title = title.replacingOccurrences(of: #"(?i)\s*-\s*youtube$"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"(?i)^watch\s*-\s*"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return isGenericFetchedTitle(title) ? nil : title
    }

    static func instagramCaption(from value: String?, for url: URL) -> String? {
        guard isInstagram(url),
              let value = value?.saviDecodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines),
              let range = value.range(of: #"(?i)\bon instagram:\s*["“](.+?)["”]\s*$"#, options: .regularExpression)
        else { return nil }
        let matched = String(value[range])
        guard let quoteRange = matched.range(of: #"["“](.+?)["”]"#, options: .regularExpression) else { return nil }
        let quoted = String(matched[quoteRange])
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return quoted.nilIfBlank
    }

    static func isGenericFetchedTitle(_ value: String) -> Bool {
        let normalized = value
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return [
            "youtube",
            "watch",
            "before you continue to youtube",
            "before you continue to google",
            "sign in - google accounts",
            "sign in to youtube",
            "verify it’s you",
            "verify it's you",
            "just a moment",
            "just a moment...",
            "access denied",
            "403 forbidden",
            "page not found",
            "not found",
            "redirecting...",
            "instagram",
            "login • instagram",
            "tiktok",
            "tiktok - make your day",
            "x",
            "twitter",
            "facebook",
            "threads",
            "linkedin",
            "reddit - please wait for verification",
            "x post",
            "twitter post",
            "facebook post",
            "threads post",
            "bluesky post"
        ].contains(normalized) ||
        normalized.contains("before you continue to") ||
        normalized.contains("checking if the site connection is secure") ||
        normalized.contains("please wait for verification") ||
        normalized.contains("are you a robot") ||
        normalized.contains("enable cookies") ||
        normalized.contains("cookies are disabled")
    }

    static func isGenericMetadataDescription(_ value: String) -> Bool {
        let normalized = value
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return true }
        return normalized.contains("sign in to confirm") ||
            normalized.contains("sign in to continue") ||
            normalized.contains("before you continue") ||
            (normalized.contains("cookies") && normalized.contains("continue")) ||
            normalized.contains("checking if the site connection is secure") ||
            normalized.contains("please wait for verification") ||
            normalized.contains("are you a robot") ||
            normalized == "javascript is not available."
    }

    static func firstHTMLMetaContent(in html: String, keys: [String]) -> String? {
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
                let value = String(html[valueRange]).saviDecodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty { return value }
            }
        }
        return nil
    }

    static func htmlTitle(in html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"<title[^>]*>(.*?)</title>"#, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              match.numberOfRanges > 1,
              let valueRange = Range(match.range(at: 1), in: html)
        else { return nil }
        let value = String(html[valueRange]).saviDecodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    static func hostDisplayName(for url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        let cleaned = host.replacingOccurrences(of: "www.", with: "")
        return cleaned.split(separator: ".").first.map { String($0).capitalized }
    }

    static func backupStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return formatter.string(from: Date())
    }

    static func folderSymbolName(id: String, name: String, system: Bool) -> String {
        let key = "\(id) \(name)".lowercased()
        if key.contains("vault") || key.contains("private") || key.contains("passport") || key.contains("insurance") { return "lock.fill" }
        if key.contains("growth") || key.contains("career") || key.contains("business") || key.contains("productivity") || key.contains("ai hack") || key.contains("ai & work") { return "bolt.fill" }
        if key.contains("wtf") || key.contains("wild") || key.contains("favorite") || key.contains("science") { return "atom" }
        if key.contains("tinfoil") || key.contains("conspiracy") || key.contains("alien") || key.contains("rabbit hole") { return "eye.fill" }
        if key.contains("lulz") || key.contains("meme") || key.contains("laugh") || key.contains("funny") || key.contains("lol") { return "theatermasks.fill" }
        if key.contains("health") || key.contains("fitness") || key.contains("wellness") { return "heart.fill" }
        if key.contains("recipe") || key.contains("food") || key.contains("cook") { return "fork.knife" }
        if key.contains("travel") || key.contains("place") || key.contains("map") || key.contains("trip") { return "mappin.and.ellipse" }
        if key.contains("design") || key.contains("inspo") || key.contains("brand") || key.contains("ui") || key.contains("ux") { return "paintpalette.fill" }
        if key.contains("research") || key.contains("study") || key.contains("paper") { return "magnifyingglass" }
        if key.contains("must") || key.contains("later") || key.contains("watch") || key.contains("read") { return "bookmark.fill" }
        if key.contains("paste") || key.contains("clip") { return "clipboard.fill" }
        if key.contains("random") || key.contains("misc") || key.contains("everything else") { return "shuffle" }
        return system ? "folder.fill" : "folder"
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var saviDecodedHTMLString: String {
        guard let data = data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        return (try? NSAttributedString(data: data, options: options, documentAttributes: nil).string) ?? self
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let red: UInt64
        let green: UInt64
        let blue: UInt64
        switch cleaned.count {
        case 3:
            red = (int >> 8) * 17
            green = (int >> 4 & 0xF) * 17
            blue = (int & 0xF) * 17
        case 6:
            red = int >> 16
            green = int >> 8 & 0xFF
            blue = int & 0xFF
        default:
            red = 216
            green = 255
            blue = 60
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: 1
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let red: UInt64
        let green: UInt64
        let blue: UInt64
        switch cleaned.count {
        case 3:
            red = (int >> 8) * 17
            green = (int >> 4 & 0xF) * 17
            blue = (int & 0xF) * 17
        case 6:
            red = int >> 16
            green = int >> 8 & 0xFF
            blue = int & 0xFF
        default:
            red = 216
            green = 255
            blue = 60
        }
        self.init(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }

    var saviUsesLightForeground: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return false
        }

        func linearized(_ component: CGFloat) -> CGFloat {
            component <= 0.03928
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }

        let luminance = 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
        return luminance < 0.42
    }
}
