import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum SAVISharedContainer {
    static let productionAppGroupIdentifier = "group.com.savi.shared"
    static let personalDebugAppGroupIdentifier = "group.com.altatecrd.savi.personaldebug"
    static var appGroupIdentifier: String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        return bundleIdentifier.contains(".personaldebug") ? personalDebugAppGroupIdentifier : productionAppGroupIdentifier
    }
    static let pendingSharesDirectory = "pending_shares"
    static let pendingAssetsDirectory = "pending_assets"
    static let foldersFileName = "folders.json"
    static let folderLearningFileName = "folder_learning.json"
    static let folderDecisionsFileName = "folder_decisions.json"
    static let shareSetupStateFileName = "share_setup_state.json"
}

struct PendingShare: Codable, Identifiable {
    var id: String
    var url: String?
    var title: String
    var type: String
    var thumbnail: String?
    var timestamp: Double
    var sourceApp: String
    var text: String?
    var fileName: String?
    var filePath: String?
    var mimeType: String?
    var itemDescription: String?
    var folderId: String?
    var folderSource: String? = nil
    var folderConfidence: Int? = nil
    var folderReason: String? = nil
    var tags: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case title
        case type
        case thumbnail
        case timestamp
        case sourceApp = "source_app"
        case text
        case fileName = "file_name"
        case filePath = "file_path"
        case mimeType = "mime_type"
        case itemDescription = "description"
        case folderId = "folder_id"
        case folderSource = "folder_source"
        case folderConfidence = "folder_confidence"
        case folderReason = "folder_reason"
        case tags
    }
}

enum SAVIDeepLinkShare {
    private static let productionScheme = "savi"
    private static let debugScheme = "savi-debug"
    private static let host = "share"
    private static let acceptedSchemes: Set<String> = [productionScheme, debugScheme]
    private static let maxTitleLength = 180
    private static let maxFieldLength = 1_200
    private static let maxURLLength = 3_500
    private static let maxTags = 12

    static var preferredScheme: String {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        return bundleIdentifier.contains(".personaldebug") ? debugScheme : productionScheme
    }

    static func supportsFallback(_ share: PendingShare) -> Bool {
        guard clean(share.filePath) == nil else { return false }
        if let thumbnail = clean(share.thumbnail), thumbnail.hasPrefix("data:") {
            return false
        }
        return clean(share.url) != nil ||
            clean(share.text) != nil ||
            clean(share.itemDescription) != nil ||
            clean(share.title) != nil
    }

    static func makeURL(from share: PendingShare) -> URL? {
        guard supportsFallback(share) else { return nil }

        var components = URLComponents()
        components.scheme = preferredScheme
        components.host = host

        var queryItems: [URLQueryItem] = []
        append("id", share.id, to: &queryItems)
        append("url", share.url, to: &queryItems, limit: maxURLLength)
        append("title", share.title, to: &queryItems, limit: maxTitleLength)
        append("type", share.type, to: &queryItems)
        append("thumbnail", share.thumbnail, to: &queryItems, limit: maxURLLength)
        append("timestamp", String(share.timestamp), to: &queryItems)
        append("source_app", share.sourceApp, to: &queryItems)
        append("text", share.text, to: &queryItems)
        append("file_name", share.fileName, to: &queryItems)
        append("mime_type", share.mimeType, to: &queryItems)
        append("description", share.itemDescription, to: &queryItems)
        append("folder_id", share.folderId, to: &queryItems)
        append("folder_source", share.folderSource, to: &queryItems)
        append("folder_confidence", share.folderConfidence.map(String.init), to: &queryItems)
        append("folder_reason", share.folderReason, to: &queryItems)

        for tag in (share.tags ?? []).prefix(maxTags) {
            append("tag", tag, to: &queryItems, limit: 48)
        }

        components.queryItems = queryItems
        return components.url
    }

    static func pendingShare(from url: URL) -> PendingShare? {
        guard let scheme = url.scheme?.lowercased(),
              acceptedSchemes.contains(scheme),
              url.host == host,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return nil
        }

        let queryItems = components.queryItems ?? []
        func first(_ name: String) -> String? {
            queryItems.first(where: { $0.name == name })?.value.flatMap(clean)
        }

        let tags = queryItems
            .filter { $0.name == "tag" }
            .compactMap { $0.value.flatMap(clean) }

        let title = first("title") ??
            first("url").flatMap { URL(string: $0)?.host } ??
            "Shared item"
        let type = first("type") ?? (first("url") == nil ? "text" : "link")
        let timestamp = first("timestamp").flatMap(Double.init) ?? Date().timeIntervalSince1970

        return PendingShare(
            id: first("id") ?? UUID().uuidString,
            url: first("url"),
            title: title,
            type: type,
            thumbnail: first("thumbnail"),
            timestamp: timestamp,
            sourceApp: first("source_app") ?? "Share Extension",
            text: first("text"),
            fileName: first("file_name"),
            filePath: nil,
            mimeType: first("mime_type"),
            itemDescription: first("description"),
            folderId: first("folder_id"),
            folderSource: first("folder_source"),
            folderConfidence: first("folder_confidence").flatMap(Int.init),
            folderReason: first("folder_reason"),
            tags: tags.isEmpty ? nil : tags
        )
    }

    private static func append(_ name: String, _ value: String?, to queryItems: inout [URLQueryItem], limit: Int = maxFieldLength) {
        guard let value = clipped(value, limit: limit) else { return }
        queryItems.append(URLQueryItem(name: name, value: value))
    }

    private static func clean(_ value: String?) -> String? {
        guard let cleaned = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !cleaned.isEmpty
        else {
            return nil
        }
        return cleaned
    }

    private static func clipped(_ value: String?, limit: Int) -> String? {
        guard let cleaned = clean(value) else { return nil }
        guard cleaned.count > limit else { return cleaned }
        return String(cleaned.prefix(limit))
    }
}

#if canImport(UIKit)
enum SAVIPasteboardShare {
    private static let payloadType = "com.savi.pending-share+json"
    private static let handoffHost = "handoff"
    private static let acceptedSchemes: Set<String> = ["savi", "savi-debug"]

    static func save(_ share: PendingShare) -> Bool {
        guard SAVIDeepLinkShare.supportsFallback(share),
              let data = try? JSONEncoder().encode(share)
        else {
            return false
        }

        UIPasteboard.general.setItems(
            [[payloadType: data]],
            options: [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(10 * 60)
            ]
        )
        return true
    }

    static func load() -> PendingShare? {
        for item in UIPasteboard.general.items {
            if let data = item[payloadType] as? Data,
               let share = try? JSONDecoder().decode(PendingShare.self, from: data) {
                return share
            }
        }
        return nil
    }

    static func clearIfCurrent(_ share: PendingShare) {
        guard load()?.id == share.id else { return }
        UIPasteboard.general.items = []
    }

    static func makeHandoffURL() -> URL? {
        var components = URLComponents()
        components.scheme = SAVIDeepLinkShare.preferredScheme
        components.host = handoffHost
        return components.url
    }

    static func isHandoffURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return acceptedSchemes.contains(scheme) && url.host == handoffHost
    }
}
#endif

struct SharedFolder: Codable, Identifiable {
    var id: String
    var name: String
    var color: String?
    var system: Bool
    var symbolName: String?
    var order: Int
    var isPublic: Bool

    init(id: String, name: String, color: String?, system: Bool, symbolName: String?, order: Int, isPublic: Bool = false) {
        self.id = id
        self.name = name
        self.color = color
        self.system = system
        self.symbolName = symbolName
        self.order = order
        self.isPublic = isPublic
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case system
        case symbolName = "symbol_name"
        case order
        case isPublic = "is_public"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        system = try container.decodeIfPresent(Bool.self, forKey: .system) ?? false
        symbolName = try container.decodeIfPresent(String.self, forKey: .symbolName)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? false
    }
}

struct SAVIRecentShareFolderUse: Codable, Identifiable, Equatable {
    var folderId: String
    var useCount: Int
    var lastUsedAt: Double

    var id: String { folderId }

    enum CodingKeys: String, CodingKey {
        case folderId = "folder_id"
        case useCount = "use_count"
        case lastUsedAt = "last_used_at"
    }
}

struct SAVIShareSetupState: Codable, Equatable {
    var shareExtensionSaveCount: Int = 0
    var firstShareExtensionSaveAt: Double?
    var lastShareExtensionSaveAt: Double?
    var lastSavedFolderId: String?
    var recentFolders: [SAVIRecentShareFolderUse] = []

    enum CodingKeys: String, CodingKey {
        case shareExtensionSaveCount = "share_extension_save_count"
        case firstShareExtensionSaveAt = "first_share_extension_save_at"
        case lastShareExtensionSaveAt = "last_share_extension_save_at"
        case lastSavedFolderId = "last_saved_folder_id"
        case recentFolders = "recent_folders"
    }

    mutating func recordSuccessfulShare(folderId: String?, at timestamp: Double = Date().timeIntervalSince1970) {
        shareExtensionSaveCount += 1
        if firstShareExtensionSaveAt == nil {
            firstShareExtensionSaveAt = timestamp
        }
        lastShareExtensionSaveAt = timestamp

        guard let folderId = folderId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !folderId.isEmpty
        else { return }

        lastSavedFolderId = folderId
        if let index = recentFolders.firstIndex(where: { $0.folderId == folderId }) {
            recentFolders[index].useCount += 1
            recentFolders[index].lastUsedAt = timestamp
        } else {
            recentFolders.append(
                SAVIRecentShareFolderUse(
                    folderId: folderId,
                    useCount: 1,
                    lastUsedAt: timestamp
                )
            )
        }

        recentFolders = Array(
            recentFolders
                .sorted {
                    if $0.lastUsedAt == $1.lastUsedAt {
                        return $0.useCount > $1.useCount
                    }
                    return $0.lastUsedAt > $1.lastUsedAt
                }
                .prefix(12)
        )
    }
}

struct SAVIFolderLearningSignal: Codable, Identifiable, Equatable {
    var id: String
    var folderId: String
    var phrase: String
    var weight: Int
    var uses: Int
    var updatedAt: Double

