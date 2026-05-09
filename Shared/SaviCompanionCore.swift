import Foundation

enum SaviCompanionItemKind: String, Codable, CaseIterable, Identifiable {
    case link
    case article
    case video
    case note
    case image
    case file
    case audio
    case place

    var id: String { rawValue }

    var title: String {
        switch self {
        case .link: return "Link"
        case .article: return "Article"
        case .video: return "Video"
        case .note: return "Note"
        case .image: return "Image"
        case .file: return "File"
        case .audio: return "Audio"
        case .place: return "Place"
        }
    }

    var symbolName: String {
        switch self {
        case .link: return "link"
        case .article: return "doc.text"
        case .video: return "play.rectangle"
        case .note: return "note.text"
        case .image: return "photo"
        case .file: return "doc"
        case .audio: return "waveform"
        case .place: return "mappin.and.ellipse"
        }
    }
}

struct SaviCompanionFolder: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var colorHex: String
    var symbolName: String
    var isPrivate: Bool
    var order: Int
}

struct SaviCompanionItem: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var summary: String
    var url: URL?
    var source: String
    var kind: SaviCompanionItemKind
    var folderId: String
    var tags: [String]
    var savedAt: Date
    var isPrivate: Bool
    var isPublic: Bool

    var searchableText: String {
        ([title, summary, source, kind.title] + tags + [url?.host() ?? ""])
            .joined(separator: " ")
            .lowercased()
    }
}

struct SaviCompanionLibrary: Codable, Equatable {
    var folders: [SaviCompanionFolder]
    var items: [SaviCompanionItem]

    var visibleFolders: [SaviCompanionFolder] {
        folders.sorted { lhs, rhs in
            if lhs.order == rhs.order { return lhs.name < rhs.name }
            return lhs.order < rhs.order
        }
    }

    func folder(for id: String) -> SaviCompanionFolder? {
        folders.first { $0.id == id }
    }

    func visibleItems(folderId: String? = nil, query: String = "", includePrivate: Bool = false) -> [SaviCompanionItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return items
            .filter { includePrivate || !$0.isPrivate }
            .filter { item in
                guard let folderId else { return true }
                return item.folderId == folderId
            }
            .filter { item in
                trimmedQuery.isEmpty || item.searchableText.contains(trimmedQuery)
            }
            .sorted { $0.savedAt > $1.savedAt }
    }
}

enum SaviCompanionBackendMode: String, Codable {
    case disabled
    case configured
}

struct SaviCompanionBackendConfig: Equatable {
    var supabaseURL: String
    var supabaseAnonKey: String
    var postHogHost: String
    var postHogProjectToken: String

    static var current: SaviCompanionBackendConfig {
        SaviCompanionBackendConfig(
            supabaseURL: value(infoKey: "SAVISupabaseURL", environmentKey: "SAVI_SUPABASE_URL"),
            supabaseAnonKey: value(infoKey: "SAVISupabaseAnonKey", environmentKey: "SAVI_SUPABASE_ANON_KEY"),
            postHogHost: value(infoKey: "SAVIPostHogHost", environmentKey: "SAVI_POSTHOG_HOST"),
            postHogProjectToken: value(infoKey: "SAVIPostHogProjectToken", environmentKey: "SAVI_POSTHOG_PROJECT_TOKEN")
        )
    }

    var socialMode: SaviCompanionBackendMode {
        isSafePublicConfig(supabaseURL) && isSafePublicConfig(supabaseAnonKey) ? .configured : .disabled
    }

    var analyticsMode: SaviCompanionBackendMode {
        isSafePublicConfig(postHogHost) && isSafePublicConfig(postHogProjectToken) ? .configured : .disabled
    }

    private static func value(infoKey: String, environmentKey: String) -> String {
        if let environmentValue = ProcessInfo.processInfo.environment[environmentKey],
           !environmentValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return environmentValue
        }
        return Bundle.main.object(forInfoDictionaryKey: infoKey) as? String ?? ""
    }

    private func isSafePublicConfig(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let lowered = trimmed.lowercased()
        return !lowered.contains("service_role")
            && !lowered.contains("service-role")
            && !lowered.contains("secret")
            && !lowered.contains("password")
    }
}

