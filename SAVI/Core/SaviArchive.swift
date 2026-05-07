import Foundation
import UniformTypeIdentifiers
import SwiftUI

extension UTType {
    // Avoid filename-extension UTType lookup during root view construction. Older
    // iOS 17 devices have crashed inside LaunchServices while resolving custom
    // archive extensions at launch; broad data import keeps restore available.
    static let saviArchiveZip = UTType.data

    static let saviArchivePackage = UTType.data
}

struct SaviArchiveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }

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

enum SaviRestoreMode {
    case replaceAll
}

struct SaviArchiveManifest: Codable {
    var app: String
    var format: String
    var schemaVersion: Int
    var exportedAt: String
    var folderCount: Int
    var itemCount: Int
    var assetCount: Int
    var noteCount: Int
    var includesPrivateVault: Bool
    var includesSocialCache: Bool
    var warnings: [String]
    var assets: [SaviArchiveManifestAsset]
}

struct SaviArchiveManifestAsset: Codable {
    var id: String
    var path: String
    var size: Int64
    var checksum: String
}

struct SaviArchiveAssetRecord: Codable, Identifiable {
    var id: String
    var name: String
    var type: String
    var size: Int64
    var fileName: String
    var createdAt: Double
    var archivePath: String
    var checksum: String
}

struct SaviArchiveLibrary: Codable {
    var app: String
    var schemaVersion: Int
    var exportedAt: String
    var folders: [SaviFolder]
    var items: [SaviItem]
    var assets: [SaviArchiveAssetRecord]
    var prefs: SaviPrefs
    var publicProfile: SaviPublicProfile?
    var friends: [SaviFriend]
    var friendLinks: [SaviSharedLink]
    var folderLearning: [SAVIFolderLearningSignal]
}

struct SaviArchivePreview: Identifiable {
    let id = UUID()
    var formatName: String
    var exportedAt: String?
    var folderCount: Int
    var itemCount: Int
    var assetCount: Int
    var noteCount: Int
    var size: Int
    var includesPrivateVault: Bool
    var includesSocialCache: Bool

    var restoreMessage: String {
        var parts = [
            "\(itemCount) saves",
            "\(folderCount) folders",
            "\(assetCount) files",
            SaviText.formatBytes(Int64(size))
        ]
        if noteCount > 0 {
            parts.append("\(noteCount) notes")
        }
        if includesPrivateVault {
            parts.append("includes locked/private items")
        }
        if includesSocialCache {
            parts.append("includes local social cache")
        }
        let dateText = exportedAt.map { " Exported \($0)." } ?? ""
        return "\(formatName): \(parts.joined(separator: " · ")).\(dateText) This will replace the current SAVI library on this device."
    }
}

enum SaviArchiveImportPayload {
    case legacyJSON(SaviBackup, sourceSize: Int)
    case fullArchive(SaviArchivePackage, sourceSize: Int)

    var preview: SaviArchivePreview {
        switch self {
        case .legacyJSON(let backup, let sourceSize):
            let privateFolderIds = Set(backup.folders.filter { $0.locked || $0.id == "f-private-vault" }.map(\.id))
            let includesPrivate = !privateFolderIds.isEmpty && backup.items.contains { privateFolderIds.contains($0.folderId) }
            return SaviArchivePreview(
                formatName: "Compact JSON backup",
                exportedAt: backup.exportedAt,
                folderCount: backup.folders.count,
                itemCount: backup.items.count,
                assetCount: backup.assets.count,
                noteCount: backup.items.filter { SaviArchiveText.isNoteLike($0) }.count,
                size: sourceSize,
                includesPrivateVault: includesPrivate,
                includesSocialCache: (backup.friends?.isEmpty == false) || (backup.friendLinks?.isEmpty == false)
            )
        case .fullArchive(let package, let sourceSize):
            return SaviArchivePreview(
                formatName: "Full SAVI archive",
                exportedAt: package.manifest.exportedAt,
                folderCount: package.manifest.folderCount,
                itemCount: package.manifest.itemCount,
                assetCount: package.manifest.assetCount,
                noteCount: package.manifest.noteCount,
                size: sourceSize,
                includesPrivateVault: package.manifest.includesPrivateVault,
                includesSocialCache: package.manifest.includesSocialCache
            )
        }
    }
}