    enum CodingKeys: String, CodingKey {
        case id
        case folderId
        case phrase
        case weight
        case uses
        case updatedAt
    }
}

enum SAVIFolderDecisionSource: String, Codable, CaseIterable {
    case rules
    case metadata
    case appleIntelligence = "apple-intelligence"
    case learning
    case manual
    case guardrail
    case fallback

    var label: String {
        switch self {
        case .rules: return "Rules"
        case .metadata: return "Metadata"
        case .appleIntelligence: return "Apple Intelligence"
        case .learning: return "Learning"
        case .manual: return "Manual"
        case .guardrail: return "Guardrail"
        case .fallback: return "Rules fallback"
        }
    }
}

enum SAVIIntelligenceDecisionOutcome: String, Codable, CaseIterable {
    case accepted
    case vetoed
    case timedOut = "timed-out"
    case unavailable
    case failed
    case skipped

    var label: String {
        switch self {
        case .accepted: return "AI accepted"
        case .vetoed: return "AI vetoed"
        case .timedOut: return "AI timed out"
        case .unavailable: return "AI unavailable"
        case .failed: return "AI failed"
        case .skipped: return "AI skipped"
        }
    }
}

struct SAVIIntelligenceAcceptance: Equatable {
    var accepted: Bool
    var vetoReason: String?
}

struct SAVIFolderDecisionRecord: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var folderId: String
    var folderName: String
    var confidence: Int
    var reason: String
    var context: String
    var createdAt: Double
    var source: String
    var outcome: String?
    var aiFolderId: String?
    var aiFolderName: String?
    var aiConfidence: Int?
    var aiReason: String?
    var vetoReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case folderId
        case folderName
        case confidence
        case reason
        case context
        case createdAt
        case source
        case outcome
        case aiFolderId
        case aiFolderName
        case aiConfidence
        case aiReason
        case vetoReason
    }

    init(
        id: String,
        title: String,
        folderId: String,
        folderName: String,
        confidence: Int,
        reason: String,
        context: String,
        createdAt: Double,
        source: SAVIFolderDecisionSource? = nil,
        outcome: SAVIIntelligenceDecisionOutcome? = nil,
        aiFolderId: String? = nil,
        aiFolderName: String? = nil,
        aiConfidence: Int? = nil,
        aiReason: String? = nil,
        vetoReason: String? = nil
    ) {
        self.id = id
        self.title = title
        self.folderId = folderId
        self.folderName = folderName
        self.confidence = confidence
        self.reason = reason
        self.context = context
        self.createdAt = createdAt
        self.source = source?.rawValue ?? Self.inferredSource(reason: reason, context: context).rawValue
        self.outcome = outcome?.rawValue
        self.aiFolderId = aiFolderId
        self.aiFolderName = aiFolderName
        self.aiConfidence = aiConfidence
        self.aiReason = aiReason
        self.vetoReason = vetoReason
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        folderId = try container.decode(String.self, forKey: .folderId)
        folderName = try container.decode(String.self, forKey: .folderName)
        confidence = try container.decode(Int.self, forKey: .confidence)
        reason = try container.decode(String.self, forKey: .reason)
        context = try container.decode(String.self, forKey: .context)
        createdAt = try container.decode(Double.self, forKey: .createdAt)
        source = try container.decodeIfPresent(String.self, forKey: .source) ??
            Self.inferredSource(reason: reason, context: context).rawValue
        outcome = try container.decodeIfPresent(String.self, forKey: .outcome)
        aiFolderId = try container.decodeIfPresent(String.self, forKey: .aiFolderId)
        aiFolderName = try container.decodeIfPresent(String.self, forKey: .aiFolderName)
        aiConfidence = try container.decodeIfPresent(Int.self, forKey: .aiConfidence)
        aiReason = try container.decodeIfPresent(String.self, forKey: .aiReason)
        vetoReason = try container.decodeIfPresent(String.self, forKey: .vetoReason)
    }

    var sourceKind: SAVIFolderDecisionSource {
        SAVIFolderDecisionSource(rawValue: source) ?? .rules
    }

    var outcomeKind: SAVIIntelligenceDecisionOutcome? {
        outcome.flatMap(SAVIIntelligenceDecisionOutcome.init(rawValue:))
    }

    var statusLabel: String {
        if let outcomeKind { return outcomeKind.label }
        switch sourceKind {
        case .appleIntelligence: return "AI accepted"
        case .guardrail: return "Guardrail"
        case .fallback: return "Rules fallback"
        case .learning: return "Learning"
        case .manual: return "Manual"
        case .metadata: return "Metadata"
        case .rules: return "Rules fallback"
        }
    }

    private static func inferredSource(reason: String, context: String) -> SAVIFolderDecisionSource {
        let reason = reason.lowercased()
        let context = context.lowercased()
        if context.contains("apple") || reason.contains("apple-intelligence") { return .appleIntelligence }
        if context.contains("manual") || reason.contains("manual") { return .manual }
        if reason.contains("learned") { return .learning }
        if reason.contains("guardrail") { return .guardrail }
        if context.contains("metadata") { return .metadata }
        if reason.contains("fallback") { return .fallback }
        return .rules
    }
}

enum PendingShareStoreError: LocalizedError {
    case missingAppGroupContainer
    case invalidFileURL

    var errorDescription: String? {
        switch self {
        case .missingAppGroupContainer:
            return "App Group container could not be found."
        case .invalidFileURL:
            return "The shared file could not be copied into the App Group container."
        }
    }
}

final class PendingShareStore {
    static let shared = PendingShareStore()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder = JSONDecoder()

    func containerURL() throws -> URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SAVISharedContainer.appGroupIdentifier
        ) else {
            throw PendingShareStoreError.missingAppGroupContainer
        }
        return url
    }

    func pendingSharesDirectoryURL() throws -> URL {
        let directory = try containerURL().appendingPathComponent(
            SAVISharedContainer.pendingSharesDirectory,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func pendingAssetsDirectoryURL() throws -> URL {
        let directory = try containerURL().appendingPathComponent(
            SAVISharedContainer.pendingAssetsDirectory,
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func foldersFileURL() throws -> URL {
        try containerURL().appendingPathComponent(SAVISharedContainer.foldersFileName)
    }

    func folderLearningFileURL() throws -> URL {
        try containerURL().appendingPathComponent(SAVISharedContainer.folderLearningFileName)
    }

    func folderDecisionsFileURL() throws -> URL {
        try containerURL().appendingPathComponent(SAVISharedContainer.folderDecisionsFileName)
    }

    func shareSetupStateFileURL() throws -> URL {
        try containerURL().appendingPathComponent(SAVISharedContainer.shareSetupStateFileName)
    }

    @discardableResult
    func save(_ share: PendingShare) throws -> URL {
        let directory = try pendingSharesDirectoryURL()
        let fileURL = directory.appendingPathComponent("\(share.id).json")
        let data = try encoder.encode(share)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    func loadPendingShares() -> [PendingShare] {
        guard let directory = try? pendingSharesDirectoryURL(),
              let urls = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
              )
        else {
            return []
        }

        return urls
            .filter { $0.pathExtension.lowercased() == "json" }
            .sorted { lhs, rhs in
                let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhsDate < rhsDate
            }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(PendingShare.self, from: data)
            }
    }

    func saveFolders(_ folders: [SharedFolder]) throws {
        let fileURL = try foldersFileURL()
        let data = try encoder.encode(folders.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.order < rhs.order
        })
        try data.write(to: fileURL, options: .atomic)
    }

    func loadFolders() -> [SharedFolder] {
        guard let fileURL = try? foldersFileURL(),
              let data = try? Data(contentsOf: fileURL),
              let folders = try? decoder.decode([SharedFolder].self, from: data)
        else {
            return []
        }

        return folders.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.order < rhs.order
        }
    }

    func saveFolderLearning(_ signals: [SAVIFolderLearningSignal]) throws {
        let fileURL = try folderLearningFileURL()
        let sorted = signals.sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt { return lhs.id < rhs.id }
            return lhs.updatedAt > rhs.updatedAt
        }
        let data = try encoder.encode(sorted)
        try data.write(to: fileURL, options: .atomic)
    }

    func loadFolderLearning() -> [SAVIFolderLearningSignal] {
        guard let fileURL = try? folderLearningFileURL(),
              let data = try? Data(contentsOf: fileURL),
              let signals = try? decoder.decode([SAVIFolderLearningSignal].self, from: data)
        else {
            return []
        }

        return signals.sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt { return lhs.id < rhs.id }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    func saveFolderDecision(_ decision: SAVIFolderDecisionRecord, limit: Int = 80) {
        var records = loadFolderDecisions()
        records.removeAll { $0.id == decision.id }
        records.insert(decision, at: 0)
        saveFolderDecisions(records, limit: limit)
    }

    func saveFolderDecisions(_ decisions: [SAVIFolderDecisionRecord], limit: Int = 80) {
        guard let fileURL = try? folderDecisionsFileURL() else { return }
        let sorted = decisions.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt { return lhs.id < rhs.id }
            return lhs.createdAt > rhs.createdAt
        }
        let limited = Array(sorted.prefix(max(1, limit)))
        guard let data = try? encoder.encode(limited) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func loadFolderDecisions() -> [SAVIFolderDecisionRecord] {
        guard let fileURL = try? folderDecisionsFileURL(),
              let data = try? Data(contentsOf: fileURL),
              let records = try? decoder.decode([SAVIFolderDecisionRecord].self, from: data)
        else {
            return []
        }

        return records.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt { return lhs.id < rhs.id }
            return lhs.createdAt > rhs.createdAt
        }
    }

    func clearFolderDecisions() {
        guard let fileURL = try? folderDecisionsFileURL() else { return }
        try? FileManager.default.removeItem(at: fileURL)
    }

    func loadShareSetupState() -> SAVIShareSetupState {
        guard let fileURL = try? shareSetupStateFileURL(),
              let data = try? Data(contentsOf: fileURL),
              let state = try? decoder.decode(SAVIShareSetupState.self, from: data)
        else {
            return SAVIShareSetupState()
        }
        return state
    }

    func saveShareSetupState(_ state: SAVIShareSetupState) throws {
        let fileURL = try shareSetupStateFileURL()
        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: .atomic)
    }

    func recordShareExtensionSave(folderId: String?) {
        var state = loadShareSetupState()
        state.recordSuccessfulShare(folderId: folderId)
        try? saveShareSetupState(state)
    }

    func remove(_ share: PendingShare) {
        guard let directory = try? pendingSharesDirectoryURL() else { return }
        let shareURL = directory.appendingPathComponent("\(share.id).json")
        try? FileManager.default.removeItem(at: shareURL)

        if let filePath = share.filePath, !filePath.isEmpty {
            try? FileManager.default.removeItem(atPath: filePath)
        }
    }

    func copyAssetToSharedContainer(from sourceURL: URL, preferredName: String? = nil) throws -> URL {
        guard sourceURL.isFileURL else { throw PendingShareStoreError.invalidFileURL }
        let directory = try pendingAssetsDirectoryURL()
        let fileName = preferredName ?? sourceURL.lastPathComponent
        let destination = directory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension((fileName as NSString).pathExtension)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return destination
    }
}

