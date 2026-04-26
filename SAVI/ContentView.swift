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
#if canImport(FoundationModels)
import FoundationModels
#endif

struct ContentView: View {
    @StateObject private var store = SaviStore()

    var body: some View {
        ZStack {
            NativeSaviRootView()
                .environmentObject(store)

            if store.shouldRunLegacyMigration {
                LegacyMigrationHost { payload in
                    Task { await store.finishLegacyMigration(payload) }
                }
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityHidden(true)
            }
        }
        .saviRoundedFontDesign()
        .preferredColorScheme(store.prefs.themeMode == "light" ? .light : .dark)
        .task {
            await store.bootstrap()
        }
    }
}

// MARK: - Models

enum SaviTab: Hashable {
    case home
    case search
    case explore
    case folders
    case profile
}

enum SearchFacet: String, CaseIterable, Identifiable {
    case type
    case keeper
    case tag
    case source

    var id: String { rawValue }

    var title: String {
        switch self {
        case .type: return "Type"
        case .keeper: return "Keeper"
        case .tag: return "Tags"
        case .source: return "Source"
        }
    }

    var symbolName: String {
        switch self {
        case .type: return "square.stack.3d.up.fill"
        case .keeper: return "folder.fill"
        case .tag: return "number"
        case .source: return "square.and.arrow.down"
        }
    }
}

enum SearchDateFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All time"
        case .today: return "Today"
        case .week: return "This week"
        case .month: return "This month"
        }
    }

    var symbolName: String {
        switch self {
        case .all: return "clock"
        case .today: return "sun.max.fill"
        case .week: return "calendar"
        case .month: return "calendar.badge.clock"
        }
    }
}

enum SearchHasFilter: String, CaseIterable, Identifiable {
    case all
    case file
    case image
    case link
    case location
    case note

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Anything"
        case .file: return "File"
        case .image: return "Image"
        case .link: return "Link"
        case .location: return "Location"
        case .note: return "Note"
        }
    }

    var symbolName: String {
        switch self {
        case .all: return "sparkles"
        case .file: return "doc.fill"
        case .image: return "photo.fill"
        case .link: return "link"
        case .location: return "mappin.and.ellipse"
        case .note: return "text.alignleft"
        }
    }
}

enum SaviFolderViewMode: String, CaseIterable, Identifiable {
    case grid
    case list

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grid: return "Grid"
        case .list: return "List"
        }
    }

    var symbolName: String {
        switch self {
        case .grid: return "square.grid.2x2.fill"
        case .list: return "list.bullet"
        }
    }
}

enum SaviCoachStep: String, CaseIterable, Identifiable {
    case home
    case add
    case share
    case search
    case explore
    case folders
    case profile

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .home: return "house.fill"
        case .add: return "plus.circle.fill"
        case .share: return "square.and.arrow.down"
        case .search: return "magnifyingglass"
        case .explore: return "sparkles"
        case .folders: return "folder.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }

    var eyebrow: String {
        switch self {
        case .home: return "Home"
        case .add: return "Add"
        case .share: return "Share Sheet"
        case .search: return "Search"
        case .explore: return "Explore"
        case .folders: return "Keepers"
        case .profile: return "Profile"
        }
    }

    var title: String {
        switch self {
        case .home: return "Your launch pad"
        case .add: return "Use the plus"
        case .share: return "Save from anywhere"
        case .search: return "Find a specific save"
        case .explore: return "Browse when curious"
        case .folders: return "Keepers are your stacks"
        case .profile: return "Your control room"
        }
    }

    var message: String {
        switch self {
        case .home:
            return "Home is the front door: recent Keepers, newest saves, and the quickest path back into your archive."
        case .add:
            return "Tap the plus for links, notes, images, PDFs, files, or whatever is waiting on your clipboard."
        case .share:
            return "In Safari, Photos, Files, YouTube, or another app, tap the iOS Share button and choose SAVI. It saves first, then fills in the details it can."
        case .search:
            return "Use Search when you remember a word, source, file name, tag, content type, or Keeper."
        case .explore:
            return "Explore is a shuffled mosaic for rediscovery: links, videos, images, and places you saved but might have forgotten."
        case .folders:
            return "Keepers are your main stacks. Drag them into the order you like; that same order appears when you save from the share sheet."
        case .profile:
            return "Backups, theme, local learning, cleanup, and this tour live here when you need to tune SAVI."
        }
    }

    var targetHint: String {
        switch self {
        case .home: return "Start with Recent Keepers and Recent Saves."
        case .add: return "Look for the chartreuse + in the bottom bar."
        case .share: return "Look for the iOS Share icon, then pick SAVI."
        case .search: return "Use the Search tab and the chips under the search bar."
        case .explore: return "Tap Explore when you want a random scroll."
        case .folders: return "Long-press a card or tap rearrange to drag Keepers."
        case .profile: return "Replay this from the Guide card any time."
        }
    }

    var hintSymbolName: String {
        switch self {
        case .home: return "clock.arrow.circlepath"
        case .add: return "plus.circle.fill"
        case .share: return "square.and.arrow.up"
        case .search: return "line.3.horizontal.decrease.circle"
        case .explore: return "shuffle"
        case .folders: return "hand.point.up.left.fill"
        case .profile: return "questionmark.circle.fill"
        }
    }

    var tab: SaviTab {
        switch self {
        case .home, .add, .share: return .home
        case .search: return .search
        case .explore: return .explore
        case .folders: return .folders
        case .profile: return .profile
        }
    }
}

struct SaviSearchKind: Identifiable, Equatable {
    let id: String
    let title: String
    let symbolName: String

    static let all: [SaviSearchKind] = [
        .init(id: "all", title: "Everything", symbolName: "tray.full.fill"),
        .init(id: "link", title: "Links", symbolName: "link"),
        .init(id: "article", title: "Articles", symbolName: "newspaper.fill"),
        .init(id: "video", title: "Videos", symbolName: "play.rectangle.fill"),
        .init(id: "image", title: "Images", symbolName: "photo.fill"),
        .init(id: "screenshot", title: "Screenshots", symbolName: "iphone.gen3"),
        .init(id: "docs", title: "Docs", symbolName: "doc.on.doc.fill"),
        .init(id: "pdf", title: "PDFs", symbolName: "doc.richtext.fill"),
        .init(id: "document", title: "Documents", symbolName: "doc.fill"),
        .init(id: "note", title: "Notes", symbolName: "text.alignleft"),
        .init(id: "place", title: "Places", symbolName: "mappin.and.ellipse")
    ]

    static let visibleRail: [SaviSearchKind] = [
        .init(id: "all", title: "All", symbolName: "tray.full.fill"),
        .init(id: "video", title: "Videos", symbolName: "play.rectangle.fill"),
        .init(id: "image", title: "Images", symbolName: "photo.fill"),
        .init(id: "pdf", title: "PDFs", symbolName: "doc.richtext.fill"),
        .init(id: "docs", title: "Docs", symbolName: "doc.on.doc.fill"),
        .init(id: "place", title: "Places", symbolName: "mappin.and.ellipse"),
        .init(id: "link", title: "Links", symbolName: "link")
    ]
}

enum SaviItemType: String, Codable, CaseIterable, Identifiable {
    case article
    case video
    case image
    case file
    case text
    case place
    case link

    var id: String { rawValue }

    var label: String {
        switch self {
        case .article: return "Article"
        case .video: return "Video"
        case .image: return "Image"
        case .file: return "File"
        case .text: return "Text"
        case .place: return "Place"
        case .link: return "Link"
        }
    }

    var symbolName: String {
        switch self {
        case .article: return "newspaper.fill"
        case .video: return "play.circle.fill"
        case .image: return "photo.fill"
        case .file: return "doc.fill"
        case .text: return "text.alignleft"
        case .place: return "mappin.and.ellipse"
        case .link: return "link"
        }
    }
}

extension SaviItem {
    var readableSource: String? {
        let label = SaviText.sourceLabel(for: url ?? "", fallback: source)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty else { return nil }
        let generic = ["web", "savi", "share extension", "link"]
        return generic.contains(label.lowercased()) ? nil : label
    }
}

enum ExploreScope: String, CaseIterable, Identifiable {
    case all
    case mine
    case friends

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .mine: return "Mine"
        case .friends: return "Friends"
        }
    }

    var symbolName: String {
        switch self {
        case .all: return "sparkles"
        case .mine: return "bookmark.fill"
        case .friends: return "person.2.fill"
        }
    }
}

struct SaviFolder: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var color: String
    var image: String?
    var system: Bool
    var symbolName: String
    var order: Int
    var locked: Bool
    var isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case image
        case system
        case symbolName = "symbol_name"
        case order
        case locked
        case isPublic
    }

    init(
        id: String,
        name: String,
        color: String,
        image: String?,
        system: Bool,
        symbolName: String,
        order: Int,
        locked: Bool = false,
        isPublic: Bool = false
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.image = image
        self.system = system
        self.symbolName = symbolName
        self.order = order
        self.locked = locked
        self.isPublic = locked || id == "f-private-vault" ? false : isPublic
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Keeper"
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#C4B5FD"
        image = try container.decodeIfPresent(String.self, forKey: .image)
        system = try container.decodeIfPresent(Bool.self, forKey: .system) ?? false
        symbolName = try container.decodeIfPresent(String.self, forKey: .symbolName) ?? SaviText.folderSymbolName(id: id, name: name, system: system)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? SaviSeeds.defaultOrder(for: id)
        locked = try container.decodeIfPresent(Bool.self, forKey: .locked) ?? (id == "f-private-vault")
        isPublic = locked || id == "f-private-vault" ? false : (try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? false)
    }
}

struct SaviItem: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var itemDescription: String
    var url: String?
    var source: String
    var type: SaviItemType
    var folderId: String
    var tags: [String]
    var thumbnail: String?
    var savedAt: Double
    var color: String?
    var assetId: String?
    var assetName: String?
    var assetMime: String?
    var assetSize: Int64?
    var demo: Bool?
    var width: Int?
    var height: Int?
    var thumbnailRetryCount: Int
    var thumbnailLastAttemptAt: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case itemDescription = "description"
        case url
        case source
        case type
        case folderId
        case tags
        case thumbnail
        case savedAt
        case color
        case assetId
        case assetName
        case assetMime
        case assetSize
        case demo
        case width
        case height
        case thumbnailRetryCount
        case thumbnailLastAttemptAt
    }

    init(
        id: String = UUID().uuidString,
        title: String,
        itemDescription: String = "",
        url: String? = nil,
        source: String = "SAVI",
        type: SaviItemType = .link,
        folderId: String,
        tags: [String] = [],
        thumbnail: String? = nil,
        savedAt: Double = Date().timeIntervalSince1970 * 1000,
        color: String? = nil,
        assetId: String? = nil,
        assetName: String? = nil,
        assetMime: String? = nil,
        assetSize: Int64? = nil,
        demo: Bool? = nil,
        width: Int? = nil,
        height: Int? = nil,
        thumbnailRetryCount: Int = 0,
        thumbnailLastAttemptAt: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.itemDescription = itemDescription
        self.url = url
        self.source = source
        self.type = type
        self.folderId = folderId
        self.tags = SaviText.dedupeTags(tags)
        self.thumbnail = thumbnail
        self.savedAt = savedAt
        self.color = color
        self.assetId = assetId
        self.assetName = assetName
        self.assetMime = assetMime
        self.assetSize = assetSize
        self.demo = demo
        self.width = width
        self.height = height
        self.thumbnailRetryCount = thumbnailRetryCount
        self.thumbnailLastAttemptAt = thumbnailLastAttemptAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Saved item"
        itemDescription = try container.decodeIfPresent(String.self, forKey: .itemDescription) ?? ""
        url = try container.decodeIfPresent(String.self, forKey: .url)
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? "SAVI"
        let rawType = try container.decodeIfPresent(String.self, forKey: .type) ?? "link"
        type = SaviItemType(rawValue: rawType) ?? .link
        folderId = try container.decodeIfPresent(String.self, forKey: .folderId) ?? "f-random"
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: .savedAt) {
            savedAt = doubleValue
        } else if let intValue = try? container.decodeIfPresent(Int.self, forKey: .savedAt) {
            savedAt = Double(intValue)
        } else {
            savedAt = Date().timeIntervalSince1970 * 1000
        }
        color = try container.decodeIfPresent(String.self, forKey: .color)
        assetId = try container.decodeIfPresent(String.self, forKey: .assetId)
        assetName = try container.decodeIfPresent(String.self, forKey: .assetName)
        assetMime = try container.decodeIfPresent(String.self, forKey: .assetMime)
        if let int64Value = try? container.decodeIfPresent(Int64.self, forKey: .assetSize) {
            assetSize = int64Value
        } else if let intValue = try? container.decodeIfPresent(Int.self, forKey: .assetSize) {
            assetSize = Int64(intValue)
        } else {
            assetSize = nil
        }
        demo = try container.decodeIfPresent(Bool.self, forKey: .demo)
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
        thumbnailRetryCount = try container.decodeIfPresent(Int.self, forKey: .thumbnailRetryCount) ?? 0
        thumbnailLastAttemptAt = try container.decodeIfPresent(Double.self, forKey: .thumbnailLastAttemptAt)
    }
}

struct SaviPrefs: Codable, Equatable {
    var viewMode: String = "list"
    var folderViewMode: String = "grid"
    var folderLayoutVersion: Int = 0
    var coachMarksVersion: Int = 0
    var themeMode: String = "dark"
    var onboarded: Bool = false
    var demoSuppressed: Bool = false
    var migrationComplete: Bool = false
    var legacySeedVersion: Int?
    var folderRepairVersion: Int = 0
    var searchTagRepairVersion: Int = 0
    var exploreSeed: Int = SaviPrefs.currentExploreDay()
    var exploreSeedDay: Int = SaviPrefs.currentExploreDay()
    var exploreScope: String = ExploreScope.all.rawValue
    var exploreSeenItemIds: [String] = []
    var likedFriendLinkIds: [String] = []
    var sampleFriendSeeded: Bool = false

    enum CodingKeys: String, CodingKey {
        case viewMode
        case folderViewMode
        case folderLayoutVersion
        case coachMarksVersion
        case themeMode
        case onboarded
        case demoSuppressed
        case migrationComplete
        case legacySeedVersion
        case folderRepairVersion
        case searchTagRepairVersion
        case exploreSeed
        case exploreSeedDay
        case exploreScope
        case exploreSeenItemIds
        case likedFriendLinkIds
        case sampleFriendSeeded
    }

    init() {}

    static func currentExploreDay() -> Int {
        Int(Date().timeIntervalSince1970 / 86_400)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        viewMode = try container.decodeIfPresent(String.self, forKey: .viewMode) ?? "list"
        folderViewMode = try container.decodeIfPresent(String.self, forKey: .folderViewMode) ?? "grid"
        folderLayoutVersion = try container.decodeIfPresent(Int.self, forKey: .folderLayoutVersion) ?? 0
        coachMarksVersion = try container.decodeIfPresent(Int.self, forKey: .coachMarksVersion) ?? 0
        themeMode = try container.decodeIfPresent(String.self, forKey: .themeMode) ?? "dark"
        onboarded = try container.decodeIfPresent(Bool.self, forKey: .onboarded) ?? false
        demoSuppressed = try container.decodeIfPresent(Bool.self, forKey: .demoSuppressed) ?? false
        migrationComplete = try container.decodeIfPresent(Bool.self, forKey: .migrationComplete) ?? false
        legacySeedVersion = try container.decodeIfPresent(Int.self, forKey: .legacySeedVersion)
        folderRepairVersion = try container.decodeIfPresent(Int.self, forKey: .folderRepairVersion) ?? 0
        searchTagRepairVersion = try container.decodeIfPresent(Int.self, forKey: .searchTagRepairVersion) ?? 0
        exploreSeed = try container.decodeIfPresent(Int.self, forKey: .exploreSeed) ?? Self.currentExploreDay()
        exploreSeedDay = try container.decodeIfPresent(Int.self, forKey: .exploreSeedDay) ?? Self.currentExploreDay()
        exploreScope = try container.decodeIfPresent(String.self, forKey: .exploreScope) ?? ExploreScope.all.rawValue
        exploreSeenItemIds = try container.decodeIfPresent([String].self, forKey: .exploreSeenItemIds) ?? []
        likedFriendLinkIds = try container.decodeIfPresent([String].self, forKey: .likedFriendLinkIds) ?? []
        sampleFriendSeeded = try container.decodeIfPresent(Bool.self, forKey: .sampleFriendSeeded) ?? false
    }
}

struct SaviAsset: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var type: String
    var size: Int64
    var fileName: String
    var createdAt: Double
}

struct SaviPublicProfile: Codable, Equatable {
    var userId: String
    var username: String
    var displayName: String
    var bio: String
    var avatarColor: String
    var isLinkSharingEnabled: Bool
    var updatedAt: Double

    static func makeDefault() -> SaviPublicProfile {
        let suffix = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6).lowercased()
        let username = "savi\(suffix)"
        return SaviPublicProfile(
            userId: UUID().uuidString,
            username: username,
            displayName: "SAVI Friend",
            bio: "",
            avatarColor: "#C4B5FD",
            isLinkSharingEnabled: false,
            updatedAt: Date().timeIntervalSince1970 * 1000
        )
    }

    var normalizedUsername: String {
        SaviSocialText.normalizedUsername(username)
    }
}

struct SaviFriend: Codable, Identifiable, Equatable {
    var id: String
    var username: String
    var displayName: String
    var avatarColor: String
    var addedAt: Double
    var lastSeenAt: Double?

    var normalizedUsername: String {
        SaviSocialText.normalizedUsername(username)
    }
}

struct SaviSharedLink: Codable, Identifiable, Equatable {
    var id: String
    var ownerUserId: String
    var ownerUsername: String
    var ownerDisplayName: String
    var title: String
    var itemDescription: String
    var url: String
    var source: String
    var type: SaviItemType
    var keeperId: String
    var keeperName: String
    var tags: [String]
    var thumbnail: String?
    var savedAt: Double
    var sharedAt: Double

    func asExploreItem() -> SaviItem {
        SaviItem(
            id: "friend-\(id)",
            title: title,
            itemDescription: itemDescription,
            url: url,
            source: "@\(ownerUsername) · \(source)",
            type: type,
            folderId: "f-friends",
            tags: SaviText.dedupeTags(["friend", ownerUsername, keeperName] + tags),
            thumbnail: thumbnail,
            savedAt: savedAt,
            color: "#C4B5FD"
        )
    }
}

struct SaviFriendKeeperSummary: Identifiable, Equatable {
    var id: String
    var name: String
    var count: Int
    var latestSharedAt: Double
}

enum SaviSocialText {
    static func normalizedUsername(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "." }
    }
}

struct SaviLibraryState: Codable {
    var version: Int
    var folders: [SaviFolder]
    var items: [SaviItem]
    var assets: [SaviAsset]
    var prefs: SaviPrefs
    var publicProfile: SaviPublicProfile?
    var friends: [SaviFriend]?
    var friendLinks: [SaviSharedLink]?
}

struct SaviBackup: Codable {
    var app: String
    var version: Int
    var exportedAt: String
    var folders: [SaviFolder]
    var items: [SaviItem]
    var assets: [SaviBackupAsset]
    var folderLearning: [SAVIFolderLearningSignal]?
}

struct SaviBackupAsset: Codable, Identifiable {
    var id: String
    var name: String
    var type: String
    var size: Int64
    var dataUrl: String
}

struct LegacyMigrationPayload {
    var storageJSON: String?
    var seedStorageJSON: String?
    var uiPrefsJSON: String?
    var onboarded: Bool
    var demoSuppressed: Bool
    var assets: [SaviBackupAsset]
    var error: String?
}

private struct LegacyStoredState: Codable {
    var folders: [SaviFolder]?
    var items: [SaviItem]?
}

private struct LegacyUiPrefs: Codable {
    var viewMode: String?
    var themeMode: String?
}

struct SaviBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - CloudKit Social Sync

final class SaviCloudKitService {
    static let containerIdentifier = "iCloud.com.savi.app"

    private let container = CKContainer(identifier: SaviCloudKitService.containerIdentifier)
    private var database: CKDatabase { container.publicCloudDatabase }

    func accountStatusText() async -> String {
        await withCheckedContinuation { continuation in
            container.accountStatus { status, _ in
                switch status {
                case .available:
                    continuation.resume(returning: "iCloud ready")
                case .noAccount:
                    continuation.resume(returning: "Sign in to iCloud")
                case .restricted:
                    continuation.resume(returning: "iCloud restricted")
                case .couldNotDetermine:
                    continuation.resume(returning: "iCloud unavailable")
                case .temporarilyUnavailable:
                    continuation.resume(returning: "iCloud warming up")
                @unknown default:
                    continuation.resume(returning: "iCloud unknown")
                }
            }
        }
    }

    func saveProfile(_ profile: SaviPublicProfile) async throws {
        let username = profile.normalizedUsername
        guard !username.isEmpty else { return }
        let recordID = CKRecord.ID(recordName: "profile-\(username)")
        let record = try await fetchRecord(id: recordID) ?? CKRecord(recordType: "SaviPublicProfile", recordID: recordID)
        record["userId"] = profile.userId as CKRecordValue
        record["username"] = username as CKRecordValue
        record["displayName"] = profile.displayName as CKRecordValue
        record["bio"] = profile.bio as CKRecordValue
        record["avatarColor"] = profile.avatarColor as CKRecordValue
        record["updatedAt"] = profile.updatedAt as CKRecordValue
        _ = try await saveRecord(record)
    }

    func publishSharedLinks(_ links: [SaviSharedLink]) async throws {
        for link in links {
            try await saveSharedLink(link)
        }
    }

    func fetchSharedLinks(friendUsernames: [String]) async throws -> [SaviSharedLink] {
        let usernames = friendUsernames.map(SaviSocialText.normalizedUsername).filter { !$0.isEmpty }
        guard !usernames.isEmpty else { return [] }
        let predicate = NSPredicate(format: "ownerUsername IN %@", usernames)
        let query = CKQuery(recordType: "SaviSharedLink", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "sharedAt", ascending: false)]
        let records = try await performQuery(query, limit: 80)
        return records.compactMap(SaviSharedLink.init(record:))
    }

    private func saveSharedLink(_ link: SaviSharedLink) async throws {
        let recordID = CKRecord.ID(recordName: "link-\(link.id)")
        let record = try await fetchRecord(id: recordID) ?? CKRecord(recordType: "SaviSharedLink", recordID: recordID)
        record["ownerUserId"] = link.ownerUserId as CKRecordValue
        record["ownerUsername"] = link.ownerUsername as CKRecordValue
        record["ownerDisplayName"] = link.ownerDisplayName as CKRecordValue
        record["title"] = link.title as CKRecordValue
        record["itemDescription"] = link.itemDescription as CKRecordValue
        record["url"] = link.url as CKRecordValue
        record["source"] = link.source as CKRecordValue
        record["type"] = link.type.rawValue as CKRecordValue
        record["keeperId"] = link.keeperId as CKRecordValue
        record["keeperName"] = link.keeperName as CKRecordValue
        record["tags"] = link.tags as NSArray
        record["savedAt"] = link.savedAt as CKRecordValue
        record["sharedAt"] = link.sharedAt as CKRecordValue
        if let thumbnail = link.thumbnail?.nilIfBlank {
            record["thumbnail"] = thumbnail as CKRecordValue
        } else {
            record["thumbnail"] = nil
        }
        _ = try await saveRecord(record)
    }

    private func fetchRecord(id: CKRecord.ID) async throws -> CKRecord? {
        try await withCheckedThrowingContinuation { continuation in
            database.fetch(withRecordID: id) { record, error in
                if let ckError = error as? CKError, ckError.code == .unknownItem {
                    continuation.resume(returning: nil)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: record)
                }
            }
        }
    }

    private func saveRecord(_ record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            database.save(record) { savedRecord, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let savedRecord {
                    continuation.resume(returning: savedRecord)
                } else {
                    continuation.resume(throwing: CKError(.internalError))
                }
            }
        }
    }

    private func performQuery(_ query: CKQuery, limit: Int) async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { continuation in
            var records: [CKRecord] = []
            let operation = CKQueryOperation(query: query)
            operation.resultsLimit = limit
            operation.recordMatchedBlock = { _, result in
                if case .success(let record) = result {
                    records.append(record)
                }
            }
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: records)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            self.database.add(operation)
        }
    }
}

extension SaviSharedLink {
    init?(record: CKRecord) {
        guard let ownerUserId = record["ownerUserId"] as? String,
              let ownerUsername = record["ownerUsername"] as? String,
              let title = record["title"] as? String,
              let url = record["url"] as? String
        else { return nil }

        let rawType = record["type"] as? String ?? SaviItemType.link.rawValue
        self.init(
            id: record.recordID.recordName.replacingOccurrences(of: "link-", with: ""),
            ownerUserId: ownerUserId,
            ownerUsername: ownerUsername,
            ownerDisplayName: record["ownerDisplayName"] as? String ?? ownerUsername,
            title: title,
            itemDescription: record["itemDescription"] as? String ?? "",
            url: url,
            source: record["source"] as? String ?? "Web",
            type: SaviItemType(rawValue: rawType) ?? .link,
            keeperId: record["keeperId"] as? String ?? "",
            keeperName: record["keeperName"] as? String ?? "Shared",
            tags: (record["tags"] as? [String]) ?? [],
            thumbnail: record["thumbnail"] as? String,
            savedAt: record["savedAt"] as? Double ?? Date().timeIntervalSince1970 * 1000,
            sharedAt: record["sharedAt"] as? Double ?? Date().timeIntervalSince1970 * 1000
        )
    }
}

// MARK: - Store

@MainActor
final class SaviStore: ObservableObject {
    @Published var folders: [SaviFolder]
    @Published var items: [SaviItem]
    @Published var assets: [SaviAsset]
    @Published var prefs: SaviPrefs
    @Published var selectedTab: SaviTab = .home
    @Published var previousTab: SaviTab = .home
    @Published var activeCoachStep: SaviCoachStep?
    @Published var exploreSeed = SaviPrefs.currentExploreDay()
    @Published var exploreScope: ExploreScope = .all
    @Published var query = ""
    @Published var folderFilter = "f-all"
    @Published var typeFilter = "all"
    @Published var sourceFilter = "all"
    @Published var tagFilter = "all"
    @Published var dateFilter = SearchDateFilter.all.rawValue
    @Published var hasFilter = SearchHasFilter.all.rawValue
    @Published var presentedSheet: SaviSheet?
    @Published var activeSearchFacet: SearchFacet?
    @Published var isSearchRefinePresented = false
    @Published var presentedItem: SaviItem?
    @Published var editingItem: SaviItem?
    @Published var editingFolder: SaviFolder?
    @Published var quickLookAssetURL: URL?
    @Published var webPreviewURL: URL?
    @Published var toast: String?
    @Published var migrationMessage: String?
    @Published var backupDocument: SaviBackupDocument?
    @Published var isExportingBackup = false
    @Published var publicProfile: SaviPublicProfile
    @Published var friends: [SaviFriend]
    @Published var friendLinks: [SaviSharedLink]
    @Published var cloudKitStatus = "Checking iCloud"
    @Published var socialSyncMessage: String?
    @Published var isSocialSyncing = false
    @Published var folderAuditReport: SAVIFolderAuditReport?
    @Published var appleIntelligenceStatus = "Checking"
    @Published private(set) var isNetworkReachable = true
    @Published private(set) var folderDecisionHistory: [SAVIFolderDecisionRecord] = []
    @Published private var unlockedProtectedKeeperIds = Set<String>()

    private let storage = SaviStorage()
    private let metadataService = SaviMetadataService()
    private let intelligenceService = SaviAppleIntelligenceService()
    private let cloudKitService = SaviCloudKitService()
    private let shareStore = PendingShareStore.shared
    private let networkMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "SAVI.NetworkMonitor")
    private var didBootstrap = false
    private var importedShareIds = Set<String>()
    private var intelligenceRefinementIds = Set<String>()
    private var autoFolderItemIds = Set<String>()
    private var scheduledThumbnailRetryIds = Set<String>()
    private var folderLearningSignals: [SAVIFolderLearningSignal] = []
    private static let thumbnailRetryDelays: [TimeInterval] = [0, 30, 60, 180, 600, 1_800, 3_600]
    private static let thumbnailLogoFallbackAttempts = 3
    private static let thumbnailLogoFallbackGrace: TimeInterval = 180
    private static let sampleFriendTargetLinkCount = 24
    private static let currentLegacySeedVersion = 2
    private static let currentFolderRepairVersion = 2
    private static let currentSearchTagRepairVersion = 1
    private static let currentFolderLayoutVersion = 1
    private static let currentCoachMarksVersion = 1

    var shouldRunLegacyMigration: Bool {
        !prefs.migrationComplete || shouldRefreshLegacySeeds
    }

    private var shouldRefreshLegacySeeds: Bool {
        guard prefs.migrationComplete,
              !prefs.demoSuppressed,
              (prefs.legacySeedVersion ?? 0) < Self.currentLegacySeedVersion
        else { return false }
        return items.contains { $0.demo == true } || items.count <= SaviSeeds.items.count
    }

    init() {
        let loaded = try? storage.loadLibrary()
        let seedFolders = SaviSeeds.folders
        var loadedPrefs = loaded?.prefs ?? SaviPrefs()
        let shouldUpgradeFolderLayout = loadedPrefs.folderLayoutVersion < Self.currentFolderLayoutVersion
        if shouldUpgradeFolderLayout {
            loadedPrefs.folderViewMode = SaviFolderViewMode.grid.rawValue
            loadedPrefs.folderLayoutVersion = Self.currentFolderLayoutVersion
        }
        let today = SaviPrefs.currentExploreDay()
        let shouldPersistExploreSeedReset = loadedPrefs.exploreSeedDay != today
        if loadedPrefs.exploreSeedDay != today {
            loadedPrefs.exploreSeedDay = today
            loadedPrefs.exploreSeed = today
        }
        self.folders = SaviSeeds.withSeedDefaults(loaded?.folders ?? seedFolders)
        self.items = loaded?.items ?? SaviSeeds.items
        self.assets = loaded?.assets ?? []
        self.prefs = loadedPrefs
        self.publicProfile = loaded?.publicProfile ?? SaviPublicProfile.makeDefault()
        self.friends = loaded?.friends ?? []
        self.friendLinks = loaded?.friendLinks ?? []
        self.exploreSeed = loadedPrefs.exploreSeed
        self.exploreScope = ExploreScope(rawValue: loadedPrefs.exploreScope) ?? .all
        self.folderLearningSignals = shareStore.loadFolderLearning()
        self.folderDecisionHistory = shareStore.loadFolderDecisions()
        syncFoldersToShareExtension()
        startNetworkMonitoring()
        runFolderAudit(showToast: false)
        if shouldPersistExploreSeedReset || shouldUpgradeFolderLayout {
            persist()
        }
    }

    deinit {
        networkMonitor.cancel()
    }

    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                let reachable = path.status == .satisfied
                let becameReachable = reachable && self?.isNetworkReachable == false
                self?.isNetworkReachable = reachable
                if becameReachable {
                    await self?.refreshStaleMetadata()
                }
            }
        }
        networkMonitor.start(queue: networkMonitorQueue)
    }

    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        await importPendingShares()
        refreshFolderDecisionHistory()
        repairObviousGenericFolderAssignmentsIfNeeded()
        repairSearchTagsIfNeeded()
        await refreshStaleMetadata()
        await refreshAppleIntelligenceStatus()
        await refreshCloudKitStatus()
#if targetEnvironment(simulator)
        let avaLinkCount = friendLinks.filter { SaviSocialText.normalizedUsername($0.ownerUsername) == "ava" }.count
        if !prefs.sampleFriendSeeded || avaLinkCount < Self.sampleFriendTargetLinkCount {
            loadSampleFriend(showToast: false)
        }