struct SaviArchivePackage {
    var manifest: SaviArchiveManifest
    var library: SaviArchiveLibrary
    var assetData: [String: Data]
}

enum SaviArchiveExporter {
    static let schemaVersion = 1

    static func makeArchive(
        folders: [SaviFolder],
        items: [SaviItem],
        assets: [SaviAsset],
        prefs: SaviPrefs,
        publicProfile: SaviPublicProfile?,
        friends: [SaviFriend],
        friendLinks: [SaviSharedLink],
        folderLearning: [SAVIFolderLearningSignal],
        assetData: (SaviAsset) throws -> Data?
    ) throws -> Data {
        let exportedAt = ISO8601DateFormatter().string(from: Date())
        let privateFolderIds = Set(folders.filter { $0.locked || $0.id == "f-private-vault" }.map(\.id))
        let includesPrivate = items.contains { privateFolderIds.contains($0.folderId) }
        let includesSocial = !friends.isEmpty || !friendLinks.isEmpty

        var entries: [SaviZipEntry] = []
        var assetRecords: [SaviArchiveAssetRecord] = []
        var manifestAssets: [SaviArchiveManifestAsset] = []

        for asset in assets.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) {
            guard let data = try assetData(asset) else { continue }
            let safeName = SaviArchiveText.safeFileName(asset.name, fallback: "asset.\(SaviText.fileExtension(forMimeType: asset.type))")
            let path = "assets/\(asset.id)-\(safeName)"
            let checksum = SaviCRC32.hex(data)
            entries.append(SaviZipEntry(path: path, data: data))
            assetRecords.append(
                SaviArchiveAssetRecord(
                    id: asset.id,
                    name: asset.name,
                    type: asset.type,
                    size: Int64(data.count),
                    fileName: asset.fileName,
                    createdAt: asset.createdAt,
                    archivePath: path,
                    checksum: checksum
                )
            )
            manifestAssets.append(
                SaviArchiveManifestAsset(
                    id: asset.id,
                    path: path,
                    size: Int64(data.count),
                    checksum: checksum
                )
            )
        }

        let library = SaviArchiveLibrary(
            app: "SAVI",
            schemaVersion: schemaVersion,
            exportedAt: exportedAt,
            folders: folders,
            items: items,
            assets: assetRecords,
            prefs: prefs,
            publicProfile: publicProfile,
            friends: friends,
            friendLinks: friendLinks,
            folderLearning: folderLearning
        )

        let notes = makeNotes(from: items, folders: folders)
        for note in notes {
            entries.append(SaviZipEntry(path: note.path, data: note.data))
        }

        let manifest = SaviArchiveManifest(
            app: "SAVI",
            format: "savi-full-archive",
            schemaVersion: schemaVersion,
            exportedAt: exportedAt,
            folderCount: folders.count,
            itemCount: items.count,
            assetCount: assetRecords.count,
            noteCount: notes.count,
            includesPrivateVault: includesPrivate,
            includesSocialCache: includesSocial,
            warnings: [
                "This archive may contain private SAVI content, locked folders, files, PDFs, images, notes, links, and local social cache.",
                "Keep it somewhere safe. Anyone with this file may be able to read the exported contents."
            ],
            assets: manifestAssets
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        entries.append(SaviZipEntry(path: "manifest.json", data: try encoder.encode(manifest)))
        entries.append(SaviZipEntry(path: "library.json", data: try encoder.encode(library)))
        entries.append(SaviZipEntry(path: "index.html", data: makeIndexHTML(items: items, folders: folders, assets: assetRecords)))
        entries.append(SaviZipEntry(path: "links.csv", data: makeCSV(items: items, folders: folders, assets: assetRecords)))

        return try SaviZipWriter.makeArchive(entries: entries.sorted { $0.path < $1.path })
    }

