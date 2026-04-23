import UIKit

final class ShareViewController: UIViewController, UITextFieldDelegate {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let previewCard = UIView()
    private let previewImageView = UIImageView()
    private let previewIconView = UIImageView()
    private let statusBadge = UILabel()
    private let previewTitleLabel = UILabel()
    private let previewSubtitleLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    private let folderSummaryLabel = UILabel()
    private let folderGridStack = UIStackView()
    private let titleField = UITextField()
    private let selectedTagsStack = UIStackView()
    private let suggestedTagsStack = UIStackView()
    private let tagsField = UITextField()
    private let notesToggleButton = UIButton(type: .system)
    private let notesTextView = UITextView()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    private var pendingShare: PendingShare?
    private var selectedFolderId = "f-must-see"
    private var selectedTags: [String] = []
    private var suggestedTags: [String] = []
    private var notesExpanded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        Task { await loadSharedItem() }
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.968, green: 0.972, blue: 0.985, alpha: 1)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -18),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 18),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -36),
        ])

        let introLabel = UILabel()
        introLabel.font = .preferredFont(forTextStyle: .headline)
        introLabel.text = "Share to SAVI"

        let helperLabel = UILabel()
        helperLabel.font = .preferredFont(forTextStyle: .subheadline)
        helperLabel.textColor = .secondaryLabel
        helperLabel.numberOfLines = 0
        helperLabel.text = "SAVI should figure out the details. You mostly just confirm the folder."

        configurePreviewCard()

        let folderSection = makeSectionCard()
        folderSection.addArrangedSubview(makeSectionLabel("Folder"))
        folderSummaryLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).bold()
        folderSummaryLabel.textColor = .systemIndigo
        folderSummaryLabel.numberOfLines = 2
        folderSection.addArrangedSubview(folderSummaryLabel)
        folderGridStack.axis = .vertical
        folderGridStack.spacing = 8
        folderSection.addArrangedSubview(folderGridStack)

        let titleSection = makeSectionCard()
        titleSection.addArrangedSubview(makeSectionLabel("Title"))
        configureTextField(titleField, placeholder: "Shared item")
        titleSection.addArrangedSubview(titleField)

        let tagsSection = makeSectionCard()
        tagsSection.addArrangedSubview(makeSectionLabel("Tags"))
        tagsSection.addArrangedSubview(makeHintLabel("Keep a few useful tags. You do not need a giant wall of keywords."))
        let selectedLabel = makeSubsectionLabel("Selected")
        let suggestedLabel = makeSubsectionLabel("Suggestions")
        selectedTagsStack.axis = .vertical
        selectedTagsStack.spacing = 8
        suggestedTagsStack.axis = .vertical
        suggestedTagsStack.spacing = 8
        configureTextField(tagsField, placeholder: "Add extra tags, comma separated")
        tagsSection.addArrangedSubview(selectedLabel)
        tagsSection.addArrangedSubview(selectedTagsStack)
        tagsSection.addArrangedSubview(suggestedLabel)
        tagsSection.addArrangedSubview(suggestedTagsStack)
        tagsSection.addArrangedSubview(tagsField)

        let notesSection = makeSectionCard()
        notesToggleButton.configuration = .plain()
        notesToggleButton.contentHorizontalAlignment = .leading
        notesToggleButton.addTarget(self, action: #selector(toggleNotes), for: .touchUpInside)
        notesSection.addArrangedSubview(notesToggleButton)
        notesTextView.font = .preferredFont(forTextStyle: .body)
        notesTextView.layer.cornerRadius = 14
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = UIColor.separator.cgColor
        notesTextView.backgroundColor = .secondarySystemBackground
        notesTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        notesTextView.heightAnchor.constraint(equalToConstant: 96).isActive = true
        notesSection.addArrangedSubview(notesTextView)

        let actionStack = UIStackView(arrangedSubviews: [cancelButton, saveButton])
        actionStack.axis = .horizontal
        actionStack.spacing = 12
        actionStack.distribution = .fillEqually

        var cancelConfig = UIButton.Configuration.tinted()
        cancelConfig.title = "Cancel"
        cancelConfig.cornerStyle = .large
        cancelButton.configuration = cancelConfig
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        var saveConfig = UIButton.Configuration.filled()
        saveConfig.title = "Save to SAVI"
        saveConfig.cornerStyle = .large
        saveConfig.baseBackgroundColor = .systemIndigo
        saveButton.configuration = saveConfig
        saveButton.isEnabled = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        [
            introLabel,
            helperLabel,
            previewCard,
            folderSection,
            titleSection,
            tagsSection,
            notesSection,
            actionStack,
        ].forEach { contentStack.addArrangedSubview($0) }

        setNotesExpanded(false, animated: false)
        rebuildFolderButtons()
        rebuildTagViews()
    }

    private func configurePreviewCard() {
        previewCard.backgroundColor = .systemBackground
        previewCard.layer.cornerRadius = 22
        previewCard.layer.shadowColor = UIColor.black.cgColor
        previewCard.layer.shadowOpacity = 0.06
        previewCard.layer.shadowRadius = 14
        previewCard.layer.shadowOffset = CGSize(width: 0, height: 6)
        previewCard.translatesAutoresizingMaskIntoConstraints = false

        let innerStack = UIStackView()
        innerStack.axis = .horizontal
        innerStack.alignment = .top
        innerStack.spacing = 12
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        previewCard.addSubview(innerStack)

        NSLayoutConstraint.activate([
            innerStack.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 14),
            innerStack.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -14),
            innerStack.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 14),
            innerStack.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: -14),
        ])

        let mediaWrap = UIView()
        mediaWrap.translatesAutoresizingMaskIntoConstraints = false
        mediaWrap.widthAnchor.constraint(equalToConstant: 82).isActive = true
        mediaWrap.heightAnchor.constraint(equalToConstant: 82).isActive = true
        mediaWrap.layer.cornerRadius = 18
        mediaWrap.layer.masksToBounds = true
        mediaWrap.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.14)

        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.isHidden = true

        previewIconView.translatesAutoresizingMaskIntoConstraints = false
        previewIconView.tintColor = .systemIndigo
        previewIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)
        previewIconView.contentMode = .scaleAspectFit

        mediaWrap.addSubview(previewImageView)
        mediaWrap.addSubview(previewIconView)
        NSLayoutConstraint.activate([
            previewImageView.leadingAnchor.constraint(equalTo: mediaWrap.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: mediaWrap.trailingAnchor),
            previewImageView.topAnchor.constraint(equalTo: mediaWrap.topAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: mediaWrap.bottomAnchor),
            previewIconView.centerXAnchor.constraint(equalTo: mediaWrap.centerXAnchor),
            previewIconView.centerYAnchor.constraint(equalTo: mediaWrap.centerYAnchor),
            previewIconView.widthAnchor.constraint(equalToConstant: 30),
            previewIconView.heightAnchor.constraint(equalToConstant: 30),
        ])

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 8

        statusBadge.font = .preferredFont(forTextStyle: .caption1)
        statusBadge.textColor = .white
        statusBadge.backgroundColor = .systemIndigo
        statusBadge.layer.cornerRadius = 999
        statusBadge.layer.masksToBounds = true
        statusBadge.textAlignment = .center
        statusBadge.text = "Analyzing"
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.heightAnchor.constraint(equalToConstant: 28).isActive = true
        statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 98).isActive = true

        previewTitleLabel.font = UIFont.preferredFont(forTextStyle: .headline).bold()
        previewTitleLabel.numberOfLines = 2
        previewTitleLabel.textColor = .label
        previewTitleLabel.text = "Preparing your save…"

        previewSubtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        previewSubtitleLabel.numberOfLines = 3
        previewSubtitleLabel.textColor = .secondaryLabel
        previewSubtitleLabel.text = "Looking for the title, preview, folder, and useful tags."

        spinner.startAnimating()

        let topRow = UIStackView(arrangedSubviews: [statusBadge, UIView(), spinner])
        topRow.axis = .horizontal
        topRow.alignment = .center

        textStack.addArrangedSubview(topRow)
        textStack.addArrangedSubview(previewTitleLabel)
        textStack.addArrangedSubview(previewSubtitleLabel)

        innerStack.addArrangedSubview(mediaWrap)
        innerStack.addArrangedSubview(textStack)
    }

    private func configureTextField(_ textField: UITextField, placeholder: String) {
        textField.borderStyle = .none
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 14
        textField.placeholder = placeholder
        textField.heightAnchor.constraint(equalToConstant: 46).isActive = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.leftViewMode = .always
        textField.delegate = self
    }

    private func makeSectionCard() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        stack.backgroundColor = .systemBackground
        stack.layer.cornerRadius = 20
        stack.layer.shadowColor = UIColor.black.cgColor
        stack.layer.shadowOpacity = 0.05
        stack.layer.shadowRadius = 12
        stack.layer.shadowOffset = CGSize(width: 0, height: 5)
        return stack
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.text = text
        return label
    }

    private func makeSubsectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.text = text
        return label
    }

    private func makeHintLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.text = text
        return label
    }

    private func loadSharedItem() async {
        do {
            let share = try await ShareItemExtractor.extract(from: extensionContext)
            await MainActor.run {
                pendingShare = share
                applyShare(share, animated: false)
                statusBadge.text = "Analyzing"
                previewSubtitleLabel.text = "Pulling the title, folder, and a few useful tags."
                saveButton.isEnabled = true
            }

            let enriched = await ShareItemExtractor.enrich(share)
            await MainActor.run {
                pendingShare = enriched
                applyShare(enriched, animated: true)
                spinner.stopAnimating()
                statusBadge.text = "Ready"
                previewSubtitleLabel.text = "Looks good. Pick the folder, skim the title, and save."
            }
        } catch {
            await MainActor.run {
                previewTitleLabel.text = "Couldn’t read this share"
                previewSubtitleLabel.text = error.localizedDescription
                previewIconView.image = UIImage(systemName: "exclamationmark.triangle.fill")
                spinner.stopAnimating()
            }
        }
    }

    private func applyShare(_ share: PendingShare, animated: Bool) {
        let summary = share.itemDescription ?? share.text ?? previewText(for: share)
        previewTitleLabel.text = share.title
        previewSubtitleLabel.text = summary
        titleField.text = share.title
        notesTextView.text = summary
        selectedFolderId = share.folderId ?? selectedFolderId
        selectedTags = Array(dedupeTags(share.tags ?? []).prefix(5))
        suggestedTags = Array(suggestionTags(for: share).filter { !selectedTags.map { $0.lowercased() }.contains($0.lowercased()) }.prefix(6))
        rebuildFolderButtons()
        rebuildTagViews()
        configurePreview(for: share)
        if animated {
            UIView.transition(with: previewCard, duration: 0.2, options: .transitionCrossDissolve, animations: {}, completion: nil)
        }
    }

    private func configurePreview(for share: PendingShare) {
        if let thumbnail = share.thumbnail, !thumbnail.isEmpty {
            loadPreview(from: thumbnail)
            return
        }
        previewImageView.image = nil
        previewImageView.isHidden = true
        previewIconView.isHidden = false
        previewIconView.image = UIImage(systemName: previewSymbolName(for: share))
    }

    private func loadPreview(from thumbnail: String) {
        if let image = imageFromDataURL(thumbnail) {
            previewImageView.image = image
            previewImageView.isHidden = false
            previewIconView.isHidden = true
            return
        }
        guard let url = URL(string: thumbnail), url.scheme?.hasPrefix("http") == true else {
            previewImageView.image = nil
            previewImageView.isHidden = true
            previewIconView.isHidden = false
            previewIconView.image = UIImage(systemName: previewSymbolName(for: pendingShare ?? PendingShare(id: "", url: nil, title: "", type: "link", thumbnail: nil, timestamp: 0, sourceApp: "", text: nil, fileName: nil, filePath: nil, mimeType: nil, itemDescription: nil, folderId: nil, tags: nil)))
            return
        }

        Task {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                await MainActor.run {
                    self.previewImageView.image = image
                    self.previewImageView.isHidden = false
                    self.previewIconView.isHidden = true
                }
            }
        }
    }

    private func imageFromDataURL(_ thumbnail: String?) -> UIImage? {
        guard let thumbnail,
              thumbnail.hasPrefix("data:"),
              let commaIndex = thumbnail.firstIndex(of: ",")
        else { return nil }
        let encoded = String(thumbnail[thumbnail.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: encoded) else { return nil }
        return UIImage(data: data)
    }

    private func rebuildFolderButtons() {
        clearArrangedSubviews(of: folderGridStack)
        let presets = ShareItemExtractor.folderPresets
        let selectedName = presets.first(where: { $0.id == selectedFolderId })?.name ?? "Must See"
        folderSummaryLabel.text = "Suggested folder: \(selectedName)"

        for row in stride(from: 0, to: presets.count, by: 2) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.distribution = .fillEqually
            let end = min(row + 2, presets.count)
            for preset in presets[row..<end] {
                rowStack.addArrangedSubview(makeFolderButton(for: preset))
            }
            if end - row == 1 { rowStack.addArrangedSubview(UIView()) }
            folderGridStack.addArrangedSubview(rowStack)
        }
    }

    private func makeFolderButton(for preset: FolderPreset) -> UIButton {
        let isSelected = preset.id == selectedFolderId
        var config = UIButton.Configuration.filled()
        config.title = preset.name
        config.cornerStyle = .medium
        config.baseBackgroundColor = isSelected ? .systemIndigo : UIColor.secondarySystemBackground
        config.baseForegroundColor = isSelected ? .white : .label
        config.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "folder")
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        let button = UIButton(configuration: config)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.tag = ShareItemExtractor.folderPresets.firstIndex(where: { $0.id == preset.id }) ?? 0
        button.addTarget(self, action: #selector(folderTapped(_:)), for: .touchUpInside)
        return button
    }

    private func rebuildTagViews() {
        clearArrangedSubviews(of: selectedTagsStack)
        clearArrangedSubviews(of: suggestedTagsStack)

        if selectedTags.isEmpty {
            selectedTagsStack.addArrangedSubview(makeHintLabel("SAVI will still save this cleanly without extra tags."))
        } else {
            buildChipRows(in: selectedTagsStack, values: selectedTags, selected: true)
        }

        if suggestedTags.isEmpty {
            suggestedTagsStack.addArrangedSubview(makeHintLabel("No extra tag suggestions right now."))
        } else {
            buildChipRows(in: suggestedTagsStack, values: suggestedTags, selected: false)
        }
    }

    private func buildChipRows(in container: UIStackView, values: [String], selected: Bool) {
        for row in stride(from: 0, to: values.count, by: 3) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.distribution = .fillEqually
            let end = min(row + 3, values.count)
            for value in values[row..<end] {
                rowStack.addArrangedSubview(makeTagButton(for: value, selected: selected))
            }
            if end - row == 1 { rowStack.addArrangedSubview(UIView()) }
            if end - row == 2 { rowStack.addArrangedSubview(UIView()) }
            container.addArrangedSubview(rowStack)
        }
    }

    private func makeTagButton(for value: String, selected: Bool) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = selected ? value : "+ \(value)"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = selected ? UIColor.systemIndigo.withAlphaComponent(0.14) : .secondarySystemBackground
        config.baseForegroundColor = selected ? .systemIndigo : .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
        let button = UIButton(configuration: config)
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.toggleTag(value, forceSelection: !selected)
        }), for: .touchUpInside)
        return button
    }

    private func suggestionTags(for share: PendingShare) -> [String] {
        let base = [share.title, share.itemDescription, share.url, share.sourceApp]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

        var tags = share.tags ?? []
        for token in ["ai", "claude", "chatgpt", "news", "reddit", "instagram", "youtube", "recipe", "travel", "design", "research", "career", "productivity", "video", "article", "maps", "place", "health", "science", "conspiracy"] where base.contains(token) {
            tags.append(token)
        }
        return dedupeTags(tags)
    }

    @objc private func toggleNotes() {
        setNotesExpanded(!notesExpanded, animated: true)
    }

    private func setNotesExpanded(_ expanded: Bool, animated: Bool) {
        notesExpanded = expanded
        var config = UIButton.Configuration.plain()
        config.title = expanded ? "Hide note" : "Add a note"
        config.image = UIImage(systemName: expanded ? "chevron.up" : "plus.circle")
        config.imagePadding = 6
        config.baseForegroundColor = .secondaryLabel
        notesToggleButton.configuration = config
        let changes = {
            self.notesTextView.isHidden = !expanded
        }
        if animated {
            UIView.animate(withDuration: 0.18, animations: changes)
        } else {
            changes()
        }
    }

    private func toggleTag(_ value: String, forceSelection: Bool? = nil) {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let shouldSelect = forceSelection ?? !selectedTags.map { $0.lowercased() }.contains(normalized.lowercased())
        if shouldSelect {
            selectedTags = Array(dedupeTags(selectedTags + [normalized]).prefix(6))
            suggestedTags.removeAll { $0.caseInsensitiveCompare(normalized) == .orderedSame }
        } else {
            selectedTags.removeAll { $0.caseInsensitiveCompare(normalized) == .orderedSame }
            if !suggestedTags.map({ $0.lowercased() }).contains(normalized.lowercased()) {
                suggestedTags = Array(dedupeTags([normalized] + suggestedTags).prefix(6))
            }
        }
        rebuildTagViews()
    }

    private func clearArrangedSubviews(of stackView: UIStackView) {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func dedupeTags(_ rawTags: [String]) -> [String] {
        var seen = Set<String>()
        return rawTags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0.lowercased()).inserted }
    }

    private func previewText(for share: PendingShare) -> String {
        if let fileName = share.fileName, !fileName.isEmpty {
            return "\(share.type.capitalized) from \(share.sourceApp)\n\(fileName)"
        }
        if let url = share.url, !url.isEmpty {
            return "\(share.type.capitalized) from \(share.sourceApp)\n\(url)"
        }
        return "\(share.type.capitalized) from \(share.sourceApp)"
    }

    private func previewSymbolName(for share: PendingShare) -> String {
        switch share.type.lowercased() {
        case "image":
            return "photo"
        case "pdf":
            return "doc.richtext"
        case "file":
            return "doc"
        case "article", "text":
            return "doc.text"
        case "video":
            return "play.rectangle.fill"
        case "place":
            return "mappin.and.ellipse"
        default:
            return share.url?.isEmpty == false ? "link" : "square.and.arrow.down"
        }
    }

    @objc private func folderTapped(_ sender: UIButton) {
        guard ShareItemExtractor.folderPresets.indices.contains(sender.tag) else { return }
        selectedFolderId = ShareItemExtractor.folderPresets[sender.tag].id
        rebuildFolderButtons()
    }

    @objc private func cancelTapped() {
        extensionContext?.cancelRequest(withError: NSError(domain: "SAVIShareExtension", code: 0))
    }

    @objc private func saveTapped() {
        guard var pendingShare else { return }

        let trimmedTitle = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notesTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let manualTags = (tagsField.text ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        pendingShare.title = trimmedTitle.nilIfEmpty ?? pendingShare.title
        pendingShare.itemDescription = trimmedNotes.nilIfEmpty
        pendingShare.folderId = selectedFolderId
        pendingShare.tags = dedupeTags(selectedTags + manualTags)

        do {
            try PendingShareStore.shared.save(pendingShare)
            saveButton.isEnabled = false
            var updated = saveButton.configuration
            updated?.title = "Saved"
            saveButton.configuration = updated
            extensionContext?.completeRequest(returningItems: nil)
        } catch {
            previewSubtitleLabel.text = error.localizedDescription
        }
    }
}

private extension UIFont {
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
