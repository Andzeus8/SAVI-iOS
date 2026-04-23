import Foundation

enum SAVISharedContainer {
    static let appGroupIdentifier = "group.com.savi.shared"
    static let pendingSharesDirectory = "pending_shares"
    static let pendingAssetsDirectory = "pending_assets"
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