#endif
        if publicProfile.isLinkSharingEnabled || !friends.isEmpty {
            await syncSocialLinks()
        }
    }

    func persist() {
        let state = SaviLibraryState(
            version: 1,
            folders: folders,
            items: items,
            assets: assets,
            prefs: prefs,
            publicProfile: publicProfile,
            friends: friends,
            friendLinks: friendLinks
        )
        do {
            try storage.saveLibrary(state)
            syncFoldersToShareExtension()
        } catch {
            toast = "Could not save SAVI locally."
            NSLog("[SAVI Native] persist failed: \(error.localizedDescription)")
        }
    }

    func finishOnboarding() {
        prefs.onboarded = true
        persist()
        startCoachTour()
    }

    func setTheme(_ mode: String) {
        prefs.themeMode = mode
        persist()
    }

    func setFolderViewMode(_ mode: SaviFolderViewMode) {
        prefs.folderViewMode = mode.rawValue
        persist()
    }

    func orderedFoldersForDisplay() -> [SaviFolder] {
        folders.filter { $0.id != "f-all" }.sorted { lhs, rhs in
            if lhs.order == rhs.order { return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending }
            return lhs.order < rhs.order
        }
    }

    func reorderFolder(draggedId: String, over targetId: String) {
        guard draggedId != targetId else { return }
        var orderedIds = orderedFoldersForDisplay().map(\.id)
        guard let from = orderedIds.firstIndex(of: draggedId),
              let to = orderedIds.firstIndex(of: targetId)
        else { return }

        orderedIds.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        applyFolderOrder(orderedIds)
    }

    func finishFolderReordering() {
        applyFolderOrder(orderedFoldersForDisplay().map(\.id))
        persist()
    }

    func isProtectedKeeperUnlocked(_ folder: SaviFolder) -> Bool {
        !folder.locked || unlockedProtectedKeeperIds.contains(folder.id)
    }

    func openAddSheet() {
        selectedTab = previousTab
        presentedSheet = .save
    }

    func setTab(_ tab: SaviTab) {
        if tab == .home {
            resetFilters()
        }
        previousTab = tab
        selectedTab = tab
    }

    func startCoachTour() {
        presentedSheet = nil
        activeSearchFacet = nil
        presentedItem = nil
        editingItem = nil
        quickLookAssetURL = nil
        webPreviewURL = nil
        routeForCoachStep(.home)
        activeCoachStep = .home
    }

    func advanceCoachTour() {
        guard let activeCoachStep,
              let index = SaviCoachStep.allCases.firstIndex(of: activeCoachStep)
        else {
            startCoachTour()
            return
        }

        let nextIndex = SaviCoachStep.allCases.index(after: index)
        guard nextIndex < SaviCoachStep.allCases.endIndex else {
            completeCoachTour()
            return
        }

        let next = SaviCoachStep.allCases[nextIndex]
        routeForCoachStep(next)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            self.activeCoachStep = next
        }
    }

    func completeCoachTour() {
        activeCoachStep = nil
        prefs.coachMarksVersion = Self.currentCoachMarksVersion
        persist()
    }

    private func routeForCoachStep(_ step: SaviCoachStep) {
        presentedSheet = nil
        activeSearchFacet = nil
        setTab(step.tab)
    }

    func resetFilters() {
        query = ""
        folderFilter = "f-all"
        typeFilter = "all"
        sourceFilter = "all"
        tagFilter = "all"
        dateFilter = SearchDateFilter.all.rawValue
        hasFilter = SearchHasFilter.all.rawValue
    }

    func openFolder(_ folder: SaviFolder) {
        Task { await openProtectedFolderIfAllowed(folder) }
    }

    func selectFolderFilter(_ folder: SaviFolder) {
        Task {
            guard await unlockKeeperIfNeeded(folder) else { return }
            folderFilter = folder.id
            activeSearchFacet = nil
        }
    }

    func openSearchFacet(_ facet: SearchFacet) {
        activeSearchFacet = facet
    }

    func openSearchRefine() {
        isSearchRefinePresented = true
    }

    func clearSearchFacet(_ facet: SearchFacet) {
        switch facet {
        case .type:
            typeFilter = "all"
        case .keeper:
            folderFilter = "f-all"
        case .tag:
            tagFilter = "all"
        case .source:
            sourceFilter = "all"
        }
    }

    func clearDateFilter() {
        dateFilter = SearchDateFilter.all.rawValue
    }

    func clearHasFilter() {
        hasFilter = SearchHasFilter.all.rawValue
    }

    func clearRefineFilters() {
        folderFilter = "f-all"
        sourceFilter = "all"
        tagFilter = "all"
        dateFilter = SearchDateFilter.all.rawValue
        hasFilter = SearchHasFilter.all.rawValue
    }

    func openKeepersManagement() {
        activeSearchFacet = nil
        setTab(.folders)
    }

    private func openProtectedFolderIfAllowed(_ folder: SaviFolder) async {
        guard await unlockKeeperIfNeeded(folder) else { return }
        folderFilter = folder.id
        typeFilter = "all"
        sourceFilter = "all"
        tagFilter = "all"
        query = ""
        setTab(.search)
    }

    private func unlockKeeperIfNeeded(_ folder: SaviFolder) async -> Bool {
        guard folder.locked, !unlockedProtectedKeeperIds.contains(folder.id) else { return true }

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"
        let reason = "Unlock \(folder.name) in SAVI."
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            toast = "Turn on Face ID or a device passcode to unlock protected Keepers."
            return false
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                unlockedProtectedKeeperIds.insert(folder.id)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                return true
            }
        } catch {
            toast = "Keeper stayed locked."
        }
        return false
    }

    func lockProtectedKeepers() {
        guard !unlockedProtectedKeeperIds.isEmpty else { return }
        unlockedProtectedKeeperIds.removeAll()

        if let item = presentedItem, isItemInLockedKeeper(item) {
            presentedItem = nil
        }
        if let item = editingItem, isItemInLockedKeeper(item) {
            editingItem = nil
        }
        if let folder = folder(for: folderFilter), folder.locked {
            resetFilters()
        }
    }

    func openExplore() {
        setTab(.explore)
    }

    func shuffleExplore() {
        exploreSeed += 1
        prefs.exploreSeed = exploreSeed
        prefs.exploreSeedDay = SaviPrefs.currentExploreDay()
        persist()
        setTab(.explore)
    }

    func previewWebURL(_ url: URL) {
        webPreviewURL = url
    }

    func previewItemContent(_ item: SaviItem) {
        guard !isItemInLockedKeeper(item) else {
            if let folder = folder(for: item.folderId) {
                openFolder(folder)
            }
            return
        }
        markExploreSeen(item)
        if let previewURL = quickLookURL(for: item) {
            quickLookAssetURL = previewURL
            return
        }
        if let urlString = item.url?.nilIfBlank,
           let url = URL(string: urlString) {
            previewWebURL(url)
            return
        }
        presentedItem = item
    }

    private func visibleItemsForBrowsing() -> [SaviItem] {
        items.filter { !isItemInLockedKeeper($0) }
    }

    private func isItemInLockedKeeper(_ item: SaviItem) -> Bool {
        guard let folder = folder(for: item.folderId), folder.locked else { return false }
        return !unlockedProtectedKeeperIds.contains(folder.id)
    }

    func filteredItems(for tab: SaviTab? = nil) -> [SaviItem] {
        if tab == .home {
            return visibleItemsForBrowsing().sorted { $0.savedAt > $1.savedAt }
        }

        var result = visibleItemsForBrowsing()
        if folderFilter != "f-all" {
            result = result.filter { $0.folderId == folderFilter }
        }
        if typeFilter != "all" {
            result = result.filter { matchesSearchKind($0, kind: typeFilter) }
        }
        if sourceFilter != "all" {
            result = result.filter { sourceKey(for: $0) == sourceFilter }
        }
        if tagFilter != "all" {
            result = result.filter { item in
                item.tags.contains { $0.caseInsensitiveCompare(tagFilter) == .orderedSame }
            }
        }
        if dateFilter != SearchDateFilter.all.rawValue {
            result = result.filter { matchesDateFilter($0, filter: dateFilter) }
        }
        if hasFilter != SearchHasFilter.all.rawValue {
            result = result.filter { matchesHasFilter($0, filter: hasFilter) }
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let needles = normalizedSearchNeedles(from: trimmed)
            result = result.filter { item in
                let haystack = searchHaystack(for: item)
                return needles.allSatisfy { haystack.contains($0) }
            }
        }

        return result.sorted { $0.savedAt > $1.savedAt }
    }

    private func normalizedSearchNeedles(from query: String) -> [String] {
        query
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace || $0 == "," })
            .map { token in
                var value = String(token)
                while value.first == "#" {
                    value.removeFirst()
                }
                return value
            }
            .filter { !$0.isEmpty }
    }

    private func searchHaystack(for item: SaviItem) -> String {
        let folderName = folder(for: item.folderId)?.name ?? ""
        let extensionName = item.assetName.flatMap { name -> String? in
            let value = URL(fileURLWithPath: name).pathExtension
            return value.isEmpty ? nil : value
        } ?? ""
        var pieces = [
            item.title,
            item.itemDescription,
            item.url ?? "",
            item.source,
            sourceKey(for: item),
            sourceLabel(for: sourceKey(for: item)),
            item.type.rawValue,
            item.type.label,
            item.assetName ?? "",
            item.assetMime ?? "",
            extensionName,
            folderName,
            item.tags.joined(separator: " "),
            item.tags.map { "#\($0)" }.joined(separator: " ")
        ]

        if isPDF(item) {
            pieces.append("pdf document file")
        } else if item.type == .file {
            pieces.append("doc docs document file attachment")
        }
        if isScreenshot(item) {
            pieces.append("screenshot screen shot image")
        }

        return pieces.joined(separator: " ").lowercased()
    }

    var hasActiveSearchControls: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            folderFilter != "f-all" ||
            typeFilter != "all" ||
            sourceFilter != "all" ||
            tagFilter != "all" ||
            dateFilter != SearchDateFilter.all.rawValue ||
            hasFilter != SearchHasFilter.all.rawValue
    }

    var refineFilterCount: Int {
        [
            folderFilter != "f-all",
            sourceFilter != "all",
            tagFilter != "all",
            dateFilter != SearchDateFilter.all.rawValue,
            hasFilter != SearchHasFilter.all.rawValue
        ].filter { $0 }.count
    }

    func folder(for id: String) -> SaviFolder? {
        folders.first { $0.id == id }
    }

    func count(in folder: SaviFolder) -> Int {
        if folder.id == "f-all" { return visibleItemsForBrowsing().count }
        if folder.locked, !unlockedProtectedKeeperIds.contains(folder.id) { return 0 }
        return items.filter { $0.folderId == folder.id }.count
    }

    func homeFolders(limit: Int = 6) -> [SaviFolder] {
        let visibleFolders = folders.filter { $0.id != "f-all" }
        let latestByFolder = Dictionary(grouping: visibleItemsForBrowsing(), by: \.folderId)
            .mapValues { saves in saves.map(\.savedAt).max() ?? 0 }

        func sortedForHome(_ folders: [SaviFolder]) -> [SaviFolder] {
            folders.sorted { lhs, rhs in
                let leftLatest = latestByFolder[lhs.id] ?? 0
                let rightLatest = latestByFolder[rhs.id] ?? 0
                if leftLatest != rightLatest { return leftLatest > rightLatest }
                if lhs.order != rhs.order { return lhs.order < rhs.order }
                return lhs.name < rhs.name
            }
        }

        let primary = visibleFolders.filter { folder in
            folder.id != "f-private-vault" && folder.id != "f-paste-bin"
        }
        let utility = visibleFolders.filter { folder in
            folder.id == "f-private-vault" || folder.id == "f-paste-bin"
        }

        return Array((sortedForHome(primary) + sortedForHome(utility)).prefix(limit))
    }

    func refreshCloudKitStatus() async {
        cloudKitStatus = await cloudKitService.accountStatusText()
    }

    func updatePublicProfile(username: String, displayName: String, bio: String) {
        let normalized = SaviSocialText.normalizedUsername(username)
        guard !normalized.isEmpty else {
            toast = "Choose a username first."
            return
        }
        publicProfile.username = normalized
        publicProfile.displayName = displayName.nilIfBlank ?? normalized
        publicProfile.bio = bio
        publicProfile.updatedAt = Date().timeIntervalSince1970 * 1000
        persist()
        Task { await syncSocialLinks() }
    }

    func setLinkSharingEnabled(_ enabled: Bool) {
        publicProfile.isLinkSharingEnabled = enabled
        publicProfile.updatedAt = Date().timeIntervalSince1970 * 1000
        persist()
        Task { await syncSocialLinks() }
    }

    func addFriend(username rawUsername: String) {
        let username = SaviSocialText.normalizedUsername(rawUsername)
        guard !username.isEmpty else { return }
        guard username != publicProfile.normalizedUsername else {
            toast = "That is your SAVI profile."
            return
        }
        guard !friends.contains(where: { $0.normalizedUsername == username }) else {
            toast = "@\(username) is already in Friends."
            return
        }
        friends.append(
            SaviFriend(
                id: username,
                username: username,
                displayName: "@\(username)",
                avatarColor: "#C4B5FD",
                addedAt: Date().timeIntervalSince1970 * 1000
            )
        )
        persist()
        toast = "Added @\(username)."
        Task { await syncSocialLinks() }
    }

    func loadSampleFriend(showToast: Bool = true) {
        let now = Date().timeIntervalSince1970 * 1000
        let friend = SaviFriend(
            id: "ava",
            username: "ava",
            displayName: "Ava",
            avatarColor: "#D8FF3C",
            addedAt: now - 86_400_000,
            lastSeenAt: now - 900_000
        )

        if !friends.contains(where: { $0.id == friend.id }) {
            friends.insert(friend, at: 0)
        }

        func youtubeThumbnail(_ rawURL: String) -> String? {
            guard let url = URL(string: rawURL) else { return nil }
            return SaviText.youtubeThumbnailURL(for: url)
        }

        let samples: [SaviSharedLink] = [
            SaviSharedLink(
                id: "demo-ava-link-1",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "Why tiny rituals make apps feel personal",
                itemDescription: "A short design read about small product moments that make tools feel remembered.",
                url: "https://example.com/tiny-rituals",
                source: "Web",
                type: .article,
                keeperId: "friend-design",
                keeperName: "Design Sparks",
                tags: ["design", "product", "ux"],
                thumbnail: "https://picsum.photos/seed/savi-friend-design/640/480",
                savedAt: now - 1_800_000,
                sharedAt: now - 1_200_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-2",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "A calm desk setup for deep work",
                itemDescription: "A watch-later video with practical desk, lighting, and focus setup ideas.",
                url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                source: "YouTube",
                type: .video,
                keeperId: "friend-videos",
                keeperName: "Watch Later",
                tags: ["video", "workspace", "focus"],
                thumbnail: youtubeThumbnail("https://www.youtube.com/watch?v=dQw4w9WgXcQ"),
                savedAt: now - 7_200_000,
                sharedAt: now - 6_900_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-3",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "Late-night dumpling spot",
                itemDescription: "A place Ava marked public for quick food ideas.",
                url: "https://maps.apple.com/?q=dumplings",
                source: "Maps",
                type: .place,
                keeperId: "friend-food",
                keeperName: "Food Ideas",
                tags: ["food", "place", "nyc"],
                thumbnail: "https://picsum.photos/seed/savi-friend-dumplings/640/480",
                savedAt: now - 21_600_000,
                sharedAt: now - 21_000_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-4",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "The internet memory palace idea",
                itemDescription: "A thoughtful essay on saving links as a living personal library.",
                url: "https://example.com/memory-palace",
                source: "Essay",
                type: .article,
                keeperId: "friend-reads",
                keeperName: "Good Reads",
                tags: ["essay", "internet", "memory"],
                thumbnail: "https://picsum.photos/seed/savi-friend-memory/640/480",
                savedAt: now - 43_200_000,
                sharedAt: now - 42_900_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-5",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "Weekend ceramic cafe list",
                itemDescription: "Ava's shortlist of calm cafes that are good for a slow Saturday browse.",
                url: "https://maps.apple.com/?q=ceramic%20cafe",
                source: "Maps",
                type: .place,
                keeperId: "friend-food",
                keeperName: "Food Ideas",
                tags: ["food", "coffee", "weekend", "place"],
                thumbnail: "https://picsum.photos/seed/savi-friend-cafe/640/480",
                savedAt: now - 55_200_000,
                sharedAt: now - 54_900_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-6",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "A product habit tracker that does not feel punishing",
                itemDescription: "A tiny interaction pattern Ava liked for making streaks feel gentle.",
                url: "https://example.com/gentle-habit-tracker",
                source: "Web",
                type: .article,
                keeperId: "friend-design",
                keeperName: "Design Sparks",
                tags: ["design", "habits", "ux", "product"],
                thumbnail: "https://picsum.photos/seed/savi-friend-habits/640/480",
                savedAt: now - 64_800_000,
                sharedAt: now - 64_100_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-7",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "Rick Astley music video rabbit hole",
                itemDescription: "A watch-later save for a music video, marked as entertainment instead of a private Keeper.",
                url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                source: "YouTube",
                type: .video,
                keeperId: "friend-music",
                keeperName: "Music Finds",
                tags: ["music", "video", "nostalgia", "youtube"],
                thumbnail: youtubeThumbnail("https://www.youtube.com/watch?v=dQw4w9WgXcQ"),
                savedAt: now - 73_200_000,
                sharedAt: now - 72_700_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-8",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "Small apartment shelf ideas",
                itemDescription: "A visual reference save for making open storage look less chaotic.",
                url: "https://www.pinterest.com/search/pins/?q=small%20apartment%20shelves",
                source: "Pinterest",
                type: .image,
                keeperId: "friend-home",
                keeperName: "Home Ideas",
                tags: ["home", "image", "storage", "interior"],
                thumbnail: "https://picsum.photos/seed/savi-friend-shelves/640/480",
                savedAt: now - 86_400_000,
                sharedAt: now - 85_900_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-9",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "A tiny notes app with excellent empty states",
                itemDescription: "A UI teardown Ava saved for onboarding and empty-state copy inspiration.",
                url: "https://example.com/empty-state-teardown",
                source: "Medium",
                type: .article,
                keeperId: "friend-design",
                keeperName: "Design Sparks",
                tags: ["design", "copy", "onboarding", "empty-state"],
                thumbnail: "https://picsum.photos/seed/savi-friend-empty-states/640/480",
                savedAt: now - 100_800_000,
                sharedAt: now - 100_100_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-10",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "Tokyo side-street walking video",
                itemDescription: "A relaxing city walk video Ava wants to watch while planning a trip.",
                url: "https://www.youtube.com/watch?v=jNQXAC9IVRw",
                source: "YouTube",
                type: .video,
                keeperId: "friend-travel",
                keeperName: "Travel Notes",
                tags: ["travel", "tokyo", "video", "city"],
                thumbnail: youtubeThumbnail("https://www.youtube.com/watch?v=jNQXAC9IVRw"),
                savedAt: now - 115_200_000,
                sharedAt: now - 114_800_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-11",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "One-bag packing checklist",
                itemDescription: "A practical travel checklist with the things Ava actually reuses.",
                url: "https://example.com/one-bag-packing",
                source: "Web",
                type: .article,
                keeperId: "friend-travel",
                keeperName: "Travel Notes",
                tags: ["travel", "packing", "checklist"],
                thumbnail: "https://picsum.photos/seed/savi-friend-packing/640/480",
                savedAt: now - 129_600_000,
                sharedAt: now - 129_000_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-12",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "The best tiny launch checklists",
                itemDescription: "A collection of product launch notes and QA reminders.",
                url: "https://github.com/topics/launch-checklist",
                source: "GitHub",
                type: .link,
                keeperId: "friend-tools",
                keeperName: "Tools & Apps",
                tags: ["tools", "startup", "checklist", "github"],
                thumbnail: "https://picsum.photos/seed/savi-friend-launch/640/480",
                savedAt: now - 151_200_000,
                sharedAt: now - 150_500_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-13",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "A reel about five-minute room resets",
                itemDescription: "A short home reset idea Ava saved from Instagram.",
                url: "https://www.instagram.com/reel/CxSAVIroomreset/",
                source: "Instagram",
                type: .video,
                keeperId: "friend-home",
                keeperName: "Home Ideas",
                tags: ["home", "video", "instagram", "routine"],
                thumbnail: "https://picsum.photos/seed/savi-friend-room-reset/640/480",
                savedAt: now - 172_800_000,
                sharedAt: now - 172_200_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-14",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "A TikTok pasta sauce trick",
                itemDescription: "A fast dinner idea Ava filed under food, not general videos.",
                url: "https://www.tiktok.com/@savi/video/7350000000000000000",
                source: "TikTok",
                type: .video,
                keeperId: "friend-food",
                keeperName: "Food Ideas",
                tags: ["food", "tiktok", "recipe", "dinner"],
                thumbnail: "https://picsum.photos/seed/savi-friend-pasta/640/480",
                savedAt: now - 201_600_000,
                sharedAt: now - 201_000_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-15",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "How to name product features without sounding cold",
                itemDescription: "A naming and copy reference for making settings feel human.",
                url: "https://example.com/feature-naming",
                source: "Substack",
                type: .article,
                keeperId: "friend-reads",
                keeperName: "Good Reads",
                tags: ["copy", "naming", "product", "essay"],
                thumbnail: "https://picsum.photos/seed/savi-friend-naming/640/480",
                savedAt: now - 230_400_000,
                sharedAt: now - 229_900_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-16",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "A playlist for rainy focus blocks",
                itemDescription: "Music Ava likes for a quiet work session.",
                url: "https://open.spotify.com/search/rainy%20focus",
                source: "Spotify",
                type: .link,
                keeperId: "friend-music",
                keeperName: "Music Finds",
                tags: ["music", "focus", "playlist", "spotify"],
                thumbnail: "https://picsum.photos/seed/savi-friend-rainy-focus/640/480",
                savedAt: now - 259_200_000,
                sharedAt: now - 258_700_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-17",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "Barcelona late checkout hotel notes",
                itemDescription: "A trip-planning link for comparing neighborhoods and quiet stays.",
                url: "https://maps.apple.com/?q=Barcelona%20boutique%20hotel",
                source: "Maps",
                type: .place,
                keeperId: "friend-travel",
                keeperName: "Travel Notes",
                tags: ["travel", "barcelona", "hotel", "place"],
                thumbnail: "https://picsum.photos/seed/savi-friend-barcelona/640/480",
                savedAt: now - 291_600_000,
                sharedAt: now - 291_000_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-18",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "A simple app icon grid reference",
                itemDescription: "A visual reference for icon balance and shape density.",
                url: "https://example.com/app-icon-grid",
                source: "Web",
                type: .image,
                keeperId: "friend-design",
                keeperName: "Design Sparks",
                tags: ["design", "icon", "brand", "image"],
                thumbnail: "https://picsum.photos/seed/savi-friend-icon-grid/640/480",
                savedAt: now - 324_000_000,
                sharedAt: now - 323_200_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-19",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "A thread about personal knowledge libraries",
                itemDescription: "A social post Ava saved for thinking about collections and recall.",
                url: "https://x.com/search?q=personal%20knowledge%20library",
                source: "X",
                type: .link,
                keeperId: "friend-reads",
                keeperName: "Good Reads",
                tags: ["knowledge", "library", "x", "ideas"],
                thumbnail: "https://picsum.photos/seed/savi-friend-knowledge/640/480",
                savedAt: now - 356_400_000,
                sharedAt: now - 355_900_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-20",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "A fast markdown editor worth testing",
                itemDescription: "A lightweight writing tool Ava wants to compare against Notes.",
                url: "https://example.com/markdown-editor",
                source: "Web",
                type: .link,
                keeperId: "friend-tools",
                keeperName: "Tools & Apps",
                tags: ["tools", "writing", "markdown", "apps"],
                thumbnail: "https://picsum.photos/seed/savi-friend-markdown/640/480",
                savedAt: now - 388_800_000,
                sharedAt: now - 388_300_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-21",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "No-knead focaccia timing notes",
                itemDescription: "A recipe link with timing notes that made it easy enough for a weeknight.",
                url: "https://example.com/no-knead-focaccia",
                source: "Recipe",
                type: .article,
                keeperId: "friend-food",
                keeperName: "Food Ideas",
                tags: ["food", "recipe", "bread", "dinner"],
                thumbnail: "https://picsum.photos/seed/savi-friend-focaccia/640/480",
                savedAt: now - 421_200_000,
                sharedAt: now - 420_700_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-22",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "Warm lamp setup inspiration",
                itemDescription: "A small-space lighting reference with a warmer evening mood.",
                url: "https://example.com/warm-lamp-setup",
                source: "Web",
                type: .image,
                keeperId: "friend-home",
                keeperName: "Home Ideas",
                tags: ["home", "lighting", "interior", "image"],
                thumbnail: "https://picsum.photos/seed/savi-friend-lamps/640/480",
                savedAt: now - 453_600_000,
                sharedAt: now - 453_100_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-23",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "A short video on making better app sounds",
                itemDescription: "A UX sound design video Ava saved for later product polish.",
                url: "https://www.youtube.com/watch?v=M7lc1UVf-VE",
                source: "YouTube",
                type: .video,
                keeperId: "friend-design",
                keeperName: "Design Sparks",
                tags: ["design", "sound", "video", "ux"],
                thumbnail: youtubeThumbnail("https://www.youtube.com/watch?v=M7lc1UVf-VE"),
                savedAt: now - 486_000_000,
                sharedAt: now - 485_400_000
            ),
            SaviSharedLink(
                id: "demo-ava-link-24",
                ownerUserId: "demo-friend-ava",
                ownerUsername: "ava",
                ownerDisplayName: "Ava",
                title: "A better way to keep restaurant wishlists",
                itemDescription: "A little essay about collecting places by mood instead of only by city.",
                url: "https://example.com/restaurant-wishlists",
                source: "Essay",
                type: .article,
                keeperId: "friend-reads",
                keeperName: "Good Reads",
                tags: ["food", "places", "essay", "memory"],
                thumbnail: "https://picsum.photos/seed/savi-friend-restaurant-wishlist/640/480",
                savedAt: now - 518_400_000,
                sharedAt: now - 517_900_000
            )
        ]

        var byId = Dictionary(uniqueKeysWithValues: friendLinks.map { ($0.id, $0) })
        for sample in samples {
            byId[sample.id] = sample
        }
        friendLinks = byId.values.sorted { $0.sharedAt > $1.sharedAt }
        prefs.sampleFriendSeeded = true
        socialSyncMessage = "Loaded Ava with \(samples.count) test links."
        persist()
        if showToast {
            toast = "Sample friend loaded."
        }
    }

    func removeFriend(_ friend: SaviFriend) {
        friends.removeAll { $0.id == friend.id }
        friendLinks.removeAll { SaviSocialText.normalizedUsername($0.ownerUsername) == friend.normalizedUsername }
        persist()
        toast = "Removed @\(friend.username)."
    }

    func toggleLikeFriendLink(_ link: SaviSharedLink) {
        var liked = Set(prefs.likedFriendLinkIds)
        if liked.contains(link.id) {
            liked.remove(link.id)
        } else {
            liked.insert(link.id)
        }
        prefs.likedFriendLinkIds = Array(liked).sorted()
        persist()
    }

    func isFriendLinkLiked(_ link: SaviSharedLink) -> Bool {
        prefs.likedFriendLinkIds.contains(link.id)
    }

    var likedFriendLinks: [SaviSharedLink] {
        friendLinks.filter { prefs.likedFriendLinkIds.contains($0.id) }
            .sorted { $0.sharedAt > $1.sharedAt }
    }

    func openFriendProfile(_ friend: SaviFriend) {
        presentedSheet = .friendProfile(friend)
    }

    func friendLinks(for friend: SaviFriend, keeperId: String? = nil) -> [SaviSharedLink] {
        friendLinks
            .filter { SaviSocialText.normalizedUsername($0.ownerUsername) == friend.normalizedUsername }
            .filter { link in
                guard let keeperId else { return true }
                return link.keeperId == keeperId
            }
            .sorted { lhs, rhs in
                if lhs.sharedAt == rhs.sharedAt { return lhs.title < rhs.title }
                return lhs.sharedAt > rhs.sharedAt
            }
    }

    func friendKeeperSummaries(for friend: SaviFriend) -> [SaviFriendKeeperSummary] {
        let groups = Dictionary(grouping: friendLinks(for: friend), by: \.keeperId)
        return groups.map { keeperId, links in
            SaviFriendKeeperSummary(
                id: keeperId,
                name: links.first?.keeperName ?? "Shared",
                count: links.count,
                latestSharedAt: links.map(\.sharedAt).max() ?? 0
            )
        }
        .sorted { lhs, rhs in
            if lhs.latestSharedAt == rhs.latestSharedAt { return lhs.name < rhs.name }
            return lhs.latestSharedAt > rhs.latestSharedAt
        }
    }

    func previewFriendLink(_ link: SaviSharedLink) {
        guard let url = URL(string: link.url) else { return }
        previewWebURL(url)
    }

    func syncSocialLinks() async {
        guard !isSocialSyncing else { return }
        isSocialSyncing = true
        defer { isSocialSyncing = false }

        await refreshCloudKitStatus()
        guard cloudKitStatus == "iCloud ready" else {
            socialSyncMessage = cloudKitStatus
            return
        }

        do {
            if publicProfile.isLinkSharingEnabled {
                try await cloudKitService.saveProfile(publicProfile)
                try await cloudKitService.publishSharedLinks(publicSharedLinks())
            }
            let fetched = try await cloudKitService.fetchSharedLinks(friendUsernames: friends.map(\.username))
            var refreshedLinks = fetched.filter { $0.ownerUserId != publicProfile.userId }
#if targetEnvironment(simulator)
            let demoLinks = friendLinks.filter { $0.ownerUserId == "demo-friend-ava" }
            let fetchedIds = Set(refreshedLinks.map(\.id))
            refreshedLinks.append(contentsOf: demoLinks.filter { !fetchedIds.contains($0.id) })
#endif
            friendLinks = refreshedLinks.sorted { $0.sharedAt > $1.sharedAt }
            socialSyncMessage = publicProfile.isLinkSharingEnabled
                ? "Shared \(publicSharedLinks().count) link preview\(publicSharedLinks().count == 1 ? "" : "s")."
                : "Friend feed refreshed."
            persist()
        } catch {
            socialSyncMessage = "CloudKit sync needs setup."
            NSLog("[SAVI Native] CloudKit social sync failed: \(error.localizedDescription)")
        }
    }

    func publicSharedLinks() -> [SaviSharedLink] {
        guard publicProfile.isLinkSharingEnabled else { return [] }
        return items.compactMap { item in
            guard let folder = folder(for: item.folderId),
                  folder.isPublic,
                  !folder.locked,
                  item.folderId != "f-private-vault",
                  let url = item.url?.nilIfBlank,
                  isShareablePublicLink(item)
            else { return nil }

            return SaviSharedLink(
                id: item.id,
                ownerUserId: publicProfile.userId,
                ownerUsername: publicProfile.normalizedUsername,
                ownerDisplayName: publicProfile.displayName,
                title: item.title,
                itemDescription: item.itemDescription,
                url: url,
                source: item.readableSource ?? item.source,
                type: item.type,
                keeperId: folder.id,
                keeperName: folder.name,
                tags: Array(item.tags.prefix(8)),
                thumbnail: item.thumbnail,
                savedAt: item.savedAt,
                sharedAt: Date().timeIntervalSince1970 * 1000
            )
        }
    }

    private func isShareablePublicLink(_ item: SaviItem) -> Bool {
        guard item.demo != true,
              item.assetId == nil,
              item.assetName == nil,
              item.assetMime == nil,
              [.link, .article, .video, .place].contains(item.type)
        else { return false }

        let haystack = [
            item.title,
            item.itemDescription,
            item.url ?? "",
            item.source,
            item.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()

        return !SaviText.looksSensitive(haystack)
    }

    private func scheduleSocialSyncIfNeeded() {
        guard publicProfile.isLinkSharingEnabled else { return }
        Task { await syncSocialLinks() }
    }

    func sourceOptions() -> [(key: String, label: String, count: Int)] {
        let groups = Dictionary(grouping: visibleItemsForBrowsing(), by: sourceKey(for:))
        return groups.map { key, values in
            (key: key, label: sourceLabel(for: key), count: values.count)
        }
        .sorted { lhs, rhs in
            if lhs.count == rhs.count { return lhs.label < rhs.label }
            return lhs.count > rhs.count
        }
    }

    func usefulSourceOptions(limit: Int = 10) -> [(key: String, label: String, count: Int)] {
        sourceOptions()
            .filter { option in
                option.count >= 2 ||
                    ["youtube", "instagram", "tiktok", "reddit", "maps", "device", "paste"].contains(option.key)
            }
            .prefix(limit)
            .map { $0 }
    }

    func tagOptions(limit: Int = 18, items sourceItems: [SaviItem]? = nil) -> [(key: String, label: String, count: Int)] {
        let hidden = Set([
            "article", "video", "image", "file", "text", "link", "upload", "shared",
            "sensitive", "private", "note"
        ])
        var counts: [String: Int] = [:]
        for item in sourceItems ?? visibleItemsForBrowsing() {
            for tag in item.tags {
                let key = SaviText.cleanSearchTag(tag)
                guard let key, !hidden.contains(key) else { continue }
                counts[key, default: 0] += 1
            }
        }
        return counts.map { key, count in
            (key: key, label: "#\(key)", count: count)
        }
        .sorted { lhs, rhs in
            if lhs.count == rhs.count { return lhs.key < rhs.key }
            return lhs.count > rhs.count
        }
        .prefix(limit)
        .map { $0 }
    }

    func searchKindOptions(includeEmpty: Bool = true) -> [(kind: SaviSearchKind, count: Int)] {
        let visibleItems = visibleItemsForBrowsing()
        return SaviSearchKind.all.compactMap { kind -> (kind: SaviSearchKind, count: Int)? in
            let count = kind.id == "all" ? visibleItems.count : visibleItems.filter { matchesSearchKind($0, kind: kind.id) }.count
            guard includeEmpty || kind.id == "all" || count > 0 else { return nil }
            return (kind: kind, count: count)
        }
    }

    func contextualTagOptions(limit: Int = 30) -> [(key: String, label: String, count: Int)] {
        tagOptions(limit: limit, items: filteredItemsIgnoringTag())
    }

    private func filteredItemsIgnoringTag() -> [SaviItem] {
        var result = visibleItemsForBrowsing()
        if folderFilter != "f-all" {
            result = result.filter { $0.folderId == folderFilter }
        }
        if typeFilter != "all" {
            result = result.filter { matchesSearchKind($0, kind: typeFilter) }
        }
        if sourceFilter != "all" {
            result = result.filter { sourceKey(for: $0) == sourceFilter }
        }
        if dateFilter != SearchDateFilter.all.rawValue {
            result = result.filter { matchesDateFilter($0, filter: dateFilter) }
        }
        if hasFilter != SearchHasFilter.all.rawValue {
            result = result.filter { matchesHasFilter($0, filter: hasFilter) }
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let needles = normalizedSearchNeedles(from: trimmed)
            result = result.filter { item in
                let haystack = searchHaystack(for: item)
                return needles.allSatisfy { haystack.contains($0) }
            }
        }
        return result
    }

    var folderLearningCount: Int {
        folderLearningSignals.count
    }

    var recentFolderLearningSignals: [SAVIFolderLearningSignal] {
        Array(folderLearningSignals.prefix(8))
    }

    func runFolderAudit(showToast: Bool = true) {
        let report = SAVIFolderClassifier.audit(
            availableFolders: folderOptionsForClassification(),
            learningSignals: []
        )
        folderAuditReport = report
        guard showToast else { return }
        toast = report.failedCount == 0 ?
            "Keeper audit passed: \(report.passedCount)/\(report.results.count)." :
            "Keeper audit found \(report.failedCount) issue(s)."
    }

    func refreshAppleIntelligenceStatus() async {
        appleIntelligenceStatus = await intelligenceService.statusText()
    }

    func refreshFolderDecisionHistory() {
        folderDecisionHistory = Array(shareStore.loadFolderDecisions().prefix(24))
    }

    func clearFolderDecisionHistory() {
        shareStore.clearFolderDecisions()
        folderDecisionHistory = []
        toast = "Keeper decision history cleared."
    }

    var exploreFreshCount: Int {
        exploreFreshCount(scope: exploreScope)
    }

    var exploreSeenCount: Int {
        exploreSeenCount(scope: exploreScope)
    }

    func setExploreScope(_ scope: ExploreScope) {
        exploreScope = scope
        prefs.exploreScope = scope.rawValue
        persist()
        setTab(.explore)
    }

    func exploreCount(scope: ExploreScope) -> Int {
        exploreCandidateItems(scope: scope).count
    }

    func exploreFreshCount(scope: ExploreScope) -> Int {
        let seenIds = Set(prefs.exploreSeenItemIds)
        return exploreCandidateItems(scope: scope).filter { !seenIds.contains($0.id) }.count
    }

    func exploreSeenCount(scope: ExploreScope) -> Int {
        let candidateIds = Set(exploreCandidateItems(scope: scope).map(\.id))
        return prefs.exploreSeenItemIds.filter { candidateIds.contains($0) }.count
    }

    func exploreStatusText(seed: Int, scope: ExploreScope) -> String {
        let count = exploreItems(seed: seed, scope: scope).count
        let freshCount = exploreFreshCount(scope: scope)
        let seenCount = exploreSeenCount(scope: scope)
        let noun: String
        switch scope {
        case .all: noun = "saves"
        case .mine: noun = "your saves"
        case .friends: noun = "friend saves"
        }
        if freshCount == 0 && seenCount > 0 {
            return "\(count) revisits · all caught up"
        }
        if seenCount > 0 {
            return "\(count) in this mix · \(freshCount) fresh"
        }
        return "\(count) browseable \(noun)"
    }

    func exploreItems(seed: Int, scope: ExploreScope) -> [SaviItem] {
        let seenIds = Set(prefs.exploreSeenItemIds)
        return exploreCandidateItems(scope: scope)
            .sorted { lhs, rhs in
                let lhsSeen = seenIds.contains(lhs.id)
                let rhsSeen = seenIds.contains(rhs.id)
                if lhsSeen != rhsSeen { return !lhsSeen }

                let left = exploreSortKey(for: lhs, seed: seed)
                let right = exploreSortKey(for: rhs, seed: seed)
                if left == right { return lhs.savedAt > rhs.savedAt }
                return left < right
            }
            .prefix(30)
            .map { $0 }
    }

    func isExploreSeen(_ item: SaviItem) -> Bool {
        prefs.exploreSeenItemIds.contains(item.id)
    }

    func openExploreItem(_ item: SaviItem) {
        markExploreSeen(item)
        presentedItem = item
    }

    func previewExploreItem(_ item: SaviItem, url: URL) {
        markExploreSeen(item)
        previewWebURL(url)
    }

    func resetExploreHistory() {
        prefs.exploreSeenItemIds = []
        persist()
        toast = "Explore is fresh again."
    }

    func isFriendExploreItem(_ item: SaviItem) -> Bool {
        item.id.hasPrefix("friend-")
    }

    func friendUsername(forExploreItem item: SaviItem) -> String? {
        guard isFriendExploreItem(item) else { return nil }
        let source = item.source.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = source.split(separator: " ").first, first.hasPrefix("@") {
            return String(first)
        }
        if let first = item.tags.first(where: { $0 != "friend" }) {
            return "@\(first)"
        }
        return "Friend"
    }

    func sourceLabel(forExploreItem item: SaviItem) -> String {
        guard isFriendExploreItem(item),
              let separator = item.source.range(of: "·")
        else { return item.source }
        return String(item.source[separator.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func exploreCandidateItems(scope: ExploreScope = .all) -> [SaviItem] {
        let mine = visibleItemsForBrowsing()
        let friends = friendLinks.map { $0.asExploreItem() }
        switch scope {
        case .all:
            return (mine + friends).filter(isExploreWorthy)
        case .mine:
            return mine.filter(isExploreWorthy)
        case .friends:
            return friends.filter(isExploreWorthy)
        }
    }

    private func markExploreSeen(_ item: SaviItem) {
        guard isExploreWorthy(item) else { return }
        var ids = prefs.exploreSeenItemIds.filter { $0 != item.id }
        ids.insert(item.id, at: 0)
        prefs.exploreSeenItemIds = Array(ids.prefix(500))
        persist()
    }

    private func isExploreWorthy(_ item: SaviItem) -> Bool {
        if item.type == .text || item.type == .file { return false }
        if item.folderId == "f-private-vault" || item.folderId == "f-paste-bin" { return false }
        if sourceKey(for: item) == "paste" { return false }

        let folderName = folder(for: item.folderId)?.name.lowercased() ?? ""
        if folderName.contains("private") || folderName.contains("vault") || folderName.contains("paste") { return false }

        let haystack = [
            item.title,
            item.itemDescription,
            item.url ?? "",
            item.source,
            item.assetName ?? "",
            item.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()

        if SaviText.looksSensitive(haystack) { return false }
        let blockedTerms = [
            "passport", "insurance", "receipt", "tax", "invoice", "bank",
            "prompt", "checklist", "todo", "meeting notes", "debug log",
            "private", "credential", "password"
        ]
        if blockedTerms.contains(where: { haystack.contains($0) }) { return false }

        return item.url?.nilIfBlank != nil ||
            item.thumbnail?.nilIfBlank != nil ||
            item.itemDescription.nilIfBlank != nil
    }

    private func exploreSortKey(for item: SaviItem, seed: Int) -> UInt64 {
        var value = UInt64(bitPattern: Int64(seed)) &+ 0xcbf29ce484222325
        for scalar in "\(item.id)-\(Int(item.savedAt))".unicodeScalars {
            value = (value ^ UInt64(scalar.value)) &* 0x100000001b3
        }
        return value
    }

    func addLink(urlString: String, title: String, description: String, folderId: String, tags: [String]) {
        let normalized = SaviText.normalizedURL(urlString)
        let url = URL(string: normalized)
        let inferred = SaviText.inferredType(for: normalized)
        let fallbackTitle = title.nilIfBlank ?? SaviText.fallbackTitle(for: normalized)
        let usesAutoFolder = folderId.isEmpty
        let targetFolderId = usesAutoFolder ? guessFolderId(title: fallbackTitle, description: description, url: normalized, tags: tags, type: inferred.rawValue, source: SaviText.sourceLabel(for: normalized, fallback: "Web")) : folderId
        let immediateThumbnail = url.flatMap { SaviText.isYouTube($0) ? SaviText.youtubeThumbnailURL(for: $0) : nil }
        let item = SaviItem(
            title: fallbackTitle,
            itemDescription: description,
            url: normalized,
            source: SaviText.sourceLabel(for: normalized, fallback: "Web"),
            type: inferred,
            folderId: targetFolderId,
            tags: SaviText.dedupeTags(tags + SaviText.inferredTags(type: inferred, url: normalized, title: fallbackTitle, description: description)),
            thumbnail: immediateThumbnail,
            color: folder(for: targetFolderId)?.color
        )
        items.insert(item, at: 0)
        if usesAutoFolder { autoFolderItemIds.insert(item.id) }
        if !usesAutoFolder { learnFolderSelection(for: item) }
        persist()
        toast = "Saved. Metadata and tags can catch up."
        scheduleAppleIntelligenceRefinement(id: item.id, allowFolderChange: usesAutoFolder)
        if let url {
            Task { await enrichItem(id: item.id, url: url) }
        }
        scheduleSocialSyncIfNeeded()
    }

    func addText(_ text: String, folderId: String, tags: [String]) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let title = SaviText.titleFromPlainText(trimmed)
        let sensitive = SaviText.looksSensitive(trimmed)
        let usesAutoFolder = folderId.isEmpty
        let preferredFolder = usesAutoFolder ? (sensitive ? "f-private-vault" : guessFolderId(title: title, description: trimmed, url: nil, tags: tags, type: SaviItemType.text.rawValue, source: "Paste")) : folderId
        let item = SaviItem(
            title: title,
            itemDescription: trimmed,
            source: "Paste",
            type: .text,
            folderId: preferredFolder,
            tags: SaviText.dedupeTags(tags + SaviText.tagsFromPlainText(trimmed)),
            thumbnail: nil,
            color: folder(for: preferredFolder)?.color
        )
        items.insert(item, at: 0)
        if usesAutoFolder { autoFolderItemIds.insert(item.id) }
        if !usesAutoFolder { learnFolderSelection(for: item) }
        persist()
        toast = "Text saved."
        scheduleAppleIntelligenceRefinement(id: item.id, allowFolderChange: usesAutoFolder && !sensitive)
    }

    func addFile(from url: URL, folderId: String, tags: [String]) async {
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let asset = try storage.copyAsset(from: url)
            if !assets.contains(where: { $0.id == asset.id }) {
                assets.append(asset)
            }
            let mime = asset.type
            let itemType = SaviText.typeForAsset(name: asset.name, mimeType: mime)
            let title = SaviText.titleFromFilename(asset.name)
            let usesAutoFolder = folderId.isEmpty
            let folder = usesAutoFolder ? guessFolderId(title: title, description: mime, url: nil, tags: tags, type: itemType.rawValue, source: "Device", fileName: asset.name, mimeType: mime) : folderId
            let item = SaviItem(
                title: title,
                itemDescription: "\(SaviText.fileKind(name: asset.name, mimeType: mime)) from your device · \(SaviText.formatBytes(asset.size))",
                source: "Device",
                type: itemType,
                folderId: folder,
                tags: SaviText.dedupeTags(
                    tags +
                    ["upload", itemType.rawValue, url.pathExtension.lowercased()] +
                    SaviText.inferredTags(type: itemType, url: nil, title: title, description: "\(asset.name) \(mime)")
                ),
                thumbnail: nil,
                color: self.folder(for: folder)?.color,
                assetId: asset.id,
                assetName: asset.name,
                assetMime: asset.type,
                assetSize: asset.size
            )
            items.insert(item, at: 0)
            if usesAutoFolder { autoFolderItemIds.insert(item.id) }
            if !usesAutoFolder { learnFolderSelection(for: item) }
            persist()
            toast = "File saved."
            scheduleAppleIntelligenceRefinement(id: item.id, allowFolderChange: usesAutoFolder)
        } catch {
            toast = "Could not save that file."
            NSLog("[SAVI Native] file import failed: \(error.localizedDescription)")
        }
    }

    func addClipboardFile(data: Data, name: String, mimeType: String, folderId: String, tags: [String]) {
        do {
            let asset = try storage.writeAssetData(data, preferredName: name, mimeType: mimeType)
            if !assets.contains(where: { $0.id == asset.id }) {
                assets.append(asset)
            }
            let itemType = SaviText.typeForAsset(name: asset.name, mimeType: asset.type)
            let title = SaviText.titleFromFilename(asset.name)
            let usesAutoFolder = folderId.isEmpty
            let folder = usesAutoFolder ? guessFolderId(title: title, description: asset.type, url: nil, tags: tags, type: itemType.rawValue, source: "Clipboard", fileName: asset.name, mimeType: asset.type) : folderId
            let item = SaviItem(
                title: title,
                itemDescription: "\(SaviText.fileKind(name: asset.name, mimeType: asset.type)) from clipboard · \(SaviText.formatBytes(asset.size))",
                source: "Clipboard",
                type: itemType,
                folderId: folder,
                tags: SaviText.dedupeTags(
                    tags +
                    ["clipboard", itemType.rawValue, asset.name.split(separator: ".").last.map(String.init) ?? "file"] +
                    SaviText.inferredTags(type: itemType, url: nil, title: title, description: "\(asset.name) \(asset.type)")
                ),
                thumbnail: asset.type.hasPrefix("image/") ? "data:\(asset.type);base64,\(data.base64EncodedString())" : nil,
                color: self.folder(for: folder)?.color,
                assetId: asset.id,
                assetName: asset.name,
                assetMime: asset.type,
                assetSize: asset.size
            )
            items.insert(item, at: 0)
            if usesAutoFolder { autoFolderItemIds.insert(item.id) }
            if !usesAutoFolder { learnFolderSelection(for: item) }
            persist()
            toast = "Clipboard saved."
            scheduleAppleIntelligenceRefinement(id: item.id, allowFolderChange: usesAutoFolder)
        } catch {
            toast = "Could not save clipboard file."
            NSLog("[SAVI Native] clipboard file import failed: \(error.localizedDescription)")
        }
    }

    func saveEditedItem(_ item: SaviItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let previous = items[index]
        items[index] = item
        if previous.folderId != item.folderId {
            autoFolderItemIds.remove(item.id)
            learnFolderSelection(for: item)
        }
        persist()
        toast = "Updated."
        scheduleSocialSyncIfNeeded()
    }

    func deleteItem(_ item: SaviItem) {
        items.removeAll { $0.id == item.id }
        if let assetId = item.assetId {
            try? storage.deleteAsset(id: assetId, assets: assets)
            assets.removeAll { $0.id == assetId }
        }
        presentedItem = nil
        editingItem = nil
        persist()
        toast = "Deleted."
        scheduleSocialSyncIfNeeded()
    }

    func addFolder(name: String, color: String, symbolName: String, image: String? = nil, locked: Bool = false, isPublic: Bool = false) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var orderedIds = orderedFoldersForDisplay().map(\.id)
        let folder = SaviFolder(
            id: "f-\(UUID().uuidString)",
            name: trimmed,
            color: color,
            image: image,
            system: false,
            symbolName: symbolName,
            order: orderedIds.count,
            locked: locked,
            isPublic: isPublic
        )
        folders.insert(folder, at: max(0, folders.count - 1))
        orderedIds.append(folder.id)
        applyFolderOrder(orderedIds)
        persist()
        toast = "Keeper created."
    }

    func saveFolder(_ folder: SaviFolder) {
        guard let index = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        var next = folder
        if next.locked || next.id == "f-private-vault" {
            next.isPublic = false
        }
        folders[index] = next
        if !folder.locked {
            unlockedProtectedKeeperIds.remove(folder.id)
        }
        persist()
        toast = "Keeper updated."
        if publicProfile.isLinkSharingEnabled {
            Task { await syncSocialLinks() }
        }
    }

    func deleteFolder(_ folder: SaviFolder) {
        guard !folder.system, folder.id != "f-all" else { return }
        let fallback = "f-random"
        items = items.map { item in
            var next = item
            if next.folderId == folder.id {
                next.folderId = fallback
            }
            return next
        }
        folders.removeAll { $0.id == folder.id }
        applyFolderOrder(orderedFoldersForDisplay().map(\.id))
        folderFilter = "f-all"
        persist()
        toast = "Keeper deleted."
    }

    func clearDemoContent() {
        items.removeAll { $0.demo == true }
        prefs.demoSuppressed = true
        persist()
        toast = "Demo content cleared."
    }

    func clearEverything() {
        items.removeAll()
        assets.removeAll()
        folders = SaviSeeds.folders
        prefs.demoSuppressed = true
        try? storage.clearAssetsDirectory()
        persist()
        toast = "Library cleared."
    }

    func restoreSeeds() {
        folders = SaviSeeds.folders
        items = SaviSeeds.items
        prefs.demoSuppressed = false
        prefs.legacySeedVersion = 0
        persist()
        toast = "Demo library restored."
    }

    func quickLookURL(for item: SaviItem) -> URL? {
        guard let assetId = item.assetId,
              let asset = assets.first(where: { $0.id == assetId })
        else { return nil }
        return storage.assetURL(for: asset)
    }

    func buildBackupDocument() {
        do {
            let backup = try storage.buildBackup(folders: folders, items: items, assets: assets, folderLearning: folderLearningSignals)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(backup)
            backupDocument = SaviBackupDocument(data: data)
            isExportingBackup = true
        } catch {
            toast = "Could not pack the backup."
            NSLog("[SAVI Native] backup export failed: \(error.localizedDescription)")
        }
    }

    func importBackup(from url: URL) async {
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let data = try Data(contentsOf: url)
            let backup = try JSONDecoder().decode(SaviBackup.self, from: data)
            guard backup.app == "SAVI" else {
                toast = "That is not a SAVI backup."
                return
            }
            try storage.clearAssetsDirectory()
            let restoredAssets = try backup.assets.map { try storage.writeBackupAsset($0) }
            folders = SaviSeeds.withSeedDefaults(backup.folders)
            items = backup.items
            assets = restoredAssets
            folderLearningSignals = backup.folderLearning ?? []
            prefs.onboarded = true
            prefs.migrationComplete = true
            persist()
            toast = "Backup restored."
        } catch {
            toast = "Could not restore that backup."
            NSLog("[SAVI Native] backup import failed: \(error.localizedDescription)")
        }
    }

    func finishLegacyMigration(_ payload: LegacyMigrationPayload) async {
        if prefs.migrationComplete {
            finishLegacySeedRefresh(payload)
            return
        }

        if let error = payload.error {
            migrationMessage = "Migration paused: \(error)"
            prefs.migrationComplete = true
            prefs.legacySeedVersion = Self.currentLegacySeedVersion
            persist()
            return
        }

        var migrated = false
        do {
            if let storageJSON = payload.storageJSON,
               let data = storageJSON.data(using: .utf8),
               let legacy = try? JSONDecoder().decode(LegacyStoredState.self, from: data),
               let legacyItems = legacy.items,
               let legacyFolders = legacy.folders,
               !legacyItems.isEmpty || !legacyFolders.isEmpty {
                try storage.clearAssetsDirectory()
                let migratedAssets = try payload.assets.map { try storage.writeBackupAsset($0) }
                folders = SaviSeeds.withSeedDefaults(legacyFolders)
                items = legacyItems
                assets = migratedAssets
                migrated = true
            }

            if !migrated,
               !payload.demoSuppressed,
               let seedStorageJSON = payload.seedStorageJSON,
               let data = seedStorageJSON.data(using: .utf8),
               let legacySeeds = try? JSONDecoder().decode(LegacyStoredState.self, from: data),
               let seedItems = legacySeeds.items,
               !seedItems.isEmpty {
                folders = SaviSeeds.withSeedDefaults(legacySeeds.folders ?? folders)
                items = seedItems
                prefs.legacySeedVersion = Self.currentLegacySeedVersion
                migrated = true
            }

            if let uiPrefsJSON = payload.uiPrefsJSON,
               let data = uiPrefsJSON.data(using: .utf8),
               let legacyPrefs = try? JSONDecoder().decode(LegacyUiPrefs.self, from: data) {
                prefs.viewMode = legacyPrefs.viewMode ?? prefs.viewMode
                prefs.themeMode = legacyPrefs.themeMode ?? prefs.themeMode
            }
            prefs.onboarded = payload.onboarded
            prefs.demoSuppressed = payload.demoSuppressed
            prefs.migrationComplete = true
            if migrated {
                prefs.legacySeedVersion = Self.currentLegacySeedVersion
            }
            persist()
            migrationMessage = migrated ? "Legacy SAVI data migrated." : nil
        } catch {
            migrationMessage = "Migration could not finish. Import a SAVI backup from Profile."
            prefs.migrationComplete = true
            prefs.legacySeedVersion = Self.currentLegacySeedVersion
            persist()
            NSLog("[SAVI Native] legacy migration failed: \(error.localizedDescription)")
        }
    }

    private func finishLegacySeedRefresh(_ payload: LegacyMigrationPayload) {
        guard shouldRefreshLegacySeeds else { return }

        if let error = payload.error {
            NSLog("[SAVI Native] legacy seed refresh skipped: \(error)")
            return
        }

        guard let seedStorageJSON = payload.seedStorageJSON,
              let data = seedStorageJSON.data(using: .utf8),
              let legacySeeds = try? JSONDecoder().decode(LegacyStoredState.self, from: data),
              let seedItems = legacySeeds.items,
              !seedItems.isEmpty
        else {
            NSLog("[SAVI Native] legacy seed refresh had no seed items")
            return
        }

        let personalItems = items.filter { $0.demo != true }
        folders = SaviSeeds.withSeedDefaults(legacySeeds.folders ?? folders)
        items = seedItems + personalItems
        prefs.legacySeedVersion = Self.currentLegacySeedVersion
        persist()
        toast = "Previous thumbnails loaded."
    }

    func importPendingShares() async {
        let startedAt = Date()
        let pending = shareStore.loadPendingShares()
        guard !pending.isEmpty else { return }
        NSLog("[SAVI Native] found %d pending share(s) to import", pending.count)

        var importedCount = 0
        for share in pending where !importedShareIds.contains(share.id) {
            importedShareIds.insert(share.id)
            let folderSource = (share.folderSource ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let usesAutoFolder = share.folderId?.nilIfBlank == nil || folderSource != "manual"
            let item = await createItem(from: share)
            items.insert(item, at: 0)
            importedCount += 1
            if usesAutoFolder { autoFolderItemIds.insert(item.id) }
            if !usesAutoFolder { learnFolderSelection(for: item) }
            shareStore.remove(share)
            persist()
            NSLog("[SAVI Native] imported pending share %@ as item %@", share.id, item.id)
            scheduleAppleIntelligenceRefinement(id: item.id, allowFolderChange: usesAutoFolder && !SaviText.looksSensitive("\(item.title) \(item.itemDescription) \(item.url ?? "")"))
            if let urlString = item.url,
               let url = URL(string: urlString),
               url.scheme?.hasPrefix("http") == true {
                Task { await enrichItem(id: item.id, url: url) }
            }
        }
        NSLog("[SAVI Native] imported %d pending share(s) in %.3fs", importedCount, Date().timeIntervalSince(startedAt))
        refreshFolderDecisionHistory()
        scheduleSocialSyncIfNeeded()
        toast = pending.count == 1 ? "Shared item saved." : "\(pending.count) shared items saved."
    }

    func refreshStaleMetadata(limit: Int = 20) async {
        let candidates = items
            .filter(needsMetadataRefresh)
            .filter { shouldAttemptMetadataRefresh($0) }
            .prefix(limit)
            .compactMap { item -> (String, URL)? in
                guard let urlString = item.url,
                      let url = URL(string: urlString),
                      url.scheme?.hasPrefix("http") == true
                else { return nil }
                return (item.id, url)
            }

        guard !candidates.isEmpty else { return }
        NSLog("[SAVI Native] refreshing metadata for %d stale item(s)", candidates.count)
        for candidate in candidates {
            await enrichItem(id: candidate.0, url: candidate.1)
        }
    }

    private func shouldAttemptMetadataRefresh(_ item: SaviItem, now: Date = Date()) -> Bool {
        guard item.thumbnail?.nilIfBlank == nil,
              expectsRemoteThumbnail(item)
        else {
            return true
        }
        guard isNetworkReachable else { return false }
        guard item.thumbnailRetryCount > 0,
              let lastAttempt = item.thumbnailLastAttemptAt
        else {
            return true
        }
        let lastAttemptSeconds = lastAttempt > 10_000_000_000 ? lastAttempt / 1000 : lastAttempt
        let elapsed = now.timeIntervalSince(Date(timeIntervalSince1970: lastAttemptSeconds))
        return elapsed >= thumbnailRetryDelay(for: item.thumbnailRetryCount)
    }

    private func thumbnailRetryDelay(for count: Int) -> TimeInterval {
        Self.thumbnailRetryDelays[min(max(count, 0), Self.thumbnailRetryDelays.count - 1)]
    }

    private func createItem(from share: PendingShare) async -> SaviItem {
        var asset: SaviAsset?
        if let filePath = share.filePath, !filePath.isEmpty {
            let fileURL = URL(fileURLWithPath: filePath)
            asset = try? storage.copyAsset(from: fileURL, preferredName: share.fileName)
            if let asset, !assets.contains(where: { $0.id == asset.id }) {
                assets.append(asset)
            }
        } else if let thumbnail = share.thumbnail,
                  thumbnail.hasPrefix("data:"),
                  share.type.lowercased() == "image" {
            asset = try? storage.writeDataURL(thumbnail, preferredName: share.fileName ?? "\(share.id).jpg", id: share.id)
            if let asset, !assets.contains(where: { $0.id == asset.id }) {
                assets.append(asset)
            }
        }

        let type = SaviText.itemType(
            forSharedType: share.type,
            url: share.url,
            fileName: asset?.name ?? share.fileName,
            mimeType: asset?.type ?? share.mimeType
        )
        let description = share.itemDescription?.nilIfBlank ?? share.text?.nilIfBlank ?? ""
        let source = SaviText.sourceLabel(for: share.url ?? "", fallback: share.sourceApp)
        let folderId = share.folderId?.nilIfBlank ?? guessFolderId(
            title: share.title,
            description: description,
            url: share.url,
            tags: share.tags ?? [],
            type: type.rawValue,
            source: source,
            fileName: asset?.name ?? share.fileName,
            mimeType: asset?.type ?? share.mimeType
        )
        let immediateThumbnail = share.thumbnail?.nilIfBlank ??
            share.url
                .flatMap(URL.init(string:))
                .flatMap { SaviText.isYouTube($0) ? SaviText.youtubeThumbnailURL(for: $0) : nil }
        return SaviItem(
            id: share.id,
            title: share.title.nilIfBlank ?? SaviText.fallbackTitle(for: share.url ?? ""),
            itemDescription: description,
            url: share.url?.nilIfBlank,
            source: source,
            type: type,
            folderId: folderId,
            tags: SaviText.dedupeTags((share.tags ?? []) + SaviText.inferredTags(type: type, url: share.url, title: share.title, description: description)),
            thumbnail: immediateThumbnail,
            savedAt: share.timestamp,
            color: folder(for: folderId)?.color,
            assetId: asset?.id,
            assetName: asset?.name ?? share.fileName,
            assetMime: asset?.type ?? share.mimeType,
            assetSize: asset?.size
        )
    }

    private func enrichItem(id: String, url: URL) async {
        let shouldWaitForThumbnail = shouldWaitForThumbnail(id: id, url: url)
        if shouldWaitForThumbnail {
            recordThumbnailAttempt(id: id)
        }

        guard let metadata = await metadataService.fetch(for: url, waitsForThumbnail: shouldWaitForThumbnail) else {
            applyMetadataFallback(id: id, url: url)
            scheduleThumbnailRetryIfNeeded(id: id, url: url)
            NSLog("[SAVI Native] metadata fetch returned no data for %@", url.absoluteString)
            return
        }
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        var item = items[index]
        let before = item

        if SaviText.shouldReplaceTitle(current: item.title, fetched: metadata.title) {
            item.title = metadata.title ?? item.title
        }
        if shouldReplaceDescription(current: item.itemDescription, fetched: metadata.description, url: url),
           let description = metadata.description?.nilIfBlank {
            item.itemDescription = description
        }
        if item.thumbnail?.nilIfBlank == nil, let imageURL = metadata.imageURL?.nilIfBlank {
            item.thumbnail = imageURL
        }
        if item.thumbnail?.nilIfBlank != nil {
            item.thumbnailRetryCount = 0
            item.thumbnailLastAttemptAt = nil
        }
        if item.source.isEmpty || item.source == "Web" || item.source == "Share Extension" {
            item.source = metadata.provider?.nilIfBlank ?? SaviText.sourceLabel(for: url.absoluteString, fallback: item.source)
        }
        if item.type == .link || item.type == .article {
            item.type = metadata.type ?? item.type
        }
        item.tags = SaviText.dedupeTags(item.tags + metadata.tags)
        if item.folderId == "f-random" || item.folderId.isEmpty {
            item.folderId = guessFolderId(
                title: item.title,
                description: item.itemDescription,
                url: item.url,
                tags: item.tags,
                type: item.type.rawValue,
                source: item.source,
                fileName: item.assetName,
                mimeType: item.assetMime
            )
        }
        items[index] = item
        if item != before {
            persist()
            scheduleSocialSyncIfNeeded()
            NSLog("[SAVI Native] enriched metadata for %@ title=%@ thumbnail=%@", id, item.title, item.thumbnail?.nilIfBlank ?? "none")
        }
        if item.thumbnail?.nilIfBlank == nil {
            scheduleThumbnailRetryIfNeeded(id: id, url: url)
        }
        scheduleAppleIntelligenceRefinement(id: id, allowFolderChange: autoFolderItemIds.contains(id) || item.folderId == "f-random")
    }

    private func shouldWaitForThumbnail(id: String, url: URL) -> Bool {
        guard let item = items.first(where: { $0.id == id }),
              item.thumbnail?.nilIfBlank == nil,
              expectsRemoteThumbnail(item, url: url)
        else { return false }
        return isNetworkReachable
    }

    private func recordThumbnailAttempt(id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].thumbnailRetryCount += 1
        items[index].thumbnailLastAttemptAt = Date().timeIntervalSince1970 * 1000
        persist()
    }

    private func scheduleThumbnailRetryIfNeeded(id: String, url: URL) {
        guard let item = items.first(where: { $0.id == id }),
              item.thumbnail?.nilIfBlank == nil,
              expectsRemoteThumbnail(item, url: url),
              isNetworkReachable,
              !scheduledThumbnailRetryIds.contains(id)
        else { return }

        let delay = thumbnailRetryDelay(for: item.thumbnailRetryCount)
        scheduledThumbnailRetryIds.insert(id)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await self?.runScheduledThumbnailRetry(id: id, url: url)
        }
    }

    private func runScheduledThumbnailRetry(id: String, url: URL) async {
        scheduledThumbnailRetryIds.remove(id)
        guard let item = items.first(where: { $0.id == id }),
              needsMetadataRefresh(item),
              shouldAttemptMetadataRefresh(item)
        else { return }
        await enrichItem(id: id, url: url)
    }

    private func applyMetadataFallback(id: String, url: URL) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }

        var item = items[index]
        let before = item
        if SaviText.isYouTube(url) {
            item.thumbnail = item.thumbnail?.nilIfBlank ?? SaviText.youtubeThumbnailURL(for: url)
            if item.source.isEmpty || item.source == "Web" || item.source == "Share Extension" {
                item.source = "YouTube"
            }
            if item.type == .link || item.type == .article {
                item.type = .video
            }
            item.tags = SaviText.dedupeTags(item.tags + ["youtube", "video"])
        } else if SaviText.isTikTok(url) {
            if item.source.isEmpty || item.source == "Web" || item.source == "Share Extension" {
                item.source = "TikTok"
            }
            if item.type == .link || item.type == .article {
                item.type = .video
            }
            item.tags = SaviText.dedupeTags(item.tags + ["tiktok", "video"])
        } else if SaviText.isInstagram(url) {
            if item.source.isEmpty || item.source == "Web" || item.source == "Share Extension" {
                item.source = "Instagram"
            }
            if item.type == .link || item.type == .article, SaviText.isInstagramReel(url) {
                item.type = .video
            }
            item.tags = SaviText.dedupeTags(item.tags + ["instagram"] + (SaviText.isInstagramReel(url) ? ["reel", "video"] : ["post"]))
        } else if SaviText.isTwitterX(url) {
            item.source = fallbackSource(current: item.source, replacement: "X")
            item.tags = SaviText.dedupeTags(item.tags + ["x", "twitter", "post"])
        } else if SaviText.isReddit(url) {
            item.source = fallbackSource(current: item.source, replacement: "Reddit")
            item.tags = SaviText.dedupeTags(item.tags + ["reddit", "post"])
        } else if SaviText.isVimeo(url) {
            item.source = fallbackSource(current: item.source, replacement: "Vimeo")
            if item.type == .link || item.type == .article { item.type = .video }
            item.tags = SaviText.dedupeTags(item.tags + ["vimeo", "video"])
        } else if SaviText.isSpotify(url) {
            item.source = fallbackSource(current: item.source, replacement: "Spotify")
            item.tags = SaviText.dedupeTags(item.tags + ["spotify", "music"])
        } else if SaviText.isSoundCloud(url) {
            item.source = fallbackSource(current: item.source, replacement: "SoundCloud")
            item.tags = SaviText.dedupeTags(item.tags + ["soundcloud", "music"])
        } else if SaviText.isPinterest(url) {
            item.source = fallbackSource(current: item.source, replacement: "Pinterest")
            if item.type == .link || item.type == .article { item.type = .image }
            item.tags = SaviText.dedupeTags(item.tags + ["pinterest", "image"])
        } else if SaviText.isFacebook(url) {
            item.source = fallbackSource(current: item.source, replacement: "Facebook")
            item.tags = SaviText.dedupeTags(item.tags + ["facebook", "post"])
        } else if SaviText.isThreads(url) {
            item.source = fallbackSource(current: item.source, replacement: "Threads")
            item.tags = SaviText.dedupeTags(item.tags + ["threads", "post"])
        } else if SaviText.isBluesky(url) {
            item.source = fallbackSource(current: item.source, replacement: "Bluesky")
            item.tags = SaviText.dedupeTags(item.tags + ["bluesky", "post"])
        } else if SaviText.isLinkedIn(url) {
            item.source = fallbackSource(current: item.source, replacement: "LinkedIn")
            item.tags = SaviText.dedupeTags(item.tags + ["linkedin", "post"])
        }
        guard item != before else { return }
        items[index] = item
        persist()
    }

    private func fallbackSource(current: String, replacement: String) -> String {
        if current.isEmpty || current == "Web" || current == "Share Extension" {
            return replacement
        }
        return current
    }

    private func needsMetadataRefresh(_ item: SaviItem) -> Bool {
        guard let urlString = item.url?.nilIfBlank,
              let url = URL(string: urlString),
              url.scheme?.hasPrefix("http") == true
        else { return false }

        let normalizedTitle = item.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let genericTitle = normalizedTitle.isEmpty ||
            normalizedTitle == "saved link" ||
            normalizedTitle == "shared item" ||
            normalizedTitle == "youtube video" ||
            normalizedTitle.hasPrefix("http") ||
            normalizedTitle.hasSuffix(" save")
        let platformLink = isMajorPlatformURL(url)
        let expectsThumbnail = expectsRemoteThumbnail(item, url: url)
        let missingThumbnail = item.thumbnail?.nilIfBlank == nil && expectsThumbnail
        let genericDescription = item.itemDescription.nilIfBlank == nil ||
            item.itemDescription.localizedCaseInsensitiveContains(urlString) ||
            item.itemDescription.localizedCaseInsensitiveContains("Video from YouTube") ||
            item.itemDescription.localizedCaseInsensitiveContains("Video from TikTok") ||
            item.itemDescription.localizedCaseInsensitiveContains("Saved from TikTok") ||
            item.itemDescription.localizedCaseInsensitiveContains("Saved from Instagram") ||
            item.itemDescription.localizedCaseInsensitiveContains("Shared from Facebook") ||
            item.itemDescription.localizedCaseInsensitiveContains("Shared from Threads")
        let expectedSource = SaviText.sourceLabel(for: urlString, fallback: "")
        let genericSource = item.source.isEmpty || item.source == "Web" || item.source == "Share Extension" ||
            (platformLink && item.source != expectedSource)
        return genericTitle || missingThumbnail || genericDescription || genericSource
    }

    func shouldShowBrandFallback(for item: SaviItem, now: Date = Date()) -> Bool {
        guard item.thumbnail?.nilIfBlank == nil,
              SaviSourceBrand.brand(for: item) != nil,
              expectsRemoteThumbnail(item),
              isNetworkReachable,
              item.thumbnailRetryCount >= Self.thumbnailLogoFallbackAttempts
        else { return false }
        return now.timeIntervalSince(itemSavedDate(item)) >= Self.thumbnailLogoFallbackGrace
    }

    func shouldShowThumbnailPending(for item: SaviItem, now: Date = Date()) -> Bool {
        guard item.thumbnail?.nilIfBlank == nil,
              expectsRemoteThumbnail(item)
        else { return false }
        return !shouldShowBrandFallback(for: item, now: now)
    }

    func thumbnailPendingMessage(for item: SaviItem) -> String {
        isNetworkReachable ? "Fetching preview" : "Waiting for internet"
    }

    private func expectsRemoteThumbnail(_ item: SaviItem, url providedURL: URL? = nil) -> Bool {
        guard item.assetId == nil,
              let url = providedURL ?? item.url?.nilIfBlank.flatMap(URL.init(string:)),
              url.scheme?.hasPrefix("http") == true
        else { return false }
        return item.type == .video ||
            item.type == .image ||
            isMajorPlatformURL(url)
    }

    private func isMajorPlatformURL(_ url: URL) -> Bool {
        SaviText.isYouTube(url) ||
            SaviText.isTikTok(url) ||
            SaviText.isInstagram(url) ||
            SaviText.isTwitterX(url) ||
            SaviText.isReddit(url) ||
            SaviText.isVimeo(url) ||
            SaviText.isSpotify(url) ||
            SaviText.isSoundCloud(url) ||
            SaviText.isPinterest(url) ||
            SaviText.isFacebook(url) ||
            SaviText.isThreads(url) ||
            SaviText.isBluesky(url) ||
            SaviText.isLinkedIn(url)
    }

    private func itemSavedDate(_ item: SaviItem) -> Date {
        let seconds = item.savedAt > 10_000_000_000 ? item.savedAt / 1000 : item.savedAt
        return Date(timeIntervalSince1970: seconds)
    }

    private func shouldReplaceDescription(current: String, fetched: String?, url: URL) -> Bool {
        guard fetched?.nilIfBlank != nil else { return false }
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return trimmed.localizedCaseInsensitiveContains(url.absoluteString) ||
            trimmed.localizedCaseInsensitiveContains("Video from YouTube") ||
            trimmed.localizedCaseInsensitiveContains("Video from TikTok") ||
            trimmed.localizedCaseInsensitiveContains("Saved link") ||
            trimmed.localizedCaseInsensitiveContains("Shared item") ||
            trimmed.localizedCaseInsensitiveContains("Saved from TikTok") ||
            trimmed.localizedCaseInsensitiveContains("Saved from Instagram") ||
            trimmed.localizedCaseInsensitiveContains("Shared from Facebook") ||
            trimmed.localizedCaseInsensitiveContains("Shared from Threads")
    }

    private func guessFolderId(
        title: String,
        description: String,
        url: String?,
        tags: [String],
        type: String? = nil,
        source: String = "",
        fileName: String? = nil,
        mimeType: String? = nil,
        context: String = "Auto Keeper"
    ) -> String {
        let input = SAVIFolderClassificationInput(
            title: title,
            description: description,
            url: url,
            type: type ?? SaviText.inferredType(for: url ?? "").rawValue,
            source: source,
            fileName: fileName,
            mimeType: mimeType,
            tags: tags
        )
        let result = classifyFolder(input: input)
        recordFolderDecision(input: input, result: result, context: context)
        return result.folderId
    }

    private func classifyFolder(input: SAVIFolderClassificationInput) -> SAVIFolderClassification {
        SAVIFolderClassifier.classify(
            input,
            availableFolders: folderOptionsForClassification(),
            learningSignals: folderLearningSignals
        )
    }

    private func classificationInput(for item: SaviItem) -> SAVIFolderClassificationInput {
        SAVIFolderClassificationInput(
            title: item.title,
            description: item.itemDescription,
            url: item.url,
            type: item.type.rawValue,
            source: item.source,
            fileName: item.assetName,
            mimeType: item.assetMime,
            tags: item.tags
        )
    }

    private func learnFolderSelection(for item: SaviItem) {
        let signals = SAVIFolderClassifier.learningSignals(
            from: classificationInput(for: item),
            correctedFolderId: item.folderId
        )
        guard !signals.isEmpty else { return }

        var byId = Dictionary(uniqueKeysWithValues: folderLearningSignals.map { ($0.id, $0) })
        for signal in signals {
            if var existing = byId[signal.id] {
                existing.weight = min(18, existing.weight + max(1, signal.weight / 3))
                existing.uses = min(existing.uses + 1, 99)
                existing.updatedAt = signal.updatedAt
                byId[signal.id] = existing
            } else {
                byId[signal.id] = signal
            }
        }

        folderLearningSignals = Array(byId.values)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt { return lhs.id < rhs.id }
                return lhs.updatedAt > rhs.updatedAt
            }
            .prefix(180)
            .map { $0 }
        try? shareStore.saveFolderLearning(folderLearningSignals)
    }

    private func localFolderClassification(for item: SaviItem) -> SAVIFolderClassification {
        classifyFolder(input: classificationInput(for: item))
    }

    private func recordFolderDecision(input: SAVIFolderClassificationInput, result: SAVIFolderClassification, context: String) {
        let title = input.title.nilIfBlank ??
            input.fileName?.nilIfBlank ??
            input.url?.nilIfBlank ??
            input.description.nilIfBlank ??
            "Untitled save"
        let safeTitle = (SAVIFolderClassifier.isSensitive(input) || SAVIFolderClassifier.looksPrivateDocument(input)) ?
            "Private item" :
            String(title.prefix(90))
        let folderName = folder(for: result.folderId)?.name ??
            SAVIFolderClassifier.defaultFolderOptions.first(where: { $0.id == result.folderId })?.name ??
            "Unknown Keeper"
        let decision = SAVIFolderDecisionRecord(
            id: UUID().uuidString,
            title: safeTitle,
            folderId: result.folderId,
            folderName: folderName,
            confidence: result.confidence,
            reason: result.reason,
            context: context,
            createdAt: Date().timeIntervalSince1970
        )
        folderDecisionHistory.insert(decision, at: 0)
        folderDecisionHistory = Array(folderDecisionHistory.prefix(24))
        shareStore.saveFolderDecision(decision)
    }

    private func folderOptionsForClassification() -> [SAVIFolderOption] {
        folders
            .filter { $0.id != "f-all" }
            .map { SAVIFolderOption(id: $0.id, name: $0.name) }
    }

    private func repairObviousGenericFolderAssignmentsIfNeeded() {
        guard prefs.folderRepairVersion < Self.currentFolderRepairVersion else { return }
        let previousRepairVersion = prefs.folderRepairVersion
        var changed = 0

        if previousRepairVersion < 1 {
            let genericFolderIds = Set(["f-random", "f-must-see"])
            let semanticFolderIds = Set(["f-recipes", "f-travel", "f-health", "f-design", "f-growth", "f-research", "f-wtf-favorites", "f-tinfoil", "f-lmao"])
            for index in items.indices {
                guard items[index].folderId.isEmpty || genericFolderIds.contains(items[index].folderId) else { continue }
                let item = items[index]
                let result = classifyFolder(input: classificationInput(for: item))
                guard semanticFolderIds.contains(result.folderId), result.confidence >= 36 else { continue }
                items[index].folderId = result.folderId
                items[index].color = folder(for: result.folderId)?.color
                changed += 1
            }
        }

        if previousRepairVersion < 2 {
            changed += repairScienceFolderFalsePositives()
        }

        prefs.folderRepairVersion = Self.currentFolderRepairVersion
        persist()
        if changed > 0 {
            NSLog("[SAVI Native] repaired %d obvious generic folder assignment(s)", changed)
        }
    }

    private func repairScienceFolderFalsePositives() -> Int {
        var changed = 0
        for index in items.indices {
            let item = items[index]
            guard item.folderId == "f-wtf-favorites", looksLikeEntertainmentFalsePositive(item) else { continue }
            let result = classifyFolder(input: classificationInput(for: item))
            guard result.folderId != "f-wtf-favorites", ["f-must-see", "f-lmao"].contains(result.folderId), result.confidence >= 14 else { continue }
            items[index].folderId = result.folderId
            items[index].color = folder(for: result.folderId)?.color
            changed += 1
        }
        return changed
    }

    private func looksLikeEntertainmentFalsePositive(_ item: SaviItem) -> Bool {
        let haystack = [
            item.title,
            item.itemDescription,
            item.source,
            item.url ?? "",
            item.tags.joined(separator: " ")
        ]
            .joined(separator: " ")
            .lowercased()
        return item.type == .video ||
            haystack.contains("youtube") ||
            haystack.contains("official video") ||
            haystack.contains("music video") ||
            haystack.contains("rick astley") ||
            haystack.contains("rickroll") ||
            haystack.contains("trailer") ||
            haystack.contains("movie") ||
            haystack.contains("meme")
    }

    private func repairSearchTagsIfNeeded() {
        guard prefs.searchTagRepairVersion < Self.currentSearchTagRepairVersion else { return }

        var changed = 0
        for index in items.indices {
            let item = items[index]
            var additions = SaviText.inferredTags(
                type: item.type,
                url: item.url,
                title: item.title,
                description: [
                    item.itemDescription,
                    item.assetName ?? "",
                    item.assetMime ?? ""
                ].joined(separator: " ")
            )

            if item.type == .file, let assetName = item.assetName {
                additions.append(URL(fileURLWithPath: assetName).pathExtension.lowercased())
            }

            if item.type == .text {
                if SaviText.looksSensitive("\(item.title) \(item.itemDescription)") {
                    additions.append(contentsOf: ["text", "sensitive"])
                } else {
                    additions.append(contentsOf: SaviText.tagsFromPlainText(item.itemDescription))
                }
            }

            let repairedTags = Array(SaviText.dedupeTags(item.tags + additions).prefix(18))
            guard repairedTags != item.tags else { continue }
            items[index].tags = repairedTags
            changed += 1
        }

        prefs.searchTagRepairVersion = Self.currentSearchTagRepairVersion
        persist()
        if changed > 0 {
            NSLog("[SAVI Native] repaired search tags on %d item(s)", changed)
        }
    }

    private func scheduleAppleIntelligenceRefinement(id: String, allowFolderChange: Bool) {
        Task { await refineWithAppleIntelligence(id: id, allowFolderChange: allowFolderChange) }
    }

    private func refineWithAppleIntelligence(id: String, allowFolderChange: Bool) async {
        guard !intelligenceRefinementIds.contains(id) else { return }
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        intelligenceRefinementIds.insert(id)
        defer { intelligenceRefinementIds.remove(id) }

        let item = items[index]
        let candidateFolders = folders.filter { $0.id != "f-all" }
        guard let result = await intelligenceService.classify(
            item: item,
            folders: candidateFolders,
            learningSignals: folderLearningSignals
        ) else { return }
        guard let currentIndex = items.firstIndex(where: { $0.id == id }) else { return }

        var next = items[currentIndex]
        let originalFolderId = next.folderId
        let sensitive = SaviText.looksSensitive("\(next.title) \(next.itemDescription) \(next.url ?? "")")
        let localResult = localFolderClassification(for: next)
        let localInput = classificationInput(for: next)
        if sensitive {
            next.folderId = "f-private-vault"
        } else if allowFolderChange,
                  let folderId = result.folderId,
                  candidateFolders.contains(where: { $0.id == folderId }),
                  SAVIFolderClassifier.shouldAcceptIntelligenceFolder(folderId, localResult: localResult, input: localInput) {
            next.folderId = folderId
        }
        if next.folderId != originalFolderId {
            let reason = sensitive ? "private-guardrail-after-ai" : "apple-intelligence"
            recordFolderDecision(
                input: localInput,
                result: .init(folderId: next.folderId, confidence: localResult.confidence, reason: reason),
                context: sensitive ? "Sensitive guardrail" : "Apple Intelligence"
            )
        }

        let cleanedTags = SaviText.dedupeTags(result.tags).filter { $0.count <= 32 }
        if !cleanedTags.isEmpty {
            next.tags = Array(SaviText.dedupeTags(next.tags + cleanedTags).prefix(10))
        }
        next.color = folder(for: next.folderId)?.color ?? next.color

        guard next != items[currentIndex] else { return }
        items[currentIndex] = next
        persist()
    }

    private func sourceKey(for item: SaviItem) -> String {
        SaviText.sourceKey(for: item.url ?? item.source, fallback: item.source)
    }

    private func sourceLabel(for key: String) -> String {
        SaviText.sourceLabel(for: key, fallback: key)
    }

    private func matchesSearchKind(_ item: SaviItem, kind: String) -> Bool {
        switch kind {
        case "all":
            return true
        case "article":
            return item.type == .article
        case "video":
            return item.type == .video
        case "image":
            return item.type == .image && !isScreenshot(item)
        case "screenshot":
            return isScreenshot(item)
        case "docs":
            return item.type == .file
        case "pdf":
            return isPDF(item)
        case "document":
            return item.type == .file && !isPDF(item)
        case "note":
            return item.type == .text || item.folderId == "f-paste-bin" || item.source.localizedCaseInsensitiveContains("paste")
        case "place":
            return item.type == .place
        case "link":
            return item.type == .link
        default:
            if let legacyType = SaviItemType(rawValue: kind) {
                return item.type == legacyType
            }
            return true
        }
    }

    private func matchesDateFilter(_ item: SaviItem, filter: String) -> Bool {
        guard let option = SearchDateFilter(rawValue: filter), option != .all else { return true }
        let date = Date(timeIntervalSince1970: item.savedAt / 1000)
        let calendar = Calendar.current
        let now = Date()
        switch option {
        case .all:
            return true
        case .today:
            return calendar.isDate(date, inSameDayAs: now)
        case .week:
            guard let start = calendar.date(byAdding: .day, value: -7, to: now) else { return true }
            return date >= start
        case .month:
            guard let start = calendar.date(byAdding: .month, value: -1, to: now) else { return true }
            return date >= start
        }
    }

    private func matchesHasFilter(_ item: SaviItem, filter: String) -> Bool {
        guard let option = SearchHasFilter(rawValue: filter), option != .all else { return true }
        switch option {
        case .all:
            return true
        case .file:
            return item.type == .file
        case .image:
            return item.type == .image
        case .link:
            return item.url?.nilIfBlank != nil
        case .location:
            return item.type == .place
        case .note:
            return item.type == .text || item.folderId == "f-paste-bin"
        }
    }

    func searchKindTitle(for id: String) -> String {
        SaviSearchKind.all.first(where: { $0.id == id })?.title ??
            SaviSearchKind.visibleRail.first(where: { $0.id == id })?.title ??
            "All"
    }

    func dateFilterTitle(for id: String) -> String {
        SearchDateFilter(rawValue: id)?.title ?? SearchDateFilter.all.title
    }

    func hasFilterTitle(for id: String) -> String {
        SearchHasFilter(rawValue: id)?.title ?? SearchHasFilter.all.title
    }

    func primaryKindLabel(for item: SaviItem) -> String {
        if isPDF(item) { return "PDF" }
        if isScreenshot(item) { return "Screenshot" }
        switch item.type {
        case .file: return "Doc"
        case .place: return "Place"
        default: return item.type.label
        }
    }

    func matchReasons(for item: SaviItem, limit: Int = 4) -> [String] {
        var reasons: [String] = []
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let needles = normalizedSearchNeedles(from: trimmed)
        let folderName = folder(for: item.folderId)?.name
        let source = sourceLabel(for: sourceKey(for: item))

        func append(_ value: String?) {
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return }
            if !reasons.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame }) {
                reasons.append(value)
            }
        }

        if typeFilter != "all" || hasFilter != SearchHasFilter.all.rawValue || !needles.isEmpty {
            append(primaryKindLabel(for: item))
        }
        if sourceFilter != "all" || needles.contains(where: { source.lowercased().contains($0) }) {
            append(source)
        }
        if let folderName,
           folderFilter != "f-all" || needles.contains(where: { folderName.lowercased().contains($0) }) {
            append("Keeper: \(folderName)")
        }
        if tagFilter != "all" {
            append("#\(tagFilter)")
        } else if !needles.isEmpty {
            let matchingTags = item.tags.filter { tag in
                let key = tag.lowercased()
                return needles.contains { key.contains($0) || "#\(key)".contains($0) }
            }
            for tag in matchingTags.prefix(2) {
                append("#\(tag)")
            }
        }
        if dateFilter != SearchDateFilter.all.rawValue {
            append(dateFilterTitle(for: dateFilter))
        }
        if reasons.isEmpty, !trimmed.isEmpty {
            if item.title.lowercased().contains(trimmed.lowercased()) {
                append("Title")
            } else if item.itemDescription.lowercased().contains(trimmed.lowercased()) {
                append("Description")
            } else if item.assetName?.lowercased().contains(trimmed.lowercased()) == true {
                append("File name")
            }
        }
        if reasons.isEmpty {
            append("Recently saved")
        }

        return Array(reasons.prefix(limit))
    }

    private func isPDF(_ item: SaviItem) -> Bool {
        let haystack = [
            item.assetName ?? "",
            item.assetMime ?? "",
            item.url ?? "",
            item.title,
            item.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        return item.type == .file &&
            (haystack.contains("application/pdf") || haystack.contains(".pdf") || haystack.contains(" pdf "))
    }

    private func isScreenshot(_ item: SaviItem) -> Bool {
        guard item.type == .image else { return false }
        let haystack = [
            item.assetName ?? "",
            item.title,
            item.source,
            item.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        return haystack.contains("screenshot") ||
            haystack.contains("screen shot") ||
            haystack.contains("screen_capture") ||
            haystack.contains("simulator screen shot")
    }

    private func syncFoldersToShareExtension() {
        let shared = folders
            .filter { $0.id != "f-all" }
            .map { folder in
                SharedFolder(
                    id: folder.id,
                    name: folder.name,
                    color: folder.color,
                    system: folder.system,
                    symbolName: folder.symbolName,
                    order: folder.order
                )
            }
        try? shareStore.saveFolders(shared)
        try? shareStore.saveFolderLearning(folderLearningSignals)
    }

    private func applyFolderOrder(_ orderedIds: [String]) {
        for (order, id) in orderedIds.enumerated() {
            guard let index = folders.firstIndex(where: { $0.id == id }) else { continue }
            folders[index].order = order
        }

        if let allIndex = folders.firstIndex(where: { $0.id == "f-all" }) {
            folders[allIndex].order = orderedIds.count
        }

        folders.sort { lhs, rhs in
            if lhs.order == rhs.order { return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending }
            return lhs.order < rhs.order
        }
    }
}

// MARK: - Apple Intelligence

private struct SaviIntelligenceClassification: Codable {
    var folderId: String?
    var tags: [String]
}

private struct SaviAppleIntelligenceService {
    func statusText() async -> String {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel(useCase: .contentTagging)
            if case .available = model.availability {
                return "Available"
            }
            return "Unavailable on this device"
        }
#endif
        return "Requires iOS 26 and Apple Intelligence"
    }

    func classify(
        item: SaviItem,
        folders: [SaviFolder],
        learningSignals: [SAVIFolderLearningSignal]
    ) async -> SaviIntelligenceClassification? {
        guard !folders.isEmpty else { return nil }
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await classifyWithFoundationModels(item: item, folders: folders, learningSignals: learningSignals)
        }
#endif
        return nil
    }