struct SAVIFolderOption {
    var id: String
    var name: String
}

struct SAVIFolderClassificationInput {
    var title: String
    var description: String
    var url: String?
    var type: String
    var source: String
    var fileName: String?
    var mimeType: String?
    var tags: [String]

    init(
        title: String = "",
        description: String = "",
        url: String? = nil,
        type: String = "",
        source: String = "",
        fileName: String? = nil,
        mimeType: String? = nil,
        tags: [String] = []
    ) {
        self.title = title
        self.description = description
        self.url = url
        self.type = type
        self.source = source
        self.fileName = fileName
        self.mimeType = mimeType
        self.tags = tags
    }
}

struct SAVIFolderClassification {
    var folderId: String
    var confidence: Int
    var reason: String
}

struct SAVIFolderAuditCase: Identifiable {
    var id: String
    var name: String
    var expectedFolderId: String
    var minimumConfidence: Int
    var input: SAVIFolderClassificationInput
}

struct SAVIFolderAuditResult: Identifiable {
    var id: String { testCase.id }
    var testCase: SAVIFolderAuditCase
    var classification: SAVIFolderClassification

    var passed: Bool {
        classification.folderId == testCase.expectedFolderId &&
            classification.confidence >= testCase.minimumConfidence
    }
}

struct SAVIIntelligenceAuditCase: Identifiable {
    var id: String
    var name: String
    var input: SAVIFolderClassificationInput
    var suggestedFolderId: String
    var suggestedConfidence: Int
    var expectedAccepted: Bool
}

struct SAVIIntelligenceAuditResult: Identifiable {
    var id: String { testCase.id }
    var testCase: SAVIIntelligenceAuditCase
    var localClassification: SAVIFolderClassification
    var acceptance: SAVIIntelligenceAcceptance

    var passed: Bool {
        acceptance.accepted == testCase.expectedAccepted
    }
}

struct SAVIFolderAuditReport {
    var results: [SAVIFolderAuditResult]
    var intelligenceResults: [SAVIIntelligenceAuditResult] = []
    var folderOptions: [SAVIFolderOption]

    var passedCount: Int {
        results.filter(\.passed).count
    }

    var failedCount: Int {
        results.count - passedCount
    }

    var failures: [SAVIFolderAuditResult] {
        results.filter { !$0.passed }
    }

    var intelligencePassedCount: Int {
        intelligenceResults.filter(\.passed).count
    }

    var intelligenceFailedCount: Int {
        intelligenceResults.count - intelligencePassedCount
    }

    var intelligenceFailures: [SAVIIntelligenceAuditResult] {
        intelligenceResults.filter { !$0.passed }
    }

    var coveredFolderIds: Set<String> {
        Set(results.map(\.testCase.expectedFolderId))
    }

    var uncoveredFolderIds: [String] {
        folderOptions
            .map(\.id)
            .filter { $0 != SAVIFolderClassifier.allItemsFolderId && !coveredFolderIds.contains($0) }
    }

    var passRate: Double {
        guard !results.isEmpty else { return 0 }
        return Double(passedCount) / Double(results.count)
    }
}

enum SAVIFolderClassifier {
    static let fallbackFolderId = "f-random"
    static let allItemsFolderId = "f-all"
    private static let privateFolderId = "f-private-vault"

    private struct WeightedTerm {
        var value: String
        var weight: Int
    }

    private enum ProfileRole: Hashable {
        case semantic
        case utility
        case collection
    }

    private struct Profile {
        var id: String
        var terms: [WeightedTerm]
        var role: ProfileRole = .semantic
    }

    private struct NormalizedInput {
        var title: String
        var description: String
        var url: String
        var type: String
        var source: String
        var fileName: String
        var mimeType: String
        var tags: String
        var all: String

        init(_ input: SAVIFolderClassificationInput) {
            title = SAVIFolderClassifier.normalize(input.title)
            description = SAVIFolderClassifier.normalize(input.description)
            url = SAVIFolderClassifier.normalize(input.url)
            type = SAVIFolderClassifier.normalize(input.type)
            source = SAVIFolderClassifier.normalize(input.source)
            fileName = SAVIFolderClassifier.normalize(input.fileName)
            mimeType = SAVIFolderClassifier.normalize(input.mimeType)
            tags = SAVIFolderClassifier.normalize(input.tags.joined(separator: " "))
            all = [
                title,
                description,
                url,
                type,
                source,
                fileName,
                mimeType,
                tags
            ].joined(separator: " ")
        }
    }

    static let defaultFolderOptions: [SAVIFolderOption] = [
        .init(id: "f-life-admin", name: "Life Admin"),
        .init(id: "f-must-see", name: "Watch / Read Later"),
        .init(id: "f-growth", name: "AI & Work"),
        .init(id: "f-lmao", name: "Memes & Laughs"),
        .init(id: "f-travel", name: "Places & Trips"),
        .init(id: "f-recipes", name: "Recipes & Food"),
        .init(id: "f-paste-bin", name: "Notes & Clips"),
        .init(id: "f-private-vault", name: "Private Vault"),
        .init(id: "f-research", name: "Research & PDFs"),
        .init(id: "f-design", name: "Design Inspo"),
        .init(id: "f-health", name: "Health"),
        .init(id: "f-wtf-favorites", name: "Science Finds"),
        .init(id: "f-tinfoil", name: "Rabbit Holes"),
        .init(id: "f-random", name: "Everything Else"),
    ]

    static func classify(
        _ input: SAVIFolderClassificationInput,
        availableFolders: [SAVIFolderOption] = defaultFolderOptions,
        learningSignals: [SAVIFolderLearningSignal] = []
    ) -> SAVIFolderClassification {
        let folders = normalizedFolders(availableFolders)
        let allowedIds = Set(folders.map(\.id))
        let normalized = NormalizedInput(input)

        if shouldUsePrivateGuardrail(input, normalized: normalized) {
            return .init(folderId: firstAllowed(privateFolderId, allowedIds: allowedIds), confidence: 100, reason: "private-guardrail")
        }

        if isPlace(input) || containsAny(normalized.all, ["google maps", "maps apple", "maps google"]) {
            return .init(folderId: firstAllowed("f-travel", allowedIds: allowedIds), confidence: 92, reason: "place-guardrail")
        }

        if shouldPreferPasteBin(input) {
            return .init(folderId: firstAllowed("f-paste-bin", allowedIds: allowedIds), confidence: 82, reason: "paste-guardrail")
        }

        var best = scoreSystemProfiles(normalized, allowedIds: allowedIds, roles: [.semantic])
        if let custom = scoreCustomFolders(folders, normalized: normalized),
           custom.confidence >= max(18, best.confidence + 4) {
            best = custom
        }
        if let learned = scoreLearningSignals(learningSignals, normalized: normalized, allowedIds: allowedIds),
           learned.confidence >= max(22, best.confidence - 6) {
            best = learned
        }

        if best.confidence >= 14 {
            return best
        }

        let utilityBest = scoreSystemProfiles(normalized, allowedIds: allowedIds, roles: [.utility])
        if utilityBest.confidence >= 20 {
            return utilityBest
        }

        let collectionBest = scoreSystemProfiles(normalized, allowedIds: allowedIds, roles: [.collection])
        if collectionBest.confidence >= 18 {
            return collectionBest
        }

        if isWatchable(input) {
            return .init(folderId: firstAllowed("f-must-see", allowedIds: allowedIds), confidence: 14, reason: "watchable-fallback")
        }

        if isDocumentLike(input) {
            return .init(folderId: firstAllowed("f-random", allowedIds: allowedIds), confidence: 8, reason: "generic-file-fallback")
        }

        return .init(folderId: firstAllowed(fallbackFolderId, allowedIds: allowedIds), confidence: 0, reason: "fallback")
    }

    static func isSensitive(_ input: SAVIFolderClassificationInput) -> Bool {
        looksSensitive(joinRaw(input))
    }

