import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let heroCard = UIView()
    private let previewImageView = UIImageView()
    private let previewIconView = UIImageView()
    private let statusBadge = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let titleField = UITextField()
    private let notesTextView = UITextView()
    private let folderChipsStack = UIStackView()
    private let folderSummaryLabel = UILabel()
    private let selectedTagsStack = UIStackView()
    private let suggestedTagsStack = UIStackView()
    private let tagsField = UITextField()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)

    private var pendingShare: PendingShare?
    private var selectedFolderId = "f-must-see"
    private var selectedTags: [String] = []
    private var suggestedTags: [String] = []
    private var heroGradient: CAGradientLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        Task { await loadSharedItem() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradient?.frame = heroCard.bounds
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])

        let introLabel = UILabel()
        introLabel.font = .preferredFont(forTextStyle: .headline)
        introLabel.text = "Share to SAVI"

        let helperLabel = UILabel()
        helperLabel.font = .preferredFont(forTextStyle: .subheadline)
        helperLabel.textColor = .secondaryLabel
        helperLabel.numberOfLines = 0
        helperLabel.text = "SAVI should do the heavy lifting. Your main job is just confirming the right folder and skimming the title."

        heroCard.translatesAutoresizingMaskIntoConstraints = false
        heroCard.backgroundColor = .secondarySystemBackground
        heroCard.layer.cornerRadius = 26
        heroCard.layer.masksToBounds = true
        heroCard.heightAnchor.constraint(equalToConstant: 146).isActive = true

        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.isHidden = true

        previewIconView.translatesAutoresizingMaskIntoConstraints = false
        previewIconView.tintColor = .white
        previewIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 34, weight: .semibold)
        previewIconView.contentMode = .scaleAspectFit

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.systemIndigo.withAlphaComponent(0.28).cgColor,
            UIColor.black.withAlphaComponent(0.84).cgColor
        ]
        gradient.locations = [0.12, 1.0]
        heroCard.layer.addSublayer(gradient)
        heroGradient = gradient

        statusBadge.font = .preferredFont(forTextStyle: .caption1)
        statusBadge.textColor = .white
        statusBadge.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.94)
        statusBadge.layer.cornerRadius = 999
        statusBadge.layer.masksToBounds = true
        statusBadge.textAlignment = .center
        statusBadge.text = "Analyzing"
        statusBadge.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont.preferredFont(forTextStyle: .title3).bold()
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.text = "Preparing your save…"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        subtitleLabel.numberOfLines = 3
        subtitleLabel.text = "Looking for the title, preview, folder, and useful tags."
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()

        heroCard.addSubview(previewImageView)
        heroCard.addSubview(previewIconView)
        heroCard.addSubview(statusBadge)
        heroCard.addSubview(titleLabel)
        heroCard.addSubview(subtitleLabel)
        heroCard.addSubview(spinner)

        NSLayoutConstraint.activate([
            previewImageView.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor),
            previewImageView.topAnchor.constraint(equalTo: heroCard.topAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: heroCard.bottomAnchor),

            previewIconView.centerXAnchor.constraint(equalTo: heroCard.centerXAnchor),
            previewIconView.centerYAnchor.constraint(equalTo: heroCard.centerYAnchor, constant: -8),
            previewIconView.widthAnchor.constraint(equalToConstant: 52),
            previewIconView.heightAnchor.constraint(equalToConstant: 52),

            statusBadge.topAnchor.constraint(equalTo: heroCard.topAnchor, constant: 16),
            statusBadge.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 16),
            statusBadge.heightAnchor.constraint(equalToConstant: 30),
            statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 104),

            titleLabel.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -6),

            subtitleLabel.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: -16),

            spinner.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -16),
            spinner.centerYAnchor.constraint(equalTo: statusBadge.centerYAnchor),
        ])

        let folderSection = makeSectionCard()
        let folderLabel = makeSectionLabel("Choose the folder")
        let folderHint = makeHintLabel("This is the main decision. SAVI suggests the best home, and you can tap another one in one motion.")
        folderSummaryLabel.font = UIFont.preferredFont(forTextStyle: .subheadline).bold()
        folderSummaryLabel.textColor = .systemIndigo
        folderSummaryLabel.numberOfLines = 2
        folderSummaryLabel.text = "Suggested: Must See"
        folderChipsStack.axis = .vertical
        folderChipsStack.spacing = 10
        folderSection.addArrangedSubview(folderLabel)
        folderSection.addArrangedSubview(folderHint)
        folderSection.addArrangedSubview(folderSummaryLabel)
        folderSection.addArrangedSubview(folderChipsStack)

        let titleSection = makeSectionCard()
        titleSection.addArrangedSubview(makeSectionLabel("Title"))
        titleField.borderStyle = .none
        titleField.backgroundColor = .secondarySystemBackground
        titleField.layer.cornerRadius = 14
        titleField.placeholder = "Shared item"
        titleField.delegate = self
        titleField.setContentHuggingPriority(.defaultLow, for: .vertical)
        titleField.heightAnchor.constraint(equalToConstant: 48).isActive = true
        titleField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        titleField.leftViewMode = .always
        titleSection.addArrangedSubview(titleField)

        let notesSection = makeSectionCard()
        notesSection.addArrangedSubview(makeSectionLabel("Notes"))
        notesTextView.font = .preferredFont(forTextStyle: .body)
        notesTextView.layer.cornerRadius = 16
        notesTextView.layer.borderColor = UIColor.separator.cgColor
        notesTextView.layer.borderWidth = 1
        notesTextView.backgroundColor = .secondarySystemBackground
        notesTextView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        notesTextView.heightAnchor.constraint(equalToConstant: 112).isActive = true
        notesSection.addArrangedSubview(notesTextView)

        let tagsSection = makeSectionCard()
        tagsSection.addArrangedSubview(makeSectionLabel("Tags"))
        tagsSection.addArrangedSubview(makeHintLabel("SAVI keeps several search-friendly tags by default so this is easy to find later. Tap to keep, remove, or add more."))

        selectedTagsStack.axis = .vertical
        selectedTagsStack.spacing = 10
        suggestedTagsStack.axis = .vertical
        suggestedTagsStack.spacing = 10

        let selectedLabel = makeSubsectionLabel("Selected tags")
        let suggestedLabel = makeSubsectionLabel("Suggested tags")
        tagsField.borderStyle = .none
        tagsField.backgroundColor = .secondarySystemBackground
        tagsField.layer.cornerRadius = 14
        tagsField.placeholder = "Add extra tags, comma separated"
        tagsField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tagsField.leftViewMode = .always
        tagsField.heightAnchor.constraint(equalToConstant: 46).isActive = true

        tagsSection.addArrangedSubview(selectedLabel)
        tagsSection.addArrangedSubview(selectedTagsStack)
        tagsSection.addArrangedSubview(suggestedLabel)
        tagsSection.addArrangedSubview(suggestedTagsStack)
        tagsSection.addArrangedSubview(tagsField)

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
            folderSection,
            titleSection,
            tagsSection,
            heroCard,
            notesSection,
            actionStack,
        ].forEach { contentStack.addArrangedSubview($0) }

        rebuildFolderChips()
        rebuildTagChips()
    }

    private func makeSectionCard() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.backgroundColor = .systemBackground
        stack.layer.cornerRadius = 22
        stack.layer.shadowColor = UIColor.black.cgColor
        stack.layer.shadowOpacity = 0.06
        stack.layer.shadowRadius = 14
        stack.layer.shadowOffset = CGSize(width: 0, height: 6)
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
                subtitleLabel.text = "Pulling the preview, title, and best folder."
                saveButton.isEnabled = true
            }

            let enriched = await ShareItemExtractor.enrich(share)
            await MainActor.run {
                pendingShare = enriched
                applyShare(enriched, animated: true)
                spinner.stopAnimating()
                statusBadge.text = "Ready"
                subtitleLabel.text = "Trust the auto-fill or quickly adjust the folder, notes, and tags."
            }
        } catch {
            await MainActor.run {
                titleLabel.text = "Couldn’t read this share"
                subtitleLabel.text = error.localizedDescription
                previewIconView.image = UIImage(systemName: "exclamationmark.triangle.fill")
                spinner.stopAnimating()
            }
        }
    }

    private func applyShare(_ share: PendingShare, animated: Bool) {
        titleLabel.text = share.title
        let summary = share.itemDescription ?? share.text ?? previewText(for: share)
        subtitleLabel.text = summary
        titleField.text = share.title
        notesTextView.text = summary
        selectedFolderId = share.folderId ?? selectedFolderId
        selectedTags = dedupeTags(share.tags ?? [])
        suggestedTags = suggestionTags(for: share).filter { !selectedTags.map { $0.lowercased() }.contains($0.lowercased()) }
        rebuildFolderChips()
        rebuildTagChips()
        configurePreview(for: share)

        if animated {
            UIView.transition(with: heroCard, duration: 0.22, options: .transitionCrossDissolve, animations: {}, completion: nil)
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
        guard let thumbnail, thumbnail.hasPrefix("data:"),
              let commaIndex = thumbnail.firstIndex(of: ",")
        else {
            return nil
        }
        let encoded = String(thumbnail[thumbnail.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: encoded) else { return nil }
        return UIImage(data: data)
    }

    private func rebuildFolderChips() {
        clearArrangedSubviews(of: folderChipsStack)
        let presets = ShareItemExtractor.folderPresets
        let selectedName = presets.first(where: { $0.id == selectedFolderId })?.name ?? "Must See"
        folderSummaryLabel.text = "Suggested folder: \(selectedName)"
        for row in stride(from: 0, to: presets.count, by: 2) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 10
            rowStack.distribution = .fillEqually
            let end = min(row + 2, presets.count)
            for preset in presets[row..<end] {
                let button = makeFolderButton(for: preset)
                rowStack.addArrangedSubview(button)
            }
            if end - row == 1 {
                rowStack.addArrangedSubview(UIView())
            }
            folderChipsStack.addArrangedSubview(rowStack)
        }
    }

    private func makeFolderButton(for preset: FolderPreset) -> UIButton {
        let isSelected = preset.id == selectedFolderId
        var config = UIButton.Configuration.filled()
        config.title = preset.name
        config.cornerStyle = .large
        config.baseBackgroundColor = isSelected ? .systemIndigo : UIColor.secondarySystemBackground.withAlphaComponent(0.95)
        config.baseForegroundColor = isSelected ? .white : .label
        config.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "folder.fill")
        config.imagePadding = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        let button = UIButton(configuration: config)
        button.tag = ShareItemExtractor.folderPresets.firstIndex(where: { $0.id == preset.id }) ?? 0
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.addTarget(self, action: #selector(folderTapped(_:)), for: .touchUpInside)
        return button
    }

    private func rebuildTagChips() {
        clearArrangedSubviews(of: selectedTagsStack)
        clearArrangedSubviews(of: suggestedTagsStack)

        if selectedTags.isEmpty {
            let label = makeHintLabel("No tags selected yet. SAVI will still save this cleanly.")
            selectedTagsStack.addArrangedSubview(label)
        } else {
            buildChipRows(in: selectedTagsStack, values: selectedTags, selected: true)
        }

        if suggestedTags.isEmpty {
            let label = makeHintLabel("No extra suggestions right now.")
            suggestedTagsStack.addArrangedSubview(label)
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
                let button = makeTagButton(for: value, selected: selected)
                rowStack.addArrangedSubview(button)
            }
            if end - row == 1 { rowStack.addArrangedSubview(UIView()) }
            if end - row == 2 { rowStack.addArrangedSubview(UIView()) }
            container.addArrangedSubview(rowStack)
        }
    }

    private func makeTagButton(for value: String, selected: Bool) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = selected ? "#\(value)  ×" : "#\(value)"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = selected ? UIColor.systemIndigo.withAlphaComponent(0.14) : .secondarySystemBackground
        config.baseForegroundColor = selected ? .systemIndigo : .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 10, bottom: 9, trailing: 10)
        let button = UIButton(configuration: config)
        button.accessibilityLabel = selected ? "Remove tag \(value)" : "Add tag \(value)"
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

    private func toggleTag(_ value: String, forceSelection: Bool? = nil) {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        let shouldSelect = forceSelection ?? !selectedTags.map { $0.lowercased() }.contains(normalized.lowercased())
        if shouldSelect {
            selectedTags = dedupeTags(selectedTags + [normalized])
            suggestedTags.removeAll { $0.caseInsensitiveCompare(normalized) == .orderedSame }
        } else {
            selectedTags.removeAll { $0.caseInsensitiveCompare(normalized) == .orderedSame }
            if !suggestedTags.map({ $0.lowercased() }).contains(normalized.lowercased()) {
                suggestedTags = dedupeTags([normalized] + suggestedTags)
            }
        }
        rebuildTagChips()
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
        if let url = share.url, !url.isEmpty {
            return "\(share.type.capitalized) from \(share.sourceApp)\n\(url)"
        }
        if let fileName = share.fileName, !fileName.isEmpty {
            return "\(share.type.capitalized) from \(share.sourceApp)\n\(fileName)"
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
        rebuildFolderChips()
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
            subtitleLabel.text = error.localizedDescription
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