    private static func makeNotes(from items: [SaviItem], folders: [SaviFolder]) -> [(path: String, data: Data)] {
        let foldersById = Dictionary(uniqueKeysWithValues: folders.map { ($0.id, $0.name) })
        return items
            .filter(SaviArchiveText.isNoteLike)
            .sorted { $0.savedAt > $1.savedAt }
            .compactMap { item in
                let title = item.title.nilIfBlank ?? "Saved note"
                let fileName = "\(SaviArchiveText.safeFileName(title, fallback: "note"))-\(String(item.id.prefix(8))).md"
                let folder = foldersById[item.folderId] ?? "Folder"
                let body = [
                    "# \(title)",
                    "",
                    "- Folder: \(folder)",
                    "- Source: \(item.source)",
                    "- Saved: \(SaviArchiveText.displayDate(item.savedAt))",
                    item.url?.nilIfBlank.map { "- URL: \($0)" },
                    "",
                    item.itemDescription.nilIfBlank ?? item.url?.nilIfBlank ?? title
                ]
                    .compactMap { $0 }
                    .joined(separator: "\n")
                return ("notes/\(fileName)", Data(body.utf8))
            }
    }

    private static func makeIndexHTML(items: [SaviItem], folders: [SaviFolder], assets: [SaviArchiveAssetRecord]) -> Data {
        let foldersById = Dictionary(uniqueKeysWithValues: folders.map { ($0.id, $0.name) })
        let assetsById = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0) })
        let rows = items
            .sorted { $0.savedAt > $1.savedAt }
            .map { item -> String in
                let folder = SaviArchiveText.htmlEscaped(foldersById[item.folderId] ?? "Folder")
                let title = SaviArchiveText.htmlEscaped(item.title)
                let description = SaviArchiveText.htmlEscaped(item.itemDescription)
                let source = SaviArchiveText.htmlEscaped(item.readableSource ?? item.source)
                let tags = item.tags.prefix(8).map { "<span>#\(SaviArchiveText.htmlEscaped($0))</span>" }.joined()
                let url = item.url?.nilIfBlank
                let asset = item.assetId.flatMap { assetsById[$0] }
                let primaryLink = url ?? asset?.archivePath
                let linkHTML = primaryLink.map {
                    "<a href=\"\(SaviArchiveText.htmlAttributeEscaped($0))\">Open</a>"
                } ?? ""
                let assetHTML = asset.map {
                    "<a class=\"asset\" href=\"\(SaviArchiveText.htmlAttributeEscaped($0.archivePath))\">\(SaviArchiveText.htmlEscaped($0.name))</a>"
                } ?? ""
                return """
                <article class="item">
                  <div>
                    <p class="meta">\(folder) · \(SaviArchiveText.htmlEscaped(item.type.label)) · \(source) · \(SaviArchiveText.displayDate(item.savedAt))</p>
                    <h2>\(title)</h2>
                    <p>\(description)</p>
                    <div class="tags">\(tags)</div>
                    \(assetHTML)
                  </div>
                  <div class="open">\(linkHTML)</div>
                </article>
                """
            }
            .joined(separator: "\n")

        let html = """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>SAVI Archive</title>
          <style>
            :root { color-scheme: light dark; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #f3effb; color: #171126; }
            body { margin: 0; padding: 32px 18px; }
            main { max-width: 900px; margin: 0 auto; }
            header { margin-bottom: 24px; }
            h1 { font-size: clamp(40px, 8vw, 72px); line-height: .9; margin: 0 0 10px; letter-spacing: -.03em; }
            .item { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 18px; padding: 18px; margin: 12px 0; border: 1px solid rgba(64, 45, 98, .12); border-radius: 22px; background: rgba(255, 255, 255, .78); box-shadow: 0 10px 28px rgba(44, 31, 72, .08); }
            h2 { margin: 4px 0 8px; font-size: 22px; line-height: 1.12; }
            p { margin: 0; color: #5c536c; line-height: 1.45; }
            .meta { font-size: 13px; font-weight: 700; color: #786b92; text-transform: uppercase; letter-spacing: .04em; }
            .tags { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 12px; }
            .tags span { padding: 5px 8px; border-radius: 999px; background: #d9ff28; color: #171126; font-weight: 700; font-size: 12px; }
            a { color: #5122d8; font-weight: 800; }
            .asset { display: inline-block; margin-top: 12px; }
            .open { align-self: center; white-space: nowrap; }
            @media (prefers-color-scheme: dark) {
              :root { background: #151025; color: #f7f2ff; }
              .item { background: rgba(33, 25, 54, .88); border-color: rgba(255, 255, 255, .12); }
              p { color: #cfc7df; }
              .meta { color: #a99bc4; }
              a { color: #d9ff28; }
            }
          </style>
        </head>
        <body>
          <main>
            <header>
              <h1>SAVI Archive</h1>
              <p>\(items.count) saves exported from SAVI. Files live in the assets folder, notes live in the notes folder, and links open from this page.</p>
            </header>
            \(rows)
          </main>
        </body>
        </html>
        """
        return Data(html.utf8)
    }

    private static func makeCSV(items: [SaviItem], folders: [SaviFolder], assets: [SaviArchiveAssetRecord]) -> Data {
        let foldersById = Dictionary(uniqueKeysWithValues: folders.map { ($0.id, $0.name) })
        let assetsById = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0.archivePath) })
        let header = ["title", "description", "url", "folder", "type", "source", "tags", "asset", "saved_at"]
        let rows = items.sorted { $0.savedAt > $1.savedAt }.map { item in
            [
                item.title,
                item.itemDescription,
                item.url ?? "",
                foldersById[item.folderId] ?? "",
                item.type.label,
                item.source,
                item.tags.joined(separator: " "),
                item.assetId.flatMap { assetsById[$0] } ?? "",
                SaviArchiveText.displayDate(item.savedAt)
            ]
        }
        let csv = ([header] + rows)
            .map { row in row.map(SaviArchiveText.csvEscaped).joined(separator: ",") }
            .joined(separator: "\n")
        return Data(csv.utf8)
    }
}