    static func looksSensitive(_ text: String) -> Bool {
        if regexMatch(#"\b(password|credential|bearer|private key|apikey|api key|seed phrase|recovery phrase|wallet|passcode|ssh)\b"#, in: text) {
            return true
        }
        return regexMatch(#"\b(api|client|auth|access|refresh|jwt|oauth|ssh)\b.{0,40}\b(secret|token)\b|\b(secret|token)\b.{0,40}\b(api|client|auth|access|refresh|jwt|oauth|ssh)\b"#, in: text)
    }

    static func looksPrivateDocument(_ input: SAVIFolderClassificationInput) -> Bool {
        looksPrivateDocument(joinRaw(input))
    }

    static func looksPrivateDocument(_ text: String) -> Bool {
        regexMatch(#"\b(passport|driver'?s license|social security|ssn|tax return|w-2|1099|insurance|bank statement|credit card|debit card|receipt|lease|medical record|lab result|prescription|id card|paystub|pay stub)\b"#, in: text)
    }

    static func shouldAcceptIntelligenceFolder(
        _ folderId: String,
        localResult: SAVIFolderClassification,
        input: SAVIFolderClassificationInput
    ) -> Bool {
        intelligenceAcceptance(folderId, localResult: localResult, input: input).accepted
    }

    static func intelligenceAcceptance(
        _ folderId: String,
        localResult: SAVIFolderClassification,
        input: SAVIFolderClassificationInput,
        aiConfidence: Int? = nil,
        aiReason: String? = nil
    ) -> SAVIIntelligenceAcceptance {
        let normalized = NormalizedInput(input)
        let aiConfidence = max(0, min(aiConfidence ?? 60, 100))
        let localConfidence = max(0, min(localResult.confidence, 100))

        func veto(_ reason: String) -> SAVIIntelligenceAcceptance {
            SAVIIntelligenceAcceptance(accepted: false, vetoReason: reason)
        }

        if folderId == privateFolderId, !isSensitive(input), !looksPrivateDocument(input) {
            return veto("Private Vault needs a real private document or credential signal.")
        }

        if folderId == "f-wtf-favorites", !hasScienceIntent(normalized) {
            return veto("Science Finds needs real science, space, research, or discovery intent.")
        }

        if folderId == "f-health", isEntertainmentContext(normalized), !hasHealthIntent(normalized) {
            return veto("Entertainment about scary topics is not Health.")
        }

        if folderId == "f-tinfoil", isEntertainmentContext(normalized) {
            return veto("Movie, show, trailer, or fandom saves should not go to Rabbit Holes.")
        }

        if folderId == "f-lmao", isEntertainmentOrCasualVideo(input, normalized: normalized), !hasComedyIntent(normalized) {
            return veto("Entertainment videos go to Watch / Read Later unless they are clearly comedy or memes.")
        }

        if folderId == fallbackFolderId,
           localResult.folderId != fallbackFolderId,
           localConfidence >= 14 {
            return veto("Everything Else is only for low-confidence leftovers.")
        }

        if localResult.reason.hasSuffix("guardrail"), localResult.folderId != folderId {
            return veto("Local \(localResult.reason) guardrail wins.")
        }

        if localResult.folderId == privateFolderId, localResult.folderId != folderId {
            return veto("Private Vault guardrail wins.")
        }

        if localResult.reason == "learned-folder",
           localResult.folderId != folderId,
           localConfidence >= 30 {
            return veto("Local learning from previous manual corrections wins.")
        }

        let genericFolders = Set([fallbackFolderId, "f-must-see", "f-paste-bin"])
        if !genericFolders.contains(localResult.folderId),
           localResult.folderId != folderId,
           localConfidence >= 48 {
            return veto("Local rules were high confidence.")
        }

        if localResult.folderId != folderId,
           localConfidence >= 22,
           aiConfidence < 70 {
            return veto("AI confidence was not strong enough to override local rules.")
        }

        return SAVIIntelligenceAcceptance(accepted: true, vetoReason: nil)
    }

    static func decisionSource(for result: SAVIFolderClassification, context: String = "") -> SAVIFolderDecisionSource {
        let reason = result.reason.lowercased()
        let context = context.lowercased()
        if context.contains("apple") || reason.contains("apple-intelligence") { return .appleIntelligence }
        if context.contains("manual") || reason.contains("manual") { return .manual }
        if reason.contains("learned") { return .learning }
        if reason.contains("guardrail") { return .guardrail }
        if context.contains("metadata") { return .metadata }
        if reason.contains("fallback") { return .fallback }
        return .rules
    }

    static func folderGuidanceLines(for availableFolders: [SAVIFolderOption]) -> [String] {
        normalizedFolders(availableFolders).map { folder in
            let guidance = folderGuidanceById[folder.id] ?? (
                use: "content that directly matches the custom folder name \"\(folder.name)\" or strong local learning examples",
                avoid: "guessing from vibes when another folder is more literal"
            )
            return "\(folder.id): \(folder.name). Use for: \(guidance.use). Avoid: \(guidance.avoid)."
        }
    }

    static func audit(
        availableFolders: [SAVIFolderOption] = defaultFolderOptions,
        learningSignals: [SAVIFolderLearningSignal] = []
    ) -> SAVIFolderAuditReport {
        let folders = normalizedFolders(availableFolders)
        let allowedIds = Set(folders.map(\.id))
        let runnableCases = auditCases.filter { allowedIds.contains($0.expectedFolderId) }
        let results = runnableCases.map { testCase in
            SAVIFolderAuditResult(
                testCase: testCase,
                classification: classify(testCase.input, availableFolders: folders, learningSignals: learningSignals)
            )
        }
        let intelligenceResults = intelligenceAuditCases
            .filter { allowedIds.contains($0.suggestedFolderId) }
            .map { testCase in
                let local = classify(testCase.input, availableFolders: folders, learningSignals: learningSignals)
                return SAVIIntelligenceAuditResult(
                    testCase: testCase,
                    localClassification: local,
                    acceptance: intelligenceAcceptance(
                        testCase.suggestedFolderId,
                        localResult: local,
                        input: testCase.input,
                        aiConfidence: testCase.suggestedConfidence,
                        aiReason: "mock-audit"
                    )
                )
            }
        return SAVIFolderAuditReport(results: results, intelligenceResults: intelligenceResults, folderOptions: folders)
    }

    static func learningExamples(
        from signals: [SAVIFolderLearningSignal],
        availableFolders: [SAVIFolderOption] = defaultFolderOptions,
        limit: Int = 8
    ) -> [String] {
        guard limit > 0 else { return [] }
        let folders = normalizedFolders(availableFolders)
        let folderNamesById = Dictionary(uniqueKeysWithValues: folders.map { ($0.id, $0.name) })
        var seen = Set<String>()

        return signals
            .sorted { lhs, rhs in
                let leftScore = lhs.weight + lhs.uses
                let rightScore = rhs.weight + rhs.uses
                if leftScore == rightScore { return lhs.updatedAt > rhs.updatedAt }
                return leftScore > rightScore
            }
            .compactMap { signal -> String? in
                guard let folderName = folderNamesById[signal.folderId] else { return nil }
                let phrase = normalizedKey(signal.phrase)
                guard isLearnablePhrase(phrase) else { return nil }
                let key = "\(signal.folderId)-\(phrase)"
                guard seen.insert(key).inserted else { return nil }
                return "\"\(phrase)\" => \(signal.folderId): \(folderName)"
            }
            .prefix(limit)
            .map { $0 }
    }

    static func learningSignals(
        from input: SAVIFolderClassificationInput,
        correctedFolderId: String,
        now: Double = Date().timeIntervalSince1970
    ) -> [SAVIFolderLearningSignal] {
        guard correctedFolderId != allItemsFolderId,
              correctedFolderId != privateFolderId,
              !isSensitive(input),
              !looksPrivateDocument(input)
        else {
            return []
        }

        var candidates: [(phrase: String, weight: Int, source: String)] = []
        candidates.append(contentsOf: input.tags.map { ($0, 8, "tag") })
        candidates.append(contentsOf: learnablePhrases(from: input.title, singleWeight: 6, phraseWeight: 8, source: "title"))
        candidates.append(contentsOf: learnablePhrases(from: input.description, singleWeight: 3, phraseWeight: 5, source: "description").prefix(5))
        candidates.append(contentsOf: learnablePhrases(from: input.fileName ?? "", singleWeight: 5, phraseWeight: 7, source: "file"))

        if let host = learnableHost(from: input.url) {
            candidates.append((host, 7, "domain"))
        }

        var seen = Set<String>()
        return candidates.compactMap { candidate in
            let phrase = normalizedKey(candidate.phrase)
            guard isLearnablePhrase(phrase) else { return nil }
            let id = learningSignalId(folderId: correctedFolderId, phrase: phrase, source: candidate.source)
            guard seen.insert(id).inserted else { return nil }
            return SAVIFolderLearningSignal(
                id: id,
                folderId: correctedFolderId,
                phrase: phrase,
                weight: max(1, min(candidate.weight, 12)),
                uses: 1,
                updatedAt: now
            )
        }
    }

    private static func scoreSystemProfiles(_ normalized: NormalizedInput, allowedIds: Set<String>, roles: Set<ProfileRole>) -> SAVIFolderClassification {
        var best = SAVIFolderClassification(folderId: firstAllowed(fallbackFolderId, allowedIds: allowedIds), confidence: 0, reason: "fallback")
        for profile in profiles where allowedIds.contains(profile.id) && roles.contains(profile.role) {
            if profile.id == "f-wtf-favorites", !hasScienceIntent(normalized) {
                continue
            }
            if profile.id == "f-tinfoil", isEntertainmentContext(normalized) {
                continue
            }
            if profile.id == "f-health", isEntertainmentContext(normalized), !hasHealthIntent(normalized) {
                continue
            }
            let score = score(profile, normalized: normalized)
            if score > best.confidence {
                best = .init(folderId: profile.id, confidence: score, reason: "profile-\(profile.id)")
            }
        }
        return best
    }

    private static func scoreCustomFolders(_ folders: [SAVIFolderOption], normalized: NormalizedInput) -> SAVIFolderClassification? {
        let systemIds = Set(defaultFolderOptions.map(\.id)).union([allItemsFolderId])
        let customFolders = folders.filter { !systemIds.contains($0.id) }
        var best: SAVIFolderClassification?

        for folder in customFolders {
            let tokens = folderTokens(folder.name)
            guard !tokens.isEmpty else { continue }
            let score = tokens.reduce(0) { partial, token in
                partial + weightedScore(for: token, normalized: normalized, baseWeight: max(2, min(token.count, 8)))
            }
            if score > (best?.confidence ?? 0) {
                best = .init(folderId: folder.id, confidence: score, reason: "custom-folder-name")
            }
        }
        return best
    }

    private static func scoreLearningSignals(_ signals: [SAVIFolderLearningSignal], normalized: NormalizedInput, allowedIds: Set<String>) -> SAVIFolderClassification? {
        var scores: [String: Int] = [:]
        for signal in signals where allowedIds.contains(signal.folderId) {
            if signal.folderId == "f-wtf-favorites", !hasScienceIntent(normalized) {
                continue
            }
            let phrase = normalizedKey(signal.phrase)
            guard isLearnablePhrase(phrase) else { continue }
            let baseWeight = max(1, min(signal.weight + min(signal.uses, 4), 16))
            let score = weightedScore(for: phrase, normalized: normalized, baseWeight: baseWeight)
            if score > 0 {
                scores[signal.folderId, default: 0] += score
            }
        }

        guard let winner = scores.max(by: { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key > rhs.key }
            return lhs.value < rhs.value
        }) else {
            return nil
        }

        return .init(folderId: winner.key, confidence: min(winner.value, 96), reason: "learned-folder")
    }

    private static let auditCases: [SAVIFolderAuditCase] = [
        .init(
            id: "life-admin-airbnb-code",
            name: "Travel access code",
            expectedFolderId: "f-life-admin",
            minimumConfidence: 42,
            input: .init(
                title: "Airbnb door code and Wi-Fi",
                description: "Front door code, guest Wi-Fi, checkout details, and confirmation number.",
                type: "text",
                source: "SAVI",
                tags: ["airbnb", "door-code", "wifi"]
            )
        ),
        .init(
            id: "life-admin-contract-template",
            name: "Reusable admin template",
            expectedFolderId: "f-life-admin",
            minimumConfidence: 36,
            input: .init(
                title: "Contract template to reuse",
                description: "Service agreement template and admin document checklist.",
                type: "file",
                source: "Files",
                fileName: "service-contract-template.docx",
                mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                tags: ["contract", "template"]
            )
        ),
        .init(
            id: "recipes-sourdough",
            name: "Recipe video",
            expectedFolderId: "f-recipes",
            minimumConfidence: 36,
            input: .init(
                title: "Sourdough focaccia recipe with garlic oil",
                description: "Ingredients, bake time, and meal prep notes.",
                url: "https://www.seriouseats.com/sourdough-focaccia",
                type: "article",
                source: "Serious Eats",
                tags: ["recipe", "bread"]
            )
        ),
        .init(
            id: "places-map",
            name: "Map save",
            expectedFolderId: "f-travel",
            minimumConfidence: 50,
            input: .init(
                title: "Google Maps pin for a tapas restaurant in Madrid",
                description: "Directions and reservation notes for the trip.",
                url: "https://maps.google.com/?q=tapas+madrid",
                type: "place",
                source: "Google Maps"
            )
        ),
        .init(
            id: "places-passport-guide",
            name: "Public passport guide",
            expectedFolderId: "f-travel",
            minimumConfidence: 18,
            input: .init(
                title: "Passport renewal guide for a Spain trip",
                description: "Requirements, timelines, and travel tips.",
                url: "https://travel.state.gov/passport-renewal",
                type: "article",
                source: "Travel"
            )
        ),
        .init(
            id: "health-parasite",
            name: "Health parasite context",
            expectedFolderId: "f-health",
            minimumConfidence: 48,
            input: .init(
                title: "Parasite cleanse symptoms and deworming protocol",
                description: "Gut health, supplement, and doctor notes.",
                url: "https://example.com/parasite-cleanse",
                type: "video",
                source: "YouTube",
                tags: ["health"]
            )
        ),
        .init(
            id: "watch-parasite-trailer",
            name: "Parasite movie trailer",
            expectedFolderId: "f-must-see",
            minimumConfidence: 32,
            input: .init(
                title: "Parasite official movie trailer",
                description: "Bong Joon Ho film trailer and cast.",
                url: "https://youtube.com/watch?v=trailer",
                type: "video",
                source: "YouTube"
            )
        ),
        .init(
            id: "watch-password-trailer",
            name: "Password movie false positive",
            expectedFolderId: "f-must-see",
            minimumConfidence: 32,
            input: .init(
                title: "Password official trailer",
                description: "Streaming movie clip, cast, and release date.",
                url: "https://youtube.com/watch?v=password-trailer",
                type: "video",
                source: "YouTube"
            )
        ),
        .init(
            id: "watch-password-manager-guide",
            name: "Password guide false positive",
            expectedFolderId: "f-must-see",
            minimumConfidence: 14,
            input: .init(
                title: "Password manager setup guide",
                description: "Security article with best practices for family account setup.",
                url: "https://www.wired.com/story/password-manager-setup-guide/",
                type: "article",
                source: "Wired"
            )
        ),
        .init(
            id: "watch-alien-trailer",
            name: "Alien movie false positive",
            expectedFolderId: "f-must-see",
            minimumConfidence: 32,
            input: .init(
                title: "Alien: Romulus official trailer",
                description: "Science fiction film trailer, cast, and streaming release date.",
                url: "https://youtube.com/watch?v=alien-romulus-trailer",
                type: "video",
                source: "YouTube"
            )
        ),
        .init(
            id: "watch-rick-astley-music",
            name: "Rick Astley music video false positive",
            expectedFolderId: "f-must-see",
            minimumConfidence: 14,
            input: .init(
                title: "Rick Astley - Driving Me Crazy (Official Video)",
                description: "Shared from YouTube by Rick Astley.",
                url: "https://www.youtube.com/watch?v=mIHHfNVfhPk",
                type: "video",
                source: "YouTube",
                tags: ["youtube", "video"]
            )
        ),
        .init(
            id: "lulz-rickroll",
            name: "Rickroll internet classic",
            expectedFolderId: "f-lmao",
            minimumConfidence: 36,
            input: .init(
                title: "Never Gonna Give You Up",
                description: "The immortal Rickroll and internet classic.",
                url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                type: "video",
                source: "YouTube",
                tags: ["rickroll", "music", "internet classic"]
            )
        ),
        .init(
            id: "design-typeface",
            name: "Design inspiration",
            expectedFolderId: "f-design",
            minimumConfidence: 50,
            input: .init(
                title: "Rounded typeface and app icon palette inspiration",
                description: "Figma UI components, typography, and brand mockups.",
                url: "https://www.behance.net/gallery/app-icon-typeface",
                type: "article",
                source: "Behance",
                tags: ["design"]
            )
        ),
        .init(
            id: "growth-chatgpt",
            name: "AI workflow",
            expectedFolderId: "f-growth",
            minimumConfidence: 42,
            input: .init(
                title: "ChatGPT automation workflow for startup growth",
                description: "OpenAI agent prompt, Zapier shortcut, and marketing funnel.",
                url: "https://example.com/chatgpt-automation",
                type: "article",
                source: "Substack",
                tags: ["ai", "automation"]
            )
        ),
        .init(
            id: "growth-api-token-docs",
            name: "Public API token docs",
            expectedFolderId: "f-growth",
            minimumConfidence: 36,
            input: .init(
                title: "OpenAI API token authentication tutorial",
                description: "Developer documentation for setup, auth headers, and best practices.",
                url: "https://platform.openai.com/docs/api-reference/authentication",
                type: "article",
                source: "OpenAI Docs",
                tags: ["api", "docs"]
            )
        ),
        .init(
            id: "research-arxiv",
            name: "Research PDF",
            expectedFolderId: "f-research",
            minimumConfidence: 50,
            input: .init(
                title: "arXiv paper: benchmark study for language models",
                description: "Abstract, methodology, citations, and appendix.",
                url: "https://arxiv.org/pdf/2501.00001.pdf",
                type: "file",
                source: "arXiv",
                fileName: "language-model-benchmark.pdf",
                mimeType: "application/pdf",
                tags: ["research"]
            )
        ),
        .init(
            id: "science-nasa",
            name: "Science discovery",
            expectedFolderId: "f-wtf-favorites",
            minimumConfidence: 34,
            input: .init(
                title: "NASA Webb telescope black hole discovery",
                description: "Astronomy breakthrough and space science analysis.",
                url: "https://www.nasa.gov/webb-black-hole",
                type: "article",
                source: "NASA"
            )
        ),
        .init(
            id: "tinfoil-ufo",
            name: "Conspiracy rabbit hole",
            expectedFolderId: "f-tinfoil",
            minimumConfidence: 42,
            input: .init(
                title: "UFO cover-up and Area 51 declassified files",
                description: "Rabbit hole about classified secret programs.",
                url: "https://example.com/ufo-cover-up",
                type: "article",
                source: "Web"
            )
        ),
        .init(
            id: "lulz-meme",
            name: "Funny save",
            expectedFolderId: "f-lmao",
            minimumConfidence: 40,
            input: .init(
                title: "Cursed meme compilation that made me laugh",
                description: "Comedy clip, parody, and absurd internet humor.",
                url: "https://www.instagram.com/reel/funny-meme",
                type: "video",
                source: "Instagram",
                tags: ["meme"]
            )
        ),
        .init(
            id: "paste-code",
            name: "Clipboard utility text",
            expectedFolderId: "f-paste-bin",
            minimumConfidence: 50,
            input: .init(
                title: "Copied JSON snippet",
                description: "TODO checklist with curl command and config draft.",
                type: "text",
                source: "Clipboard",
                tags: ["snippet"]
            )
        ),
        .init(
            id: "paste-ai-prompt",
            name: "Copied AI prompt",
            expectedFolderId: "f-paste-bin",
            minimumConfidence: 50,
            input: .init(
                title: "Prompt draft",
                description: "Copied ChatGPT prompt checklist with variables and TODO notes.",
                type: "text",
                source: "Clipboard",
                tags: ["prompt"]
            )
        ),
        .init(
            id: "private-passport-scan",
            name: "Private document",
            expectedFolderId: "f-private-vault",
            minimumConfidence: 90,
            input: .init(
                title: "Passport scan PDF",
                description: "My passport copy for an application.",
                type: "file",
                source: "Device",
                fileName: "passport-scan.pdf",
                mimeType: "application/pdf"
            )
        ),
        .init(
            id: "private-token",
            name: "Credential text",
            expectedFolderId: "f-private-vault",
            minimumConfidence: 90,
            input: .init(
                title: "API secret token",
                description: "Bearer token and private key for auth.",
                type: "text",
                source: "Clipboard"
            )
        ),
        .init(
            id: "random-generic-file",
            name: "Generic file fallback",
            expectedFolderId: "f-random",
            minimumConfidence: 8,
            input: .init(
                title: "Untitled scan 003",
                description: "application/octet-stream",
                type: "file",
                source: "Device",
                fileName: "scan-003.bin",
                mimeType: "application/octet-stream"
            )
        )
    ]

    private static let intelligenceAuditCases: [SAVIIntelligenceAuditCase] = [
        .init(
            id: "ai-veto-rick-astley-science",
            name: "Veto music video into Science Finds",
            input: .init(
                title: "Rick Astley - Driving Me Crazy (Official Video)",
                description: "Shared from YouTube by Rick Astley.",
                url: "https://www.youtube.com/watch?v=mIHHfNVfhPk",
                type: "video",
                source: "YouTube",
                tags: ["youtube", "video"]
            ),
            suggestedFolderId: "f-wtf-favorites",
            suggestedConfidence: 91,
            expectedAccepted: false
        ),
        .init(
            id: "ai-veto-parasite-health",
            name: "Veto movie trailer into Health",
            input: .init(
                title: "Parasite official movie trailer",
                description: "Bong Joon Ho film trailer and cast.",
                url: "https://youtube.com/watch?v=trailer",
                type: "video",
                source: "YouTube"
            ),
            suggestedFolderId: "f-health",
            suggestedConfidence: 84,
            expectedAccepted: false
        ),
        .init(
            id: "ai-veto-map-random",
            name: "Veto map pin into Everything Else",
            input: .init(
                title: "Google Maps pin for a tapas restaurant in Madrid",
                description: "Directions and reservation notes for the trip.",
                url: "https://maps.google.com/?q=tapas+madrid",
                type: "place",
                source: "Google Maps"
            ),
            suggestedFolderId: "f-random",
            suggestedConfidence: 74,
            expectedAccepted: false
        ),
        .init(
            id: "ai-veto-research-science",
            name: "Veto research PDF into Science Finds",
            input: .init(
                title: "arXiv paper: benchmark study for language models",
                description: "Abstract, methodology, citations, and appendix.",
                url: "https://arxiv.org/pdf/2501.00001.pdf",
                type: "file",
                source: "arXiv",
                fileName: "language-model-benchmark.pdf",
                mimeType: "application/pdf",
                tags: ["research"]
            ),
            suggestedFolderId: "f-wtf-favorites",
            suggestedConfidence: 76,
            expectedAccepted: false
        ),
        .init(
            id: "ai-accept-low-confidence-design",
            name: "Accept strong AI when local rules are weak",
            input: .init(
                title: "Beautiful onboarding motion examples",
                description: "Saved inspiration for app welcome animations.",
                url: "https://example.com/onboarding-motion-gallery",
                type: "link",
                source: "Web"
            ),
            suggestedFolderId: "f-design",
            suggestedConfidence: 86,
            expectedAccepted: true
        ),
        .init(
            id: "ai-veto-random-bucket",
            name: "Veto Everything Else as personality bucket",
            input: .init(
                title: "Sourdough focaccia recipe with garlic oil",
                description: "Ingredients, bake time, and meal prep notes.",
                url: "https://www.seriouseats.com/sourdough-focaccia",
                type: "article",
                source: "Serious Eats",
                tags: ["recipe", "bread"]
            ),
            suggestedFolderId: "f-random",
            suggestedConfidence: 88,
            expectedAccepted: false
        )
    ]

    private static let profiles: [Profile] = [
        .init(id: "f-life-admin", terms: weighted([
            ("life admin", 10), ("admin", 8), ("important", 5), ("door code", 10), ("access code", 10),
            ("wifi", 8), ("wi-fi", 8), ("guest code", 8), ("airbnb", 8), ("reservation", 7),
            ("confirmation number", 9), ("booking code", 8), ("itinerary", 6), ("contract", 9),
            ("template", 6), ("agreement", 7), ("license copy", 8), ("driver license copy", 8),
            ("insurance card", 8), ("policy", 6), ("certificate copy", 7), ("birth certificate copy", 7),
            ("receipt", 5), ("return receipt", 6), ("warranty", 6), ("serial number", 7),
            ("recovery code", 7), ("backup code", 7), ("long code", 6), ("document", 4),
            ("docx", 5), ("important document", 8), ("account recovery", 6)
        ])),
        .init(id: "f-recipes", terms: weighted([
            ("recipe", 9), ("recipes", 9), ("ingredients", 8), ("cook", 7), ("cooking", 7), ("bake", 7), ("kitchen", 6),
            ("food", 6), ("meal", 6), ("dinner", 6), ("lunch", 6), ("breakfast", 6), ("dessert", 6), ("pasta", 7),
            ("menu", 7), ("restaurant menu", 9), ("air fryer", 8), ("chef", 5), ("sauce", 5), ("soup", 5),
            ("salad", 5), ("tacos", 5), ("pizza", 5), ("chicken", 5), ("steak", 5), ("rice", 4), ("meal prep", 8),
            ("grocery", 6), ("groceries", 6), ("baking", 7), ("bread", 5), ("cocktail", 6), ("coffee", 5),
            ("allrecipes", 9), ("bon appetit", 8), ("smitten kitchen", 8), ("serious eats", 8), ("nytcooking", 8),
            ("marinade", 6), ("roast", 5), ("grill", 5), ("ferment", 6), ("sourdough", 7), ("vegan", 6), ("keto", 6)
        ])),
        .init(id: "f-travel", terms: weighted([
            ("map", 9), ("maps", 9), ("place", 8), ("restaurant", 7), ("hotel", 8), ("flight", 8), ("travel", 8),
            ("trip", 7), ("destination", 7), ("vacation", 7), ("museum", 6), ("cafe", 6), ("city guide", 8),
            ("beach", 5), ("google maps", 10), ("maps apple", 10), ("directions", 7), ("airbnb", 8), ("booking", 7),
            ("reservation", 6), ("itinerary", 8), ("passport", 4), ("visa", 5), ("airport", 7), ("train", 5),
            ("neighborhood", 5), ("things to do", 8), ("yelp", 7), ("tripadvisor", 8), ("lonely planet", 8),
            ("citymapper", 7), ("uber", 5), ("lyft", 5), ("venue", 6), ("bar", 5), ("bakery", 5), ("park", 5),
            ("exhibit", 5), ("gallery", 4), ("route", 6), ("stay", 5)
        ])),
        .init(id: "f-health", terms: weighted([
            ("health", 8), ("medical", 9), ("doctor", 8), ("medicine", 7), ("symptom", 7), ("symptoms", 7),
            ("infection", 7), ("disease", 7), ("wellness", 6), ("fitness", 7), ("workout", 7), ("sleep", 6),
            ("stress", 6), ("mental health", 9), ("nutrition", 7), ("protein", 6), ("hydration", 6), ("gut", 5),
            ("parasite", 10), ("parasites", 10), ("cleanse", 7), ("detox", 7), ("deworm", 10), ("deworming", 10),
            ("wormwood", 9), ("black walnut", 9), ("clove", 6), ("supplement", 7), ("vitamin", 7), ("mineral", 6),
            ("microbiome", 8), ("digestion", 7), ("inflammation", 7), ("immune", 7), ("hormone", 7), ("blood sugar", 8),
            ("therapy", 6), ("protocol", 5), ("recovery", 6), ("mobility", 6), ("cardio", 6), ("strength", 5),
            ("exercise", 7), ("meditation", 7), ("mindfulness", 7), ("anxiety", 7), ("adhd", 8), ("depression", 7),
            ("clinic", 7), ("blood pressure", 8), ("cholesterol", 7), ("glucose", 7), ("metabolism", 7), ("fasting", 6)
        ])),
        .init(id: "f-design", terms: weighted([
            ("design", 9), ("figma", 9), ("ui", 7), ("ux", 7), ("typography", 8), ("font", 7), ("layout", 7),
            ("brand", 6), ("branding", 8), ("palette", 7), ("visual", 6), ("interface", 7), ("poster", 5),
            ("dribbble", 8), ("behance", 8), ("inspiration", 5), ("logo", 8), ("icon", 7), ("mockup", 7),
            ("wireframe", 8), ("prototype", 7), ("component", 6), ("animation", 5), ("motion", 5), ("landing page", 6),
            ("fontshare", 8), ("typeface", 8), ("color palette", 8), ("moodboard", 8), ("aesthetic", 6), ("webflow", 6),
            ("framer", 6), ("tailwind", 5), ("material design", 8), ("human interface", 8), ("app icon", 8)
        ])),
        .init(id: "f-growth", terms: weighted([
            ("ai", 7), ("chatgpt", 9), ("claude", 9), ("llm", 8), ("prompt", 7), ("automation", 8), ("workflow", 7),
            ("productivity", 8), ("startup", 7), ("business", 6), ("career", 6), ("resume", 7), ("leadership", 6),
            ("networking", 6), ("software", 5), ("coding", 5), ("marketing", 6), ("sales", 6), ("growth", 8),
            ("founder", 7), ("saas", 7), ("nocode", 7), ("no code", 7), ("shortcut", 6), ("zapier", 7),
            ("notion", 5), ("spreadsheet", 5), ("template", 5), ("openai", 9), ("api", 6), ("agent", 7), ("agents", 7),
            ("coding assistant", 8), ("swift", 5), ("xcode", 5), ("python", 5), ("javascript", 5), ("automation script", 8),
            ("conversion", 6), ("funnel", 6), ("analytics", 5), ("seo", 6), ("newsletter growth", 8)
        ])),
        .init(id: "f-research", terms: weighted([
            ("research", 9), ("paper", 9), ("study", 8), ("arxiv", 10), ("journal", 8), ("report", 7), ("analysis", 6),
            ("technical", 6), ("dataset", 7), ("whitepaper", 8), ("science paper", 10), ("attention is all you need", 10),
            ("pdf", 4), ("thesis", 8), ("abstract", 7), ("citation", 7), ("clinical trial", 9), ("meta analysis", 9),
            ("case study", 7), ("benchmark", 7), ("paperwithcode", 9), ("pubmed", 9), ("doi", 8),
            ("nature", 6), ("science direct", 8), ("springer", 7), ("ieee", 8), ("acm", 7), ("jstor", 7),
            ("methodology", 7), ("appendix", 5), ("survey", 6), ("preprint", 8), ("hypothesis", 6), ("evidence", 5)
        ])),
        .init(id: "f-wtf-favorites", terms: weighted([
            ("science", 6), ("space", 7), ("astronomy", 7), ("nasa", 7), ("webb", 7), ("discovery", 7), ("wild", 6),
            ("mind blowing", 8), ("mind-blowing", 8), ("crazy", 5), ("unbelievable", 6), ("shocking", 5),
            ("mystery", 5), ("quantum", 6), ("experiment", 6), ("physics", 7), ("biology", 6), ("robotics", 6),
            ("fossil", 6), ("volcano", 5), ("deep sea", 6), ("ancient", 4), ("archaeology", 6), ("mars", 7),
            ("asteroid", 7), ("black hole", 8), ("dinosaur", 6), ("breakthrough", 6), ("engineering", 5), ("technology", 4)
        ])),
        .init(id: "f-tinfoil", terms: weighted([
            ("conspiracy", 9), ("ufo", 9), ("alien", 8), ("aliens", 8), ("cover up", 8), ("cover-up", 8),
            ("coverup", 8), ("area 51", 9), ("mkultra", 9), ("northwoods", 8), ("rabbit hole", 7),
            ("ancient egypt", 7), ("pyramid", 6), ("sphinx", 6), ("pentagon", 5), ("classified", 6),
            ("declassified", 6), ("secret program", 7), ("shadow government", 9), ("deep state", 8), ("psyop", 8),
            ("mandela effect", 8), ("simulation theory", 8), ("illuminati", 9), ("freemason", 7)
        ])),
        .init(id: "f-lmao", terms: weighted([
            ("meme", 9), ("memes", 9), ("funny", 8), ("comedy", 8), ("joke", 7), ("lmao", 8), ("lol", 6),
            ("viral", 5), ("laugh", 7), ("fail", 6), ("cursed", 6), ("rickroll", 9), ("keyboard cat", 9),
            ("dramatic chipmunk", 9), ("satire", 7), ("sketch", 6), ("standup", 7), ("stand up", 7), ("roast", 6),
            ("parody", 7), ("shitpost", 8), ("reaction", 5), ("prank", 6), ("silly", 5), ("absurd", 5),
            ("comic", 5), ("humor", 8), ("humour", 8), ("cringe", 6), ("chaos", 4)
        ])),
        .init(id: "f-paste-bin", terms: weighted([
            ("paste", 8), ("clipboard", 8), ("copied", 7), ("snippet", 7), ("note", 5), ("notes", 5),
            ("checklist", 6), ("draft", 5), ("todo", 5), ("to do", 5), ("text", 4), ("transcript", 5),
            ("outline", 5), ("meeting notes", 6), ("scratch", 5)
        ]), role: .utility),
        .init(id: "f-must-see", terms: weighted([
            ("watch", 7), ("trailer", 10), ("movie", 8), ("film", 8), ("episode", 7), ("clip", 6),
            ("documentary", 7), ("newsletter", 6), ("read later", 8), ("longform", 6), ("substack", 7),
            ("essay", 6), ("interview", 6), ("podcast", 7), ("lecture", 6), ("webinar", 6), ("screening", 7),
            ("streaming", 6), ("netflix", 7), ("hulu", 7), ("max", 5), ("disney plus", 7), ("letterboxd", 8)
        ]), role: .collection),
    ]

    private static func score(_ profile: Profile, normalized: NormalizedInput) -> Int {
        profile.terms.reduce(0) { partial, term in
            partial + weightedScore(for: term.value, normalized: normalized, baseWeight: term.weight)
        }
    }

    private static func weightedScore(for term: String, normalized: NormalizedInput, baseWeight: Int) -> Int {
        var score = 0
        if containsTerm(normalized.title, term) { score += baseWeight * 4 }
        if containsTerm(normalized.tags, term) { score += baseWeight * 4 }
        if containsTerm(normalized.fileName, term) { score += baseWeight * 3 }
        if containsTerm(normalized.url, term) { score += baseWeight * 2 }
        if containsTerm(normalized.source, term) { score += baseWeight * 2 }
        if containsTerm(normalized.type, term) { score += baseWeight * 2 }
        if containsTerm(normalized.mimeType, term) { score += baseWeight * 2 }
        if containsTerm(normalized.description, term) { score += baseWeight }
        return score
    }

    private static func shouldPreferPasteBin(_ input: SAVIFolderClassificationInput) -> Bool {
        let normalized = NormalizedInput(input)
        let isTextOnly = normalizedKey(input.type) == "text" && (input.url ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isClipboard = containsAny(normalized.source, ["paste", "clipboard"]) || containsAny(normalized.type, ["text", "plain text"])
        let looksLikeUtilityText = containsAny(normalized.all, ["prompt", "snippet", "checklist", "todo", "to do", "draft", "notes"]) ||
            regexMatch(#"\b(function|class|struct|import|const|let|var|select \*|curl|json|yaml|todo)\b"#, in: joinRaw(input))
        return isTextOnly && isClipboard && looksLikeUtilityText
    }

    private static func isPlace(_ input: SAVIFolderClassificationInput) -> Bool {
        let normalized = NormalizedInput(input)
        return normalizedKey(input.type) == "place" ||
            containsAny(normalized.url, ["maps google", "google com maps", "maps apple", "maps apple com"]) ||
            containsAny(normalized.all, ["map pin", "directions", "restaurant", "hotel"])
    }

    private static func isWatchable(_ input: SAVIFolderClassificationInput) -> Bool {
        let normalized = NormalizedInput(input)
        let type = normalizedKey(input.type)
        let hasWebURL = (input.url ?? "").trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("http")
        let webRead = hasWebURL && ["article", "link"].contains(type)
        return webRead ||
            containsAny(normalized.url, ["youtube", "youtu be", "vimeo", "tiktok"]) ||
            containsAny(normalized.source, ["youtube", "vimeo", "tiktok", "substack"]) ||
            containsAny(normalized.all, ["trailer", "movie", "film", "watch", "read later", "newsletter", "podcast", "episode"])
    }

    private static func isEntertainmentOrCasualVideo(_ input: SAVIFolderClassificationInput, normalized: NormalizedInput) -> Bool {
        let type = normalizedKey(input.type)
        let isVideo = type == "video" ||
            containsAny(normalized.url, ["youtube", "youtu be", "vimeo", "tiktok", "instagram", "reel"]) ||
            containsAny(normalized.source, ["youtube", "vimeo", "tiktok", "instagram"])
        guard isVideo else { return false }
        return isEntertainmentContext(normalized) ||
            containsAny(normalized.all, [
                "official video", "music video", "lyric video", "song", "single", "album", "clip",
                "trailer", "teaser", "reaction", "streaming", "watch"
            ])
    }

    private static func isDocumentLike(_ input: SAVIFolderClassificationInput) -> Bool {
        let normalized = NormalizedInput(input)
        return containsAny(normalized.type, ["file", "pdf", "image"]) ||
            containsAny(normalized.mimeType, ["application pdf", "image", "video", "text plain"])
    }

    private static func shouldUsePrivateGuardrail(_ input: SAVIFolderClassificationInput, normalized: NormalizedInput) -> Bool {
        let sensitive = isSensitive(input)
        let privateDocument = looksPrivateDocument(input)
        guard sensitive || privateDocument else { return false }

        if isEntertainmentContext(normalized), !hasHighRiskPrivateSignal(normalized) {
            return false
        }

        if sensitive,
           looksLikePublicSecurityGuide(normalized),
           !hasPersonalDocumentSignal(normalized),
           !hasHighRiskPrivateSignal(normalized) {
            return false
        }

        if privateDocument,
           looksLikePublicInfoGuide(normalized),
           !hasPersonalDocumentSignal(normalized),
           !hasHighRiskPrivateSignal(normalized) {
            return false
        }

        return true
    }

    private static func isEntertainmentContext(_ normalized: NormalizedInput) -> Bool {
        containsAny(normalized.all, [
            "official trailer", "teaser trailer", "movie", "film", "episode", "season", "series", "cinema",
            "box office", "cast", "streaming", "netflix", "hulu", "letterboxd", "disney plus", "watch trailer"
        ])
    }

    private static func hasHealthIntent(_ normalized: NormalizedInput) -> Bool {
        containsAny(normalized.all, [
            "health", "medical", "doctor", "symptom", "symptoms", "cleanse", "detox", "deworm",
            "supplement", "vitamin", "protocol", "wellness", "fitness", "infection", "disease",
            "digestion", "gut", "microbiome", "workout", "therapy", "nutrition"
        ])
    }

    private static func hasComedyIntent(_ normalized: NormalizedInput) -> Bool {
        containsAny(normalized.all, [
            "meme", "memes", "funny", "comedy", "joke", "lmao", "lol", "laugh", "parody",
            "satire", "sketch", "standup", "stand up", "rickroll", "shitpost", "cursed",
            "prank", "humor", "humour", "absurd"
        ])
    }

    private static func hasScienceIntent(_ normalized: NormalizedInput) -> Bool {
        if containsAny(normalized.all, ["science fiction", "sci fi", "sci-fi"]) &&
            !containsAny(normalized.all, scienceSpecificSignals) {
            return false
        }

        if containsAny(normalized.all, scienceSpecificSignals) {
            return true
        }

        if containsAny(normalized.title + normalized.description + normalized.tags + normalized.source, [
            "science", "scientific", "science news", "scientist", "scientists", "research discovery"
        ]) {
            return true
        }

        return false
    }

    private static let scienceSpecificSignals = [
        "astronomy", "asteroid", "biology", "black hole", "chemistry", "crispr", "deep sea",
        "dinosaur", "exoplanet", "experiment", "fossil", "genetics", "hubble", "jwst",
        "lab", "laboratory", "mars", "microbe", "microbiology", "nasa", "neuroscience",
        "physics", "planetary science", "quantum", "research discovery", "robotics", "science paper",
        "space", "spacecraft", "starship", "telescope", "universe", "volcano", "webb"
    ]

    private static let folderGuidanceById: [String: (use: String, avoid: String)] = [
        "f-life-admin": (
            use: "useful admin/reference items like door codes, Wi-Fi notes, reservation details, templates, contracts, receipts, certificates, non-secret account recovery notes, and practical life documents",
            avoid: "actual private IDs, banking, medical, tax, credentials, passwords, seed phrases, or sensitive scans that belong in Private Vault"
        ),
        "f-must-see": (
            use: "articles, videos, trailers, music videos, podcasts, essays, newsletters, and links to watch or read later",
            avoid: "private files, raw clipboard snippets, map pins, recipes, or obvious jokes"
        ),
        "f-paste-bin": (
            use: "copied text, prompts, snippets, checklists, drafts, transcripts, and scratch notes without a real destination",
            avoid: "normal links with useful metadata or finished documents"
        ),
        "f-wtf-favorites": (
            use: "real science, space, astronomy, research discoveries, engineering, nature, robotics, and lab findings",
            avoid: "sci-fi, trailers, music videos, movie news, or content that merely says crazy, secret, parasite, alien, or mystery"
        ),
        "f-growth": (
            use: "AI tools, prompts, automation, startups, business, coding, workflows, productivity, marketing, and career saves",
            avoid: "actual credentials, private tokens, or generic entertainment"
        ),
        "f-lmao": (
            use: "memes, jokes, comedy, parody, funny videos, internet classics, and obvious laugh saves",
            avoid: "normal music videos, trailers, articles, or serious news unless clearly comedic"
        ),
        "f-private-vault": (
            use: "credentials, IDs, receipts, tax, banking, insurance, medical, legal, personal scans, and sensitive private documents",
            avoid: "entertainment/news that uses words like secret, leaked, vault, alien, parasite, or password"
        ),
        "f-travel": (
            use: "map pins, places, restaurants, hotels, trips, directions, city guides, tickets, routes, and travel planning",
            avoid: "private IDs unless it is only a public travel guide"
        ),
        "f-recipes": (
            use: "recipes, ingredients, restaurants to try, cooking videos, meal prep, groceries, menus, and food ideas",
            avoid: "food science articles unless the intent is actually cooking/eating"
        ),
        "f-health": (
            use: "health, doctors, symptoms, supplements, workouts, nutrition, sleep, mental health, and wellness",
            avoid: "movies, trailers, memes, or entertainment that happens to mention parasites, disease, or bodies"
        ),
        "f-design": (
            use: "UI, UX, typography, app icons, branding, color palettes, design inspiration, Figma, mockups, and layouts",
            avoid: "general tech articles without a visual/design angle"
        ),
        "f-research": (
            use: "papers, PDFs, arXiv, studies, reports, citations, datasets, whitepapers, and deep technical references",
            avoid: "lightweight blog posts unless they are clearly research material"
        ),
        "f-tinfoil": (
            use: "conspiracy, UFO, declassified rabbit holes, shadow-government theories, Area 51, fringe mystery saves, and weird internet dives",
            avoid: "Alien or Parasite movie trailers, science fiction, fandom, or mainstream entertainment"
        ),
        "f-random": (
            use: "low-confidence leftovers when no folder clearly fits",
            avoid: "using it as a personality bucket or when any specific folder has a clear match"
        )
    ]

    private static func hasHighRiskPrivateSignal(_ normalized: NormalizedInput) -> Bool {
        containsAny(normalized.all, [
            "api secret", "auth token", "access token", "refresh token", "private key", "seed phrase",
            "recovery phrase", "social security", "ssn", "bank statement", "credit card", "debit card",
            "driver license", "driver s license", "w 2", "1099", "medical record", "lab result",
            "passport scan", "passport copy", "password manager export", "password vault export"
        ])
    }

    private static func looksLikePublicInfoGuide(_ normalized: NormalizedInput) -> Bool {
        containsAny(normalized.all, [
            "guide", "how to", "renew", "renewal", "requirements", "rules", "explained",
            "article", "news", "checklist", "what to know", "tips"
        ])
    }

    private static func looksLikePublicSecurityGuide(_ normalized: NormalizedInput) -> Bool {
        containsAny(normalized.all, [
            "guide", "how to", "tutorial", "docs", "documentation", "explained", "best practices",
            "setup", "set up", "configure", "security article", "password manager", "api docs",
            "developer documentation", "authentication docs"
        ])
    }

    private static func hasPersonalDocumentSignal(_ normalized: NormalizedInput) -> Bool {
        containsAny(normalized.all, [
            "scan", "scanned", "copy", "photo", "front back", "attachment", "uploaded",
            "my passport", "my license", "my insurance", "my bank", "my taxes", "statement",
            "receipt", "paystub", "pay stub", "record", "results"
        ]) || containsAny(normalized.type, ["file", "pdf", "image"]) ||
            containsAny(normalized.mimeType, ["application pdf", "image"])
    }

    private static func normalizedFolders(_ folders: [SAVIFolderOption]) -> [SAVIFolderOption] {
        let filtered = folders.filter { $0.id != allItemsFolderId }
        return filtered.isEmpty ? defaultFolderOptions : filtered
    }

    private static func firstAllowed(_ preferred: String, allowedIds: Set<String>) -> String {
        if allowedIds.contains(preferred) { return preferred }
        if allowedIds.contains(fallbackFolderId) { return fallbackFolderId }
        return allowedIds.first ?? fallbackFolderId
    }

    private static func weighted(_ values: [(String, Int)]) -> [WeightedTerm] {
        values.map { WeightedTerm(value: $0.0, weight: $0.1) }
    }

    private static func folderTokens(_ value: String) -> [String] {
        normalize(value)
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count >= 3 && !["folder", "saves", "stuff", "later", "club"].contains($0) }
    }

    private static func learnablePhrases(from text: String, singleWeight: Int, phraseWeight: Int, source: String) -> [(phrase: String, weight: Int, source: String)] {
        let tokens = normalizedKey(text)
            .split(separator: " ")
            .map(String.init)
            .filter(isLearnableToken)

        var phrases: [(phrase: String, weight: Int, source: String)] = tokens.prefix(8).map { ($0, singleWeight, source) }
        if tokens.count >= 2 {
            for index in 0..<(tokens.count - 1) {
                let phrase = "\(tokens[index]) \(tokens[index + 1])"
                if isLearnablePhrase(phrase) {
                    phrases.append((phrase, phraseWeight, source))
                }
                if phrases.count >= 14 { break }
            }
        }
        return phrases
    }

    private static func learnableHost(from urlString: String?) -> String? {
        guard let urlString,
              let url = URL(string: urlString),
              let host = url.host?.lowercased()
        else {
            return nil
        }

        let normalizedHost = host
            .replacingOccurrences(of: "www.", with: "")
            .replacingOccurrences(of: ".", with: " ")
        let broadHosts = [
            "youtube", "youtu be", "tiktok", "instagram", "facebook", "reddit", "x com", "twitter",
            "google", "apple", "icloud", "dropbox", "drive google", "docs google", "notion"
        ]
        guard !containsAny(normalize(normalizedHost), broadHosts) else { return nil }
        return normalizedHost
    }

    private static func isLearnablePhrase(_ phrase: String) -> Bool {
        let cleaned = normalizedKey(phrase)
        guard !cleaned.isEmpty else { return false }
        let parts = cleaned.split(separator: " ").map(String.init)
        return parts.contains(where: isLearnableToken)
    }

    private static func isLearnableToken(_ token: String) -> Bool {
        if ["ai", "ui", "ux", "llm", "pdf", "api", "seo", "adhd"].contains(token) { return true }
        guard token.count >= 4 else { return false }
        return !learningStopWords.contains(token)
    }

    private static func learningSignalId(folderId: String, phrase: String, source: String) -> String {
        let phraseKey = normalizedKey(phrase).replacingOccurrences(of: " ", with: "-")
        let sourceKey = normalizedKey(source).replacingOccurrences(of: " ", with: "-")
        return "\(folderId)-\(sourceKey)-\(phraseKey)"
    }

    private static let learningStopWords: Set<String> = [
        "about", "after", "again", "all", "also", "and", "any", "are", "article", "before", "best", "can",
        "could", "day", "file", "from", "full", "good", "great", "have", "here", "how", "into", "later",
        "link", "more", "new", "news", "now", "only", "page", "part", "post", "read", "save", "saved",
        "share", "shared", "should", "some", "that", "the", "their", "there", "these", "thing", "things",
        "this", "those", "time", "title", "video", "watch", "what", "when", "where", "with", "would",
        "youtube", "tiktok", "instagram", "reddit", "twitter"
    ]

    private static func containsAny(_ haystack: String, _ terms: [String]) -> Bool {
        terms.contains { containsTerm(haystack, $0) }
    }

    private static func containsTerm(_ haystack: String, _ rawTerm: String) -> Bool {
        let term = normalizedKey(rawTerm)
        guard !term.isEmpty else { return false }
        return haystack.contains(" \(term) ")
    }

    private static func normalize(_ value: String?) -> String {
        let lower = (value ?? "").lowercased()
        let replaced = lower.replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
        return " " + replaced.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines) + " "
    }

    private static func normalizedKey(_ value: String?) -> String {
        normalize(value).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func joinRaw(_ input: SAVIFolderClassificationInput) -> String {
        [
            input.title,
            input.description,
            input.url ?? "",
            input.type,
            input.source,
            input.fileName ?? "",
            input.mimeType ?? "",
            input.tags.joined(separator: " ")
        ].joined(separator: " ")
    }

    private static func regexMatch(_ pattern: String, in text: String) -> Bool {
        text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