#if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func classifyWithFoundationModels(
        item: SaviItem,
        folders: [SaviFolder],
        learningSignals: [SAVIFolderLearningSignal]
    ) async -> SaviIntelligenceClassification? {
        let model = SystemLanguageModel(useCase: .contentTagging)
        guard case .available = model.availability else {
            NSLog("[SAVI Native] Apple Intelligence unavailable for item classification: %@", String(describing: model.availability))
            return nil
        }

        return await withTaskGroup(of: SaviIntelligenceClassification?.self) { group in
            group.addTask {
                await requestClassification(item: item, folders: folders, learningSignals: learningSignals, model: model)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                return nil
            }

            while let result = await group.next() {
                group.cancelAll()
                return result
            }
            return nil
        }
    }

    @available(iOS 26.0, *)
    private func requestClassification(
        item: SaviItem,
        folders: [SaviFolder],
        learningSignals: [SAVIFolderLearningSignal],
        model: SystemLanguageModel
    ) async -> SaviIntelligenceClassification? {
        let session = LanguageModelSession(
            model: model,
            instructions: """
            You classify saved items for SAVI. Return only compact JSON. Do not include markdown.
            The JSON must match: {"folderId":"one-folder-id","tags":["tag-one","tag-two"]}.
            Tags must be lowercase, short hashtags without #, and useful for search.
            """
        )
        let prompt = classificationPrompt(item: item, folders: folders, learningSignals: learningSignals)

        do {
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(temperature: 0.0, maximumResponseTokens: 180)
            )
            return decodeClassification(response.content, allowedFolderIds: Set(folders.map(\.id)))
        } catch {
            NSLog("[SAVI Native] Apple Intelligence classification skipped: \(error.localizedDescription)")
            return nil
        }
    }
