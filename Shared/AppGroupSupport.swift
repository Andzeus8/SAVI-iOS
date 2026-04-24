import Foundation

enum SAVISharedContainer {
    static let appGroupIdentifier = "group.com.savi.shared"
    static let pendingSharesDirectory = "pending_shares"
    static let pendingAssetsDirectory = "pending_assets"
    static let foldersFileName = "folders.json"
    static let recentFoldersFileName = "recent_folders.json"
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
    var tags: [String]?
    var needsMetadata: Bool?

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
        case tags
        case needsMetadata = "needs_metadata"
    }
}

struct SharedFolder: Codable, Identifiable {
    var id: String
    var name: String
    var color: String?
    var image: String?
    var system: Bool
    var symbolName: String?
    var order: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case image
        case system
        case symbolName = "symbol_name"
        case order
    }
}

struct RecentFolder: Codable, Identifiable {
    var id: String
    var name: String
    var color: String?
    var image: String?
    var symbolName: String?
    var lastUsedAt: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case image
        case symbolName = "symbol_name"
        case lastUsedAt = "last_used_at"
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

    func recentFoldersFileURL() throws -> URL {
        try containerURL().appendingPathComponent(SAVISharedContainer.recentFoldersFileName)
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

    func saveRecentFolders(_ folders: [RecentFolder]) throws {
        let fileURL = try recentFoldersFileURL()
        let normalized = Array(
            folders
                .sorted { lhs, rhs in
                    if lhs.lastUsedAt == rhs.lastUsedAt {
                        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                    }
                    return lhs.lastUsedAt > rhs.lastUsedAt
                }
                .prefix(8)
        )
        let data = try encoder.encode(normalized)
        try data.write(to: fileURL, options: .atomic)
    }

    func loadRecentFolders() -> [RecentFolder] {
        guard let fileURL = try? recentFoldersFileURL(),
              let data = try? Data(contentsOf: fileURL),
              let folders = try? decoder.decode([RecentFolder].self, from: data)
        else {
            return []
        }

        return folders.sorted { lhs, rhs in
            if lhs.lastUsedAt == rhs.lastUsedAt {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.lastUsedAt > rhs.lastUsedAt
        }
    }

    func touchRecentFolder(id: String, timestamp: Double = Date().timeIntervalSince1970 * 1000) {
        let sharedFolders = loadFolders()
        let recentFolders = loadRecentFolders()

        let shared = sharedFolders.first(where: { $0.id == id })
        let fallbackName = shared?.name ?? "Folder"
        let fallbackColor = shared?.color
        let fallbackImage = shared?.image
        let fallbackSymbol = shared?.symbolName

        var merged = recentFolders.filter { $0.id != id }
        merged.insert(
            RecentFolder(
                id: id,
                name: fallbackName,
                color: fallbackColor,
                image: fallbackImage,
                symbolName: fallbackSymbol,
                lastUsedAt: timestamp
            ),
            at: 0
        )

        try? saveRecentFolders(merged)
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
