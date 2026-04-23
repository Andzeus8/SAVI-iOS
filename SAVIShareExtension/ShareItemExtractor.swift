import Foundation
import LinkPresentation
import MobileCoreServices
import UniformTypeIdentifiers

enum ShareItemExtractorError: LocalizedError {
    case missingInputItem
    case unsupportedAttachment
    case failedToLoadContent

    var errorDescription: String? {
        switch self {
        case .missingInputItem:
            return "No shared content was provided."
        case .unsupportedAttachment:
            return "This kind of shared content isn’t supported yet."
        case .failedToLoadContent:
            return "The shared content could not be loaded."
        }
    }
}

enum ShareItemExtractor {
    static func extract(from context: NSExtensionContext?) async throws -> PendingShare {
        guard let item = (context?.inputItems.first as? NSExtensionItem) ?? (context?.inputItems.compactMap({ $0 as? NSExtensionItem }).first),
              let provider = item.attachments?.first
        else {
            throw ShareItemExtractorError.missingInputItem
        }

        let sourceBundleID = "Share Extension"
        let timestamp = Date().timeIntervalSince1970 * 1000
        let itemTitle: String? = nil
        let itemText: String? = nil

        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            let url = try await provider.loadURL()
            let fallbackTitle = url.lastPathComponent.isEmpty ? url.absoluteString : url.lastPathComponent
            let type = inferredType(for: url.absoluteString)
            return PendingShare(
                id: UUID().uuidString,
                url: url.absoluteString,
                title: itemTitle ?? fallbackTitle,
                type: type,
                thumbnail: nil,
                timestamp: timestamp,
                sourceApp: sourceLabel(from: sourceBundleID, sharedURL: url.absoluteString),
                text: itemText,
                fileName: nil,
                filePath: nil,
                mimeType: nil,
                itemDescription: itemText,
                folderId: suggestedFolderId(type: type, url: url.absoluteString, title: itemTitle, description: itemText),
                tags: inferredTags(type: type, url: url.absoluteString, title: itemTitle, description: itemText, source: sourceBundleID)
            )
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) || provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            let text = try await provider.loadText()
            let title = itemTitle ?? text.split(separator: "\n").first.map(String.init) ?? "Shared text"
            return PendingShare(
                id: UUID().uuidString,
                url: nil,
                title: title,
                type: "text",
                thumbnail: nil,
                timestamp: timestamp,
                sourceApp: sourceLabel(from: sourceBundleID, sharedURL: nil),
                text: text,
                fileName: nil,
                filePath: nil,
                mimeType: UTType.plainText.identifier,
                itemDescription: text,
                folderId: suggestedFolderId(type: "article", url: nil, title: title, description: text),
                tags: inferredTags(type: "article", url: nil, title: title, description: text, source: sourceBundleID)
            )
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            let copiedURL = try await provider.copyFileRepresentation(
                preferredTypeIdentifier: UTType.image.identifier
            )
            let data = try Data(contentsOf: copiedURL)
            let dataURL = "data:\(UTType.image.identifier);base64,\(data.base64EncodedString())"
            return PendingShare(
                id: UUID().uuidString,
                url: nil,
                title: itemTitle ?? copiedURL.lastPathComponent,
                type: "image",
                thumbnail: dataURL,
                timestamp: timestamp,
                sourceApp: sourceLabel(from: sourceBundleID, sharedURL: nil),
                text: itemText,
                fileName: copiedURL.lastPathComponent,
                filePath: copiedURL.path,
                mimeType: UTType.image.identifier,
                itemDescription: itemText,
                folderId: "f-private-vault",
                tags: inferredTags(type: "image", url: nil, title: itemTitle ?? copiedURL.lastPathComponent, description: itemText, source: sourceBundleID)
            )
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            let copiedURL = try await provider.copyFileRepresentation(
                preferredTypeIdentifier: UTType.pdf.identifier
            )
            return PendingShare(
                id: UUID().uuidString,
                url: nil,
                title: itemTitle ?? copiedURL.lastPathComponent,
                type: "pdf",
                thumbnail: nil,
                timestamp: timestamp,
                sourceApp: sourceLabel(from: sourceBundleID, sharedURL: nil),
                text: itemText,
                fileName: copiedURL.lastPathComponent,
                filePath: copiedURL.path,
                mimeType: UTType.pdf.identifier,
                itemDescription: itemText,
                folderId: "f-private-vault",
                tags: inferredTags(type: "file", url: nil, title: itemTitle ?? copiedURL.lastPathComponent, description: itemText, source: sourceBundleID)
            )
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) || provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
            let preferred = provider.registeredTypeIdentifiers.first ?? UTType.data.identifier
            let copiedURL = try await provider.copyFileRepresentation(preferredTypeIdentifier: preferred)
            return PendingShare(
                id: UUID().uuidString,
                url: nil,
                title: itemTitle ?? copiedURL.lastPathComponent,
                type: "file",
                thumbnail: nil,
                timestamp: timestamp,
                sourceApp: sourceLabel(from: sourceBundleID, sharedURL: nil),
                text: itemText,
                fileName: copiedURL.lastPathComponent,
                filePath: copiedURL.path,
                mimeType: preferred,
                itemDescription: itemText,
                folderId: "f-private-vault",
                tags: inferredTags(type: "file", url: nil, title: itemTitle ?? copiedURL.lastPathComponent, description: itemText, source: sourceBundleID)
            )
        }

        throw ShareItemExtractorError.unsupportedAttachment
    }

    static func enrich(_ share: PendingShare) async -> PendingShare {
        var resolved = share
        let cleanTitle = resolved.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.isEmpty {
            resolved.title = fallbackTitle(for: resolved)
        }

        guard let urlString = resolved.url,
              let url = URL(string: urlString),
              url.scheme?.hasPrefix("http") == true
        else {
            resolved.folderId = resolved.folderId ?? suggestedFolderId(type: resolved.type, url: resolved.url, title: resolved.title, description: resolved.itemDescription ?? resolved.text)
            resolved.tags = dedupeTags(resolved.tags ?? inferredTags(type: resolved.type, url: resolved.url, title: resolved.title, description: resolved.itemDescription ?? resolved.text, source: resolved.sourceApp))
            return resolved
        }

        resolved.type = inferredType(for: urlString)
        resolved.sourceApp = sourceLabel(from: resolved.sourceApp, sharedURL: urlString)

        if resolved.type == "place",
           let placeName = extractPlaceName(from: url) {
            resolved.title = placeName
            resolved.itemDescription = resolved.itemDescription ?? "Saved place from \(resolved.sourceApp)."
        }

        if let metadata = await fetchRemoteMetadata(for: url) {
            if shouldReplaceTitle(current: resolved.title, with: metadata.title) {
                resolved.title = metadata.title ?? resolved.title
            }
            if let description = metadata.description, !description.isEmpty {
                resolved.itemDescription = description
            }
            if (resolved.thumbnail ?? "").isEmpty, let imageURL = metadata.imageURL, !imageURL.isEmpty {
                resolved.thumbnail = imageURL
            }
            if (resolved.sourceApp.isEmpty || resolved.sourceApp == "Share Extension"), let provider = metadata.provider, !provider.isEmpty {
                resolved.sourceApp = provider
            }
            resolved.tags = dedupeTags((resolved.tags ?? []) + metadata.tags)
        }

        resolved.folderId = suggestedFolderId(
            type: resolved.type,
            url: resolved.url,
            title: resolved.title,
            description: resolved.itemDescription ?? resolved.text
        )
        resolved.tags = dedupeTags(
            (resolved.tags ?? []) +
            inferredTags(
                type: resolved.type,
                url: resolved.url,
                title: resolved.title,
                description: resolved.itemDescription ?? resolved.text,
                source: resolved.sourceApp
            )
        )
        return resolved
    }
}