#endif

    private func classificationPrompt(
        item: SaviItem,
        folders: [SaviFolder],
        learningSignals: [SAVIFolderLearningSignal]
    ) -> String {
        let folderChoices = folders
            .map { "\($0.id): \($0.name)" }
            .joined(separator: "\n")
        let description = String(item.itemDescription.prefix(1_200))
        let url = String((item.url ?? "").prefix(500))
        let existingTags = item.tags.prefix(8).joined(separator: ", ")
        let folderOptions = folders.map { SAVIFolderOption(id: $0.id, name: $0.name) }
        let examples = SAVIFolderClassifier.learningExamples(
            from: learningSignals,
            availableFolders: folderOptions,
            limit: 8
        )
        let examplesBlock = examples.isEmpty ? "" : """

        Local user correction examples:
        \(examples.map { "- \($0)" }.joined(separator: "\n"))

        Prefer these local examples when the current item clearly matches them.
        """

        return """
        Choose the best folder and 3 to 6 tags for this saved item.

        Folder choices:
        \(folderChoices)
        \(examplesBlock)

        Item:
        title: \(item.title)
        description: \(description)
        url: \(url)
        source: \(item.source)
        type: \(item.type.rawValue)
        existing tags: \(existingTags)

        Use exactly one folderId from the folder choices.
        Only choose Private Vault for genuinely private documents, credentials, IDs, receipts, medical, insurance, banking, or tax material.
        Entertainment, trailers, news, and fandom posts are not private just because their title says secret, leaked, vault, or password.
        Return only JSON.
        """
    }

    private func decodeClassification(_ text: String, allowedFolderIds: Set<String>) -> SaviIntelligenceClassification? {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let candidates = [cleaned, extractJSONObject(from: cleaned)].compactMap { $0 }
        for candidate in candidates {
            guard let data = candidate.data(using: .utf8),
                  var decoded = try? JSONDecoder().decode(SaviIntelligenceClassification.self, from: data)
            else { continue }
            if let folderId = decoded.folderId, !allowedFolderIds.contains(folderId) {
                decoded.folderId = nil
            }
            decoded.tags = Array(SaviText.dedupeTags(decoded.tags).prefix(8))
            if decoded.folderId != nil || !decoded.tags.isEmpty {
                return decoded
            }
        }
        return nil
    }

    private func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start <= end
        else { return nil }
        return String(text[start...end])
    }
}

enum SaviSheet: Identifiable {
    case save
    case folderEditor(SaviFolder?)
    case publicProfile
    case friendProfile(SaviFriend)

    var id: String {
        switch self {
        case .save: return "save"
        case .folderEditor(let folder): return "folder-\(folder?.id ?? "new")"
        case .publicProfile: return "public-profile"
        case .friendProfile(let friend): return "friend-\(friend.id)"
        }
    }
}

private struct SaviClipboardDraft: Identifiable {
    let id = UUID()
    var mode: SaviSaveMode
    var title: String
    var subtitle: String
    var url: String?
    var text: String?
    var data: Data?
    var fileName: String?
    var mimeType: String?
    var tags: [String]
}

private enum SaviClipboardReader {
    @MainActor
    static func readDraft() async -> SaviClipboardDraft? {
        let pasteboard = UIPasteboard.general

        if pasteboard.hasImages,
           let image = pasteboard.image,
           let data = image.pngData() ?? image.jpegData(compressionQuality: 0.92) {
            return fileDraft(
                data: data,
                name: "clipboard-image-\(SaviText.backupStamp()).png",
                typeIdentifier: UTType.png.identifier,
                tags: ["clipboard", "image"]
            )
        }

        if pasteboard.hasURLs,
           let url = pasteboard.url {
            if url.isFileURL,
               let draft = fileDraft(from: url, typeIdentifier: UTType.fileURL.identifier) {
                return draft
            }
            return linkDraft(url.absoluteString)
        }

        if pasteboard.hasStrings,
           let draft = textDraft(from: pasteboard.string) {
            return draft
        }

        for provider in pasteboard.itemProviders {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
               let draft = await providerTextDraft(from: provider, typeIdentifier: UTType.url.identifier) {
                return draft
            }
        }

        for provider in pasteboard.itemProviders {
            for typeIdentifier in [UTType.plainText.identifier, UTType.utf8PlainText.identifier, UTType.text.identifier] {
                if provider.hasItemConformingToTypeIdentifier(typeIdentifier),
                   let draft = await providerTextDraft(from: provider, typeIdentifier: typeIdentifier) {
                    return draft
                }
            }
        }

        for provider in pasteboard.itemProviders {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
               let draft = await fileDraft(from: provider, typeIdentifier: UTType.fileURL.identifier) {
                return draft
            }
        }

        for provider in pasteboard.itemProviders {
            if let typeIdentifier = preferredFileTypeIdentifier(for: provider),
               let draft = await dataDraft(from: provider, typeIdentifier: typeIdentifier) {
                return draft
            }
        }

        return nil
    }

    private static func preferredFileTypeIdentifier(for provider: NSItemProvider) -> String? {
        let preferred = [
            UTType.pdf.identifier,
            UTType.image.identifier,
            UTType.movie.identifier,
            UTType.audio.identifier,
            UTType.spreadsheet.identifier,
            UTType.presentation.identifier,
            UTType.compositeContent.identifier
        ]

        if let direct = preferred.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) {
            return direct
        }

        return provider.registeredTypeIdentifiers.first { identifier in
            guard ![
                UTType.url.identifier,
                UTType.plainText.identifier,
                UTType.text.identifier,
                UTType.utf8PlainText.identifier,
                UTType.data.identifier,
                UTType.item.identifier
            ].contains(identifier),
                  let type = UTType(identifier)
            else { return false }
            return type.conforms(to: .data) || type.conforms(to: .item)
        }
    }

    private static func linkDraft(_ urlString: String) -> SaviClipboardDraft {
        SaviClipboardDraft(
            mode: .link,
            title: "Clipboard link",
            subtitle: SaviText.sourceLabel(for: urlString, fallback: "Web"),
            url: urlString,
            text: nil,
            data: nil,
            fileName: nil,
            mimeType: nil,
            tags: SaviText.inferredTags(type: SaviText.inferredType(for: urlString), url: urlString, title: "", description: "")
        )
    }

    private static func textDraft(from rawText: String?) -> SaviClipboardDraft? {
        guard let text = rawText?.nilIfBlank else { return nil }
        if let url = URL(string: SaviText.normalizedURL(text)),
           url.host != nil,
           text.range(of: #"\s"#, options: .regularExpression) == nil {
            return linkDraft(url.absoluteString)
        }

        return SaviClipboardDraft(
            mode: .text,
            title: "Clipboard text",
            subtitle: SaviText.titleFromPlainText(text),
            url: nil,
            text: text,
            data: nil,
            fileName: nil,
            mimeType: nil,
            tags: SaviText.tagsFromPlainText(text)
        )
    }

    private static func providerTextDraft(from provider: NSItemProvider, typeIdentifier: String) async -> SaviClipboardDraft? {
        return await withCheckedContinuation { (continuation: CheckedContinuation<SaviClipboardDraft?, Never>) in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                if let url = item as? URL {
                    if url.isFileURL {
                        continuation.resume(returning: fileDraft(from: url, typeIdentifier: UTType.fileURL.identifier))
                    } else {
                        continuation.resume(returning: linkDraft(url.absoluteString))
                    }
                    return
                }

                if let url = item as? NSURL {
                    let value = url as URL
                    if value.isFileURL {
                        continuation.resume(returning: fileDraft(from: value, typeIdentifier: UTType.fileURL.identifier))
                    } else {
                        continuation.resume(returning: linkDraft(value.absoluteString))
                    }
                    return
                }

                if let text = item as? String {
                    continuation.resume(returning: textDraft(from: text))
                    return
                }

                if let text = item as? NSString {
                    continuation.resume(returning: textDraft(from: text as String))
                    return
                }

                if let data = item as? Data,
                   let text = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: textDraft(from: text))
                    return
                }

                continuation.resume(returning: nil)
            }
        }
    }

    private static func fileDraft(from provider: NSItemProvider, typeIdentifier: String) async -> SaviClipboardDraft? {
        let suggestedName = provider.suggestedName
        return await withCheckedContinuation { (continuation: CheckedContinuation<SaviClipboardDraft?, Never>) in
            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, _ in
                guard let url else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(
                    returning: fileDraft(
                        from: url,
                        preferredName: suggestedName,
                        typeIdentifier: typeIdentifier
                    )
                )
            }
        }
    }

    private static func dataDraft(from provider: NSItemProvider, typeIdentifier: String) async -> SaviClipboardDraft? {
        let suggestedName = provider.suggestedName
        return await withCheckedContinuation { (continuation: CheckedContinuation<SaviClipboardDraft?, Never>) in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                guard let data else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(
                    returning: fileDraft(
                        data: data,
                        name: suggestedName,
                        typeIdentifier: typeIdentifier,
                        tags: ["clipboard"]
                    )
                )
            }
        }
    }

    private static func fileDraft(from url: URL, preferredName: String? = nil, typeIdentifier: String) -> SaviClipboardDraft? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return fileDraft(
            data: data,
            name: preferredName?.nilIfBlank ?? url.lastPathComponent.nilIfBlank,
            typeIdentifier: typeIdentifier,
            tags: ["clipboard"]
        )
    }

    private static func fileDraft(data: Data, name: String?, typeIdentifier: String, tags: [String]) -> SaviClipboardDraft {
        let type = UTType(typeIdentifier)
        let mimeType = type?.preferredMIMEType ?? "application/octet-stream"
        let fileName = name?.nilIfBlank ?? "clipboard.\(SaviText.fileExtension(forMimeType: mimeType))"
        let itemType = SaviText.typeForAsset(name: fileName, mimeType: mimeType)
        return SaviClipboardDraft(
            mode: .file,
            title: "Clipboard file",
            subtitle: "\(fileName) · \(SaviText.formatBytes(Int64(data.count)))",
            url: nil,
            text: nil,
            data: data,
            fileName: fileName,
            mimeType: mimeType,
            tags: SaviText.dedupeTags(tags + [itemType.rawValue])
        )
    }
}

// MARK: - Storage

struct SaviStorage {
    private let fileManager = FileManager.default
    private let libraryFileName = "savi_native_library.json"
    private let assetsDirectoryName = "native_assets"

