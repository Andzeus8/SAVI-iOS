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
import AuthenticationServices
#if DEBUG && canImport(FoundationModels)
import FoundationModels
#endif

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
                    SaveQuickStartCard(
                        mode: mode,
                        selectLinkAction: { switchToMode(.link) },
                        selectFileAction: { switchToMode(.file) },
                        selectNoteAction: { switchToMode(.text) }
                    )

                    if isCheckingClipboard {
                        ClipboardDraftCard(draft: nil, isLoading: true, clearAction: {})
                    } else if let clipboardDraft {
                        ClipboardDraftCard(draft: clipboardDraft, isLoading: false) {
                            clearClipboardDraft()
                        }
                    }

                    if showPreview {
                        SavePreviewCard(
                            mode: mode,
                            title: previewTitle,
                            subtitle: previewSubtitle,
                            detail: previewDetail
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        switch mode {
                        case .link:
                            LinkPasteField(text: $urlText) {
                                Task { await pasteLinkFromClipboard() }
                            }
                            if urlText.nilIfBlank != nil {
                                SaviTextField(title: "Title", text: $title, prompt: "Optional")
                                Text("SAVI saves now and fills in preview, Folder, and tags afterward.")
                                    .font(.footnote)
                                    .foregroundStyle(SaviTheme.textMuted)
                            }
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

                                Button {
                                    Task { await readClipboardDraftFromUserAction() }
                                } label: {
                                    Label(isCheckingClipboard ? "Checking" : "Clipboard", systemImage: "doc.on.clipboard")
                                }
                                .buttonStyle(SaviSecondaryButtonStyle())
                                .disabled(isCheckingClipboard)
                            }
                            Text(fileHelpText)
                                .font(.footnote)
                                .foregroundStyle(SaviTheme.textMuted)
                        }
                    }

                    if showDetails {
                        FolderPicker(selectedFolderId: $selectedFolderId)

                        SaviTextField(title: "Optional tags", text: $tagsText, prompt: "recipe, pdf, travel")
                            .textInputAutocapitalization(.never)
                    }
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("New Save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                SaveSheetBottomBar(
                    title: saveActionTitle,
                    helper: saveHelperText,
                    canSave: canSave,
                    action: save
                )
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

    private var showPreview: Bool {
        activeClipboardDraft != nil ||
            urlText.nilIfBlank != nil ||
            bodyText.nilIfBlank != nil ||
            mode == .file
    }

    private var showDetails: Bool {
        showPreview
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
        switch mode {
        case .link:
            return "Save Link"
        case .text:
            return "Save Note"
        case .file:
            return activeClipboardDraft == nil ? "Choose File" : "Save File"
        }
    }

    private var saveHelperText: String {
        switch mode {
        case .link:
            return canSave ? "Saves now. Preview and tags can improve later." : "Paste a link or type one to save."
        case .text:
            return canSave ? "Your note becomes searchable right away." : "Write or paste text to save."
        case .file:
            return activeClipboardDraft == nil ? "Choose a file or photo to import." : "Clipboard file is ready to import."
        }
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

    @MainActor
    private func readClipboardDraftFromUserAction() async {
        didCheckClipboard = true
        isCheckingClipboard = true
        let draft = await SaviClipboardReader.readDraft()
        isCheckingClipboard = false

        if let draft {
            applyClipboardDraft(draft)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            store.toast = "Clipboard does not have a supported link, note, image, or file."
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

    private func switchToMode(_ newMode: SaviSaveMode) {
        mode = newMode
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func cleanClipboardTagsIfNeeded(for newMode: SaviSaveMode) {
        guard let clipboardDraft,
              clipboardDraft.mode != newMode,
              tagsText == clipboardDraft.tags.joined(separator: ", ")
        else { return }
        tagsText = ""
    }

    private func startFileImport() {
        mode = .file
        clipboardDraft = nil
        filePickerPresented = true
    }

    @MainActor
    private func pasteLinkFromClipboard() async {
        mode = .link
        isCheckingClipboard = true
        let draft = await SaviClipboardReader.readDraft()
        isCheckingClipboard = false
        didCheckClipboard = true

        if let draft, draft.mode == .link {
            applyClipboardDraft(draft)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        if let rawText = UIPasteboard.general.string,
           let urlString = firstLink(in: rawText) {
            applyClipboardDraft(
                SaviClipboardDraft(
                    mode: .link,
                    title: "Clipboard link",
                    subtitle: SaviText.sourceLabel(for: urlString, fallback: "Web"),
                    url: urlString,
                    text: nil,
                    data: nil,
                    fileName: nil,
                    mimeType: nil,
                    tags: SaviText.inferredTags(
                        type: SaviText.inferredType(for: urlString),
                        url: urlString,
                        title: "",
                        description: ""
                    )
                )
            )
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        store.toast = "No link found on the clipboard."
    }

    private func firstLink(in rawText: String) -> String? {
        let nsRange = NSRange(rawText.startIndex..<rawText.endIndex, in: rawText)
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
           let match = detector.firstMatch(in: rawText, options: [], range: nsRange),
           let url = match.url {
            return url.absoluteString
        }

        let normalized = SaviText.normalizedURL(rawText)
        if URL(string: normalized)?.host != nil {
            return normalized
        }

        return nil
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

private struct SaveQuickStartCard: View {
    let mode: SaviSaveMode
    let selectLinkAction: () -> Void
    let selectFileAction: () -> Void
    let selectNoteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.headline.weight(.black))
                    .frame(width: 38, height: 38)
                    .background(SaviTheme.surfaceRaised)
                    .foregroundStyle(SaviTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("What are we saving?")
                        .font(SaviType.ui(.headline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                    Text("Paste a link, add a note, or import a file. Sharing to SAVI from another app is fastest.")
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 10) {
                SaveModeTile(
                    title: "Link",
                    symbolName: SaviSaveMode.link.symbolName,
                    active: mode == .link,
                    action: selectLinkAction
                )
                SaveModeTile(
                    title: "File",
                    symbolName: SaviSaveMode.file.symbolName,
                    active: mode == .file,
                    action: selectFileAction
                )
                SaveModeTile(
                    title: "Note",
                    symbolName: SaviSaveMode.text.symbolName,
                    active: mode == .text,
                    action: selectNoteAction
                )
            }
        }
        .padding(14)
        .saviCard(cornerRadius: 18)
    }
}

private struct SaveModeTile: View {
    let title: String
    let symbolName: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: active ? "checkmark.circle.fill" : symbolName)
                    .font(SaviType.ui(.headline, weight: .black))
                Text(title)
                    .font(SaviType.ui(.caption, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(active ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
            .foregroundStyle(active ? .black : SaviTheme.text)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(active ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct LinkPasteField: View {
    @Binding var text: String
    let pasteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("Link")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                Spacer()
                Button(action: pasteAction) {
                    Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                        .font(SaviType.ui(.caption, weight: .black))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 34)
                        .background(SaviTheme.surfaceRaised)
                        .foregroundStyle(SaviTheme.accentText)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Paste link from clipboard")
            }

            TextField("Paste a link or type one", text: $text)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(14)
                .foregroundStyle(SaviTheme.text)
                .saviCard(cornerRadius: 16, shadow: false)
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
                Text(isLoading ? "Checking clipboard" : "Clipboard ready")
                    .font(.headline)
                    .foregroundStyle(SaviTheme.text)
                Text(draft?.subtitle ?? "Paste from clipboard to bring in a link, text, image, or file.")
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

private struct SaveSheetBottomBar: View {
    let title: String
    let helper: String
    let canSave: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Label(title, systemImage: title.hasPrefix("Choose") ? "doc.badge.plus" : "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .font(SaviType.ui(.headline, weight: .black))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(canSave ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                    .foregroundStyle(canSave ? .black : SaviTheme.textMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(canSave ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSave)

            Text(helper)
                .font(SaviType.ui(.caption, weight: .semibold))
                .foregroundStyle(SaviTheme.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(SaviTheme.cardStroke)
                .frame(height: 1)
        }
    }
}

struct ItemDetailSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var webPreview: WebPreviewURL?
    @State private var assetPreview: AssetPreviewURL?
    @State private var thumbnailPreviewPresented = false
    @State private var deleteConfirmationPresented = false
    let item: SaviItem

    var body: some View {
        let quickLookURL = store.quickLookURL(for: item)
        let hasThumbnailPreview = item.thumbnail?.nilIfBlank != nil

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ItemDetailHeroCard(
                        item: item,
                        folder: store.folder(for: item.folderId),
                        bodyTitle: SaviItemDisplay.detailBodyTitle(for: item),
                        bodyText: SaviItemDisplay.detailBody(for: item),
                        canOpenPrimaryContent: itemURL != nil || quickLookURL != nil || hasThumbnailPreview,
                        onOpenPrimaryContent: openPrimaryContent,
                        onPreviewPrimaryContent: previewPrimaryContent
                    )

                    ItemDetailActionPanel(
                        item: item,
                        itemURL: itemURL,
                        quickLookURL: quickLookURL,
                        hasThumbnailPreview: hasThumbnailPreview,
                        shareURL: shareURL,
                        shareText: shareText,
                        onPreviewURL: { webPreview = WebPreviewURL(url: $0) },
                        onPreviewAsset: { assetPreview = AssetPreviewURL(url: $0) },
                        onPreviewThumbnail: { thumbnailPreviewPresented = true },
                        onEdit: { store.editItem(item) },
                        onDelete: {
                            deleteConfirmationPresented = true
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    toolbarShareAction
                }
            }
            .sheet(item: $webPreview) { preview in
                SafariLinkPreview(url: preview.url)
                    .ignoresSafeArea()
            }
            .sheet(item: $assetPreview) { preview in
                QuickLookPreview(url: preview.url)
            }
            .sheet(isPresented: $thumbnailPreviewPresented) {
                ItemThumbnailPreviewSheet(item: item)
            }
            .alert("Are you sure you want to delete this save?", isPresented: $deleteConfirmationPresented) {
                Button("Delete Save", role: .destructive) {
                    store.deleteItem(item)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes it from SAVI. This can’t be undone.")
            }
        }
    }

    @ViewBuilder
    private var toolbarShareAction: some View {
        if let shareURL {
            ShareLink(item: shareURL) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share \(SaviItemDisplay.rowTitle(for: item))")
        } else {
            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share \(SaviItemDisplay.rowTitle(for: item))")
        }
    }

    private var itemURL: URL? {
        guard let rawURL = item.url?.nilIfBlank else { return nil }
        if let url = URL(string: rawURL), url.scheme != nil {
            return url
        }
        return URL(string: "https://\(rawURL)")
    }

    private var shareURL: URL? {
        itemURL
    }

    private var shareText: String {
        let title = SaviItemDisplay.rowTitle(for: item)
        if let description = item.itemDescription.nilIfBlank,
           description.caseInsensitiveCompare(title) != .orderedSame {
            return "\(title)\n\(description)"
        }
        return title
    }

    private func openPrimaryContent() {
        if let itemURL {
            openURL(itemURL)
        } else if let quickLookURL = store.quickLookURL(for: item) {
            assetPreview = AssetPreviewURL(url: quickLookURL)
        } else if item.thumbnail?.nilIfBlank != nil {
            thumbnailPreviewPresented = true
        }
    }

    private func previewPrimaryContent() {
        if let itemURL {
            webPreview = WebPreviewURL(url: itemURL)
        } else if let quickLookURL = store.quickLookURL(for: item) {
            assetPreview = AssetPreviewURL(url: quickLookURL)
        } else if item.thumbnail?.nilIfBlank != nil {
            thumbnailPreviewPresented = true
        }
    }
}

private struct ItemThumbnailPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: SaviItem

    var body: some View {
        NavigationStack {
            ZStack {
                SaviTheme.background.ignoresSafeArea()

                VStack(spacing: 14) {
                    SaviThumbnailPreviewContent(item: item)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(14)
                        .background(SaviTheme.surface.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(SaviTheme.cardStroke.opacity(0.6), lineWidth: 1)
                        )

                    Text(SaviItemDisplay.rowTitle(for: item))
                        .font(SaviType.reading(.callout, weight: .bold))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
            }
            .navigationTitle("Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct SaviThumbnailPreviewContent: View {
    let item: SaviItem

    var body: some View {
        if let thumbnail = item.thumbnail?.nilIfBlank,
           thumbnail.hasPrefix("http"),
           let url = URL(string: thumbnail) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    fallback
                case .empty:
                    ProgressView()
                        .tint(SaviTheme.chartreuse)
                @unknown default:
                    fallback
                }
            }
        } else if let thumbnail = item.thumbnail?.nilIfBlank,
                  let image = SaviImageCache.image(fromDataURL: thumbnail) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else if let thumbnail = item.thumbnail?.nilIfBlank,
                  SaviText.isSVGDataURL(thumbnail) {
            SaviSVGDataThumbnail(dataURL: thumbnail)
                .aspectRatio(1, contentMode: .fit)
        } else {
            fallback
        }
    }

    private var fallback: some View {
        VStack(spacing: 10) {
            Image(systemName: item.type.symbolName)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(SaviTheme.accentText)
            Text("No image preview available")
                .font(SaviType.ui(.caption, weight: .bold))
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ItemDetailActionPanel: View {
    let item: SaviItem
    let itemURL: URL?
    let quickLookURL: URL?
    let hasThumbnailPreview: Bool
    let shareURL: URL?
    let shareText: String
    let onPreviewURL: (URL) -> Void
    let onPreviewAsset: (URL) -> Void
    let onPreviewThumbnail: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            shareAction

            HStack(spacing: 8) {
                if let itemURL {
                    Button {
                        onPreviewURL(itemURL)
                    } label: {
                        Label("Preview", systemImage: "eye.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ItemDetailActionButtonStyle())

                    Link(destination: itemURL) {
                        Label("Open", systemImage: "safari.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ItemDetailActionButtonStyle())
                } else if let quickLookURL {
                    Button {
                        onPreviewAsset(quickLookURL)
                    } label: {
                        Label("Preview", systemImage: "eye.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ItemDetailActionButtonStyle())
                } else if hasThumbnailPreview {
                    Button {
                        onPreviewThumbnail()
                    } label: {
                        Label("View Image", systemImage: "photo.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ItemDetailActionButtonStyle())
                }

                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(ItemDetailActionButtonStyle())
                .accessibilityLabel("Edit save")
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ItemDetailDeleteButtonStyle())
            .padding(.top, 1)
        }
        .padding(10)
        .saviCard(cornerRadius: 16, shadow: false)
    }

    @ViewBuilder
    private var shareAction: some View {
        if let shareURL {
            ShareLink(item: shareURL) {
                Label("Share", systemImage: "square.and.arrow.up.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ItemDetailShareButtonStyle())
            .accessibilityLabel("Share \(SaviItemDisplay.rowTitle(for: item))")
        } else {
            ShareLink(item: shareText) {
                Label("Share", systemImage: "square.and.arrow.up.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ItemDetailShareButtonStyle())
            .accessibilityLabel("Share \(SaviItemDisplay.rowTitle(for: item))")
        }
    }
}

struct ItemDetailHeroCard: View {
    let item: SaviItem
    let folder: SaviFolder?
    let bodyTitle: String
    let bodyText: String?
    var canOpenPrimaryContent = false
    var onOpenPrimaryContent: () -> Void = {}
    var onPreviewPrimaryContent: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                ItemPreview(item: item)
                    .itemDetailPrimaryContentTarget(
                        isEnabled: canOpenPrimaryContent,
                        onOpen: onOpenPrimaryContent,
                        onPreview: onPreviewPrimaryContent
                    )

                ItemDetailPreviewBadge(item: item)
                .padding(12)
            }

            VStack(alignment: .leading, spacing: 9) {
                Text(SaviItemDisplay.rowTitle(for: item))
                    .font(SaviItemTypography.detailTitle)
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(3)
                    .lineSpacing(2)
                    .itemDetailPrimaryContentTarget(
                        isEnabled: canOpenPrimaryContent,
                        onOpen: onOpenPrimaryContent,
                        onPreview: onPreviewPrimaryContent
                    )

                ItemDetailMetadataRow(
                    item: item,
                    folder: folder,
                    assetName: item.assetName?.nilIfBlank
                )

                ItemDetailTagSummary(tags: item.tags)

                if let bodyText {
                    Divider()
                        .overlay(SaviTheme.cardStroke.opacity(0.55))
                        .padding(.vertical, 2)

                    ItemDetailInlineSummary(
                        title: bodyTitle,
                        text: bodyText,
                        isNoteLike: SaviItemDisplay.isNoteLike(item)
                    )
                    .itemDetailPrimaryContentTarget(
                        isEnabled: canOpenPrimaryContent && !SaviItemDisplay.isNoteLike(item),
                        onOpen: onOpenPrimaryContent,
                        onPreview: onPreviewPrimaryContent
                    )
                }
            }
            .padding(13)
        }
        .saviCard(cornerRadius: 22)
    }
}

private struct ItemDetailPrimaryContentTarget: ViewModifier {
    let isEnabled: Bool
    let onOpen: () -> Void
    let onPreview: () -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .contentShape(Rectangle())
                .onTapGesture(perform: onOpen)
                .highPriorityGesture(
                    LongPressGesture(minimumDuration: 0.42)
                        .onEnded { _ in
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onPreview()
                        }
                )
                .accessibilityAddTraits(.isButton)
                .accessibilityAction(named: "Open") { onOpen() }
                .accessibilityAction(named: "Preview") { onPreview() }
        } else {
            content
        }
    }
}

private extension View {
    func itemDetailPrimaryContentTarget(
        isEnabled: Bool,
        onOpen: @escaping () -> Void,
        onPreview: @escaping () -> Void
    ) -> some View {
        modifier(ItemDetailPrimaryContentTarget(
            isEnabled: isEnabled,
            onOpen: onOpen,
            onPreview: onPreview
        ))
    }
}

struct ItemDetailPreviewBadge: View {
    let item: SaviItem

    private var presentation: ItemSourcePinPresentation {
        ItemSourcePinPresentation.make(for: item)
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: presentation.symbolName)
                .font(.system(size: 10, weight: .black))
            Text(presentation.title)
                .lineLimit(1)
        }
        .font(SaviItemTypography.pill)
        .foregroundStyle(.white.opacity(0.92))
        .padding(.horizontal, 8)
        .frame(height: 25)
        .background(.black.opacity(0.36))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
        .accessibilityLabel(presentation.title)
    }
}

struct ItemDetailMetadataRow: View {
    let item: SaviItem
    let folder: SaviFolder?
    let assetName: String?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                compactIdentity
                savedAndAsset
            }

            VStack(alignment: .leading, spacing: 7) {
                compactIdentity
                savedAndAsset
            }
        }
    }

    private var compactIdentity: some View {
        HStack(spacing: 8) {
            if let folder {
                KeeperPill(folder: folder, maxWidth: 128)
                    .layoutPriority(2)
            }

            ItemTypeSourceText(item: item)
                .layoutPriority(1)
        }
    }

    private var savedAndAsset: some View {
        HStack(spacing: 8) {
            SavedAgoLabel(savedAt: item.savedAt, prefix: "Saved")

            if let assetName {
                ItemMetaDivider()
                Label(assetName, systemImage: "doc")
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .font(SaviItemTypography.meta)
        .foregroundStyle(SaviTheme.metadataText)
    }
}

struct ItemDetailTagSummary: View {
    @State private var expanded = false
    let tags: [String]

    var body: some View {
        if !displayTags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if expanded {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 74), spacing: 6)],
                        alignment: .leading,
                        spacing: 6
                    ) {
                        ForEach(displayTags, id: \.self) { tag in
                            ItemDetailTagChip(title: "#\(tag)")
                        }
                    }
                } else {
                    ViewThatFits(in: .horizontal) {
                        collapsedRow(count: 3)
                        collapsedRow(count: 2)
                        collapsedRow(count: 1)
                    }
                }

                if displayTags.count > 3 {
                    Button {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                            expanded.toggle()
                        }
                    } label: {
                        Text(expanded ? "Hide tags" : "Show all tags")
                            .font(SaviType.ui(.caption, weight: .bold))
                            .foregroundStyle(SaviTheme.accentText.opacity(0.82))
                    }
                    .buttonStyle(SaviPressScaleButtonStyle(scale: 0.97))
                    .accessibilityLabel(expanded ? "Hide tags" : "Show all tags")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var displayTags: [String] {
        let generic: Set<String> = [
            "link", "article", "video", "image", "file", "post", "web", "save",
            "twitter", "x", "youtube", "instagram", "tiktok", "reddit", "facebook",
            "device", "clipboard", "text", "note", "friend"
        ]
        let useful = tags.filter { !generic.contains($0.lowercased()) }
        return useful
    }

    private func collapsedRow(count: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(displayTags.prefix(count)), id: \.self) { tag in
                ItemDetailTagChip(title: "#\(tag)")
            }

            if displayTags.count > count {
                ItemDetailTagChip(title: "+\(displayTags.count - count)", muted: true)
                    .accessibilityLabel("\(displayTags.count - count) more tags")
            }
        }
    }
}

struct ItemDetailTagChip: View {
    let title: String
    var muted = false

    var body: some View {
        Text(title)
            .font(SaviType.ui(.caption2, weight: .semibold))
            .foregroundStyle(SaviTheme.metadataText.opacity(muted ? 0.68 : 0.82))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 7)
            .frame(height: 24)
            .background(SaviTheme.subtleSurface.opacity(muted ? 0.18 : 0.25))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(SaviTheme.cardStroke.opacity(0.22), lineWidth: 1))
    }
}

struct ItemDetailActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaviType.ui(.caption, weight: .black))
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
            .background(SaviTheme.surfaceRaised.opacity(configuration.isPressed ? 0.70 : 1))
            .foregroundStyle(SaviTheme.text)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(SaviTheme.cardStroke.opacity(0.86), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct ItemDetailShareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaviType.ui(.subheadline, weight: .black))
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .frame(minHeight: 46)
            .background(SaviTheme.chartreuse.opacity(configuration.isPressed ? 0.78 : 1))
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct ItemDetailDeleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaviType.ui(.caption, weight: .bold))
            .padding(.vertical, 9)
            .padding(.horizontal, 12)
            .frame(minHeight: 42)
            .background(Color.red.opacity(configuration.isPressed ? 0.14 : 0.08))
            .foregroundStyle(Color.red.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.red.opacity(0.16), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct ItemDetailInlineSummary: View {
    let title: String
    let text: String
    let isNoteLike: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: isNoteLike ? "text.alignleft" : "quote.bubble.fill")
                .font(SaviType.ui(.caption2, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
                .textCase(.uppercase)

            Text(text)
                .font(SaviType.reading(.subheadline, weight: .regular))
                .foregroundStyle(SaviTheme.text)
                .lineSpacing(2)
                .lineLimit(isNoteLike ? 8 : 3)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    @State private var showThumbnailSearch = false
    @State private var thumbnailMessage: String?

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
                    ItemThumbnailEditSection(
                        item: $item,
                        message: $thumbnailMessage,
                        showImageSearch: $showThumbnailSearch,
                        searchQuery: itemThumbnailSearchQuery
                    )
                    FolderPicker(selectedFolderId: $item.folderId)
                    SaviTextField(title: "Tags", text: $tagsText, prompt: "tag, tag")
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showThumbnailSearch) {
                WebImageSearchSheet(
                    title: "Change thumbnail",
                    initialQuery: itemThumbnailSearchQuery,
                    maxPixelSize: 960,
                    cropToSquare: false
                ) { dataURL in
                    item.thumbnail = dataURL
                    item.thumbnailRetryCount = 0
                    item.thumbnailLastAttemptAt = nil
                    thumbnailMessage = "Thumbnail selected from Pexels."
                }
            }
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

    private var itemThumbnailSearchQuery: String {
        let parts = [item.title, item.source, store.folder(for: item.folderId)?.name]
            .compactMap { $0?.nilIfBlank }
        return parts.isEmpty ? "useful saved link" : parts.joined(separator: " ")
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
    @State private var usesImageBackground: Bool
    @State private var locked: Bool
    @State private var isPublic: Bool
    @State private var selectedCoverPhoto: PhotosPickerItem?
    @State private var artworkMessage: String?
    @State private var showFolderImageSearch = false
    @State private var colorExpanded = true
    @State private var artworkExpanded = true
    @State private var iconsExpanded = false
    @State private var privacyExpanded = false

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
        _usesImageBackground = State(initialValue: folder?.usesImageBackground ?? false)
        _locked = State(initialValue: folder?.locked ?? false)
        _isPublic = State(initialValue: folder?.isPublic ?? false)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    FolderEditorPreviewCard(
                        name: name.nilIfBlank ?? "Untitled Folder",
                        color: color,
                        symbolName: symbolName,
                        imageDataURL: folderImage,
                        usesImageBackground: usesImageBackground,
                        locked: locked,
                        isPublic: SaviReleaseGate.socialFeaturesEnabled && isPublic && !locked
                    )

                    SaviTextField(title: "Name", text: $name, prompt: "Folder name")

                    DisclosureGroup(isExpanded: $colorExpanded) {
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
                                        .overlay(
                                            Circle()
                                                .stroke(color == swatch ? SaviTheme.text : SaviTheme.cardStroke, lineWidth: color == swatch ? 2 : 1)
                                        )
                                }
                                .buttonStyle(SaviPressScaleButtonStyle())
                            }
                        }
                        .padding(.top, 10)
                    } label: {
                        FolderEditorSectionLabel(
                            title: "Color",
                            subtitle: "Choose the Folder color shown on Home, Search, and the share sheet.",
                            systemImage: "paintpalette.fill"
                        )
                    }
                    .padding(14)
                    .saviCard(cornerRadius: 18, shadow: false)

                    DisclosureGroup(isExpanded: $artworkExpanded) {
                        HStack(alignment: .center, spacing: 12) {
                            FolderIconBadge(
                                symbolName: symbolName,
                                color: color,
                                imageDataURL: usesImageBackground ? nil : folderImage,
                                size: 58,
                                cornerRadius: 17,
                                font: SaviType.ui(.title2, weight: .black)
                            )
                            .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 8) {
                                PhotosPicker(selection: $selectedCoverPhoto, matching: .images) {
                                    Label(folderImage == nil ? "Choose cover" : "Change cover", systemImage: "photo.fill")
                                        .font(SaviType.ui(.subheadline, weight: .black))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .padding(.horizontal, 12)
                                        .background(SaviTheme.surfaceRaised)
                                        .foregroundStyle(SaviTheme.text)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    showFolderImageSearch = true
                                } label: {
                                    Label("Find image", systemImage: "magnifyingglass")
                                        .font(SaviType.ui(.subheadline, weight: .black))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .padding(.horizontal, 12)
                                        .background(SaviImageSearchService.isConfigured ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                                        .foregroundStyle(SaviImageSearchService.isConfigured ? .black : SaviTheme.accentText)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(SaviPressScaleButtonStyle())
                                .disabled(!SaviImageSearchService.isConfigured)

                                if folderImage != nil {
                                    Button {
                                        folderImage = nil
                                        usesImageBackground = false
                                        artworkMessage = nil
                                    } label: {
                                        Label("Remove cover image", systemImage: "xmark.circle.fill")
                                            .font(SaviType.ui(.caption, weight: .bold))
                                            .foregroundStyle(SaviTheme.accentText)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.top, 10)

                        VStack(alignment: .leading, spacing: 8) {
                            if folderImage != nil {
                                Toggle(isOn: $usesImageBackground) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Use as cover background")
                                            .font(SaviType.ui(.caption, weight: .bold))
                                            .foregroundStyle(SaviTheme.text)
                                        Text("The symbol stays separate. SAVI adds an overlay so names remain readable.")
                                            .font(SaviType.ui(.caption2, weight: .semibold))
                                            .foregroundStyle(SaviTheme.textMuted)
                                    }
                                }
                                .toggleStyle(.switch)
                                .tint(SaviTheme.chartreuse)
                            }

                            if !SaviImageSearchService.isConfigured {
                                Text("Web image search is not set up on this build. Choose a cover from Photos for now.")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(SaviTheme.textMuted)
                            }

                            if let artworkMessage {
                                Text(artworkMessage)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(SaviTheme.textMuted)
                            }
                        }
                    } label: {
                        FolderEditorSectionLabel(
                            title: "Cover image",
                            subtitle: "Use a photo as the Folder background. The symbol stays separate.",
                            systemImage: "photo.on.rectangle.angled"
                        )
                    }
                    .padding(14)
                    .saviCard(cornerRadius: 18, shadow: false)

                    DisclosureGroup(isExpanded: $iconsExpanded) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                            ForEach(symbols, id: \.self) { symbol in
                                Button {
                                    symbolName = symbol
                                    artworkMessage = nil
                                } label: {
                                    Image(systemName: symbol)
                                        .font(.subheadline.weight(.black))
                                        .frame(maxWidth: .infinity, minHeight: 42)
                                        .background(symbolName == symbol ? SaviTheme.chartreuse : SaviTheme.surface)
                                        .foregroundStyle(symbolName == symbol ? .black : SaviTheme.text)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(SaviTheme.cardStroke, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(SaviPressScaleButtonStyle())
                            }
                        }
                        .padding(.top, 10)
                    } label: {
                        FolderEditorSectionLabel(
                            title: "Symbol",
                            subtitle: "Pick the small icon that sits above the Folder name.",
                            systemImage: "square.grid.2x2.fill"
                        )
                    }
                    .padding(14)
                    .saviCard(cornerRadius: 18, shadow: false)

                    DisclosureGroup(isExpanded: $privacyExpanded) {
                        VStack(spacing: 12) {
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
                                        Text("Locked Folders hide their saves until Face ID or passcode unlocks them.")
                                            .font(SaviType.ui(.caption, weight: .semibold))
                                            .foregroundStyle(SaviTheme.textMuted)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .toggleStyle(.switch)
                            .tint(SaviTheme.chartreuse)

                            if SaviReleaseGate.socialFeaturesEnabled {
                                Divider()
                                    .overlay(SaviTheme.cardStroke)

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
                                            Text("Only URL previews from this Folder can publish. Files, PDFs, images, notes, and locked Folders stay private.")
                                                .font(SaviType.ui(.caption, weight: .semibold))
                                                .foregroundStyle(SaviTheme.textMuted)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                                .disabled(locked || folder?.id == "f-private-vault")
                                .toggleStyle(.switch)
                                .tint(SaviTheme.chartreuse)
                                .onChange(of: locked) { value in
                                    if value { isPublic = false }
                                }
                            }
                        }
                        .padding(.top, 10)
                    } label: {
                        FolderEditorSectionLabel(
                            title: "Privacy",
                            subtitle: privacySubtitle,
                            systemImage: locked ? "lock.fill" : "lock.shield.fill"
                        )
                    }
                    .padding(14)
                    .saviCard(cornerRadius: 18, shadow: false)

                    if let folder, !folder.system {
                        Button(role: .destructive) {
                            store.deleteFolder(folder)
                            dismiss()
                        } label: {
                            Label("Delete Folder", systemImage: "trash.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SaviDangerButtonStyle())
                        .padding(.top, 10)
                    }
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle(folder == nil ? "New Folder" : "Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedCoverPhoto) { item in
                loadCoverImage(item)
            }
            .sheet(isPresented: $showFolderImageSearch) {
                WebImageSearchSheet(
                    title: "Find folder image",
                    initialQuery: folderImageSearchQuery,
                    maxPixelSize: 256,
                    cropToSquare: true
                ) { dataURL in
                    folderImage = dataURL
                    usesImageBackground = true
                    artworkMessage = "Cover image selected from Pexels."
                }
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
                            folder.usesImageBackground = folderImage?.nilIfBlank != nil && usesImageBackground
                            folder.locked = locked
                            folder.isPublic = SaviReleaseGate.socialFeaturesEnabled && !locked ? isPublic : false
                            store.saveFolder(folder)
                        } else {
                            store.addFolder(
                                name: name,
                                color: color,
                                symbolName: symbolName,
                                image: folderImage,
                                locked: locked,
                                isPublic: SaviReleaseGate.socialFeaturesEnabled && !locked ? isPublic : false,
                                usesImageBackground: folderImage?.nilIfBlank != nil && usesImageBackground
                            )
                        }
                        dismiss()
                    }
                    .disabled(name.nilIfBlank == nil)
                }
            }
        }
    }

    private var folderImageSearchQuery: String {
        name.nilIfBlank ?? folder?.name.nilIfBlank ?? "folder cover"
    }

    private var privacySubtitle: String {
        if locked { return "Face ID is required." }
        if SaviReleaseGate.socialFeaturesEnabled, isPublic {
            return "Public link previews can appear for friends."
        }
        return "Private by default."
    }

    private func loadCoverImage(_ item: PhotosPickerItem?) {
        guard let item else { return }
        artworkMessage = "Preparing cover..."
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let dataURL = Self.folderCoverDataURL(from: data) {
                    await MainActor.run {
                        folderImage = dataURL
                        usesImageBackground = true
                        artworkMessage = nil
                    }
                } else {
                    await MainActor.run {
                        artworkMessage = "That image could not be used."
                    }
                }
            } catch {
                await MainActor.run {
                    artworkMessage = "That image could not be used."
                }
            }
        }
    }

    private static func folderCoverDataURL(from data: Data) -> String? {
        SaviImageDataURL.make(from: data, maxPixelSize: 960, cropToSquare: true)
    }
}

private struct FolderEditorPreviewCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let name: String
    let color: String
    let symbolName: String
    let imageDataURL: String?
    let usesImageBackground: Bool
    let locked: Bool
    let isPublic: Bool

    var body: some View {
        let folder = previewFolder
        let style = SaviFolderVisualStyle.make(for: folder, colorScheme: colorScheme)

        ZStack(alignment: .topLeading) {
            FolderTileBackground(folder: folder, style: style)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    FolderIconBadge(
                        symbolName: symbolName,
                        color: style.baseHex,
                        imageDataURL: usesImageBackground ? nil : imageDataURL,
                        size: 52,
                        cornerRadius: 16,
                        font: SaviType.ui(.title3, weight: .black),
                        background: style.iconBackground,
                        foreground: style.iconForeground,
                        publicBadgeStyle: isPublic ? style : nil
                    )

                    Spacer()

                    if locked {
                        Image(systemName: "lock.fill")
                            .font(SaviType.ui(.caption, weight: .black))
                            .foregroundStyle(style.countForeground)
                            .frame(width: 28, height: 28)
                            .background(style.countBackground)
                            .clipShape(Circle())
                    }
                }

                Spacer(minLength: 0)

                Text(SaviFolderNameFormatter.balanced(name))
                    .font(SaviType.display(size: 25, weight: .heavy))
                    .foregroundStyle(style.text)
                    .shadow(color: style.titleShadow, radius: style.titleShadowRadius, x: 0, y: 1)
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)
                    .lineSpacing(1.2)

                HStack(spacing: 7) {
                    FolderEditorMiniChip(text: usesImageBackground && imageDataURL?.nilIfBlank != nil ? "Cover" : color.uppercased(), systemImage: usesImageBackground && imageDataURL?.nilIfBlank != nil ? "photo.fill" : "paintpalette.fill")
                    if locked {
                        FolderEditorMiniChip(text: "Locked", systemImage: "lock.fill")
                    } else if isPublic {
                        FolderEditorMiniChip(text: "Public", systemImage: "person.2.fill")
                    }
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(style.stroke, lineWidth: 1)
        )
        .shadow(color: style.shadow, radius: 12, x: 0, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Folder preview, \(name)")
    }

    private var previewFolder: SaviFolder {
        SaviFolder(
            id: "folder-editor-preview",
            name: name,
            color: color,
            image: imageDataURL,
            system: false,
            symbolName: symbolName,
            order: 0,
            locked: locked,
            isPublic: isPublic,
            usesImageBackground: imageDataURL?.nilIfBlank != nil && usesImageBackground
        )
    }
}

