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

// MARK: - Models

enum SaviReleaseGate {
#if DEBUG
    static let socialFeaturesEnabled = true
    static let seedsDemoSocialContent = true
    static let debugToolsEnabled = true
#else
    static let socialFeaturesEnabled = false
    static let seedsDemoSocialContent = false
    static let debugToolsEnabled = false
#endif

    static var demoLibraryEnabled: Bool {
        sampleLibraryEnabled
    }

    static var sampleLibraryEnabled: Bool {
        if let bool = Bundle.main.object(forInfoDictionaryKey: "SAVISampleLibraryEnabled") as? Bool {
            return bool
        }
        if let string = Bundle.main.object(forInfoDictionaryKey: "SAVISampleLibraryEnabled") as? String {
            let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if ["1", "yes", "true"].contains(normalized) { return true }
            if ["0", "no", "false"].contains(normalized) { return false }
        }
#if DEBUG
        return true
#else
        return false
#endif
    }

    static var buildChannel: String {
        socialFeaturesEnabled ? "Debug" : "TestFlight"
    }
}

enum SaviTab: Hashable {
    case home
    case search
    case explore
    case folders
    case profile
}

enum SearchFacet: String, CaseIterable, Identifiable {
    case type
    case tag
    case keeper
    case date
    case source
    case has

    var id: String { rawValue }

    static let visible: [SearchFacet] = [.type, .keeper, .tag, .date, .source]

    var title: String {
        switch self {
        case .type: return "Type"
        case .tag: return "Tags"
        case .keeper: return "Folders"
        case .date: return "Date"
        case .source: return "Source"
        case .has: return "Has"
        }
    }

    var symbolName: String {
        switch self {
        case .type: return "square.stack.3d.up.fill"
        case .keeper: return "folder.fill"
        case .tag: return "number"
        case .date: return "calendar"
        case .source: return "square.and.arrow.down"
        case .has: return "checklist"
        }
    }
}

enum SearchDateFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case yesterday
    case last7Days = "week"
    case month
    case last30Days
    case thisYear
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All time"
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .last7Days: return "Last 7 days"
        case .month: return "This month"
        case .last30Days: return "Last 30 days"
        case .thisYear: return "This year"
        case .custom: return "Custom range"
        }
    }

    var symbolName: String {
        switch self {
        case .all: return "clock"
        case .today: return "sun.max.fill"
        case .yesterday: return "moon.fill"
        case .last7Days: return "calendar"
        case .month: return "calendar.badge.clock"
        case .last30Days: return "calendar.badge.clock"
        case .thisYear: return "calendar.circle.fill"
        case .custom: return "calendar.badge.plus"
        }
    }
}

enum SearchHasFilter: String, CaseIterable, Identifiable {
    case all
    case file
    case image
    case video
    case audio
    case pdf
    case link
    case location
    case note

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Anything"
        case .file: return "File"
        case .image: return "Image"
        case .video: return "Video"
        case .audio: return "Audio"
        case .pdf: return "PDF"
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
        case .video: return "play.rectangle.fill"
        case .audio: return "waveform"
        case .pdf: return "doc.richtext.fill"
        case .link: return "link"
        case .location: return "mappin.and.ellipse"
        case .note: return "text.alignleft"
        }
    }
}

enum SearchDocumentSubtype: String, CaseIterable, Identifiable {
    case all
    case pdf
    case word
    case spreadsheet
    case presentation
    case text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All docs"
        case .pdf: return "PDFs"
        case .word: return "Word"
        case .spreadsheet: return "Spreadsheets"
        case .presentation: return "Presentations"
        case .text: return "Text files"
        }
    }

    var symbolName: String {
        switch self {
        case .all: return "doc.on.doc.fill"
        case .pdf: return "doc.richtext.fill"
        case .word: return "doc.text.fill"
        case .spreadsheet: return "tablecells.fill"
        case .presentation: return "rectangle.on.rectangle.fill"
        case .text: return "text.alignleft"
        }
    }
}

struct SaviSearchSourceGroup: Identifiable, Equatable {
    let id: String
    let title: String
    let symbolName: String

    static let curated: [SaviSearchSourceGroup] = [
        .init(id: "youtube", title: "YouTube", symbolName: "play.rectangle.fill"),
        .init(id: "tiktok", title: "TikTok", symbolName: "music.note"),
        .init(id: "instagram", title: "Instagram", symbolName: "camera.fill"),
        .init(id: "x-twitter", title: "X / Twitter", symbolName: "bubble.left.fill"),
        .init(id: "reddit", title: "Reddit", symbolName: "bubble.left.and.bubble.right.fill"),
        .init(id: "pinterest", title: "Pinterest", symbolName: "pin.fill"),
        .init(id: "spotify-audio", title: "Spotify / Audio", symbolName: "waveform"),
        .init(id: "maps", title: "Maps", symbolName: "map.fill"),
        .init(id: "device-files", title: "Device / Files", symbolName: "folder.fill"),
        .init(id: "clipboard-paste", title: "Clipboard / Paste", symbolName: "clipboard.fill"),
        .init(id: "web", title: "Web", symbolName: "globe")
    ]

    static func group(for id: String) -> SaviSearchSourceGroup? {
        curated.first { $0.id == id }
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

enum SaviHomeLayoutMode: String, CaseIterable, Identifiable {
    case timeline
    case cards
    case featured

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timeline: return "Timeline"
        case .cards: return "Compact"
        case .featured: return "Digest"
        }
    }

    var symbolName: String {
        switch self {
        case .timeline: return "timeline.selection"
        case .cards: return "rectangle.stack.fill"
        case .featured: return "newspaper.fill"
        }
    }
}

enum SaviHomeFolderMode: String, CaseIterable, Identifiable {
    case fourGrid
    case strip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fourGrid: return "4 folders"
        case .strip: return "Scrolling row"
        }
    }

    var symbolName: String {
        switch self {
        case .fourGrid: return "square.grid.2x2.fill"
        case .strip: return "rectangle.grid.1x2.fill"
        }
    }
}

enum SaviHomeWidgetKind: String, CaseIterable, Identifiable, Codable {
    case latestSaves
    case folders
    case recentSaves
    case pinnedFolder
    case searchShortcuts
    case friendActivity

    var id: String { rawValue }

    static var allCases: [SaviHomeWidgetKind] {
        var cases: [SaviHomeWidgetKind] = [
            .latestSaves,
            .folders,
            .recentSaves,
            .pinnedFolder,
            .searchShortcuts
        ]
        if SaviReleaseGate.socialFeaturesEnabled {
            cases.append(.friendActivity)
        }
        return cases
    }

    var title: String {
        switch self {
        case .latestSaves: return "Just Saved"
        case .folders: return "Folders"
        case .recentSaves: return "Recent Saves"
        case .pinnedFolder: return "Pinned Folder"
        case .searchShortcuts: return "Search Shortcuts"
        case .friendActivity: return "Friend Activity"
        }
    }

    var symbolName: String {
        switch self {
        case .latestSaves: return "sparkles.rectangle.stack.fill"
        case .folders: return "folder.fill"
        case .recentSaves: return "clock.fill"
        case .pinnedFolder: return "pin.fill"
        case .searchShortcuts: return "magnifyingglass.circle.fill"
        case .friendActivity: return "person.2.fill"
        }
    }

    var defaultSize: SaviHomeWidgetSize {
        switch self {
        case .latestSaves: return .compact
        case .folders: return .medium
        case .recentSaves: return .large
        case .pinnedFolder: return .medium
        case .searchShortcuts: return .compact
        case .friendActivity: return .compact
        }
    }

    var allowsMultiple: Bool {
        self == .pinnedFolder
    }
}

enum SaviHomeWidgetSize: String, CaseIterable, Identifiable, Codable {
    case compact
    case medium
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: return "Compact"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}

struct SaviHomeWidgetConfig: Codable, Identifiable, Equatable {
    static let currentVersion = 1

    var id: String
    var kind: String
    var size: String
    var isHidden: Bool
    var folderId: String?
    var title: String?

    var widgetKind: SaviHomeWidgetKind {
        SaviHomeWidgetKind(rawValue: kind) ?? .recentSaves
    }

    var widgetSize: SaviHomeWidgetSize {
        SaviHomeWidgetSize(rawValue: size) ?? widgetKind.defaultSize
    }

    init(
        id: String = UUID().uuidString,
        kind: SaviHomeWidgetKind,
        size: SaviHomeWidgetSize? = nil,
        isHidden: Bool = false,
        folderId: String? = nil,
        title: String? = nil
    ) {
        self.id = id
        self.kind = kind.rawValue
        self.size = (size ?? kind.defaultSize).rawValue
        self.isHidden = isHidden
        self.folderId = folderId
        self.title = title
    }

    static func defaultWidgets(showLatest: Bool = false) -> [SaviHomeWidgetConfig] {
        [
            SaviHomeWidgetConfig(id: "home-widget-folders", kind: .folders, size: .medium),
            SaviHomeWidgetConfig(id: "home-widget-latest", kind: .latestSaves, size: .compact, isHidden: !showLatest),
            SaviHomeWidgetConfig(id: "home-widget-recent", kind: .recentSaves, size: .large)
        ]
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
        case .folders: return "Folders"
        case .profile: return "Profile"
        }
    }

    var title: String {
        switch self {
        case .home: return "Your SAVI library"
        case .add: return "Save something new"
        case .share: return "Share into SAVI"
        case .search: return "Find anything fast"
        case .explore: return "Rediscover saved things"
        case .folders: return "Folders keep it organized"
        case .profile: return "Settings, privacy, backup"
        }
    }

    var message: String {
        switch self {
        case .home:
            return "Home shows your recent Folders and newest saves so you can jump back into anything you kept."
        case .add:
            return "Tap the plus to paste a link, write a note, import a file, or bring in something from the clipboard."
        case .share:
            return "From Safari, YouTube, Photos, Files, or almost any app, tap the iOS Share button and choose SAVI. It saves immediately, then fills in details."
        case .search:
            return "Search titles, notes, Folders, tags, sources, file names, PDFs, videos, screenshots, and places."
        case .explore:
            return SaviReleaseGate.socialFeaturesEnabled
                ? "Explore is a fresh mix of your links, places, videos, and friends' saves."
                : "Explore is a fresh mix of your links, places, videos, and favorite finds."
        case .folders:
            return "Folders are your main categories. Drag them into the order you like; that order also appears when you save from the share sheet."
        case .profile:
            return SaviReleaseGate.socialFeaturesEnabled
                ? "Manage appearance, backups, privacy, social features, folder learning, and this quick tour."
                : "Manage appearance, backups, privacy, folder learning, and this quick tour."
        }
    }

    var targetHint: String {
        switch self {
        case .home: return "Start with Recent Folders and your newest saves."
        case .add: return "Look for the chartreuse + in the bottom bar."
        case .share: return "Look for the iOS Share icon, then pick SAVI."
        case .search: return "Use the search bar, type rail, and Refine button."
        case .explore: return "Tap Explore when you want SAVI to surprise you."
        case .folders: return "Long-press a card or use reorder to arrange Folders."
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
        .init(id: "audio", title: "Audio", symbolName: "waveform"),
        .init(id: "screenshot", title: "Screenshots", symbolName: "iphone.gen3"),
        .init(id: "docs", title: "Docs", symbolName: "doc.on.doc.fill"),
        .init(id: "pdf", title: "PDFs", symbolName: "doc.richtext.fill"),
        .init(id: "document", title: "Documents", symbolName: "doc.fill"),
        .init(id: "note", title: "Notes", symbolName: "text.alignleft"),
        .init(id: "place", title: "Places", symbolName: "mappin.and.ellipse")
    ]

    static let visibleRail: [SaviSearchKind] = [
        .init(id: "all", title: "All", symbolName: "tray.full.fill"),
        .init(id: "link", title: "Links", symbolName: "link"),
        .init(id: "docs", title: "Docs", symbolName: "doc.on.doc.fill"),
        .init(id: "note", title: "Notes", symbolName: "text.alignleft"),
        .init(id: "video", title: "Videos", symbolName: "play.rectangle.fill"),
        .init(id: "place", title: "Places", symbolName: "mappin.and.ellipse"),
        .init(id: "image", title: "Images", symbolName: "photo.fill")
    ]

    static let refinePrimary: [SaviSearchKind] = [
        .init(id: "all", title: "All", symbolName: "tray.full.fill"),
        .init(id: "link", title: "Links", symbolName: "link"),
        .init(id: "docs", title: "Docs", symbolName: "doc.on.doc.fill"),
        .init(id: "note", title: "Notes", symbolName: "text.alignleft"),
        .init(id: "video", title: "Videos", symbolName: "play.rectangle.fill"),
        .init(id: "image", title: "Images", symbolName: "photo.fill"),
        .init(id: "place", title: "Places", symbolName: "mappin.and.ellipse"),
        .init(id: "audio", title: "Audio", symbolName: "waveform")
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

    static var allCases: [ExploreScope] {
        SaviReleaseGate.socialFeaturesEnabled ? [.all, .mine, .friends] : [.all, .mine]
    }

    static func visibleScope(for rawValue: String) -> ExploreScope {
        let scope = ExploreScope(rawValue: rawValue) ?? .all
        if scope == .friends, !SaviReleaseGate.socialFeaturesEnabled {
            return .mine
        }
        return scope
    }

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

struct SaviExploreSnapshot {
    let items: [SaviItem]
    let statusText: String
    let seenCount: Int
}

enum SaviMetadataPolicy: String, Codable, Equatable {
    case preserveSeed
    case liveMetadata
}

struct SaviSearchRefineKindOption: Identifiable, Equatable {
    let kind: SaviSearchKind
    let count: Int

    var id: String { kind.id }
}

struct SaviSearchRefineDocumentOption: Identifiable, Equatable {
    let subtype: SearchDocumentSubtype
    let count: Int

    var id: String { subtype.id }
}

struct SaviSearchRefineFolderOption: Identifiable, Equatable {
    let id: String
    let folder: SaviFolder?
    let title: String
    let systemImage: String
    let count: Int?
    let locked: Bool

    static func all(count: Int) -> SaviSearchRefineFolderOption {
        SaviSearchRefineFolderOption(
            id: "f-all",
            folder: nil,
            title: "All Folders",
            systemImage: "square.grid.2x2.fill",
            count: count,
            locked: false
        )
    }
}

struct SaviSearchRefineSourceGroupOption: Identifiable, Equatable {
    let group: SaviSearchSourceGroup
    let count: Int

    var id: String { group.id }
}

struct SaviSearchRefineRawSourceOption: Identifiable, Equatable {
    let key: String
    let label: String
    let count: Int

    var id: String { key }
}

struct SaviSearchRefineTagOption: Identifiable, Equatable {
    let key: String
    let label: String
    let count: Int

    var id: String { key }
}

struct SaviSearchRefineOptionsSnapshot: Equatable {
    var kindOptions: [SaviSearchRefineKindOption] = []
    var documentOptions: [SaviSearchRefineDocumentOption] = []
    var folderOptions: [SaviSearchRefineFolderOption] = []
    var sourceGroupOptions: [SaviSearchRefineSourceGroupOption] = []
    var otherSourceOptions: [SaviSearchRefineRawSourceOption] = []
    var tagOptions: [SaviSearchRefineTagOption] = []
    var includesTags = false

    static let empty = SaviSearchRefineOptionsSnapshot()

    func kindCount(for kindId: String) -> Int? {
        kindOptions.first { $0.kind.id == kindId }?.count
    }

    func filteredTags(matching searchText: String, defaultLimit: Int = 24) -> [SaviSearchRefineTagOption] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return Array(tagOptions.prefix(defaultLimit)) }
        let normalized = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        return tagOptions.filter { tag in
            tag.key.contains(normalized) || tag.label.lowercased().contains(normalized)
        }
    }
}

private struct SaviFilterCacheKey: Hashable {
    let tab: SaviTab?
    let query: String
    let folderFilter: String
    let typeFilter: String
    let sourceFilter: String
    let tagFilter: String
    let dateFilter: String
    let customDateStart: TimeInterval
    let customDateEnd: TimeInterval
    let documentSubtypeFilter: String
    let hasFilter: String
    let itemsRevision: Int
    let foldersRevision: Int
    let unlockedFolderIds: [String]
}

private struct SaviExploreCacheKey: Hashable {
    let seed: Int
    let scope: ExploreScope
    let itemsRevision: Int
    let foldersRevision: Int
    let friendLinksRevision: Int
    let unlockedFolderIds: [String]
    let seenItemIds: [String]
}

private struct SaviSearchRefineSnapshotKey: Hashable {
    let includeTags: Bool
    let tagLimit: Int
    let itemsRevision: Int
    let foldersRevision: Int
    let unlockedFolderIds: [String]
    let query: String
    let folderFilter: String
    let typeFilter: String
    let documentSubtypeFilter: String
    let sourceFilter: String
    let dateFilter: String
    let customDateStart: TimeInterval
    let customDateEnd: TimeInterval
    let hasFilter: String
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
    var usesImageBackground: Bool

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
        case usesImageBackground = "uses_image_background"
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
        isPublic: Bool = false,
        usesImageBackground: Bool = false
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
        self.usesImageBackground = image?.nilIfBlank != nil && usesImageBackground
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Folder"
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? "#C4B5FD"
        image = try container.decodeIfPresent(String.self, forKey: .image)
        system = try container.decodeIfPresent(Bool.self, forKey: .system) ?? false
        symbolName = try container.decodeIfPresent(String.self, forKey: .symbolName) ?? SaviText.folderSymbolName(id: id, name: name, system: system)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? SaviSeeds.defaultOrder(for: id)
        locked = try container.decodeIfPresent(Bool.self, forKey: .locked) ?? (id == "f-private-vault")
        isPublic = locked || id == "f-private-vault" ? false : (try container.decodeIfPresent(Bool.self, forKey: .isPublic) ?? false)
        let decodedUsesImageBackground = try container.decodeIfPresent(Bool.self, forKey: .usesImageBackground) ?? false
        usesImageBackground = image?.nilIfBlank != nil && decodedUsesImageBackground
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
    var metadataPolicy: SaviMetadataPolicy?

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
        case metadataPolicy
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
        thumbnailLastAttemptAt: Double? = nil,
        metadataPolicy: SaviMetadataPolicy? = nil
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
        self.metadataPolicy = metadataPolicy
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
        metadataPolicy = try container.decodeIfPresent(SaviMetadataPolicy.self, forKey: .metadataPolicy)
    }
}

struct SaviPrefs: Codable, Equatable {
    static let currentHomePresentationVersion = 3