    func rootURL() throws -> URL {
        let root: URL
        if let appGroup = fileManager.containerURL(forSecurityApplicationGroupIdentifier: SAVISharedContainer.appGroupIdentifier) {
            root = appGroup.appendingPathComponent("native", isDirectory: true)
        } else {
            root = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("SAVI-native", isDirectory: true)
        }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    func assetsDirectoryURL() throws -> URL {
        let directory = try rootURL().appendingPathComponent(assetsDirectoryName, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func libraryFileURL() throws -> URL {
        try rootURL().appendingPathComponent(libraryFileName)
    }

    func loadLibrary() throws -> SaviLibraryState? {
        let url = try libraryFileURL()
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(SaviLibraryState.self, from: data)
    }

    func saveLibrary(_ state: SaviLibraryState) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state)
        try data.write(to: try libraryFileURL(), options: .atomic)
    }

    func copyAsset(from sourceURL: URL, preferredName: String? = nil) throws -> SaviAsset {
        let originalName = preferredName?.nilIfBlank ?? sourceURL.lastPathComponent
        let id = UUID().uuidString
        let fileName = safeAssetFileName(id: id, preferredName: originalName)
        let destination = try assetsDirectoryURL().appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)
        let values = try destination.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])
        let size = Int64(values.fileSize ?? 0)
        let type = values.contentType?.preferredMIMEType ?? SaviText.mimeType(forExtension: destination.pathExtension)
        return SaviAsset(
            id: id,
            name: originalName,
            type: type,
            size: size,
            fileName: fileName,
            createdAt: Date().timeIntervalSince1970 * 1000
        )
    }

    func writeBackupAsset(_ asset: SaviBackupAsset) throws -> SaviAsset {
        try writeDataURL(asset.dataUrl, preferredName: asset.name, id: asset.id, explicitType: asset.type, explicitSize: asset.size)
    }

    func writeDataURL(_ dataURL: String, preferredName: String, id: String = UUID().uuidString, explicitType: String? = nil, explicitSize: Int64? = nil) throws -> SaviAsset {
        let decoded = try SaviText.decodeDataURL(dataURL)
        let type = explicitType?.nilIfBlank ?? decoded.mimeType
        let fileName = safeAssetFileName(id: id, preferredName: preferredName.nilIfBlank ?? "asset.\(SaviText.fileExtension(forMimeType: type))")
        let destination = try assetsDirectoryURL().appendingPathComponent(fileName)
        try decoded.data.write(to: destination, options: .atomic)
        return SaviAsset(
            id: id,
            name: preferredName,
            type: type,
            size: explicitSize ?? Int64(decoded.data.count),
            fileName: fileName,
            createdAt: Date().timeIntervalSince1970 * 1000
        )
    }

    func writeAssetData(_ data: Data, preferredName: String, mimeType: String, id: String = UUID().uuidString) throws -> SaviAsset {
        let type = mimeType.nilIfBlank ?? "application/octet-stream"
        let fallbackName = "clipboard.\(SaviText.fileExtension(forMimeType: type))"
        let safeName = preferredName.nilIfBlank ?? fallbackName
        let fileName = safeAssetFileName(id: id, preferredName: safeName)
        let destination = try assetsDirectoryURL().appendingPathComponent(fileName)
        try data.write(to: destination, options: .atomic)
        return SaviAsset(
            id: id,
            name: safeName,
            type: type,
            size: Int64(data.count),
            fileName: fileName,
            createdAt: Date().timeIntervalSince1970 * 1000
        )
    }

    func assetURL(for asset: SaviAsset) -> URL? {
        try? assetsDirectoryURL().appendingPathComponent(asset.fileName)
    }

    func deleteAsset(id: String, assets: [SaviAsset]) throws {
        guard let asset = assets.first(where: { $0.id == id }),
              let url = assetURL(for: asset),
              fileManager.fileExists(atPath: url.path)
        else { return }
        try fileManager.removeItem(at: url)
    }

    func clearAssetsDirectory() throws {
        let directory = try assetsDirectoryURL()
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for url in contents {
            try fileManager.removeItem(at: url)
        }
    }

    func buildBackup(folders: [SaviFolder], items: [SaviItem], assets: [SaviAsset], folderLearning: [SAVIFolderLearningSignal]) throws -> SaviBackup {
        let backupAssets: [SaviBackupAsset] = try assets.compactMap { asset in
            guard let url = assetURL(for: asset),
                  fileManager.fileExists(atPath: url.path)
            else { return nil }
            let data = try Data(contentsOf: url)
            let dataURL = "data:\(asset.type);base64,\(data.base64EncodedString())"
            return SaviBackupAsset(id: asset.id, name: asset.name, type: asset.type, size: asset.size, dataUrl: dataURL)
        }

        return SaviBackup(
            app: "SAVI",
            version: 2,
            exportedAt: ISO8601DateFormatter().string(from: Date()),
            folders: folders,
            items: items,
            assets: backupAssets,
            folderLearning: folderLearning
        )
    }

    private func safeAssetFileName(id: String, preferredName: String) -> String {
        let cleanName = preferredName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = cleanName.isEmpty ? "asset" : cleanName
        return "\(id)-\(fallback)"
    }
}

// MARK: - Metadata

struct SaviMetadata {
    var title: String?
    var description: String?
    var imageURL: String?
    var provider: String?
    var tags: [String]
    var type: SaviItemType?
}

private enum SaviMetadataResult {
    case metadata(SaviMetadata)
    case empty
    case timedOut
}

private struct SaviOEmbedResponse: Decodable {
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

struct SaviMetadataService {
    func fetch(for url: URL, waitsForThumbnail: Bool = false) async -> SaviMetadata? {
        await withTaskGroup(of: SaviMetadataResult.self) { group in
            if SaviText.isYouTube(url) {
                group.addTask {
                    guard let metadata = try? await fetchYouTubeMetadata(for: url) else { return .empty }
                    return .metadata(metadata)
                }
            } else {
                group.addTask {
                    guard let metadata = try? await fetchProviderSpecificMetadata(for: url) else { return .empty }
                    return .metadata(metadata)
                }
                group.addTask {
                    guard let metadata = try? await fetchNoembedMetadata(for: url) else { return .empty }
                    return .metadata(metadata)
                }
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
                try? await Task.sleep(nanoseconds: waitsForThumbnail ? 30_000_000_000 : 8_000_000_000)
                return .timedOut
            }

            var candidates: [SaviMetadata] = []
            while let result = await group.next() {
                switch result {
                case .metadata(let metadata):
                    candidates.append(metadata)
                    if metadataLooksComplete(metadata, waitsForThumbnail: waitsForThumbnail) {
                        group.cancelAll()
                        return merge(candidates)
                    }
                case .empty:
                    continue
                case .timedOut:
                    group.cancelAll()
                    return candidates.isEmpty ? nil : merge(candidates)
                }
            }
            return candidates.isEmpty ? nil : merge(candidates)
        }
    }

    private func fetchYouTubeMetadata(for url: URL) async throws -> SaviMetadata {
        let canonical = SaviText.canonicalYouTubeURL(from: url)
        if let metadata = try? await fetchNoembedMetadata(for: canonical) {
            return SaviMetadata(
                title: metadata.title,
                description: metadata.description ?? "Video from YouTube.",
                imageURL: metadata.imageURL ?? SaviText.youtubeThumbnailURL(for: canonical),
                provider: metadata.provider ?? "YouTube",
                tags: SaviText.dedupeTags(metadata.tags + ["youtube", "video"]),
                type: .video
            )
        }
        if let metadata = try? await fetchYouTubeOEmbedMetadata(for: canonical) {
            return metadata
        }
        return SaviMetadata(
            title: nil,
            description: "Video from YouTube.",
            imageURL: SaviText.youtubeThumbnailURL(for: canonical),
            provider: "YouTube",
            tags: ["youtube", "video"],
            type: .video
        )
    }

    private func fetchYouTubeOEmbedMetadata(for url: URL) async throws -> SaviMetadata {
        let endpoint = try oEmbedEndpoint(
            base: "https://www.youtube.com/oembed",
            url: url,
            extraItems: [URLQueryItem(name: "format", value: "json")]
        )
        let decoded = try JSONDecoder().decode(SaviOEmbedResponse.self, from: try await fetchData(from: endpoint))
        return SaviMetadata(
            title: SaviText.cleanedTitle(decoded.title, for: url),
            description: decoded.authorName?.nilIfBlank.map { "\($0) via YouTube" } ?? "YouTube video",
            imageURL: decoded.thumbnailURL ?? SaviText.youtubeThumbnailURL(for: url),
            provider: decoded.providerName ?? "YouTube",
            tags: ["youtube", "video"],
            type: .video
        )
    }

    private func fetchProviderSpecificMetadata(for url: URL) async throws -> SaviMetadata? {
        if SaviText.isTikTok(url) {
            return try await fetchGenericOEmbedMetadata(
                base: "https://www.tiktok.com/oembed",
                for: url,
                defaultProvider: "TikTok",
                tags: ["tiktok", "video"],
                type: .video
            )
        }

        if SaviText.isTwitterX(url) {
            return try await fetchGenericOEmbedMetadata(
                base: "https://publish.twitter.com/oembed",
                for: url,
                defaultProvider: "X",
                tags: ["x", "twitter", "post"],
                type: .article,
                extraItems: [URLQueryItem(name: "omit_script", value: "true")]
            )
        }

        if SaviText.isReddit(url) {
            return try await fetchGenericOEmbedMetadata(
                base: "https://www.reddit.com/oembed",
                for: url,
                defaultProvider: "Reddit",
                tags: ["reddit", "post"],
                type: .article
            )
        }

        if SaviText.isVimeo(url) {
            return try await fetchGenericOEmbedMetadata(
                base: "https://vimeo.com/api/oembed.json",
                for: url,
                defaultProvider: "Vimeo",
                tags: ["vimeo", "video"],
                type: .video
            )
        }

        if SaviText.isSpotify(url) {
            return try await fetchGenericOEmbedMetadata(
                base: "https://open.spotify.com/oembed",
                for: url,
                defaultProvider: "Spotify",
                tags: ["spotify", "music"],
                type: .link
            )
        }

        if SaviText.isSoundCloud(url) {
            return try await fetchGenericOEmbedMetadata(
                base: "https://soundcloud.com/oembed",
                for: url,
                defaultProvider: "SoundCloud",
                tags: ["soundcloud", "music"],
                type: .link,
                extraItems: [URLQueryItem(name: "format", value: "json")]
            )
        }

        if SaviText.isPinterest(url) {
            return try await fetchGenericOEmbedMetadata(
                base: "https://www.pinterest.com/oembed.json",
                for: url,
                defaultProvider: "Pinterest",
                tags: ["pinterest", "image", "inspiration"],
                type: .image
            )
        }

        if SaviText.isBluesky(url) {
            return try await fetchGenericOEmbedMetadata(
                base: "https://embed.bsky.app/oembed",
                for: url,
                defaultProvider: "Bluesky",
                tags: ["bluesky", "post"],
                type: .article
            )
        }

        if SaviText.isInstagram(url) {
            return SaviMetadata(
                title: SaviText.isInstagramReel(url) ? "Instagram Reel" : "Instagram Post",
                description: "Saved from Instagram.",
                imageURL: nil,
                provider: "Instagram",
                tags: SaviText.isInstagramReel(url) ? ["instagram", "reel", "video"] : ["instagram", "post"],
                type: SaviText.isInstagramReel(url) ? .video : .article
            )
        }

        return nil
    }

    private func fetchGenericOEmbedMetadata(
        base: String,
        for url: URL,
        defaultProvider: String,
        tags: [String],
        type: SaviItemType?,
        extraItems: [URLQueryItem] = []
    ) async throws -> SaviMetadata {
        let endpoint = try oEmbedEndpoint(base: base, url: url, extraItems: extraItems)
        let decoded = try JSONDecoder().decode(SaviOEmbedResponse.self, from: try await fetchData(from: endpoint))
        let provider = SaviText.providerDisplayName(decoded.providerName, fallback: defaultProvider)
        let embeddedText = SaviText.oEmbedPrimaryText(from: decoded.html)
        let title = SaviText.cleanedTitle(decoded.title, for: url) ?? SaviText.cleanedTitle(embeddedText, for: url)
        let description = SaviText.cleanedMetadataDescription(decoded.description) ??
            decoded.authorName?.nilIfBlank.map { "\($0) via \(provider)" } ??
            (title == nil ? embeddedText : nil) ??
            "Saved from \(provider)."
        return SaviMetadata(
            title: title,
            description: description,
            imageURL: decoded.thumbnailURL,
            provider: provider,
            tags: tags,
            type: type
        )
    }

    private func fetchNoembedMetadata(for url: URL) async throws -> SaviMetadata {
        let endpoint = try oEmbedEndpoint(base: "https://noembed.com/embed", url: url)
        let decoded = try JSONDecoder().decode(SaviOEmbedResponse.self, from: try await fetchData(from: endpoint))
        let tags = SaviText.dedupeTags([decoded.providerName, decoded.title, decoded.type].compactMap { $0 }.flatMap { value in
            ["youtube", "instagram", "tiktok", "reddit", "spotify", "vimeo", "pinterest", "soundcloud", "bluesky", "twitter", "video", "post"].filter { value.lowercased().contains($0) }
        })
        let provider = decoded.providerName?.nilIfBlank.map { SaviText.providerDisplayName($0, fallback: $0) }
        let author = decoded.authorName?.nilIfBlank
        let embeddedText = SaviText.oEmbedPrimaryText(from: decoded.html)
        return SaviMetadata(
            title: SaviText.cleanedTitle(decoded.title, for: url) ?? SaviText.cleanedTitle(embeddedText, for: url),
            description: SaviText.cleanedMetadataDescription(decoded.description) ?? author.map { author in
                if let provider {
                    return "\(author) via \(provider)"
                }
                return author
            } ?? provider ?? embeddedText,
            imageURL: decoded.thumbnailURL,
            provider: provider,
            tags: tags,
            type: decoded.type == "video" ? .video : nil
        )
    }

    private func fetchHTMLMetadata(for url: URL) async throws -> SaviMetadata {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<400).contains(http.statusCode),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode)
        else {
            throw URLError(.badServerResponse)
        }
        let image = SaviText.firstHTMLMetaContent(in: html, keys: ["og:image", "twitter:image"]).flatMap { value in
            URL(string: value, relativeTo: url)?.absoluteURL.absoluteString
        }
        let provider = SaviText.firstHTMLMetaContent(in: html, keys: ["og:site_name", "application-name"]) ?? SaviText.hostDisplayName(for: url)
        let rawTitle = SaviText.firstHTMLMetaContent(in: html, keys: ["og:title", "twitter:title"]) ?? SaviText.htmlTitle(in: html)
        let description = SaviText.cleanedMetadataDescription(SaviText.firstHTMLMetaContent(in: html, keys: ["og:description", "description", "twitter:description"])) ??
            SaviText.instagramCaption(from: rawTitle, for: url)
        return SaviMetadata(
            title: SaviText.cleanedTitle(rawTitle, for: url),
            description: description,
            imageURL: image,
            provider: provider,
            tags: [],
            type: SaviText.inferredType(for: url.absoluteString)
        )
    }

    private func fetchLinkPresentationMetadata(for url: URL) async throws -> SaviMetadata {
        let provider = LPMetadataProvider()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                provider.startFetchingMetadata(for: url) { metadata, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let metadata else {
                        continuation.resume(throwing: URLError(.cannotParseResponse))
                        return
                    }
                    let providerName = metadata.url?.host ?? metadata.originalURL?.host
                    Task {
                        let imageURL = try? await loadLinkPresentationImageDataURL(from: metadata.imageProvider)
                        continuation.resume(returning: SaviMetadata(
                            title: SaviText.cleanedTitle(metadata.title, for: url),
                            description: nil,
                            imageURL: imageURL,
                            provider: providerName.map { SaviText.providerDisplayName(SaviText.hostDisplayName(for: URL(string: "https://\($0)") ?? url), fallback: SaviText.sourceLabel(for: url.absoluteString, fallback: "Web")) },
                            tags: [],
                            type: SaviText.inferredType(for: url.absoluteString)
                        ))
                    }
                }
            }
        } onCancel: {
            provider.cancel()
        }
    }

    private func loadLinkPresentationImageDataURL(from provider: NSItemProvider?) async throws -> String? {
        guard let provider, provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else { return nil }
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

    private func fetchData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func oEmbedEndpoint(base: String, url: URL, extraItems: [URLQueryItem] = []) throws -> String {
        guard var components = URLComponents(string: base) else { throw URLError(.badURL) }
        components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)] + extraItems
        guard let endpoint = components.url?.absoluteString else { throw URLError(.badURL) }
        return endpoint
    }

    private func merge(_ candidates: [SaviMetadata]) -> SaviMetadata {
        SaviMetadata(
            title: bestTitle(from: candidates),
            description: candidates.compactMap(\.description).compactMap(SaviText.cleanedMetadataDescription).max(by: { $0.count < $1.count }),
            imageURL: candidates.first(where: { $0.imageURL?.nilIfBlank != nil })?.imageURL,
            provider: candidates.first(where: { $0.provider?.nilIfBlank != nil })?.provider,
            tags: SaviText.dedupeTags(candidates.flatMap(\.tags)),
            type: bestType(from: candidates)
        )
    }

    private func bestType(from candidates: [SaviMetadata]) -> SaviItemType? {
        let types = candidates.compactMap(\.type)
        for preferred in [SaviItemType.video, .image, .place, .file, .text, .link] where types.contains(preferred) {
            return preferred
        }
        return types.first
    }

    private func metadataLooksComplete(_ metadata: SaviMetadata, waitsForThumbnail: Bool) -> Bool {
        if waitsForThumbnail {
            guard metadata.imageURL?.nilIfBlank != nil else { return false }
            if metadata.title?.nilIfBlank == nil {
                return true
            }
        }
        guard let title = metadata.title?.nilIfBlank,
              titleQualityScore(title) > 0
        else { return false }

        let normalizedTitle = title.lowercased()
        let provider = metadata.provider?.lowercased() ?? ""
        if provider.contains("instagram"),
           metadata.imageURL?.nilIfBlank == nil,
           ["instagram reel", "instagram post"].contains(normalizedTitle) {
            return false
        }

        return metadata.description?.nilIfBlank != nil ||
            metadata.imageURL?.nilIfBlank != nil ||
            metadata.provider?.nilIfBlank != nil
    }

    private func bestTitle(from candidates: [SaviMetadata]) -> String? {
        candidates
            .compactMap(\.title)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .max { lhs, rhs in
                titleQualityScore(lhs) < titleQualityScore(rhs)
            }
    }

    private func titleQualityScore(_ title: String) -> Int {
        let normalized = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if SaviText.isGenericFetchedTitle(normalized) { return 0 }
        var score = min(title.count, 80)
        if normalized.contains(" on instagram:") { score += 30 }
        if normalized.contains("instagram reel") || normalized.contains("instagram post") { score += 8 }
        if normalized.contains("#") { score += 6 }
        return score
    }
}

// MARK: - Root UI

struct NativeSaviRootView: View {
    @EnvironmentObject private var store: SaviStore
    @State private var backupImportPresented = false

    var body: some View {
        ZStack(alignment: .bottom) {
            SaviTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                selectedScreen
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                if store.prefs.onboarded {
                    bottomBar
                }
            }
                .sheet(item: $store.presentedSheet) { sheet in
                    switch sheet {
                    case .save:
                        SaveSheet()
                            .environmentObject(store)
                    case .folderEditor(let folder):
                        FolderEditorSheet(folder: folder)
                            .environmentObject(store)
                    case .publicProfile:
                        PublicProfileSheet()
                            .environmentObject(store)
                    case .friendProfile(let friend):
                        FriendProfileSheet(friend: friend)
                            .environmentObject(store)
                    }
                }
                .sheet(item: $store.presentedItem) { item in
                    ItemDetailSheet(item: item)
                        .environmentObject(store)
                }
                .sheet(item: $store.editingItem) { item in
                    ItemEditorSheet(item: item)
                        .environmentObject(store)
                }
                .sheet(item: Binding<AssetPreviewURL?>(
                    get: { store.quickLookAssetURL.map { AssetPreviewURL(url: $0) } },
                    set: { store.quickLookAssetURL = $0?.url }
                )) { preview in
                    QuickLookPreview(url: preview.url)
                }
                .sheet(item: Binding<WebPreviewURL?>(
                    get: { store.webPreviewURL.map { WebPreviewURL(url: $0) } },
                    set: { store.webPreviewURL = $0?.url }
                )) { preview in
                    SafariLinkPreview(url: preview.url)
                        .ignoresSafeArea()
                }
                .sheet(isPresented: $store.isSearchRefinePresented) {
                    SearchRefineSheet()
                        .environmentObject(store)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
                .fileImporter(isPresented: $backupImportPresented, allowedContentTypes: [.json]) { result in
                    if case .success(let url) = result {
                        Task { await store.importBackup(from: url) }
                    }
                }
                .fileExporter(
                    isPresented: $store.isExportingBackup,
                    document: store.backupDocument ?? SaviBackupDocument(data: Data()),
                    contentType: .json,
                    defaultFilename: "savi-backup-\(SaviText.backupStamp()).json"
                ) { result in
                    if case .failure = result {
                        store.toast = "Backup export was cancelled."
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await store.importPendingShares()
                        await store.refreshStaleMetadata()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    Task {
                        await store.importPendingShares()
                        await store.refreshStaleMetadata()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    store.lockProtectedKeepers()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    store.lockProtectedKeepers()
                }

            if !store.prefs.onboarded {
                OnboardingView()
                    .environmentObject(store)
                    .transition(.opacity)
                    .zIndex(2)
            }

            if store.prefs.onboarded, let step = store.activeCoachStep {
                SaviCoachOverlay(
                    step: step,
                    currentIndex: (SaviCoachStep.allCases.firstIndex(of: step) ?? 0) + 1,
                    totalCount: SaviCoachStep.allCases.count,
                    nextAction: { store.advanceCoachTour() },
                    skipAction: { store.completeCoachTour() }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(3)
            }

            if let toast = store.toast {
                ToastView(message: toast)
                    .padding(.bottom, store.prefs.onboarded ? 104 : 72)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            if store.toast == toast {
                                withAnimation { store.toast = nil }
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var selectedScreen: some View {
        switch store.selectedTab {
        case .home:
            HomeScreen()
        case .search:
            SearchScreen()
        case .explore:
            ExploreScreen()
        case .folders:
            FoldersScreen()
        case .profile:
            ProfileScreen(backupImportPresented: $backupImportPresented)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(SaviTheme.cardStroke)
                .frame(height: 1)
            SaviBottomBar()
                .environmentObject(store)
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .padding(.bottom, 4)
        }
        .background(SaviTheme.surfaceRaised.ignoresSafeArea(edges: .bottom))
    }
}

struct SaviBottomBar: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        HStack(spacing: 6) {
            SaviBottomTab(tab: .home, title: "Home", symbolName: "house.fill")
            SaviBottomTab(tab: .search, title: "Search", symbolName: "magnifyingglass")

            Button {
                store.openAddSheet()
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.black))
                    .frame(width: 46, height: 46)
                    .background(SaviTheme.chartreuse)
                    .foregroundStyle(.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Add save")

            SaviBottomTab(tab: .explore, title: "Explore", symbolName: "sparkles")
            SaviBottomTab(tab: .profile, title: "Profile", symbolName: "person.crop.circle.fill")
        }
    }
}

struct SaviBottomTab: View {
    @EnvironmentObject private var store: SaviStore
    let tab: SaviTab
    let title: String
    let symbolName: String

    private var isSelected: Bool {
        store.selectedTab == tab
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                store.setTab(tab)
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: symbolName)
                    .font(.system(size: 18, weight: .bold))
                Text(title)
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isSelected ? .black : SaviTheme.text)
            .background(isSelected ? SaviTheme.chartreuse : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct HomeScreen: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HeaderBlock(
                        eyebrow: "\(store.items.count) saves",
                        title: "SAVI",
                        subtitle: "Your pocket archive for links, files, notes, and the odd brilliant thing.",
                        titleSize: 36
                    )

                    FolderStrip(title: "Recent Keepers", folders: store.homeFolders())

                    SectionHeader(title: "Recent Saves", actionTitle: "Search") {
                        store.resetFilters()
                        store.setTab(.search)
                    }

                    LazyVStack(spacing: 10) {
                        ForEach(store.filteredItems(for: .home)) { item in
                            ItemRow(item: item)
                        }
                    }

                    if store.items.isEmpty {
                        EmptyStateView(
                            symbol: "tray.fill",
                            title: "Nothing saved yet",
                            message: "Use Add or the iOS share sheet and SAVI will start filling this space."
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 14)
            }
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
        }
    }
}

struct SearchScreen: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    SearchHeaderBlock()

                    SearchBar(text: $store.query, prompt: "Search anything you saved...")
                        .id("search-bar")

                    SearchKindRail()

                    if store.hasActiveSearchControls {
                        ActiveSearchFiltersRow()
                    }

                    SearchResultsHeading()

                    LazyVStack(spacing: 10) {
                        ForEach(store.filteredItems()) { item in
                            ItemRow(item: item, context: .search, showsMatchReasons: true)
                        }
                    }

                    if store.filteredItems().isEmpty {
                        EmptyStateView(
                            symbol: "magnifyingglass",
                            title: "No matches",
                            message: "Try a source, Keeper, file name, or a smaller phrase."
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 14)
            }
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
        }
    }
}

struct SearchHeaderBlock: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SEARCH")
                    .font(SaviType.ui(.caption, weight: .heavy))
                    .foregroundStyle(SaviTheme.accentText)
                Text("Find it fast")
                    .font(SaviType.display(size: 31, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 10)

            Text("\(store.filteredItems().count)")
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(SaviTheme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(SaviTheme.cardStroke, lineWidth: 1))
                .accessibilityLabel("\(store.filteredItems().count) searchable saves")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SearchResultsHeading: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SaviType.ui(.title3, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text(subtitle)
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            SearchRefineButton()
        }
    }

    private var title: String {
        store.hasActiveSearchControls ? "Results" : "Recently saved"
    }

    private var subtitle: String {
        let count = store.filteredItems().count
        if store.hasActiveSearchControls {
            return "\(count) match\(count == 1 ? "" : "es")"
        }
        return "\(count) newest save\(count == 1 ? "" : "s")"
    }
}

struct ExploreScreen: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeaderBlock(
                        eyebrow: "Explore",
                        title: "SAVI shuffle",
                        subtitle: "A random scroll of links, videos, images, and places worth revisiting."
                    )

                    ExploreLibraryView(seed: $store.exploreSeed)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 14)
            }
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
        }
    }
}

struct FoldersScreen: View {
    @EnvironmentObject private var store: SaviStore

    private var folderViewMode: SaviFolderViewMode {
        SaviFolderViewMode(rawValue: store.prefs.folderViewMode) ?? .grid
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HeaderBlock(
                        eyebrow: "Keepers",
                        title: "Keepers",
                        subtitle: "Your saved stacks, ordered your way.",
                        titleSize: 32
                    )

                    FolderLibraryView(viewMode: folderViewMode)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 14)
            }
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
        }
    }
}

struct ProfileScreen: View {
    @EnvironmentObject private var store: SaviStore
    @Binding var backupImportPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeaderBlock(
                        eyebrow: "Profile",
                        title: "Settings",
                        subtitle: "Tune SAVI, manage backups, and keep your local archive tidy."
                    )

                    StatsPanel()

                    SettingsCard(title: "Keepers", symbol: "folder.fill") {
                        Button {
                            store.openKeepersManagement()
                        } label: {
                            Label("Manage Keepers", systemImage: "square.grid.2x2.fill")
                        }
                        .buttonStyle(SaviSecondaryButtonStyle())
                    }

                    FriendsSettingsCard()

                    SettingsCard(title: "Guide", symbol: "questionmark.circle.fill") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Replay the quick tour for Home, Add, Share, Search, Explore, Keepers, and Profile.")
                                .font(SaviType.ui(.subheadline, weight: .semibold))
                                .foregroundStyle(SaviTheme.textMuted)
                                .fixedSize(horizontal: false, vertical: true)

