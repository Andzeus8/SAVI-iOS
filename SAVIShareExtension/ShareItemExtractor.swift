import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
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
            let canonicalURLString = canonicalizedURLString(from: url.absoluteString)
            let fallbackTitle = fallbackTitleForURLString(canonicalURLString)
            let type = inferredType(for: canonicalURLString)
            return PendingShare(
                id: UUID().uuidString,
                url: canonicalURLString,
                title: itemTitle ?? fallbackTitle,
                type: type,
                thumbnail: nil,
                timestamp: timestamp,
                sourceApp: sourceLabel(from: sourceBundleID, sharedURL: canonicalURLString),
                text: itemText,
                fileName: nil,
                filePath: nil,
                mimeType: nil,
                itemDescription: itemText,
                folderId: suggestedFolderId(type: type, url: canonicalURLString, title: itemTitle ?? fallbackTitle, description: itemText),
                tags: inferredTags(type: type, url: canonicalURLString, title: itemTitle, description: itemText, source: sourceBundleID)
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
                folderId: suggestedFolderId(type: "text", url: nil, title: title, description: text, source: sourceBundleID),
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
                folderId: suggestedFolderId(type: "image", url: nil, title: itemTitle ?? copiedURL.lastPathComponent, description: itemText, fileName: copiedURL.lastPathComponent, mimeType: UTType.image.identifier, source: sourceBundleID),
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
                folderId: suggestedFolderId(type: "pdf", url: nil, title: itemTitle ?? copiedURL.lastPathComponent, description: itemText, fileName: copiedURL.lastPathComponent, mimeType: UTType.pdf.identifier, source: sourceBundleID),
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
                folderId: suggestedFolderId(type: "file", url: nil, title: itemTitle ?? copiedURL.lastPathComponent, description: itemText, fileName: copiedURL.lastPathComponent, mimeType: preferred, source: sourceBundleID),
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

        if let urlString = resolved.url {
            resolved.url = canonicalizedURLString(from: urlString)
        }

        guard let urlString = resolved.url,
              let url = URL(string: urlString),
              url.scheme?.hasPrefix("http") == true
        else {
            let classification = suggestedFolderClassification(
                type: resolved.type,
                url: resolved.url,
                title: resolved.title,
                description: resolved.itemDescription ?? resolved.text,
                fileName: resolved.fileName,
                mimeType: resolved.mimeType,
                tags: resolved.tags ?? [],
                source: resolved.sourceApp
            )
            resolved.folderId = resolved.folderId ?? classification.folderId
            if (resolved.folderSource ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                resolved.folderSource = "rules"
                resolved.folderConfidence = classification.confidence
                resolved.folderReason = classification.reason
            }
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

        let classification = suggestedFolderClassification(
            type: resolved.type,
            url: resolved.url,
            title: resolved.title,
            description: resolved.itemDescription ?? resolved.text,
            fileName: resolved.fileName,
            mimeType: resolved.mimeType,
            tags: resolved.tags ?? [],
            source: resolved.sourceApp
        )
        resolved.folderId = classification.folderId
        resolved.folderSource = "metadata"
        resolved.folderConfidence = classification.confidence
        resolved.folderReason = classification.reason
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

    static func improveWithAppleIntelligence(_ share: PendingShare) async -> PendingShare {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await improveWithFoundationModels(share)
        }
#endif
        return share
    }
}

private struct RemoteMetadata {
    let title: String?
    let description: String?
    let imageURL: String?
    let provider: String?
    let tags: [String]
}

private struct ShareIntelligenceDraft: Codable {
    var title: String?
    var folderId: String?
    var tags: [String]?
}

private enum MetadataFetchResult {
    case metadata(RemoteMetadata)
    case empty
    case timedOut
}

private struct YouTubeOEmbedResponse: Decodable {
    let title: String?
    let description: String?
    let authorName: String?
    let providerName: String?
    let thumbnailURL: String?
    let html: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case authorName = "author_name"
        case providerName = "provider_name"
        case thumbnailURL = "thumbnail_url"
        case html
        case type
    }
}

private struct NoembedResponse: Decodable {
    let title: String?
    let description: String?
    let authorName: String?
    let providerName: String?
    let thumbnailURL: String?
    let html: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case authorName = "author_name"
        case providerName = "provider_name"
        case thumbnailURL = "thumbnail_url"
        case html
        case type
    }
}

private struct GenericOEmbedResponse: Decodable {
    let title: String?
    let description: String?
    let authorName: String?
    let providerName: String?
    let thumbnailURL: String?
    let html: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case authorName = "author_name"
        case providerName = "provider_name"
        case thumbnailURL = "thumbnail_url"
        case html
        case type
    }
}

struct FolderPreset {
    let id: String
    let name: String
    let symbolName: String
    let colorHex: String?
}

extension ShareItemExtractor {
    static let defaultFolderPresets: [FolderPreset] = [
        .init(id: "f-private-vault", name: "Private Vault", symbolName: "lock.fill", colorHex: "#6C63FF"),
        .init(id: "f-paste-bin", name: "Paste Bin", symbolName: "clipboard.fill", colorHex: "#C4B5FD"),
        .init(id: "f-growth", name: "AI Hacks", symbolName: "bolt.fill", colorHex: "#FF8A3D"),
        .init(id: "f-wtf-favorites", name: "Science Stuff", symbolName: "atom", colorHex: "#5875FF"),
        .init(id: "f-tinfoil", name: "Tinfoil Hat Club", symbolName: "eye.fill", colorHex: "#6D4AFF"),
        .init(id: "f-lmao", name: "LULZ", symbolName: "theatermasks.fill", colorHex: "#FF4D6D"),
        .init(id: "f-health", name: "Health Hacks", symbolName: "heart.fill", colorHex: "#1CBF75"),
        .init(id: "f-recipes", name: "Recipes & Food", symbolName: "fork.knife", colorHex: "#FF6B57"),
        .init(id: "f-travel", name: "Places", symbolName: "mappin.and.ellipse", colorHex: "#18B7A0"),
        .init(id: "f-design", name: "Design Inspo", symbolName: "paintpalette.fill", colorHex: "#FF4DC4"),
        .init(id: "f-research", name: "Research", symbolName: "magnifyingglass", colorHex: "#7B61FF"),
        .init(id: "f-must-see", name: "Watch / Read Later", symbolName: "bookmark.fill", colorHex: "#F7C948"),
        .init(id: "f-random", name: "Random AF", symbolName: "shuffle", colorHex: "#9AA5B1"),
    ]