    var viewMode: String = "list"
    var folderViewMode: String = "grid"
    var homeLayoutMode: String = SaviHomeLayoutMode.timeline.rawValue
    var homeFolderMode: String = SaviHomeFolderMode.fourGrid.rawValue
    var homeShowsFeaturedSave: Bool = false
    var homePresentationVersion: Int = Self.currentHomePresentationVersion
    var homeWidgets: [SaviHomeWidgetConfig] = SaviHomeWidgetConfig.defaultWidgets()
    var homeWidgetVersion: Int = SaviHomeWidgetConfig.currentVersion
    var folderLayoutVersion: Int = 0
    var coachMarksVersion: Int = 0
    var themeMode: String = "system"
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
    var blockedFriendUsernames: [String] = []
    var publishedPublicLinkIds: [String] = []
    var sampleFriendSeeded: Bool = false
    var appleUserIdentifier: String?
    var appleEmail: String?
    var appleFullName: String?
    var appleAuthorizedAt: Double?
    var shareExtensionSaveCount: Int = 0
    var firstShareExtensionSaveAt: Double?
    var lastShareExtensionSaveAt: Double?
    var shareSetupFirstEligibleAt: Double?
    var shareSetupReminderCount: Int = 0
    var shareSetupLastReminderAt: Double?
    var shareSetupSnoozedUntil: Double?
    var shareSetupDontRemindAgain: Bool = false

    enum CodingKeys: String, CodingKey {
        case viewMode
        case folderViewMode
        case homeLayoutMode
        case homeFolderMode
        case homeShowsFeaturedSave
        case homePresentationVersion
        case homeWidgets
        case homeWidgetVersion
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
        case blockedFriendUsernames
        case publishedPublicLinkIds
        case sampleFriendSeeded
        case appleUserIdentifier
        case appleEmail
        case appleFullName
        case appleAuthorizedAt
        case shareExtensionSaveCount
        case firstShareExtensionSaveAt
        case lastShareExtensionSaveAt
        case shareSetupFirstEligibleAt
        case shareSetupReminderCount
        case shareSetupLastReminderAt
        case shareSetupSnoozedUntil
        case shareSetupDontRemindAgain
    }

    init() {}