private struct RemoteMetadata {
    let title: String?
    let description: String?
    let imageURL: String?
    let provider: String?
    let tags: [String]
}

private struct YouTubeOEmbedResponse: Decodable {
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

private struct NoembedResponse: Decodable {
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

struct FolderPreset {
    let id: String
    let name: String
}

extension ShareItemExtractor {
    static let folderPresets: [FolderPreset] = [
        .init(id: "f-private-vault", name: "Private Vault"),
        .init(id: "f-growth", name: "Growth Hacks"),
        .init(id: "f-wtf-favorites", name: "WTF Favorites"),
        .init(id: "f-tinfoil", name: "Tinfoil Hat Club"),
        .init(id: "f-lmao", name: "LMAO"),
        .init(id: "f-health", name: "Health Hacks"),
        .init(id: "f-recipes", name: "Recipes & Food"),
        .init(id: "f-travel", name: "Travel & Places"),
        .init(id: "f-design", name: "Design Inspo"),
        .init(id: "f-research", name: "Research"),
        .init(id: "f-must-see", name: "Must See"),
    ]
}

private extension ShareItemExtractor {
    static func fallbackTitle(for share: PendingShare) -> String {
        if let fileName = share.fileName, !fileName.isEmpty { return fileName }
        if let url = share.url, let parsed = URL(string: url), !parsed.lastPathComponent.isEmpty { return parsed.lastPathComponent }
        return "Shared item"
    }