    static func folderPresets() -> [FolderPreset] {
        let sharedFolders = PendingShareStore.shared.loadFolders()
        guard !sharedFolders.isEmpty else { return defaultFolderPresets }

        let defaultsById = Dictionary(uniqueKeysWithValues: defaultFolderPresets.map { ($0.id, $0) })

        let normalized = sharedFolders
            .filter { $0.id != "f-all" }
            .sorted { lhs, rhs in
                if lhs.order == rhs.order {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.order < rhs.order
            }
            .map { shared in
                let fallback = defaultsById[shared.id]
                return FolderPreset(
                    id: shared.id,
                    name: shared.name,
                    symbolName: shared.symbolName ?? fallback?.symbolName ?? inferredSymbolName(for: shared.name, id: shared.id),
                    colorHex: shared.color ?? fallback?.colorHex
                )
            }

        return normalized.isEmpty ? defaultFolderPresets : normalized
    }
}

private extension ShareItemExtractor {
#if canImport(FoundationModels)
    @available(iOS 26.0, *)
    static func improveWithFoundationModels(_ share: PendingShare) async -> PendingShare {
        let model = SystemLanguageModel(useCase: .contentTagging)
        guard case .available = model.availability else {
            NSLog("[SAVIShareExtension] Apple Intelligence unavailable in share extension: %@", String(describing: model.availability))
            return share
        }

        let startedAt = Date()
        let draft = await withTaskGroup(of: ShareIntelligenceDraft?.self) { group in
            group.addTask {
                await requestShareDraft(share: share, model: model)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                return nil
            }

            while let result = await group.next() {
                group.cancelAll()
                return result
            }
            return nil
        }

        guard let draft else {
            NSLog("[SAVIShareExtension] Apple Intelligence share draft timed out in %.3fs", Date().timeIntervalSince(startedAt))
            return share
        }
        NSLog("[SAVIShareExtension] Apple Intelligence share draft returned in %.3fs", Date().timeIntervalSince(startedAt))
        return applyingIntelligenceDraft(draft, to: share)
    }

    @available(iOS 26.0, *)
    static func requestShareDraft(share: PendingShare, model: SystemLanguageModel) async -> ShareIntelligenceDraft? {
        let session = LanguageModelSession(
            model: model,
            instructions: """
            You improve SAVI share-sheet drafts. Return only compact JSON. Do not include markdown.
            JSON shape: {"title":"clear short title","folderId":"one-folder-id","tags":["tag-one","tag-two"]}.
            Keep titles specific, human-readable, and under 70 characters.
            Tags must be lowercase search tags without #.
            """
        )

        do {
            let response = try await session.respond(
                to: shareDraftPrompt(for: share),
                options: GenerationOptions(temperature: 0.0, maximumResponseTokens: 180)
            )
            return decodeShareDraft(response.content)
        } catch {
            NSLog("[SAVI Share] Apple Intelligence draft skipped: \(error.localizedDescription)")
            return nil
        }
    }
#endif

    static func fallbackTitle(for share: PendingShare) -> String {
        if let fileName = share.fileName, !fileName.isEmpty { return fileName }
        if let url = share.url { return fallbackTitleForURLString(url) }
        return "Shared item"
    }

    static func fallbackTitleForURLString(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return "Shared item" }
        if isYouTubeURL(url) { return "YouTube video" }
        if isTikTokURL(url) { return "TikTok video" }
        if isInstagramReelURL(url) { return "Instagram Reel" }
        if isInstagramURL(url) { return "Instagram Post" }
        if isTwitterXURL(url) { return "X post" }
        if isRedditURL(url) { return "Reddit post" }
        if isVimeoURL(url) { return "Vimeo video" }
        if isSpotifyURL(url) { return "Spotify save" }
        if isSoundCloudURL(url) { return "SoundCloud save" }
        if isPinterestURL(url) { return "Pinterest pin" }
        if isFacebookURL(url) { return "Facebook post" }
        if isThreadsURL(url) { return "Threads post" }
        if isBlueskyURL(url) { return "Bluesky post" }
        if isLinkedInURL(url) { return "LinkedIn save" }
        if let host = hostDisplayName(for: url), !host.isEmpty { return "\(host) save" }
        if !url.lastPathComponent.isEmpty { return url.lastPathComponent }
        return "Shared item"
    }