                            Button {
                                store.startCoachTour()
                            } label: {
                                Label("Replay quick tour", systemImage: "sparkles")
                            }
                            .buttonStyle(SaviSecondaryButtonStyle())
                        }
                    }

                    SettingsCard(title: "Appearance", symbol: "moon.stars.fill") {
                        HStack(spacing: 10) {
                            ThemeButton(title: "Dark", active: store.prefs.themeMode == "dark") {
                                store.setTheme("dark")
                            }
                            ThemeButton(title: "Light", active: store.prefs.themeMode == "light") {
                                store.setTheme("light")
                            }
                        }
                    }

                    SettingsCard(title: "Backup", symbol: "externaldrive.fill") {
                        VStack(spacing: 10) {
                            Button {
                                store.buildBackupDocument()
                            } label: {
                                Label("Export SAVI backup", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(SaviPrimaryButtonStyle())

                            Button {
                                backupImportPresented = true
                            } label: {
                                Label("Restore backup", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(SaviSecondaryButtonStyle())

                            if let migration = store.migrationMessage {
                                Text(migration)
                                    .font(.footnote)
                                    .foregroundStyle(SaviTheme.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    FolderBrainSettingsCard()

                    SettingsCard(title: "Library", symbol: "archivebox.fill") {
                        VStack(spacing: 10) {
                            Button {
                                store.clearDemoContent()
                            } label: {
                                Label("Clear demo content", systemImage: "sparkles")
                            }
                            .buttonStyle(SaviSecondaryButtonStyle())

                            Button {
                                store.restoreSeeds()
                            } label: {
                                Label("Restore demo library", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(SaviSecondaryButtonStyle())

                            Button(role: .destructive) {
                                store.clearEverything()
                            } label: {
                                Label("Delete everything on this device", systemImage: "trash.fill")
                            }
                            .buttonStyle(SaviDangerButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 14)
            }
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
        }
    }
}

struct FriendsSettingsCard: View {
    @EnvironmentObject private var store: SaviStore
    @State private var friendUsername = ""

    var body: some View {
        SettingsCard(title: "Friends", symbol: "person.2.fill") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(Color(hex: store.publicProfile.avatarColor))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Text(store.publicProfile.normalizedUsername.prefix(1).uppercased())
                                .font(SaviType.ui(.headline, weight: .black))
                                .foregroundStyle(SaviTheme.foreground(onHex: store.publicProfile.avatarColor))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("@\(store.publicProfile.normalizedUsername)")
                            .font(SaviType.ui(.headline, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                        Text("\(store.cloudKitStatus) · \(store.publicSharedLinks().count) public link preview\(store.publicSharedLinks().count == 1 ? "" : "s")")
                            .font(SaviType.ui(.caption, weight: .semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Button {
                        store.presentedSheet = .publicProfile
                    } label: {
                        Image(systemName: "pencil")
                            .font(.headline.weight(.bold))
                            .frame(width: 38, height: 38)
                            .background(SaviTheme.surfaceRaised)
                            .foregroundStyle(SaviTheme.accentText)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit public profile")
                }

                Toggle(isOn: Binding(
                    get: { store.publicProfile.isLinkSharingEnabled },
                    set: { store.setLinkSharingEnabled($0) }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Link sharing")
                            .font(SaviType.ui(.subheadline, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                        Text("Only URL saves from public Keepers sync. Files, PDFs, images, notes, and Private Vault never publish.")
                            .font(SaviType.ui(.caption, weight: .semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(.switch)
                .tint(SaviTheme.chartreuse)

                HStack(spacing: 8) {
                    TextField("@username", text: $friendUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(SaviType.ui(.subheadline, weight: .bold))
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .background(SaviTheme.surface)
                        .foregroundStyle(SaviTheme.text)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(SaviTheme.cardStroke, lineWidth: 1)
                        )

                    Button {
                        store.addFriend(username: friendUsername)
                        friendUsername = ""
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline.weight(.black))
                            .frame(width: 44, height: 44)
                            .background(SaviTheme.chartreuse)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add friend")
                }

                if store.friends.isEmpty {
                    Text("Add a friend's SAVI username to pull their public link previews into Friends and Explore.")
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(spacing: 8) {
                        ForEach(store.friends) { friend in
                            FriendRow(friend: friend)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        Task { await store.syncSocialLinks() }
                    } label: {
                        Label(store.isSocialSyncing ? "Syncing..." : "Sync now", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(SaviSecondaryButtonStyle())
                    .disabled(store.isSocialSyncing)

                    if !store.likedFriendLinks.isEmpty {
                        Label("\(store.likedFriendLinks.count) liked", systemImage: "heart.fill")
                            .font(SaviType.ui(.caption, weight: .black))
                            .foregroundStyle(SaviTheme.accentText)
                    }
                }

                Button {
                    store.loadSampleFriend()
                } label: {
                    Label("Load sample friend", systemImage: "person.crop.circle.badge.plus")
                }
                .buttonStyle(SaviSecondaryButtonStyle())

                if let message = store.socialSyncMessage {
                    Text(message)
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                }

                if !store.friendLinks.isEmpty {
                    Divider().overlay(SaviTheme.cardStroke)
                    Text("New from friends")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                    ForEach(store.friendLinks.prefix(4)) { link in
                        FriendLinkRow(link: link)
                    }
                }
            }
        }
    }
}

struct FriendRow: View {
    @EnvironmentObject private var store: SaviStore
    let friend: SaviFriend

    private var linkCount: Int {
        store.friendLinks(for: friend).count
    }

    private var keeperCount: Int {
        store.friendKeeperSummaries(for: friend).count
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: friend.avatarColor))
                .frame(width: 30, height: 30)
                .overlay(
                    Text(friend.username.prefix(1).uppercased())
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.foreground(onHex: friend.avatarColor))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(friend.username)")
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text("\(keeperCount) public Keeper\(keeperCount == 1 ? "" : "s") · \(linkCount) link\(linkCount == 1 ? "" : "s")")
                    .font(SaviType.ui(.caption2, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
            }
            Spacer()
            Button {
                store.openFriendProfile(friend)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .frame(width: 30, height: 30)
                    .background(SaviTheme.surface)
                    .foregroundStyle(SaviTheme.textMuted)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open @\(friend.username) profile")
            Button {
                store.removeFriend(friend)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.black))
                    .frame(width: 30, height: 30)
                    .background(SaviTheme.surface)
                    .foregroundStyle(SaviTheme.textMuted)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove @\(friend.username)")
        }
        .padding(10)
        .background(SaviTheme.surface.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            store.openFriendProfile(friend)
        }
    }
}

struct FriendLinkRow: View {
    @EnvironmentObject private var store: SaviStore
    let link: SaviSharedLink

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AsyncImage(url: link.thumbnail.flatMap(URL.init(string:))) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: link.type.symbolName)
                        .font(.headline.weight(.black))
                        .foregroundStyle(SaviTheme.accentText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(SaviTheme.surfaceRaised)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(link.title)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(2)
                Text("@\(link.ownerUsername) · \(link.source) · \(link.keeperName)")
                    .font(SaviType.ui(.caption2, weight: .bold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Button {
                store.toggleLikeFriendLink(link)
            } label: {
                Image(systemName: store.isFriendLinkLiked(link) ? "heart.fill" : "heart")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(store.isFriendLinkLiked(link) ? SaviTheme.accentText : SaviTheme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(SaviTheme.surface.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            store.previewFriendLink(link)
        }
    }
}

struct FriendProfileSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    let friend: SaviFriend
    @State private var selectedKeeperId: String?

    private var links: [SaviSharedLink] {
        store.friendLinks(for: friend, keeperId: selectedKeeperId)
    }

    private var allLinks: [SaviSharedLink] {
        store.friendLinks(for: friend)
    }

    private var keepers: [SaviFriendKeeperSummary] {
        store.friendKeeperSummaries(for: friend)
    }

    private var likedCount: Int {
        allLinks.filter { store.isFriendLinkLiked($0) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    profileHeader
                    statsRow

                    if keepers.isEmpty {
                        EmptyStateView(
                            symbol: "person.2.slash",
                            title: "No public links yet",
                            message: "@\(friend.username) has not shared public Keeper links with you yet."
                        )
                    } else {
                        publicKeepersSection
                        publicLinksSection
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("@\(friend.username)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var profileHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(Color(hex: friend.avatarColor))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(friend.username.prefix(1).uppercased())
                        .font(SaviType.ui(.title2, weight: .black))
                        .foregroundStyle(SaviTheme.foreground(onHex: friend.avatarColor))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(friend.displayName.nilIfBlank ?? "@\(friend.username)")
                    .font(SaviType.display(size: 30, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("@\(friend.username)")
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.accentText)
                Text("Public links from Keepers they chose to share. Files, PDFs, images, and private notes stay out of this feed.")
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .saviCard(cornerRadius: 20)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            FriendProfileMetric(value: "\(allLinks.count)", label: "Links")
            FriendProfileMetric(value: "\(keepers.count)", label: "Keepers")
            FriendProfileMetric(value: "\(likedCount)", label: "Liked")
        }
    }

    private var publicKeepersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Public Keepers")
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Spacer()
                Button {
                    selectedKeeperId = nil
                } label: {
                    Text("All")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(selectedKeeperId == nil ? .black : SaviTheme.accentText)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(selectedKeeperId == nil ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(keepers) { keeper in
                    FriendKeeperCard(
                        keeper: keeper,
                        active: selectedKeeperId == keeper.id
                    ) {
                        selectedKeeperId = selectedKeeperId == keeper.id ? nil : keeper.id
                    }
                }
            }
        }
    }

    private var publicLinksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(selectedKeeperId.flatMap { id in keepers.first(where: { $0.id == id })?.name } ?? "Shared Links")
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Spacer()
                Text("\(links.count)")
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
            }

            LazyVStack(spacing: 10) {
                ForEach(links) { link in
                    FriendProfileLinkCard(link: link)
                }
            }
        }
    }
}

struct FriendProfileMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(SaviType.display(size: 25, weight: .black))
                .foregroundStyle(SaviTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
            Text(label)
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(SaviTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
    }
}

struct FriendKeeperCard: View {
    let keeper: SaviFriendKeeperSummary
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.headline.weight(.black))
                        .frame(width: 34, height: 34)
                        .background(active ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                        .foregroundStyle(active ? .black : SaviTheme.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    Spacer()
                    if active {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SaviTheme.accentText)
                    }
                }

                Text(keeper.name)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(keeper.count) link\(keeper.count == 1 ? "" : "s")")
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .padding(12)
            .background(active ? SaviTheme.surfaceRaised : SaviTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(active ? SaviTheme.chartreuse.opacity(0.75) : SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FriendProfileLinkCard: View {
    @EnvironmentObject private var store: SaviStore
    let link: SaviSharedLink

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: link.thumbnail.flatMap(URL.init(string:))) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: link.type.symbolName)
                        .font(.headline.weight(.black))
                        .foregroundStyle(SaviTheme.accentText)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(SaviTheme.surfaceRaised)
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Label(link.type.label, systemImage: link.type.symbolName)
                    Text(link.source)
                }
                .font(SaviType.ui(.caption2, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
                .lineLimit(1)

                Text(link.title)
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let description = link.itemDescription.nilIfBlank {
                    Text(description)
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Text(link.keeperName)
                    .font(SaviType.ui(.caption2, weight: .black))
                    .foregroundStyle(SaviTheme.accentText)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Button {
                store.toggleLikeFriendLink(link)
            } label: {
                Image(systemName: store.isFriendLinkLiked(link) ? "heart.fill" : "heart")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(store.isFriendLinkLiked(link) ? SaviTheme.accentText : SaviTheme.textMuted)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(SaviTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            store.previewFriendLink(link)
        }
    }
}

struct FolderBrainSettingsCard: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        SettingsCard(title: "SAVI Brain", symbol: "brain") {
            VStack(alignment: .leading, spacing: 14) {
                if let report = store.folderAuditReport {
                    FolderAuditSummary(report: report)

                    FolderBrainStatusRow(
                        title: "Apple Intelligence",
                        value: store.appleIntelligenceStatus,
                        symbolName: store.appleIntelligenceStatus == "Available" ? "sparkles" : "bolt.slash"
                    )

                    if report.failedCount == 0 {
                        Label("All golden Keeper examples pass.", systemImage: "checkmark.seal.fill")
                            .font(SaviType.ui(.subheadline, weight: .bold))
                            .foregroundStyle(SaviTheme.accentText)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Needs attention")
                                .font(SaviType.ui(.caption, weight: .black))
                                .foregroundStyle(Color.orange)
                            ForEach(Array(report.failures.prefix(4))) { result in
                                FolderAuditFailureRow(result: result)
                            }
                        }
                    }

                    if !report.uncoveredFolderIds.isEmpty {
                        Text("Uncovered Keepers need example saves: \(folderNames(for: report.uncoveredFolderIds).joined(separator: ", "))")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                    }
                } else {
                    Text("Run the Keeper audit to check SAVI’s local sorting rules against the golden examples.")
                        .font(.footnote)
                        .foregroundStyle(SaviTheme.textMuted)
                }

                Button {
                    store.runFolderAudit()
                } label: {
                    Label("Run Keeper audit", systemImage: "checklist")
                }
                .buttonStyle(SaviSecondaryButtonStyle())

                Divider()
                    .overlay(SaviTheme.cardStroke)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent auto decisions")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                    if store.folderDecisionHistory.isEmpty {
                        Text("New auto-saves will show the chosen Keeper, confidence, and reason here.")
                            .font(.footnote)
                            .foregroundStyle(SaviTheme.textMuted)
                    } else {
                        ForEach(store.folderDecisionHistory.prefix(5)) { decision in
                            FolderDecisionRow(decision: decision)
                        }
                        Button {
                            store.clearFolderDecisionHistory()
                        } label: {
                            Label("Clear decision history", systemImage: "xmark.circle")
                        }
                        .buttonStyle(SaviSecondaryButtonStyle())
                    }
                }

                Divider()
                    .overlay(SaviTheme.cardStroke)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Local learning")
                            .font(SaviType.ui(.caption, weight: .black))
                            .foregroundStyle(SaviTheme.textMuted)
                        Spacer()
                        Text("\(store.folderLearningCount) rule\(store.folderLearningCount == 1 ? "" : "s")")
                            .font(SaviType.ui(.caption, weight: .heavy))
                            .foregroundStyle(SaviTheme.accentText)
                    }
                    if store.recentFolderLearningSignals.isEmpty {
                        Text("When you move an auto-saved item to a better Keeper, SAVI stores safe local hints here.")
                            .font(.footnote)
                            .foregroundStyle(SaviTheme.textMuted)
                    } else {
                        ForEach(store.recentFolderLearningSignals) { signal in
                            FolderLearningRow(
                                signal: signal,
                                folderName: store.folder(for: signal.folderId)?.name ?? signal.folderId
                            )
                        }
                    }
                }
            }
        }
    }

    private func folderNames(for ids: [String]) -> [String] {
        ids.map { id in
            store.folder(for: id)?.name ??
                SAVIFolderClassifier.defaultFolderOptions.first(where: { $0.id == id })?.name ??
                id
        }
    }
}

struct FolderAuditSummary: View {
    let report: SAVIFolderAuditReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(report.passedCount)/\(report.results.count)")
                    .font(SaviType.display(size: 26, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text("golden examples")
                    .font(SaviType.ui(.subheadline, weight: .bold))
                    .foregroundStyle(SaviTheme.textMuted)
                Spacer()
                Text("\(Int((report.passRate * 100).rounded()))%")
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(report.failedCount == 0 ? SaviTheme.accentText : Color.orange)
            }

            HStack(spacing: 10) {
                FolderBrainMetric(
                    title: "Coverage",
                    value: "\(report.coveredFolderIds.count)/\(report.folderOptions.count)"
                )
                FolderBrainMetric(
                    title: "Failures",
                    value: "\(report.failedCount)"
                )
            }
        }
    }
}

struct FolderBrainMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(SaviType.ui(.caption2, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
            Text(value)
                .font(SaviType.ui(.headline, weight: .black))
                .foregroundStyle(SaviTheme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FolderBrainStatusRow: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.caption.weight(.black))
                .foregroundStyle(SaviTheme.accentText)
                .frame(width: 24, height: 24)
                .background(SaviTheme.surfaceRaised)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
                Text(value)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
            }
            Spacer(minLength: 8)
        }
        .accessibilityElement(children: .combine)
    }
}

struct FolderAuditFailureRow: View {
    let result: SAVIFolderAuditResult

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(result.testCase.name)
                .font(SaviType.ui(.subheadline, weight: .black))
                .foregroundStyle(SaviTheme.text)
            Text("Expected \(result.testCase.expectedFolderId), got \(result.classification.folderId) · \(result.classification.confidence) · \(result.classification.reason)")
                .font(.caption)
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FolderDecisionRow: View {
    let decision: SAVIFolderDecisionRecord

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "arrow.triangle.branch")
                .font(.caption.weight(.black))
                .foregroundStyle(SaviTheme.accentText)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                Text(decision.title)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(1)
                Text("\(decision.folderName) · \(decision.reason) · \(decision.context)")
                    .font(.caption)
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(decision.confidence)")
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .accessibilityLabel("Confidence \(decision.confidence)")
                Text(SaviText.relativeSavedTime(decision.createdAt))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(SaviTheme.textMuted)
            }
        }
    }
}

struct FolderLearningRow: View {
    let signal: SAVIFolderLearningSignal
    let folderName: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(signal.phrase)
                .font(SaviType.ui(.subheadline, weight: .black))
                .foregroundStyle(SaviTheme.text)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text("\(folderName) · \(signal.uses)x")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SaviTheme.textMuted)
                .lineLimit(1)
        }
    }
}

// MARK: - Sheets

struct SaveSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @State private var mode: SaviSaveMode = .link
    @State private var urlText = ""
    @State private var title = ""
    @State private var bodyText = ""
    @State private var tagsText = ""
    @State private var selectedFolderId = ""
    @State private var filePickerPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isImportingPhoto = false
    @State private var clipboardDraft: SaviClipboardDraft?
    @State private var didCheckClipboard = false
    @State private var isCheckingClipboard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isCheckingClipboard {
                        ClipboardDraftCard(draft: nil, isLoading: true, clearAction: {})
                    } else if let clipboardDraft {
                        ClipboardDraftCard(draft: clipboardDraft, isLoading: false) {
                            clearClipboardDraft()
                        }
                    }

                    SavePreviewCard(
                        mode: mode,
                        title: previewTitle,
                        subtitle: previewSubtitle,
                        detail: previewDetail
                    )

                    Picker("Mode", selection: $mode) {
                        Label(SaviSaveMode.link.title, systemImage: SaviSaveMode.link.symbolName).tag(SaviSaveMode.link)
                        Label(SaviSaveMode.text.title, systemImage: SaviSaveMode.text.symbolName).tag(SaviSaveMode.text)
                        Label(SaviSaveMode.file.title, systemImage: SaviSaveMode.file.symbolName).tag(SaviSaveMode.file)
                    }
                    .pickerStyle(.segmented)
                    .tint(SaviTheme.chartreuse)

                    VStack(alignment: .leading, spacing: 12) {
                        switch mode {
                        case .link:
                            SaviTextField(title: "URL", text: $urlText, prompt: "https://...")
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                            SaviTextField(title: "Title", text: $title, prompt: "Optional")
                            Text("Save the link immediately. SAVI can finish the preview, Keeper, and tags afterward.")
                                .font(.footnote)
                                .foregroundStyle(SaviTheme.textMuted)
                        case .text:
                            Text("Note")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SaviTheme.textMuted)
                            TextEditor(text: $bodyText)
                                .frame(minHeight: 170)
                                .padding(10)
                                .scrollContentBackground(.hidden)
                                .saviCard(cornerRadius: 16, shadow: false)
                        case .file:
                            HStack(spacing: 10) {
                                Button {
                                    filePickerPresented = true
                                } label: {
                                    Label(clipboardDraft?.mode == .file ? "Different file" : "Files", systemImage: "doc.badge.plus")
                                }
                                .buttonStyle(SaviSecondaryButtonStyle())

                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    Label(isImportingPhoto ? "Importing" : "Photos", systemImage: "photo.fill")
                                }
                                .buttonStyle(SaviSecondaryButtonStyle())
                                .disabled(isImportingPhoto)
                            }
                            Text(fileHelpText)
                                .font(.footnote)
                                .foregroundStyle(SaviTheme.textMuted)
                        }
                    }

                    FolderPicker(selectedFolderId: $selectedFolderId)

                    SaviTextField(title: "Optional tags", text: $tagsText, prompt: "recipe, pdf, travel")
                        .textInputAutocapitalization(.never)
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("New Save")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadClipboardDraftIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveActionTitle) {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
            .fileImporter(
                isPresented: $filePickerPresented,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result,
                   let url = urls.first {
                    Task {
                        await store.addFile(from: url, folderId: selectedFolderId, tags: tags)
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { item in
                Task {
                    await importPhoto(item)
                }
            }
            .onChange(of: mode) { newMode in
                cleanClipboardTagsIfNeeded(for: newMode)
            }
        }
    }

    private var activeClipboardDraft: SaviClipboardDraft? {
        guard let clipboardDraft, clipboardDraft.mode == mode else { return nil }
        return clipboardDraft
    }

    private var previewTitle: String {
        if let draft = activeClipboardDraft {
            return draft.title
        }
        switch mode {
        case .link:
            if let title = title.nilIfBlank { return title }
            if let url = urlText.nilIfBlank { return SaviText.sourceLabel(for: url, fallback: "New link") }
            return "New link"
        case .text:
            if let text = bodyText.nilIfBlank { return SaviText.titleFromPlainText(text) }
            return "New note"
        case .file:
            return "New upload"
        }
    }

    private var previewSubtitle: String {
        if let draft = activeClipboardDraft {
            return draft.subtitle
        }
        switch mode {
        case .link:
            return urlText.nilIfBlank ?? "Paste a link from anywhere."
        case .text:
            return bodyText.nilIfBlank ?? "Save a thought, prompt, recipe, address, or anything else you want searchable."
        case .file:
            return "Import a photo, PDF, document, screenshot, or clipboard file."
        }
    }

    private var previewDetail: String {
        switch mode {
        case .link:
            return "Link"
        case .text:
            return "Note"
        case .file:
            return activeClipboardDraft == nil ? "File or photo" : "Clipboard file"
        }
    }

    private var fileHelpText: String {
        if activeClipboardDraft != nil {
            return "A clipboard file is ready. Save imports it now, or choose a different file."
        }
        return "Files and photos are copied into SAVI's private asset storage."
    }

    private var saveActionTitle: String {
        if mode == .file, activeClipboardDraft == nil {
            return "Choose"
        }
        return "Save"
    }

    private var tags: [String] {
        SaviText.dedupeTags(tagsText.split(separator: ",").map(String.init))
    }

    private var canSave: Bool {
        switch mode {
        case .link: return urlText.nilIfBlank != nil
        case .text: return bodyText.nilIfBlank != nil
        case .file: return true
        }
    }

    private func loadClipboardDraftIfNeeded() async {
        guard !didCheckClipboard,
              urlText.isEmpty,
              title.isEmpty,
              bodyText.isEmpty,
              tagsText.isEmpty
        else { return }

        didCheckClipboard = true
        isCheckingClipboard = true
        let draft = await SaviClipboardReader.readDraft()
        isCheckingClipboard = false

        if let draft {
            applyClipboardDraft(draft)
        }
    }

    private func applyClipboardDraft(_ draft: SaviClipboardDraft) {
        clipboardDraft = draft
        mode = draft.mode

        switch draft.mode {
        case .link:
            urlText = draft.url ?? ""
            title = ""
            bodyText = ""
        case .text:
            bodyText = draft.text ?? ""
            urlText = ""
            title = ""
        case .file:
            urlText = ""
            title = ""
            bodyText = ""
        }

        if tagsText.nilIfBlank == nil {
            tagsText = draft.tags.joined(separator: ", ")
        }
    }

    private func clearClipboardDraft() {
        clipboardDraft = nil
        urlText = ""
        title = ""
        bodyText = ""
        tagsText = ""
        mode = .link
    }

    private func cleanClipboardTagsIfNeeded(for newMode: SaviSaveMode) {
        guard let clipboardDraft,
              clipboardDraft.mode != newMode,
              tagsText == clipboardDraft.tags.joined(separator: ", ")
        else { return }
        tagsText = ""
    }

    private func importPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isImportingPhoto = true
        defer { isImportingPhoto = false }

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            store.toast = "Could not import that photo."
            return
        }

        let type = item.supportedContentTypes.first(where: { $0.conforms(to: .image) }) ?? .jpeg
        let mimeType = type.preferredMIMEType ?? "image/jpeg"
        let fileExtension = type.preferredFilenameExtension ?? SaviText.fileExtension(forMimeType: mimeType)
        store.addClipboardFile(
            data: data,
            name: "photo-\(SaviText.backupStamp()).\(fileExtension)",
            mimeType: mimeType,
            folderId: selectedFolderId,
            tags: tags
        )
        dismiss()
    }

    private func save() {
        switch mode {
        case .link:
            store.addLink(
                urlString: urlText,
                title: title,
                description: "",
                folderId: selectedFolderId,
                tags: tags
            )
            dismiss()
        case .text:
            store.addText(bodyText, folderId: selectedFolderId, tags: tags)
            dismiss()
        case .file:
            if let draft = clipboardDraft,
               let data = draft.data,
               let fileName = draft.fileName,
               let mimeType = draft.mimeType {
                store.addClipboardFile(
                    data: data,
                    name: fileName,
                    mimeType: mimeType,
                    folderId: selectedFolderId,
                    tags: tags
                )
                dismiss()
            } else {
                filePickerPresented = true
            }
        }
    }
}

enum SaviSaveMode: String, Hashable {
    case link
    case text
    case file

    var title: String {
        switch self {
        case .link: return "Link"
        case .text: return "Note"
        case .file: return "Upload"
        }
    }

    var symbolName: String {
        switch self {
        case .link: return "link"
        case .text: return "text.alignleft"
        case .file: return "square.and.arrow.down.fill"
        }
    }
}

private struct SavePreviewCard: View {
    let mode: SaviSaveMode
    let title: String
    let subtitle: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SaviTheme.chartreuse)
                Image(systemName: mode.symbolName)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.black)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(detail)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SaviTheme.accentText)
                    Text("Instant save")
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SaviTheme.surfaceRaised)
                        .foregroundStyle(SaviTheme.textMuted)
                        .clipShape(Capsule())
                }

                Text(title)
                    .font(SaviType.ui(.title3, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .saviCard(cornerRadius: 20)
    }
}

private struct ClipboardDraftCard: View {
    let draft: SaviClipboardDraft?
    let isLoading: Bool
    let clearAction: () -> Void

    private var symbolName: String {
        switch draft?.mode {
        case .link: return "link"
        case .text: return "text.alignleft"
        case .file: return "doc.on.clipboard.fill"
        case nil: return "doc.on.clipboard"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SaviTheme.chartreuse)
                if isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: symbolName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                }
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(isLoading ? "Checking clipboard" : "Loaded from clipboard")
                    .font(.headline)
                    .foregroundStyle(SaviTheme.text)
                Text(draft?.subtitle ?? "Looking for a link, text, image, or file.")
                    .font(.caption)
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if !isLoading {
                Button {
                    clearAction()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear clipboard draft")
            }
        }
        .padding(14)
        .saviCard(cornerRadius: 18)
    }
}

struct ItemDetailSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @State private var webPreview: WebPreviewURL?
    let item: SaviItem

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ItemPreview(item: item)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(item.title)
                            .font(SaviItemTypography.detailTitle)
                            .foregroundStyle(SaviTheme.text)
                        HStack {
                            Label(item.type.label, systemImage: item.type.symbolName)
                            if let folder = store.folder(for: item.folderId) {
                                Label(folder.name, systemImage: folder.symbolName)
                            }
                            SavedAgoLabel(savedAt: item.savedAt, prefix: "Saved")
                        }
                        .font(SaviItemTypography.meta)
                        .foregroundStyle(SaviTheme.textMuted)
                    }

                    if let bodyText = SaviItemDisplay.detailBody(for: item) {
                        ItemDetailBodyCard(
                            title: SaviItemDisplay.detailBodyTitle(for: item),
                            text: bodyText,
                            isNoteLike: SaviItemDisplay.isNoteLike(item)
                        )
                    }

                    TagFlow(tags: item.tags)

                    VStack(spacing: 10) {
                        if let urlString = item.url,
                           let url = URL(string: urlString) {
                            Button {
                                webPreview = WebPreviewURL(url: url)
                            } label: {
                                Label("Preview in SAVI", systemImage: "eye.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SaviPrimaryButtonStyle())

                            Link(destination: url) {
                                Label("Open in Safari", systemImage: "safari.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SaviSecondaryButtonStyle())

                            ShareLink(item: url) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SaviSecondaryButtonStyle())
                        } else if let previewURL = store.quickLookURL(for: item) {
                            Button {
                                store.quickLookAssetURL = previewURL
                            } label: {
                                Label("Preview file", systemImage: "eye.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SaviPrimaryButtonStyle())
                        }

                        Button {
                            store.editingItem = item
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SaviSecondaryButtonStyle())

                        Button(role: .destructive) {
                            store.deleteItem(item)
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SaviDangerButtonStyle())
                    }
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Saved Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $webPreview) { preview in
                SafariLinkPreview(url: preview.url)
                    .ignoresSafeArea()
            }
        }
    }
}

struct ItemDetailBodyCard: View {
    let title: String
    let text: String
    let isNoteLike: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: isNoteLike ? "text.alignleft" : "quote.bubble.fill")
                .font(SaviItemTypography.detailBodyTitle)
                .foregroundStyle(isNoteLike ? SaviTheme.accentText : SaviTheme.textMuted)
                .textCase(.uppercase)

            Text(text)
                .font(SaviItemTypography.detailBody)
                .foregroundStyle(SaviTheme.text)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(SaviTheme.surface.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
    }
}

struct ItemEditorSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @State private var item: SaviItem
    @State private var tagsText: String

    init(item: SaviItem) {
        _item = State(initialValue: item)
        _tagsText = State(initialValue: item.tags.joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SaviTextField(title: "Title", text: $item.title, prompt: "Title")
                    Text("Description")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                    TextEditor(text: $item.itemDescription)
                        .frame(minHeight: 140)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .saviCard(cornerRadius: 16, shadow: false)
                    FolderPicker(selectedFolderId: $item.folderId)
                    SaviTextField(title: "Tags", text: $tagsText, prompt: "tag, tag")
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        item.tags = SaviText.dedupeTags(tagsText.split(separator: ",").map(String.init))
                        store.saveEditedItem(item)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FolderEditorSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    let folder: SaviFolder?
    @State private var name: String
    @State private var color: String
    @State private var symbolName: String
    @State private var folderImage: String?
    @State private var locked: Bool
    @State private var isPublic: Bool
    @State private var selectedIconPhoto: PhotosPickerItem?
    @State private var iconLoadMessage: String?

    private let colors = ["#D8FF3C", "#C4B5FD", "#A78BFA", "#B8D4F5", "#F4C6A5", "#C4E8D4", "#FFE066", "#8A7CA8", "#FF7A90", "#67E8F9", "#F0ABFC", "#86EFAC"]
    private let symbols = [
        "folder.fill", "archivebox.fill", "tray.full.fill", "shippingbox.fill", "bookmark.fill", "tag.fill",
        "star.fill", "heart.fill", "bolt.fill", "sparkles", "wand.and.stars", "lock.fill",
        "newspaper.fill", "play.rectangle.fill", "film.fill", "photo.fill", "camera.fill", "doc.text.fill",
        "doc.richtext.fill", "book.closed.fill", "quote.bubble.fill", "mappin.and.ellipse", "map.fill", "house.fill",
        "cart.fill", "gift.fill", "fork.knife", "airplane", "gamecontroller.fill", "music.note",
        "paintpalette.fill", "hammer.fill", "laptopcomputer", "graduationcap.fill", "briefcase.fill", "creditcard.fill",
        "calendar", "clock.fill", "person.2.fill", "atom", "leaf.fill", "shuffle"
    ]

    init(folder: SaviFolder?) {
        self.folder = folder
        _name = State(initialValue: folder?.name ?? "")
        _color = State(initialValue: folder?.color ?? "#C4B5FD")
        _symbolName = State(initialValue: folder?.symbolName ?? "folder.fill")
        _folderImage = State(initialValue: folder?.image)
        _locked = State(initialValue: folder?.locked ?? false)
        _isPublic = State(initialValue: folder?.isPublic ?? false)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SaviTextField(title: "Name", text: $name, prompt: "Keeper name")

                    Text("Color")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(colors, id: \.self) { swatch in
                            Button {
                                color = swatch
                            } label: {
                                Circle()
                                    .fill(Color(hex: swatch))
                                    .frame(height: 44)
                                    .overlay {
                                        if color == swatch {
                                            Image(systemName: "checkmark")
                                                .font(.headline.bold())
                                                .foregroundStyle(SaviTheme.foreground(onHex: swatch))
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Icon")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                    HStack(alignment: .center, spacing: 12) {
                        FolderIconBadge(
                            symbolName: symbolName,
                            color: color,
                            imageDataURL: folderImage,
                            size: 58,
                            cornerRadius: 17,
                            font: SaviType.ui(.title2, weight: .black)
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            PhotosPicker(selection: $selectedIconPhoto, matching: .images) {
                                Label(folderImage == nil ? "Choose image" : "Change image", systemImage: "photo.fill")
                                    .font(SaviType.ui(.subheadline, weight: .black))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .padding(.horizontal, 12)
                                    .background(SaviTheme.surfaceRaised)
                                    .foregroundStyle(SaviTheme.text)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            if folderImage != nil {
                                Button {
                                    folderImage = nil
                                    iconLoadMessage = nil
                                } label: {
                                    Label("Use symbol", systemImage: "square.grid.2x2.fill")
                                        .font(SaviType.ui(.caption, weight: .bold))
                                        .foregroundStyle(SaviTheme.accentText)
                                }
                                .buttonStyle(.plain)
                            }

                            if let iconLoadMessage {
                                Text(iconLoadMessage)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(SaviTheme.textMuted)
                            }
                        }
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                        ForEach(symbols, id: \.self) { symbol in
                            Button {
                                symbolName = symbol
                                folderImage = nil
                                iconLoadMessage = nil
                            } label: {
                                Image(systemName: symbol)
                                    .font(.subheadline.weight(.black))
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(folderImage == nil && symbolName == symbol ? SaviTheme.chartreuse : SaviTheme.surface)
                                    .foregroundStyle(folderImage == nil && symbolName == symbol ? .black : SaviTheme.text)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(SaviTheme.cardStroke, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Toggle(isOn: $locked) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: locked ? "lock.fill" : "lock.open.fill")
                                .font(SaviType.ui(.headline, weight: .black))
                                .frame(width: 40, height: 40)
                                .background(locked ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                                .foregroundStyle(locked ? .black : SaviTheme.accentText)
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Require Face ID")
                                    .font(SaviType.ui(.headline, weight: .black))
                                    .foregroundStyle(SaviTheme.text)
                                Text("Locked Keepers hide their saves until Face ID or passcode unlocks them.")
                                    .font(SaviType.ui(.caption, weight: .semibold))
                                    .foregroundStyle(SaviTheme.textMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(SaviTheme.chartreuse)
                    .padding(14)
                    .saviCard(cornerRadius: 18, shadow: false)

                    Toggle(isOn: Binding(
                        get: { isPublic && !locked },
                        set: { isPublic = $0 && !locked }
                    )) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .font(SaviType.ui(.headline, weight: .black))
                                .frame(width: 40, height: 40)
                                .background(isPublic && !locked ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                                .foregroundStyle(isPublic && !locked ? .black : SaviTheme.accentText)
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Share links with friends")
                                    .font(SaviType.ui(.headline, weight: .black))
                                    .foregroundStyle(SaviTheme.text)
                                Text("Only URL previews from this Keeper can publish. Files, PDFs, images, notes, and locked Keepers stay private.")
                                    .font(SaviType.ui(.caption, weight: .semibold))
                                    .foregroundStyle(SaviTheme.textMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .disabled(locked || folder?.id == "f-private-vault")
                    .toggleStyle(.switch)
                    .tint(SaviTheme.chartreuse)
                    .padding(14)
                    .saviCard(cornerRadius: 18, shadow: false)
                    .onChange(of: locked) { value in
                        if value { isPublic = false }
                    }

                    if let folder, !folder.system {
                        Button(role: .destructive) {
                            store.deleteFolder(folder)
                            dismiss()
                        } label: {
                            Label("Delete Keeper", systemImage: "trash.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SaviDangerButtonStyle())
                        .padding(.top, 10)
                    }
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle(folder == nil ? "New Keeper" : "Edit Keeper")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedIconPhoto) { item in
                loadCustomIcon(item)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if var folder {
                            folder.name = name
                            folder.color = color
                            folder.symbolName = symbolName
                            folder.image = folderImage
                            folder.locked = locked
                            folder.isPublic = locked ? false : isPublic
                            store.saveFolder(folder)
                        } else {
                            store.addFolder(name: name, color: color, symbolName: symbolName, image: folderImage, locked: locked, isPublic: isPublic)
                        }
                        dismiss()
                    }
                    .disabled(name.nilIfBlank == nil)
                }
            }
        }
    }

    private func loadCustomIcon(_ item: PhotosPickerItem?) {
        guard let item else { return }
        iconLoadMessage = "Preparing icon..."
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let dataURL = Self.folderIconDataURL(from: data) {
                    await MainActor.run {
                        folderImage = dataURL
                        iconLoadMessage = nil
                    }
                } else {
                    await MainActor.run {
                        iconLoadMessage = "That image could not be used."
                    }
                }
            } catch {
                await MainActor.run {
                    iconLoadMessage = "That image could not be used."
                }
            }
        }
    }

    private static func folderIconDataURL(from data: Data) -> String? {
        guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else { return nil }
        let target = CGSize(width: 256, height: 256)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let rendered = renderer.image { _ in
            let scale = max(target.width / image.size.width, target.height / image.size.height)
            let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(
                x: (target.width - drawSize.width) / 2,
                y: (target.height - drawSize.height) / 2
            )
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
        guard let jpeg = rendered.jpegData(compressionQuality: 0.84) else { return nil }
        return "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
    }
}

// MARK: - Components

struct FolderIconBadge: View {
    let symbolName: String
    let color: String
    let imageDataURL: String?
    var size: CGFloat = 42
    var cornerRadius: CGFloat = 14
    var font: Font = SaviType.ui(.title3, weight: .bold)

    private var customImage: UIImage? {
        guard let imageDataURL = imageDataURL?.nilIfBlank else { return nil }
        return SaviText.imageFromDataURL(imageDataURL)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(hex: color))

            if let customImage {
                Image(uiImage: customImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
            } else {
                Image(systemName: symbolName)
                    .font(font)
                    .foregroundStyle(SaviTheme.foreground(onHex: color))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct FolderIconView: View {
    let folder: SaviFolder
    var size: CGFloat = 42
    var cornerRadius: CGFloat = 14
    var font: Font = SaviType.ui(.title3, weight: .bold)

    var body: some View {
        FolderIconBadge(
            symbolName: folder.symbolName,
            color: folder.color,
            imageDataURL: folder.image,
            size: size,
            cornerRadius: cornerRadius,
            font: font
        )
    }
}

struct HeaderBlock: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var titleSize: CGFloat = 42

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(SaviType.ui(.caption, weight: .heavy))
                .foregroundStyle(SaviTheme.accentText)
            Text(title)
                .font(SaviType.display(size: titleSize, weight: .black))
                .foregroundStyle(SaviTheme.text)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
            Text(subtitle)
                .font(SaviType.ui(.callout, weight: .regular))
                .foregroundStyle(SaviTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(SaviType.ui(.title3, weight: .black))
                .foregroundStyle(SaviTheme.text)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(SaviType.ui(.subheadline, weight: .bold))
                    .foregroundStyle(SaviTheme.accentText)
            }
        }
    }
}

struct FolderLibraryView: View {
    @EnvironmentObject private var store: SaviStore
    @State private var isReordering = false
    @State private var draggedFolderId: String?
    let viewMode: SaviFolderViewMode

    private var sortedFolders: [SaviFolder] {
        store.orderedFoldersForDisplay()
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(sortedFolders.count) keepers")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.accentText)
                    Text("Tap to browse. Drag to reorder.")
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                FolderViewModePicker(selectedMode: viewMode)

                Button {
                    toggleReordering()
                } label: {
                    Image(systemName: isReordering ? "checkmark" : "arrow.up.arrow.down")
                        .font(.subheadline.weight(.black))
                        .frame(width: 34, height: 34)
                        .background(isReordering ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                        .foregroundStyle(isReordering ? .black : SaviTheme.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(SaviTheme.cardStroke, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isReordering ? "Done rearranging Keepers" : "Rearrange Keepers")

                Button {
                    store.presentedSheet = .folderEditor(nil)
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.subheadline.weight(.black))
                        .frame(width: 34, height: 34)
                        .background(SaviTheme.chartreuse)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("New Keeper")
            }

            if isReordering {
                HStack(spacing: 8) {
                    Image(systemName: "hand.point.up.left.fill")
                    Text("Drag Keepers into the order you want.")
                    Spacer()
                }
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.accentText)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .saviCard(cornerRadius: 14, shadow: false)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if viewMode == .grid {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(sortedFolders) { folder in
                        FolderGridTile(
                            folder: folder,
                            isReordering: isReordering,
                            isDragged: draggedFolderId == folder.id
                        )
                        .onDrag {
                            dragProvider(for: folder)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: FolderReorderDropDelegate(
                                targetFolder: folder,
                                store: store,
                                draggedFolderId: $draggedFolderId,
                                isReordering: $isReordering
                            )
                        )
                    }
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sortedFolders) { folder in
                        FolderCard(
                            folder: folder,
                            isReordering: isReordering,
                            isDragged: draggedFolderId == folder.id
                        )
                        .onDrag {
                            dragProvider(for: folder)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: FolderReorderDropDelegate(
                                targetFolder: folder,
                                store: store,
                                draggedFolderId: $draggedFolderId,
                                isReordering: $isReordering
                            )
                        )
                    }
                }
            }
        }
    }

    private func toggleReordering() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            if isReordering {
                store.finishFolderReordering()
                draggedFolderId = nil
                isReordering = false
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isReordering = true
            }
        }
    }

    private func dragProvider(for folder: SaviFolder) -> NSItemProvider {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            isReordering = true
            draggedFolderId = folder.id
        }
        return NSItemProvider(object: folder.id as NSString)
    }
}

private struct FolderReorderDropDelegate: DropDelegate {
    let targetFolder: SaviFolder
    let store: SaviStore
    @Binding var draggedFolderId: String?
    @Binding var isReordering: Bool

    func dropEntered(info: DropInfo) {
        guard let draggedFolderId, draggedFolderId != targetFolder.id else { return }
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                store.reorderFolder(draggedId: draggedFolderId, over: targetFolder.id)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.86)) {
                store.finishFolderReordering()
                draggedFolderId = nil
                isReordering = false
            }
        }
        return true
    }
}

struct FolderViewModePicker: View {
    @EnvironmentObject private var store: SaviStore
    let selectedMode: SaviFolderViewMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(SaviFolderViewMode.allCases) { mode in
                Button {
                    store.setFolderViewMode(mode)
                } label: {
                    Image(systemName: mode.symbolName)
                        .font(.caption.weight(.black))
                        .frame(width: 28, height: 28)
                        .background(selectedMode == mode ? SaviTheme.chartreuse : Color.clear)
                        .foregroundStyle(selectedMode == mode ? .black : SaviTheme.textMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(mode.title) view")
            }
        }
        .padding(3)
        .saviCard(cornerRadius: 12, shadow: false)
    }
}

struct FolderGridTile: View {
    @EnvironmentObject private var store: SaviStore
    let folder: SaviFolder
    var isReordering = false
    var isDragged = false

    private var isLocked: Bool {
        folder.locked && !store.isProtectedKeeperUnlocked(folder)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                if !isReordering {
                    store.openFolder(folder)
                }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 6) {
                        FolderIconView(
                            folder: folder,
                            size: 31,
                            cornerRadius: 10,
                            font: SaviType.ui(.caption, weight: .black)
                        )
                        Spacer()
                    }

                    Spacer(minLength: 2)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(folder.name)
                            .font(SaviType.ui(.subheadline, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                            .multilineTextAlignment(.leading)
                        Text(isLocked ? "Locked" : "\(store.count(in: folder)) saves")
                            .font(SaviType.ui(.caption2, weight: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color(hex: folder.color).opacity(isLocked ? 0.16 : 0.22))
                            .foregroundStyle(isLocked ? SaviTheme.textMuted : SaviTheme.accentText)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                .padding(10)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: folder.color).opacity(folder.id == "f-all" ? 0.34 : 0.18),
                            SaviTheme.surface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(SaviTheme.cardStroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: SaviTheme.cardShadow.opacity(0.045), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            if isReordering {
                Image(systemName: "line.3.horizontal")
                    .font(.caption.weight(.black))
                    .frame(width: 26, height: 26)
                    .background(SaviTheme.chartreuse)
                    .foregroundStyle(.black)
                    .clipShape(Circle())
                    .padding(6)
                    .accessibilityHidden(true)
            } else if !folder.system {
                Button {
                    store.presentedSheet = .folderEditor(folder)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption.weight(.black))
                        .frame(width: 26, height: 26)
                        .background(SaviTheme.surfaceRaised.opacity(0.78))
                        .foregroundStyle(SaviTheme.text)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
                .accessibilityLabel("Edit \(folder.name)")
            }
        }
        .scaleEffect(isDragged ? 1.04 : 1)
        .opacity(isDragged ? 0.68 : 1)
        .rotationEffect(.degrees(isReordering && !isDragged ? (folder.order.isMultiple(of: 2) ? -0.7 : 0.7) : 0))
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isDragged)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isReordering)
    }
}

struct ExploreLibraryView: View {
    @EnvironmentObject private var store: SaviStore
    @Binding var seed: Int

    private var items: [SaviItem] {
        store.exploreItems(seed: seed, scope: store.exploreScope)
    }

    private var emptyTitle: String {
        switch store.exploreScope {
        case .all, .mine: return "No browseable saves yet"
        case .friends: return "No friend links yet"
        }
    }

    private var emptyMessage: String {
        switch store.exploreScope {
        case .all:
            return "Links, videos, images, and places will show up here when they are not private or paste-bin material."
        case .mine:
            return "Your public-feeling links, videos, images, and places will show here. Private, paste, and document saves stay out."
        case .friends:
            return "Friend links appear here when they come from public Keepers."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's mix")
                        .font(.title3.bold())
                        .foregroundStyle(SaviTheme.text)
                    Text(store.exploreStatusText(seed: seed, scope: store.exploreScope))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                }
                Spacer()
                if store.exploreSeenCount > 0 {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                            store.resetExploreHistory()
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.headline.weight(.bold))
                            .frame(width: 42, height: 42)
                            .background(SaviTheme.surfaceRaised)
                            .foregroundStyle(SaviTheme.accentText)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset Explore history")
                }
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                        store.shuffleExplore()
                    }
                } label: {
                    Image(systemName: "shuffle")
                        .font(.headline.weight(.bold))
                        .frame(width: 42, height: 42)
                        .background(SaviTheme.chartreuse)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Shuffle Explore")
            }

            ExploreScopeControl()

            if let hero = items.first {
                ExploreHeroCard(item: hero)

                ExploreMosaicBoard(items: Array(items.dropFirst()))
            } else {
                EmptyStateView(
                    symbol: "sparkles",
                    title: emptyTitle,
                    message: emptyMessage
                )
            }
        }
    }
}