    static func inferredType(for urlString: String) -> String {
        let value = urlString.lowercased()
        if value.contains("maps.google.") || value.contains("google.com/maps") || value.contains("goo.gl/maps") || value.contains("maps.apple.com") {
            return "place"
        }
        if value.contains("youtube.com") || value.contains("youtu.be") || value.contains("vimeo.com") || value.contains("tiktok.com") {
            return "video"
        }
        if value.contains("cnn.com") || value.contains("bbc.") || value.contains("nytimes.com") || value.contains("reuters.com") || value.contains("theverge.com") || value.contains("wired.com") || value.contains("medium.com") || value.contains("/article/") || value.contains("/news/") {
            return "article"
        }
        if value.hasSuffix(".jpg") || value.hasSuffix(".jpeg") || value.hasSuffix(".png") || value.hasSuffix(".webp") || value.hasSuffix(".gif") {
            return "image"
        }
        if value.hasSuffix(".pdf") || value.hasSuffix(".doc") || value.hasSuffix(".docx") {
            return "file"
        }
        return "link"
    }

    static func sourceLabel(from sourceBundleOrLabel: String?, sharedURL: String?) -> String {
        let seed = sourceBundleOrLabel ?? ""
        let lowered = seed.lowercased()
        if let sharedURL, let host = URL(string: sharedURL)?.host?.lowercased() {
            if host.contains("youtube") || host.contains("youtu.be") { return "YouTube" }
            if host.contains("instagram") { return "Instagram" }
            if host.contains("tiktok") { return "TikTok" }
            if host.contains("reddit") { return "Reddit" }
            if host.contains("spotify") { return "Spotify" }
            if host.contains("x.com") || host.contains("twitter.com") { return "X" }
            if host.contains("pinterest") { return "Pinterest" }
            if host.contains("google.") && sharedURL.contains("/maps") { return "Google Maps" }
            if host.contains("apple.com") && sharedURL.contains("maps") { return "Apple Maps" }
            if host.contains("cnn.com") { return "CNN" }
            if host.contains("bbc.") { return "BBC" }
            if host.contains("nytimes.com") { return "New York Times" }
            if host.contains("reuters.com") { return "Reuters" }
            if host.contains("theverge.com") { return "The Verge" }
            if host.contains("wired.com") { return "Wired" }
            if host != "" {
                let parts = host.replacingOccurrences(of: "www.", with: "").split(separator: ".")
                if let first = parts.first {
                    return first.prefix(1).uppercased() + first.dropFirst()
                }
            }
        }
        if lowered.contains("safari") { return "Safari" }
        if lowered.contains("photos") { return "Photos" }
        if lowered.contains("files") { return "Files" }
        return seed.isEmpty ? "Share Extension" : seed
    }

    static func shouldReplaceTitle(current: String, with candidate: String?) -> Bool {
        guard let candidate, !candidate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let currentLower = current.lowercased()
        return current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || currentLower.hasPrefix("http")
            || currentLower == "shared item"
            || currentLower.contains("youtube.com")
            || currentLower.contains("maps.google")
    }