struct SaviCompanionAnalyticsEvent: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var surface: String
    var createdAt: Date
    var properties: [String: String]
}

protocol SaviCompanionAnalyticsClient {
    func capture(_ event: SaviCompanionAnalyticsEvent)
}

struct SaviCompanionNoopAnalyticsClient: SaviCompanionAnalyticsClient {
    func capture(_ event: SaviCompanionAnalyticsEvent) {}
}

struct SaviCompanionConsoleAnalyticsClient: SaviCompanionAnalyticsClient {
    func capture(_ event: SaviCompanionAnalyticsEvent) {
#if DEBUG
        NSLog("[SAVI Mac Analytics] %@ %@", event.name, event.properties)
#endif
    }
}

protocol SaviCompanionSocialClient {
    var mode: SaviCompanionBackendMode { get }
    func statusText() -> String
}

struct SaviCompanionDisabledSocialClient: SaviCompanionSocialClient {
    let mode: SaviCompanionBackendMode = .disabled

    func statusText() -> String {
        "Sync is off until Supabase URL and anon key are configured."
    }
}

struct SaviCompanionConfiguredSocialClient: SaviCompanionSocialClient {
    let mode: SaviCompanionBackendMode = .configured

    func statusText() -> String {
        "Supabase config is present. Network sync adapter is stubbed until account auth is wired."
    }
}

enum SaviCompanionServiceFactory {
    static func socialClient(config: SaviCompanionBackendConfig = .current) -> any SaviCompanionSocialClient {
        config.socialMode == .configured ? SaviCompanionConfiguredSocialClient() : SaviCompanionDisabledSocialClient()
    }

    static func analyticsClient(config: SaviCompanionBackendConfig = .current) -> any SaviCompanionAnalyticsClient {
#if DEBUG
        config.analyticsMode == .configured ? SaviCompanionConsoleAnalyticsClient() : SaviCompanionNoopAnalyticsClient()
#else
        SaviCompanionNoopAnalyticsClient()
#endif
    }
}