struct ExploreScopeControl: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ExploreScope.allCases) { scope in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        store.setExploreScope(scope)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: scope.symbolName)
                            .font(.caption.weight(.black))
                        Text(scope.title)
                            .font(SaviType.ui(.caption, weight: .black))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .padding(.horizontal, 8)
                    .background(scope == store.exploreScope ? SaviTheme.chartreuse : SaviTheme.surface)
                    .foregroundStyle(scope == store.exploreScope ? Color.black : SaviTheme.text)
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(scope == store.exploreScope ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show \(scope.title) in Explore")
            }
        }
    }
}

struct ExploreMosaicBoard: View {
    let items: [SaviItem]

    private var groups: [[SaviItem]] {
        var result: [[SaviItem]] = []
        var index = 0
        while index < items.count {
            let end = min(index + 6, items.count)
            result.append(Array(items[index..<end]))
            index += 6
        }
        return result
    }

    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                ExploreMosaicGroup(index: index, items: group)
            }
        }
    }
}

struct ExploreMosaicGroup: View {
    let index: Int
    let items: [SaviItem]

    var body: some View {
        VStack(spacing: 12) {
            if items.count >= 3 {
                cluster
            } else if items.count == 2 {
                HStack(spacing: 12) {
                    ExploreTileCard(item: items[0], variant: .square)
                    ExploreTileCard(item: items[1], variant: .square)
                }
            } else if let item = items.first {
                ExploreStoryCard(item: item)
            }

            if items.indices.contains(3) {
                ExploreStoryCard(item: items[3])
            }

            if items.indices.contains(4) {
                HStack(spacing: 12) {
                    ExploreTileCard(item: items[4], variant: .square)
                    if items.indices.contains(5) {
                        ExploreTileCard(item: items[5], variant: .square)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var cluster: some View {
        if index.isMultiple(of: 2) {
            HStack(alignment: .top, spacing: 12) {
                ExploreTileCard(item: items[0], variant: .poster)
                    .frame(maxWidth: .infinity)
                VStack(spacing: 12) {
                    ExploreTileCard(item: items[1], variant: .mini)
                    ExploreTileCard(item: items[2], variant: .mini)
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 12) {
                    ExploreTileCard(item: items[1], variant: .mini)
                    ExploreTileCard(item: items[2], variant: .mini)
                }
                .frame(maxWidth: .infinity)
                ExploreTileCard(item: items[0], variant: .poster)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

enum ExploreTileVariant {
    case poster
    case mini
    case square

    var height: CGFloat {
        switch self {
        case .poster: return 252
        case .mini: return 120
        case .square: return 156
        }
    }

    var titleLimit: Int {
        switch self {
        case .poster: return 4
        case .mini, .square: return 3
        }
    }
}

struct ExploreTileCard: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem
    let variant: ExploreTileVariant

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ItemThumb(item: item, large: variant == .poster, enablesPressPreview: false)
                .frame(maxWidth: .infinity)
                .frame(height: variant.height)

            LinearGradient(
                colors: [Color.black.opacity(0.1), Color.black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 7) {
                ExploreTileMeta(item: item)
                Text(item.title)
                    .font(variant == .poster ? SaviType.ui(.headline, weight: .black) : SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(variant.titleLimit)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)
                if variant == .poster {
                    ExploreTagLine(item: item)
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: variant.height)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SaviTheme.cardStroke.opacity(0.75), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.42)
                .onEnded { _ in
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    store.previewItemContent(item)
                }
        )
        .onTapGesture {
            store.openExploreItem(item)
        }
    }
}

struct ExploreStoryCard: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    private var snippet: String? {
        item.itemDescription.nilIfBlank ?? item.url?.nilIfBlank
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                store.openExploreItem(item)
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 9) {
                        ExploreMetaLine(item: item)
                        Text(item.title)
                            .font(SaviType.ui(.headline, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        if let snippet {
                            Text(snippet)
                                .font(SaviType.ui(.callout, weight: .regular))
                                .foregroundStyle(SaviTheme.textMuted)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        ExploreTagLine(item: item)
                    }

                    Spacer(minLength: 8)

                    ItemThumb(item: item, enablesPressPreview: false)
                        .frame(width: 74, height: 74)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ExplorePreviewAction(item: item)
        }
        .padding(14)
        .saviCard(cornerRadius: 18)
    }
}

struct ExploreTileMeta: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: item.type.symbolName)
            Text(item.type.label)
            if let username = store.friendUsername(forExploreItem: item) {
                Text(username)
                    .font(.system(.caption2, design: .monospaced).weight(.black))
                    .foregroundStyle(SaviTheme.chartreuse)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.26))
                    .clipShape(Capsule())
            }
            if store.isExploreSeen(item) {
                Text("Seen")
            }
        }
        .font(SaviType.ui(.caption2, weight: .black))
        .foregroundStyle(.white.opacity(0.86))
        .lineLimit(1)
    }
}

struct ExploreHeroCard: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ItemThumb(item: item, large: true, enablesPressPreview: false)
                .frame(maxWidth: .infinity)
                .frame(height: 238)

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                ExploreMetaLine(item: item)
                Text(item.title)
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                if let snippet = item.itemDescription.nilIfBlank {
                    Text(snippet)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(2)
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(Rectangle())
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.42)
                .onEnded { _ in
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    store.previewItemContent(item)
                }
        )
        .onTapGesture {
            store.openExploreItem(item)
        }
    }
}

struct ExploreSnippetCard: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    private var snippet: String {
        item.itemDescription.nilIfBlank ?? item.url?.nilIfBlank ?? item.title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                store.openExploreItem(item)
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    ExploreMetaLine(item: item)
                    Text(item.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(snippet)
                        .font(.body)
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                    ExploreTagLine(item: item)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ExplorePreviewAction(item: item)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .saviCard(cornerRadius: 18)
    }
}

struct ExploreImageBandCard: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 13) {
                ItemThumb(item: item)
                    .frame(width: 104, height: 116)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onTapGesture {
                        store.openExploreItem(item)
                    }

                Button {
                    store.openExploreItem(item)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        ExploreMetaLine(item: item)
                        Text(item.title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(SaviTheme.text)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        if let snippet = item.itemDescription.nilIfBlank {
                            Text(snippet)
                                .font(.caption)
                                .foregroundStyle(SaviTheme.textMuted)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ExplorePreviewAction(item: item)
        }
        .padding(12)
        .saviCard(cornerRadius: 18)
    }
}

struct ExplorePreviewAction: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    private var url: URL? {
        guard let urlString = item.url?.nilIfBlank else { return nil }
        return URL(string: urlString)
    }

    var body: some View {
        if let url {
            VStack(alignment: .leading, spacing: 12) {
                Divider()
                    .overlay(SaviTheme.cardStroke)
                Button {
                    store.previewExploreItem(item, url: url)
                } label: {
                    HStack(spacing: 10) {
                        Label("Preview", systemImage: "eye.fill")
                            .font(.caption.weight(.bold))

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(SaviTheme.accentText)
            }
        }
    }
}

struct ExploreCompactCard: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        Button {
            store.openExploreItem(item)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.type.symbolName)
                    .font(.headline.weight(.bold))
                    .frame(width: 42, height: 42)
                    .background(Color(hex: item.color ?? "#C4B5FD"))
                    .foregroundStyle(SaviTheme.foreground(onHex: item.color ?? "#C4B5FD"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    ExploreTagLine(item: item)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SaviTheme.textMuted)
            }
            .padding(14)
            .saviCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}

struct ExploreMetaLine: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        HStack(spacing: 7) {
            Label(item.type.label, systemImage: item.type.symbolName)
            if let username = store.friendUsername(forExploreItem: item) {
                ExploreFriendBadge(username: username)
            }
            if let folder = store.folder(for: item.folderId) {
                Text(folder.name)
            }
            Text(store.sourceLabel(forExploreItem: item))
            SavedAgoText(savedAt: item.savedAt)
            if store.isExploreSeen(item) {
                Text("Seen")
            }
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(SaviTheme.textMuted)
        .lineLimit(1)
    }
}

struct ExploreFriendBadge: View {
    let username: String

    var body: some View {
        Text(username)
            .font(.system(.caption2, design: .monospaced).weight(.black))
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.28))
            .foregroundStyle(SaviTheme.chartreuse)
            .overlay(
                Capsule()
                    .stroke(SaviTheme.chartreuse.opacity(0.32), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

struct SavedAgoText: View {
    let savedAt: Double
    var prefix: String?

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            Text(displayText(at: context.date))
                .lineLimit(1)
                .accessibilityLabel("Saved \(SaviText.relativeSavedTime(savedAt, now: context.date))")
        }
    }

    private func displayText(at date: Date) -> String {
        let value = SaviText.relativeSavedTime(savedAt, now: date)
        return prefix.map { "\($0) \(value)" } ?? value
    }
}

struct SavedAgoLabel: View {
    let savedAt: Double
    var prefix: String?

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            Label(displayText(at: context.date), systemImage: "clock")
                .lineLimit(1)
                .accessibilityLabel("Saved \(SaviText.relativeSavedTime(savedAt, now: context.date))")
        }
    }

    private func displayText(at date: Date) -> String {
        let value = SaviText.relativeSavedTime(savedAt, now: date)
        return prefix.map { "\($0) \(value)" } ?? value
    }
}

struct ExploreTagLine: View {
    let item: SaviItem

    var body: some View {
        if !item.tags.isEmpty {
            Text(item.tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                .font(.caption.weight(.semibold))
                .foregroundStyle(SaviTheme.textMuted.opacity(0.9))
                .lineLimit(1)
        }
    }
}

struct FolderStrip: View {
    @EnvironmentObject private var store: SaviStore
    var title = "Quick Keepers"
    let folders: [SaviFolder]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, actionTitle: "All") {
                store.openKeepersManagement()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(folders) { folder in
                        let isLocked = folder.locked && !store.isProtectedKeeperUnlocked(folder)
                        Button {
                            store.openFolder(folder)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    FolderIconView(
                                        folder: folder,
                                        size: 32,
                                        cornerRadius: 11,
                                        font: SaviType.ui(.subheadline, weight: .black)
                                    )
                                    if folder.locked {
                                        Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                                            .font(.caption2.weight(.black))
                                            .foregroundStyle(SaviTheme.accentText)
                                    }
                                }
                                Text(folder.name)
                                    .font(SaviType.ui(.caption, weight: .black))
                                    .foregroundStyle(SaviTheme.text)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.78)
                                    .multilineTextAlignment(.leading)
                                Text(isLocked ? "Locked" : "\(store.count(in: folder)) saves")
                                    .font(SaviType.ui(.caption2, weight: .bold))
                                    .foregroundStyle(SaviTheme.textMuted)
                            }
                            .frame(width: 116, height: 104, alignment: .leading)
                            .padding(11)
                            .saviCard(cornerRadius: 15)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct ItemRow: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem
    var context: ItemRowContext = .home
    var showsMatchReasons = false

    var body: some View {
        HStack(alignment: .top, spacing: SaviItemLayout.rowSpacing) {
            ItemThumb(item: item)
                .frame(width: SaviItemLayout.rowThumbnail, height: SaviItemLayout.rowThumbnail)
                .clipShape(RoundedRectangle(cornerRadius: SaviItemLayout.thumbnailCorner, style: .continuous))
                .onTapGesture {
                    store.presentedItem = item
                }

            Button {
                store.presentedItem = item
            } label: {
                VStack(alignment: .leading, spacing: SaviItemLayout.rowTextSpacing) {
                    Text(item.title)
                        .font(SaviItemTypography.rowTitle)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(SaviTheme.text)
                        .fixedSize(horizontal: false, vertical: true)

                    ItemMetaLine(item: item)

                    ItemSnippetLine(item: item, context: context)

                    ItemTokenRow(
                        folder: store.folder(for: item.folderId),
                        tags: item.tags,
                        hidesTags: showsMatchReasons && store.hasActiveSearchControls
                    )

                    if showsMatchReasons, store.hasActiveSearchControls {
                        SearchMatchReasonLine(item: item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(SaviItemLayout.rowPadding)
        .saviCard(cornerRadius: SaviItemLayout.cardCorner)
    }
}

enum ItemRowContext {
    case home
    case search
}

enum SaviItemLayout {
    static let rowThumbnail: CGFloat = 78
    static let rowSpacing: CGFloat = 12
    static let rowTextSpacing: CGFloat = 6
    static let rowPadding: CGFloat = 10
    static let cardCorner: CGFloat = 17
    static let thumbnailCorner: CGFloat = 15
    static let pillHeight: CGFloat = 24
    static let detailPreviewCorner: CGFloat = 22
}

enum SaviItemTypography {
    static var rowTitle: Font { SaviType.ui(.headline, weight: .black) }
    static var rowSnippet: Font { SaviType.ui(.caption, weight: .semibold) }
    static var meta: Font { SaviType.ui(.caption2, weight: .bold) }
    static var pill: Font { SaviType.ui(.caption2, weight: .black) }
    static var matchReason: Font { SaviType.ui(.caption, weight: .semibold) }
    static var detailTitle: Font { SaviType.ui(.title2, weight: .black) }
    static var detailBodyTitle: Font { SaviType.ui(.caption, weight: .black) }
    static var detailBody: Font { SaviType.ui(.callout, weight: .regular) }
}

enum SaviItemDisplay {
    static func isNoteLike(_ item: SaviItem) -> Bool {
        if item.type == .text { return true }
        if item.source.lowercased().contains("paste") { return true }
        return item.url?.nilIfBlank == nil && item.tags.contains { $0 == "note" || $0 == "text" }
    }

    static func rowSnippet(for item: SaviItem, context: ItemRowContext) -> String? {
        guard let description = normalized(item.itemDescription),
              !description.caseInsensitiveCompare(item.title).isSame
        else {
            if context == .search, item.type == .file {
                return normalized(item.assetName ?? item.assetMime ?? "")
            }
            return nil
        }

        if isNoteLike(item) { return description }
        if context == .search { return description }
        if item.thumbnail?.nilIfBlank == nil && (item.type == .link || item.type == .file) {
            return description
        }
        return nil
    }

    static func rowSnippetLineLimit(for item: SaviItem) -> Int {
        isNoteLike(item) ? 2 : 1
    }

    static func detailBody(for item: SaviItem) -> String? {
        guard let description = normalized(item.itemDescription),
              !description.caseInsensitiveCompare(item.title).isSame
        else { return nil }
        return description
    }

    static func detailBodyTitle(for item: SaviItem) -> String {
        isNoteLike(item) ? "Note" : "Summary"
    }

    static func detailPreviewHeight(for item: SaviItem) -> CGFloat {
        if isNoteLike(item) { return 132 }
        if item.type == .file && item.thumbnail?.nilIfBlank == nil { return 156 }
        return 210
    }

    private static func normalized(_ value: String) -> String? {
        let trimmed = value
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
    }
}

private extension ComparisonResult {
    var isSame: Bool { self == .orderedSame }
}

struct ItemSnippetLine: View {
    let item: SaviItem
    let context: ItemRowContext

    var body: some View {
        if let snippet = SaviItemDisplay.rowSnippet(for: item, context: context) {
            Text(snippet)
                .font(SaviItemTypography.rowSnippet)
                .foregroundStyle(SaviTheme.textMuted)
                .lineLimit(SaviItemDisplay.rowSnippetLineLimit(for: item))
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ItemMetaLine: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        HStack(spacing: 7) {
            ItemMetaPart(
                title: store.primaryKindLabel(for: item),
                systemImage: item.type.symbolName
            )

            if let source = item.readableSource {
                ItemMetaDivider()
                ItemMetaPart(
                    title: source,
                    systemImage: SaviSearchPresentation.sourceSymbolName(for: source.lowercased())
                )
                .layoutPriority(1)
            }

            ItemMetaDivider()
            SavedTimeInline(savedAt: item.savedAt)
                .layoutPriority(2)
        }
        .font(SaviItemTypography.meta)
        .foregroundStyle(SaviTheme.textMuted)
        .lineLimit(1)
    }
}

struct ItemMetaPart: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
    }
}

struct ItemMetaDivider: View {
    var body: some View {
        Circle()
            .fill(SaviTheme.textMuted.opacity(0.45))
            .frame(width: 3, height: 3)
            .accessibilityHidden(true)
    }
}

struct SavedTimeInline: View {
    let savedAt: Double

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            Label(SaviText.compactRelativeSavedTime(savedAt, now: context.date), systemImage: "clock")
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel("Saved \(SaviText.relativeSavedTime(savedAt, now: context.date))")
        }
    }
}

struct ItemTokenRow: View {
    let folder: SaviFolder?
    let tags: [String]
    var hidesTags = false

    var body: some View {
        HStack(spacing: 6) {
            if let folder {
                KeeperPill(folder: folder)
                    .layoutPriority(2)
            }

            if !hidesTags {
                ItemTagPreview(tags: tags)
            }

            Spacer(minLength: 0)
        }
        .frame(height: SaviItemLayout.pillHeight)
        .clipped()
    }
}

struct ItemKindBadge: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        Label(store.primaryKindLabel(for: item), systemImage: item.type.symbolName)
            .font(SaviItemTypography.pill)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(SaviTheme.surfaceRaised.opacity(0.75))
            .foregroundStyle(SaviTheme.textMuted)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(SaviTheme.cardStroke, lineWidth: 1))
    }
}

struct ItemSourceInline: View {
    let source: String

    var body: some View {
        Label(source, systemImage: SaviSearchPresentation.sourceSymbolName(for: source.lowercased()))
            .font(SaviItemTypography.pill)
            .foregroundStyle(SaviTheme.textMuted)
            .lineLimit(1)
            .truncationMode(.tail)
            .minimumScaleFactor(0.75)
    }
}

struct KeeperPill: View {
    let folder: SaviFolder

    var body: some View {
        Label(folder.name, systemImage: folder.locked ? "lock.fill" : folder.symbolName)
            .font(SaviItemTypography.pill)
            .lineLimit(1)
            .minimumScaleFactor(0.76)
            .padding(.horizontal, 8)
            .frame(height: SaviItemLayout.pillHeight)
            .background(Color(hex: folder.color).opacity(0.18))
            .foregroundStyle(SaviTheme.text)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(hex: folder.color).opacity(0.38), lineWidth: 1))
    }
}

struct SavedTimePill: View {
    let savedAt: Double

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            Text(SaviText.compactRelativeSavedTime(savedAt, now: context.date))
                .font(SaviItemTypography.pill)
                .foregroundStyle(SaviTheme.textMuted)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(SaviTheme.surface)
                .clipShape(Capsule())
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel("Saved \(SaviText.relativeSavedTime(savedAt, now: context.date))")
        }
    }
}

struct ItemTagPreview: View {
    let tags: [String]

    var body: some View {
        ForEach(displayTags.prefix(1), id: \.self) { tag in
            Text("#\(tag)")
                .font(SaviItemTypography.pill)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.horizontal, 8)
                .frame(height: SaviItemLayout.pillHeight)
                .foregroundStyle(SaviTheme.textMuted)
                .background(SaviTheme.surface.opacity(0.72))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(SaviTheme.cardStroke.opacity(0.8), lineWidth: 1))
        }
    }

    private var displayTags: [String] {
        let generic: Set<String> = [
            "link", "article", "video", "image", "file", "post", "web", "save",
            "twitter", "x", "youtube", "instagram", "tiktok", "reddit", "facebook",
            "device", "clipboard", "text", "note"
        ]
        return tags.filter { tag in
            !generic.contains(tag.lowercased())
        }
    }
}