    static func extractPlaceName(from url: URL) -> String? {
        let absolute = url.absoluteString.removingPercentEncoding ?? url.absoluteString
        let patterns = ["/place/", "/search/"]
        for token in patterns {
            if let range = absolute.range(of: token) {
                let value = absolute[range.upperBound...].split(separator: "/").first.map(String.init) ?? ""
                let normalized = value.replacingOccurrences(of: "+", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                if !normalized.isEmpty { return normalized }
            }
        }
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let items = components.queryItems ?? []
            for key in ["q", "query"] {
                if let value = items.first(where: { $0.name == key })?.value?.removingPercentEncoding, !value.isEmpty {
                    return value
                }
            }
        }
        return nil
    }

    static func suggestedFolderId(type: String, url: String?, title: String?, description: String?) -> String {
        let haystack = [url ?? "", title ?? "", description ?? ""].joined(separator: " ").lowercased()
        if type == "image" || type == "file" || haystack.matches("passport|insurance|card|social security|tax|lease|medical|wifi|document") {
            return "f-private-vault"
        }
        if type == "place" || haystack.matches("travel|hotel|flight|map|restaurant|cafe|museum|trip|visit|pin") {
            return "f-travel"
        }
        if haystack.matches("recipe|pasta|food|cook|kitchen|meal|restaurant|dessert") {
            return "f-recipes"
        }
        if haystack.matches("claude|chatgpt|prompt|productivity|career|business|startup|resume|workflow|automation|software") {
            return "f-growth"
        }
        if haystack.matches("alien|atlantis|sphinx|pyramid|mkultra|northwoods|cover-up|conspiracy|pentagon|ufo|government secret|rabbit hole") {
            return "f-tinfoil"
        }
        if haystack.matches("funny|meme|viral|laugh|lmao|rickroll|numa|charlie bit|keyboard cat") {
            return "f-lmao"
        }
        if haystack.matches("health|wellness|fitness|sleep|stress|mental health|nutrition|protein|hydration") {
            return "f-health"
        }
        if haystack.matches("design|ui|ux|figma|dribbble|branding|visual") {
            return "f-design"
        }
        if haystack.matches("research|paper|study|science|technical|gpt-4|attention is all you need|webb|nasa") {
            return "f-research"
        }
        if haystack.matches("mind-blowing|wild|space|discovery|crazy|mystery") {
            return "f-wtf-favorites"
        }
        return "f-must-see"
    }

    static func inferredTags(type: String, url: String?, title: String?, description: String?, source: String?) -> [String] {
        let sourceTag = (source ?? "")
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ".", with: "")
        let haystack = [url ?? "", title ?? "", description ?? ""].joined(separator: " ").lowercased()
        var tags = [type, sourceTag]
        if type == "place" { tags.append("location") }
        if haystack.contains("youtube") { tags.append("video") }
        if haystack.contains("instagram") { tags.append("post") }
        if haystack.contains("pdf") { tags.append("pdf") }
        for token in ["ai", "claude", "chatgpt", "recipe", "travel", "design", "research", "health", "funny", "meme", "conspiracy", "pentagon", "egypt", "maps", "news", "reddit", "instagram", "youtube", "career", "productivity", "science"] where haystack.contains(token) {
            tags.append(token)
        }
        tags.append(contentsOf: keywordTags(title: title, description: description, url: url, source: source))
        return dedupeTags(tags)
    }