enum SaviCompanionSamples {
    static var library: SaviCompanionLibrary {
        let folders = [
            SaviCompanionFolder(id: "life-admin", name: "Life Admin", colorHex: "#D6F83A", symbolName: "key.fill", isPrivate: false, order: 0),
            SaviCompanionFolder(id: "private-vault", name: "Private Vault", colorHex: "#C7B7FF", symbolName: "lock.fill", isPrivate: true, order: 1),
            SaviCompanionFolder(id: "watch-read", name: "Watch / Read Later", colorHex: "#68C6E8", symbolName: "play.rectangle.fill", isPrivate: false, order: 2),
            SaviCompanionFolder(id: "ai-work", name: "AI & Work", colorHex: "#7A35E8", symbolName: "sparkles", isPrivate: false, order: 3),
            SaviCompanionFolder(id: "places", name: "Places & Trips", colorHex: "#FFB84D", symbolName: "mappin.and.ellipse", isPrivate: false, order: 4),
            SaviCompanionFolder(id: "memes", name: "Memes & LOLZ", colorHex: "#F8DA2F", symbolName: "face.smiling", isPrivate: false, order: 5),
            SaviCompanionFolder(id: "health", name: "Health", colorHex: "#70D59B", symbolName: "heart.text.square.fill", isPrivate: false, order: 6),
            SaviCompanionFolder(id: "rabbit", name: "Rabbit Holes", colorHex: "#9286A8", symbolName: "questionmark.circle.fill", isPrivate: false, order: 7)
        ]

        let now = Date()
        let items = [
            item("airbnb-code", "Airbnb door code + Wi-Fi", "Screenshot-style save with check-in code, Wi-Fi, and checkout time.", nil, "Photos", .image, "life-admin", ["screenshot", "airbnb", "wifi", "travel"], 1, false, false, now),
            item("lasagna-audio", "Mom's lasagna sauce voice note", "Audio note sample for the kind of family detail you do not want to lose.", nil, "Voice Memos", .audio, "life-admin", ["audio", "recipe", "family"], 2, false, false, now),
            item("cpr", "Hands-only CPR: what to do before help arrives", "A practical emergency reference saved for later.", URL(string: "https://www.redcross.org/take-a-class/cpr/performing-cpr/hands-only-cpr"), "Red Cross", .article, "health", ["cpr", "emergency", "health"], 3, false, false, now),
            item("parasite-cancer", "Parasite medication and cancer remission?", "Research note framed as a question for doctor follow-up, not medical advice.", URL(string: "https://pubmed.ncbi.nlm.nih.gov/24160353/"), "PubMed", .article, "health", ["research", "parasite", "cancer", "doctor"], 4, false, false, now),
            item("microbiome-mind", "Does your microbiome control your thoughts?", "Gut-brain-axis curiosity save with a science-first posture.", URL(string: "https://pubmed.ncbi.nlm.nih.gov/30109417/"), "PubMed", .article, "health", ["microbiome", "mind", "research"], 5, false, false, now),
            item("ai-agents", "Building Effective AI Agents", "Useful AI engineering reference for the work folder.", URL(string: "https://www.anthropic.com/research/building-effective-agents"), "Anthropic", .article, "ai-work", ["ai", "agents", "work"], 6, false, true, now),
            item("ramen", "Jennifer's ramen recommendation", "Friend-style food recommendation that shows why buried group-chat saves matter.", nil, "Messages", .place, "places", ["ramen", "friend", "tokyo"], 7, false, false, now),
            item("numa", "Numa Numa: the webcam dance that ate the internet", "Classic internet save for the fun side of the library.", URL(string: "https://www.youtube.com/watch?v=Cqd1Gvq-RBY"), "YouTube", .video, "memes", ["meme", "youtube", "classic"], 8, false, true, now),
            item("hotel", "Hotel booking confirmation", "Travel admin sample with dates, confirmation code, and address.", nil, "Email", .file, "life-admin", ["hotel", "booking", "travel"], 9, false, false, now),
            item("webb", "James Webb Space Telescope - NASA Science", "Awe and credible knowledge, saved for a quiet read.", URL(string: "https://science.nasa.gov/mission/webb/"), "NASA", .article, "watch-read", ["space", "science", "nasa"], 10, false, true, now),
            item("credit-freeze", "How to freeze your credit before someone steals it", "High-value life admin link from a trusted public source.", URL(string: "https://consumer.ftc.gov/articles/what-know-about-credit-freezes-fraud-alerts"), "FTC", .article, "life-admin", ["credit", "security", "life-admin"], 11, false, false, now),
            item("rickroll", "Rick Astley - Never Gonna Give You Up", "A saved video that proves SAVI can keep the useful and the ridiculous together.", URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"), "YouTube", .video, "memes", ["meme", "video", "rickroll"], 12, false, true, now),
            item("insurance", "Insurance card", "Private document sample kept out of social and public sync.", nil, "Files", .image, "private-vault", ["insurance", "private", "sample"], 13, true, false, now),
            item("pentagon-audit", "Pentagon audit rabbit hole", "Official source saved for a budget-accountability deep dive.", URL(string: "https://www.defense.gov/News/News-Stories/Article/Article/3967135/dods-2024-audit-shows-progress-toward-2028-goals/"), "Defense.gov", .article, "rabbit", ["audit", "budget", "official"], 14, false, true, now),
            item("pyramids", "Were the pyramids aligned on purpose?", "Curiosity link with a skeptical source-backed angle.", URL(string: "https://www.smithsonianmag.com/smart-news/fall-equinox-secret-pyramids-near-perfect-alignment-180968223/"), "Smithsonian", .article, "rabbit", ["pyramids", "history", "curiosity"], 15, false, true, now)
        ]

        return SaviCompanionLibrary(folders: folders, items: items)
    }

    private static func item(
        _ id: String,
        _ title: String,
        _ summary: String,
        _ url: URL?,
        _ source: String,
        _ kind: SaviCompanionItemKind,
        _ folderId: String,
        _ tags: [String],
        _ hoursAgo: Int,
        _ isPrivate: Bool,
        _ isPublic: Bool,
        _ now: Date
    ) -> SaviCompanionItem {
        SaviCompanionItem(
            id: id,
            title: title,
            summary: summary,
            url: url,
            source: source,
            kind: kind,
            folderId: folderId,
            tags: tags,
            savedAt: now.addingTimeInterval(TimeInterval(-hoursAgo * 3600)),
            isPrivate: isPrivate,
            isPublic: isPublic
        )
    }
}