enum SaviArchiveImporter {
    static func importPayload(data: Data, suggestedName: String?) throws -> SaviArchiveImportPayload {
        if SaviZipReader.isZip(data) || suggestedName?.lowercased().hasSuffix(".zip") == true || suggestedName?.lowercased().hasSuffix(".saviarchive") == true {
            let package = try importArchive(data: data)
            return .fullArchive(package, sourceSize: data.count)
        }

        let backup = try JSONDecoder().decode(SaviBackup.self, from: data)
        guard backup.app == "SAVI" else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return .legacyJSON(backup, sourceSize: data.count)
    }

    private static func importArchive(data: Data) throws -> SaviArchivePackage {
        let entries = try SaviZipReader.read(data)
        guard let manifestData = entries["manifest.json"],
              let libraryData = entries["library.json"]
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let decoder = JSONDecoder()
        let manifest = try decoder.decode(SaviArchiveManifest.self, from: manifestData)
        let library = try decoder.decode(SaviArchiveLibrary.self, from: libraryData)
        guard manifest.app == "SAVI",
              library.app == "SAVI",
              manifest.format == "savi-full-archive",
              manifest.schemaVersion <= SaviArchiveExporter.schemaVersion,
              library.schemaVersion <= SaviArchiveExporter.schemaVersion
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        var assetData: [String: Data] = [:]
        for asset in library.assets {
            guard SaviArchiveText.isSafeArchivePath(asset.archivePath),
                  let data = entries[asset.archivePath]
            else {
                throw CocoaError(.fileReadNoSuchFile)
            }
            guard Int64(data.count) == asset.size,
                  SaviCRC32.hex(data) == asset.checksum
            else {
                throw CocoaError(.fileReadCorruptFile)
            }
            assetData[asset.id] = data
        }

        return SaviArchivePackage(manifest: manifest, library: library, assetData: assetData)
    }
}

struct SaviZipEntry {
    var path: String
    var data: Data
    var date: Date = Date()
}