    static func currentExploreDay() -> Int {
        Int(Date().timeIntervalSince1970 / 86_400)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        viewMode = try container.decodeIfPresent(String.self, forKey: .viewMode) ?? "list"
        folderViewMode = try container.decodeIfPresent(String.self, forKey: .folderViewMode) ?? "grid"
        homeLayoutMode = try container.decodeIfPresent(String.self, forKey: .homeLayoutMode) ?? SaviHomeLayoutMode.timeline.rawValue
        homeFolderMode = try container.decodeIfPresent(String.self, forKey: .homeFolderMode) ?? SaviHomeFolderMode.fourGrid.rawValue
        homeShowsFeaturedSave = try container.decodeIfPresent(Bool.self, forKey: .homeShowsFeaturedSave) ?? false
        homePresentationVersion = try container.decodeIfPresent(Int.self, forKey: .homePresentationVersion) ?? 0
        homeWidgets = try container.decodeIfPresent([SaviHomeWidgetConfig].self, forKey: .homeWidgets) ?? SaviHomeWidgetConfig.defaultWidgets(showLatest: homeShowsFeaturedSave)
        homeWidgetVersion = try container.decodeIfPresent(Int.self, forKey: .homeWidgetVersion) ?? 0
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
        blockedFriendUsernames = try container.decodeIfPresent([String].self, forKey: .blockedFriendUsernames) ?? []
        publishedPublicLinkIds = try container.decodeIfPresent([String].self, forKey: .publishedPublicLinkIds) ?? []
        sampleFriendSeeded = try container.decodeIfPresent(Bool.self, forKey: .sampleFriendSeeded) ?? false
        appleUserIdentifier = try container.decodeIfPresent(String.self, forKey: .appleUserIdentifier)
        appleEmail = try container.decodeIfPresent(String.self, forKey: .appleEmail)
        appleFullName = try container.decodeIfPresent(String.self, forKey: .appleFullName)
        appleAuthorizedAt = try container.decodeIfPresent(Double.self, forKey: .appleAuthorizedAt)
        shareExtensionSaveCount = try container.decodeIfPresent(Int.self, forKey: .shareExtensionSaveCount) ?? 0
        firstShareExtensionSaveAt = try container.decodeIfPresent(Double.self, forKey: .firstShareExtensionSaveAt)
        lastShareExtensionSaveAt = try container.decodeIfPresent(Double.self, forKey: .lastShareExtensionSaveAt)
        shareSetupFirstEligibleAt = try container.decodeIfPresent(Double.self, forKey: .shareSetupFirstEligibleAt)
        shareSetupReminderCount = try container.decodeIfPresent(Int.self, forKey: .shareSetupReminderCount) ?? 0
        shareSetupLastReminderAt = try container.decodeIfPresent(Double.self, forKey: .shareSetupLastReminderAt)
        shareSetupSnoozedUntil = try container.decodeIfPresent(Double.self, forKey: .shareSetupSnoozedUntil)
        shareSetupDontRemindAgain = try container.decodeIfPresent(Bool.self, forKey: .shareSetupDontRemindAgain) ?? false
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

enum SaviSafety {
    static let moderationEmail = "safety@savi.app"

    static func containsObjectionableContent(_ text: String) -> Bool {
        let lower = text.lowercased()
        let terms = [
            "csam", "child sexual abuse", "sexual abuse material",
            "terrorist", "terrorism", "nazi", "white supremacist",
            "kill yourself", "self harm", "suicide method",
            "dox", "doxx", "revenge porn", "nonconsensual",
            "racial slur", "hate speech"
        ]
        return terms.contains { lower.contains($0) }
    }

    static func publicThumbnail(_ thumbnail: String?) -> String? {
        guard let thumbnail = thumbnail?.nilIfBlank,
              thumbnail.lowercased().hasPrefix("http")
        else { return nil }
        return String(thumbnail.prefix(1_000))
    }

    static func publicTags(_ tags: [String], limit: Int = 8) -> [String] {
        let blocked = ["private", "password", "credential", "passport", "bank", "tax", "medical"]
        let cleaned = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty && $0.count <= 32 }
            .filter { tag in
                !blocked.contains { tag.contains($0) }
            }
        return Array(SaviText.dedupeTags(cleaned).prefix(limit))
    }

    static func clipped(_ value: String, maxLength: Int) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > maxLength else { return trimmed }
        return String(trimmed.prefix(maxLength))
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
    var prefs: SaviPrefs?
    var publicProfile: SaviPublicProfile?
    var friends: [SaviFriend]?
    var friendLinks: [SaviSharedLink]?
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

struct SaviCloudBackupSnapshot {
    var data: Data
    var updatedAt: Double
    var size: Int
}

final class SaviCloudKitService {
    static let containerIdentifier = "iCloud.com.savi.app"

    private static var isPersonalDebugBuild: Bool {
        Bundle.main.bundleIdentifier?.contains(".personaldebug") == true
    }

    private lazy var container: CKContainer? = {
        guard !Self.isPersonalDebugBuild else { return nil }
        return CKContainer(identifier: Self.containerIdentifier)
    }()

    func accountStatusText() async -> String {
        guard let container else { return "iCloud unavailable" }

        return await withCheckedContinuation { continuation in
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

    func savePrivateBackup(data: Data) async throws -> Double {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("savi-icloud-backup-\(UUID().uuidString).json")
        try data.write(to: tempURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let updatedAt = Date().timeIntervalSince1970 * 1000
        let recordID = CKRecord.ID(recordName: "library")
        let record = try await fetchPrivateRecord(id: recordID) ?? CKRecord(recordType: "SaviPrivateBackup", recordID: recordID)
        record["backupFile"] = CKAsset(fileURL: tempURL)
        record["updatedAt"] = updatedAt as CKRecordValue
        record["size"] = NSNumber(value: data.count)
        _ = try await savePrivateRecord(record)
        return updatedAt
    }

    func fetchPrivateBackup() async throws -> SaviCloudBackupSnapshot? {
        guard let record = try await fetchPrivateRecord(id: CKRecord.ID(recordName: "library")) else { return nil }
        guard let asset = record["backupFile"] as? CKAsset,
              let fileURL = asset.fileURL
        else { return nil }
        let data = try Data(contentsOf: fileURL)
        let updatedAt = record["updatedAt"] as? Double ?? 0
        let size = (record["size"] as? NSNumber)?.intValue ?? data.count
        return SaviCloudBackupSnapshot(data: data, updatedAt: updatedAt, size: size)
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

    func deleteProfile(username: String) async throws {
        let username = SaviSocialText.normalizedUsername(username)
        guard !username.isEmpty else { return }
        try await deleteRecord(id: CKRecord.ID(recordName: "profile-\(username)"))
    }

    func deleteSharedLinks(ids: [String]) async throws {
        for id in Set(ids.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }).filter({ !$0.isEmpty }) {
            try await deleteRecord(id: CKRecord.ID(recordName: "link-\(id)"))
        }
    }

    func deleteSharedLinks(ownerUsername: String) async throws {
        let username = SaviSocialText.normalizedUsername(ownerUsername)
        guard !username.isEmpty else { return }
        let predicate = NSPredicate(format: "ownerUsername == %@", username)
        let query = CKQuery(recordType: "SaviSharedLink", predicate: predicate)
        let records = try await performQuery(query, limit: 200)
        for record in records {
            try await deleteRecord(id: record.recordID)
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
        let database = try publicDatabase()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord?, Error>) in
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
        let database = try publicDatabase()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord, Error>) in
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

    private func fetchPrivateRecord(id: CKRecord.ID) async throws -> CKRecord? {
        let privateDatabase = try privateDatabase()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord?, Error>) in
            privateDatabase.fetch(withRecordID: id) { record, error in
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

    private func savePrivateRecord(_ record: CKRecord) async throws -> CKRecord {
        let privateDatabase = try privateDatabase()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord, Error>) in
            privateDatabase.save(record) { savedRecord, error in
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
        let database = try publicDatabase()
        return try await withCheckedThrowingContinuation { continuation in
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
            database.add(operation)
        }
    }

    private func deleteRecord(id: CKRecord.ID) async throws {
        let database = try publicDatabase()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            database.delete(withRecordID: id) { _, error in
                if let ckError = error as? CKError, ckError.code == .unknownItem {
                    continuation.resume(returning: ())
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func publicDatabase() throws -> CKDatabase {
        guard let container else { throw CKError(.notAuthenticated) }
        return container.publicCloudDatabase
    }

    private func privateDatabase() throws -> CKDatabase {
        guard let container else { throw CKError(.notAuthenticated) }
        return container.privateCloudDatabase
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
    @Published var folders: [SaviFolder] {
        didSet {
            rebuildFolderLookup()
            foldersRevision &+= 1
            invalidateItemDerivedCaches()
        }
    }
    @Published var items: [SaviItem] {
        didSet {
            itemsRevision &+= 1
            invalidateItemDerivedCaches()
        }
    }
    @Published var assets: [SaviAsset]
    @Published var prefs: SaviPrefs
    @Published var selectedTab: SaviTab = .home
    @Published var previousTab: SaviTab = .home
    @Published var homeScrollToTopRequest = 0
    @Published var searchFocusRequest = 0
    @Published var activeCoachStep: SaviCoachStep?
    @Published var exploreSeed = SaviPrefs.currentExploreDay()
    @Published var exploreScope: ExploreScope = .all
    @Published var query = ""
    @Published var folderFilter = "f-all"
    @Published var typeFilter = "all" {
        didSet {
            if typeFilter != "docs" {
                documentSubtypeFilter = SearchDocumentSubtype.all.rawValue
            }
        }
    }
    @Published var sourceFilter = "all"
    @Published var tagFilter = "all"
    @Published var dateFilter = SearchDateFilter.all.rawValue
    @Published var customSearchStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var customSearchEndDate = Date()
    @Published var documentSubtypeFilter = SearchDocumentSubtype.all.rawValue
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
    @Published var archiveDocument: SaviArchiveDocument?
    @Published var backupExportFilename = "savi-backup-\(SaviText.backupStamp()).json"
    @Published var archiveExportFilename = "savi-full-archive-\(SaviText.backupStamp()).zip"
    @Published var isExportingBackup = false
    @Published var isExportingArchive = false
    @Published var pendingBackupPreview: SaviArchivePreview?
    @Published var isCloudBackupRunning = false
    @Published var cloudBackupMessage: String?
    @Published var isShareSetupGuidePresented = false
    @Published var isShareSetupReminderPresented = false
    @Published var publicProfile: SaviPublicProfile
    @Published var friends: [SaviFriend]
    @Published var friendLinks: [SaviSharedLink] {
        didSet {
            friendLinksRevision &+= 1
            invalidateExploreSnapshotCache()
        }
    }
    @Published var cloudKitStatus = "Checking iCloud"
    @Published var appleAccountStatus = "Not linked"
    @Published var socialSyncMessage: String?
    @Published var isSocialSyncing = false
    @Published var folderAuditReport: SAVIFolderAuditReport?
    @Published var appleIntelligenceStatus = "Checking"
    @Published private(set) var isNetworkReachable = true
    @Published private(set) var folderDecisionHistory: [SAVIFolderDecisionRecord] = []
    @Published private var unlockedProtectedKeeperIds = Set<String>() {
        didSet {
            invalidateVisibilityDerivedCaches()
        }
    }

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
    private var foldersById: [String: SaviFolder] = [:]
    private var searchHaystackCache: [String: String] = [:]
    private var filteredItemsCache: [SaviFilterCacheKey: [SaviItem]] = [:]
    private var searchRefineOptionsCache: [SaviSearchRefineSnapshotKey: SaviSearchRefineOptionsSnapshot] = [:]
    private var exploreSnapshotCache: [SaviExploreCacheKey: SaviExploreSnapshot] = [:]
    private var itemsRevision = 0
    private var foldersRevision = 0
    private var friendLinksRevision = 0
    private var lastSharedFolderSignature = ""
    private var lastFolderLearningSignature = ""
    private var isForegroundRefreshRunning = false
    private var lastForegroundRefreshAt: Date?
    private var metadataEnrichmentInFlightIds = Set<String>()
    private var pendingBackupImportPayload: SaviArchiveImportPayload?
    private var deferredPresentation: SaviDeferredPresentation?
    private var lastSlowFilterLogAt = Date.distantPast
    private var searchRefineOpenRequestedAt: Date?
    private static let thumbnailRetryDelays: [TimeInterval] = [0, 30, 60, 180, 600, 1_800, 3_600]
    private static let thumbnailLogoFallbackAttempts = 3
    private static let thumbnailLogoFallbackGrace: TimeInterval = 180
    private static let maxMetadataEnrichmentTasks = 4
    private static let foregroundRefreshCooldown: TimeInterval = 6
    private static let slowFilterLogThreshold: TimeInterval = 0.05
    private static let slowRefineSnapshotLogThreshold: TimeInterval = 0.02
    private static let shareSetupInitialReminderDelay: TimeInterval = 86_400
    private static let shareSetupSecondReminderDelay: TimeInterval = 3 * 86_400
    private static let shareSetupLaterReminderDelay: TimeInterval = 7 * 86_400
    private static let sampleFriendTargetLinkCount = 24
    private static let currentLegacySeedVersion = 13
    private static let currentFolderRepairVersion = 2
    private static let currentSearchTagRepairVersion = 1
    private static let currentFolderLayoutVersion = 3
    private static let currentCoachMarksVersion = 1
    private static let currentHomePresentationVersion = SaviPrefs.currentHomePresentationVersion

    var preferredColorScheme: ColorScheme? {
        switch prefs.themeMode {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }

    var shouldRunLegacyMigration: Bool {
        !prefs.migrationComplete || shouldRefreshLegacySeeds
    }

    private var shouldRefreshLegacySeeds: Bool {
        guard SaviReleaseGate.demoLibraryEnabled else { return false }
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
        var shouldPersistPreferenceNormalization = false
        let shouldUpgradeFolderLayout = loadedPrefs.folderLayoutVersion < Self.currentFolderLayoutVersion
        if shouldUpgradeFolderLayout {
            loadedPrefs.folderViewMode = SaviFolderViewMode.grid.rawValue
            loadedPrefs.folderLayoutVersion = Self.currentFolderLayoutVersion
        }
        if Self.normalizeHomePresentationPreferences(&loadedPrefs) {
            shouldPersistPreferenceNormalization = true
        }
        if Self.syncPairedFolderPreferences(&loadedPrefs) {
            shouldPersistPreferenceNormalization = true
        }
        let visibleExploreScope = ExploreScope.visibleScope(for: loadedPrefs.exploreScope)
        if visibleExploreScope.rawValue != loadedPrefs.exploreScope {
            loadedPrefs.exploreScope = visibleExploreScope.rawValue
            shouldPersistPreferenceNormalization = true
        }
        let today = SaviPrefs.currentExploreDay()
        let shouldPersistExploreSeedReset = loadedPrefs.exploreSeedDay != today
        if loadedPrefs.exploreSeedDay != today {
            loadedPrefs.exploreSeedDay = today
            loadedPrefs.exploreSeed = today
        }
        let sharedShareSetupState = PendingShareStore.shared.loadShareSetupState()
        if Self.merge(sharedShareSetupState, into: &loadedPrefs) {
            shouldPersistPreferenceNormalization = true
        }
        if loadedPrefs.onboarded,
           loadedPrefs.shareExtensionSaveCount == 0,
           loadedPrefs.shareSetupFirstEligibleAt == nil {
            loadedPrefs.shareSetupFirstEligibleAt = Date().timeIntervalSince1970
            shouldPersistPreferenceNormalization = true
        }
        let seededFolders = SaviSeeds.withSeedDefaults(loaded?.folders ?? seedFolders)
        var initialFolders = shouldUpgradeFolderLayout ? SaviSeeds.refreshingDefaultFolderPresentation(seededFolders) : seededFolders
        let storedItems = loaded?.items
        let storedPersonalItems = (storedItems ?? []).filter { $0.demo != true }
        let shouldRestoreSuppressedEmptySampleLibrary = SaviReleaseGate.demoLibraryEnabled &&
            loadedPrefs.demoSuppressed &&
            storedPersonalItems.isEmpty &&
            (storedItems?.isEmpty ?? true) &&
            (loadedPrefs.legacySeedVersion ?? 0) < Self.currentLegacySeedVersion
        if shouldRestoreSuppressedEmptySampleLibrary {
            loadedPrefs.demoSuppressed = false
            shouldPersistPreferenceNormalization = true
        }
        let shouldSeedSampleLibrary = SaviReleaseGate.demoLibraryEnabled &&
            !loadedPrefs.demoSuppressed &&
            (storedItems == nil || storedItems?.isEmpty == true)
        let shouldRefreshSampleLibrary = SaviReleaseGate.demoLibraryEnabled &&
            !loadedPrefs.demoSuppressed &&
            (loadedPrefs.legacySeedVersion ?? 0) < Self.currentLegacySeedVersion &&
            (storedItems ?? []).contains { $0.demo == true }
        let initialItems = (shouldSeedSampleLibrary || shouldRefreshSampleLibrary)
            ? SaviSeeds.items + storedPersonalItems
            : (storedItems ?? [])
        if shouldSeedSampleLibrary || shouldRefreshSampleLibrary {
            loadedPrefs.legacySeedVersion = Self.currentLegacySeedVersion
            shouldPersistPreferenceNormalization = true
            initialFolders = SaviSeeds.refreshingDefaultFolderPresentation(SaviSeeds.withSeedDefaults(initialFolders))
        }
        let releaseSafeItems = SaviReleaseGate.demoLibraryEnabled ? initialItems : initialItems.filter { $0.demo != true }
        if releaseSafeItems.count != initialItems.count {
            shouldPersistPreferenceNormalization = true
        }
        self.folders = initialFolders
        self.items = releaseSafeItems
        self.assets = loaded?.assets ?? []
        self.prefs = loadedPrefs
        var loadedPublicProfile = loaded?.publicProfile ?? SaviPublicProfile.makeDefault()
        if !SaviReleaseGate.socialFeaturesEnabled, loadedPublicProfile.isLinkSharingEnabled {
            loadedPublicProfile.isLinkSharingEnabled = false
            loadedPublicProfile.updatedAt = Date().timeIntervalSince1970 * 1000
            shouldPersistPreferenceNormalization = true
        }
        self.publicProfile = loadedPublicProfile
        self.friends = loaded?.friends ?? []
        self.friendLinks = loaded?.friendLinks ?? []
        self.exploreSeed = loadedPrefs.exploreSeed
        self.exploreScope = visibleExploreScope
        self.folderLearningSignals = shareStore.loadFolderLearning()
        self.folderDecisionHistory = shareStore.loadFolderDecisions()
        rebuildFolderLookup()
        syncFoldersToShareExtension()
#if DEBUG
        applyDebugLaunchOverrides()
#endif
        applyWindowThemeOverride()
        startNetworkMonitoring()
        runFolderAudit(showToast: false)
        if shouldPersistExploreSeedReset || shouldUpgradeFolderLayout || shouldPersistPreferenceNormalization {
            persist()
        }
    }

    deinit {
        networkMonitor.cancel()
    }

    @discardableResult
    private static func normalizeHomePresentationPreferences(_ prefs: inout SaviPrefs) -> Bool {
        var changed = false
        if prefs.homePresentationVersion < 1 {
            changed = true
        }

        if prefs.homeWidgets.isEmpty {
            prefs.homeWidgets = SaviHomeWidgetConfig.defaultWidgets(showLatest: prefs.homeShowsFeaturedSave)
            changed = true
        } else {
            let sanitized = sanitizedHomeWidgets(prefs.homeWidgets)
            if sanitized != prefs.homeWidgets {
                prefs.homeWidgets = sanitized
                changed = true
            }
        }

        if prefs.homePresentationVersion < 3,
           isStockHomeWidgetStack(prefs.homeWidgets) {
            prefs.homeShowsFeaturedSave = false
            prefs.homeWidgets = SaviHomeWidgetConfig.defaultWidgets(showLatest: false)
            changed = true
        }

        if prefs.homeWidgetVersion < SaviHomeWidgetConfig.currentVersion {
            prefs.homeWidgetVersion = SaviHomeWidgetConfig.currentVersion
            changed = true
        }

        guard prefs.homePresentationVersion < currentHomePresentationVersion || changed else { return false }
        prefs.homePresentationVersion = currentHomePresentationVersion
        return true
    }

    private static func isStockHomeWidgetStack(_ widgets: [SaviHomeWidgetConfig]) -> Bool {
        let expected: [(id: String, kind: SaviHomeWidgetKind, size: SaviHomeWidgetSize)] = [
            ("home-widget-folders", .folders, .medium),
            ("home-widget-latest", .latestSaves, .compact),
            ("home-widget-recent", .recentSaves, .large)
        ]
        guard widgets.count == expected.count else { return false }

        return zip(widgets, expected).allSatisfy { pair in
            let (widget, expected) = pair
            let hasCustomTitle = !(widget.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return widget.id == expected.id &&
                widget.widgetKind == expected.kind &&
                widget.widgetSize == expected.size &&
                widget.folderId == nil &&
                !hasCustomTitle
        }
    }

    private static func sanitizedHomeWidgets(_ widgets: [SaviHomeWidgetConfig]) -> [SaviHomeWidgetConfig] {
        var seenSingleKinds = Set<String>()
        var seenIds = Set<String>()

        return widgets.compactMap { widget in
            let kind = widget.widgetKind
            if kind == .friendActivity, !SaviReleaseGate.socialFeaturesEnabled {
                return nil
            }
            if !kind.allowsMultiple, seenSingleKinds.contains(kind.rawValue) {
                return nil
            }
            seenSingleKinds.insert(kind.rawValue)

            var sanitized = widget
            sanitized.kind = kind.rawValue
            sanitized.size = widget.widgetSize.rawValue
            if kind != .pinnedFolder {
                sanitized.folderId = nil
            }
            if sanitized.id.isEmpty || seenIds.contains(sanitized.id) {
                sanitized.id = UUID().uuidString
            }
            seenIds.insert(sanitized.id)
            return sanitized
        }
    }

    @discardableResult
    private static func syncPairedFolderPreferences(_ prefs: inout SaviPrefs) -> Bool {
        let originalFolderViewMode = prefs.folderViewMode
        let originalHomeFolderMode = prefs.homeFolderMode
        let folderViewMode = SaviFolderViewMode(rawValue: prefs.folderViewMode) ?? .grid
        let homeFolderMode = SaviHomeFolderMode(rawValue: prefs.homeFolderMode) ?? .fourGrid

        if folderViewMode == .list || homeFolderMode == .strip {
            prefs.folderViewMode = SaviFolderViewMode.list.rawValue
            prefs.homeFolderMode = SaviHomeFolderMode.strip.rawValue
        } else {
            prefs.folderViewMode = SaviFolderViewMode.grid.rawValue
            prefs.homeFolderMode = SaviHomeFolderMode.fourGrid.rawValue
        }

        return prefs.folderViewMode != originalFolderViewMode || prefs.homeFolderMode != originalHomeFolderMode
    }

    @discardableResult
    private static func merge(_ state: SAVIShareSetupState, into prefs: inout SaviPrefs) -> Bool {
        var changed = false
        if state.shareExtensionSaveCount > prefs.shareExtensionSaveCount {
            prefs.shareExtensionSaveCount = state.shareExtensionSaveCount
            changed = true
        }
        if let first = state.firstShareExtensionSaveAt,
           prefs.firstShareExtensionSaveAt == nil || first < (prefs.firstShareExtensionSaveAt ?? first) {
            prefs.firstShareExtensionSaveAt = first
            changed = true
        }
        if let last = state.lastShareExtensionSaveAt,
           prefs.lastShareExtensionSaveAt == nil || last > (prefs.lastShareExtensionSaveAt ?? last) {
            prefs.lastShareExtensionSaveAt = last
            changed = true
        }
        if prefs.shareExtensionSaveCount > 0 || prefs.firstShareExtensionSaveAt != nil {
            if prefs.shareSetupSnoozedUntil != nil {
                prefs.shareSetupSnoozedUntil = nil
                changed = true
            }
        }
        return changed
    }

#if DEBUG
    private func applyDebugLaunchOverrides() {
        let environment = ProcessInfo.processInfo.environment

        if environment["SAVI_QA_BYPASS_ONBOARDING"] == "1" {
            prefs.onboarded = true
            prefs.migrationComplete = true
            prefs.legacySeedVersion = Self.currentLegacySeedVersion
            activeCoachStep = nil
        }

        if let launchTab = environment["SAVI_START_TAB"]?.lowercased() {
            switch launchTab {
            case "search":
                selectedTab = .search
                previousTab = .search
            case "explore":
                selectedTab = .explore
                previousTab = .explore
            case "folders":
                selectedTab = .folders
                previousTab = .folders
            case "profile":
                selectedTab = .profile
                previousTab = .profile
            default:
                break
            }
        }

        if let scope = environment["SAVI_EXPLORE_SCOPE"].flatMap(ExploreScope.init(rawValue:)) {
            exploreScope = scope
        }
    }
#endif

    private func rebuildFolderLookup() {
        foldersById = folders.reduce(into: [:]) { result, folder in
            result[folder.id] = folder
        }
    }

    private func invalidateItemDerivedCaches() {
        searchHaystackCache.removeAll(keepingCapacity: true)
        invalidateVisibilityDerivedCaches()
    }

    private func invalidateVisibilityDerivedCaches() {
        filteredItemsCache.removeAll(keepingCapacity: true)
        searchRefineOptionsCache.removeAll(keepingCapacity: true)
        invalidateExploreSnapshotCache()
    }

    private func invalidateExploreSnapshotCache() {
        exploreSnapshotCache.removeAll(keepingCapacity: true)
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
        let startedAt = Date()
        guard !didBootstrap else { return }
        didBootstrap = true
        mergeShareSetupStateFromAppGroup()
        await importPendingShares()
        evaluateShareSetupReminder()
        refreshFolderDecisionHistory()
        repairObviousGenericFolderAssignmentsIfNeeded()
        repairSearchTagsIfNeeded()
        await refreshStaleMetadata()
        await refreshAppleIntelligenceStatus()
        await refreshAppleAccountStatus()
        await refreshCloudKitStatus()
#if targetEnvironment(simulator)
        if SaviReleaseGate.seedsDemoSocialContent {
            let avaLinkCount = friendLinks.filter { SaviSocialText.normalizedUsername($0.ownerUsername) == "ava" }.count
            if !prefs.sampleFriendSeeded || avaLinkCount < Self.sampleFriendTargetLinkCount {
                loadSampleFriend(showToast: false)
            }
        }
#endif
        if SaviReleaseGate.socialFeaturesEnabled,
           publicProfile.isLinkSharingEnabled || !friends.isEmpty {
            await syncSocialLinks()
        }
        NSLog("[SAVI Native] bootstrap scheduled in %.3fs", Date().timeIntervalSince(startedAt))
    }

    func refreshForegroundWork() async {
        guard !isForegroundRefreshRunning else { return }
        let now = Date()
        if let lastForegroundRefreshAt,
           now.timeIntervalSince(lastForegroundRefreshAt) < Self.foregroundRefreshCooldown {
            return
        }
        lastForegroundRefreshAt = now
        isForegroundRefreshRunning = true
        defer { isForegroundRefreshRunning = false }

        let startedAt = Date()
        mergeShareSetupStateFromAppGroup()
        await importPendingShares()
        evaluateShareSetupReminder()
        await refreshStaleMetadata()
        NSLog("[SAVI Native] foreground refresh scheduled in %.3fs", Date().timeIntervalSince(startedAt))
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
        if prefs.shareSetupFirstEligibleAt == nil && prefs.shareExtensionSaveCount == 0 {
            prefs.shareSetupFirstEligibleAt = Date().timeIntervalSince1970
        }
        persist()
        startCoachTour()
    }

    var isShareExtensionSetupComplete: Bool {
        prefs.shareExtensionSaveCount > 0 || prefs.firstShareExtensionSaveAt != nil
    }

    var shareSetupStatusText: String {
        guard isShareExtensionSetupComplete else {
            return "Not used yet"
        }
        if let last = prefs.lastShareExtensionSaveAt {
            return "Last used \(SaviText.relativeSavedTime(last)) ago"
        }
        return "Ready"
    }

    func openShareSetupGuide() {
        isShareSetupReminderPresented = false
        isShareSetupGuidePresented = true
    }

    func snoozeShareSetupReminder() {
        isShareSetupReminderPresented = false
        prefs.shareSetupSnoozedUntil = Date().timeIntervalSince1970 + Self.nextShareSetupReminderDelay(afterShowingCount: prefs.shareSetupReminderCount)
        persist()
    }

    func disableShareSetupReminders() {
        isShareSetupReminderPresented = false
        prefs.shareSetupDontRemindAgain = true
        persist()
    }

    func evaluateShareSetupReminder() {
        guard prefs.onboarded,
              !isShareExtensionSetupComplete,
              !prefs.shareSetupDontRemindAgain,
              activeCoachStep == nil
        else {
            isShareSetupReminderPresented = false
            return
        }

        let now = Date().timeIntervalSince1970
        if prefs.shareSetupFirstEligibleAt == nil {
            prefs.shareSetupFirstEligibleAt = now
            persist()
            return
        }
        if let snoozedUntil = prefs.shareSetupSnoozedUntil,
           snoozedUntil > now {
            return
        }

        let base = prefs.shareSetupLastReminderAt ?? prefs.shareSetupFirstEligibleAt ?? now
        let delay = Self.nextShareSetupReminderDelay(afterShowingCount: prefs.shareSetupReminderCount)
        guard now - base >= delay else { return }

        guard !isShareSetupReminderPresented else { return }
        prefs.shareSetupReminderCount += 1
        prefs.shareSetupLastReminderAt = now
        prefs.shareSetupSnoozedUntil = nil
        isShareSetupReminderPresented = true
        persist()
    }

    private static func nextShareSetupReminderDelay(afterShowingCount count: Int) -> TimeInterval {
        switch count {
        case 0:
            return shareSetupInitialReminderDelay
        case 1:
            return shareSetupSecondReminderDelay
        default:
            return shareSetupLaterReminderDelay
        }
    }

    @discardableResult
    private func mergeShareSetupStateFromAppGroup(persistChanges: Bool = true) -> Bool {
        let state = shareStore.loadShareSetupState()
        let changed = Self.merge(state, into: &prefs)
        if changed {
            isShareSetupReminderPresented = false
            if persistChanges { persist() }
        }
        return changed
    }

    private func recordShareExtensionCompletion(folderId: String?) {
        shareStore.recordShareExtensionSave(folderId: folderId)
        mergeShareSetupStateFromAppGroup()
        isShareSetupReminderPresented = false
    }

    func setTheme(_ mode: String) {
        prefs.themeMode = mode
        applyWindowThemeOverride()
        persist()
    }

    private func applyWindowThemeOverride() {
        let style: UIUserInterfaceStyle
        switch prefs.themeMode {
        case "dark":
            style = .dark
        case "light":
            style = .light
        default:
            style = .unspecified
        }

        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { $0.overrideUserInterfaceStyle = style }
    }

    func setFolderViewMode(_ mode: SaviFolderViewMode) {
        prefs.folderViewMode = mode.rawValue
        prefs.homeFolderMode = mode == .grid
            ? SaviHomeFolderMode.fourGrid.rawValue
            : SaviHomeFolderMode.strip.rawValue
        persist()
    }

    func setHomeLayoutMode(_ mode: SaviHomeLayoutMode) {
        prefs.homeLayoutMode = mode.rawValue
        persist()
    }

    func setHomeFolderMode(_ mode: SaviHomeFolderMode) {
        prefs.homeFolderMode = mode.rawValue
        prefs.folderViewMode = mode == .fourGrid
            ? SaviFolderViewMode.grid.rawValue
            : SaviFolderViewMode.list.rawValue
        persist()
    }

    func setHomeShowsFeaturedSave(_ enabled: Bool) {
        prefs.homeShowsFeaturedSave = enabled
        var widgets = prefs.homeWidgets
        if let index = widgets.firstIndex(where: { $0.widgetKind == .latestSaves }) {
            widgets[index].isHidden = !enabled
        } else if enabled {
            widgets.insert(
                SaviHomeWidgetConfig(id: "home-widget-latest", kind: .latestSaves, size: .compact),
                at: min(1, widgets.count)
            )
        }
        prefs.homeWidgets = widgets
        persist()
    }

    var visibleHomeWidgets: [SaviHomeWidgetConfig] {
        prefs.homeWidgets.filter { widget in
            !widget.isHidden &&
                (SaviReleaseGate.socialFeaturesEnabled || widget.widgetKind != .friendActivity)
        }
    }

    func setHomeWidgets(_ widgets: [SaviHomeWidgetConfig]) {
        prefs.homeWidgets = Self.sanitizedHomeWidgets(widgets)
        prefs.homeWidgetVersion = SaviHomeWidgetConfig.currentVersion
        persist()
    }

    func resetHomeWidgets() {
        prefs.homeWidgets = SaviHomeWidgetConfig.defaultWidgets(showLatest: false)
        prefs.homeShowsFeaturedSave = false
        prefs.homeWidgetVersion = SaviHomeWidgetConfig.currentVersion
        persist()
    }

    func moveHomeWidget(from source: IndexSet, to destination: Int) {
        var widgets = prefs.homeWidgets
        widgets.move(fromOffsets: source, toOffset: destination)
        setHomeWidgets(widgets)
    }

    func addHomeWidget(kind: SaviHomeWidgetKind, size: SaviHomeWidgetSize? = nil, folderId: String? = nil, title: String? = nil) {
        guard SaviReleaseGate.socialFeaturesEnabled || kind != .friendActivity else {
            toast = "Social Beta is off for this TestFlight build."
            return
        }
        var widgets = prefs.homeWidgets
        if !kind.allowsMultiple, widgets.contains(where: { $0.widgetKind == kind }) {
            if let index = widgets.firstIndex(where: { $0.widgetKind == kind }) {
                widgets[index].isHidden = false
                widgets[index].size = (size ?? kind.defaultSize).rawValue
            }
        } else {
            widgets.append(
                SaviHomeWidgetConfig(
                    kind: kind,
                    size: size,
                    folderId: kind == .pinnedFolder ? folderId : nil,
                    title: title
                )
            )
        }
        prefs.homeWidgets = Self.sanitizedHomeWidgets(widgets)
        if kind == .latestSaves {
            prefs.homeShowsFeaturedSave = true
        }
        persist()
    }

    func deleteHomeWidget(_ widget: SaviHomeWidgetConfig) {
        prefs.homeWidgets.removeAll { $0.id == widget.id }
        if widget.widgetKind == .latestSaves {
            prefs.homeShowsFeaturedSave = false
        }
        persist()
    }

    func setHomeWidgetHidden(_ widget: SaviHomeWidgetConfig, hidden: Bool) {
        var widgets = prefs.homeWidgets
        guard let index = widgets.firstIndex(where: { $0.id == widget.id }) else { return }
        widgets[index].isHidden = hidden
        prefs.homeWidgets = Self.sanitizedHomeWidgets(widgets)
        if widgets[index].widgetKind == .latestSaves {
            prefs.homeShowsFeaturedSave = !hidden
        }
        persist()
    }

    func setHomeWidgetSize(_ widget: SaviHomeWidgetConfig, size: SaviHomeWidgetSize) {
        var widgets = prefs.homeWidgets
        guard let index = widgets.firstIndex(where: { $0.id == widget.id }) else { return }
        widgets[index].size = size.rawValue
        prefs.homeWidgets = Self.sanitizedHomeWidgets(widgets)
        persist()
    }

    func setHomeWidgetPinnedFolder(_ widget: SaviHomeWidgetConfig, folderId: String?) {
        var widgets = prefs.homeWidgets
        guard let index = widgets.firstIndex(where: { $0.id == widget.id }) else { return }
        widgets[index].folderId = folderId
        widgets[index].title = folderId.flatMap { folder(for: $0)?.name }
        prefs.homeWidgets = Self.sanitizedHomeWidgets(widgets)
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
        presentSafely(.sheet(.save))
    }

    func openFolderEditor(_ folder: SaviFolder?) {
        presentSafely(.sheet(.folderEditor(folder)))
    }

    func presentItem(_ item: SaviItem) {
        presentSafely(.item(item))
    }

    func editItem(_ item: SaviItem) {
        presentSafely(.editItem(item))
    }

    private var hasActivePresentation: Bool {
        presentedSheet != nil ||
        presentedItem != nil ||
        editingItem != nil ||
        quickLookAssetURL != nil ||
        webPreviewURL != nil ||
        isSearchRefinePresented ||
        activeSearchFacet != nil
    }

    private func clearActivePresentation() {
        presentedSheet = nil
        presentedItem = nil
        editingItem = nil
        quickLookAssetURL = nil
        webPreviewURL = nil
        isSearchRefinePresented = false
        activeSearchFacet = nil
    }

    private func presentSafely(_ presentation: SaviDeferredPresentation) {
        guard hasActivePresentation else {
            applyPresentation(presentation)
            return
        }

        deferredPresentation = presentation
        clearActivePresentation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) { [weak self] in
            self?.flushDeferredPresentation()
        }
    }

    private func flushDeferredPresentation() {
        guard let presentation = deferredPresentation else { return }
        deferredPresentation = nil
        guard !hasActivePresentation else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.flushDeferredPresentation()
            }
            return
        }
        applyPresentation(presentation)
    }

    private func applyPresentation(_ presentation: SaviDeferredPresentation) {
        switch presentation {
        case .sheet(let sheet):
            presentedSheet = sheet
        case .item(let item):
            presentedItem = item
        case .editItem(let item):
            editingItem = item
        case .quickLook(let url):
            quickLookAssetURL = url
        case .web(let url):
            webPreviewURL = url
        }
    }

    func setTab(_ tab: SaviTab) {
        if tab == .home {
            resetFilters()
        }
        previousTab = tab
        selectedTab = tab
    }

    func handleBottomTabTap(_ tab: SaviTab) {
        setTab(tab)
        if tab == .home {
            homeScrollToTopRequest += 1
        }
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
        evaluateShareSetupReminder()
    }

    private func routeForCoachStep(_ step: SaviCoachStep) {
        presentedSheet = nil
        activeSearchFacet = nil
        setTab(step.tab)
    }

    func resetFilters() {
        if query != "" { query = "" }
        if folderFilter != "f-all" { folderFilter = "f-all" }
        if typeFilter != "all" { typeFilter = "all" }
        if documentSubtypeFilter != SearchDocumentSubtype.all.rawValue {
            documentSubtypeFilter = SearchDocumentSubtype.all.rawValue
        }
        if sourceFilter != "all" { sourceFilter = "all" }
        if tagFilter != "all" { tagFilter = "all" }
        if dateFilter != SearchDateFilter.all.rawValue { dateFilter = SearchDateFilter.all.rawValue }
        if hasFilter != SearchHasFilter.all.rawValue { hasFilter = SearchHasFilter.all.rawValue }
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
        if !isSearchRefinePresented {
            searchRefineOpenRequestedAt = Date()
            NSLog("[SAVI Native] Search refine presentation requested.")
            isSearchRefinePresented = true
        }
    }

    func markSearchRefineSheetAppeared() {
        guard let requestedAt = searchRefineOpenRequestedAt else { return }
        let duration = Date().timeIntervalSince(requestedAt)
        NSLog("[SAVI Native] Search refine sheet appeared after %.3fs.", duration)
        searchRefineOpenRequestedAt = nil
    }

    func startHomeSearch(query: String = "", typeFilter: String = "all") {
        routeFromHomeToSearch(query: query, typeFilter: typeFilter, focusesSearchField: true, opensRefine: false)
    }

    func startHomeRefine() {
        routeFromHomeToSearch(query: "", typeFilter: "all", focusesSearchField: false, opensRefine: true)
    }

    private func routeFromHomeToSearch(
        query: String,
        typeFilter: String,
        focusesSearchField: Bool,
        opensRefine: Bool
    ) {
        applyHomeSearchFilters(query: query, typeFilter: typeFilter)
        if activeSearchFacet != nil {
            activeSearchFacet = nil
        }
        if isSearchRefinePresented {
            isSearchRefinePresented = false
        }
        setTab(.search)
        if focusesSearchField {
            searchFocusRequest += 1
        }
        if opensRefine {
            Task { @MainActor [weak self] in
                await Task.yield()
                self?.openSearchRefine()
            }
        }
    }

    private func applyHomeSearchFilters(query: String, typeFilter targetTypeFilter: String) {
        if self.query != query { self.query = query }
        if folderFilter != "f-all" { folderFilter = "f-all" }
        if sourceFilter != "all" { sourceFilter = "all" }
        if tagFilter != "all" { tagFilter = "all" }
        if dateFilter != SearchDateFilter.all.rawValue { dateFilter = SearchDateFilter.all.rawValue }
        if hasFilter != SearchHasFilter.all.rawValue { hasFilter = SearchHasFilter.all.rawValue }
        if typeFilter != targetTypeFilter { typeFilter = targetTypeFilter }
        if documentSubtypeFilter != SearchDocumentSubtype.all.rawValue {
            documentSubtypeFilter = SearchDocumentSubtype.all.rawValue
        }
    }

    func clearSearchFacet(_ facet: SearchFacet) {
        switch facet {
        case .type:
            typeFilter = "all"
            documentSubtypeFilter = SearchDocumentSubtype.all.rawValue
        case .keeper:
            folderFilter = "f-all"
        case .tag:
            tagFilter = "all"
        case .date:
            dateFilter = SearchDateFilter.all.rawValue
        case .source:
            sourceFilter = "all"
        case .has:
            hasFilter = SearchHasFilter.all.rawValue
        }
    }

    func clearDateFilter() {
        dateFilter = SearchDateFilter.all.rawValue
    }

    func clearHasFilter() {
        hasFilter = SearchHasFilter.all.rawValue
    }

    func clearRefineFilters() {
        if folderFilter != "f-all" { folderFilter = "f-all" }
        if typeFilter != "all" { typeFilter = "all" }
        if documentSubtypeFilter != SearchDocumentSubtype.all.rawValue {
            documentSubtypeFilter = SearchDocumentSubtype.all.rawValue
        }
        if sourceFilter != "all" { sourceFilter = "all" }
        if tagFilter != "all" { tagFilter = "all" }
        if dateFilter != SearchDateFilter.all.rawValue { dateFilter = SearchDateFilter.all.rawValue }
        if hasFilter != SearchHasFilter.all.rawValue { hasFilter = SearchHasFilter.all.rawValue }
    }

    func normalizeLegacyHasFilterIfNeeded() {
        guard let option = SearchHasFilter(rawValue: hasFilter), option != .all else { return }
        switch option {
        case .all:
            break
        case .file:
            typeFilter = "docs"
            documentSubtypeFilter = SearchDocumentSubtype.all.rawValue
        case .image:
            typeFilter = "image"
        case .video:
            typeFilter = "video"
        case .audio:
            typeFilter = "audio"
        case .pdf:
            typeFilter = "docs"
            documentSubtypeFilter = SearchDocumentSubtype.pdf.rawValue
        case .link:
            typeFilter = "link"
        case .location:
            typeFilter = "place"
        case .note:
            typeFilter = "note"
        }
        hasFilter = SearchHasFilter.all.rawValue
    }

    func openFoldersManagement() {
        activeSearchFacet = nil
        setTab(.folders)
    }

    private func openProtectedFolderIfAllowed(_ folder: SaviFolder) async {
        guard await unlockKeeperIfNeeded(folder) else { return }
        folderFilter = folder.id
        typeFilter = "all"
        documentSubtypeFilter = SearchDocumentSubtype.all.rawValue
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
            toast = "Turn on Face ID or a device passcode to unlock protected folders."
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
            toast = "Folder stayed locked."
        }
        return false
    }

    func lockProtectedFolders() {
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
        presentSafely(.web(url))
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
            presentSafely(.quickLook(previewURL))
            return
        }
        if let urlString = item.url?.nilIfBlank,
           let url = URL(string: urlString) {
            previewWebURL(url)
            return
        }
        presentItem(item)
    }

    private func visibleItemsForBrowsing() -> [SaviItem] {
        items.filter { !isItemInLockedKeeper($0) }
    }

    private func isItemInLockedKeeper(_ item: SaviItem) -> Bool {
        guard let folder = folder(for: item.folderId), folder.locked else { return false }
        return !unlockedProtectedKeeperIds.contains(folder.id)
    }

    func filteredItems(for tab: SaviTab? = nil) -> [SaviItem] {
        normalizeLegacyHasFilterIfNeeded()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let cacheKey = filterCacheKey(tab: tab, trimmedQuery: trimmed)
        if let cached = filteredItemsCache[cacheKey] {
            return cached
        }

        let startedAt = Date()
        defer {
            logSlowFilterIfNeeded(startedAt: startedAt, tab: tab)
        }

        if tab == .home {
            let result = visibleItemsForBrowsing().sorted { $0.savedAt > $1.savedAt }
            storeFilteredItems(result, for: cacheKey)
            return result
        }

        var result = visibleItemsForBrowsing()
        if folderFilter != "f-all" {
            result = result.filter { $0.folderId == folderFilter }
        }
        if typeFilter != "all" {
            result = result.filter { matchesSearchKind($0, kind: typeFilter) }
        }
        if typeFilter == "docs", documentSubtypeFilter != SearchDocumentSubtype.all.rawValue {
            result = result.filter { matchesDocumentSubtype($0, subtype: documentSubtypeFilter) }
        }
        if sourceFilter != "all" {
            result = result.filter { matchesSourceFilter($0, filter: sourceFilter) }
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
        if !trimmed.isEmpty {
            let needles = normalizedSearchNeedles(from: trimmed)
            result = result.filter { item in
                let haystack = searchHaystack(for: item)
                return needles.allSatisfy { haystack.contains($0) }
            }
        }

        let sorted = result.sorted { $0.savedAt > $1.savedAt }
        storeFilteredItems(sorted, for: cacheKey)
        return sorted
    }

    private func filterCacheKey(tab: SaviTab?, trimmedQuery: String) -> SaviFilterCacheKey {
        let isHome = tab == .home
        return SaviFilterCacheKey(
            tab: tab,
            query: isHome ? "" : trimmedQuery.lowercased(),
            folderFilter: isHome ? "f-all" : folderFilter,
            typeFilter: isHome ? "all" : typeFilter,
            sourceFilter: isHome ? "all" : sourceFilter,
            tagFilter: isHome ? "all" : tagFilter,
            dateFilter: isHome ? SearchDateFilter.all.rawValue : dateFilter,
            customDateStart: isHome || dateFilter != SearchDateFilter.custom.rawValue ? 0 : customSearchStartDate.timeIntervalSince1970,
            customDateEnd: isHome || dateFilter != SearchDateFilter.custom.rawValue ? 0 : customSearchEndDate.timeIntervalSince1970,
            documentSubtypeFilter: isHome || typeFilter != "docs" ? SearchDocumentSubtype.all.rawValue : documentSubtypeFilter,
            hasFilter: isHome ? SearchHasFilter.all.rawValue : hasFilter,
            itemsRevision: itemsRevision,
            foldersRevision: foldersRevision,
            unlockedFolderIds: unlockedProtectedKeeperIds.sorted()
        )
    }

    private func storeFilteredItems(_ result: [SaviItem], for key: SaviFilterCacheKey) {
        if filteredItemsCache.count > 24 {
            filteredItemsCache.removeAll(keepingCapacity: true)
        }
        filteredItemsCache[key] = result
    }

    private func logSlowFilterIfNeeded(startedAt: Date, tab: SaviTab?) {
        let duration = Date().timeIntervalSince(startedAt)
        guard duration >= Self.slowFilterLogThreshold,
              Date().timeIntervalSince(lastSlowFilterLogAt) > 5
        else { return }

        lastSlowFilterLogAt = Date()
        let label = tab.map { "\($0)" } ?? "search"
        NSLog("[SAVI Native] %@ filtering took %.3fs across %d item(s)", label, duration, items.count)
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
        if let cached = searchHaystackCache[item.id] {
            return cached
        }

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

        pieces.append(fileExtensionTokens(for: item).joined(separator: " "))

        if isPDF(item) {
            pieces.append("pdf document file")
        } else if isAudio(item) {
            pieces.append("audio music podcast sound")
        } else if isDocument(item) {
            pieces.append("doc docs document file attachment")
            pieces.append(documentSubtypeSearchTokens(for: item).joined(separator: " "))
        }
        if isScreenshot(item) {
            pieces.append("screenshot screen shot image")
        }

        let haystack = pieces.joined(separator: " ").lowercased()
        searchHaystackCache[item.id] = haystack
        return haystack
    }

    var hasActiveSearchControls: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            folderFilter != "f-all" ||
            typeFilter != "all" ||
            documentSubtypeFilter != SearchDocumentSubtype.all.rawValue ||
            sourceFilter != "all" ||
            tagFilter != "all" ||
            dateFilter != SearchDateFilter.all.rawValue
    }

    var refineFilterCount: Int {
        [
            folderFilter != "f-all",
            typeFilter != "all",
            documentSubtypeFilter != SearchDocumentSubtype.all.rawValue,
            sourceFilter != "all",
            tagFilter != "all",
            dateFilter != SearchDateFilter.all.rawValue
        ].filter { $0 }.count
    }

    func folder(for id: String) -> SaviFolder? {
        foldersById[id] ?? folders.first { $0.id == id }
    }

    func count(in folder: SaviFolder) -> Int {
        if folder.id == "f-all" { return visibleItemsForBrowsing().count }
        if folder.locked, !unlockedProtectedKeeperIds.contains(folder.id) { return 0 }
        return items.filter { $0.folderId == folder.id }.count
    }

    var sampleItemCount: Int {
        items.filter { $0.demo == true }.count
    }

    var hasSampleLibraryContent: Bool {
        sampleItemCount > 0
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

        if visibleItemsForBrowsing().allSatisfy({ $0.demo == true }) {
            return Array((primary + utility).sorted {
                if $0.order == $1.order { return $0.name < $1.name }
                return $0.order < $1.order
            }.prefix(limit))
        }

        return Array((sortedForHome(primary) + sortedForHome(utility)).prefix(limit))
    }

    var visibleFriends: [SaviFriend] {
        guard SaviReleaseGate.socialFeaturesEnabled else { return [] }
        return friends.filter { !isFriendBlocked($0.username) }
    }

    var visibleFriendLinks: [SaviSharedLink] {
        guard SaviReleaseGate.socialFeaturesEnabled else { return [] }
        return friendLinks.filter(isAllowedSharedLink)
    }

    var blockedFriendUsernames: [String] {
        prefs.blockedFriendUsernames
            .map(SaviSocialText.normalizedUsername)
            .filter { !$0.isEmpty }
            .sorted()
    }

    func isFriendBlocked(_ username: String) -> Bool {
        blockedFriendUsernameSet.contains(SaviSocialText.normalizedUsername(username))
    }

    func refreshCloudKitStatus() async {
        cloudKitStatus = await cloudKitService.accountStatusText()
    }

    var isAppleAccountLinked: Bool {
        prefs.appleUserIdentifier?.nilIfBlank != nil
    }

    var appleAccountDisplayName: String {
        prefs.appleFullName?.nilIfBlank ??
            prefs.appleEmail?.nilIfBlank ??
            (isAppleAccountLinked ? "Apple ID linked" : "Not linked")
    }

    var appleAccountDetail: String {
        if let email = prefs.appleEmail?.nilIfBlank {
            return email
        }
        if let authorizedAt = prefs.appleAuthorizedAt {
            return "Linked \(SaviText.relativeSavedTime(authorizedAt, now: Date())) ago"
        }
        if !SaviReleaseGate.socialFeaturesEnabled {
            return "Optional for private iCloud backup. Social Beta is off in this build."
        }
        return "Use Apple ID for public sharing and recovery-ready account identity."
    }

    func configureAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                toast = "Apple sign in could not finish."
                return
            }
            let fullName = credential.fullName.flatMap { components -> String? in
                PersonNameComponentsFormatter().string(from: components).nilIfBlank
            }
            prefs.appleUserIdentifier = credential.user
            if let email = credential.email?.nilIfBlank {
                prefs.appleEmail = email
            }
            if let fullName {
                prefs.appleFullName = fullName
                if publicProfile.displayName == "SAVI Friend" || publicProfile.displayName == publicProfile.normalizedUsername {
                    publicProfile.displayName = fullName
                }
            }
            prefs.appleAuthorizedAt = Date().timeIntervalSince1970 * 1000
            appleAccountStatus = "Apple ID linked"
            persist()
            toast = "Apple ID linked."
            Task {
                await refreshAppleAccountStatus()
                if SaviReleaseGate.socialFeaturesEnabled {
                    await syncSocialLinks()
                }
            }
        case .failure(let error):
            let nsError = error as NSError
            guard nsError.code != ASAuthorizationError.Code.canceled.rawValue else { return }
            toast = "Apple sign in failed."
            NSLog("[SAVI Native] Sign in with Apple failed: \(error.localizedDescription)")
        }
    }

    func refreshAppleAccountStatus() async {
        guard let userIdentifier = prefs.appleUserIdentifier?.nilIfBlank else {
            appleAccountStatus = "Not linked"
            return
        }
        let provider = ASAuthorizationAppleIDProvider()
        let state = await withCheckedContinuation { continuation in
            provider.getCredentialState(forUserID: userIdentifier) { state, error in
                if let error {
                    NSLog("[SAVI Native] Apple credential state failed: \(error.localizedDescription)")
                }
                continuation.resume(returning: state)
            }
        }
        switch state {
        case .authorized:
            appleAccountStatus = "Apple ID linked"
        case .revoked, .notFound:
            prefs.appleUserIdentifier = nil
            prefs.appleEmail = nil
            prefs.appleFullName = nil
            prefs.appleAuthorizedAt = nil
            publicProfile.isLinkSharingEnabled = false
            appleAccountStatus = "Apple ID disconnected"
            persist()
        case .transferred:
            appleAccountStatus = "Apple ID transferred"
        @unknown default:
            appleAccountStatus = "Apple ID unknown"
        }
    }

    func unlinkAppleAccount() {
        prefs.appleUserIdentifier = nil
        prefs.appleEmail = nil
        prefs.appleFullName = nil
        prefs.appleAuthorizedAt = nil
        publicProfile.isLinkSharingEnabled = false
        appleAccountStatus = "Not linked"
        persist()
        toast = "Apple ID unlinked. Public sharing is off."
        Task { await syncSocialLinks() }
    }

    func updatePublicProfile(username: String, displayName: String, bio: String) {
        guard SaviReleaseGate.socialFeaturesEnabled else {
            publicProfile.isLinkSharingEnabled = false
            persist()
            toast = "Social Beta is off for this TestFlight build."
            return
        }
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
        guard SaviReleaseGate.socialFeaturesEnabled else {
            if publicProfile.isLinkSharingEnabled {
                publicProfile.isLinkSharingEnabled = false
                publicProfile.updatedAt = Date().timeIntervalSince1970 * 1000
                prefs.publishedPublicLinkIds = []
                persist()
            }
            socialSyncMessage = "Social Beta is off for this TestFlight build."
            toast = socialSyncMessage
            return
        }
        guard !enabled || isAppleAccountLinked else {
            toast = "Sign in with Apple before public sharing."
            socialSyncMessage = "Apple ID is required before public link sharing."
            return
        }
        publicProfile.isLinkSharingEnabled = enabled
        publicProfile.updatedAt = Date().timeIntervalSince1970 * 1000
        persist()
        Task { await syncSocialLinks() }
    }

    func deletePublicProfile() async {
        guard SaviReleaseGate.socialFeaturesEnabled else {
            publicProfile.isLinkSharingEnabled = false
            publicProfile.bio = ""
            publicProfile.updatedAt = Date().timeIntervalSince1970 * 1000
            prefs.publishedPublicLinkIds = []
            persist()
            socialSyncMessage = "Social Beta is off for this TestFlight build."
            toast = "Public sharing is off."
            return
        }
        let username = publicProfile.normalizedUsername
        let publishedIds = prefs.publishedPublicLinkIds
        publicProfile.isLinkSharingEnabled = false
        publicProfile.bio = ""
        publicProfile.updatedAt = Date().timeIntervalSince1970 * 1000
        prefs.publishedPublicLinkIds = []
        for index in folders.indices where !folders[index].locked {
            folders[index].isPublic = false
        }
        persist()

        await refreshCloudKitStatus()
        guard cloudKitStatus == "iCloud ready" else {
            socialSyncMessage = "Public sharing is off locally. \(cloudKitStatus) to remove cloud copies."
            toast = "Public sharing turned off locally."
            return
        }

        do {
            try await cloudKitService.deleteSharedLinks(ids: publishedIds)
            try await cloudKitService.deleteSharedLinks(ownerUsername: username)
            try await cloudKitService.deleteProfile(username: username)
            socialSyncMessage = "Public profile and shared links deleted."
            toast = "Public profile deleted."
        } catch {
            socialSyncMessage = "Could not delete every public record yet."
            toast = "Public sharing is off. Try deleting again when iCloud is ready."
            NSLog("[SAVI Native] delete public profile failed: \(error.localizedDescription)")
        }
    }

    func addFriend(username rawUsername: String) {
        guard SaviReleaseGate.socialFeaturesEnabled else {
            toast = "Social Beta is off for this TestFlight build."
            return
        }
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
        removeBlockedUsername(username)
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
        guard SaviReleaseGate.seedsDemoSocialContent else {
            toast = "Sample social data is debug-only."
            return
        }
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
                itemDescription: "A watch-later save for a music video, marked as entertainment instead of a private Folder.",
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
        guard SaviReleaseGate.socialFeaturesEnabled else { return }
        friends.removeAll { $0.id == friend.id }
        friendLinks.removeAll { SaviSocialText.normalizedUsername($0.ownerUsername) == friend.normalizedUsername }
        persist()
        toast = "Removed @\(friend.username)."
    }

    func blockFriend(_ friend: SaviFriend) {
        guard SaviReleaseGate.socialFeaturesEnabled else { return }
        blockFriend(username: friend.username)
    }

    func blockFriend(username rawUsername: String) {
        guard SaviReleaseGate.socialFeaturesEnabled else { return }
        let username = SaviSocialText.normalizedUsername(rawUsername)
        guard !username.isEmpty else { return }
        let blockedLinkIds = friendLinks
            .filter { SaviSocialText.normalizedUsername($0.ownerUsername) == username }
            .map(\.id)
        let blockedLinkIdSet = Set(blockedLinkIds)
        prefs.likedFriendLinkIds.removeAll { blockedLinkIdSet.contains($0) }
        friends.removeAll { $0.normalizedUsername == username }
        friendLinks.removeAll { SaviSocialText.normalizedUsername($0.ownerUsername) == username }
        if !blockedFriendUsernameSet.contains(username) {
            prefs.blockedFriendUsernames.append(username)
            prefs.blockedFriendUsernames = blockedFriendUsernames
        }
        persist()
        toast = "Blocked @\(username)."
    }

    func unblockFriend(username rawUsername: String) {
        guard SaviReleaseGate.socialFeaturesEnabled else { return }
        let username = SaviSocialText.normalizedUsername(rawUsername)
        guard !username.isEmpty else { return }
        prefs.blockedFriendUsernames.removeAll { SaviSocialText.normalizedUsername($0) == username }
        persist()
        toast = "Unblocked @\(username)."
        Task { await syncSocialLinks() }
    }

    func reportFriend(_ friend: SaviFriend) {
        guard SaviReleaseGate.socialFeaturesEnabled else { return }
        openModerationEmail(
            subject: "SAVI report: @\(friend.username)",
            body: """
            I want to report this SAVI profile.

            Username: @\(friend.username)
            Display name: \(friend.displayName)
            Reason:
            """
        )
    }

    func reportFriendLink(_ link: SaviSharedLink) {
        guard SaviReleaseGate.socialFeaturesEnabled else { return }
        openModerationEmail(
            subject: "SAVI report: link from @\(link.ownerUsername)",
            body: """
            I want to report this SAVI link.

            Owner: @\(link.ownerUsername)
            Title: \(link.title)
            URL: \(link.url)
            Link ID: \(link.id)
            Reason:
            """
        )
    }

    func toggleLikeFriendLink(_ link: SaviSharedLink) {
        guard SaviReleaseGate.socialFeaturesEnabled else { return }
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
        guard SaviReleaseGate.socialFeaturesEnabled else { return false }
        return prefs.likedFriendLinkIds.contains(link.id)
    }

    var likedFriendLinks: [SaviSharedLink] {
        visibleFriendLinks.filter { prefs.likedFriendLinkIds.contains($0.id) }
            .sorted { $0.sharedAt > $1.sharedAt }
    }

    func openFriendProfile(_ friend: SaviFriend) {
        guard SaviReleaseGate.socialFeaturesEnabled else {
            toast = "Social Beta is off for this TestFlight build."
            return
        }
        guard !isFriendBlocked(friend.username) else {
            toast = "@\(friend.username) is blocked."
            return
        }
        presentSafely(.sheet(.friendProfile(friend)))
    }

    func openFriendLinkDetail(_ link: SaviSharedLink) {
        guard SaviReleaseGate.socialFeaturesEnabled else {
            toast = "Social Beta is off for this TestFlight build."
            return
        }
        guard !isFriendBlocked(link.ownerUsername) else {
            toast = "@\(link.ownerUsername) is blocked."
            return
        }
        presentSafely(.sheet(.friendLinkDetail(link)))
    }

    func openFriendLinkSave(_ link: SaviSharedLink) {
        guard SaviReleaseGate.socialFeaturesEnabled else {
            toast = "Social Beta is off for this TestFlight build."
            return
        }
        presentSafely(.sheet(.friendLinkSave(link)))
    }

    func friend(for link: SaviSharedLink) -> SaviFriend {
        let username = SaviSocialText.normalizedUsername(link.ownerUsername)
        if let existing = visibleFriends.first(where: { $0.normalizedUsername == username }) {
            return existing
        }
        return SaviFriend(
            id: username,
            username: username,
            displayName: link.ownerDisplayName.nilIfBlank ?? "@\(username)",
            avatarColor: "#D8FF3C",
            addedAt: link.sharedAt,
            lastSeenAt: link.sharedAt
        )
    }

    func friend(forExploreItem item: SaviItem) -> SaviFriend? {
        guard SaviReleaseGate.socialFeaturesEnabled else { return nil }
        guard let link = friendLink(forExploreItem: item) else { return nil }
        return friend(for: link)
    }

    func friendLinks(for friend: SaviFriend, keeperId: String? = nil) -> [SaviSharedLink] {
        visibleFriendLinks
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
        guard let url = URL(string: SaviText.normalizedURL(link.url)) else { return }
        previewWebURL(url)
    }

    func url(forFriendLink link: SaviSharedLink) -> URL? {
        URL(string: SaviText.normalizedURL(link.url))
    }

    func friendLinkAlreadySaved(_ link: SaviSharedLink) -> Bool {
        let normalized = SaviText.normalizedURL(link.url).lowercased()
        return items.contains { item in
            item.url?.lowercased() == normalized
        }
    }

    func suggestedFolderForFriendLink(_ link: SaviSharedLink) -> SaviFolder? {
        folder(for: classifyFolder(input: classificationInput(for: link)).folderId)
    }

    @discardableResult
    func saveFriendLinkToLibrary(_ link: SaviSharedLink, folderId: String) -> Bool {
        guard SaviReleaseGate.socialFeaturesEnabled else {
            toast = "Social Beta is off for this TestFlight build."
            return false
        }
        let normalized = SaviText.normalizedURL(link.url)
        guard !friendLinkAlreadySaved(link) else {
            toast = "That link is already in SAVI."
            return false
        }

        let usesAutoFolder = folderId.isEmpty
        let tags = SaviText.dedupeTags(
            link.tags +
            ["from-\(link.ownerUsername)", link.source, link.keeperName]
        )
        let targetFolderId = usesAutoFolder
            ? guessFolderId(
                title: link.title,
                description: link.itemDescription,
                url: normalized,
                tags: tags,
                type: link.type.rawValue,
                source: link.source,
                context: "Friend Link Save"
            )
            : folderId
        let item = SaviItem(
            title: link.title.nilIfBlank ?? SaviText.fallbackTitle(for: normalized),
            itemDescription: link.itemDescription,
            url: normalized,
            source: link.source,
            type: link.type,
            folderId: targetFolderId,
            tags: tags,
            thumbnail: link.thumbnail,
            color: folder(for: targetFolderId)?.color
        )

        items.insert(item, at: 0)
        if usesAutoFolder {
            autoFolderItemIds.insert(item.id)
        } else {
            learnFolderSelection(for: item)
        }
        persist()
        toast = "Saved from @\(link.ownerUsername)."
        scheduleAppleIntelligenceRefinement(id: item.id, allowFolderChange: usesAutoFolder)
        if let url = URL(string: normalized) {
            scheduleMetadataEnrichment(id: item.id, url: url, reason: "friend-save")
        }
        scheduleSocialSyncIfNeeded()
        return true
    }

    private var blockedFriendUsernameSet: Set<String> {
        Set(prefs.blockedFriendUsernames.map(SaviSocialText.normalizedUsername).filter { !$0.isEmpty })
    }

    private func removeBlockedUsername(_ username: String) {
        prefs.blockedFriendUsernames.removeAll {
            SaviSocialText.normalizedUsername($0) == username
        }
    }

    private func isAllowedSharedLink(_ link: SaviSharedLink) -> Bool {
        guard !isFriendBlocked(link.ownerUsername),
              [.link, .article, .video, .image, .place].contains(link.type)
        else { return false }

        let normalizedURL = SaviText.normalizedURL(link.url)
        guard let url = URL(string: normalizedURL),
              ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        else { return false }

        let haystack = [
            link.ownerUsername,
            link.ownerDisplayName,
            link.title,
            link.itemDescription,
            normalizedURL,
            link.source,
            link.keeperName,
            link.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()

        return !SaviText.looksSensitive(haystack) &&
            !SaviSafety.containsObjectionableContent(haystack)
    }

    private func openModerationEmail(subject: String, body: String) {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=?")
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: allowed) ?? subject
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: allowed) ?? body
        guard let url = URL(string: "mailto:\(SaviSafety.moderationEmail)?subject=\(encodedSubject)&body=\(encodedBody)") else {
            toast = "Email \(SaviSafety.moderationEmail) to report this."
            return
        }
        UIApplication.shared.open(url)
        toast = "Opening report email."
    }

    func syncSocialLinks() async {
        guard SaviReleaseGate.socialFeaturesEnabled else {
            if publicProfile.isLinkSharingEnabled || !prefs.publishedPublicLinkIds.isEmpty {
                publicProfile.isLinkSharingEnabled = false
                prefs.publishedPublicLinkIds = []
                persist()
            }
            socialSyncMessage = "Social Beta is off for this TestFlight build."
            return
        }
        guard !isSocialSyncing else { return }
        isSocialSyncing = true
        defer { isSocialSyncing = false }

        await refreshCloudKitStatus()
        guard cloudKitStatus == "iCloud ready" else {
            socialSyncMessage = cloudKitStatus
            return
        }
        guard !publicProfile.isLinkSharingEnabled || isAppleAccountLinked else {
            publicProfile.isLinkSharingEnabled = false
            persist()
            socialSyncMessage = "Sign in with Apple to share public links."
            return
        }

        do {
            let shareableLinks = publicSharedLinks()
            if publicProfile.isLinkSharingEnabled {
                try await cloudKitService.saveProfile(publicProfile)
                try await cloudKitService.publishSharedLinks(shareableLinks)
                let nextIds = Set(shareableLinks.map(\.id))
                let staleIds = Set(prefs.publishedPublicLinkIds).subtracting(nextIds)
                if !staleIds.isEmpty {
                    try await cloudKitService.deleteSharedLinks(ids: Array(staleIds))
                }
                prefs.publishedPublicLinkIds = Array(nextIds).sorted()
            } else {
                if !prefs.publishedPublicLinkIds.isEmpty {
                    try await cloudKitService.deleteSharedLinks(ids: prefs.publishedPublicLinkIds)
                    prefs.publishedPublicLinkIds = []
                } else {
                    try await cloudKitService.deleteSharedLinks(ownerUsername: publicProfile.normalizedUsername)
                }
            }
            let fetched = try await cloudKitService.fetchSharedLinks(friendUsernames: visibleFriends.map(\.username))
            var refreshedLinks = fetched.filter { $0.ownerUserId != publicProfile.userId }
                .filter(isAllowedSharedLink)
#if targetEnvironment(simulator)
            let demoLinks = friendLinks.filter { $0.ownerUserId == "demo-friend-ava" }
            let fetchedIds = Set(refreshedLinks.map(\.id))
            refreshedLinks.append(contentsOf: demoLinks.filter { !fetchedIds.contains($0.id) && isAllowedSharedLink($0) })
#endif
            friendLinks = refreshedLinks.sorted { $0.sharedAt > $1.sharedAt }
            socialSyncMessage = publicProfile.isLinkSharingEnabled
                ? "Shared \(shareableLinks.count) link preview\(shareableLinks.count == 1 ? "" : "s")."
                : "Friend feed refreshed."
            persist()
        } catch {
            socialSyncMessage = "CloudKit sync needs setup."
            NSLog("[SAVI Native] CloudKit social sync failed: \(error.localizedDescription)")
        }
    }

    func publicSharedLinks() -> [SaviSharedLink] {
        guard SaviReleaseGate.socialFeaturesEnabled,
              publicProfile.isLinkSharingEnabled
        else { return [] }
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
                title: SaviSafety.clipped(item.title, maxLength: 160),
                itemDescription: SaviSafety.clipped(item.itemDescription, maxLength: 500),
                url: url,
                source: item.readableSource ?? item.source,
                type: item.type,
                keeperId: folder.id,
                keeperName: folder.name,
                tags: SaviSafety.publicTags(item.tags),
                thumbnail: SaviSafety.publicThumbnail(item.thumbnail),
                savedAt: item.savedAt,
                sharedAt: item.savedAt
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

        return !SaviText.looksSensitive(haystack) &&
            !SaviSafety.containsObjectionableContent(haystack)
    }

    private func scheduleSocialSyncIfNeeded() {
        guard SaviReleaseGate.socialFeaturesEnabled,
              publicProfile.isLinkSharingEnabled
        else { return }
        Task { await syncSocialLinks() }
    }

    func searchRefineOptionsSnapshot(includeTags: Bool, tagLimit: Int = 80) -> SaviSearchRefineOptionsSnapshot {
        let key = searchRefineSnapshotKey(includeTags: includeTags, tagLimit: tagLimit)
        if let cached = searchRefineOptionsCache[key] {
            return cached
        }

        if includeTags {
            let startedAt = Date()
            let core = searchRefineOptionsSnapshot(includeTags: false, tagLimit: 0)
            let tagStartedAt = Date()
            let refineTagOptions = tagOptions(limit: tagLimit, items: filteredItemsIgnoringTag()).map {
                SaviSearchRefineTagOption(key: $0.key, label: $0.label, count: $0.count)
            }
            let tagDuration = Date().timeIntervalSince(tagStartedAt)
            let snapshot = SaviSearchRefineOptionsSnapshot(
                kindOptions: core.kindOptions,
                documentOptions: core.documentOptions,
                folderOptions: core.folderOptions,
                sourceGroupOptions: core.sourceGroupOptions,
                otherSourceOptions: core.otherSourceOptions,
                tagOptions: refineTagOptions,
                includesTags: true
            )
            storeSearchRefineOptionsSnapshot(snapshot, for: key)
            logSearchRefineSnapshotIfNeeded(
                startedAt: startedAt,
                includeTags: true,
                visibleDuration: 0,
                kindDuration: 0,
                folderDuration: 0,
                sourceDuration: 0,
                tagDuration: tagDuration
            )
            return snapshot
        }

        let startedAt = Date()
        let visibleStartedAt = Date()
        let visibleItems = visibleItemsForBrowsing()
        let visibleDuration = Date().timeIntervalSince(visibleStartedAt)

        let kindStartedAt = Date()
        let kindOptions = searchKindOptions(from: visibleItems, kinds: SaviSearchKind.refinePrimary, includeEmpty: true)
        let documentOptions = documentSubtypeOptions(from: visibleItems, includeEmpty: true)
        let kindDuration = Date().timeIntervalSince(kindStartedAt)

        let folderStartedAt = Date()
        let folderOptions = searchRefineFolderOptions(from: visibleItems)
        let folderDuration = Date().timeIntervalSince(folderStartedAt)

        let sourceStartedAt = Date()
        let sourceOptions = searchRefineSourceOptions(from: visibleItems, includeEmpty: false, limit: 8)
        let sourceGroupOptions = sourceOptions.groups
        let otherSourceOptions = sourceOptions.other
        let sourceDuration = Date().timeIntervalSince(sourceStartedAt)

        let snapshot = SaviSearchRefineOptionsSnapshot(
            kindOptions: kindOptions,
            documentOptions: documentOptions,
            folderOptions: folderOptions,
            sourceGroupOptions: sourceGroupOptions,
            otherSourceOptions: otherSourceOptions,
            tagOptions: [],
            includesTags: false
        )

        storeSearchRefineOptionsSnapshot(snapshot, for: key)

        logSearchRefineSnapshotIfNeeded(
            startedAt: startedAt,
            includeTags: false,
            visibleDuration: visibleDuration,
            kindDuration: kindDuration,
            folderDuration: folderDuration,
            sourceDuration: sourceDuration,
            tagDuration: 0
        )

        return snapshot
    }

    private func storeSearchRefineOptionsSnapshot(
        _ snapshot: SaviSearchRefineOptionsSnapshot,
        for key: SaviSearchRefineSnapshotKey
    ) {
        if searchRefineOptionsCache.count > 12 {
            searchRefineOptionsCache.removeAll(keepingCapacity: true)
        }
        searchRefineOptionsCache[key] = snapshot
    }

    private func searchRefineSnapshotKey(includeTags: Bool, tagLimit: Int) -> SaviSearchRefineSnapshotKey {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return SaviSearchRefineSnapshotKey(
            includeTags: includeTags,
            tagLimit: includeTags ? tagLimit : 0,
            itemsRevision: itemsRevision,
            foldersRevision: foldersRevision,
            unlockedFolderIds: unlockedProtectedKeeperIds.sorted(),
            query: includeTags ? trimmed : "",
            folderFilter: includeTags ? folderFilter : "f-all",
            typeFilter: includeTags ? typeFilter : "all",
            documentSubtypeFilter: includeTags ? documentSubtypeFilter : SearchDocumentSubtype.all.rawValue,
            sourceFilter: includeTags ? sourceFilter : "all",
            dateFilter: includeTags ? dateFilter : SearchDateFilter.all.rawValue,
            customDateStart: includeTags && dateFilter == SearchDateFilter.custom.rawValue ? customSearchStartDate.timeIntervalSince1970 : 0,
            customDateEnd: includeTags && dateFilter == SearchDateFilter.custom.rawValue ? customSearchEndDate.timeIntervalSince1970 : 0,
            hasFilter: includeTags ? hasFilter : SearchHasFilter.all.rawValue
        )
    }

    private func logSearchRefineSnapshotIfNeeded(
        startedAt: Date,
        includeTags: Bool,
        visibleDuration: TimeInterval,
        kindDuration: TimeInterval,
        folderDuration: TimeInterval,
        sourceDuration: TimeInterval,
        tagDuration: TimeInterval
    ) {
        let duration = Date().timeIntervalSince(startedAt)
        guard duration >= Self.slowRefineSnapshotLogThreshold else { return }
        NSLog(
            "[SAVI Native] Refine options snapshot took %.3fs across %d item(s), tags=%@ [visible %.3f, type/docs %.3f, folders %.3f, sources %.3f, tags %.3f]",
            duration,
            items.count,
            includeTags ? "yes" : "no",
            visibleDuration,
            kindDuration,
            folderDuration,
            sourceDuration,
            tagDuration
        )
    }

    func sourceOptions() -> [(key: String, label: String, count: Int)] {
        sourceOptions(from: visibleItemsForBrowsing())
    }

    private func sourceOptions(from visibleItems: [SaviItem]) -> [(key: String, label: String, count: Int)] {
        let groups = Dictionary(grouping: visibleItems, by: sourceKey(for:))
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

    func sourceGroupOptions(includeEmpty: Bool = false) -> [(group: SaviSearchSourceGroup, count: Int)] {
        sourceGroupOptions(from: visibleItemsForBrowsing(), includeEmpty: includeEmpty).map {
            (group: $0.group, count: $0.count)
        }
    }

    func otherSourceOptions(limit: Int = 8) -> [(key: String, label: String, count: Int)] {
        otherSourceOptions(from: visibleItemsForBrowsing(), limit: limit).map {
            (key: $0.key, label: $0.label, count: $0.count)
        }
    }

    func sourceFilterLabel(for filter: String) -> String {
        if filter == "all" { return "Any source" }
        if let group = SaviSearchSourceGroup.group(for: filter) {
            return group.title
        }
        return sourceOptions().first(where: { $0.key == filter })?.label ?? sourceLabel(for: filter)
    }

    func documentSubtypeOptions(includeEmpty: Bool = true) -> [(subtype: SearchDocumentSubtype, count: Int)] {
        documentSubtypeOptions(from: visibleItemsForBrowsing(), includeEmpty: includeEmpty).map {
            (subtype: $0.subtype, count: $0.count)
        }
    }

    func documentSubtypeTitle(for id: String) -> String {
        SearchDocumentSubtype(rawValue: id)?.title ?? SearchDocumentSubtype.all.title
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
        searchKindOptions(from: visibleItemsForBrowsing(), kinds: SaviSearchKind.all, includeEmpty: includeEmpty).map {
            (kind: $0.kind, count: $0.count)
        }
    }

    func contextualTagOptions(limit: Int = 30) -> [(key: String, label: String, count: Int)] {
        tagOptions(limit: limit, items: filteredItemsIgnoringTag())
    }

    private func searchKindOptions(
        from visibleItems: [SaviItem],
        kinds: [SaviSearchKind],
        includeEmpty: Bool
    ) -> [SaviSearchRefineKindOption] {
        kinds.compactMap { kind in
            let count = kind.id == "all" ? visibleItems.count : visibleItems.filter { matchesSearchKind($0, kind: kind.id) }.count
            guard includeEmpty || kind.id == "all" || count > 0 else { return nil }
            return SaviSearchRefineKindOption(kind: kind, count: count)
        }
    }

    private func documentSubtypeOptions(
        from visibleItems: [SaviItem],
        includeEmpty: Bool
    ) -> [SaviSearchRefineDocumentOption] {
        let docs = visibleItems.filter { isDocument($0) }
        return SearchDocumentSubtype.allCases.compactMap { subtype in
            let count = subtype == .all ? docs.count : docs.filter { matchesDocumentSubtype($0, subtype: subtype.rawValue) }.count
            guard includeEmpty || subtype == .all || count > 0 else { return nil }
            return SaviSearchRefineDocumentOption(subtype: subtype, count: count)
        }
    }

    private func searchRefineFolderOptions(from visibleItems: [SaviItem]) -> [SaviSearchRefineFolderOption] {
        let countsByFolder = Dictionary(grouping: visibleItems, by: \.folderId).mapValues(\.count)
        let folders = orderedFoldersForDisplay().map { folder in
            let locked = folder.locked && !isProtectedKeeperUnlocked(folder)
            return SaviSearchRefineFolderOption(
                id: folder.id,
                folder: folder,
                title: folder.name,
                systemImage: SaviReleaseGate.socialFeaturesEnabled && folder.isPublic ? "person.2.fill" : locked ? "lock.fill" : folder.symbolName,
                count: locked ? nil : countsByFolder[folder.id, default: 0],
                locked: locked
            )
        }
        return [.all(count: visibleItems.count)] + folders
    }

    private func sourceGroupOptions(
        from visibleItems: [SaviItem],
        includeEmpty: Bool
    ) -> [SaviSearchRefineSourceGroupOption] {
        searchRefineSourceOptions(from: visibleItems, includeEmpty: includeEmpty, limit: 0).groups
    }

    private func otherSourceOptions(
        from visibleItems: [SaviItem],
        limit: Int
    ) -> [SaviSearchRefineRawSourceOption] {
        searchRefineSourceOptions(from: visibleItems, includeEmpty: false, limit: limit).other
    }

    private func searchRefineSourceOptions(
        from visibleItems: [SaviItem],
        includeEmpty: Bool,
        limit: Int
    ) -> (groups: [SaviSearchRefineSourceGroupOption], other: [SaviSearchRefineRawSourceOption]) {
        var groupCounts: [String: Int] = [:]
        var counts: [String: Int] = [:]
        var labels: [String: String] = [:]

        for item in visibleItems {
            let groupKey = sourceGroupKey(for: item)
            groupCounts[groupKey, default: 0] += 1

            guard groupKey == "web" else { continue }
            let rawKey = sourceKey(for: item)
            guard rawKey != "web" else { continue }
            counts[rawKey, default: 0] += 1
            labels[rawKey] = sourceLabel(for: rawKey)
        }

        let groups: [SaviSearchRefineSourceGroupOption] = SaviSearchSourceGroup.curated.compactMap { group in
            let count = groupCounts[group.id, default: 0]
            guard includeEmpty || count > 0 else { return nil }
            return SaviSearchRefineSourceGroupOption(group: group, count: count)
        }

        let other = counts.map { key, count in
            SaviSearchRefineRawSourceOption(key: key, label: labels[key] ?? sourceLabel(for: key), count: count)
        }
        .sorted { lhs, rhs in
            if lhs.count == rhs.count { return lhs.label < rhs.label }
            return lhs.count > rhs.count
        }
        .prefix(max(limit, 0))
        .map { $0 }

        return (groups: groups, other: other)
    }

    private func filteredItemsIgnoringTag() -> [SaviItem] {
        normalizeLegacyHasFilterIfNeeded()
        var result = visibleItemsForBrowsing()
        if folderFilter != "f-all" {
            result = result.filter { $0.folderId == folderFilter }
        }
        if typeFilter != "all" {
            result = result.filter { matchesSearchKind($0, kind: typeFilter) }
        }
        if typeFilter == "docs", documentSubtypeFilter != SearchDocumentSubtype.all.rawValue {
            result = result.filter { matchesDocumentSubtype($0, subtype: documentSubtypeFilter) }
        }
        if sourceFilter != "all" {
            result = result.filter { matchesSourceFilter($0, filter: sourceFilter) }
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
            "Folder audit passed: \(report.passedCount)/\(report.results.count)." :
            "Folder audit found \(report.failedCount) issue(s)."
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
        toast = "Folder decision history cleared."
    }

    var exploreFreshCount: Int {
        exploreFreshCount(scope: exploreScope)
    }

    var exploreSeenCount: Int {
        exploreSeenCount(scope: exploreScope)
    }

    func setExploreScope(_ scope: ExploreScope) {
        let visibleScope = ExploreScope.visibleScope(for: scope.rawValue)
        exploreScope = visibleScope
        prefs.exploreScope = visibleScope.rawValue
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
        exploreSnapshot(seed: seed, scope: scope).statusText
    }

    func exploreSnapshot(seed: Int, scope: ExploreScope) -> SaviExploreSnapshot {
        let cacheKey = SaviExploreCacheKey(
            seed: seed,
            scope: scope,
            itemsRevision: itemsRevision,
            foldersRevision: foldersRevision,
            friendLinksRevision: friendLinksRevision,
            unlockedFolderIds: unlockedProtectedKeeperIds.sorted(),
            seenItemIds: prefs.exploreSeenItemIds
        )
        if let cached = exploreSnapshotCache[cacheKey] {
            return cached
        }

        let candidates = exploreCandidateItems(scope: scope)
        let seenIds = Set(prefs.exploreSeenItemIds)
        let candidateIds = Set(candidates.map(\.id))
        let sortedItems = candidates.sorted { lhs, rhs in
            let lhsSeen = seenIds.contains(lhs.id)
            let rhsSeen = seenIds.contains(rhs.id)
            if lhsSeen != rhsSeen { return !lhsSeen }

            let left = exploreSortKey(for: lhs, seed: seed)
            let right = exploreSortKey(for: rhs, seed: seed)
            if left == right { return lhs.savedAt > rhs.savedAt }
            return left < right
        }
        let items = Array(sortedItems.prefix(30))
        let freshCount = candidates.filter { !seenIds.contains($0.id) }.count
        let seenCount = prefs.exploreSeenItemIds.filter { candidateIds.contains($0) }.count
        let snapshot = SaviExploreSnapshot(
            items: items,
            statusText: exploreStatusText(itemCount: items.count, freshCount: freshCount, seenCount: seenCount, scope: scope),
            seenCount: seenCount
        )
        storeExploreSnapshot(snapshot, for: cacheKey)
        return snapshot
    }

    private func storeExploreSnapshot(_ snapshot: SaviExploreSnapshot, for key: SaviExploreCacheKey) {
        if exploreSnapshotCache.count > 12 {
            exploreSnapshotCache.removeAll(keepingCapacity: true)
        }
        exploreSnapshotCache[key] = snapshot
    }

    private func exploreStatusText(itemCount count: Int, freshCount: Int, seenCount: Int, scope: ExploreScope) -> String {
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
        exploreSnapshot(seed: seed, scope: scope).items
    }

    func isExploreSeen(_ item: SaviItem) -> Bool {
        prefs.exploreSeenItemIds.contains(item.id)
    }

    func openExploreItem(_ item: SaviItem) {
        markExploreSeen(item)
        presentItem(item)
    }

    func openExploreCard(_ item: SaviItem) {
        markExploreSeen(item)
        if SaviReleaseGate.socialFeaturesEnabled,
           let link = friendLink(forExploreItem: item) {
            openFriendLinkDetail(link)
            return
        }
        presentItem(item)
    }

    func previewExploreCard(_ item: SaviItem) {
        markExploreSeen(item)
        if SaviReleaseGate.socialFeaturesEnabled,
           let link = friendLink(forExploreItem: item),
           let url = url(forFriendLink: link) {
            previewWebURL(url)
            return
        }
        previewItemContent(item)
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
        guard SaviReleaseGate.socialFeaturesEnabled else { return false }
        return item.id.hasPrefix("friend-")
    }

    func friendLink(forExploreItem item: SaviItem) -> SaviSharedLink? {
        guard isFriendExploreItem(item) else { return nil }
        let rawId = String(item.id.dropFirst("friend-".count))
        return visibleFriendLinks.first { $0.id == rawId }
    }

    @discardableResult
    func toggleLikeForExploreItem(_ item: SaviItem) -> Bool {
        guard SaviReleaseGate.socialFeaturesEnabled else { return false }
        guard let link = friendLink(forExploreItem: item) else { return false }
        toggleLikeFriendLink(link)
        return true
    }

    func friendUsername(forExploreItem item: SaviItem) -> String? {
        guard SaviReleaseGate.socialFeaturesEnabled else { return nil }
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
        guard SaviReleaseGate.socialFeaturesEnabled else { return item.source }
        guard isFriendExploreItem(item),
              let separator = item.source.range(of: "·")
        else { return item.source }
        return String(item.source[separator.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func exploreCandidateItems(scope: ExploreScope = .all) -> [SaviItem] {
        let mine = visibleItemsForBrowsing()
        let visibleScope = ExploreScope.visibleScope(for: scope.rawValue)
        let friends = SaviReleaseGate.socialFeaturesEnabled ? visibleFriendLinks.map { $0.asExploreItem() } : []
        switch visibleScope {
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
            scheduleMetadataEnrichment(id: item.id, url: url, reason: "manual-save")
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
            recordFolderDecision(
                input: classificationInput(for: item),
                result: .init(folderId: item.folderId, confidence: 100, reason: "manual-correction"),
                context: "Manual edit",
                source: .manual
            )
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

    func addFolder(
        name: String,
        color: String,
        symbolName: String,
        image: String? = nil,
        locked: Bool = false,
        isPublic: Bool = false,
        usesImageBackground: Bool = false
    ) {
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
            isPublic: SaviReleaseGate.socialFeaturesEnabled && !locked ? isPublic : false,
            usesImageBackground: usesImageBackground
        )
        folders.insert(folder, at: max(0, folders.count - 1))
        orderedIds.append(folder.id)
        applyFolderOrder(orderedIds)
        persist()
        toast = "Folder created."
    }

    func saveFolder(_ folder: SaviFolder) {
        guard let index = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        var next = folder
        if !SaviReleaseGate.socialFeaturesEnabled || next.locked || next.id == "f-private-vault" {
            next.isPublic = false
        }
        if next.image?.nilIfBlank == nil {
            next.usesImageBackground = false
        }
        folders[index] = next
        if !folder.locked {
            unlockedProtectedKeeperIds.remove(folder.id)
        }
        persist()
        toast = "Folder updated."
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
        toast = "Folder deleted."
    }

    func clearDemoContent() {
        items.removeAll { $0.demo == true }
        prefs.demoSuppressed = true
        persist()
        toast = "Sample saves cleared."
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
        let personalItems = items.filter { $0.demo != true }
        folders = personalItems.isEmpty ? SaviSeeds.folders : SaviSeeds.withSeedDefaults(folders)
        items = SaviSeeds.items + personalItems
        prefs.demoSuppressed = false
        prefs.legacySeedVersion = Self.currentLegacySeedVersion
        persist()
        toast = "Sample library restored."
    }

    func quickLookURL(for item: SaviItem) -> URL? {
        guard let assetId = item.assetId,
              let asset = assets.first(where: { $0.id == assetId })
        else { return nil }
        return storage.assetURL(for: asset)
    }

    func buildBackupDocument() {
        do {
            let data = try backupData()
            backupDocument = SaviBackupDocument(data: data)
            backupExportFilename = "savi-backup-\(SaviText.backupStamp()).json"
            isExportingBackup = true
        } catch {
            toast = "Could not pack the backup."
            NSLog("[SAVI Native] backup export failed: \(error.localizedDescription)")
        }
    }

    func buildFullArchiveDocument(folderIds: Set<String>? = nil) {
        do {
            let exportScope = fullArchiveScope(folderIds: folderIds)
            let data = try storage.buildFullArchive(
                folders: exportScope.folders,
                items: exportScope.items,
                assets: exportScope.assets,
                prefs: prefs,
                publicProfile: publicProfile,
                friends: exportScope.friends,
                friendLinks: exportScope.friendLinks,
                folderLearning: exportScope.folderLearning
            )
            archiveDocument = SaviArchiveDocument(data: data)
            archiveExportFilename = "\(exportScope.filePrefix)-\(SaviText.backupStamp()).zip"
            isExportingArchive = true
        } catch {
            toast = "Could not pack the full archive."
            NSLog("[SAVI Native] full archive export failed: \(error.localizedDescription)")
        }
    }

    private func fullArchiveScope(folderIds: Set<String>?) -> (
        folders: [SaviFolder],
        items: [SaviItem],
        assets: [SaviAsset],
        friends: [SaviFriend],
        friendLinks: [SaviSharedLink],
        folderLearning: [SAVIFolderLearningSignal],
        filePrefix: String
    ) {
        let exportableFolderIds = Set(folders.filter { $0.id != "f-all" }.map(\.id))
        let selectedIds = Set((folderIds ?? exportableFolderIds).filter { exportableFolderIds.contains($0) })
        let exportsEverything = selectedIds.isEmpty || selectedIds == exportableFolderIds

        if exportsEverything {
            return (
                folders,
                items,
                assets,
                friends,
                friendLinks,
                folderLearningSignals,
                "savi-full-archive"
            )
        }

        let selectedItems = items.filter { selectedIds.contains($0.folderId) }
        let selectedAssetIds = Set(selectedItems.compactMap(\.assetId))
        return (
            folders.filter { selectedIds.contains($0.id) },
            selectedItems,
            assets.filter { selectedAssetIds.contains($0.id) },
            [],
            [],
            folderLearningSignals.filter { selectedIds.contains($0.folderId) },
            "savi-selected-folders"
        )
    }

    func backupToICloud() async {
        guard !isCloudBackupRunning else { return }
        isCloudBackupRunning = true
        defer { isCloudBackupRunning = false }

        await refreshCloudKitStatus()
        guard cloudKitStatus == "iCloud ready" else {
            cloudBackupMessage = "\(cloudKitStatus). Turn on iCloud to back up SAVI."
            toast = "iCloud backup needs iCloud."
            return
        }

        do {
            let data = try backupData()
            let updatedAt = try await cloudKitService.savePrivateBackup(data: data)
            cloudBackupMessage = "Saved to iCloud \(SaviText.relativeSavedTime(updatedAt, now: Date())) ago · \(SaviText.formatBytes(Int64(data.count)))"
            toast = "iCloud backup saved."
        } catch {
            cloudBackupMessage = "Could not save iCloud backup."
            toast = "iCloud backup failed."
            NSLog("[SAVI Native] iCloud backup failed: \(error.localizedDescription)")
        }
    }

    func restoreFromICloudBackup() async {
        guard !isCloudBackupRunning else { return }
        isCloudBackupRunning = true
        defer { isCloudBackupRunning = false }

        await refreshCloudKitStatus()
        guard cloudKitStatus == "iCloud ready" else {
            cloudBackupMessage = "\(cloudKitStatus). Turn on iCloud to restore SAVI."
            toast = "iCloud restore needs iCloud."
            return
        }

        do {
            guard let snapshot = try await cloudKitService.fetchPrivateBackup() else {
                cloudBackupMessage = "No iCloud backup found yet."
                toast = "No iCloud backup found."
                return
            }
            try restoreBackupData(snapshot.data)
            cloudBackupMessage = "Restored iCloud backup from \(SaviText.relativeSavedTime(snapshot.updatedAt, now: Date())) ago · \(SaviText.formatBytes(Int64(snapshot.size)))"
            toast = "iCloud backup restored."
        } catch {
            cloudBackupMessage = "Could not restore iCloud backup."
            toast = "iCloud restore failed."
            NSLog("[SAVI Native] iCloud restore failed: \(error.localizedDescription)")
        }
    }

    func importBackup(from url: URL) async {
        await previewBackupImport(from: url)
    }

    func previewBackupImport(from url: URL) async {
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let data = try Data(contentsOf: url)
            let payload = try SaviArchiveImporter.importPayload(data: data, suggestedName: url.lastPathComponent)
            pendingBackupImportPayload = payload
            pendingBackupPreview = payload.preview
        } catch {
            pendingBackupImportPayload = nil
            pendingBackupPreview = nil
            toast = "Could not read that backup."
            NSLog("[SAVI Native] backup preview failed: \(error.localizedDescription)")
        }
    }

    func cancelPendingBackupImport() {
        pendingBackupImportPayload = nil
        pendingBackupPreview = nil
    }

    func restorePendingBackupImport() async {
        guard let payload = pendingBackupImportPayload else { return }
        do {
            try restoreBackupPayload(payload)
            pendingBackupImportPayload = nil
            pendingBackupPreview = nil
            toast = "Backup restored."
        } catch {
            toast = "Could not restore that backup."
            NSLog("[SAVI Native] backup restore failed: \(error.localizedDescription)")
        }
    }

    private func backupData() throws -> Data {
        let backup = try storage.buildBackup(
            folders: folders,
            items: items,
            assets: assets,
            prefs: prefs,
            publicProfile: publicProfile,
            friends: friends,
            friendLinks: friendLinks,
            folderLearning: folderLearningSignals
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    private func restoreBackupData(_ data: Data) throws {
        let backup = try JSONDecoder().decode(SaviBackup.self, from: data)
        guard backup.app == "SAVI" else {
            throw CocoaError(.fileReadCorruptFile)
        }
        try restoreBackup(backup)
    }

    private func restoreBackupPayload(_ payload: SaviArchiveImportPayload) throws {
        switch payload {
        case .legacyJSON(let backup, _):
            try restoreBackup(backup)
        case .fullArchive(let package, _):
            try restoreArchivePackage(package)
        }
    }

    private func restoreBackup(_ backup: SaviBackup) throws {
        try storage.clearAssetsDirectory()
        let restoredAssets = try backup.assets.map { try storage.writeBackupAsset($0) }
        applyRestoredLibrary(
            folders: backup.folders,
            items: backup.items,
            assets: restoredAssets,
            restoredPrefs: backup.prefs,
            restoredPublicProfile: backup.publicProfile,
            restoredFriends: backup.friends,
            restoredFriendLinks: backup.friendLinks,
            restoredFolderLearning: backup.folderLearning ?? []
        )
    }

    private func restoreArchivePackage(_ package: SaviArchivePackage) throws {
        try storage.clearAssetsDirectory()
        let restoredAssets = try package.library.assets.map { record in
            guard let data = package.assetData[record.id] else {
                throw CocoaError(.fileReadNoSuchFile)
            }
            return try storage.writeArchiveAsset(record, data: data)
        }
        applyRestoredLibrary(
            folders: package.library.folders,
            items: package.library.items,
            assets: restoredAssets,
            restoredPrefs: package.library.prefs,
            restoredPublicProfile: package.library.publicProfile,
            restoredFriends: package.library.friends,
            restoredFriendLinks: package.library.friendLinks,
            restoredFolderLearning: package.library.folderLearning
        )
    }

    private func applyRestoredLibrary(
        folders restoredFolders: [SaviFolder],
        items restoredItems: [SaviItem],
        assets restoredAssets: [SaviAsset],
        restoredPrefs: SaviPrefs?,
        restoredPublicProfile: SaviPublicProfile?,
        restoredFriends: [SaviFriend]?,
        restoredFriendLinks: [SaviSharedLink]?,
        restoredFolderLearning: [SAVIFolderLearningSignal]
    ) {
        folders = SaviSeeds.withSeedDefaults(restoredFolders)
        items = restoredItems
        assets = restoredAssets
        if var importedPrefs = restoredPrefs {
            importedPrefs.onboarded = true
            importedPrefs.migrationComplete = true
            Self.normalizeHomePresentationPreferences(&importedPrefs)
            Self.syncPairedFolderPreferences(&importedPrefs)
            importedPrefs.exploreScope = ExploreScope.visibleScope(for: importedPrefs.exploreScope).rawValue
            prefs = importedPrefs
        } else {
            prefs.onboarded = true
            prefs.migrationComplete = true
            Self.normalizeHomePresentationPreferences(&prefs)
            Self.syncPairedFolderPreferences(&prefs)
            prefs.exploreScope = ExploreScope.visibleScope(for: prefs.exploreScope).rawValue
        }
        if let restoredPublicProfile {
            publicProfile = restoredPublicProfile
        }
        if !SaviReleaseGate.socialFeaturesEnabled {
            publicProfile.isLinkSharingEnabled = false
            prefs.publishedPublicLinkIds = []
        }
        if let restoredFriends {
            friends = restoredFriends
        }
        if let restoredFriendLinks {
            friendLinks = restoredFriendLinks
        }
        folderLearningSignals = restoredFolderLearning
        exploreSeed = prefs.exploreSeed
        exploreScope = ExploreScope.visibleScope(for: prefs.exploreScope)
        persist()
    }

    func finishLegacyMigration(_ payload: LegacyMigrationPayload) async {
        if prefs.migrationComplete {
            finishLegacySeedRefresh(payload)
            return
        }

        let currentSeedIds = Set(SaviSeeds.items.map(\.id))
        let existingPersonalItems = items.filter { item in
            item.demo != true && !currentSeedIds.contains(item.id)
        }
        let existingPersonalAssetIds = Set(existingPersonalItems.compactMap(\.assetId))
        let existingPersonalAssets = assets.filter { existingPersonalAssetIds.contains($0.id) }

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
                items = mergeImportedItems(legacyItems, preserving: existingPersonalItems)
                assets = mergeAssets(migratedAssets, preserving: existingPersonalAssets)
                migrated = true
            }

            if !migrated,
               !payload.demoSuppressed,
               let seedStorageJSON = payload.seedStorageJSON,
               let data = seedStorageJSON.data(using: .utf8),
               let legacySeeds = try? JSONDecoder().decode(LegacyStoredState.self, from: data),
               let seedItems = legacySeeds.items,
                !seedItems.isEmpty {
                folders = SaviSeeds.refreshingDefaultFolderPresentation(SaviSeeds.withSeedDefaults(legacySeeds.folders ?? folders))
                let sampleItems = SaviReleaseGate.demoLibraryEnabled ? SaviSeeds.items : seedItems
                items = mergeImportedItems(sampleItems, preserving: existingPersonalItems)
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

        let personalItems = items.filter { $0.demo != true }
        folders = SaviSeeds.refreshingDefaultFolderPresentation(SaviSeeds.withSeedDefaults(folders))
        items = SaviSeeds.items + personalItems
        prefs.legacySeedVersion = Self.currentLegacySeedVersion
        persist()
        toast = "Sample library refreshed."
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
            NSLog("[SAVI Native] imported pending share %@ as item %@", share.id, item.id)
            scheduleAppleIntelligenceRefinement(id: item.id, allowFolderChange: usesAutoFolder && !SaviText.looksSensitive("\(item.title) \(item.itemDescription) \(item.url ?? "")"))
            if let urlString = item.url,
               let url = URL(string: urlString),
               url.scheme?.hasPrefix("http") == true {
                scheduleMetadataEnrichment(id: item.id, url: url, reason: "share-import")
            }
        }
        if importedCount > 0 {
            mergeShareSetupStateFromAppGroup(persistChanges: false)
            persist()
            isShareSetupReminderPresented = false
        }
        NSLog("[SAVI Native] imported %d pending share(s) in %.3fs", importedCount, Date().timeIntervalSince(startedAt))
        refreshFolderDecisionHistory()
        scheduleSocialSyncIfNeeded()
        toast = pending.count == 1 ? "Shared item saved." : "\(pending.count) shared items saved."
    }

    func importSharedDeepLink(_ url: URL) async {
        if SAVIPasteboardShare.isHandoffURL(url) {
            await importPasteboardFallbackIfAvailable()
            return
        }

        guard let share = SAVIDeepLinkShare.pendingShare(from: url) else {
            NSLog("[SAVI Native] ignored unsupported deep link %@", url.absoluteString)
            return
        }
        guard !importedShareIds.contains(share.id) else {
            toast = "Already saved."
            selectedTab = .home
            return
        }

        let startedAt = Date()
        importedShareIds.insert(share.id)
        let folderSource = (share.folderSource ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let usesAutoFolder = share.folderId?.nilIfBlank == nil || folderSource != "manual"
        let item = await createItem(from: share)
        items.insert(item, at: 0)
        if usesAutoFolder { autoFolderItemIds.insert(item.id) }
        if !usesAutoFolder { learnFolderSelection(for: item) }
        recordShareExtensionCompletion(folderId: item.folderId)
        persist()
        selectedTab = .home
        refreshFolderDecisionHistory()
        scheduleSocialSyncIfNeeded()
        scheduleAppleIntelligenceRefinement(id: item.id, allowFolderChange: usesAutoFolder && !SaviText.looksSensitive("\(item.title) \(item.itemDescription) \(item.url ?? "")"))
        if let urlString = item.url,
           let itemURL = URL(string: urlString),
           itemURL.scheme?.hasPrefix("http") == true {
            scheduleMetadataEnrichment(id: item.id, url: itemURL, reason: "share-deeplink")
        }
        NSLog("[SAVI Native] imported deep link share %@ as item %@ in %.3fs", share.id, item.id, Date().timeIntervalSince(startedAt))
        toast = "Shared item saved."
    }

    func importPasteboardFallbackIfAvailable() async {
        guard let share = SAVIPasteboardShare.load() else { return }
        guard !importedShareIds.contains(share.id),
              !items.contains(where: { $0.id == share.id })
        else {
            SAVIPasteboardShare.clearIfCurrent(share)
            return
        }

        let startedAt = Date()
        importedShareIds.insert(share.id)
        let folderSource = (share.folderSource ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let usesAutoFolder = share.folderId?.nilIfBlank == nil || folderSource != "manual"
        let item = await createItem(from: share)
        items.insert(item, at: 0)
        if usesAutoFolder { autoFolderItemIds.insert(item.id) }
        if !usesAutoFolder { learnFolderSelection(for: item) }
        recordShareExtensionCompletion(folderId: item.folderId)
        persist()
        selectedTab = .home
        refreshFolderDecisionHistory()
        scheduleSocialSyncIfNeeded()
        scheduleAppleIntelligenceRefinement(id: item.id, allowFolderChange: usesAutoFolder && !SaviText.looksSensitive("\(item.title) \(item.itemDescription) \(item.url ?? "")"))
        if let urlString = item.url,
           let itemURL = URL(string: urlString),
           itemURL.scheme?.hasPrefix("http") == true {
            scheduleMetadataEnrichment(id: item.id, url: itemURL, reason: "share-pasteboard")
        }
        SAVIPasteboardShare.clearIfCurrent(share)
        NSLog("[SAVI Native] imported pasteboard fallback share %@ as item %@ in %.3fs", share.id, item.id, Date().timeIntervalSince(startedAt))
        toast = "Shared item saved."
    }

    private func mergeImportedItems(_ imported: [SaviItem], preserving personalItems: [SaviItem]) -> [SaviItem] {
        guard !personalItems.isEmpty else { return imported }
        var seen = Set(imported.map(\.id))
        let uniquePersonal = personalItems.filter { seen.insert($0.id).inserted }
        return uniquePersonal + imported
    }

    private func mergeAssets(_ imported: [SaviAsset], preserving personalAssets: [SaviAsset]) -> [SaviAsset] {
        guard !personalAssets.isEmpty else { return imported }
        var seen = Set(imported.map(\.id))
        return imported + personalAssets.filter { seen.insert($0.id).inserted }
    }

    func refreshStaleMetadata(limit: Int = 20) async {
        let availableSlots = max(0, Self.maxMetadataEnrichmentTasks - metadataEnrichmentInFlightIds.count)
        guard availableSlots > 0 else { return }

        let candidates = items
            .filter(needsMetadataRefresh)
            .filter { shouldAttemptMetadataRefresh($0) }
            .filter { !metadataEnrichmentInFlightIds.contains($0.id) }
            .prefix(min(limit, availableSlots))
            .compactMap { item -> (String, URL)? in
                guard let urlString = item.url,
                      let url = URL(string: urlString),
                      url.scheme?.hasPrefix("http") == true
                else { return nil }
                return (item.id, url)
            }

        guard !candidates.isEmpty else { return }
        NSLog("[SAVI Native] scheduling metadata refresh for %d stale item(s)", candidates.count)
        for candidate in candidates {
            scheduleMetadataEnrichment(id: candidate.0, url: candidate.1, reason: "stale")
        }
    }

    private func scheduleMetadataEnrichment(id: String, url: URL, reason: String) {
        guard !metadataEnrichmentInFlightIds.contains(id),
              metadataEnrichmentInFlightIds.count < Self.maxMetadataEnrichmentTasks
        else { return }

        metadataEnrichmentInFlightIds.insert(id)
        Task { [weak self] in
            let startedAt = Date()
            await self?.enrichItem(id: id, url: url)
            await MainActor.run { [weak self] in
                self?.metadataEnrichmentInFlightIds.remove(id)
                NSLog("[SAVI Native] metadata %@ task for %@ finished in %.3fs", reason, id, Date().timeIntervalSince(startedAt))
            }
            await self?.refreshStaleMetadata(limit: 1)
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
        let prefersLiveMetadata = item.metadataPolicy == .liveMetadata

        if prefersLiveMetadata, let title = metadata.title?.nilIfBlank {
            item.title = title
        } else if SaviText.shouldReplaceTitle(current: item.title, fetched: metadata.title) {
            item.title = metadata.title ?? item.title
        }
        if prefersLiveMetadata, let description = metadata.description?.nilIfBlank {
            item.itemDescription = description
        } else if shouldReplaceDescription(current: item.itemDescription, fetched: metadata.description, url: url),
           let description = metadata.description?.nilIfBlank {
            item.itemDescription = description
        }
        if prefersLiveMetadata, let imageURL = metadata.imageURL?.nilIfBlank {
            item.thumbnail = imageURL
        } else if item.thumbnail?.nilIfBlank == nil, let imageURL = metadata.imageURL?.nilIfBlank {
            item.thumbnail = imageURL
        }
        if item.thumbnail?.nilIfBlank != nil {
            item.thumbnailRetryCount = 0
            item.thumbnailLastAttemptAt = nil
        }
        if prefersLiveMetadata {
            item.source = metadata.provider?.nilIfBlank ?? SaviText.sourceLabel(for: url.absoluteString, fallback: item.source)
        } else if item.source.isEmpty || item.source == "Web" || item.source == "Share Extension" {
            item.source = metadata.provider?.nilIfBlank ?? SaviText.sourceLabel(for: url.absoluteString, fallback: item.source)
        }
        if prefersLiveMetadata {
            item.type = metadata.type ?? item.type
        } else if item.type == .link || item.type == .article {
            item.type = metadata.type ?? item.type
        }
        item.tags = SaviText.dedupeTags(item.tags + metadata.tags)
        if prefersLiveMetadata {
            item.metadataPolicy = nil
        }
        if item.folderId == "f-random" || item.folderId.isEmpty {
            item.folderId = guessFolderId(
                title: item.title,
                description: item.itemDescription,
                url: item.url,
                tags: item.tags,
                type: item.type.rawValue,
                source: item.source,
                fileName: item.assetName,
                mimeType: item.assetMime,
                context: "Metadata"
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

        if item.metadataPolicy == .liveMetadata {
            return true
        }

        let normalizedTitle = item.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let genericTitle = normalizedTitle.isEmpty ||
            SaviText.isGenericFetchedTitle(normalizedTitle) ||
            normalizedTitle == "saved link" ||
            normalizedTitle == "shared item" ||
            normalizedTitle == "youtube video" ||
            normalizedTitle.hasPrefix("http") ||
            normalizedTitle.hasSuffix(" save")
        let platformLink = isMajorPlatformURL(url)
        let expectsThumbnail = expectsRemoteThumbnail(item, url: url)
        let missingThumbnail = item.thumbnail?.nilIfBlank == nil && expectsThumbnail
        let genericDescription = item.itemDescription.nilIfBlank == nil ||
            SaviText.isGenericMetadataDescription(item.itemDescription) ||
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
        guard let fetched = fetched?.nilIfBlank,
              !SaviText.isGenericMetadataDescription(fetched)
        else { return false }
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return trimmed.localizedCaseInsensitiveContains(url.absoluteString) ||
            SaviText.isGenericMetadataDescription(trimmed) ||
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
        context: String = "Auto Folder"
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

    private func classificationInput(for link: SaviSharedLink) -> SAVIFolderClassificationInput {
        SAVIFolderClassificationInput(
            title: link.title,
            description: link.itemDescription,
            url: link.url,
            type: link.type.rawValue,
            source: link.source,
            fileName: nil,
            mimeType: nil,
            tags: link.tags
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

    private func recordFolderDecision(
        input: SAVIFolderClassificationInput,
        result: SAVIFolderClassification,
        context: String,
        source: SAVIFolderDecisionSource? = nil,
        outcome: SAVIIntelligenceDecisionOutcome? = nil,
        aiFolderId: String? = nil,
        aiConfidence: Int? = nil,
        aiReason: String? = nil,
        vetoReason: String? = nil
    ) {
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
            "Unknown Folder"
        let aiFolderName = aiFolderId.flatMap { id in
            folder(for: id)?.name ??
                SAVIFolderClassifier.defaultFolderOptions.first(where: { $0.id == id })?.name
        }
        let decision = SAVIFolderDecisionRecord(
            id: UUID().uuidString,
            title: safeTitle,
            folderId: result.folderId,
            folderName: folderName,
            confidence: result.confidence,
            reason: result.reason,
            context: context,
            createdAt: Date().timeIntervalSince1970,
            source: source ?? SAVIFolderClassifier.decisionSource(for: result, context: context),
            outcome: outcome,
            aiFolderId: aiFolderId,
            aiFolderName: aiFolderName,
            aiConfidence: aiConfidence,
            aiReason: aiReason,
            vetoReason: vetoReason
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
                guard items[index].demo != true else { continue }
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
            guard item.demo != true else { continue }
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
        let response = await intelligenceService.classify(
            item: item,
            folders: candidateFolders,
            learningSignals: folderLearningSignals
        )
        guard let currentIndex = items.firstIndex(where: { $0.id == id }) else { return }

        var next = items[currentIndex]
        let originalFolderId = next.folderId
        let sensitive = SaviText.looksSensitive("\(next.title) \(next.itemDescription) \(next.url ?? "")")
        let localResult = localFolderClassification(for: next)
        let localInput = classificationInput(for: next)

        guard let result = response.classification else {
            recordFolderDecision(
                input: localInput,
                result: localResult,
                context: "Apple Intelligence",
                source: .appleIntelligence,
                outcome: response.outcome,
                vetoReason: response.message
            )
            return
        }

        if let folderId = result.folderId,
           candidateFolders.contains(where: { $0.id == folderId }) {
            if sensitive, folderId != "f-private-vault" {
                next.folderId = "f-private-vault"
                recordFolderDecision(
                    input: localInput,
                    result: .init(folderId: next.folderId, confidence: 100, reason: "private-guardrail-after-ai"),
                    context: "Apple Intelligence",
                    source: .guardrail,
                    outcome: .vetoed,
                    aiFolderId: folderId,
                    aiConfidence: result.confidence,
                    aiReason: result.reason,
                    vetoReason: "Private guardrail overrode Apple Intelligence."
                )
            } else if !allowFolderChange && folderId != originalFolderId {
                recordFolderDecision(
                    input: localInput,
                    result: localResult,
                    context: "Apple Intelligence",
                    source: .appleIntelligence,
                    outcome: .vetoed,
                    aiFolderId: folderId,
                    aiConfidence: result.confidence,
                    aiReason: result.reason,
                    vetoReason: "Manual folder choice is protected."
                )
            } else {
                let acceptance = SAVIFolderClassifier.intelligenceAcceptance(
                    folderId,
                    localResult: localResult,
                    input: localInput,
                    aiConfidence: result.confidence,
                    aiReason: result.reason
                )
                if allowFolderChange, acceptance.accepted {
                    next.folderId = folderId
                    recordFolderDecision(
                        input: localInput,
                        result: .init(
                            folderId: folderId,
                            confidence: result.confidence ?? localResult.confidence,
                            reason: result.reason?.nilIfBlank ?? "apple-intelligence"
                        ),
                        context: "Apple Intelligence",
                        source: .appleIntelligence,
                        outcome: .accepted,
                        aiFolderId: folderId,
                        aiConfidence: result.confidence,
                        aiReason: result.reason
                    )
                } else {
                    recordFolderDecision(
                        input: localInput,
                        result: localResult,
                        context: "Apple Intelligence",
                        source: .appleIntelligence,
                        outcome: .vetoed,
                        aiFolderId: folderId,
                        aiConfidence: result.confidence,
                        aiReason: result.reason,
                        vetoReason: acceptance.vetoReason ?? "Local rules kept the existing folder."
                    )
                }
            }
        } else if result.folderId != nil {
            recordFolderDecision(
                input: localInput,
                result: localResult,
                context: "Apple Intelligence",
                source: .appleIntelligence,
                outcome: .vetoed,
                aiFolderId: result.folderId,
                aiConfidence: result.confidence,
                aiReason: result.reason,
                vetoReason: "Apple Intelligence returned a folder that is not available."
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

    private func sourceGroupKey(for item: SaviItem) -> String {
        let key = sourceKey(for: item)
        let label = sourceLabel(for: key)
        let haystack = [
            key,
            label,
            item.url ?? "",
            item.source,
            item.assetName ?? "",
            item.assetMime ?? "",
            item.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()

        if haystack.contains("youtube") || haystack.contains("youtu.be") { return "youtube" }
        if haystack.contains("tiktok") { return "tiktok" }
        if haystack.contains("instagram") { return "instagram" }
        if haystack.contains("twitter") || haystack.contains("x.com") || key == "x" { return "x-twitter" }
        if haystack.contains("reddit") { return "reddit" }
        if haystack.contains("pinterest") { return "pinterest" }
        if haystack.contains("spotify") || haystack.contains("soundcloud") || isAudio(item) { return "spotify-audio" }
        if haystack.contains("maps") || haystack.contains("google-maps") || haystack.contains("apple-maps") || item.type == .place { return "maps" }
        if haystack.contains("clipboard") || haystack.contains("paste") || item.source.localizedCaseInsensitiveContains("clipboard") { return "clipboard-paste" }
        if haystack.contains("device") || haystack.contains("files") || haystack.contains("photos") || (item.url?.nilIfBlank == nil && item.type == .file) { return "device-files" }
        return "web"
    }

    private func matchesSourceFilter(_ item: SaviItem, filter: String) -> Bool {
        guard filter != "all" else { return true }
        if SaviSearchSourceGroup.group(for: filter) != nil {
            return sourceGroupKey(for: item) == filter
        }
        return sourceKey(for: item) == filter
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
        case "audio":
            return isAudio(item)
        case "screenshot":
            return isScreenshot(item)
        case "docs":
            return isDocument(item)
        case "pdf":
            return isPDF(item)
        case "document":
            return isDocument(item) && !isPDF(item)
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
        case .yesterday:
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return false }
            return calendar.isDate(date, inSameDayAs: yesterday)
        case .last7Days:
            guard let start = calendar.date(byAdding: .day, value: -7, to: now) else { return true }
            return date >= start
        case .month:
            guard let start = calendar.dateInterval(of: .month, for: now)?.start else { return true }
            return date >= start
        case .last30Days:
            guard let start = calendar.date(byAdding: .day, value: -30, to: now) else { return true }
            return date >= start
        case .thisYear:
            guard let start = calendar.dateInterval(of: .year, for: now)?.start else { return true }
            return date >= start
        case .custom:
            let start = calendar.startOfDay(for: min(customSearchStartDate, customSearchEndDate))
            let endSeed = max(customSearchStartDate, customSearchEndDate)
            guard let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: endSeed)) else {
                return date >= start
            }
            return date >= start && date <= end
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
        case .video:
            return item.type == .video
        case .audio:
            return isAudio(item)
        case .pdf:
            return isPDF(item)
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
        if isAudio(item) { return "Audio" }
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

        if documentSubtypeFilter != SearchDocumentSubtype.all.rawValue {
            append(documentSubtypeTitle(for: documentSubtypeFilter))
        } else if typeFilter != "all" || !needles.isEmpty {
            append(primaryKindLabel(for: item))
        }
        if sourceFilter != "all" || needles.contains(where: { source.lowercased().contains($0) }) {
            append(source)
        }
        if let folderName,
           folderFilter != "f-all" || needles.contains(where: { folderName.lowercased().contains($0) }) {
            append("Folder: \(folderName)")
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

    private func isDocument(_ item: SaviItem) -> Bool {
        guard item.type == .file else { return false }
        let haystack = documentHaystack(for: item)

        if isPDF(item) { return true }
        if haystack.contains("application/msword") ||
            haystack.contains("officedocument.wordprocessingml") ||
            haystack.contains("officedocument.spreadsheetml") ||
            haystack.contains("officedocument.presentationml") ||
            haystack.contains("application/vnd.apple.pages") ||
            haystack.contains("application/rtf") ||
            haystack.contains("text/plain") ||
            haystack.contains("spreadsheet") ||
            haystack.contains("presentation") ||
            haystack.contains("word") ||
            haystack.contains("pages") {
            return true
        }

        let extensions = fileExtensionTokens(for: item)
        return extensions.contains { token in
            ["doc", "docx", "pages", "rtf", "txt", "md", "csv", "xls", "xlsx", "numbers", "ppt", "pptx", "key"].contains(token)
        }
    }

    private func matchesDocumentSubtype(_ item: SaviItem, subtype: String) -> Bool {
        guard let option = SearchDocumentSubtype(rawValue: subtype), isDocument(item) else { return false }
        let haystack = documentHaystack(for: item)
        let extensions = fileExtensionTokens(for: item)
        switch option {
        case .all:
            return true
        case .pdf:
            return isPDF(item)
        case .word:
            return haystack.contains("application/msword") ||
                haystack.contains("officedocument.wordprocessingml") ||
                haystack.contains("application/vnd.apple.pages") ||
                haystack.contains("word") ||
                haystack.contains("pages") ||
                extensions.contains { ["doc", "docx", "pages"].contains($0) }
        case .spreadsheet:
            return haystack.contains("officedocument.spreadsheetml") ||
                haystack.contains("spreadsheet") ||
                haystack.contains("text/csv") ||
                extensions.contains { ["csv", "xls", "xlsx", "numbers"].contains($0) }
        case .presentation:
            return haystack.contains("officedocument.presentationml") ||
                haystack.contains("presentation") ||
                extensions.contains { ["ppt", "pptx", "key"].contains($0) }
        case .text:
            return haystack.contains("application/rtf") ||
                haystack.contains("text/plain") ||
                haystack.contains("text/markdown") ||
                extensions.contains { ["txt", "md", "rtf"].contains($0) }
        }
    }

    private func documentSubtypeSearchTokens(for item: SaviItem) -> [String] {
        SearchDocumentSubtype.allCases
            .filter { $0 != .all && matchesDocumentSubtype(item, subtype: $0.rawValue) }
            .flatMap { subtype in
                switch subtype {
                case .all:
                    return [] as [String]
                case .pdf:
                    return ["pdf"]
                case .word:
                    return ["word", "doc", "docx", "pages"]
                case .spreadsheet:
                    return ["spreadsheet", "sheet", "csv", "xls", "xlsx", "numbers"]
                case .presentation:
                    return ["presentation", "slides", "ppt", "pptx", "keynote"]
                case .text:
                    return ["text", "txt", "md", "rtf"]
                }
            }
    }

    private func documentHaystack(for item: SaviItem) -> String {
        [
            item.assetName ?? "",
            item.assetMime ?? "",
            item.url ?? "",
            item.title,
            item.itemDescription,
            item.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()
    }

    private func fileExtensionTokens(for item: SaviItem) -> [String] {
        let candidates = [
            item.assetName,
            item.url,
            item.title
        ].compactMap { $0 }
        let extensions = candidates.compactMap { value -> String? in
            let ext = URL(fileURLWithPath: value).pathExtension.lowercased()
            return ext.isEmpty ? nil : ext
        }
        return Array(Set(extensions)).sorted()
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

    private func isAudio(_ item: SaviItem) -> Bool {
        let haystack = [
            item.assetName ?? "",
            item.assetMime ?? "",
            item.url ?? "",
            item.source,
            item.title,
            item.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        return haystack.contains("audio/") ||
            haystack.contains("podcast") ||
            haystack.contains("spotify") ||
            haystack.contains("soundcloud") ||
            haystack.contains("music") ||
            haystack.contains(".mp3") ||
            haystack.contains(".m4a") ||
            haystack.contains(".wav") ||
            haystack.contains(".aac")
    }

    private func syncFoldersToShareExtension(force: Bool = false) {
        let shared = folders
            .filter { $0.id != "f-all" }
            .map { folder in
                SharedFolder(
                    id: folder.id,
                    name: folder.name,
                    color: folder.color,
                    system: folder.system,
                    symbolName: folder.symbolName,
                    order: folder.order,
                    isPublic: SaviReleaseGate.socialFeaturesEnabled && folder.isPublic
                )
            }
        let folderSignature = shared
            .sorted { lhs, rhs in lhs.order == rhs.order ? lhs.name < rhs.name : lhs.order < rhs.order }
            .map { "\($0.id)|\($0.name)|\($0.color ?? "")|\($0.system)|\($0.symbolName ?? "")|\($0.order)|\($0.isPublic)" }
            .joined(separator: "\n")
        if force || folderSignature != lastSharedFolderSignature {
            try? shareStore.saveFolders(shared)
            lastSharedFolderSignature = folderSignature
        }

        let learningSignature = folderLearningSignals
            .sorted { $0.id < $1.id }
            .map { "\($0.id)|\($0.folderId)|\($0.phrase)|\($0.weight)|\($0.uses)|\($0.updatedAt)" }
            .joined(separator: "\n")
        if force || learningSignature != lastFolderLearningSignature {
            try? shareStore.saveFolderLearning(folderLearningSignals)
            lastFolderLearningSignature = learningSignature
        }
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
    var confidence: Int?
    var reason: String?
    var tags: [String]
}

private struct SaviIntelligenceResponse {
    var classification: SaviIntelligenceClassification?
    var outcome: SAVIIntelligenceDecisionOutcome?
    var message: String?
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
    ) async -> SaviIntelligenceResponse {
        guard !folders.isEmpty else {
            return .init(classification: nil, outcome: .skipped, message: "No folders available.")
        }
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await classifyWithFoundationModels(item: item, folders: folders, learningSignals: learningSignals)
        }
#endif
        return .init(
            classification: nil,
            outcome: .unavailable,
            message: "Requires iOS 26 and Apple Intelligence."
        )
    }

#if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func classifyWithFoundationModels(
        item: SaviItem,
        folders: [SaviFolder],
        learningSignals: [SAVIFolderLearningSignal]
    ) async -> SaviIntelligenceResponse {
        let model = SystemLanguageModel(useCase: .contentTagging)
        guard case .available = model.availability else {
            NSLog("[SAVI Native] Apple Intelligence unavailable for item classification: %@", String(describing: model.availability))
            return .init(
                classification: nil,
                outcome: .unavailable,
                message: "Apple Intelligence unavailable: \(String(describing: model.availability))"
            )
        }

        return await withTaskGroup(of: SaviIntelligenceResponse.self) { group in
            group.addTask {
                let classification = await requestClassification(item: item, folders: folders, learningSignals: learningSignals, model: model)
                return .init(
                    classification: classification,
                    outcome: classification == nil ? .failed : nil,
                    message: classification == nil ? "Apple Intelligence returned no usable JSON." : nil
                )
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                return .init(classification: nil, outcome: .timedOut, message: "Apple Intelligence timed out after 2.5 seconds.")
            }

            while let result = await group.next() {
                group.cancelAll()
                return result
            }
            return .init(classification: nil, outcome: .failed, message: "Apple Intelligence did not return.")
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
            The JSON must match: {"folderId":"one-folder-id","confidence":82,"reason":"short reason","tags":["tag-one","tag-two"]}.
            Choose exactly one folderId from the allowed folders.
            Confidence is 0-100. Use 80+ only when the folder is clearly correct.
            Tags must be lowercase, short hashtags without #, and useful for search.
            Everything Else is only for low-confidence leftovers. It is not a personality bucket.
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
        let folderGuidance = SAVIFolderClassifier.folderGuidanceLines(for: folders.map { SAVIFolderOption(id: $0.id, name: $0.name) })
            .joined(separator: "\n")
        let description = String(item.itemDescription.prefix(1_200))
        let url = String((item.url ?? "").prefix(500))
        let existingTags = item.tags.prefix(8).joined(separator: ", ")
        let folderOptions = folders.map { SAVIFolderOption(id: $0.id, name: $0.name) }
        let localInput = SAVIFolderClassificationInput(
            title: item.title,
            description: item.itemDescription,
            url: item.url,
            type: item.type.rawValue,
            source: item.source,
            fileName: item.assetName,
            mimeType: item.assetMime,
            tags: item.tags
        )
        let localCandidate = SAVIFolderClassifier.classify(
            localInput,
            availableFolders: folderOptions,
            learningSignals: learningSignals
        )
        let localName = folders.first(where: { $0.id == localCandidate.folderId })?.name ?? localCandidate.folderId
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

        Folder guidance:
        \(folderGuidance)

        Local classifier candidate:
        \(localCandidate.folderId): \(localName) · confidence \(localCandidate.confidence) · \(localCandidate.reason)
        \(examplesBlock)

        Item:
        title: \(item.title)
        description: \(description)
        url: \(url)
        source: \(item.source)
        type: \(item.type.rawValue)
        existing tags: \(existingTags)

        Use exactly one folderId from the folder choices.
        Life Admin is for useful non-secret admin/reference saves like door codes, Wi-Fi notes, travel access, templates, contracts, receipts, and account recovery notes.
        Only choose Private Vault for genuinely private documents, credentials, IDs, receipts, medical, insurance, banking, or tax material.
        Actual private IDs, passwords, banking, medical, tax, or credential scans must stay in Private Vault, not Life Admin.
        Entertainment, trailers, news, and fandom posts are not private just because their title says secret, leaked, vault, or password.
        Entertainment videos default to Watch / Read Later unless clearly comedy/meme, then Memes & Laughs.
        Never choose Science Finds unless the item has real science, space, research, or discovery intent.
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
            decoded.confidence = decoded.confidence.map { max(0, min($0, 100)) }
            decoded.reason = decoded.reason?.nilIfBlank.map { String($0.prefix(140)) }
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
    case friendLinkDetail(SaviSharedLink)
    case friendLinkSave(SaviSharedLink)

    var id: String {
        switch self {
        case .save: return "save"
        case .folderEditor(let folder): return "folder-\(folder?.id ?? "new")"
        case .publicProfile: return "public-profile"
        case .friendProfile(let friend): return "friend-\(friend.id)"
        case .friendLinkDetail(let link): return "friend-link-detail-\(link.id)"
        case .friendLinkSave(let link): return "friend-link-save-\(link.id)"
        }
    }
}

private enum SaviDeferredPresentation {
    case sheet(SaviSheet)
    case item(SaviItem)
    case editItem(SaviItem)
    case quickLook(URL)
    case web(URL)
}

struct SaviClipboardDraft: Identifiable {
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

enum SaviClipboardReader {
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

    func writeArchiveAsset(_ asset: SaviArchiveAssetRecord, data: Data) throws -> SaviAsset {
        let type = asset.type.nilIfBlank ?? "application/octet-stream"
        let name = asset.name.nilIfBlank ?? "asset.\(SaviText.fileExtension(forMimeType: type))"
        let fileName = safeAssetFileName(id: asset.id, preferredName: name)
        let destination = try assetsDirectoryURL().appendingPathComponent(fileName)
        try data.write(to: destination, options: .atomic)
        return SaviAsset(
            id: asset.id,
            name: name,
            type: type,
            size: Int64(data.count),
            fileName: fileName,
            createdAt: asset.createdAt
        )
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

    func assetData(for asset: SaviAsset) throws -> Data? {
        guard let url = assetURL(for: asset),
              fileManager.fileExists(atPath: url.path)
        else { return nil }
        return try Data(contentsOf: url)
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

    func buildBackup(
        folders: [SaviFolder],
        items: [SaviItem],
        assets: [SaviAsset],
        prefs: SaviPrefs? = nil,
        publicProfile: SaviPublicProfile? = nil,
        friends: [SaviFriend]? = nil,
        friendLinks: [SaviSharedLink]? = nil,
        folderLearning: [SAVIFolderLearningSignal]
    ) throws -> SaviBackup {
        let backupAssets: [SaviBackupAsset] = try assets.compactMap { asset in
            guard let data = try assetData(for: asset) else { return nil }
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
            prefs: prefs,
            publicProfile: publicProfile,
            friends: friends,
            friendLinks: friendLinks,
            folderLearning: folderLearning
        )
    }

    func buildFullArchive(
        folders: [SaviFolder],
        items: [SaviItem],
        assets: [SaviAsset],
        prefs: SaviPrefs,
        publicProfile: SaviPublicProfile?,
        friends: [SaviFriend],
        friendLinks: [SaviSharedLink],
        folderLearning: [SAVIFolderLearningSignal]
    ) throws -> Data {
        try SaviArchiveExporter.makeArchive(
            folders: folders,
            items: items,
            assets: assets,
            prefs: prefs,
            publicProfile: publicProfile,
            friends: friends,
            friendLinks: friendLinks,
            folderLearning: folderLearning,
            assetData: { asset in
                try assetData(for: asset)
            }
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
            .filter { !$0.isEmpty && titleQualityScore($0) > 0 }
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