struct SearchMatchReasonLine: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        let reasons = store.matchReasons(for: item)
        if !reasons.isEmpty {
            Text("Matched by: \(reasons.joined(separator: " · "))")
                .font(SaviItemTypography.matchReason)
                .foregroundStyle(SaviTheme.accentText.opacity(0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

struct ItemPreview: View {
    let item: SaviItem

    var body: some View {
        ItemThumb(item: item, large: true, enablesPressPreview: false)
            .frame(maxWidth: .infinity)
            .frame(height: SaviItemDisplay.detailPreviewHeight(for: item))
            .clipShape(RoundedRectangle(cornerRadius: SaviItemLayout.detailPreviewCorner, style: .continuous))
    }
}

struct ItemThumb: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem
    var large = false
    var enablesPressPreview = true

    var body: some View {
        if enablesPressPreview {
            thumbnailBody
                .highPriorityGesture(pressPreviewGesture)
                .accessibilityAction(named: "Preview") {
                    store.previewItemContent(item)
                }
        } else {
            thumbnailBody
        }
    }

    private var thumbnailBody: some View {
        ZStack {
            LinearGradient(
                colors: SaviSourceBrand.brand(for: item)?.backgroundColors.map { Color(hex: $0) } ??
                    [Color(hex: item.color ?? "#2D2151"), Color(hex: "#141120")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            thumbnailContent
        }
        .contentShape(Rectangle())
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: large ? 24 : 16, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var pressPreviewGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.42)
            .onEnded { _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                store.previewItemContent(item)
            }
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let thumbnail = item.thumbnail?.nilIfBlank,
           thumbnail.hasPrefix("http"),
           let url = URL(string: thumbnail) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    fallback
                }
            }
        } else if let thumbnail = item.thumbnail?.nilIfBlank,
                  let image = SaviText.imageFromDataURL(thumbnail) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let thumbnail = item.thumbnail?.nilIfBlank,
                  SaviText.isSVGDataURL(thumbnail) {
            SaviSVGDataThumbnail(dataURL: thumbnail)
        } else {
            fallback
        }
    }

    @ViewBuilder
    private var fallback: some View {
        TimelineView(.periodic(from: Date(), by: 30)) { context in
            if let brand = SaviSourceBrand.brand(for: item),
               store.shouldShowBrandFallback(for: item, now: context.date) {
                SaviBrandFallbackThumb(brand: brand, large: large)
            } else if store.shouldShowThumbnailPending(for: item, now: context.date) {
                SaviThumbnailPendingThumb(
                    message: store.thumbnailPendingMessage(for: item),
                    large: large
                )
            } else {
                VStack(spacing: large ? 12 : 4) {
                    Image(systemName: item.type.symbolName)
                        .font(large ? .system(size: 46, weight: .bold) : .title3.weight(.bold))
                        .foregroundStyle(SaviTheme.chartreuse)
                    if large {
                        Text(item.readableSource ?? item.type.label)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
        }
    }
}

struct SaviThumbnailPendingThumb: View {
    let message: String
    var large = false

    var body: some View {
        VStack(spacing: large ? 10 : 5) {
            ProgressView()
                .tint(SaviTheme.chartreuse)
                .scaleEffect(large ? 1.1 : 0.82)
            if large {
                Text(message)
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
            }
        }
        .padding(large ? 18 : 8)
        .accessibilityLabel(message)
    }
}

struct SaviBrandFallbackThumb: View {
    let brand: SaviSourceBrand
    var large = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: brand.backgroundColors.map { Color(hex: $0) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: large ? 12 : 5) {
                brandMark

                if large {
                    Text(brand.name)
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(brand.foregroundColor.opacity(0.82))
                        .lineLimit(1)
                }
            }
            .padding(large ? 18 : 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: large ? 24 : 16, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .accessibilityLabel("\(brand.name) thumbnail")
    }

    @ViewBuilder
    private var brandMark: some View {
        if let symbolName = brand.symbolName {
            Image(systemName: symbolName)
                .font(large ? .system(size: 48, weight: .black) : .system(size: 26, weight: .black))
                .foregroundStyle(brand.foregroundColor)
        } else {
            Text(brand.mark)
                .font(.system(size: large ? brand.largeMarkSize : brand.markSize, weight: .black, design: .rounded))
                .foregroundStyle(brand.foregroundColor)
                .minimumScaleFactor(0.55)
                .lineLimit(1)
        }
    }
}

struct SaviSourceBrand {
    let name: String
    let mark: String
    let symbolName: String?
    let backgroundColors: [String]
    let foregroundColor: Color
    var markSize: CGFloat = 24
    var largeMarkSize: CGFloat = 50

    static func brand(for item: SaviItem) -> SaviSourceBrand? {
        let haystack = [
            item.source,
            item.url ?? "",
            item.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()

        if haystack.contains("youtube") || haystack.contains("youtu.be") {
            return .init(name: "YouTube", mark: "", symbolName: "play.fill", backgroundColors: ["#FF0033", "#8B000E"], foregroundColor: .white)
        }
        if haystack.contains("tiktok") || haystack.contains("vm.tiktok") {
            return .init(name: "TikTok", mark: "♪", symbolName: nil, backgroundColors: ["#111111", "#00F2EA", "#FF0050"], foregroundColor: .white, markSize: 30, largeMarkSize: 58)
        }
        if haystack.contains("instagram") {
            return .init(name: "Instagram", mark: "", symbolName: "camera.fill", backgroundColors: ["#F58529", "#DD2A7B", "#8134AF", "#515BD4"], foregroundColor: .white)
        }
        if haystack.contains("twitter.com") || haystack.contains("x.com") || haystack.contains(" x ") || haystack.contains("twitter") {
            return .init(name: "X", mark: "X", symbolName: nil, backgroundColors: ["#000000", "#1C1C1E"], foregroundColor: .white, markSize: 25, largeMarkSize: 52)
        }
        if haystack.contains("facebook") || haystack.contains("fb.watch") {
            return .init(name: "Facebook", mark: "f", symbolName: nil, backgroundColors: ["#1877F2", "#0B4FB3"], foregroundColor: .white, markSize: 30, largeMarkSize: 60)
        }
        if haystack.contains("threads.net") || haystack.contains("threads.com") || haystack.contains("threads") {
            return .init(name: "Threads", mark: "@", symbolName: nil, backgroundColors: ["#000000", "#2B2B2F"], foregroundColor: .white, markSize: 28, largeMarkSize: 56)
        }
        if haystack.contains("reddit") || haystack.contains("redd.it") {
            return .init(name: "Reddit", mark: "r/", symbolName: nil, backgroundColors: ["#FF4500", "#8F2500"], foregroundColor: .white, markSize: 22, largeMarkSize: 46)
        }
        if haystack.contains("spotify") {
            return .init(name: "Spotify", mark: "", symbolName: "music.note", backgroundColors: ["#1DB954", "#093B1F"], foregroundColor: .black)
        }
        if haystack.contains("pinterest") || haystack.contains("pin.it") {
            return .init(name: "Pinterest", mark: "P", symbolName: nil, backgroundColors: ["#E60023", "#7A0012"], foregroundColor: .white, markSize: 27, largeMarkSize: 58)
        }
        if haystack.contains("linkedin") {
            return .init(name: "LinkedIn", mark: "in", symbolName: nil, backgroundColors: ["#0A66C2", "#073D73"], foregroundColor: .white, markSize: 23, largeMarkSize: 48)
        }
        if haystack.contains("vimeo") {
            return .init(name: "Vimeo", mark: "v", symbolName: nil, backgroundColors: ["#1AB7EA", "#0A5C79"], foregroundColor: .white, markSize: 29, largeMarkSize: 58)
        }
        if haystack.contains("soundcloud") {
            return .init(name: "SoundCloud", mark: "", symbolName: "waveform", backgroundColors: ["#FF7700", "#8F3A00"], foregroundColor: .white)
        }
        if haystack.contains("bluesky") || haystack.contains("bsky.app") {
            return .init(name: "Bluesky", mark: "B", symbolName: nil, backgroundColors: ["#1185FE", "#62C6FF"], foregroundColor: .white, markSize: 27, largeMarkSize: 56)
        }
        if haystack.contains("maps") || haystack.contains("google.com/maps") || haystack.contains("maps.apple") {
            return .init(name: "Maps", mark: "", symbolName: "mappin.and.ellipse", backgroundColors: ["#34A853", "#0F6B3B"], foregroundColor: .white)
        }
        return nil
    }
}

struct SaviSVGDataThumbnail: UIViewRepresentable {
    let dataURL: String

    func makeCoordinator() -> Coordinator {
        Coordinator(dataURL: dataURL)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        load(dataURL, into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard context.coordinator.dataURL != dataURL else { return }
        context.coordinator.dataURL = dataURL
        load(dataURL, into: uiView)
    }

    private func load(_ dataURL: String, into webView: WKWebView) {
        let escaped = dataURL
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
        let html = """
        <!doctype html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width,initial-scale=1">
            <style>
              html, body { margin:0; width:100%; height:100%; overflow:hidden; background:transparent; }
              img { width:100%; height:100%; object-fit:cover; display:block; }
            </style>
          </head>
          <body><img src="\(escaped)" /></body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    final class Coordinator {
        var dataURL: String

        init(dataURL: String) {
            self.dataURL = dataURL
        }
    }
}

struct FolderCard: View {
    @EnvironmentObject private var store: SaviStore
    let folder: SaviFolder
    var isReordering = false
    var isDragged = false

    private var isLocked: Bool {
        folder.locked && !store.isProtectedKeeperUnlocked(folder)
    }

    var body: some View {
        Button {
            if !isReordering {
                store.openFolder(folder)
            }
        } label: {
            HStack(spacing: 12) {
                FolderIconView(
                    folder: folder,
                    size: 46,
                    cornerRadius: 14,
                    font: SaviType.ui(.title3, weight: .black)
                )
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(folder.name)
                            .font(SaviType.ui(.headline, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                        if folder.locked {
                            Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                                .font(.caption.weight(.black))
                                .foregroundStyle(SaviTheme.accentText)
                        }
                    }
                    Text(isLocked ? "Locked" : "\(store.count(in: folder)) saves")
                        .font(SaviType.ui(.subheadline, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                }
                Spacer()
                if isReordering {
                    Image(systemName: "line.3.horizontal")
                        .font(.subheadline.weight(.black))
                        .frame(width: 36, height: 36)
                        .background(SaviTheme.chartreuse)
                        .foregroundStyle(.black)
                        .clipShape(Circle())
                } else if !folder.system {
                    Button {
                        store.presentedSheet = .folderEditor(folder)
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 36, height: 36)
                            .background(SaviTheme.surfaceRaised)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .saviCard(cornerRadius: 16)
        }
        .buttonStyle(.plain)
        .scaleEffect(isDragged ? 1.02 : 1)
        .opacity(isDragged ? 0.68 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isDragged)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isReordering)
    }
}

struct SearchBar: View {
    @Binding var text: String
    var prompt = "Search SAVI"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SaviTheme.textMuted)
            TextField(prompt, text: $text)
                .font(SaviType.ui(.callout, weight: .semibold))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .foregroundStyle(SaviTheme.text)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(SaviTheme.textMuted)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .saviCard(cornerRadius: 16, shadow: false)
    }
}

struct SearchKindRail: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SaviSearchKind.visibleRail) { kind in
                    Button {
                        store.typeFilter = kind.id
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: kind.symbolName)
                                .font(SaviType.ui(.caption, weight: .black))
                            Text(kind.title)
                                .font(SaviType.ui(.caption, weight: .black))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(store.typeFilter == kind.id ? SaviTheme.chartreuse : SaviTheme.surface)
                        .foregroundStyle(store.typeFilter == kind.id ? .black : SaviTheme.text)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(store.typeFilter == kind.id ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 1)
        }
    }
}

struct SearchRefineButton: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        Button {
            store.openSearchRefine()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                Text("Refine")
                if store.refineFilterCount > 0 {
                    Text("\(store.refineFilterCount)")
                        .font(SaviType.ui(.caption2, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(store.refineFilterCount > 0 ? Color.black.opacity(0.12) : Color.clear)
                        .clipShape(Capsule())
                }
            }
            .font(SaviType.ui(.caption, weight: .black))
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(store.refineFilterCount > 0 ? SaviTheme.chartreuse : SaviTheme.surface)
            .foregroundStyle(store.refineFilterCount > 0 ? .black : SaviTheme.text)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(store.refineFilterCount > 0 ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SearchFacetBar: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SearchFacet.allCases) { facet in
                SearchFacetButton(
                    facet: facet,
                    value: value(for: facet),
                    active: isActive(facet)
                ) {
                    store.openSearchFacet(facet)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func value(for facet: SearchFacet) -> String {
        switch facet {
        case .type:
            return store.typeFilter == "all" ? "All" : SaviSearchKind.all.first(where: { $0.id == store.typeFilter })?.title ?? "All"
        case .keeper:
            return store.folderFilter == "f-all" ? "All" : store.folder(for: store.folderFilter)?.name ?? "All"
        case .tag:
            return store.tagFilter == "all" ? "Any" : "#\(store.tagFilter)"
        case .source:
            return store.sourceFilter == "all" ? "Any" : store.sourceOptions().first(where: { $0.key == store.sourceFilter })?.label ?? store.sourceFilter
        }
    }

    private func isActive(_ facet: SearchFacet) -> Bool {
        switch facet {
        case .type: return store.typeFilter != "all"
        case .keeper: return store.folderFilter != "f-all"
        case .tag: return store.tagFilter != "all"
        case .source: return store.sourceFilter != "all"
        }
    }
}

struct SearchFacetButton: View {
    let facet: SearchFacet
    let value: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: facet.symbolName)
                    .font(SaviType.ui(.caption, weight: .black))
                VStack(alignment: .leading, spacing: 1) {
                    Text(facet.title)
                        .font(SaviType.ui(.caption2, weight: .black))
                        .foregroundStyle(active ? .black.opacity(0.65) : SaviTheme.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                    Text(value)
                        .font(SaviType.ui(.caption, weight: .black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(active ? SaviTheme.chartreuse : SaviTheme.surface)
            .foregroundStyle(active ? .black : SaviTheme.text)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(active ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ActiveSearchFiltersRow: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !store.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ActiveFilterChip(title: "Search", systemImage: "magnifyingglass") {
                        store.query = ""
                    }
                }
                if store.typeFilter != "all" {
                    ActiveFilterChip(
                        title: store.searchKindTitle(for: store.typeFilter),
                        systemImage: "square.stack.3d.up.fill"
                    ) {
                        store.typeFilter = "all"
                    }
                }
                if store.folderFilter != "f-all" {
                    ActiveFilterChip(
                        title: store.folder(for: store.folderFilter)?.name ?? "Keeper",
                        systemImage: "folder.fill"
                    ) {
                        store.folderFilter = "f-all"
                    }
                }
                if store.tagFilter != "all" {
                    ActiveFilterChip(title: "#\(store.tagFilter)", systemImage: "number") {
                        store.tagFilter = "all"
                    }
                }
                if store.sourceFilter != "all" {
                    ActiveFilterChip(
                        title: store.sourceOptions().first(where: { $0.key == store.sourceFilter })?.label ?? store.sourceFilter,
                        systemImage: SaviSearchPresentation.sourceSymbolName(for: store.sourceFilter)
                    ) {
                        store.sourceFilter = "all"
                    }
                }
                if store.dateFilter != SearchDateFilter.all.rawValue {
                    ActiveFilterChip(
                        title: store.dateFilterTitle(for: store.dateFilter),
                        systemImage: "calendar"
                    ) {
                        store.clearDateFilter()
                    }
                }
                if store.hasFilter != SearchHasFilter.all.rawValue {
                    ActiveFilterChip(
                        title: store.hasFilterTitle(for: store.hasFilter),
                        systemImage: "checklist"
                    ) {
                        store.clearHasFilter()
                    }
                }

                Button {
                    store.resetFilters()
                } label: {
                    Label("Reset", systemImage: "xmark.circle.fill")
                        .font(SaviType.ui(.caption, weight: .black))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .foregroundStyle(SaviTheme.accentText)
                        .background(SaviTheme.surface)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 1)
        }
    }
}

struct ActiveFilterChip: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.caption2.weight(.black))
            }
            .font(SaviType.ui(.caption, weight: .black))
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(SaviTheme.surfaceRaised)
            .foregroundStyle(SaviTheme.text)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SearchRefineSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @State private var tagSearch = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SearchRefineSection(title: "Keeper") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Chip(
                                    title: "All Keepers",
                                    systemImage: "square.grid.2x2.fill",
                                    count: store.folder(for: "f-all").map { store.count(in: $0) },
                                    active: store.folderFilter == "f-all"
                                ) {
                                    store.folderFilter = "f-all"
                                }

                                Chip(title: "Manage", systemImage: "slider.horizontal.3", active: false) {
                                    store.openKeepersManagement()
                                    dismiss()
                                }

                                ForEach(store.orderedFoldersForDisplay()) { folder in
                                    let locked = folder.locked && !store.isProtectedKeeperUnlocked(folder)
                                    Chip(
                                        title: folder.name,
                                        systemImage: locked ? "lock.fill" : folder.symbolName,
                                        count: locked ? nil : store.count(in: folder),
                                        active: store.folderFilter == folder.id
                                    ) {
                                        store.selectFolderFilter(folder)
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }

                    SearchRefineSection(title: "Source") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Chip(title: "Any source", systemImage: "square.and.arrow.down", active: store.sourceFilter == "all") {
                                    store.sourceFilter = "all"
                                }

                                ForEach(store.sourceOptions(), id: \.key) { source in
                                    Chip(
                                        title: source.label,
                                        systemImage: SaviSearchPresentation.sourceSymbolName(for: source.key),
                                        count: source.count,
                                        active: store.sourceFilter == source.key
                                    ) {
                                        store.sourceFilter = source.key
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }

                    SearchRefineSection(title: "Tags") {
                        SearchBar(text: $tagSearch, prompt: "Search tags")

                        let tags = filteredTags()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Chip(title: "Any tag", systemImage: "number", active: store.tagFilter == "all") {
                                    store.tagFilter = "all"
                                }

                                ForEach(tags, id: \.key) { tag in
                                    Chip(title: tag.label, count: tag.count, active: store.tagFilter == tag.key) {
                                        store.tagFilter = tag.key
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }

                        if tags.isEmpty {
                            Text("No contextual tags for this result set.")
                                .font(SaviType.ui(.caption, weight: .semibold))
                                .foregroundStyle(SaviTheme.textMuted)
                        }
                    }

                    SearchRefineSection(title: "Date") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SearchDateFilter.allCases) { option in
                                    Chip(title: option.title, systemImage: option.symbolName, active: store.dateFilter == option.rawValue) {
                                        store.dateFilter = option.rawValue
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }

                    SearchRefineSection(title: "Has") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SearchHasFilter.allCases) { option in
                                    Chip(title: option.title, systemImage: option.symbolName, active: store.hasFilter == option.rawValue) {
                                        store.hasFilter = option.rawValue
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Refine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if store.refineFilterCount > 0 {
                        Button("Clear") {
                            store.clearRefineFilters()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func filteredTags() -> [(key: String, label: String, count: Int)] {
        let options = store.contextualTagOptions(limit: 80)
        let trimmed = tagSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return options }
        let normalized = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        return options.filter { tag in
            tag.key.contains(normalized) || tag.label.lowercased().contains(normalized)
        }
    }
}

struct SearchRefineSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
            content
        }
    }
}

struct SearchFacetSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    let facet: SearchFacet
    @State private var tagSearch = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    content
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle(facet.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.activeSearchFacet = nil
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch facet {
        case .type:
            ForEach(store.searchKindOptions(includeEmpty: true), id: \.kind.id) { option in
                SearchFacetOptionRow(
                    title: option.kind.title,
                    subtitle: option.kind.id == "all" ? "All searchable saves" : nil,
                    systemImage: option.kind.symbolName,
                    count: option.count,
                    active: store.typeFilter == option.kind.id
                ) {
                    store.typeFilter = option.kind.id
                    store.activeSearchFacet = nil
                    dismiss()
                }
            }
        case .keeper:
            SearchFacetOptionRow(
                title: "All Keepers",
                subtitle: "Search every unlocked save",
                systemImage: "square.grid.2x2.fill",
                count: store.folder(for: "f-all").map { store.count(in: $0) },
                active: store.folderFilter == "f-all"
            ) {
                store.folderFilter = "f-all"
                store.activeSearchFacet = nil
                dismiss()
            }

            Button {
                store.openKeepersManagement()
                dismiss()
            } label: {
                Label("Manage Keepers", systemImage: "slider.horizontal.3")
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviSecondaryButtonStyle())
            .padding(.bottom, 4)

            ForEach(store.orderedFoldersForDisplay()) { folder in
                let locked = folder.locked && !store.isProtectedKeeperUnlocked(folder)
                SearchFacetOptionRow(
                    title: folder.name,
                    subtitle: locked ? "Locked" : "\(store.count(in: folder)) saves",
                    systemImage: locked ? "lock.fill" : folder.symbolName,
                    count: nil,
                    active: store.folderFilter == folder.id
                ) {
                    store.selectFolderFilter(folder)
                }
            }
        case .tag:
            SearchBar(text: $tagSearch, prompt: "Search tags")
                .padding(.bottom, 2)

            SearchFacetOptionRow(
                title: "Any tag",
                subtitle: "Do not filter by tag",
                systemImage: "number",
                count: nil,
                active: store.tagFilter == "all"
            ) {
                store.tagFilter = "all"
                store.activeSearchFacet = nil
                dismiss()
            }

            let tags = filteredTags()
            if tags.isEmpty {
                EmptyStateView(
                    symbol: "number",
                    title: "No tags",
                    message: "Tags from saved items will appear here."
                )
            } else {
                ForEach(tags, id: \.key) { tag in
                    SearchFacetOptionRow(
                        title: tag.label,
                        subtitle: nil,
                        systemImage: "number",
                        count: tag.count,
                        active: store.tagFilter == tag.key
                    ) {
                        store.tagFilter = tag.key
                        store.activeSearchFacet = nil
                        dismiss()
                    }
                }
            }
        case .source:
            SearchFacetOptionRow(
                title: "Any source",
                subtitle: "Search across every source",
                systemImage: "square.and.arrow.down",
                count: nil,
                active: store.sourceFilter == "all"
            ) {
                store.sourceFilter = "all"
                store.activeSearchFacet = nil
                dismiss()
            }

            ForEach(store.sourceOptions(), id: \.key) { source in
                SearchFacetOptionRow(
                    title: source.label,
                    subtitle: nil,
                    systemImage: SaviSearchPresentation.sourceSymbolName(for: source.key),
                    count: source.count,
                    active: store.sourceFilter == source.key
                ) {
                    store.sourceFilter = source.key
                    store.activeSearchFacet = nil
                    dismiss()
                }
            }
        }
    }

    private func filteredTags() -> [(key: String, label: String, count: Int)] {
        let options = store.tagOptions(limit: 80)
        let trimmed = tagSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return options }
        let normalized = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        return options.filter { tag in
            tag.key.contains(normalized) || tag.label.lowercased().contains(normalized)
        }
    }
}

struct SearchFacetOptionRow: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    var count: Int?
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .frame(width: 36, height: 36)
                    .background(active ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                    .foregroundStyle(active ? .black : SaviTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(1)
                    if let subtitle {
                        Text(subtitle)
                            .font(SaviType.ui(.caption, weight: .semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let count {
                    Text("\(count)")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(active ? .black : SaviTheme.textMuted)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(active ? SaviTheme.chartreuse.opacity(0.7) : SaviTheme.surfaceRaised)
                        .clipShape(Capsule())
                }
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .font(SaviType.ui(.headline, weight: .black))
                        .foregroundStyle(SaviTheme.accentText)
                }
            }
            .padding(12)
            .saviCard(cornerRadius: 16, shadow: false)
        }
        .buttonStyle(.plain)
    }
}

enum SaviSearchPresentation {
    static func sourceSymbolName(for key: String) -> String {
        if key.contains("youtube") { return "play.rectangle.fill" }
        if key.contains("instagram") { return "camera.fill" }
        if key.contains("tiktok") { return "music.note" }
        if key == "x" || key.contains("twitter") { return "bubble.left.fill" }
        if key.contains("reddit") { return "bubble.left.and.bubble.right.fill" }
        if key.contains("facebook") { return "person.2.fill" }
        if key.contains("threads") { return "at" }
        if key.contains("linkedin") { return "briefcase.fill" }
        if key.contains("spotify") { return "music.quarternote.3" }
        if key.contains("soundcloud") { return "waveform" }
        if key.contains("vimeo") { return "video.fill" }
        if key.contains("pinterest") { return "pin.fill" }
        if key.contains("bluesky") || key.contains("bsky") { return "cloud.fill" }
        if key.contains("maps") { return "map.fill" }
        if key.contains("device") { return "iphone" }
        if key.contains("paste") { return "clipboard.fill" }
        return "link"
    }
}

struct SearchFilterSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
                .textCase(.uppercase)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    content
                }
                .padding(.vertical, 1)
            }
        }
    }
}

struct Chip: View {
    let title: String
    var systemImage: String?
    var count: Int?
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.black))
                }
                Text(title)
                    .lineLimit(1)
                if let count {
                    Text("\(count)")
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(active ? Color.black.opacity(0.12) : SaviTheme.surfaceRaised)
                        .clipShape(Capsule())
                }
            }
            .font(.caption.weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(active ? SaviTheme.chartreuse : SaviTheme.surface)
            .foregroundStyle(active ? .black : SaviTheme.text)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(active ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FolderPicker: View {
    @EnvironmentObject private var store: SaviStore
    @Binding var selectedFolderId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keeper")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SaviTheme.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Chip(title: "Auto", active: selectedFolderId.isEmpty) {
                        selectedFolderId = ""
                    }
                    ForEach(store.folders.filter { $0.id != "f-all" }) { folder in
                        Chip(title: folder.name, systemImage: folder.locked ? "lock.fill" : nil, active: selectedFolderId == folder.id) {
                            selectedFolderId = folder.id
                        }
                    }
                }
            }
        }
    }
}

struct SaviTextField: View {
    let title: String
    @Binding var text: String
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SaviTheme.textMuted)
            TextField(prompt, text: $text)
                .padding(14)
                .foregroundStyle(SaviTheme.text)
                .saviCard(cornerRadius: 16, shadow: false)
        }
    }
}

struct PublicProfileSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var bio: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeaderBlock(
                        eyebrow: "Friends",
                        title: "Public profile",
                        subtitle: "This is how friends find your public link previews in SAVI.",
                        titleSize: 30
                    )

                    SaviTextField(title: "Username", text: $username, prompt: "yourname")
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SaviTextField(title: "Display name", text: $displayName, prompt: "Your name")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                        TextField("Optional", text: $bio, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .padding(14)
                            .foregroundStyle(SaviTheme.text)
                            .saviCard(cornerRadius: 16, shadow: false)
                    }

                    Text("Public Keepers publish link metadata only. Do not mark a Keeper public unless you are comfortable sharing those URLs and previews.")
                        .font(SaviType.ui(.footnote, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .background(SaviTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                username = store.publicProfile.username
                displayName = store.publicProfile.displayName
                bio = store.publicProfile.bio
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updatePublicProfile(username: username, displayName: displayName, bio: bio)
                        dismiss()
                    }
                    .disabled(SaviSocialText.normalizedUsername(username).isEmpty)
                }
            }
        }
    }
}

struct TagFlow: View {
    let tags: [String]

    var body: some View {
        if !displayTags.isEmpty {
            ViewThatFits(in: .horizontal) {
                tagRow(Array(displayTags.prefix(4)))
                tagRow(Array(displayTags.prefix(2)))
                tagRow(Array(displayTags.prefix(1)))
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var displayTags: [String] {
        let generic: Set<String> = [
            "link", "article", "video", "image", "file", "post", "web", "save",
            "twitter", "x", "youtube", "instagram", "tiktok", "reddit", "facebook",
            "device", "clipboard", "text", "note", "friend"
        ]
        let useful = tags.filter { !generic.contains($0.lowercased()) }
        let source = useful.isEmpty ? tags : useful
        return Array(source.prefix(6))
    }

    @ViewBuilder
    private func tagRow(_ visibleTags: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(visibleTags, id: \.self) { tag in
                tagChip("#\(tag)")
            }

            let remaining = max(0, tags.count - visibleTags.count)
            if remaining > 0 {
                tagChip("+\(remaining)", muted: true)
                    .accessibilityLabel("\(remaining) more tags")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tagChip(_ title: String, muted: Bool = false) -> some View {
        Text(title)
            .font(SaviType.ui(.caption2, weight: .black))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(muted ? SaviTheme.surfaceRaised.opacity(0.72) : SaviTheme.surface.opacity(0.72))
            .foregroundStyle(muted ? SaviTheme.textMuted.opacity(0.82) : SaviTheme.textMuted)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(SaviTheme.cardStroke.opacity(0.8), lineWidth: 1))
    }
}

struct StatsPanel: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        HStack(spacing: 10) {
            StatCell(value: "\(store.items.count)", label: "Saves")
            StatCell(value: "\(store.folders.count - 1)", label: "Keepers")
            StatCell(value: "\(store.assets.count)", label: "Files")
        }
    }
}

struct StatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(SaviType.display(size: 28, weight: .black))
                .foregroundStyle(SaviTheme.text)
            Text(label)
                .font(SaviType.ui(.caption, weight: .heavy))
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .saviCard(cornerRadius: 16)
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let symbol: String
    let content: Content

    init(title: String, symbol: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbol = symbol
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.accentText)
                    .frame(width: 34, height: 34)
                    .background(SaviTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(title)
                    .font(SaviType.ui(.title3, weight: .black))
                    .foregroundStyle(SaviTheme.text)
            }
            content
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .saviCard(cornerRadius: 18)
    }
}

struct ThemeButton: View {
    let title: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SaviType.ui(.headline, weight: .black))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .background(active ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                .foregroundStyle(active ? .black : SaviTheme.text)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(active ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(SaviType.display(size: 38, weight: .black))
                .foregroundStyle(SaviTheme.accentText)
            Text(title)
                .font(SaviType.ui(.headline, weight: .black))
                .foregroundStyle(SaviTheme.text)
            Text(message)
                .font(SaviType.ui(.subheadline))
                .multilineTextAlignment(.center)
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(26)
        .saviCard(cornerRadius: 18)
    }
}

struct SaviCoachOverlay: View {
    let step: SaviCoachStep
    let currentIndex: Int
    let totalCount: Int
    let nextAction: () -> Void
    let skipAction: () -> Void

    private var isLastStep: Bool {
        currentIndex == totalCount
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.34)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: step.symbolName)
                        .font(SaviType.ui(.title3, weight: .black))
                        .frame(width: 46, height: 46)
                        .background(SaviTheme.chartreuse)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(step.eyebrow.uppercased()) · \(currentIndex)/\(totalCount)")
                            .font(SaviType.ui(.caption, weight: .heavy))
                            .foregroundStyle(SaviTheme.accentText)
                        Text(step.title)
                            .font(SaviType.ui(.title3, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Button {
                        skipAction()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.black))
                            .frame(width: 30, height: 30)
                            .background(SaviTheme.surfaceRaised)
                            .foregroundStyle(SaviTheme.textMuted)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Skip tour")
                }

                Text(step.message)
                    .font(SaviType.ui(.callout, weight: .semibold))
                    .foregroundStyle(SaviTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Label(step.targetHint, systemImage: step.hintSymbolName)
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(SaviTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                HStack(spacing: 10) {
                    Button {
                        skipAction()
                    } label: {
                        Text("Skip")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SaviSecondaryButtonStyle())

                    Button {
                        nextAction()
                    } label: {
                        Label(isLastStep ? "Done" : "Next", systemImage: isLastStep ? "checkmark" : "arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SaviPrimaryButtonStyle())
                }
            }
            .padding(16)
            .background(SaviTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: SaviTheme.cardShadow.opacity(0.28), radius: 26, x: 0, y: 14)
            .padding(.horizontal, 16)
            .padding(.bottom, 104)
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        ZStack {
            SaviTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                Text("SAVI")
                    .font(SaviType.display(size: 52, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text("Save first. Find it later.")
                    .font(SaviType.ui(.title, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("SAVI is your pocket archive for links, videos, images, files, notes, and the odd brilliant thing.")
                    .font(SaviType.ui(.callout, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    OnboardingFeatureCard(
                        symbolName: "square.and.arrow.down",
                        title: "Save from anywhere",
                        message: "Use the iOS Share button or the plus in SAVI. The save happens first; title, preview, tags, and Keeper can catch up."
                    )
                    OnboardingFeatureCard(
                        symbolName: "sparkles",
                        title: "Browse what you forgot",
                        message: "Explore shuffles saved links, videos, images, and places into a scroll that feels alive."
                    )
                    OnboardingFeatureCard(
                        symbolName: "folder.fill",
                        title: "Keepers stay yours",
                        message: "Keepers are your main stacks. Drag them into the order that matters to you."
                    )
                }

                Spacer()
                Button {
                    withAnimation { store.finishOnboarding() }
                } label: {
                    Text("Start quick tour")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaviPrimaryButtonStyle())
            }
            .padding(24)
        }
    }
}

struct OnboardingFeatureCard: View {
    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(SaviType.ui(.headline, weight: .black))
                .frame(width: 38, height: 38)
                .background(SaviTheme.surfaceRaised)
                .foregroundStyle(SaviTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text(message)
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(13)
        .saviCard(cornerRadius: 17, shadow: false)
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(SaviType.ui(.subheadline, weight: .bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 14)
            .padding(.horizontal, 18)
    }
}

struct SaviPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaviType.ui(.headline, weight: .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(SaviTheme.chartreuse.opacity(configuration.isPressed ? 0.75 : 1))
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SaviSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaviType.ui(.headline, weight: .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(SaviTheme.surfaceRaised.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(SaviTheme.text)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
    }
}

struct SaviDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaviType.ui(.headline, weight: .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.red.opacity(configuration.isPressed ? 0.22 : 0.16))
            .foregroundStyle(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
    }
}

struct SaviType {
    static func display(size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func ui(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}

private extension View {
    @ViewBuilder
    func saviRoundedFontDesign() -> some View {
        if #available(iOS 16.1, *) {
            self.fontDesign(.rounded)
        } else {
            self
        }
    }
}

struct SaviTheme {
    static let background = adaptive(dark: "#100B1C", light: "#FBF8FF")
    static let surface = adaptive(dark: "#1C1530", light: "#FFFFFF")
    static let surfaceRaised = adaptive(dark: "#2A2144", light: "#F1EBF8")
    static let text = adaptive(dark: "#F5F0FF", light: "#160F22")
    static let textMuted = adaptive(dark: "#B7A9D6", light: "#5D526C")
    static let chartreuse = adaptive(dark: "#D8FF3C", light: "#A6DB16")
    static let accentText = adaptive(dark: "#D8FF3C", light: "#563082")
    static let cardStroke = adaptive(dark: "#2F244C", light: "#D8CEE6")
    static let cardShadow = adaptive(dark: "#000000", light: "#5E4A73")

    private static func adaptive(dark: String, light: String) -> Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    static func foreground(onHex hex: String) -> Color {
        Color(UIColor(hex: hex).saviUsesLightForeground ? UIColor.white : UIColor.black)
    }
}

private struct SaviCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadow: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(SaviTheme.surface)
            .clipShape(shape)
            .overlay(shape.stroke(SaviTheme.cardStroke, lineWidth: 1))
            .shadow(
                color: shadow ? SaviTheme.cardShadow.opacity(0.08) : Color.clear,
                radius: shadow ? 14 : 0,
                x: 0,
                y: shadow ? 6 : 0
            )
    }
}

extension View {
    func saviCard(cornerRadius: CGFloat = 18, shadow: Bool = true) -> some View {
        modifier(SaviCardModifier(cornerRadius: cornerRadius, shadow: shadow))
    }
}

// MARK: - Legacy Migration Host

struct LegacyMigrationHost: UIViewRepresentable {
    let onComplete: (LegacyMigrationPayload) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "saviMigration")
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
        .init(id: "f-must-see", name: "Watch / Read Later", color: "#4C1D95", image: nil, system: false, symbolName: "bookmark.fill", order: 0),
        .init(id: "f-paste-bin", name: "Paste Bin", color: "#8A7CA8", image: nil, system: false, symbolName: "clipboard.fill", order: 1),
        .init(id: "f-wtf-favorites", name: "Science Stuff", color: "#C4B5FD", image: nil, system: false, symbolName: "atom", order: 2),
        .init(id: "f-growth", name: "AI Hacks", color: "#A78BFA", image: nil, system: false, symbolName: "bolt.fill", order: 3),
        .init(id: "f-lmao", name: "LULZ", color: "#D8FF3C", image: nil, system: false, symbolName: "theatermasks.fill", order: 4),
        .init(id: "f-private-vault", name: "Private Vault", color: "#0A0614", image: nil, system: false, symbolName: "lock.fill", order: 5, locked: true),
        .init(id: "f-travel", name: "Places", color: "#B8D4F5", image: nil, system: false, symbolName: "mappin.and.ellipse", order: 6),
        .init(id: "f-recipes", name: "Recipes & Food", color: "#F4C6A5", image: nil, system: false, symbolName: "fork.knife", order: 7),
        .init(id: "f-health", name: "Health Hacks", color: "#C4E8D4", image: nil, system: false, symbolName: "heart.fill", order: 8),
        .init(id: "f-design", name: "Design Inspo", color: "#E8DCF5", image: nil, system: false, symbolName: "paintpalette.fill", order: 9),
        .init(id: "f-research", name: "Research", color: "#DDD1F3", image: nil, system: false, symbolName: "magnifyingglass", order: 10),
        .init(id: "f-tinfoil", name: "Tinfoil Hat Club", color: "#6D28D9", image: nil, system: false, symbolName: "eye.fill", order: 11),
        .init(id: "f-random", name: "Random AF", color: "#FFE066", image: nil, system: false, symbolName: "shuffle", order: 12),
        .init(id: "f-all", name: "All Saves", color: "#D8FF3C", image: nil, system: true, symbolName: "sparkles", order: 13)
    ]

    static func picsumThumb(_ seed: String, width: Int = 900, height: Int = 1100) -> String {
        "https://picsum.photos/seed/\(seed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? seed)/\(width)/\(height)"
    }

    static func youtubeThumb(_ videoId: String) -> String {
        "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
    }

    static let items: [SaviItem] = [
        SaviItem(title: "The AI automation checklist", itemDescription: "Batch renaming, scraping, reminders, exports, and all the tiny scripts that quietly pay rent.", url: "https://example.com/ai-automation", source: "Web", type: .article, folderId: "f-growth", tags: ["ai", "automation", "productivity"], thumbnail: picsumThumb("ai-productivity-stack"), color: "#A78BFA", demo: true),
        SaviItem(title: "Late-night pasta formula", itemDescription: "A recipe save that turns one Keeper into dinner plans instantly.", url: "https://example.com/pasta", source: "Web", type: .article, folderId: "f-recipes", tags: ["recipe", "dinner"], thumbnail: picsumThumb("viral-tiktok-pasta"), color: "#F4C6A5", demo: true),
        SaviItem(title: "Brutalist mobile nav inspiration", itemDescription: "A compact design reference for thumb-first interfaces.", url: "https://example.com/mobile-nav", source: "Behance", type: .image, folderId: "f-design", tags: ["design", "mobile", "ui"], thumbnail: picsumThumb("dribbble-best-2024"), color: "#E8DCF5", demo: true),
        SaviItem(title: "Constitutional AI notes", itemDescription: "An important read on model behavior shaping.", url: "https://example.com/research", source: "Research", type: .article, folderId: "f-research", tags: ["paper", "ai"], thumbnail: picsumThumb("claude-constitution"), color: "#DDD1F3", demo: true),
        SaviItem(title: "Tokyo ramen map pin", itemDescription: "The one map pin that turns a trip Keeper into dinner plans.", url: "https://maps.apple.com/?q=ramen", source: "Maps", type: .place, folderId: "f-travel", tags: ["place", "food"], thumbnail: picsumThumb("nyc-pasta-map"), color: "#B8D4F5", demo: true),
        SaviItem(title: "Return receipt PDF", itemDescription: "A practical file save for the forms you always need later.", source: "Device", type: .file, folderId: "f-private-vault", tags: ["receipt", "private"], thumbnail: picsumThumb("tax-documents"), color: "#0A0614", demo: true),
        SaviItem(title: "Workout recovery protocol", itemDescription: "Sleep, mobility, and protein notes for busy weeks.", url: "https://example.com/recovery", source: "Web", type: .article, folderId: "f-health", tags: ["health", "sleep"], thumbnail: picsumThumb("sleep-hygiene"), color: "#C4E8D4", demo: true),
        SaviItem(title: "Perfectly cursed screenshot", itemDescription: "An internet moment that belongs exactly where it is.", source: "Device", type: .image, folderId: "f-lmao", tags: ["meme", "screenshot"], thumbnail: picsumThumb("this-is-fine"), color: "#D8FF3C", demo: true),
        SaviItem(title: "Tinfoil hat origin story", itemDescription: "A weird internet rabbit hole, saved for later.", url: "https://example.com/tinfoil", source: "Web", type: .article, folderId: "f-tinfoil", tags: ["mystery"], thumbnail: picsumThumb("pyramid-theories"), color: "#6D28D9", demo: true),
        SaviItem(title: "Paste: launch checklist", itemDescription: "Export backup, smoke test share extension, verify search filters, send build.", source: "Paste", type: .text, folderId: "f-paste-bin", tags: ["note", "checklist"], color: "#8A7CA8", demo: true)
    ].enumerated().map { index, item in
        var next = item
        next.savedAt = Date().timeIntervalSince1970 * 1000 - Double(index + 1) * 3_600_000
        return next
    }

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

    static func defaultOrder(for id: String) -> Int {
        folders.first(where: { $0.id == id })?.order ?? 99
    }
}

// MARK: - Utilities

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
        let normalized = current.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ||
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
        if key.contains("growth") || key.contains("career") || key.contains("business") || key.contains("productivity") || key.contains("ai hack") { return "bolt.fill" }
        if key.contains("wtf") || key.contains("wild") || key.contains("favorite") || key.contains("science") { return "atom" }
        if key.contains("tinfoil") || key.contains("conspiracy") || key.contains("alien") { return "eye.fill" }
        if key.contains("lulz") || key.contains("meme") || key.contains("funny") || key.contains("lol") { return "theatermasks.fill" }
        if key.contains("health") || key.contains("fitness") || key.contains("wellness") { return "heart.fill" }
        if key.contains("recipe") || key.contains("food") || key.contains("cook") { return "fork.knife" }
        if key.contains("travel") || key.contains("place") || key.contains("map") || key.contains("trip") { return "mappin.and.ellipse" }
        if key.contains("design") || key.contains("inspo") || key.contains("brand") || key.contains("ui") || key.contains("ux") { return "paintpalette.fill" }
        if key.contains("research") || key.contains("study") || key.contains("paper") { return "magnifyingglass" }
        if key.contains("must") || key.contains("later") || key.contains("watch") || key.contains("read") { return "bookmark.fill" }
        if key.contains("paste") { return "clipboard.fill" }
        if key.contains("random") || key.contains("misc") { return "shuffle" }
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