private struct FolderEditorSectionLabel: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(SaviType.ui(.headline, weight: .black))
                .frame(width: 36, height: 36)
                .background(SaviTheme.surfaceRaised)
                .foregroundStyle(SaviTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text(subtitle)
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct FolderEditorMiniChip: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(SaviType.ui(.caption2, weight: .bold))
            .foregroundStyle(SaviTheme.metadataText)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(SaviTheme.subtleSurface)
            .clipShape(Capsule())
    }
}

struct ItemThumbnailEditSection: View {
    @Binding var item: SaviItem
    @Binding var message: String?
    @Binding var showImageSearch: Bool
    let searchQuery: String

    var body: some View {
        if SaviImageSearchService.isConfigured {
            VStack(alignment: .leading, spacing: 10) {
                Text("Thumbnail")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SaviTheme.textMuted)

                HStack(alignment: .center, spacing: 12) {
                    SaviListItemThumb(item: item)
                        .frame(width: 86, height: 66)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(SaviTheme.cardStroke.opacity(0.8), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            showImageSearch = true
                        } label: {
                            Label("Change thumbnail", systemImage: "magnifyingglass")
                                .font(SaviType.ui(.subheadline, weight: .black))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .padding(.horizontal, 12)
                                .background(SaviTheme.surfaceRaised)
                                .foregroundStyle(SaviTheme.text)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(SaviPressScaleButtonStyle())
                        .accessibilityHint("Search stock images for \(searchQuery)")

                        if let message {
                            Text(message)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(SaviTheme.textMuted)
                        }
                    }
                }
            }
        }
    }
}