    static func dedupeTags(_ rawTags: [String]) -> [String] {
        var seen = Set<String>()
        return rawTags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0.lowercased()).inserted }
    }

    static func fetchRemoteMetadata(for url: URL) async -> RemoteMetadata? {
        var candidates: [RemoteMetadata] = []
        if isYouTubeURL(url), let metadata = try? await fetchYouTubeMetadata(for: url) {
            candidates.append(metadata)
        }
        if let metadata = try? await fetchNoembedMetadata(for: url) {
            candidates.append(metadata)
        }
        if let metadata = try? await fetchLinkPresentationMetadata(for: url) {
            candidates.append(metadata)
        }
        if let metadata = try? await fetchHTMLMetadata(for: url) {
            candidates.append(metadata)
        }
        guard !candidates.isEmpty else { return nil }
        return mergeMetadata(candidates)
    }

    static func fetchYouTubeMetadata(for url: URL) async throws -> RemoteMetadata {
        if let metadata = try? await fetchYouTubeOEmbed(for: url) {
            if let richer = try? await fetchHTMLMetadata(for: url) {
                return RemoteMetadata(
                    title: metadata.title ?? richer.title,
                    description: richer.description ?? metadata.description,
                    imageURL: metadata.imageURL ?? richer.imageURL,
                    provider: metadata.provider ?? richer.provider ?? "YouTube",
                    tags: dedupeTags(metadata.tags + richer.tags)
                )
            }
            return RemoteMetadata(
                title: metadata.title,
                description: metadata.description,
                imageURL: metadata.imageURL,
                provider: metadata.provider ?? "YouTube",
                tags: metadata.tags
            )
        }

        if let metadata = try? await fetchNoembedMetadata(for: url) {
            if let richer = try? await fetchHTMLMetadata(for: url) {
                return RemoteMetadata(
                    title: metadata.title ?? richer.title,
                    description: richer.description ?? metadata.description,
                    imageURL: metadata.imageURL ?? richer.imageURL,
                    provider: metadata.provider ?? richer.provider ?? "YouTube",
                    tags: dedupeTags(metadata.tags + richer.tags)
                )
            }
            return RemoteMetadata(
                title: metadata.title,
                description: metadata.description,
                imageURL: metadata.imageURL,
                provider: metadata.provider ?? "YouTube",
                tags: metadata.tags
            )
        }

        return try await fetchHTMLMetadata(for: url)
    }

    static func fetchYouTubeOEmbed(for url: URL) async throws -> RemoteMetadata {
        let endpoint = "https://www.youtube.com/oembed?url=\(url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url.absoluteString)&format=json"
        let data = try await fetchJSONData(from: endpoint)
        let decoded = try JSONDecoder().decode(YouTubeOEmbedResponse.self, from: data)
        return RemoteMetadata(
            title: decoded.title,
            description: youtubeFallbackDescription(from: decoded),
            imageURL: decoded.thumbnailURL,
            provider: decoded.providerName ?? "YouTube",
            tags: ["youtube", "video"]
        )
    }

    static func fetchNoembedMetadata(for url: URL) async throws -> RemoteMetadata {
        let endpoint = "https://noembed.com/embed?url=\(url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url.absoluteString)"
        let data = try await fetchJSONData(from: endpoint)
        let decoded = try JSONDecoder().decode(NoembedResponse.self, from: data)
        return RemoteMetadata(
            title: decoded.title,
            description: youtubeFallbackDescription(from: decoded),
            imageURL: decoded.thumbnailURL,
            provider: decoded.providerName,
            tags: noembedTags(from: decoded.providerName, title: decoded.title)
        )
    }

    static func fetchJSONData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw ShareItemExtractorError.failedToLoadContent }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
            throw ShareItemExtractorError.failedToLoadContent
        }
        return data
    }

    static func fetchLinkPresentationMetadata(for url: URL) async throws -> RemoteMetadata {
        let provider = LPMetadataProvider()
        let metadata = try await provider.startFetchingMetadata(for: url)
        let title = metadata.title
        let providerName = metadata.url?.host?.replacingOccurrences(of: "www.", with: "") ?? metadata.originalURL?.host?.replacingOccurrences(of: "www.", with: "")
        var imageURL: String?
        if let remote = metadata.imageProvider {
            imageURL = try await loadRemoteImageDataURL(from: remote)
        }
        return RemoteMetadata(
            title: title,
            description: nil,
            imageURL: imageURL,
            provider: providerName?.capitalized,
            tags: []
        )
    }

    static func loadRemoteImageDataURL(from provider: NSItemProvider) async throws -> String? {
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            return try await withCheckedThrowingContinuation { continuation in
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let data else {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: "data:image/jpeg;base64,\(data.base64EncodedString())")
                }
            }
        }
        return nil
    }

    static func fetchHTMLMetadata(for url: URL) async throws -> RemoteMetadata {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode)
        else {
            throw ShareItemExtractorError.failedToLoadContent
        }
        let title = firstMetaContent(in: html, keys: ["og:title", "twitter:title", "parsely-title"]) ?? htmlTitle(in: html)
        let description = firstMetaContent(in: html, keys: ["og:description", "description", "twitter:description", "parsely-description"])
        let imageValue = firstMetaContent(in: html, keys: ["og:image", "twitter:image"])
        let imageURL = imageValue.flatMap { resolve(urlString: $0, relativeTo: url) }
        let provider = firstMetaContent(in: html, keys: ["og:site_name", "application-name"]) ?? hostDisplayName(for: url)
        let metaTags = extractMetaTags(in: html)
        return RemoteMetadata(title: title, description: description, imageURL: imageURL, provider: provider, tags: metaTags)
    }

    static func mergeMetadata(_ candidates: [RemoteMetadata]) -> RemoteMetadata {
        let bestTitle = candidates.first(where: { !($0.title ?? "").isEmpty })?.title
        let bestDescription = candidates
            .compactMap(\.description)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .max(by: { $0.count < $1.count })
        let bestImage = candidates.first(where: { !($0.imageURL ?? "").isEmpty })?.imageURL
        let bestProvider = candidates.first(where: { !($0.provider ?? "").isEmpty })?.provider
        let tags = dedupeTags(candidates.flatMap(\.tags))
        return RemoteMetadata(title: bestTitle, description: bestDescription, imageURL: bestImage, provider: bestProvider, tags: tags)
    }

    static func noembedTags(from provider: String?, title: String?) -> [String] {
        let seed = [provider ?? "", title ?? ""].joined(separator: " ").lowercased()
        var tags: [String] = []
        for token in ["youtube", "instagram", "tiktok", "reddit", "spotify", "pinterest", "video", "playlist", "post"] where seed.contains(token) {
            tags.append(token)
        }
        return dedupeTags(tags)
    }

    static func extractMetaTags(in html: String) -> [String] {
        let keys = [
            "keywords",
            "news_keywords",
            "parsely-tags",
            "article:tag",
            "og:type",
            "article:section"
        ]
        var tags: [String] = []
        for key in keys {
            if let content = firstMetaContent(in: html, keys: [key]) {
                let pieces = content
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                tags.append(contentsOf: pieces)
            }
        }
        return dedupeTags(
            tags
                .map { $0.lowercased() }
                .map { $0.replacingOccurrences(of: " ", with: "-") }
                .filter { $0.count > 1 && $0.count < 30 }
        )
    }

    static func hostDisplayName(for url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        if host.contains("cnn.com") { return "CNN" }
        if host.contains("bbc.") { return "BBC" }
        if host.contains("nytimes.com") { return "New York Times" }
        if host.contains("reuters.com") { return "Reuters" }
        if host.contains("theverge.com") { return "The Verge" }
        if host.contains("wired.com") { return "Wired" }
        let parts = host.replacingOccurrences(of: "www.", with: "").split(separator: ".")
        guard let first = parts.first else { return nil }
        return first.prefix(1).uppercased() + first.dropFirst()
    }

    static func keywordTags(title: String?, description: String?, url: String?, source: String?) -> [String] {
        let combined = [title, description, source]
            .compactMap { $0 }
            .joined(separator: " ")
        let normalized = combined
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s-]", with: " ", options: .regularExpression)
        let stopwords: Set<String> = [
            "the", "and", "with", "from", "that", "this", "into", "your", "about", "have",
            "will", "just", "they", "them", "their", "were", "what", "when", "where", "which",
            "while", "also", "than", "after", "before", "over", "under", "more", "less", "best",
            "using", "used", "want", "need", "must", "watch", "read", "save", "link", "video"
        ]

        var tags: [String] = []
        let tokens = normalized
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "-" })
            .map(String.init)

        for token in tokens where token.count >= 3 && token.count <= 24 && !stopwords.contains(token) {
            tags.append(token)
            if tags.count >= 10 { break }
        }

        if let title {
            let titleTokens = title
                .lowercased()
                .replacingOccurrences(of: "[^a-z0-9\\s-]", with: " ", options: .regularExpression)
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "-" })
                .map(String.init)
                .filter { $0.count >= 3 && $0.count <= 24 && !stopwords.contains($0) }
            for index in 0..<(max(titleTokens.count - 1, 0)) {
                let phrase = "\(titleTokens[index])-\(titleTokens[index + 1])"
                tags.append(phrase)
                if tags.count >= 14 { break }
            }
        }

        if let url, let host = URL(string: url)?.host?.lowercased() {
            if host.contains("youtube") || host.contains("youtu.be") { tags.append("youtube") }
            if host.contains("instagram") { tags.append("instagram") }
            if host.contains("reddit") { tags.append("reddit") }
            if host.contains("cnn.com") || host.contains("bbc.") || host.contains("nytimes.com") || host.contains("reuters.com") { tags.append("news") }
        }

        return dedupeTags(tags)
    }

    static func youtubeFallbackDescription(from payload: YouTubeOEmbedResponse) -> String? {
        if let author = payload.authorName, !author.isEmpty {
            return "Video from YouTube by \(author)."
        }
        return "Video from YouTube."
    }

    static func youtubeFallbackDescription(from payload: NoembedResponse) -> String? {
        if let author = payload.authorName, !author.isEmpty {
            return "Video from YouTube by \(author)."
        }
        return "Video from YouTube."
    }

    static func isYouTubeURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("youtube.com") || host.contains("youtu.be")
    }

    static func htmlTitle(in html: String) -> String? {
        guard let match = html.range(of: "(?is)<title[^>]*>(.*?)</title>", options: .regularExpression) else { return nil }
        let snippet = String(html[match])
        return snippet.replacingOccurrences(of: "(?is)</?title[^>]*>", with: "", options: .regularExpression).decodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func firstMetaContent(in html: String, keys: [String]) -> String? {
        for key in keys {
            let patterns = [
                "(?is)<meta[^>]+property=[\"']\(NSRegularExpression.escapedPattern(for: key))[\"'][^>]+content=[\"']([^\"']+)[\"'][^>]*>",
                "(?is)<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']\(NSRegularExpression.escapedPattern(for: key))[\"'][^>]*>",
                "(?is)<meta[^>]+name=[\"']\(NSRegularExpression.escapedPattern(for: key))[\"'][^>]+content=[\"']([^\"']+)[\"'][^>]*>",
                "(?is)<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+name=[\"']\(NSRegularExpression.escapedPattern(for: key))[\"'][^>]*>",
            ]
            for pattern in patterns {
                if let value = firstCapture(in: html, pattern: pattern)?.decodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                    return value
                }
            }
        }
        return nil
    }

    static func firstCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        return String(text[captureRange])
    }

    static func resolve(urlString: String, relativeTo baseURL: URL) -> String? {
        if let absolute = URL(string: urlString), absolute.scheme != nil {
            return absolute.absoluteString
        }
        return URL(string: urlString, relativeTo: baseURL)?.absoluteURL.absoluteString
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
}

