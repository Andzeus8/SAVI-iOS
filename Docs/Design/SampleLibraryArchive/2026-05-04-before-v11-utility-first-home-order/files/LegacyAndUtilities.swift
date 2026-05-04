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
        .init(id: "f-life-admin", name: "Life Admin", color: "#FFD15C", image: nil, system: false, symbolName: "key.fill", order: 0),
        .init(id: "f-health", name: "Health", color: "#70D59B", image: nil, system: false, symbolName: "heart.fill", order: 1),
        .init(id: "f-must-see", name: "Watch / Read Later", color: "#7A35E8", image: nil, system: false, symbolName: "bookmark.fill", order: 2),
        .init(id: "f-growth", name: "AI & Work", color: "#F47A3B", image: nil, system: false, symbolName: "bolt.fill", order: 3),
        .init(id: "f-travel", name: "Places & Trips", color: "#68C6E8", image: nil, system: false, symbolName: "mappin.and.ellipse", order: 4),
        .init(id: "f-lmao", name: "Memes & Laughs", color: "#D6F83A", image: nil, system: false, symbolName: "theatermasks.fill", order: 5),
        .init(id: "f-recipes", name: "Recipes & Food", color: "#FFB978", image: nil, system: false, symbolName: "fork.knife", order: 6),
        .init(id: "f-paste-bin", name: "Notes & Clips", color: "#9286A8", image: nil, system: false, symbolName: "clipboard.fill", order: 7),
        .init(id: "f-private-vault", name: "Private Vault", color: "#171026", image: nil, system: false, symbolName: "lock.fill", order: 8, locked: true),
        .init(id: "f-research", name: "Research & PDFs", color: "#5ADDCB", image: nil, system: false, symbolName: "magnifyingglass", order: 9),
        .init(id: "f-design", name: "Design Inspo", color: "#DE5B98", image: nil, system: false, symbolName: "paintpalette.fill", order: 10),
        .init(id: "f-wtf-favorites", name: "Science Finds", color: "#73CDED", image: nil, system: false, symbolName: "atom", order: 11),
        .init(id: "f-tinfoil", name: "Rabbit Holes", color: "#7B3FE4", image: nil, system: false, symbolName: "eye.fill", order: 12),
        .init(id: "f-random", name: "Everything Else", color: "#FFE16A", image: nil, system: false, symbolName: "shuffle", order: 13),
        .init(id: "f-all", name: "All Saves", color: "#D6F83A", image: nil, system: true, symbolName: "sparkles", order: 14)
    ]

    static let legacyFolderColors: [String: String] = [
        "f-life-admin": "#FFD15C",
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
        thumbnail: String? = nil,
        thumbnailSeed: String? = nil,
        hoursAgo: Double,
        assetName: String? = nil,
        assetMime: String? = nil,
        assetSize: Int64? = nil,
        metadataPolicy: SaviMetadataPolicy? = nil
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
            thumbnail: thumbnail ?? thumbnailSeed.map { picsumThumb($0, width: 720, height: 720) },
            savedAt: Self.hoursAgo(hoursAgo),
            color: sampleColors[folderId],
            assetName: assetName,
            assetMime: assetMime,
            assetSize: assetSize,
            demo: true,
            metadataPolicy: metadataPolicy
        )
    }

    private static func sampleDocumentThumb(
        title: String,
        subtitle: String,
        accentHex: String = "#FFD15C"
    ) -> String {
        let size = CGSize(width: 720, height: 720)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            UIColor(red: 0.985, green: 0.978, blue: 0.996, alpha: 1).setFill()
            context.fill(bounds)

            let accent = UIColor(hex: accentHex)
            accent.withAlphaComponent(0.18).setFill()
            UIBezierPath(roundedRect: CGRect(x: 54, y: 54, width: 612, height: 612), cornerRadius: 42).fill()

            UIColor.white.withAlphaComponent(0.96).setFill()
            UIBezierPath(roundedRect: CGRect(x: 86, y: 82, width: 548, height: 556), cornerRadius: 28).fill()

            accent.setFill()
            UIBezierPath(roundedRect: CGRect(x: 116, y: 120, width: 132, height: 14), cornerRadius: 7).fill()

            UIColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 1).setFill()
            let titleStyle = NSMutableParagraphStyle()
            titleStyle.lineBreakMode = .byWordWrapping
            titleStyle.alignment = .left
            NSString(string: title).draw(
                in: CGRect(x: 116, y: 166, width: 420, height: 110),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 42, weight: .black),
                    .foregroundColor: UIColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 1),
                    .paragraphStyle: titleStyle
                ]
            )

            let subtitleStyle = NSMutableParagraphStyle()
            subtitleStyle.lineBreakMode = .byWordWrapping
            NSString(string: subtitle).draw(
                in: CGRect(x: 116, y: 292, width: 430, height: 86),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                    .foregroundColor: UIColor(red: 0.36, green: 0.30, blue: 0.48, alpha: 1),
                    .paragraphStyle: subtitleStyle
                ]
            )

            for index in 0..<5 {
                let y = 414 + CGFloat(index) * 34
                UIColor(red: 0.78, green: 0.74, blue: 0.84, alpha: 0.75).setFill()
                UIBezierPath(roundedRect: CGRect(x: 116, y: y, width: index == 4 ? 220 : 402, height: 10), cornerRadius: 5).fill()
            }

            let watermark = "SAMPLE"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 78, weight: .black),
                .foregroundColor: UIColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 0.10)
            ]
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 360, y: 518)
            context.cgContext.rotate(by: -.pi / 9)
            let sampleSize = NSString(string: watermark).size(withAttributes: attrs)
            NSString(string: watermark).draw(
                at: CGPoint(x: -sampleSize.width / 2, y: -sampleSize.height / 2),
                withAttributes: attrs
            )
            context.cgContext.restoreGState()
        }

        guard let data = image.pngData() else {
            return picsumThumb("savi-sample-\(title)", width: 720, height: 720)
        }
        return "data:image/png;base64,\(data.base64EncodedString())"
    }

    private static func sampleGraphicThumb(
        title: String,
        subtitle: String,
        accentHex: String,
        symbolName: String,
        rows: [String],
        dark: Bool = false
    ) -> String {
        let size = CGSize(width: 720, height: 720)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            let accent = UIColor(hex: accentHex)
            let ink = dark
                ? UIColor(red: 0.96, green: 0.93, blue: 1.0, alpha: 1)
                : UIColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 1)
            let muted = dark
                ? UIColor(red: 0.78, green: 0.72, blue: 0.88, alpha: 1)
                : UIColor(red: 0.37, green: 0.32, blue: 0.48, alpha: 1)

            (dark
                ? UIColor(red: 0.07, green: 0.04, blue: 0.12, alpha: 1)
                : UIColor(red: 0.985, green: 0.978, blue: 0.996, alpha: 1)
            ).setFill()
            context.fill(bounds)

            accent.withAlphaComponent(dark ? 0.36 : 0.18).setFill()
            UIBezierPath(roundedRect: CGRect(x: 48, y: 48, width: 624, height: 624), cornerRadius: 52).fill()

            (dark
                ? UIColor(red: 0.11, green: 0.07, blue: 0.18, alpha: 0.96)
                : UIColor.white.withAlphaComponent(0.96)
            ).setFill()
            UIBezierPath(roundedRect: CGRect(x: 82, y: 82, width: 556, height: 556), cornerRadius: 34).fill()

            accent.withAlphaComponent(dark ? 0.28 : 0.18).setFill()
            UIBezierPath(roundedRect: CGRect(x: 116, y: 116, width: 112, height: 112), cornerRadius: 26).fill()
            if let icon = UIImage(systemName: symbolName)?.withTintColor(accent, renderingMode: .alwaysOriginal) {
                icon.draw(in: CGRect(x: 146, y: 146, width: 52, height: 52))
            }

            drawText(
                title,
                in: CGRect(x: 116, y: 260, width: 456, height: 92),
                font: .systemFont(ofSize: 38, weight: .black),
                color: ink
            )
            drawText(
                subtitle,
                in: CGRect(x: 116, y: 358, width: 448, height: 56),
                font: .systemFont(ofSize: 22, weight: .semibold),
                color: muted
            )

            for (index, row) in rows.prefix(4).enumerated() {
                let y = 446 + CGFloat(index) * 42
                accent.withAlphaComponent(index == 0 ? 0.22 : 0.11).setFill()
                UIBezierPath(roundedRect: CGRect(x: 116, y: y, width: 452, height: 30), cornerRadius: 15).fill()
                drawText(
                    row,
                    in: CGRect(x: 136, y: y + 4, width: 410, height: 24),
                    font: .monospacedSystemFont(ofSize: 17, weight: .semibold),
                    color: index == 0 ? ink : muted,
                    lineBreakMode: .byTruncatingTail
                )
            }

            drawSampleWatermark(in: context.cgContext, center: CGPoint(x: 466, y: 188), color: ink.withAlphaComponent(dark ? 0.12 : 0.10), size: 54, rotation: -.pi / 12)
        }

        guard let data = image.pngData() else {
            return picsumThumb("savi-sample-\(title)", width: 720, height: 720)
        }
        return "data:image/png;base64,\(data.base64EncodedString())"
    }

    private static func sampleLicenseThumb() -> String {
        let size = CGSize(width: 720, height: 720)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            let accent = UIColor(hex: "#FFD15C")
            let ink = UIColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 1)
            let muted = UIColor(red: 0.37, green: 0.32, blue: 0.48, alpha: 1)

            UIColor(red: 0.985, green: 0.978, blue: 0.996, alpha: 1).setFill()
            context.fill(bounds)
            accent.withAlphaComponent(0.24).setFill()
            UIBezierPath(roundedRect: CGRect(x: 54, y: 112, width: 612, height: 432), cornerRadius: 46).fill()
            UIColor.white.withAlphaComponent(0.97).setFill()
            UIBezierPath(roundedRect: CGRect(x: 82, y: 142, width: 556, height: 374), cornerRadius: 34).fill()

            accent.setFill()
            UIBezierPath(roundedRect: CGRect(x: 116, y: 174, width: 488, height: 34), cornerRadius: 17).fill()
            drawText("SAMPLE DRIVER LICENSE", in: CGRect(x: 136, y: 181, width: 420, height: 24), font: .systemFont(ofSize: 17, weight: .black), color: ink)

            UIColor(hex: "#D9EEF8").setFill()
            UIBezierPath(roundedRect: CGRect(x: 116, y: 246, width: 152, height: 174), cornerRadius: 22).fill()
            UIColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 0.18).setFill()
            UIBezierPath(ovalIn: CGRect(x: 162, y: 278, width: 60, height: 60)).fill()
            UIBezierPath(roundedRect: CGRect(x: 142, y: 354, width: 100, height: 42), cornerRadius: 21).fill()

            drawText("Alex Sample", in: CGRect(x: 300, y: 250, width: 260, height: 42), font: .systemFont(ofSize: 30, weight: .black), color: ink)
            drawText("ID D123-456-789", in: CGRect(x: 300, y: 310, width: 260, height: 28), font: .monospacedSystemFont(ofSize: 20, weight: .bold), color: muted)
            drawText("DOB 05/04/1990", in: CGRect(x: 300, y: 350, width: 260, height: 28), font: .monospacedSystemFont(ofSize: 18, weight: .semibold), color: muted)
            drawText("EXP 05/04/2030", in: CGRect(x: 300, y: 390, width: 260, height: 28), font: .monospacedSystemFont(ofSize: 18, weight: .semibold), color: muted)

            for index in 0..<3 {
                UIColor(red: 0.78, green: 0.74, blue: 0.84, alpha: 0.65).setFill()
                UIBezierPath(roundedRect: CGRect(x: 116, y: 452 + CGFloat(index) * 18, width: 414, height: 8), cornerRadius: 4).fill()
            }
            drawSampleWatermark(in: context.cgContext, center: CGPoint(x: 442, y: 456), color: ink.withAlphaComponent(0.10), size: 62, rotation: -.pi / 10)
        }

        guard let data = image.pngData() else {
            return picsumThumb("savi-sample-license", width: 720, height: 720)
        }
        return "data:image/png;base64,\(data.base64EncodedString())"
    }

    private static func sampleInsuranceThumb() -> String {
        sampleGraphicThumb(
            title: "Insurance card",
            subtitle: "Fake policy details",
            accentHex: "#70D59B",
            symbolName: "cross.case.fill",
            rows: ["Plan DEMO PPO", "Member SAVI-2048", "Group SAMPLE", "Copay $00"]
        )
    }

    private static func sampleAccessThumb() -> String {
        let size = CGSize(width: 720, height: 720)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            let ink = UIColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 1)
            let muted = UIColor(red: 0.38, green: 0.32, blue: 0.48, alpha: 1)
            let coral = UIColor(hex: "#FF5A5F")
            let gold = UIColor(hex: "#FFD15C")

            UIColor(red: 0.985, green: 0.978, blue: 0.996, alpha: 1).setFill()
            context.fill(bounds)

            coral.withAlphaComponent(0.13).setFill()
            UIBezierPath(roundedRect: CGRect(x: 44, y: 44, width: 632, height: 632), cornerRadius: 58).fill()
            UIColor.white.withAlphaComponent(0.97).setFill()
            UIBezierPath(roundedRect: CGRect(x: 76, y: 80, width: 568, height: 560), cornerRadius: 38).fill()

            let photoRect = CGRect(x: 102, y: 108, width: 516, height: 178)
            let photoPath = UIBezierPath(roundedRect: photoRect, cornerRadius: 28)
            context.cgContext.saveGState()
            photoPath.addClip()
            UIColor(hex: "#68C6E8").setFill()
            context.fill(photoRect)
            UIColor(hex: "#2A1745").withAlphaComponent(0.28).setFill()
            UIBezierPath(ovalIn: CGRect(x: 384, y: 70, width: 180, height: 180)).fill()
            UIColor(hex: "#70D59B").setFill()
            UIBezierPath(roundedRect: CGRect(x: 76, y: 226, width: 590, height: 88), cornerRadius: 30).fill()
            UIColor.white.withAlphaComponent(0.72).setFill()
            UIBezierPath(roundedRect: CGRect(x: 102, y: 188, width: 92, height: 74), cornerRadius: 18).fill()
            UIBezierPath(roundedRect: CGRect(x: 214, y: 166, width: 144, height: 104), cornerRadius: 24).fill()
            context.cgContext.restoreGState()

            coral.setFill()
            UIBezierPath(roundedRect: CGRect(x: 116, y: 318, width: 142, height: 30), cornerRadius: 15).fill()
            drawText("STAY SAMPLE", in: CGRect(x: 132, y: 324, width: 120, height: 18), font: .systemFont(ofSize: 14, weight: .black), color: .white, lineBreakMode: .byTruncatingTail)

            drawText("Airbnb door code", in: CGRect(x: 116, y: 366, width: 420, height: 48), font: .systemFont(ofSize: 38, weight: .black), color: ink, lineBreakMode: .byTruncatingTail)
            drawText("Door, Wi-Fi, checkout, lockbox.", in: CGRect(x: 116, y: 418, width: 430, height: 30), font: .systemFont(ofSize: 22, weight: .semibold), color: muted)

            let chips: [(String, String)] = [
                ("DOOR", "2486"),
                ("WI-FI", "Pinehouse Guest"),
                ("OUT", "11 AM")
            ]
            for (index, chip) in chips.enumerated() {
                let y = 482 + CGFloat(index) * 46
                gold.withAlphaComponent(index == 0 ? 0.90 : 0.32).setFill()
                UIBezierPath(roundedRect: CGRect(x: 116, y: y, width: 488, height: 34), cornerRadius: 17).fill()
                drawText(chip.0, in: CGRect(x: 136, y: y + 8, width: 70, height: 18), font: .monospacedSystemFont(ofSize: 14, weight: .black), color: ink)
                drawText(chip.1, in: CGRect(x: 220, y: y + 7, width: 350, height: 20), font: .monospacedSystemFont(ofSize: 17, weight: .bold), color: ink, lineBreakMode: .byTruncatingTail)
            }

            drawSampleWatermark(in: context.cgContext, center: CGPoint(x: 486, y: 336), color: ink.withAlphaComponent(0.08), size: 48, rotation: -.pi / 11)
        }

        guard let data = image.pngData() else {
            return picsumThumb("savi-sample-airbnb-access", width: 720, height: 720)
        }
        return "data:image/png;base64,\(data.base64EncodedString())"
    }

    private static func sampleBookingThumb() -> String {
        let size = CGSize(width: 720, height: 720)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            let ink = UIColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 1)
            let muted = UIColor(red: 0.40, green: 0.34, blue: 0.52, alpha: 1)
            let blue = UIColor(hex: "#68C6E8")
            let purple = UIColor(hex: "#7A35E8")

            UIColor(red: 0.985, green: 0.978, blue: 0.996, alpha: 1).setFill()
            context.fill(bounds)

            blue.withAlphaComponent(0.16).setFill()
            UIBezierPath(roundedRect: CGRect(x: 42, y: 44, width: 636, height: 632), cornerRadius: 56).fill()
            UIColor.white.withAlphaComponent(0.98).setFill()
            UIBezierPath(roundedRect: CGRect(x: 78, y: 78, width: 564, height: 564), cornerRadius: 36).fill()

            purple.setFill()
            UIBezierPath(roundedRect: CGRect(x: 78, y: 78, width: 564, height: 106), cornerRadius: 36).fill()
            UIBezierPath(rect: CGRect(x: 78, y: 132, width: 564, height: 52)).fill()
            drawText("HOTEL NUBE", in: CGRect(x: 116, y: 110, width: 250, height: 34), font: .systemFont(ofSize: 28, weight: .black), color: .white)
            drawText("Booking confirmation", in: CGRect(x: 390, y: 116, width: 190, height: 24), font: .systemFont(ofSize: 16, weight: .bold), color: UIColor.white.withAlphaComponent(0.82), alignment: .right)

            drawText("May 14 - May 17", in: CGRect(x: 116, y: 220, width: 260, height: 36), font: .systemFont(ofSize: 30, weight: .black), color: ink)
            drawText("2 guests  |  Late check-in noted", in: CGRect(x: 116, y: 264, width: 420, height: 28), font: .systemFont(ofSize: 20, weight: .semibold), color: muted)

            let confirmationRect = CGRect(x: 116, y: 328, width: 488, height: 74)
            blue.withAlphaComponent(0.22).setFill()
            UIBezierPath(roundedRect: confirmationRect, cornerRadius: 22).fill()
            drawText("CONFIRMATION", in: CGRect(x: 142, y: 346, width: 160, height: 18), font: .monospacedSystemFont(ofSize: 13, weight: .black), color: muted)
            drawText("SVI-48291", in: CGRect(x: 142, y: 366, width: 210, height: 28), font: .monospacedSystemFont(ofSize: 23, weight: .black), color: ink)

            let qrOrigin = CGPoint(x: 486, y: 334)
            UIColor.white.withAlphaComponent(0.98).setFill()
            UIBezierPath(roundedRect: CGRect(x: qrOrigin.x, y: qrOrigin.y, width: 84, height: 84), cornerRadius: 12).fill()
            ink.setFill()
            for row in 0..<5 {
                for col in 0..<5 where (row + col) % 2 == 0 || row == col {
                    UIBezierPath(roundedRect: CGRect(x: qrOrigin.x + 12 + CGFloat(col) * 12, y: qrOrigin.y + 12 + CGFloat(row) * 12, width: 8, height: 8), cornerRadius: 2).fill()
                }
            }

            let details = [
                ("ROOM", "King demo suite"),
                ("ADDRESS", "18 Sample Ave"),
                ("CHECK-IN", "After 3 PM")
            ]
            for (index, detail) in details.enumerated() {
                let y = 444 + CGFloat(index) * 44
                UIColor(red: 0.78, green: 0.74, blue: 0.84, alpha: 0.18).setFill()
                UIBezierPath(roundedRect: CGRect(x: 116, y: y, width: 488, height: 32), cornerRadius: 16).fill()
                drawText(detail.0, in: CGRect(x: 136, y: y + 8, width: 90, height: 17), font: .monospacedSystemFont(ofSize: 12, weight: .black), color: muted)
                drawText(detail.1, in: CGRect(x: 244, y: y + 6, width: 318, height: 20), font: .systemFont(ofSize: 17, weight: .bold), color: ink, lineBreakMode: .byTruncatingTail)
            }

            drawSampleWatermark(in: context.cgContext, center: CGPoint(x: 470, y: 252), color: ink.withAlphaComponent(0.08), size: 52, rotation: -.pi / 12)
        }

        guard let data = image.pngData() else {
            return picsumThumb("savi-sample-hotel-booking", width: 720, height: 720)
        }
        return "data:image/png;base64,\(data.base64EncodedString())"
    }

    private enum SampleEditorialScene {
        case stay
        case food
        case health
        case aiAgent
        case mythCheck
    }

    private static func sampleEditorialThumb(
        title: String,
        kicker: String,
        subtitle: String,
        accentHex: String,
        symbolName: String,
        scene: SampleEditorialScene
    ) -> String {
        let size = CGSize(width: 720, height: 720)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            let ink = UIColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 1)
            let muted = UIColor(red: 0.36, green: 0.30, blue: 0.48, alpha: 1)
            let accent = UIColor(hex: accentHex)
            let colors: [UIColor]
            switch scene {
            case .stay:
                colors = [UIColor(hex: "#78C7E8"), UIColor(hex: "#FFD15C"), UIColor(hex: "#FF8A5C")]
            case .food:
                colors = [UIColor(hex: "#FFB978"), UIColor(hex: "#F47A3B"), UIColor(hex: "#70D59B")]
            case .health:
                colors = [UIColor(hex: "#70D59B"), UIColor(hex: "#5ADDCB"), UIColor(hex: "#D6F83A")]
            case .aiAgent:
                colors = [UIColor(hex: "#2A1745"), UIColor(hex: "#7A35E8"), UIColor(hex: "#F47A3B")]
            case .mythCheck:
                colors = [UIColor(hex: "#FFD15C"), UIColor(hex: "#FFB978"), UIColor(hex: "#F4EEF9")]
            }

            let cgColors = colors.map(\.cgColor) as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: [0, 0.58, 1]) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: bounds.maxX, y: bounds.maxY),
                    options: []
                )
            } else {
                colors.first?.setFill()
                context.fill(bounds)
            }

            switch scene {
            case .stay:
                UIColor(hex: "#2A1745").withAlphaComponent(0.22).setFill()
                UIBezierPath(roundedRect: CGRect(x: 428, y: 84, width: 178, height: 320), cornerRadius: 34).fill()
                UIColor.white.withAlphaComponent(0.72).setFill()
                UIBezierPath(roundedRect: CGRect(x: 460, y: 142, width: 114, height: 204), cornerRadius: 24).fill()
                accent.setFill()
                UIBezierPath(roundedRect: CGRect(x: 486, y: 226, width: 62, height: 52), cornerRadius: 16).fill()
                for row in 0..<2 {
                    for col in 0..<3 {
                        UIColor.white.withAlphaComponent(0.88).setFill()
                        UIBezierPath(ovalIn: CGRect(x: 498 + CGFloat(col) * 15, y: 238 + CGFloat(row) * 14, width: 7, height: 7)).fill()
                    }
                }
                UIColor.white.withAlphaComponent(0.44).setFill()
                UIBezierPath(roundedRect: CGRect(x: -28, y: 390, width: 802, height: 210), cornerRadius: 82).fill()
                UIColor(hex: "#70D59B").withAlphaComponent(0.62).setFill()
                UIBezierPath(ovalIn: CGRect(x: -70, y: 338, width: 350, height: 210)).fill()
            case .food:
                UIColor.white.withAlphaComponent(0.58).setFill()
                UIBezierPath(ovalIn: CGRect(x: 98, y: 112, width: 410, height: 330)).fill()
                UIColor(hex: "#2A1745").withAlphaComponent(0.14).setStroke()
                for offset in stride(from: 0, through: 190, by: 38) {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: 184 + CGFloat(offset), y: 224))
                    path.addCurve(to: CGPoint(x: 206 + CGFloat(offset), y: 360), controlPoint1: CGPoint(x: 118 + CGFloat(offset), y: 278), controlPoint2: CGPoint(x: 278 + CGFloat(offset), y: 314))
                    path.lineWidth = 14
                    path.stroke()
                }
                accent.setFill()
                UIBezierPath(ovalIn: CGRect(x: 390, y: 252, width: 82, height: 82)).fill()
                UIColor(hex: "#D6F83A").withAlphaComponent(0.82).setFill()
                UIBezierPath(ovalIn: CGRect(x: 218, y: 168, width: 72, height: 48)).fill()
            case .health:
                UIColor.white.withAlphaComponent(0.28).setFill()
                for index in 0..<14 {
                    let x = CGFloat((index * 97) % 610) + 34
                    let y = CGFloat((index * 151) % 430) + 42
                    let size = CGFloat(42 + (index % 4) * 18)
                    UIBezierPath(ovalIn: CGRect(x: x, y: y, width: size, height: size)).fill()
                }
                UIColor(hex: "#2A1745").withAlphaComponent(0.15).setStroke()
                let strand = UIBezierPath()
                strand.move(to: CGPoint(x: 120, y: 188))
                strand.addCurve(to: CGPoint(x: 560, y: 390), controlPoint1: CGPoint(x: 238, y: 86), controlPoint2: CGPoint(x: 424, y: 508))
                strand.lineWidth = 18
                strand.stroke()
                accent.withAlphaComponent(0.72).setFill()
                UIBezierPath(ovalIn: CGRect(x: 494, y: 136, width: 92, height: 92)).fill()
            case .aiAgent:
                UIColor.white.withAlphaComponent(0.14).setFill()
                for index in 0..<8 {
                    let x = CGFloat(94 + (index % 4) * 138)
                    let y = CGFloat(112 + (index / 4) * 132)
                    UIBezierPath(ovalIn: CGRect(x: x, y: y, width: 72, height: 72)).fill()
                    if index < 7 {
                        let path = UIBezierPath()
                        path.move(to: CGPoint(x: x + 36, y: y + 36))
                        path.addLine(to: CGPoint(x: x + 174, y: y + (index % 2 == 0 ? 168 : 36)))
                        UIColor.white.withAlphaComponent(0.22).setStroke()
                        path.lineWidth = 8
                        path.stroke()
                    }
                }
                accent.setFill()
                UIBezierPath(roundedRect: CGRect(x: 260, y: 250, width: 200, height: 124), cornerRadius: 38).fill()
                if let icon = UIImage(systemName: "play.fill")?.withTintColor(ink, renderingMode: .alwaysOriginal) {
                    icon.draw(in: CGRect(x: 342, y: 288, width: 44, height: 50))
                }
            case .mythCheck:
                UIColor.white.withAlphaComponent(0.52).setFill()
                for index in 0..<5 {
                    UIBezierPath(roundedRect: CGRect(x: 112 + CGFloat(index) * 72, y: 148 + CGFloat(index % 2) * 44, width: 88, height: 88), cornerRadius: 18).fill()
                }
                UIColor(hex: "#7A35E8").withAlphaComponent(0.20).setStroke()
                let check = UIBezierPath()
                check.move(to: CGPoint(x: 258, y: 360))
                check.addLine(to: CGPoint(x: 326, y: 422))
                check.addLine(to: CGPoint(x: 482, y: 236))
                check.lineWidth = 34
                check.lineCapStyle = .round
                check.lineJoinStyle = .round
                check.stroke()
            }

            UIColor.white.withAlphaComponent(0.86).setFill()
            UIBezierPath(roundedRect: CGRect(x: 48, y: 472, width: 624, height: 176), cornerRadius: 40).fill()
            accent.setFill()
            UIBezierPath(roundedRect: CGRect(x: 82, y: 504, width: 86, height: 86), cornerRadius: 24).fill()
            if let icon = UIImage(systemName: symbolName)?.withTintColor(ink, renderingMode: .alwaysOriginal) {
                icon.draw(in: CGRect(x: 108, y: 530, width: 34, height: 34))
            }

            drawText(kicker.uppercased(), in: CGRect(x: 190, y: 508, width: 398, height: 22), font: .monospacedSystemFont(ofSize: 13, weight: .black), color: muted, lineBreakMode: .byTruncatingTail)
            drawText(title, in: CGRect(x: 190, y: 536, width: 408, height: 58), font: .systemFont(ofSize: 28, weight: .black), color: ink, lineBreakMode: .byWordWrapping)
            drawText(subtitle, in: CGRect(x: 190, y: 600, width: 398, height: 28), font: .systemFont(ofSize: 17, weight: .semibold), color: muted, lineBreakMode: .byTruncatingTail)
        }

        guard let data = image.pngData() else {
            return picsumThumb("savi-sample-\(title)", width: 720, height: 720)
        }
        return "data:image/png;base64,\(data.base64EncodedString())"
    }

    private static func sampleFullBleedStayThumb() -> String {
        sampleEditorialThumb(
            title: "Door code + Wi-Fi",
            kicker: "Stay access",
            subtitle: "The tiny details you need fast.",
            accentHex: "#FFD15C",
            symbolName: "key.fill",
            scene: .stay
        )
    }

    private static func sampleFoodRecommendationThumb() -> String {
        let size = CGSize(width: 720, height: 720)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            let ink = UIColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 1)
            let muted = UIColor(red: 0.39, green: 0.32, blue: 0.50, alpha: 1)
            let table = UIColor(hex: "#FFB978")
            let broth = UIColor(hex: "#F47A3B")
            let lime = UIColor(hex: "#D6F83A")
            let herb = UIColor(hex: "#70D59B")

            table.setFill()
            context.fill(bounds)

            UIColor.white.withAlphaComponent(0.16).setFill()
            for offset in stride(from: -160, through: 720, by: 120) {
                UIBezierPath(roundedRect: CGRect(x: CGFloat(offset), y: -42, width: 58, height: 840), cornerRadius: 29).fill()
            }

            UIColor(hex: "#2A1745").withAlphaComponent(0.14).setFill()
            UIBezierPath(ovalIn: CGRect(x: 102, y: 112, width: 530, height: 430)).fill()
            UIColor.white.withAlphaComponent(0.94).setFill()
            UIBezierPath(ovalIn: CGRect(x: 92, y: 92, width: 520, height: 420)).fill()
            broth.withAlphaComponent(0.92).setFill()
            UIBezierPath(ovalIn: CGRect(x: 142, y: 134, width: 420, height: 334)).fill()

            UIColor(hex: "#F8D889").withAlphaComponent(0.92).setStroke()
            for offset in stride(from: 0, through: 190, by: 34) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 206 + CGFloat(offset), y: 202))
                path.addCurve(to: CGPoint(x: 196 + CGFloat(offset), y: 402), controlPoint1: CGPoint(x: 124 + CGFloat(offset), y: 268), controlPoint2: CGPoint(x: 314 + CGFloat(offset), y: 328))
                path.lineWidth = 15
                path.lineCapStyle = .round
                path.stroke()
            }

            UIColor.white.withAlphaComponent(0.92).setFill()
            UIBezierPath(ovalIn: CGRect(x: 360, y: 202, width: 116, height: 92)).fill()
            lime.setFill()
            UIBezierPath(ovalIn: CGRect(x: 392, y: 226, width: 48, height: 44)).fill()
            herb.setFill()
            UIBezierPath(ovalIn: CGRect(x: 236, y: 310, width: 62, height: 34)).fill()
            UIBezierPath(ovalIn: CGRect(x: 302, y: 344, width: 54, height: 28)).fill()
            ink.withAlphaComponent(0.42).setStroke()
            let chopsticks = UIBezierPath()
            chopsticks.move(to: CGPoint(x: 516, y: 96))
            chopsticks.addLine(to: CGPoint(x: 376, y: 440))
            chopsticks.move(to: CGPoint(x: 556, y: 106))
            chopsticks.addLine(to: CGPoint(x: 416, y: 450))
            chopsticks.lineWidth = 10
            chopsticks.lineCapStyle = .round
            chopsticks.stroke()

            UIColor.white.withAlphaComponent(0.88).setFill()
            UIBezierPath(roundedRect: CGRect(x: 64, y: 530, width: 592, height: 106), cornerRadius: 36).fill()
            lime.setFill()
            UIBezierPath(ovalIn: CGRect(x: 92, y: 552, width: 62, height: 62)).fill()
            drawText("J", in: CGRect(x: 92, y: 562, width: 62, height: 42), font: .systemFont(ofSize: 32, weight: .black), color: ink, alignment: .center)
            if let pin = UIImage(systemName: "mappin.circle.fill")?.withTintColor(broth, renderingMode: .alwaysOriginal) {
                pin.draw(in: CGRect(x: 570, y: 560, width: 42, height: 42))
            }
            drawText("Jennifer's ramen rec", in: CGRect(x: 176, y: 548, width: 340, height: 36), font: .systemFont(ofSize: 28, weight: .black), color: ink, lineBreakMode: .byTruncatingTail)
            drawText("Spicy miso. Counter seats. Save the pin.", in: CGRect(x: 176, y: 588, width: 344, height: 26), font: .systemFont(ofSize: 18, weight: .semibold), color: muted, lineBreakMode: .byTruncatingTail)
        }

        guard let data = image.pngData() else {
            return picsumThumb("savi-sample-jennifer-ramen", width: 720, height: 720)
        }
        return "data:image/png;base64,\(data.base64EncodedString())"
    }

    private static func sampleHealthResearchThumb() -> String {
        sampleEditorialThumb(
            title: "Fasting research",
            kicker: "Health notes",
            subtitle: "Saved evidence, not advice.",
            accentHex: "#70D59B",
            symbolName: "cross.case.fill",
            scene: .health
        )
    }

    private static func sampleAIAgentVideoThumb() -> String {
        sampleEditorialThumb(
            title: "Use your AI agent better",
            kicker: "AI & Work",
            subtitle: "A practical saved guide.",
            accentHex: "#D6F83A",
            symbolName: "sparkles",
            scene: .aiAgent
        )
    }

    private static func sampleMythCheckThumb() -> String {
        sampleEditorialThumb(
            title: "Sugar and cancer myths",
            kicker: "Evidence check",
            subtitle: "A source to revisit calmly.",
            accentHex: "#FFD15C",
            symbolName: "checkmark.seal.fill",
            scene: .mythCheck
        )
    }

    private static func sampleContractThumb() -> String {
        sampleGraphicThumb(
            title: "Contract template",
            subtitle: "Reusable admin file",
            accentHex: "#F47A3B",
            symbolName: "doc.text.fill",
            rows: ["Scope of work", "Payment terms", "Timeline", "Signature lines"]
        )
    }

    private static func sampleRecoveryThumb() -> String {
        sampleGraphicThumb(
            title: "Recovery code",
            subtitle: "Exact text worth finding",
            accentHex: "#FFD15C",
            symbolName: "key.horizontal.fill",
            rows: ["RK8F-Q44P", "29LM-7DZQ", "J2X9-P0RA", "Saved for emergencies"]
        )
    }

    private static func sampleAIPromptThumb() -> String {
        sampleGraphicThumb(
            title: "Chaos -> plan",
            subtitle: "Prompt template",
            accentHex: "#F47A3B",
            symbolName: "sparkles",
            rows: ["Goal -> Context -> Output", "Ask 3 sharp questions", "Return a clean plan", "Keep assumptions visible"]
        )
    }

    private static func sampleCrossCheckPromptThumb() -> String {
        sampleGraphicThumb(
            title: "Cross-check",
            subtitle: "Find blind spots",
            accentHex: "#F47A3B",
            symbolName: "checkmark.seal.fill",
            rows: ["Argue both sides", "List hidden risks", "Show weak evidence", "Give next test"]
        )
    }

    private static func sampleAudioRecipeThumb() -> String {
        sampleGraphicThumb(
            title: "Mom's sauce note",
            subtitle: "Audio recipe",
            accentHex: "#FFB978",
            symbolName: "waveform",
            rows: ["Brown garlic slowly", "Simmer 45 minutes", "More basil at the end", "Voice memo sample"]
        )
    }

    private static func sampleTalentPromptThumb() -> String {
        sampleGraphicThumb(
            title: "Talent finder",
            subtitle: "Pattern prompt",
            accentHex: "#F47A3B",
            symbolName: "person.crop.circle.fill",
            rows: ["Look at my history", "Spot recurring strengths", "Name 3 directions", "Make a 7-day test"]
        )
    }

    private static func sampleNoteThumb(
        title: String,
        subtitle: String,
        accentHex: String,
        symbolName: String,
        rows: [String]
    ) -> String {
        sampleGraphicThumb(
            title: title,
            subtitle: subtitle,
            accentHex: accentHex,
            symbolName: symbolName,
            rows: rows
        )
    }

    private static func sampleVideoThumb(
        title: String,
        accentHex: String = "#D6F83A",
        symbolName: String = "play.fill"
    ) -> String {
        let size = CGSize(width: 720, height: 720)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let bounds = CGRect(origin: .zero, size: size)
            let ink = UIColor(red: 0.12, green: 0.07, blue: 0.20, alpha: 1)
            let accent = UIColor(hex: accentHex)

            UIColor(red: 0.985, green: 0.978, blue: 0.996, alpha: 1).setFill()
            context.fill(bounds)

            accent.withAlphaComponent(0.30).setFill()
            UIBezierPath(roundedRect: CGRect(x: 44, y: 44, width: 632, height: 632), cornerRadius: 62).fill()

            let frame = CGRect(x: 88, y: 108, width: 544, height: 356)
            UIColor(red: 0.10, green: 0.07, blue: 0.16, alpha: 1).setFill()
            UIBezierPath(roundedRect: frame, cornerRadius: 38).fill()

            UIColor(hex: "#68C6E8").withAlphaComponent(0.95).setFill()
            UIBezierPath(ovalIn: CGRect(x: 112, y: 132, width: 170, height: 170)).fill()
            UIColor(hex: "#FFB978").withAlphaComponent(0.95).setFill()
            UIBezierPath(ovalIn: CGRect(x: 420, y: 178, width: 138, height: 138)).fill()
            UIColor(hex: "#7A35E8").withAlphaComponent(0.88).setFill()
            UIBezierPath(roundedRect: CGRect(x: 178, y: 292, width: 360, height: 118), cornerRadius: 42).fill()

            UIColor.white.withAlphaComponent(0.92).setFill()
            UIBezierPath(ovalIn: CGRect(x: 298, y: 234, width: 124, height: 124)).fill()
            if let icon = UIImage(systemName: symbolName)?.withTintColor(ink, renderingMode: .alwaysOriginal) {
                icon.draw(in: CGRect(x: 342, y: 272, width: 44, height: 48))
            }

            drawText(
                title,
                in: CGRect(x: 116, y: 506, width: 488, height: 74),
                font: .systemFont(ofSize: 34, weight: .black),
                color: ink,
                lineBreakMode: .byWordWrapping
            )

            UIColor.white.withAlphaComponent(0.72).setFill()
            UIBezierPath(roundedRect: CGRect(x: 116, y: 596, width: 170, height: 30), cornerRadius: 15).fill()
            drawText("VIDEO SAMPLE", in: CGRect(x: 136, y: 603, width: 132, height: 18), font: .monospacedSystemFont(ofSize: 12, weight: .black), color: ink, lineBreakMode: .byTruncatingTail)
        }

        guard let data = image.pngData() else {
            return picsumThumb("savi-sample-video-\(title)", width: 720, height: 720)
        }
        return "data:image/png;base64,\(data.base64EncodedString())"
    }

    private static func sampleVaultThumb(title: String, subtitle: String, symbolName: String = "lock.fill") -> String {
        sampleGraphicThumb(
            title: title,
            subtitle: subtitle,
            accentHex: "#7A35E8",
            symbolName: symbolName,
            rows: ["Private sample", "Invented demo data", "Protected by vault", "SAMPLE only"],
            dark: true
        )
    }

    private static func sampleSpreadsheetThumb() -> String {
        sampleGraphicThumb(
            title: "Market sizing",
            subtitle: "Sample spreadsheet",
            accentHex: "#5ADDCB",
            symbolName: "tablecells.fill",
            rows: ["TAM / SAM / SOM", "Assumptions", "Revenue model", "Sensitivity"]
        )
    }

    private static func drawText(
        _ value: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left,
        lineBreakMode: NSLineBreakMode = .byWordWrapping
    ) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = lineBreakMode
        NSString(string: value).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: style
            ]
        )
    }

    private static func drawSampleWatermark(
        in context: CGContext,
        center: CGPoint,
        color: UIColor,
        size: CGFloat,
        rotation: CGFloat
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: .black),
            .foregroundColor: color
        ]
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: rotation)
        let sampleSize = NSString(string: "SAMPLE").size(withAttributes: attrs)
        NSString(string: "SAMPLE").draw(
            at: CGPoint(x: -sampleSize.width / 2, y: -sampleSize.height / 2),
            withAttributes: attrs
        )
        context.restoreGState()
    }

    static let items: [SaviItem] = [
        // First-run utility saves, ordered to prove SAVI's practical value immediately.
        item(id: "sample-life-airbnb-code", title: "Airbnb door code + Wi-Fi", description: "SAMPLE stay note: front door 2486, Wi-Fi Pinehouse Guest, checkout 11 AM.", source: "SAVI", type: .text, folderId: "f-life-admin", tags: ["sample", "airbnb", "door-code", "wifi", "travel"], thumbnail: sampleFullBleedStayThumb(), hoursAgo: 1),
        item(id: "sample-watch-ted-procrastination", title: "Inside the Mind of a Master Procrastinator | Tim Urban | TED", description: "Tim Urban via YouTube", url: "https://www.youtube.com/watch?v=arj7oStGLkU", source: "YouTube", type: .video, folderId: "f-must-see", tags: ["youtube", "video", "productivity", "life-hack"], thumbnail: youtubeThumb("arj7oStGLkU"), hoursAgo: 2, metadataPolicy: .liveMetadata),
        item(id: "sample-place-ramen", title: "Jennifer's ramen recommendation", description: "Jennifer said to order the spicy miso, sit at the counter, and save the pin before the group chat buries it.", url: "https://maps.apple.com/?q=Tokyo%20ramen", source: "Jennifer", type: .place, folderId: "f-travel", tags: ["maps", "restaurant", "friend-rec", "tokyo", "food"], thumbnail: sampleFoodRecommendationThumb(), hoursAgo: 3),
        item(id: "sample-life-driver-license", title: "Sample driver license copy", description: "Watermarked fake ID copy with invented demo data for testing document saves.", source: "Device", type: .file, folderId: "f-life-admin", tags: ["sample", "driver-license", "id", "document"], thumbnail: sampleLicenseThumb(), hoursAgo: 4, assetName: "sample-driver-license-copy.png", assetMime: "image/png", assetSize: 248_000),
        item(id: "sample-health-fasting-autophagy", title: "Intermittent fasting in the prevention and treatment of cancer - PubMed", description: "Chronic caloric restriction has powerful anticarcinogenic actions in both preclinical and clinical studies but may be difficult to sustain.", url: "https://pubmed.ncbi.nlm.nih.gov/34383300/", source: "PubMed", type: .article, folderId: "f-health", tags: ["research", "fasting", "autophagy", "questions-for-doctor"], thumbnail: "https://cdn.ncbi.nlm.nih.gov/pubmed/persistent/pubmed-meta-image-v2.jpg", hoursAgo: 5, metadataPolicy: .liveMetadata),
        item(id: "sample-ai-chaos-plan", title: "Prompt: turn chaos into a plan", description: "Reusable AI prompt: Here is the messy situation, the goal, and the constraints. Ask me three sharp questions, then turn it into a prioritized plan with next actions, risks, and what to do first.", source: "Prompt", type: .text, folderId: "f-growth", tags: ["prompt", "ai", "planning", "productivity"], thumbnail: sampleAIPromptThumb(), hoursAgo: 6),
        item(id: "sample-life-hotel-booking", title: "Hotel booking confirmation", description: "SAMPLE booking card: Hotel Nube Demo, May 14-17, confirmation SVI-48291.", source: "SAVI", type: .text, folderId: "f-life-admin", tags: ["sample", "hotel", "booking", "confirmation", "travel"], thumbnail: sampleBookingThumb(), hoursAgo: 7),
        item(id: "sample-food-mom-lasagna-audio", title: "Mom's lasagna sauce voice note", description: "Audio note sample: brown the garlic slowly, simmer the sauce, and add the basil at the end.", source: "Voice Memo", type: .file, folderId: "f-recipes", tags: ["audio", "recipe", "mom", "sauce", "lasagna"], thumbnail: sampleAudioRecipeThumb(), hoursAgo: 8, assetName: "moms-lasagna-sauce.m4a", assetMime: "audio/mp4", assetSize: 824_000),
        item(id: "sample-meme-goyo", title: "Goyo goyo with lyrics", description: "A funny video save that shows how memes land in SAVI.", url: "https://www.youtube.com/results?search_query=goyo+goyo+with+lyrics", source: "YouTube", type: .video, folderId: "f-lmao", tags: ["meme", "funny", "youtube"], thumbnail: sampleVideoThumb(title: "Goyo goyo with lyrics"), hoursAgo: 9),
        item(id: "sample-health-sugar-cancer-myths", title: "Common Cancer Myths and Misconceptions", description: "The latest science-based information concerning some common misconceptions about cancer.", url: "https://www.cancer.gov/about-cancer/causes-prevention/risk/myths", source: "NCI", type: .article, folderId: "f-health", tags: ["research", "cancer-myths", "nutrition", "questions-for-doctor"], thumbnail: "https://www.cancer.gov/sites/www/files/cgov_image/social_media/900/700/files/pensive-woman-blue-background-social-media.jpg", hoursAgo: 10, metadataPolicy: .liveMetadata),
        item(id: "sample-life-insurance-card", title: "Sample insurance card", description: "Fake insurance card with demo policy numbers and a clear SAMPLE watermark.", source: "Device", type: .file, folderId: "f-life-admin", tags: ["sample", "insurance", "card", "document"], thumbnail: sampleInsuranceThumb(), hoursAgo: 11, assetName: "sample-insurance-card.png", assetMime: "image/png", assetSize: 196_000),
        item(id: "sample-science-webb", title: "James Webb Space Telescope - NASA Science", description: "Webb is the premier observatory of the next decade, serving thousands of astronomers worldwide.", url: "https://science.nasa.gov/mission/webb/", source: "NASA", type: .article, folderId: "f-wtf-favorites", tags: ["space", "nasa", "science"], thumbnail: "https://science.nasa.gov/wp-content/uploads/2024/05/jwst_artist_concept_0.png", hoursAgo: 12, metadataPolicy: .liveMetadata),
        item(id: "sample-life-contract-template", title: "Contract template to reuse", description: "A reusable service agreement template saved where life admin documents live.", source: "Files", type: .file, folderId: "f-life-admin", tags: ["contract", "template", "docx", "important"], thumbnail: sampleContractThumb(), hoursAgo: 13, assetName: "sample-service-contract-template.docx", assetMime: "application/vnd.openxmlformats-officedocument.wordprocessingml.document", assetSize: 312_000),
        item(id: "sample-health-parasites-gut", title: "Parasites and gut health: evidence notes", description: "Neutral reading list from CDC and PubMed on parasite risk, prevention, and the gut parasitome.", url: "https://www.cdc.gov/parasites/causes/index.html", source: "CDC", type: .article, folderId: "f-health", tags: ["research", "gut-health", "parasites", "questions-for-doctor"], thumbnail: sampleHealthResearchThumb(), hoursAgo: 14, metadataPolicy: .liveMetadata),
        item(id: "sample-life-recovery-code", title: "Emergency recovery code", description: "SAMPLE long code: RK8F-Q44P-29LM-7DZQ. Shows how SAVI keeps exact text findable.", source: "SAVI", type: .text, folderId: "f-life-admin", tags: ["sample", "recovery-code", "important", "admin"], thumbnail: sampleRecoveryThumb(), hoursAgo: 16),
        item(id: "sample-research-mebendazole", title: "Anti-parasitic drugs in cancer trials", description: "Clinical-trial and phase 1 research links about mebendazole. Saved as research, not medical advice.", url: "https://www.clinicaltrials.gov/study/NCT03628079", source: "ClinicalTrials.gov", type: .article, folderId: "f-research", tags: ["clinical-trial", "research", "mebendazole", "questions-for-doctor"], thumbnailSeed: "savi-mebendazole-trials", hoursAgo: 22, metadataPolicy: .liveMetadata),
        item(id: "sample-ai-agent-guide", title: "Building Effective AI Agents", description: "Discover how Anthropic approaches the development of reliable AI agents.", url: "https://www.anthropic.com/engineering/building-effective-agents", source: "Anthropic", type: .article, folderId: "f-growth", tags: ["ai", "agent", "productivity", "life-hack"], thumbnail: "https://cdn.sanity.io/images/4zrzovbb/website/76b5733c669f0dfb9c7aa7fc512a495867cf12e6-2400x1260.png", hoursAgo: 23, metadataPolicy: .liveMetadata),

        item(id: "sample-watch-claude", title: "How to use Claude like a thinking partner", description: "A practical setup for long-context productivity and better saved research.", url: "https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview", source: "Anthropic", type: .article, folderId: "f-must-see", tags: ["read-later", "ai", "productivity"], thumbnailSeed: "savi-claude-thinking", hoursAgo: 24, metadataPolicy: .liveMetadata),
        item(id: "sample-watch-wwdc", title: "Apple WWDC recap", description: "A conference video page to watch when you have ten quiet minutes.", url: "https://developer.apple.com/videos/wwdc2024/", source: "Apple", type: .video, folderId: "f-must-see", tags: ["video", "apple", "tech"], thumbnailSeed: "savi-wwdc-recap", hoursAgo: 25, metadataPolicy: .liveMetadata),
        item(id: "sample-watch-extension", title: "The browser extension I keep using", description: "A practical link about extensions and tiny tools that keep saving time.", url: "https://support.apple.com/guide/safari/get-extensions-sfri32508/mac", source: "Apple Support", type: .article, folderId: "f-must-see", tags: ["read-later", "tools", "browser"], thumbnailSeed: "savi-browser-extension", hoursAgo: 26),
        item(id: "sample-watch-coffee-tech", title: "Japan's quiet coffee tech", description: "A calm travel read about cafe culture and delightful little systems.", url: "https://www.japan-guide.com/e/e2343.html", source: "Japan Guide", type: .article, folderId: "f-must-see", tags: ["read-later", "japan", "coffee"], thumbnailSeed: "savi-coffee-tech", hoursAgo: 35),
        item(id: "sample-watch-documentary", title: "Useful documentary to watch later", description: "A video placeholder showing that watch-list saves do not have to be urgent.", url: "https://www.youtube.com/learning", source: "YouTube", type: .video, folderId: "f-must-see", tags: ["watch-later", "documentary", "youtube"], thumbnail: sampleVideoThumb(title: "Useful documentary", accentHex: "#7A35E8"), hoursAgo: 44),

        item(id: "sample-ai-automation", title: "AI automation starter pack", description: "Agent patterns, tools, and tiny automations that make SAVI-worthy notes.", url: "https://www.anthropic.com/engineering/building-effective-agents", source: "Anthropic", type: .article, folderId: "f-growth", tags: ["ai", "automation", "productivity"], thumbnailSeed: "savi-ai-automation", hoursAgo: 56),
        item(id: "sample-ai-meeting-tasks", title: "Prompt: cross-check my blind spots", description: "Reusable AI prompt: Review this plan like a skeptical expert. Find the weakest assumptions, name what I am ignoring, argue the opposite side, and give me the smallest test that would prove whether I am right.", source: "Prompt", type: .text, folderId: "f-growth", tags: ["prompt", "ai", "cross-check", "blind-spots", "decision"], thumbnail: sampleCrossCheckPromptThumb(), hoursAgo: 17),
        item(id: "sample-ai-inbox-zero", title: "Inbox zero with shortcuts", description: "A workflow link for shortcuts, reminders, and calmer inboxes.", url: "https://support.apple.com/guide/shortcuts/welcome/ios", source: "Apple Support", type: .article, folderId: "f-growth", tags: ["workflow", "shortcuts", "productivity"], thumbnailSeed: "savi-inbox-zero", hoursAgo: 80),
        item(id: "sample-ai-workspace", title: "Prompt: find my strongest talents", description: "Reusable AI prompt: Look at my work history, hobbies, saved notes, and the problems people ask me to solve. Identify my recurring strengths, where they are useful, and a 7-day experiment to test one direction.", source: "Prompt", type: .text, folderId: "f-growth", tags: ["prompt", "ai", "talent", "reflection", "career"], thumbnail: sampleTalentPromptThumb(), hoursAgo: 92),

        item(id: "sample-meme-cursed", title: "Perfectly cursed screenshot", description: "An internet moment that belongs exactly where it is.", source: "Photos", type: .image, folderId: "f-lmao", tags: ["meme", "screenshot", "funny"], thumbnailSeed: "savi-cursed-screenshot", hoursAgo: 104),
        item(id: "sample-meme-group-chat", title: "Group chat reaction image", description: "The reaction image you will absolutely need again.", source: "Photos", type: .image, folderId: "f-lmao", tags: ["reaction", "meme", "image"], thumbnailSeed: "savi-reaction-image", hoursAgo: 116),
        item(id: "sample-meme-typo", title: "A+ accidental typo", description: "A tiny screenshot save with extremely specific future usefulness.", source: "Device", type: .image, folderId: "f-lmao", tags: ["screenshot", "funny"], thumbnailSeed: "savi-accidental-typo", hoursAgo: 128),
        item(id: "sample-meme-review", title: "The funniest product review", description: "A saved review that somehow became the whole joke.", url: "https://en.wikipedia.org/wiki/Review_bomb", source: "Web", type: .link, folderId: "f-lmao", tags: ["funny", "review", "web"], thumbnailSeed: "savi-funny-review", hoursAgo: 140),

        item(id: "sample-place-airport-coffee", title: "Best airport coffee backup", description: "A useful pin for the next time your gate changes twice.", url: "https://maps.apple.com/?q=airport%20coffee", source: "Maps", type: .place, folderId: "f-travel", tags: ["maps", "coffee", "travel"], thumbnailSeed: "savi-airport-coffee", hoursAgo: 18),
        item(id: "sample-place-museum", title: "Weekend museum idea", description: "A place save for the kind of Saturday that starts with coffee.", url: "https://maps.apple.com/?q=museum", source: "Maps", type: .place, folderId: "f-travel", tags: ["maps", "museum", "weekend"], thumbnailSeed: "savi-museum", hoursAgo: 164),
        item(id: "sample-place-walk", title: "Walking route for a lazy Sunday", description: "A route save with snacks, shade, and one perfect bookstore stop.", url: "https://maps.apple.com/?q=walking%20route", source: "Maps", type: .place, folderId: "f-travel", tags: ["route", "maps", "weekend"], thumbnailSeed: "savi-sunday-walk", hoursAgo: 188),

        item(id: "sample-food-pasta", title: "Late-night pasta formula", description: "A fast dinner idea you would otherwise lose in a scroll.", url: "https://www.bbcgoodfood.com/recipes/collection/pasta-recipes", source: "BBC Good Food", type: .article, folderId: "f-recipes", tags: ["recipe", "dinner", "pasta"], thumbnailSeed: "savi-late-pasta", hoursAgo: 15, metadataPolicy: .liveMetadata),
        item(id: "sample-food-salmon", title: "Crispy salmon bowl", description: "A dinner recipe collection for salmon nights and lunch leftovers.", url: "https://www.bbcgoodfood.com/recipes/collection/salmon-recipes", source: "BBC Good Food", type: .article, folderId: "f-recipes", tags: ["recipe", "salmon", "dinner"], thumbnailSeed: "savi-salmon-bowl", hoursAgo: 212),
        item(id: "sample-food-wrap", title: "3-minute breakfast wrap", description: "A quick breakfast idea for mornings that got away from you.", url: "https://www.bbcgoodfood.com/recipes/collection/wrap-recipes", source: "BBC Good Food", type: .article, folderId: "f-recipes", tags: ["recipe", "breakfast", "wrap"], thumbnailSeed: "savi-breakfast-wrap", hoursAgo: 224),
        item(id: "sample-food-taco-sauce", title: "The taco sauce worth saving", description: "A tiny recipe link with huge future leftovers energy.", url: "https://www.bbcgoodfood.com/recipes/collection/taco-recipes", source: "BBC Good Food", type: .article, folderId: "f-recipes", tags: ["recipe", "tacos", "sauce"], thumbnailSeed: "savi-taco-sauce", hoursAgo: 236),
        item(id: "sample-food-shopping", title: "Dinner party shopping list", description: "Pasta, lemons, sparkling water, salad, dark chocolate, extra ice.", source: "Paste", type: .text, folderId: "f-recipes", tags: ["groceries", "dinner", "list"], thumbnail: sampleNoteThumb(title: "Dinner list", subtitle: "Groceries to remember", accentHex: "#FFB978", symbolName: "cart.fill", rows: ["Pasta + lemons", "Sparkling water", "Salad", "Dark chocolate + ice"]), hoursAgo: 248),

        item(id: "sample-note-gifts", title: "Gift ideas note", description: "Dad: good flashlight. Mia: ceramic mug. Save before December panic.", source: "Paste", type: .text, folderId: "f-paste-bin", tags: ["note", "gifts"], thumbnail: sampleNoteThumb(title: "Gift ideas", subtitle: "Tiny notes worth keeping", accentHex: "#DE5B98", symbolName: "gift.fill", rows: ["Dad: flashlight", "Mia: ceramic mug", "No panic shopping", "Revisit in December"]), hoursAgo: 20),
        item(id: "sample-note-packing", title: "Packing list snippet", description: "Charger, passport, headphones, sunscreen, tiny umbrella, patience.", source: "Clipboard", type: .text, folderId: "f-paste-bin", tags: ["packing", "travel", "note"], thumbnail: sampleNoteThumb(title: "Packing list", subtitle: "Clipboard save", accentHex: "#68C6E8", symbolName: "suitcase.fill", rows: ["Charger", "Passport", "Headphones", "Sunscreen + umbrella"]), hoursAgo: 272),
        item(id: "sample-note-email", title: "Reusable email reply", description: "Thanks for sending this over. I will review it and get back to you by Friday.", source: "Paste", type: .text, folderId: "f-paste-bin", tags: ["template", "email"], thumbnail: sampleNoteThumb(title: "Email reply", subtitle: "Reusable response", accentHex: "#9286A8", symbolName: "envelope.fill", rows: ["Thanks for sending this", "I'll review it", "Back to you by Friday", "Polite + fast"]), hoursAgo: 284),
        item(id: "sample-note-quote", title: "Random quote to keep", description: "A line that made sense at 1:12 AM and may make sense again later.", source: "Clipboard", type: .text, folderId: "f-paste-bin", tags: ["quote", "note"], thumbnail: sampleNoteThumb(title: "Quote", subtitle: "Saved at 1:12 AM", accentHex: "#7A35E8", symbolName: "quote.bubble.fill", rows: ["Keep the weird line", "Find it later", "Maybe it matters", "Maybe it was midnight"]), hoursAgo: 296),
        item(id: "sample-note-before-disappears", title: "Save this before it disappears", description: "The kind of tiny copied detail that gets lost unless you park it somewhere.", source: "Clipboard", type: .text, folderId: "f-paste-bin", tags: ["note", "clipboard", "temporary"], thumbnail: sampleNoteThumb(title: "Quick clip", subtitle: "Before it disappears", accentHex: "#D6F83A", symbolName: "paperclip", rows: ["Copied detail", "Temporary but useful", "Searchable later", "No tab pile"]), hoursAgo: 308),

        item(id: "sample-private-passport", title: "Sample passport checklist", description: "SAMPLE only: invented renewal reminder, scan checklist, and travel document note.", source: "SAVI", type: .text, folderId: "f-private-vault", tags: ["sample", "private", "passport"], thumbnail: sampleVaultThumb(title: "Passport list", subtitle: "Renewal checklist", symbolName: "airplane"), hoursAgo: 21),
        item(id: "sample-private-birth-certificate", title: "Sample birth certificate copy", description: "Fake birth certificate record with invented demo data and SAMPLE watermark.", source: "Files", type: .file, folderId: "f-private-vault", tags: ["sample", "birth-certificate", "private", "pdf"], thumbnail: sampleVaultThumb(title: "Birth record", subtitle: "Invented sample copy", symbolName: "doc.richtext.fill"), hoursAgo: 332, assetName: "sample-birth-certificate.pdf", assetMime: "application/pdf", assetSize: 205_000),
        item(id: "sample-private-medical-note", title: "Sample medical appointment note", description: "SAMPLE only: invented appointment time, questions to ask, and follow-up reminder.", source: "SAVI", type: .text, folderId: "f-private-vault", tags: ["sample", "medical", "private"], thumbnail: sampleVaultThumb(title: "Medical note", subtitle: "Questions to ask", symbolName: "cross.case.fill"), hoursAgo: 344),
        item(id: "sample-private-wifi", title: "Sample Wi-Fi password note", description: "SAMPLE password note: network Pinehouse, guest code placeholder, router location.", source: "SAVI", type: .text, folderId: "f-private-vault", tags: ["sample", "private", "password", "wifi"], thumbnail: sampleVaultThumb(title: "Wi-Fi password", subtitle: "Sample credentials", symbolName: "wifi"), hoursAgo: 356),
        item(id: "sample-private-receipt", title: "Sample return receipt PDF", description: "Fake receipt sample that demonstrates protected document saves.", source: "Device", type: .file, folderId: "f-private-vault", tags: ["sample", "receipt", "pdf"], thumbnail: sampleVaultThumb(title: "Return receipt", subtitle: "Protected PDF", symbolName: "receipt.fill"), hoursAgo: 368, assetName: "sample-return-receipt.pdf", assetMime: "application/pdf", assetSize: 142_000),

        item(id: "sample-research-climate", title: "Climate report PDF", description: "A public PDF report for testing document search and filters.", url: "https://www.ipcc.ch/report/ar6/wg1/downloads/report/IPCC_AR6_WGI_SPM.pdf", source: "IPCC", type: .file, folderId: "f-research", tags: ["pdf", "report", "climate"], thumbnail: sampleGraphicThumb(title: "Climate report", subtitle: "Public PDF sample", accentHex: "#5ADDCB", symbolName: "leaf.fill", rows: ["IPCC summary", "Charts + findings", "PDF document", "Saved for research"]), hoursAgo: 19, assetName: "ipcc-ar6-summary.pdf", assetMime: "application/pdf", assetSize: 920_000),
        item(id: "sample-research-microbiome", title: "Gut parasitome review", description: "PubMed review save about parasites, microbiome interactions, and research questions.", url: "https://pubmed.ncbi.nlm.nih.gov/35509426/", source: "PubMed", type: .article, folderId: "f-research", tags: ["pubmed", "microbiome", "parasites", "research"], thumbnailSeed: "savi-parasitome-review", hoursAgo: 392),
        item(id: "sample-research-paper", title: "Academic paper to revisit", description: "Attention Is All You Need, saved as a classic research reference.", url: "https://arxiv.org/abs/1706.03762", source: "arXiv", type: .article, folderId: "f-research", tags: ["paper", "arxiv", "pdf"], thumbnailSeed: "savi-academic-paper", hoursAgo: 404),
        item(id: "sample-research-market", title: "Market sizing spreadsheet", description: "A spreadsheet save for testing docs, work research, and file search.", source: "Device", type: .file, folderId: "f-research", tags: ["spreadsheet", "market", "research"], thumbnail: sampleSpreadsheetThumb(), hoursAgo: 416, assetName: "sample-market-sizing.xlsx", assetMime: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", assetSize: 286_000),

        item(id: "sample-design-palette", title: "Color palette screenshot", description: "A screenshot save for the next time a project needs a mood fast.", source: "Photos", type: .image, folderId: "f-design", tags: ["color", "screenshot", "design"], thumbnailSeed: "savi-color-palette", hoursAgo: 428),
        item(id: "sample-design-mobile-nav", title: "Mobile nav reference", description: "A compact visual reference for thumb-first interface ideas.", url: "https://developer.apple.com/design/human-interface-guidelines/navigation-bars", source: "Apple HIG", type: .article, folderId: "f-design", tags: ["design", "mobile", "ui"], thumbnailSeed: "savi-mobile-nav", hoursAgo: 440),
        item(id: "sample-design-type", title: "Type pairing reference", description: "A typography idea saved because the right font changes the whole mood.", url: "https://fonts.google.com/knowledge/choosing_type/pairing_typefaces", source: "Google Fonts", type: .article, folderId: "f-design", tags: ["typography", "font", "design"], thumbnailSeed: "savi-type-pairing", hoursAgo: 452),
        item(id: "sample-design-empty-state", title: "Beautiful empty state", description: "A friendly screen that explains what to do without shouting.", url: "https://www.nngroup.com/articles/empty-state-interface-design/", source: "NN/g", type: .article, folderId: "f-design", tags: ["ui", "empty-state", "design"], thumbnailSeed: "savi-empty-state", hoursAgo: 464),
        item(id: "sample-design-spacing", title: "Landing page spacing idea", description: "A layout reference for visual hierarchy, margins, and readable sections.", url: "https://www.nngroup.com/articles/visual-hierarchy-ux-definition/", source: "NN/g", type: .article, folderId: "f-design", tags: ["layout", "web", "design"], thumbnailSeed: "savi-spacing", hoursAgo: 476),

        item(id: "sample-health-sleep", title: "Sleep hygiene article", description: "A readable guide for sleep basics, routines, and better rest.", url: "https://www.cdc.gov/sleep/about/index.html", source: "CDC", type: .article, folderId: "f-health", tags: ["sleep", "wellness", "article"], thumbnailSeed: "savi-sleep-hygiene", hoursAgo: 500),
        item(id: "sample-health-recovery", title: "Workout recovery protocol", description: "Sleep, mobility, hydration, and protein notes for busy weeks.", source: "Paste", type: .text, folderId: "f-health", tags: ["health", "fitness", "recovery"], thumbnail: sampleNoteThumb(title: "Recovery", subtitle: "Busy week protocol", accentHex: "#70D59B", symbolName: "figure.cooldown", rows: ["Sleep", "Mobility", "Hydration", "Protein"]), hoursAgo: 512),
        item(id: "sample-health-protein", title: "Protein snack list", description: "Greek yogurt, eggs, tuna packets, hummus, cottage cheese, protein smoothie.", source: "Paste", type: .text, folderId: "f-health", tags: ["nutrition", "protein", "note"], thumbnail: sampleNoteThumb(title: "Protein snacks", subtitle: "Fast list", accentHex: "#70D59B", symbolName: "fork.knife", rows: ["Greek yogurt", "Eggs", "Tuna packets", "Hummus + cottage cheese"]), hoursAgo: 524),

        item(id: "sample-science-math", title: "Beautiful math thread", description: "A number theory collection worth saving for the next curiosity spiral.", url: "https://www.quantamagazine.org/tag/number-theory/", source: "Quanta", type: .article, folderId: "f-wtf-favorites", tags: ["math", "science", "thread"], thumbnailSeed: "savi-beautiful-math", hoursAgo: 536),
        item(id: "sample-science-sea", title: "Deep sea creature article", description: "A NOAA explainer from the part of Earth that looks imaginary.", url: "https://oceanexplorer.noaa.gov/facts/deep-ocean.html", source: "NOAA", type: .article, folderId: "f-wtf-favorites", tags: ["biology", "deep-sea", "science"], thumbnailSeed: "savi-deep-sea", hoursAgo: 548),
        item(id: "sample-science-robot", title: "Tiny robot research clip", description: "A robotics save that belongs with real discoveries, not random tech noise.", url: "https://en.wikipedia.org/wiki/Microrobotics", source: "Web", type: .article, folderId: "f-wtf-favorites", tags: ["robotics", "science", "video"], thumbnailSeed: "savi-tiny-robot", hoursAgo: 560),
        item(id: "sample-science-volcano", title: "Volcano camera feed", description: "A volcano reference link for the dramatic rocks department.", url: "https://www.nps.gov/subjects/volcanoes/index.htm", source: "NPS", type: .link, folderId: "f-wtf-favorites", tags: ["volcano", "science", "nature"], thumbnailSeed: "savi-volcano", hoursAgo: 572),

        item(id: "sample-rabbit-lost-media", title: "Lost media rabbit hole", description: "A weird media-history dive to enjoy when curiosity wins.", url: "https://en.wikipedia.org/wiki/Lost_media", source: "Wikipedia", type: .link, folderId: "f-tinfoil", tags: ["rabbit-hole", "lost-media"], thumbnailSeed: "savi-lost-media", hoursAgo: 584),
        item(id: "sample-rabbit-map", title: "Ancient map mystery", description: "A cartography history save for later, with just enough skepticism.", url: "https://en.wikipedia.org/wiki/History_of_cartography", source: "Wikipedia", type: .article, folderId: "f-tinfoil", tags: ["mystery", "history", "map"], thumbnailSeed: "savi-ancient-map", hoursAgo: 596),
        item(id: "sample-rabbit-ufo", title: "UFO article to fact-check", description: "A public archive link kept as a rabbit hole, not confused for science.", url: "https://www.archives.gov/research/topics/uaps", source: "National Archives", type: .article, folderId: "f-tinfoil", tags: ["ufo", "fact-check", "rabbit-hole"], thumbnailSeed: "savi-ufo-fact-check", hoursAgo: 608),
        item(id: "sample-rabbit-folklore", title: "Internet folklore timeline", description: "A chronology of strange web stories and the screenshots that survived.", url: "https://knowyourmeme.com/", source: "Know Your Meme", type: .article, folderId: "f-tinfoil", tags: ["internet", "folklore", "history"], thumbnailSeed: "savi-folklore", hoursAgo: 620),
        item(id: "sample-rabbit-failed-budget", title: "Failed budget rabbit hole", description: "A weird mega-project article for the things that cost too much and got too famous.", url: "https://en.wikipedia.org/wiki/Big_Dig", source: "Wikipedia", type: .article, folderId: "f-tinfoil", tags: ["rabbit-hole", "budget", "weird-project"], thumbnailSeed: "savi-failed-budget", hoursAgo: 632),

        item(id: "sample-random-screenshot", title: "Mystery screenshot", description: "A screenshot with no context, lovingly contained.", source: "Device", type: .image, folderId: "f-random", tags: ["screenshot", "misc"], thumbnailSeed: "savi-mystery-screenshot", hoursAgo: 644),
        item(id: "sample-random-untitled", title: "Untitled link rescue", description: "A generic link that SAVI keeps reachable until metadata improves.", url: "https://www.wikipedia.org/", source: "Web", type: .link, folderId: "f-random", tags: ["link", "unsorted"], thumbnailSeed: "savi-untitled-rescue", hoursAgo: 656),
        item(id: "sample-random-product", title: "Random product page", description: "A product link saved before the tab pile eats it.", url: "https://www.apple.com/airtag/", source: "Web", type: .link, folderId: "f-random", tags: ["product", "misc"], thumbnailSeed: "savi-random-product", hoursAgo: 668),
        item(id: "sample-random-later", title: "Maybe useful later", description: "A save that has no obvious home yet, which is exactly the point.", url: "https://archive.org/", source: "Web", type: .link, folderId: "f-random", tags: ["misc", "later"], thumbnailSeed: "savi-maybe-useful", hoursAgo: 680),
        item(id: "sample-random-classify", title: "Thing I could not classify", description: "A mystery save that shows where leftovers go until you sort them.", source: "SAVI", type: .text, folderId: "f-random", tags: ["misc", "unsorted"], hoursAgo: 692)
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
        let previousOrders: [String: [Int]] = [
            "f-life-admin": [0],
            "f-must-see": [0, 1],
            "f-growth": [1, 2, 3],
            "f-lmao": [2, 3, 4],
            "f-travel": [3, 4, 6],
            "f-recipes": [4, 5, 7],
            "f-paste-bin": [1, 5, 6],
            "f-private-vault": [5, 6, 7],
            "f-research": [7, 8, 10],
            "f-design": [8, 9, 10],
            "f-health": [8, 9, 10],
            "f-wtf-favorites": [2, 10, 11],
            "f-tinfoil": [11, 12],
            "f-random": [12, 13],
            "f-all": [13, 14]
        ]

        return folders.map { folder in
            guard let seed = Self.folders.first(where: { $0.id == folder.id }) else { return folder }
            var next = folder
            let knownNames = previousNames[folder.id, default: [seed.name]]
            if knownNames.contains(folder.name) {
                next.name = seed.name
            }
            if previousOrders[folder.id]?.contains(folder.order) == true {
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