enum SaviZipWriter {
    static func makeArchive(entries: [SaviZipEntry]) throws -> Data {
        var output = Data()
        var centralDirectory = Data()
        let cleanEntries = entries.filter { !$0.path.isEmpty }

        for entry in cleanEntries {
            guard SaviArchiveText.isSafeArchivePath(entry.path) else {
                throw CocoaError(.fileWriteInvalidFileName)
            }
            let nameData = Data(entry.path.utf8)
            guard nameData.count <= Int(UInt16.max),
                  entry.data.count <= Int(UInt32.max),
                  output.count <= Int(UInt32.max)
            else {
                throw CocoaError(.fileWriteOutOfSpace)
            }

            let offset = UInt32(output.count)
            let crc = SaviCRC32.value(entry.data)
            let (dosTime, dosDate) = dosDateTime(from: entry.date)
            let size = UInt32(entry.data.count)

            output.appendUInt32LE(0x0403_4b50)
            output.appendUInt16LE(20)
            output.appendUInt16LE(0)
            output.appendUInt16LE(0)
            output.appendUInt16LE(dosTime)
            output.appendUInt16LE(dosDate)
            output.appendUInt32LE(crc)
            output.appendUInt32LE(size)
            output.appendUInt32LE(size)
            output.appendUInt16LE(UInt16(nameData.count))
            output.appendUInt16LE(0)
            output.append(nameData)
            output.append(entry.data)

            centralDirectory.appendUInt32LE(0x0201_4b50)
            centralDirectory.appendUInt16LE(20)
            centralDirectory.appendUInt16LE(20)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(dosTime)
            centralDirectory.appendUInt16LE(dosDate)
            centralDirectory.appendUInt32LE(crc)
            centralDirectory.appendUInt32LE(size)
            centralDirectory.appendUInt32LE(size)
            centralDirectory.appendUInt16LE(UInt16(nameData.count))
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt32LE(0)
            centralDirectory.appendUInt32LE(offset)
            centralDirectory.append(nameData)
        }

        guard centralDirectory.count <= Int(UInt32.max),
              output.count <= Int(UInt32.max),
              cleanEntries.count <= Int(UInt16.max)
        else {
            throw CocoaError(.fileWriteOutOfSpace)
        }

        let directoryOffset = UInt32(output.count)
        output.append(centralDirectory)
        output.appendUInt32LE(0x0605_4b50)
        output.appendUInt16LE(0)
        output.appendUInt16LE(0)
        output.appendUInt16LE(UInt16(cleanEntries.count))
        output.appendUInt16LE(UInt16(cleanEntries.count))
        output.appendUInt32LE(UInt32(centralDirectory.count))
        output.appendUInt32LE(directoryOffset)
        output.appendUInt16LE(0)
        return output
    }

    private static func dosDateTime(from date: Date) -> (time: UInt16, date: UInt16) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = max(1980, components.year ?? 1980)
        let month = max(1, components.month ?? 1)
        let day = max(1, components.day ?? 1)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = (components.second ?? 0) / 2
        let dosTime = UInt16((hour << 11) | (minute << 5) | second)
        let dosDate = UInt16(((year - 1980) << 9) | (month << 5) | day)
        return (dosTime, dosDate)
    }
}

enum SaviZipReader {
    static func isZip(_ data: Data) -> Bool {
        data.count >= 4 &&
            data[0] == 0x50 &&
            data[1] == 0x4b &&
            data[2] == 0x03 &&
            data[3] == 0x04
    }