    static func inferredType(for urlString: String) -> String {
        let value = urlString.lowercased()
        if value.contains("maps.google.") || value.contains("google.com/maps") || value.contains("goo.gl/maps") || value.contains("maps.apple.com") {
            return "place"
        }
        if value.contains("youtube.com") || value.contains("youtu.be") || value.contains("vimeo.com") || value.contains("tiktok.com") || value.contains("instagram.com/reel/") || value.contains("facebook.com/watch") || value.contains("fb.watch") {
            return "video"
        }
        if value.contains("pinterest.") || value.contains("pin.it") {
            return "image"
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
            if host.contains("vimeo") { return "Vimeo" }
            if host.contains("spotify") { return "Spotify" }
            if host.contains("soundcloud") { return "SoundCloud" }
            if host.contains("x.com") || host.contains("twitter.com") { return "X" }
            if host.contains("pinterest") { return "Pinterest" }
            if host.contains("facebook.com") || host.contains("fb.watch") { return "Facebook" }
            if host.contains("threads.net") || host.contains("threads.com") { return "Threads" }
            if host.contains("bsky.app") || host.contains("bsky.social") { return "Bluesky" }
            if host.contains("linkedin.com") { return "LinkedIn" }
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
        let candidateLower = candidate.lowercased()
        return current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || currentLower.hasPrefix("http")
            || currentLower == "shared item"
            || currentLower == "youtube video"
            || currentLower == "youtube save"
            || currentLower == "tiktok video"
            || currentLower == "instagram reel"
            || currentLower == "instagram post"
            || currentLower == "x post"
            || currentLower == "twitter post"
            || currentLower == "reddit post"
            || currentLower == "vimeo video"
            || currentLower == "spotify save"
            || currentLower == "soundcloud save"
            || currentLower == "pinterest pin"
            || currentLower == "facebook post"
            || currentLower == "threads post"
            || currentLower == "bluesky post"
            || currentLower == "linkedin save"
            || currentLower == "reddit - please wait for verification"
            || currentLower == "watch"
            || currentLower == "share"
            || currentLower.contains("youtube.com")
            || currentLower.contains("maps.google")
            || candidateLower == "youtube"
    }

    static func applyingIntelligenceDraft(_ draft: ShareIntelligenceDraft, to share: PendingShare) -> PendingShare {
        var resolved = share

        if let title = cleanedIntelligenceTitle(draft.title),
           shouldReplaceTitle(current: resolved.title, with: title) || title.count > resolved.title.count + 8 {
            resolved.title = title
        }

        let validFolderIds = Set(folderPresets().map(\.id))
        if let folderId = draft.folderId?.trimmingCharacters(in: .whitespacesAndNewlines),
           validFolderIds.contains(folderId) {
            let input = SAVIFolderClassificationInput(
                title: resolved.title,
                description: resolved.itemDescription ?? resolved.text ?? "",
                url: resolved.url,
                type: resolved.type,
                source: resolved.sourceApp,
                fileName: resolved.fileName,
                mimeType: resolved.mimeType,
                tags: resolved.tags ?? []
            )
            let localResult = SAVIFolderClassifier.classify(
                input,
                availableFolders: folderPresets().map { SAVIFolderOption(id: $0.id, name: $0.name) },
                learningSignals: PendingShareStore.shared.loadFolderLearning()
            )
            if SAVIFolderClassifier.shouldAcceptIntelligenceFolder(folderId, localResult: localResult, input: input) {
                resolved.folderId = folderId
                resolved.folderSource = "apple-intelligence"
                resolved.folderConfidence = nil
                resolved.folderReason = "apple-intelligence"
            }
        }

        let aiTags = (draft.tags ?? [])
            .map(cleanedIntelligenceTag)
            .compactMap { $0 }
        if !aiTags.isEmpty {
            resolved.tags = Array(dedupeTags((resolved.tags ?? []) + aiTags).prefix(10))
        }

        return resolved
    }

    static func cleanedIntelligenceTitle(_ value: String?) -> String? {
        guard let value else { return nil }
        let cleaned = value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count >= 3, cleaned.count <= 90 else { return nil }
        let lowered = cleaned.lowercased()
        if ["untitled", "shared item", "new save", "link", "file"].contains(lowered) { return nil }
        return cleaned
    }

    static func cleanedIntelligenceTag(_ value: String) -> String? {
        let cleaned = value
            .lowercased()
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "[^a-z0-9\\s_-]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-_ ").union(.whitespacesAndNewlines))
        guard cleaned.count >= 2, cleaned.count <= 32 else { return nil }
        return cleaned
    }

    static func shareDraftPrompt(for share: PendingShare) -> String {
        let presets = folderPresets()
        let folderOptions = presets.map { SAVIFolderOption(id: $0.id, name: $0.name) }
        let folderChoices = presets
            .map { "\($0.id): \($0.name)" }
            .joined(separator: "\n")
        let description = String((share.itemDescription ?? share.text ?? "").prefix(1_200))
        let url = String((share.url ?? "").prefix(500))
        let fileName = share.fileName ?? ""
        let mimeType = share.mimeType ?? ""
        let tags = (share.tags ?? []).prefix(8).joined(separator: ", ")
        let learningExamples = SAVIFolderClassifier.learningExamples(
            from: PendingShareStore.shared.loadFolderLearning(),
            availableFolders: folderOptions,
            limit: 8
        )
        let learningBlock = learningExamples.isEmpty ? "" : """

        Local user correction examples:
        \(learningExamples.map { "- \($0)" }.joined(separator: "\n"))

        Prefer these local examples when the current share clearly matches them.
        """

        return """
        Improve this SAVI save draft. Choose a better title only if the current one is generic, a filename, or a raw URL.

        Folder choices:
        \(folderChoices)
        \(learningBlock)

        Draft:
        current title: \(share.title)
        description/text: \(description)
        url: \(url)
        source: \(share.sourceApp)
        type: \(share.type)
        filename: \(fileName)
        mime type: \(mimeType)
        existing tags: \(tags)

        Use exactly one folderId from the choices. For private documents, IDs, receipts, medical, insurance, banking, credentials, or tax files, choose f-private-vault.
        Entertainment, trailers, news, and fandom posts are not private just because their title says secret, leaked, vault, or password.
        Return only JSON.
        """
    }

    static func decodeShareDraft(_ text: String) -> ShareIntelligenceDraft? {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let candidates = [cleaned, extractJSONObject(from: cleaned)].compactMap { $0 }
        for candidate in candidates {
            guard let data = candidate.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(ShareIntelligenceDraft.self, from: data)
            else { continue }
            if cleanedIntelligenceTitle(decoded.title) != nil ||
                decoded.folderId?.isEmpty == false ||
                !(decoded.tags ?? []).isEmpty {
                return decoded
            }
        }
        return nil
    }

    static func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start <= end else { return nil }
        return String(text[start...end])
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

    static func suggestedFolderId(
        type: String,
        url: String?,
        title: String?,
        description: String?,
        fileName: String? = nil,
        mimeType: String? = nil,
        tags: [String] = [],
        source: String? = nil
    ) -> String {
        suggestedFolderClassification(
            type: type,
            url: url,
            title: title,
            description: description,
            fileName: fileName,
            mimeType: mimeType,
            tags: tags,
            source: source
        ).folderId
    }

    static func suggestedFolderClassification(
        type: String,
        url: String?,
        title: String?,
        description: String?,
        fileName: String? = nil,
        mimeType: String? = nil,
        tags: [String] = [],
        source: String? = nil
    ) -> SAVIFolderClassification {
        let options = folderPresets().map { SAVIFolderOption(id: $0.id, name: $0.name) }
        let input = SAVIFolderClassificationInput(
            title: title ?? "",
            description: description ?? "",
            url: url,
            type: type,
            source: source ?? "",
            fileName: fileName,
            mimeType: mimeType,
            tags: tags
        )
        let result = SAVIFolderClassifier.classify(
            input,
            availableFolders: options,
            learningSignals: PendingShareStore.shared.loadFolderLearning()
        )
        recordFolderDecision(input: input, result: result, options: options, context: "Share Extension")
        return result
    }

    static func recordFolderDecision(
        input: SAVIFolderClassificationInput,
        result: SAVIFolderClassification,
        options: [SAVIFolderOption],
        context: String
    ) {
        let rawTitle = input.title.nilIfBlank ??
            input.fileName?.nilIfBlank ??
            input.url?.nilIfBlank ??
            input.description.nilIfBlank ??
            "Untitled share"
        let safeTitle = (SAVIFolderClassifier.isSensitive(input) || SAVIFolderClassifier.looksPrivateDocument(input)) ?
            "Private item" :
            String(rawTitle.prefix(90))
        let folderName = options.first(where: { $0.id == result.folderId })?.name ??
            SAVIFolderClassifier.defaultFolderOptions.first(where: { $0.id == result.folderId })?.name ??
            "Unknown folder"
        let record = SAVIFolderDecisionRecord(
            id: UUID().uuidString,
            title: safeTitle,
            folderId: result.folderId,
            folderName: folderName,
            confidence: result.confidence,
            reason: result.reason,
            context: context,
            createdAt: Date().timeIntervalSince1970
        )
        PendingShareStore.shared.saveFolderDecision(record)
    }

    static func inferredTags(type: String, url: String?, title: String?, description: String?, source: String?) -> [String] {
        let sourceTag = (source ?? "")
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ".", with: "")
        let haystack = [url ?? "", title ?? "", description ?? "", source ?? ""].joined(separator: " ").lowercased()
        var tags: [String] = []
        tags.append(contentsOf: keywordTags(title: title, description: description, url: url, source: source))
        tags.append(contentsOf: topicalTags(from: haystack))
        if type != "link" && type != "text" {
            tags.append(type)
        }
        if ["pdf", "file"].contains(type) { tags.append("document") }
        if type == "text" { tags.append("note") }
        if !sourceTag.isEmpty, sourceTag != "share-extension" {
            tags.append(sourceTag)
        }
        if type == "place" { tags += ["location", "place"] }
        if haystack.contains("youtube") || haystack.contains("youtu.be") { tags += ["youtube", "video"] }
        if haystack.contains("instagram") {
            tags.append("instagram")
            tags.append("post")
            if haystack.contains("/reel/") { tags += ["reel", "video"] }
        }
        if haystack.contains("tiktok") { tags += ["tiktok", "video"] }
        if haystack.contains("twitter.com") || haystack.contains("x.com/") { tags += ["x", "twitter", "post"] }
        if haystack.contains("reddit") { tags += ["reddit", "post"] }
        if haystack.contains("vimeo") { tags += ["vimeo", "video"] }
        if haystack.contains("spotify") { tags += ["spotify", "music"] }
        if haystack.contains("soundcloud") { tags += ["soundcloud", "music"] }
        if haystack.contains("pinterest") || haystack.contains("pin.it") { tags += ["pinterest", "image"] }
        if haystack.contains("facebook") || haystack.contains("fb.watch") { tags += ["facebook", "post"] }
        if haystack.contains("threads.net") || haystack.contains("threads.com") { tags += ["threads", "post"] }
        if haystack.contains("bsky.app") || haystack.contains("bluesky") { tags += ["bluesky", "post"] }
        if haystack.contains("linkedin") { tags += ["linkedin", "post"] }
        if haystack.contains("pdf") || haystack.range(of: #"\.pdf(\?|$|\s)"#, options: .regularExpression) != nil { tags += ["pdf", "document"] }
        if haystack.contains("screenshot") || haystack.contains("screen shot") { tags += ["screenshot", "image"] }
        if haystack.contains("prompt") { tags.append("prompt") }
        if haystack.contains("todo") || haystack.contains("checklist") { tags.append("checklist") }
        return dedupeTags(tags)
    }

    static func dedupeTags(_ rawTags: [String]) -> [String] {
        var seen = Set<String>()
        return rawTags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0.lowercased()).inserted }
    }

    static func inferredSymbolName(for name: String, id: String) -> String {
        let key = "\(id) \(name)".lowercased()
        if key.contains("vault") || key.contains("private") || key.contains("passport") || key.contains("insurance") { return "lock.fill" }
        if key.contains("growth") || key.contains("career") || key.contains("business") || key.contains("productivity") || key.contains("ai hack") { return "bolt.fill" }
        if key.contains("wtf") || key.contains("wild") || key.contains("favorite") || key.contains("crazy") || key.contains("science stuff") { return "atom" }
        if key.contains("tinfoil") || key.contains("conspiracy") || key.contains("alien") { return "eye.fill" }
        if key.contains("lmao") || key.contains("lulz") || key.contains("meme") || key.contains("funny") || key.contains("lol") { return "theatermasks.fill" }
        if key.contains("health") || key.contains("fitness") || key.contains("wellness") { return "heart.fill" }
        if key.contains("recipe") || key.contains("food") || key.contains("cook") { return "fork.knife" }
        if key.contains("travel") || key.contains("place") || key.contains("map") || key.contains("trip") || key.contains("gps") { return "mappin.and.ellipse" }
        if key.contains("design") || key.contains("inspo") || key.contains("brand") || key.contains("ui") || key.contains("ux") { return "paintpalette.fill" }
        if key.contains("research") || key.contains("study") || key.contains("paper") { return "magnifyingglass" }
        if key.contains("must") || key.contains("later") || key.contains("watch") || key.contains("read") { return "bookmark.fill" }
        if key.contains("random") || key.contains("misc") { return "shuffle" }
        return "folder"
    }

    static func score(folderName: String, haystack: String) -> Int {
        let tokens = folderName
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s-]", with: " ", options: .regularExpression)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "-" })
            .map(String.init)
            .filter { $0.count > 2 }
        return tokens.reduce(0) { partial, token in
            partial + (haystack.contains(token) ? max(1, token.count - 2) : 0)
        }
    }

    static func folderScore(keywords: [String], title: String, description: String, url: String) -> Int {
        var score = 0
        for keyword in keywords {
            let normalized = keyword.lowercased()
            if title.contains(normalized) { score += normalized.count >= 8 ? 8 : 6 }
            if description.contains(normalized) { score += normalized.count >= 8 ? 5 : 3 }
            if url.contains(normalized) { score += 2 }
        }
        return score
    }

    static func fetchRemoteMetadata(for url: URL) async -> RemoteMetadata? {
        let startedAt = Date()
        return await withTaskGroup(of: MetadataFetchResult.self) { group in
            if isYouTubeURL(url) {
                group.addTask {
                    guard let metadata = try? await fetchYouTubeMetadata(for: url) else { return .empty }
                    return .metadata(metadata)
                }
            }

            group.addTask {
                guard let metadata = try? await fetchProviderSpecificMetadata(for: url) else { return .empty }
                return .metadata(metadata)
            }
            group.addTask {
                guard let metadata = try? await fetchNoembedMetadata(for: url) else { return .empty }
                return .metadata(metadata)
            }
            group.addTask {
                guard let metadata = try? await fetchHTMLMetadata(for: url) else { return .empty }
                return .metadata(metadata)
            }
            group.addTask {
                guard let metadata = try? await fetchLinkPresentationMetadata(for: url) else { return .empty }
                return .metadata(metadata)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                return .timedOut
            }

            var candidates: [RemoteMetadata] = []
            while let result = await group.next() {
                switch result {
                case .metadata(let metadata):
                    candidates.append(metadata)
                    if metadataLooksComplete(metadata) {
                        group.cancelAll()
                        NSLog("[SAVIShareExtension] metadata ready in %.2fs for %@", Date().timeIntervalSince(startedAt), url.absoluteString)
                        return mergeMetadata(candidates)
                    }
                case .empty:
                    continue
                case .timedOut:
                    group.cancelAll()
                    NSLog("[SAVIShareExtension] metadata timed out after %.2fs for %@", Date().timeIntervalSince(startedAt), url.absoluteString)
                    return candidates.isEmpty ? nil : mergeMetadata(candidates)
                }
            }

            guard !candidates.isEmpty else { return nil }
            NSLog("[SAVIShareExtension] metadata finished in %.2fs for %@", Date().timeIntervalSince(startedAt), url.absoluteString)
            return mergeMetadata(candidates)
        }
    }

    static func metadataLooksComplete(_ metadata: RemoteMetadata) -> Bool {
        guard let title = metadata.title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty,
              titleQualityScore(title) > 0
        else {
            return false
        }
        let normalizedTitle = title.lowercased()
        let provider = metadata.provider?.lowercased() ?? ""
        if provider.contains("instagram"),
           metadata.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false,
           ["instagram reel", "instagram post"].contains(normalizedTitle) {
            return false
        }
        return metadata.description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            || metadata.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            || metadata.provider?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    static func fetchYouTubeMetadata(for url: URL) async throws -> RemoteMetadata {
        let canonicalURL = canonicalYouTubeURL(from: url)

        if let metadata = try? await fetchNoembedMetadata(for: canonicalURL) {
            return RemoteMetadata(
                title: metadata.title,
                description: metadata.description,
                imageURL: metadata.imageURL ?? youtubeThumbnailURL(for: canonicalURL),
                provider: metadata.provider ?? "YouTube",
                tags: metadata.tags
            )
        }

        if let metadata = try? await fetchYouTubeOEmbed(for: canonicalURL) {
            return RemoteMetadata(
                title: metadata.title,
                description: metadata.description,
                imageURL: metadata.imageURL ?? youtubeThumbnailURL(for: canonicalURL),
                provider: metadata.provider ?? "YouTube",
                tags: metadata.tags
            )
        }
        if var htmlMetadata = try? await fetchHTMLMetadata(for: canonicalURL) {
            htmlMetadata = RemoteMetadata(
                title: htmlMetadata.title,
                description: htmlMetadata.description,
                imageURL: htmlMetadata.imageURL ?? youtubeThumbnailURL(for: canonicalURL),
                provider: htmlMetadata.provider ?? "YouTube",
                tags: dedupeTags(htmlMetadata.tags + ["youtube", "video"])
            )
            return htmlMetadata
        }
        return RemoteMetadata(
            title: nil,
            description: "Video from YouTube.",
            imageURL: youtubeThumbnailURL(for: canonicalURL),
            provider: "YouTube",
            tags: ["youtube", "video"]
        )
    }

    static func fetchYouTubeOEmbed(for url: URL) async throws -> RemoteMetadata {
        let endpoint = try oEmbedEndpoint(
            base: "https://www.youtube.com/oembed",
            url: url,
            extraItems: [URLQueryItem(name: "format", value: "json")]
        )
        let data = try await fetchJSONData(from: endpoint)
        let decoded = try JSONDecoder().decode(YouTubeOEmbedResponse.self, from: data)
        return RemoteMetadata(
            title: cleanedFetchedTitle(decoded.title, for: url),
            description: youtubeFallbackDescription(from: decoded),
            imageURL: decoded.thumbnailURL,
            provider: decoded.providerName ?? "YouTube",
            tags: ["youtube", "video"]
        )
    }

    static func fetchProviderSpecificMetadata(for url: URL) async throws -> RemoteMetadata? {
        if isTikTokURL(url) {
            return try await fetchGenericOEmbedMetadata(
                endpoint: try oEmbedEndpoint(base: "https://www.tiktok.com/oembed", url: url),
                for: url,
                defaultProvider: "TikTok",
                tags: ["tiktok", "video"]
            )
        }
        if isInstagramURL(url) {
            return RemoteMetadata(
                title: isInstagramReelURL(url) ? "Instagram Reel" : "Instagram Post",
                description: "Shared from Instagram.",
                imageURL: nil,
                provider: "Instagram",
                tags: isInstagramReelURL(url) ? ["instagram", "reel", "video"] : ["instagram", "post"]
            )
        }
        if isTwitterXURL(url) {
            return try await fetchGenericOEmbedMetadata(
                endpoint: try oEmbedEndpoint(
                    base: "https://publish.twitter.com/oembed",
                    url: url,
                    extraItems: [URLQueryItem(name: "omit_script", value: "true")]
                ),
                for: url,
                defaultProvider: "X",
                tags: ["x", "twitter", "post"]
            )
        }
        if isRedditURL(url) {
            return try await fetchGenericOEmbedMetadata(
                endpoint: try oEmbedEndpoint(base: "https://www.reddit.com/oembed", url: url),
                for: url,
                defaultProvider: "Reddit",
                tags: ["reddit", "post"]
            )
        }
        if isVimeoURL(url) {
            return try await fetchGenericOEmbedMetadata(
                endpoint: try oEmbedEndpoint(base: "https://vimeo.com/api/oembed.json", url: url),
                for: url,
                defaultProvider: "Vimeo",
                tags: ["vimeo", "video"]
            )
        }
        if isSpotifyURL(url) {
            return try await fetchGenericOEmbedMetadata(
                endpoint: try oEmbedEndpoint(base: "https://open.spotify.com/oembed", url: url),
                for: url,
                defaultProvider: "Spotify",
                tags: ["spotify", "music"]
            )
        }
        if isSoundCloudURL(url) {
            return try await fetchGenericOEmbedMetadata(
                endpoint: try oEmbedEndpoint(
                    base: "https://soundcloud.com/oembed",
                    url: url,
                    extraItems: [URLQueryItem(name: "format", value: "json")]
                ),
                for: url,
                defaultProvider: "SoundCloud",
                tags: ["soundcloud", "music"]
            )
        }
        if isPinterestURL(url) {
            return try await fetchGenericOEmbedMetadata(
                endpoint: try oEmbedEndpoint(base: "https://www.pinterest.com/oembed.json", url: url),
                for: url,
                defaultProvider: "Pinterest",
                tags: ["pinterest", "image", "inspiration"]
            )
        }
        if isBlueskyURL(url) {
            return try await fetchGenericOEmbedMetadata(
                endpoint: try oEmbedEndpoint(base: "https://embed.bsky.app/oembed", url: url),
                for: url,
                defaultProvider: "Bluesky",
                tags: ["bluesky", "post"]
            )
        }
        return nil
    }

    static func fetchGenericOEmbedMetadata(endpoint: String, for url: URL, defaultProvider: String, tags: [String]) async throws -> RemoteMetadata {
        let data = try await fetchJSONData(from: endpoint)
        let decoded = try JSONDecoder().decode(GenericOEmbedResponse.self, from: data)
        let provider = providerDisplayName(decoded.providerName, fallback: defaultProvider)
        let embeddedText = oEmbedPrimaryText(from: decoded.html)
        let title = cleanedFetchedTitle(decoded.title, for: url) ?? cleanedFetchedTitle(embeddedText, for: url)
        let description = cleanedMetadataDescription(decoded.description) ??
            providerFallbackDescription(provider: provider, author: decoded.authorName, url: url) ??
            (title == nil ? embeddedText : nil)
        return RemoteMetadata(
            title: title,
            description: description,
            imageURL: decoded.thumbnailURL,
            provider: provider,
            tags: tags
        )
    }

    static func fetchNoembedMetadata(for url: URL) async throws -> RemoteMetadata {
        let endpoint = try oEmbedEndpoint(base: "https://noembed.com/embed", url: url)
        let data = try await fetchJSONData(from: endpoint)
        let decoded = try JSONDecoder().decode(NoembedResponse.self, from: data)
        let embeddedText = oEmbedPrimaryText(from: decoded.html)
        return RemoteMetadata(
            title: cleanedFetchedTitle(decoded.title, for: url) ?? cleanedFetchedTitle(embeddedText, for: url),
            description: cleanedMetadataDescription(decoded.description) ??
                providerFallbackDescription(provider: decoded.providerName, author: decoded.authorName, url: url) ??
                embeddedText,
            imageURL: decoded.thumbnailURL,
            provider: decoded.providerName.map { providerDisplayName($0, fallback: $0) },
            tags: dedupeTags(noembedTags(from: decoded.providerName, title: decoded.title))
        )
    }

    static func oEmbedEndpoint(base: String, url: URL, extraItems: [URLQueryItem] = []) throws -> String {
        guard var components = URLComponents(string: base) else {
            throw ShareItemExtractorError.failedToLoadContent
        }
        components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)] + extraItems
        guard let endpoint = components.url?.absoluteString else {
            throw ShareItemExtractorError.failedToLoadContent
        }
        return endpoint
    }

    static func fetchJSONData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw ShareItemExtractorError.failedToLoadContent }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
            throw ShareItemExtractorError.failedToLoadContent
        }
        return data
    }

    static func fetchLinkPresentationMetadata(for url: URL) async throws -> RemoteMetadata {
        let provider = LPMetadataProvider()
        return try await withTaskCancellationHandler {
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
        } onCancel: {
            provider.cancel()
        }
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
        request.timeoutInterval = 2
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode)
        else {
            throw ShareItemExtractorError.failedToLoadContent
        }
        let title = cleanedFetchedTitle(
            firstMetaContent(in: html, keys: ["og:title", "twitter:title", "parsely-title", "title"]) ?? htmlTitle(in: html),
            for: url
        )
        let rawTitle = firstMetaContent(in: html, keys: ["og:title", "twitter:title", "parsely-title", "title"]) ?? htmlTitle(in: html)
        let description = cleanedMetadataDescription(firstMetaContent(in: html, keys: ["og:description", "description", "twitter:description", "parsely-description"])) ??
            instagramCaption(from: rawTitle, for: url)
        let imageValue = firstMetaContent(in: html, keys: ["og:image", "twitter:image"])
        let imageURL = imageValue.flatMap { resolve(urlString: $0, relativeTo: url) }
        let provider = firstMetaContent(in: html, keys: ["og:site_name", "application-name"]) ?? hostDisplayName(for: url)
        let metaTags = extractMetaTags(in: html)
        return RemoteMetadata(title: title, description: description, imageURL: imageURL, provider: provider, tags: metaTags)
    }

    static func mergeMetadata(_ candidates: [RemoteMetadata]) -> RemoteMetadata {
        let bestTitle = candidates
            .compactMap(\.title)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .max { lhs, rhs in titleQualityScore(lhs) < titleQualityScore(rhs) }
        let bestDescription = candidates
            .compactMap(\.description)
            .compactMap(cleanedMetadataDescription)
            .max(by: { $0.count < $1.count })
        let bestImage = candidates.first(where: { !($0.imageURL ?? "").isEmpty })?.imageURL
        let bestProvider = candidates.first(where: { !($0.provider ?? "").isEmpty })?.provider
        let tags = dedupeTags(candidates.flatMap(\.tags))
        return RemoteMetadata(title: bestTitle, description: bestDescription, imageURL: bestImage, provider: bestProvider, tags: tags)
    }

    static func titleQualityScore(_ title: String) -> Int {
        let normalized = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if isGenericFetchedTitle(normalized) { return 0 }
        var score = min(title.count, 80)
        if normalized.contains(" on instagram:") { score += 30 }
        if normalized.contains("instagram reel") || normalized.contains("instagram post") { score += 8 }
        if normalized.contains("#") { score += 6 }
        return score
    }

    static func cleanedFetchedTitle(_ value: String?, for url: URL) -> String? {
        guard var title = value?.decodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty
        else { return nil }

        if isYouTubeURL(url) {
            title = title
                .replacingOccurrences(of: #"(?i)\s*-\s*youtube$"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"(?i)^watch\s*-\s*"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if isGenericFetchedTitle(title) {
            return nil
        }

        return title
    }

    static func providerDisplayName(_ value: String?, fallback: String) -> String {
        let trimmed = value?.decodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? fallback
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
        guard let value = value?.nilIfEmpty else { return nil }
        let cleaned = value
            .replacingOccurrences(of: #"(?is)<script[^>]*>.*?</script>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"(?is)<style[^>]*>.*?</style>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"(?is)<[^>]+>"#, with: " ", options: .regularExpression)
            .decodedHTMLString
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.nilIfEmpty
    }

    static func oEmbedPrimaryText(from html: String?) -> String? {
        guard let html = html?.nilIfEmpty else { return nil }
        let paragraph = firstCapture(in: html, pattern: #"(?is)<p[^>]*>(.*?)</p>"#) ?? html
        let cleaned = paragraph
            .replacingOccurrences(of: #"(?is)<script[^>]*>.*?</script>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"(?is)<style[^>]*>.*?</style>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"(?is)<[^>]+>"#, with: " ", options: .regularExpression)
            .decodedHTMLString
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.nilIfEmpty
    }

    static func instagramCaption(from value: String?, for url: URL) -> String? {
        guard isInstagramURL(url),
              let value = value?.decodedHTMLString.trimmingCharacters(in: .whitespacesAndNewlines),
              let range = value.range(of: #"(?i)\bon instagram:\s*["“](.+?)["”]\s*$"#, options: .regularExpression)
        else { return nil }
        let matched = String(value[range])
        guard let quoteRange = matched.range(of: #"["“](.+?)["”]"#, options: .regularExpression) else { return nil }
        return String(matched[quoteRange])
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty
    }

    static func isGenericFetchedTitle(_ value: String) -> Bool {
        let normalized = value
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return [
            "youtube",
            "watch",
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
        ].contains(normalized)
    }

    static func noembedTags(from provider: String?, title: String?) -> [String] {
        let seed = [provider ?? "", title ?? ""].joined(separator: " ").lowercased()
        var tags: [String] = []
        for token in ["youtube", "instagram", "tiktok", "reddit", "spotify", "pinterest", "vimeo", "soundcloud", "bluesky", "video", "playlist", "post"] where seed.contains(token) {
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

    static func canonicalizedURLString(from value: String) -> String {
        guard let url = URL(string: value) else { return value }
        if isYouTubeURL(url) {
            return canonicalYouTubeURL(from: url).absoluteString
        }
        return url.absoluteString
    }

    static func canonicalYouTubeURL(from url: URL) -> URL {
        guard let videoID = extractYouTubeVideoID(from: url) else { return url }
        return URL(string: "https://www.youtube.com/watch?v=\(videoID)") ?? url
    }

    static func extractYouTubeVideoID(from url: URL) -> String? {
        let host = url.host?.lowercased() ?? ""
        if host.contains("youtu.be") {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return id.nilIfEmpty
        }
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if let value = components.queryItems?.first(where: { $0.name == "v" })?.value, !value.isEmpty {
                return value
            }
        }
        let path = url.path.lowercased()
        if path.contains("/shorts/") || path.contains("/embed/") {
            let parts = url.path.split(separator: "/")
            if let last = parts.last, !last.isEmpty {
                return String(last)
            }
        }
        return nil
    }

    static func youtubeThumbnailURL(for url: URL) -> String? {
        guard let id = extractYouTubeVideoID(from: url) else { return nil }
        return "https://img.youtube.com/vi/\(id)/hqdefault.jpg"
    }

    static func slugTag(from value: String?) -> String {
        guard let value else { return "" }
        return value
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s-]", with: " ", options: .regularExpression)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "-" })
            .prefix(2)
            .map(String.init)
            .joined(separator: "-")
    }

    static func keywordTags(title: String?, description: String?, url: String?, source: String?) -> [String] {
        let titleNormalized = (title ?? "")
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s-]", with: " ", options: .regularExpression)
        let descriptionNormalized = (description ?? "")
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s-]", with: " ", options: .regularExpression)
        let sourceNormalized = (source ?? "")
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s-]", with: " ", options: .regularExpression)
        let stopwords: Set<String> = [
            "the", "and", "with", "from", "that", "this", "into", "your", "about", "have",
            "will", "just", "they", "them", "their", "were", "what", "when", "where", "which",
            "while", "also", "than", "after", "before", "over", "under", "more", "less", "best",
            "using", "used", "want", "need", "must", "watch", "read", "save", "link", "video",
            "things", "thing", "know", "should", "extension", "share"
        ]

        var tags: [String] = []
        let titleTokens = titleNormalized
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "-" })
            .map(String.init)
            .filter { $0.count >= 3 && $0.count <= 24 && !stopwords.contains($0) }
        let descriptionTokens = descriptionNormalized
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "-" })
            .map(String.init)
            .filter { $0.count >= 3 && $0.count <= 24 && !stopwords.contains($0) }
        let sourceTokens = sourceNormalized
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "-" })
            .map(String.init)
            .filter { $0.count >= 3 && $0.count <= 24 && !stopwords.contains($0) }

        for token in titleTokens {
            tags.append(token)
            if token.hasSuffix("s"), token.count > 4 {
                tags.append(String(token.dropLast()))
            }
            if tags.count >= 8 { break }
        }

        if !titleTokens.isEmpty {
            for index in 0..<(max(titleTokens.count - 1, 0)) {
                let phrase = "\(titleTokens[index])-\(titleTokens[index + 1])"
                tags.append(phrase)
                if tags.count >= 12 { break }
            }
        }

        for token in descriptionTokens {
            tags.append(token)
            if token.hasSuffix("s"), token.count > 4 {
                tags.append(String(token.dropLast()))
            }
            if tags.count >= 16 { break }
        }

        for token in sourceTokens where !["share", "extension", "camera", "photo", "photos", "safari"].contains(token) {
            tags.append(token)
        }

        if let url, let host = URL(string: url)?.host?.lowercased() {
            if host.contains("youtube") || host.contains("youtu.be") { tags.append("youtube") }
            if host.contains("instagram") { tags.append("instagram") }
            if host.contains("tiktok") { tags.append("tiktok") }
            if host.contains("x.com") || host.contains("twitter.com") { tags.append("x") }
            if host.contains("reddit") { tags.append("reddit") }
            if host.contains("vimeo") { tags.append("vimeo") }
            if host.contains("spotify") { tags.append("spotify") }
            if host.contains("soundcloud") { tags.append("soundcloud") }
            if host.contains("pinterest") || host.contains("pin.it") { tags.append("pinterest") }
            if host.contains("facebook.com") || host.contains("fb.watch") { tags.append("facebook") }
            if host.contains("threads.net") || host.contains("threads.com") { tags.append("threads") }
            if host.contains("bsky.app") || host.contains("bsky.social") { tags.append("bluesky") }
            if host.contains("linkedin") { tags.append("linkedin") }
            if host.contains("cnn.com") || host.contains("bbc.") || host.contains("nytimes.com") || host.contains("reuters.com") { tags.append("news") }
        }

        return dedupeTags(tags)
    }

    static func topicalTags(from haystack: String) -> [String] {
        let groups: [(String, [String])] = [
            ("health", ["parasite", "parasites", "infection", "disease", "doctor", "medical", "symptom", "symptoms", "body", "gut", "wellness"]),
            ("travel", ["travel", "trip", "hotel", "vacation", "destination", "flight", "beach", "city"]),
            ("food", ["recipe", "food", "cook", "meal", "dessert", "restaurant"]),
            ("science", ["science", "research", "study", "nasa", "space", "discovery"]),
            ("design", ["design", "ui", "ux", "figma", "branding"]),
            ("conspiracy", ["conspiracy", "ufo", "pentagon", "mkultra", "atlantis", "pyramid"]),
            ("funny", ["funny", "meme", "viral", "comedy", "laugh"]),
            ("productivity", ["productivity", "automation", "workflow", "career", "business", "ai", "claude", "chatgpt"])
        ]

        var tags: [String] = []
        for (tag, keywords) in groups {
            if keywords.contains(where: { haystack.contains($0) }) {
                tags.append(tag)
            }
        }
        if haystack.contains("parasite") || haystack.contains("parasites") {
            tags.append("parasite")
        }
        if haystack.contains("worm") || haystack.contains("worms") {
            tags.append("worms")
        }
        return tags
    }

    static func youtubeFallbackDescription(from payload: YouTubeOEmbedResponse) -> String? {
        if let author = payload.authorName, !author.isEmpty {
            return "Video from YouTube by \(author)."
        }
        return "Video from YouTube."
    }

    static func providerFallbackDescription(provider: String?, author: String?, url: URL) -> String? {
        let label = (provider?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty)
            ?? sourceLabel(from: nil, sharedURL: url.absoluteString)
        guard !label.isEmpty else { return nil }
        if let author, !author.isEmpty {
            return "Shared from \(label) by \(author)."
        }
        return "Shared from \(label)."
    }

    static func isYouTubeURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("youtube.com") || host.contains("youtu.be")
    }

    static func isTikTokURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("tiktok.com")
    }

    static func isInstagramURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("instagram.com")
    }

    static func isInstagramReelURL(_ url: URL) -> Bool {
        isInstagramURL(url) && url.path.lowercased().contains("/reel/")
    }

    static func isTwitterXURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("x.com") || host.contains("twitter.com")
    }

    static func isRedditURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("reddit.com") || host.contains("redd.it")
    }

    static func isVimeoURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("vimeo.com")
    }

    static func isSpotifyURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("spotify.com") || host.contains("spotify.link")
    }

    static func isSoundCloudURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("soundcloud.com")
    }

    static func isPinterestURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("pinterest.") || host.contains("pin.it")
    }

    static func isFacebookURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("facebook.com") || host == "fb.watch" || host.hasSuffix(".fb.watch")
    }

    static func isThreadsURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("threads.net") || host.contains("threads.com")
    }

    static func isBlueskyURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("bsky.app") || host.contains("bsky.social")
    }

    static func isLinkedInURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        return host.contains("linkedin.com")
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

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