struct WebImageSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let initialQuery: String
    let maxPixelSize: CGFloat
    let cropToSquare: Bool
    let onSelect: (String) -> Void

    @State private var query: String
    @State private var results: [SaviImageSearchResult] = []
    @State private var selectedResult: SaviImageSearchResult?
    @State private var isSearching = false
    @State private var downloadingResultId: String?
    @State private var errorMessage: String?
    @State private var didAutoSearch = false

    init(
        title: String,
        initialQuery: String,
        maxPixelSize: CGFloat,
        cropToSquare: Bool,
        onSelect: @escaping (String) -> Void
    ) {
        self.title = title
        self.initialQuery = initialQuery
        self.maxPixelSize = maxPixelSize
        self.cropToSquare = cropToSquare
        self.onSelect = onSelect
        _query = State(initialValue: initialQuery)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                searchBar

                if let errorMessage {
                    Text(errorMessage)
                        .font(SaviType.ui(.caption, weight: .bold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .saviCard(cornerRadius: 14, shadow: false)
                }

                if let selectedResult {
                    WebImageSelectedPreview(
                        result: selectedResult,
                        isDownloading: downloadingResultId == selectedResult.id
                    ) {
                        Task { await use(selectedResult) }
                    }
                }

                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2),
                        spacing: 10
                    ) {
                        ForEach(results) { result in
                            WebImageSearchResultCard(
                                result: result,
                                isSelected: selectedResult?.id == result.id
                            ) {
                                selectedResult = result
                            }
                        }
                    }
                    .padding(.bottom, 12)

                    if isSearching {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                    } else if results.isEmpty && errorMessage == nil {
                        Text("Search for a folder cover or replacement thumbnail.")
                            .font(SaviType.ui(.callout, weight: .semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 28)
                    }
                }

                imageProviderAttribution
            }
            .padding(16)
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                guard !didAutoSearch else { return }
                didAutoSearch = true
                if query.nilIfBlank != nil {
                    await search()
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(SaviTheme.textMuted)

            TextField("Search Pexels images", text: $query)
                .font(SaviType.ui(.callout, weight: .semibold))
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .onSubmit {
                    Task { await search() }
                }

            Button {
                Task { await search() }
            } label: {
                Text("Search")
                    .font(SaviType.ui(.caption, weight: .black))
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(SaviTheme.chartreuse)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
            .buttonStyle(SaviPressScaleButtonStyle())
            .disabled(query.nilIfBlank == nil || isSearching)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 48)
        .background(SaviTheme.inputSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SaviTheme.cardStroke.opacity(0.8), lineWidth: 1)
        )
    }

    private var imageProviderAttribution: some View {
        HStack(spacing: 6) {
            Text("Photos provided by")
                .font(SaviType.ui(.caption2, weight: .semibold))
                .foregroundStyle(SaviTheme.textMuted)
            Link("Pexels", destination: URL(string: "https://www.pexels.com")!)
                .font(SaviType.ui(.caption2, weight: .black))
                .foregroundStyle(SaviTheme.accentText)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    @MainActor
    private func search() async {
        guard let trimmed = query.nilIfBlank else { return }
        guard let service = SaviImageSearchService() else {
            errorMessage = "Image search is not configured on this build."
            results = []
            return
        }

        isSearching = true
        errorMessage = nil
        selectedResult = nil
        do {
            results = try await service.searchImages(query: trimmed, page: 1)
            if results.isEmpty {
                errorMessage = "No images found. Try a simpler search."
            }
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }
        isSearching = false
    }

    @MainActor
    private func use(_ result: SaviImageSearchResult) async {
        guard let service = SaviImageSearchService() else {
            errorMessage = "Image search is not configured on this build."
            return
        }

        downloadingResultId = result.id
        errorMessage = nil
        do {
            let dataURL = try await service.downloadSelection(
                result,
                maxPixelSize: maxPixelSize,
                cropToSquare: cropToSquare
            )
            onSelect(dataURL)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        downloadingResultId = nil
    }
}

private struct WebImageSearchResultCard: View {
    let result: SaviImageSearchResult
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                if let url = URL(string: result.thumbURL) {
                    SaviCachedRemoteImage(url: url) {
                        Rectangle()
                            .fill(SaviTheme.subtleSurface)
                            .overlay {
                                Image(systemName: "photo.fill")
                                    .foregroundStyle(SaviTheme.textMuted)
                            }
                    }
                    .frame(height: 116)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Text(result.photographerName?.nilIfBlank ?? result.provider)
                    .font(SaviType.ui(.caption2, weight: .bold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(1)
            }
            .padding(7)
            .background(isSelected ? SaviTheme.softAccent.opacity(0.58) : SaviTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? SaviTheme.chartreuse : SaviTheme.cardStroke, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("Image by \(result.photographerName?.nilIfBlank ?? result.provider)")
    }
}

private struct WebImageSelectedPreview: View {
    let result: SaviImageSearchResult
    let isDownloading: Bool
    let useAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let url = URL(string: result.previewURL) {
                SaviCachedRemoteImage(url: url) {
                    Rectangle()
                        .fill(SaviTheme.subtleSurface)
                }
                .frame(width: 86, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Selected image")
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                if let photographerURL = result.photographerURL.flatMap(URL.init(string:)) {
                    Link("Photo by \(result.photographerName?.nilIfBlank ?? "Pexels")", destination: photographerURL)
                        .font(SaviType.ui(.caption2, weight: .bold))
                        .foregroundStyle(SaviTheme.accentText)
                        .lineLimit(1)
                } else {
                    Text("Photo by \(result.photographerName?.nilIfBlank ?? "Pexels")")
                        .font(SaviType.ui(.caption2, weight: .bold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: useAction) {
                Group {
                    if isDownloading {
                        ProgressView()
                    } else {
                        Text("Use")
                    }
                }
                .font(SaviType.ui(.caption, weight: .black))
                .frame(width: 54, height: 38)
                .background(SaviTheme.chartreuse)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(SaviPressScaleButtonStyle())
            .disabled(isDownloading)
        }
        .padding(10)
        .saviCard(cornerRadius: 18, shadow: false)
    }
}

struct SaviImageSearchResult: Codable, Identifiable, Hashable {
    var id: String
    var provider: String
    var thumbURL: String
    var previewURL: String
    var downloadURL: String
    var photographerName: String?
    var photographerURL: String?
    var sourceURL: String?
    var averageColor: String?
}

enum SaviImageSearchError: LocalizedError {
    case notConfigured
    case badResponse
    case noUsableImage
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Image search is not configured on this build."
        case .badResponse:
            return "Image search returned something SAVI could not read."
        case .noUsableImage:
            return "That image could not be used."
        case .imageTooLarge:
            return "That image was too large to import."
        }
    }
}

struct SaviImageSearchService {
    private struct SearchEnvelope: Decodable {
        let results: [SaviImageSearchResult]
    }

    private struct DownloadResponse: Decodable {
        let dataURL: String?
    }

    private static let maximumImageBytes = 12 * 1024 * 1024
    private let baseURL: URL

    static var configuredBaseURL: URL? {
        let environment = ProcessInfo.processInfo.environment["SAVI_IMAGE_SEARCH_BASE_URL"]?.nilIfBlank
        let plistValue = Bundle.main.object(forInfoDictionaryKey: "SAVI_IMAGE_SEARCH_BASE_URL") as? String
        let rawValue = environment ?? plistValue?.nilIfBlank
        guard let rawValue else { return nil }
        return URL(string: rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    static var isConfigured: Bool {
        configuredBaseURL != nil
    }

    init?() {
        guard let baseURL = Self.configuredBaseURL else { return nil }
        self.baseURL = baseURL
    }

    func searchImages(query: String, page: Int) async throws -> [SaviImageSearchResult] {
        var components = URLComponents(url: baseURL.appendingPathComponent("image-search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(max(page, 1))"),
            URLQueryItem(name: "per_page", value: "24")
        ]
        guard let url = components?.url else { throw SaviImageSearchError.badResponse }

        var request = URLRequest(url: url)
        request.timeoutInterval = 14
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        if let envelope = try? JSONDecoder().decode(SearchEnvelope.self, from: data) {
            return envelope.results
        }
        if let results = try? JSONDecoder().decode([SaviImageSearchResult].self, from: data) {
            return results
        }
        throw SaviImageSearchError.badResponse
    }

    func downloadSelection(_ result: SaviImageSearchResult) async throws -> String {
        try await downloadSelection(result, maxPixelSize: 960, cropToSquare: false)
    }

    func downloadSelection(_ result: SaviImageSearchResult, maxPixelSize: CGFloat, cropToSquare: Bool) async throws -> String {
        let endpoint = baseURL.appendingPathComponent("image-download")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 22
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(result)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        if let decoded = try? JSONDecoder().decode(DownloadResponse.self, from: data),
           let dataURL = decoded.dataURL?.nilIfBlank {
            if let imageData = SaviImageDataURL.data(from: dataURL),
               let normalized = SaviImageDataURL.make(from: imageData, maxPixelSize: maxPixelSize, cropToSquare: cropToSquare) {
                return normalized
            }
            return dataURL
        }

        guard let dataURL = SaviImageDataURL.make(from: data, maxPixelSize: maxPixelSize, cropToSquare: cropToSquare) else {
            throw SaviImageSearchError.noUsableImage
        }
        return dataURL
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else {
            throw SaviImageSearchError.badResponse
        }
        guard data.count <= Self.maximumImageBytes else {
            throw SaviImageSearchError.imageTooLarge
        }
    }
}

enum SaviImageDataURL {
    static func make(
        from data: Data,
        maxPixelSize: CGFloat,
        cropToSquare: Bool,
        compressionQuality: CGFloat = 0.84
    ) -> String? {
        guard data.count <= 12 * 1024 * 1024,
              let image = UIImage(data: data),
              image.size.width > 0,
              image.size.height > 0
        else { return nil }

        let targetSize: CGSize
        if cropToSquare {
            targetSize = CGSize(width: maxPixelSize, height: maxPixelSize)
        } else {
            let longest = max(image.size.width, image.size.height)
            let scale = min(maxPixelSize / longest, 1)
            targetSize = CGSize(
                width: max(1, image.size.width * scale),
                height: max(1, image.size.height * scale)
            )
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let rendered = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))

            let scale = cropToSquare
                ? max(targetSize.width / image.size.width, targetSize.height / image.size.height)
                : min(targetSize.width / image.size.width, targetSize.height / image.size.height)
            let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(
                x: (targetSize.width - drawSize.width) / 2,
                y: (targetSize.height - drawSize.height) / 2
            )
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }

        guard let jpeg = rendered.jpegData(compressionQuality: compressionQuality) else { return nil }
        return "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
    }

    static func data(from dataURL: String) -> Data? {
        guard let comma = dataURL.firstIndex(of: ",") else { return nil }
        let encoded = dataURL[dataURL.index(after: comma)...]
        return Data(base64Encoded: String(encoded))
    }
}

// MARK: - Components