private extension String {
    func matches(_ pattern: String) -> Bool {
        range(of: pattern, options: .regularExpression) != nil
    }
}

private extension NSItemProvider {
    func loadURL() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let url = item as? URL {
                    continuation.resume(returning: url)
                    return
                }

                if let data = item as? Data,
                   let string = String(data: data, encoding: .utf8),
                   let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    continuation.resume(returning: url)
                    return
                }

                if let string = item as? String,
                   let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    continuation.resume(returning: url)
                    return
                }

                continuation.resume(throwing: ShareItemExtractorError.failedToLoadContent)
            }
        }
    }

    func loadText() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let type = hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
                ? UTType.plainText.identifier
                : UTType.text.identifier

            loadItem(forTypeIdentifier: type, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let text = item as? String {
                    continuation.resume(returning: text)
                    return
                }

                if let data = item as? Data,
                   let text = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: text)
                    return
                }

                continuation.resume(throwing: ShareItemExtractorError.failedToLoadContent)
            }
        }
    }

    func copyFileRepresentation(preferredTypeIdentifier: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            loadFileRepresentation(forTypeIdentifier: preferredTypeIdentifier) { url, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let url else {
                    continuation.resume(throwing: ShareItemExtractorError.failedToLoadContent)
                    return
                }

                do {
                    let destination = try PendingShareStore.shared.copyAssetToSharedContainer(
                        from: url,
                        preferredName: url.lastPathComponent
                    )
                    continuation.resume(returning: destination)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