    static func read(_ data: Data) throws -> [String: Data] {
        guard let endOfCentralDirectory = findEndOfCentralDirectory(in: data) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let entryCount = Int(readUInt16(data, endOfCentralDirectory + 10))
        let centralDirectorySize = Int(readUInt32(data, endOfCentralDirectory + 12))
        let centralDirectoryOffset = Int(readUInt32(data, endOfCentralDirectory + 16))
        guard centralDirectoryOffset >= 0,
              centralDirectorySize >= 0,
              centralDirectoryOffset + centralDirectorySize <= data.count
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        var cursor = centralDirectoryOffset
        var result: [String: Data] = [:]
        for _ in 0..<entryCount {
            guard cursor + 46 <= data.count,
                  readUInt32(data, cursor) == 0x0201_4b50
            else {
                throw CocoaError(.fileReadCorruptFile)
            }

            let compressionMethod = readUInt16(data, cursor + 10)
            let crc = readUInt32(data, cursor + 16)
            let compressedSize = Int(readUInt32(data, cursor + 20))
            let fileNameLength = Int(readUInt16(data, cursor + 28))
            let extraLength = Int(readUInt16(data, cursor + 30))
            let commentLength = Int(readUInt16(data, cursor + 32))
            let localHeaderOffset = Int(readUInt32(data, cursor + 42))
            let nameStart = cursor + 46
            let nameEnd = nameStart + fileNameLength
            guard compressionMethod == 0,
                  nameEnd <= data.count,
                  let path = String(data: data[nameStart..<nameEnd], encoding: .utf8),
                  SaviArchiveText.isSafeArchivePath(path),
                  localHeaderOffset + 30 <= data.count,
                  readUInt32(data, localHeaderOffset) == 0x0403_4b50
            else {
                throw CocoaError(.fileReadCorruptFile)
            }

            let localNameLength = Int(readUInt16(data, localHeaderOffset + 26))
            let localExtraLength = Int(readUInt16(data, localHeaderOffset + 28))
            let dataStart = localHeaderOffset + 30 + localNameLength + localExtraLength
            let dataEnd = dataStart + compressedSize
            guard dataStart >= 0, dataEnd <= data.count else {
                throw CocoaError(.fileReadCorruptFile)
            }

            let entryData = Data(data[dataStart..<dataEnd])
            guard SaviCRC32.value(entryData) == crc else {
                throw CocoaError(.fileReadCorruptFile)
            }
            if !path.hasSuffix("/") {
                result[path] = entryData
            }

            cursor = nameEnd + extraLength + commentLength
        }

        return result
    }

    private static func findEndOfCentralDirectory(in data: Data) -> Int? {
        guard data.count >= 22 else { return nil }
        let minOffset = max(0, data.count - 65_557)
        var index = data.count - 22
        while index >= minOffset {
            if readUInt32(data, index) == 0x0605_4b50 {
                return index
            }
            index -= 1
        }
        return nil
    }

    private static func readUInt16(_ data: Data, _ offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32(_ data: Data, _ offset: Int) -> UInt32 {
        UInt32(data[offset]) |
            (UInt32(data[offset + 1]) << 8) |
            (UInt32(data[offset + 2]) << 16) |
            (UInt32(data[offset + 3]) << 24)
    }
}

enum SaviCRC32 {
    private static let table: [UInt32] = (0..<256).map { index in
        var crc = UInt32(index)
        for _ in 0..<8 {
            if crc & 1 == 1 {
                crc = 0xedb8_8320 ^ (crc >> 1)
            } else {
                crc >>= 1
            }
        }
        return crc
    }

    static func value(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffff_ffff
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xff)
            crc = table[index] ^ (crc >> 8)
        }
        return crc ^ 0xffff_ffff
    }

    static func hex(_ data: Data) -> String {
        String(format: "%08x", value(data))
    }
}

enum SaviArchiveText {
    static func isNoteLike(_ item: SaviItem) -> Bool {
        item.type == .text ||
            (item.url?.nilIfBlank == nil &&
             item.assetId?.nilIfBlank == nil &&
             item.itemDescription.nilIfBlank != nil)
    }

    static func displayDate(_ timestamp: Double) -> String {
        let seconds = timestamp > 10_000_000_000 ? timestamp / 1000 : timestamp
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: Date(timeIntervalSince1970: seconds))
    }

    static func safeFileName(_ value: String, fallback: String) -> String {
        let illegal = CharacterSet(charactersIn: "/\\?%*|\"<>:\n\r\t")
        let cleaned = value
            .components(separatedBy: illegal)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = cleaned.replacingOccurrences(of: #"-{2,}"#, with: "-", options: .regularExpression)
        let final = collapsed.nilIfBlank ?? fallback
        return String(final.prefix(96))
    }

    static func isSafeArchivePath(_ path: String) -> Bool {
        guard !path.isEmpty,
              !path.hasPrefix("/"),
              !path.hasPrefix("\\"),
              !path.contains(".."),
              !path.contains("\\")
        else { return false }
        return true
    }

    static func csvEscaped(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    static func htmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    static func htmlAttributeEscaped(_ value: String) -> String {
        htmlEscaped(value)
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

private extension Data {
    mutating func appendUInt16LE(_ value: UInt16) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
    }

    mutating func appendUInt32LE(_ value: UInt32) {
        append(UInt8(value & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 24) & 0xff))
    }
}
