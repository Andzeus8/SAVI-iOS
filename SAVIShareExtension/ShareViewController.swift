import UIKit

final class ShareViewController: UIViewController, UITextFieldDelegate {
    private let topBar = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let previewCard = UIView()
    private let previewImageView = UIImageView()
    private let previewIconView = UIImageView()
    private let statusBadge = UILabel()
    private let previewTitleLabel = UILabel()
    private let previewMetaLabel = UILabel()
    private let previewSubtitleLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    private let recentFoldersCard = UIView()
    private let recentFoldersScrollView = UIScrollView()
    private let recentFoldersRow = UIStackView()
    private let recentFoldersHintLabel = UILabel()

    private let folderSummaryCard = UIView()
    private let folderSummaryIconWrap = UIView()
    private let folderSummaryIconView = UIImageView()
    private let folderSummaryTitleLabel = UILabel()
    private let folderSummaryHintLabel = UILabel()
    private let folderGridStack = UIStackView()

    private let titleField = UITextField()

    private let selectedTagScrollView = UIScrollView()
    private let selectedTagRow = UIStackView()
    private let suggestedTagScrollView = UIScrollView()
    private let suggestedTagRow = UIStackView()
    private let tagsField = UITextField()

    private let notesToggleButton = UIButton(type: .system)
    private let notesTextView = UITextView()

    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let quickBannerLabel = UILabel()

    private var rawShare: PendingShare?
    private var pendingShare: PendingShare?
    private var availableFolders: [FolderPreset] = ShareItemExtractor.folderPresets()
    private var recentFolders: [FolderPreset] = ShareItemExtractor.recentFolderPresets()
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
        view.backgroundColor = UIColor(red: 0.967, green: 0.973, blue: 0.988, alpha: 1)

        configureTopBar()
        configureQuickBanner()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 18),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -18),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 14),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -36),
        ])

        configurePreviewCard()
        configureRecentFoldersCard()
        configureFolderSummaryCard()

        let quickSection = makeSectionCard(emphasized: true)
        quickSection.addArrangedSubview(makeSectionLabel("Quick send"))
        quickSection.addArrangedSubview(makeHintLabel("This is the closest fast path to WhatsApp-style recents on iOS. Tap a folder once and SAVI will save it instantly there."))
        quickSection.addArrangedSubview(recentFoldersCard)

        let folderSection = makeSectionCard(emphasized: true)
        folderSection.addArrangedSubview(makeSectionLabel("Save in"))
        folderSection.addArrangedSubview(makeHintLabel("SAVI picked the folder for you. Tap another one only if you want to override it."))
        folderSection.addArrangedSubview(folderSummaryCard)
        configureFolderGrid()
        folderSection.addArrangedSubview(folderGridStack)

        let titleSection = makeSectionCard()
        titleSection.addArrangedSubview(makeSectionLabel("Title"))
        titleSection.addArrangedSubview(makeHintLabel("Quick gut check. If this looks right, hit Save from the top and move on."))
        configureTextField(titleField, placeholder: "Shared item")
        titleSection.addArrangedSubview(titleField)

        let tagsSection = makeSectionCard()
        tagsSection.addArrangedSubview(makeSectionLabel("Tags"))
        tagsSection.addArrangedSubview(makeHintLabel("A few smart tags make this easy to find later. Keep the strongest ones."))
        tagsSection.addArrangedSubview(makeSubsectionLabel("Selected"))
        configureHorizontalStrip(scrollView: selectedTagScrollView, row: selectedTagRow, height: 42)
        tagsSection.addArrangedSubview(selectedTagScrollView)
        tagsSection.addArrangedSubview(makeSubsectionLabel("Suggestions"))
        configureHorizontalStrip(scrollView: suggestedTagScrollView, row: suggestedTagRow, height: 42)
        tagsSection.addArrangedSubview(suggestedTagScrollView)
        configureTextField(tagsField, placeholder: "Add extra tags, comma separated")
        tagsSection.addArrangedSubview(tagsField)

        let notesSection = makeSectionCard()
        configureNotesToggle()
        notesSection.addArrangedSubview(makeSectionLabel("Optional note"))
        notesSection.addArrangedSubview(notesToggleButton)
        notesTextView.font = .preferredFont(forTextStyle: .body)
        notesTextView.textColor = .label
        notesTextView.backgroundColor = UIColor.secondarySystemBackground
        notesTextView.layer.cornerRadius = 16
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = UIColor.separator.withAlphaComponent(0.45).cgColor
        notesTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        notesTextView.heightAnchor.constraint(equalToConstant: 94).isActive = true
        notesSection.addArrangedSubview(notesTextView)

        [previewCard, quickSection, folderSection, titleSection, tagsSection, notesSection].forEach { contentStack.addArrangedSubview($0) }

        setNotesExpanded(false, animated: false)
        if let firstFolder = availableFolders.first?.id, !firstFolder.isEmpty {
            selectedFolderId = firstFolder
        }
        rebuildRecentFolders()
        rebuildFolderButtons()
        rebuildTagViews()
        updateSaveButton(isReady: false)
    }

    private func configureTopBar() {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = UIColor(red: 0.967, green: 0.973, blue: 0.988, alpha: 0.84)
        view.addSubview(topBar)

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialLight))
        blur.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(blur)

        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.32)
        topBar.addSubview(divider)

        let controls = UIStackView()
        controls.axis = .horizontal
        controls.alignment = .center
        controls.spacing = 12
        controls.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(controls)

        var cancelConfig = UIButton.Configuration.plain()
        cancelConfig.title = "Cancel"
        cancelConfig.baseForegroundColor = .secondaryLabel
        cancelButton.configuration = cancelConfig
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 1

        let sheetTitle = UILabel()
        sheetTitle.font = .preferredFont(forTextStyle: .headline).bold()
        sheetTitle.text = "Save to SAVI"

        let sheetSubtitle = UILabel()
        sheetSubtitle.font = .preferredFont(forTextStyle: .caption1)
        sheetSubtitle.textColor = .secondaryLabel
        sheetSubtitle.text = "Folder first. Save from here."

        titleStack.addArrangedSubview(sheetTitle)
        titleStack.addArrangedSubview(sheetSubtitle)

        var saveConfig = UIButton.Configuration.filled()
        saveConfig.title = "Save"
        saveConfig.cornerStyle = .capsule
        saveConfig.baseBackgroundColor = .systemIndigo
        saveConfig.baseForegroundColor = .white
        saveConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        saveButton.configuration = saveConfig
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        controls.addArrangedSubview(cancelButton)
        controls.addArrangedSubview(titleStack)
        controls.addArrangedSubview(UIView())
        controls.addArrangedSubview(saveButton)

        NSLayoutConstraint.activate([
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.topAnchor.constraint(equalTo: view.topAnchor),

            blur.leadingAnchor.constraint(equalTo: topBar.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: topBar.trailingAnchor),
            blur.topAnchor.constraint(equalTo: topBar.topAnchor),
            blur.bottomAnchor.constraint(equalTo: topBar.bottomAnchor),

            controls.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            controls.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            controls.topAnchor.constraint(equalTo: topBar.safeAreaLayoutGuide.topAnchor, constant: 8),
            controls.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: -10),

            divider.leadingAnchor.constraint(equalTo: topBar.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: topBar.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: topBar.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    private func configurePreviewCard() {
        previewCard.backgroundColor = .systemBackground
        previewCard.layer.cornerRadius = 22
        previewCard.layer.shadowColor = UIColor.black.cgColor
        previewCard.layer.shadowOpacity = 0.07
        previewCard.layer.shadowRadius = 18
        previewCard.layer.shadowOffset = CGSize(width: 0, height: 8)

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
        mediaWrap.widthAnchor.constraint(equalToConstant: 64).isActive = true
        mediaWrap.heightAnchor.constraint(equalToConstant: 64).isActive = true
        mediaWrap.layer.cornerRadius = 18
        mediaWrap.layer.masksToBounds = true
        mediaWrap.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.12)

        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.isHidden = true

        previewIconView.translatesAutoresizingMaskIntoConstraints = false
        previewIconView.tintColor = .systemIndigo
        previewIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)

        mediaWrap.addSubview(previewImageView)
        mediaWrap.addSubview(previewIconView)

        NSLayoutConstraint.activate([
            previewImageView.leadingAnchor.constraint(equalTo: mediaWrap.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: mediaWrap.trailingAnchor),
            previewImageView.topAnchor.constraint(equalTo: mediaWrap.topAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: mediaWrap.bottomAnchor),
            previewIconView.centerXAnchor.constraint(equalTo: mediaWrap.centerXAnchor),
            previewIconView.centerYAnchor.constraint(equalTo: mediaWrap.centerYAnchor),
            previewIconView.widthAnchor.constraint(equalToConstant: 28),
            previewIconView.heightAnchor.constraint(equalToConstant: 28),
        ])

        statusBadge.font = .preferredFont(forTextStyle: .caption1).bold()
        statusBadge.textColor = .white
        statusBadge.backgroundColor = .systemIndigo
        statusBadge.layer.cornerRadius = 999
        statusBadge.layer.masksToBounds = true
        statusBadge.textAlignment = .center
        statusBadge.text = "Auto-filling"
        statusBadge.heightAnchor.constraint(equalToConstant: 24).isActive = true
        statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 104).isActive = true

        previewTitleLabel.font = .preferredFont(forTextStyle: .headline).bold()
        previewTitleLabel.numberOfLines = 2
        previewTitleLabel.text = "Preparing your save…"

        previewMetaLabel.font = .preferredFont(forTextStyle: .caption1)
        previewMetaLabel.textColor = .systemIndigo
        previewMetaLabel.text = "Share Extension • Link"

        previewSubtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        previewSubtitleLabel.textColor = .secondaryLabel
        previewSubtitleLabel.numberOfLines = 2
        previewSubtitleLabel.text = "Finding the title, folder, and a few useful tags."

        spinner.startAnimating()

        let topRow = UIStackView(arrangedSubviews: [statusBadge, UIView(), spinner])
        topRow.axis = .horizontal
        topRow.alignment = .center

        let textStack = UIStackView(arrangedSubviews: [topRow, previewTitleLabel, previewMetaLabel, previewSubtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 6

        innerStack.addArrangedSubview(mediaWrap)
        innerStack.addArrangedSubview(textStack)
    }

    private func configureQuickBanner() {
        quickBannerLabel.translatesAutoresizingMaskIntoConstraints = false
        quickBannerLabel.font = .preferredFont(forTextStyle: .subheadline).bold()
        quickBannerLabel.textColor = .white
        quickBannerLabel.backgroundColor = UIColor.black.withAlphaComponent(0.82)
        quickBannerLabel.layer.cornerRadius = 16
        quickBannerLabel.layer.masksToBounds = true
        quickBannerLabel.textAlignment = .center
        quickBannerLabel.alpha = 0
        quickBannerLabel.numberOfLines = 2
        view.addSubview(quickBannerLabel)

        NSLayoutConstraint.activate([
            quickBannerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            quickBannerLabel.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 10),
            quickBannerLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.82),
        ])
    }

    private func configureRecentFoldersCard() {
        recentFoldersCard.backgroundColor = .secondarySystemBackground
        recentFoldersCard.layer.cornerRadius = 18
        recentFoldersCard.layer.borderWidth = 1
        recentFoldersCard.layer.borderColor = UIColor.separator.withAlphaComponent(0.24).cgColor

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        recentFoldersCard.addSubview(stack)

        recentFoldersHintLabel.font = .preferredFont(forTextStyle: .footnote)
        recentFoldersHintLabel.textColor = .secondaryLabel
        recentFoldersHintLabel.numberOfLines = 2
        recentFoldersHintLabel.text = "Your most recently used folders show up here."

        configureHorizontalStrip(scrollView: recentFoldersScrollView, row: recentFoldersRow, height: 116)

        stack.addArrangedSubview(recentFoldersHintLabel)
        stack.addArrangedSubview(recentFoldersScrollView)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: recentFoldersCard.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: recentFoldersCard.trailingAnchor, constant: -14),
            stack.topAnchor.constraint(equalTo: recentFoldersCard.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: recentFoldersCard.bottomAnchor, constant: -14),
        ])
    }

    private func configureFolderSummaryCard() {
        folderSummaryCard.backgroundColor = .secondarySystemBackground
        folderSummaryCard.layer.cornerRadius = 18
        folderSummaryCard.layer.borderWidth = 1
        folderSummaryCard.layer.borderColor = UIColor.separator.withAlphaComponent(0.24).cgColor

        let iconHolder = UIView()
        iconHolder.translatesAutoresizingMaskIntoConstraints = false
        iconHolder.widthAnchor.constraint(equalToConstant: 46).isActive = true
        iconHolder.heightAnchor.constraint(equalToConstant: 46).isActive = true
        iconHolder.addSubview(folderSummaryIconWrap)

        folderSummaryIconWrap.translatesAutoresizingMaskIntoConstraints = false
        folderSummaryIconWrap.layer.cornerRadius = 14
        folderSummaryIconWrap.layer.masksToBounds = true

        folderSummaryIconView.translatesAutoresizingMaskIntoConstraints = false
        folderSummaryIconView.tintColor = .white
        folderSummaryIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        folderSummaryIconWrap.addSubview(folderSummaryIconView)

        NSLayoutConstraint.activate([
            folderSummaryIconWrap.leadingAnchor.constraint(equalTo: iconHolder.leadingAnchor),
            folderSummaryIconWrap.trailingAnchor.constraint(equalTo: iconHolder.trailingAnchor),
            folderSummaryIconWrap.topAnchor.constraint(equalTo: iconHolder.topAnchor),
            folderSummaryIconWrap.bottomAnchor.constraint(equalTo: iconHolder.bottomAnchor),
            folderSummaryIconView.centerXAnchor.constraint(equalTo: folderSummaryIconWrap.centerXAnchor),
            folderSummaryIconView.centerYAnchor.constraint(equalTo: folderSummaryIconWrap.centerYAnchor),
        ])

        folderSummaryTitleLabel.font = .preferredFont(forTextStyle: .headline).bold()
        folderSummaryTitleLabel.numberOfLines = 2

        folderSummaryHintLabel.font = .preferredFont(forTextStyle: .footnote)
        folderSummaryHintLabel.textColor = .secondaryLabel
        folderSummaryHintLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [folderSummaryTitleLabel, folderSummaryHintLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let row = UIStackView(arrangedSubviews: [iconHolder, textStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false

        folderSummaryCard.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: folderSummaryCard.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: folderSummaryCard.trailingAnchor, constant: -14),
            row.topAnchor.constraint(equalTo: folderSummaryCard.topAnchor, constant: 14),
            row.bottomAnchor.constraint(equalTo: folderSummaryCard.bottomAnchor, constant: -14),
        ])
    }

    private func configureFolderGrid() {
        folderGridStack.axis = .vertical
        folderGridStack.spacing = 10
        folderGridStack.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureHorizontalStrip(scrollView: UIScrollView, row: UIStackView, height: CGFloat) {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .fill
        row.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            row.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            row.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            row.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: height),
        ])
    }

    private func configureTextField(_ textField: UITextField, placeholder: String) {
        textField.borderStyle = .none
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 14
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.separator.withAlphaComponent(0.26).cgColor
        textField.placeholder = placeholder
        textField.clearButtonMode = .whileEditing
        textField.heightAnchor.constraint(equalToConstant: 46).isActive = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.leftViewMode = .always
        textField.delegate = self
    }

    private func configureNotesToggle() {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        config.baseForegroundColor = .secondaryLabel
        notesToggleButton.configuration = config
        notesToggleButton.contentHorizontalAlignment = .leading
        notesToggleButton.addTarget(self, action: #selector(toggleNotes), for: .touchUpInside)
    }

    private func makeSectionCard(emphasized: Bool = false) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        stack.backgroundColor = .systemBackground
        stack.layer.cornerRadius = 22
        stack.layer.shadowColor = UIColor.black.cgColor
        stack.layer.shadowOpacity = emphasized ? 0.08 : 0.05
        stack.layer.shadowRadius = emphasized ? 18 : 12
        stack.layer.shadowOffset = CGSize(width: 0, height: emphasized ? 8 : 5)
        if emphasized {
            stack.layer.borderWidth = 1
            stack.layer.borderColor = UIColor.systemIndigo.withAlphaComponent(0.1).cgColor
        }
        return stack
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline).bold()
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
                rawShare = share
                pendingShare = share
                applyShare(share, animated: false)
                statusBadge.text = "Auto-filling"
                previewSubtitleLabel.text = "Finding the best title, folder, and a few useful tags."
                updateSaveButton(isReady: false)
            }

            let enriched = await ShareItemExtractor.enrich(share)
            await MainActor.run {
                pendingShare = enriched
                applyShare(enriched, animated: true)
                spinner.stopAnimating()
                statusBadge.text = "Ready"
                previewSubtitleLabel.text = "Looks good. Save now or make one quick change."
                updateSaveButton(isReady: true)
            }
        } catch {
            await MainActor.run {
                previewTitleLabel.text = "Couldn’t read this share"
                previewSubtitleLabel.text = error.localizedDescription
                previewMetaLabel.text = "Share Extension"
                previewIconView.image = UIImage(systemName: "exclamationmark.triangle.fill")
                spinner.stopAnimating()
                statusBadge.text = "Review"
                updateSaveButton(isReady: true)
            }
        }
    }

    private func applyShare(_ share: PendingShare, animated: Bool) {
        let summary = share.itemDescription ?? share.text ?? previewText(for: share)
        previewTitleLabel.text = share.title
        previewMetaLabel.text = "\(share.sourceApp) • \(share.type.capitalized)"
        previewSubtitleLabel.text = summary
        titleField.text = share.title
        notesTextView.text = summary

        selectedFolderId = share.folderId ?? selectedFolderId
        selectedTags = Array(dedupeTags(share.tags ?? []).prefix(3))
        suggestedTags = Array(
            suggestionTags(for: share)
                .filter { !selectedTags.map { $0.lowercased() }.contains($0.lowercased()) }
                .prefix(4)
        )

        rebuildRecentFolders()
        rebuildFolderButtons()
        rebuildTagViews()
        configurePreview(for: share)

        if animated {
            UIView.transition(with: previewCard, duration: 0.18, options: .transitionCrossDissolve, animations: {}, completion: nil)
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
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 12)
            if let (data, _) = try? await URLSession.shared.data(for: request),
               let image = UIImage(data: data) {
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

        availableFolders = ShareItemExtractor.folderPresets()
        let presets = availableFolders
        let selectedPreset = presets.first(where: { $0.id == selectedFolderId }) ?? FolderPreset(id: "f-must-see", name: "Must See", symbolName: "bookmark.fill", colorHex: "#F7C948", image: nil)
        let theme = folderTheme(for: selectedPreset)

        folderSummaryCard.backgroundColor = theme.color.withAlphaComponent(0.09)
        folderSummaryCard.layer.borderColor = theme.color.withAlphaComponent(0.18).cgColor
        folderSummaryIconWrap.backgroundColor = theme.color
        folderSummaryIconView.image = UIImage(systemName: selectedPreset.symbolName)
        folderSummaryTitleLabel.text = selectedPreset.name
        if pendingShare?.folderId == selectedFolderId {
            folderSummaryHintLabel.text = "Auto-picked and ready to save. Tap another folder below if you want to move it."
        } else {
            folderSummaryHintLabel.text = "You changed the folder for this save. SAVI will use this instead."
        }

        for index in stride(from: 0, to: presets.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .fill
            row.distribution = .fillEqually
            row.spacing = 10

            let left = makeFolderButton(for: presets[index])
            row.addArrangedSubview(left)

            if index + 1 < presets.count {
                row.addArrangedSubview(makeFolderButton(for: presets[index + 1]))
            } else {
                let spacer = UIView()
                spacer.backgroundColor = .clear
                row.addArrangedSubview(spacer)
            }

            folderGridStack.addArrangedSubview(row)
        }
    }

    private func rebuildRecentFolders() {
        clearArrangedSubviews(of: recentFoldersRow)
        recentFolders = ShareItemExtractor.recentFolderPresets(limit: 5)

        if recentFolders.isEmpty {
            recentFoldersHintLabel.text = "Save to a few folders and SAVI will float your recent ones here for one-tap sends."
            let label = makeInlineHint("No recent folders yet")
            recentFoldersRow.addArrangedSubview(label)
            return
        }

        recentFoldersHintLabel.text = "Tap once to save there instantly. SAVI will fetch the rich metadata the next time the app wakes up."
        recentFolders.forEach { folder in
            recentFoldersRow.addArrangedSubview(makeRecentFolderButton(for: folder))
        }
    }

    private func makeRecentFolderButton(for preset: FolderPreset) -> UIControl {
        let control = UIControl()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.widthAnchor.constraint(equalToConstant: 92).isActive = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(stack)

        let imageWrap = UIView()
        imageWrap.translatesAutoresizingMaskIntoConstraints = false
        imageWrap.widthAnchor.constraint(equalToConstant: 64).isActive = true
        imageWrap.heightAnchor.constraint(equalToConstant: 64).isActive = true
        imageWrap.layer.cornerRadius = 20
        imageWrap.layer.masksToBounds = true

        let theme = folderTheme(for: preset)
        imageWrap.backgroundColor = theme.color.withAlphaComponent(0.18)

        if let imageValue = preset.image, !imageValue.isEmpty {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageWrap.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: imageWrap.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: imageWrap.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: imageWrap.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: imageWrap.bottomAnchor),
            ])

            if let image = imageFromDataURL(imageValue) {
                imageView.image = image
            } else if let url = URL(string: imageValue), url.scheme?.hasPrefix("http") == true {
                Task {
                    let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 12)
                    if let (data, _) = try? await URLSession.shared.data(for: request),
                       let image = UIImage(data: data) {
                        await MainActor.run { imageView.image = image }
                    }
                }
            }

            let overlay = UIView()
            overlay.translatesAutoresizingMaskIntoConstraints = false
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.16)
            imageWrap.addSubview(overlay)
            NSLayoutConstraint.activate([
                overlay.leadingAnchor.constraint(equalTo: imageWrap.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: imageWrap.trailingAnchor),
                overlay.topAnchor.constraint(equalTo: imageWrap.topAnchor),
                overlay.bottomAnchor.constraint(equalTo: imageWrap.bottomAnchor),
            ])
        } else {
            let iconView = UIImageView(image: UIImage(systemName: preset.symbolName))
            iconView.translatesAutoresizingMaskIntoConstraints = false
            iconView.tintColor = .white
            iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
            imageWrap.addSubview(iconView)
            NSLayoutConstraint.activate([
                iconView.centerXAnchor.constraint(equalTo: imageWrap.centerXAnchor),
                iconView.centerYAnchor.constraint(equalTo: imageWrap.centerYAnchor),
            ])
        }

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .caption1).bold()
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.text = preset.name

        stack.addArrangedSubview(imageWrap)
        stack.addArrangedSubview(titleLabel)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            stack.topAnchor.constraint(equalTo: control.topAnchor),
            stack.bottomAnchor.constraint(equalTo: control.bottomAnchor),
        ])

        control.addAction(UIAction(handler: { [weak self] _ in
            self?.quickSave(to: preset)
        }), for: .touchUpInside)

        return control
    }

    private func makeFolderButton(for preset: FolderPreset) -> UIButton {
        let theme = folderTheme(for: preset)
        let isSelected = preset.id == selectedFolderId

        var config = UIButton.Configuration.filled()
        config.title = preset.name
        config.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : preset.symbolName)
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.cornerStyle = .large
        config.baseBackgroundColor = isSelected ? theme.color.withAlphaComponent(0.16) : .white
        config.baseForegroundColor = isSelected ? theme.color : .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)

        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.layer.cornerRadius = 18
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = (isSelected ? theme.color.withAlphaComponent(0.22) : UIColor.separator.withAlphaComponent(0.22)).cgColor
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        button.tag = availableFolders.firstIndex(where: { $0.id == preset.id }) ?? 0
        button.addTarget(self, action: #selector(folderTapped(_:)), for: .touchUpInside)
        return button
    }

    private func rebuildTagViews() {
        clearArrangedSubviews(of: selectedTagRow)
        clearArrangedSubviews(of: suggestedTagRow)

        if selectedTags.isEmpty {
            selectedTagRow.addArrangedSubview(makeInlineHint("SAVI didn’t find tags yet"))
        } else {
            selectedTags.forEach { selectedTagRow.addArrangedSubview(makeTagButton(for: $0, selected: true)) }
        }

        if suggestedTags.isEmpty {
            suggestedTagRow.addArrangedSubview(makeInlineHint("No extra suggestions"))
        } else {
            suggestedTags.forEach { suggestedTagRow.addArrangedSubview(makeTagButton(for: $0, selected: false)) }
        }
    }

    private func makeInlineHint(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.text = text
        return label
    }

    private func makeTagButton(for value: String, selected: Bool) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = selected ? value : "+ \(value)"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = selected ? UIColor.systemIndigo.withAlphaComponent(0.12) : UIColor.secondarySystemBackground
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

    private func folderTheme(for preset: FolderPreset) -> (color: UIColor, glow: UIColor) {
        if let colorHex = preset.colorHex, let parsed = UIColor(hex: colorHex) {
            return (parsed, parsed.withAlphaComponent(0.18))
        }

        switch preset.id {
        case "f-private-vault":
            return (.systemIndigo, UIColor.systemIndigo.withAlphaComponent(0.18))
        case "f-growth":
            return (.systemTeal, UIColor.systemTeal.withAlphaComponent(0.18))
        case "f-wtf-favorites":
            return (.systemPink, UIColor.systemPink.withAlphaComponent(0.18))
        case "f-tinfoil":
            return (.systemPurple, UIColor.systemPurple.withAlphaComponent(0.18))
        case "f-lmao":
            return (.systemOrange, UIColor.systemOrange.withAlphaComponent(0.18))
        case "f-health":
            return (.systemGreen, UIColor.systemGreen.withAlphaComponent(0.18))
        case "f-recipes":
            return (.systemRed, UIColor.systemRed.withAlphaComponent(0.18))
        case "f-travel":
            return (.systemBlue, UIColor.systemBlue.withAlphaComponent(0.18))
        case "f-design":
            return (.systemCyan, UIColor.systemCyan.withAlphaComponent(0.18))
        case "f-research":
            return (.systemMint, UIColor.systemMint.withAlphaComponent(0.18))
        default:
            return (.systemBrown, UIColor.systemBrown.withAlphaComponent(0.18))
        }
    }

    private func updateSaveButton(isReady: Bool, titleOverride: String? = nil) {
        var config = saveButton.configuration ?? UIButton.Configuration.filled()
        config.title = titleOverride ?? (isReady ? "Save" : "Auto-filling…")
        config.baseBackgroundColor = isReady ? .systemIndigo : UIColor.systemIndigo.withAlphaComponent(0.45)
        config.baseForegroundColor = .white
        saveButton.configuration = config
        saveButton.isEnabled = isReady
    }

    private func showBanner(_ text: String) {
        quickBannerLabel.text = "  \(text)  "
        UIView.animate(withDuration: 0.16) {
            self.quickBannerLabel.alpha = 1
        }
    }

    private func hideBanner() {
        UIView.animate(withDuration: 0.18) {
            self.quickBannerLabel.alpha = 0
        }
    }

    private func shouldDeferMetadata(for share: PendingShare) -> Bool {
        if let url = share.url, !url.isEmpty {
            return url.lowercased().hasPrefix("http")
        }
        return false
    }

    private func quickSave(to preset: FolderPreset) {
        guard var share = rawShare ?? pendingShare else { return }
        share.folderId = preset.id
        share.needsMetadata = shouldDeferMetadata(for: share)
        share.tags = dedupeTags(share.tags ?? [])

        do {
            try PendingShareStore.shared.save(share)
            PendingShareStore.shared.touchRecentFolder(id: preset.id, timestamp: share.timestamp)
            showBanner("Saved to \(preset.name)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
                self?.hideBanner()
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
        } catch {
            previewSubtitleLabel.text = error.localizedDescription
        }
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
        config.contentInsets = .zero
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
            selectedTags = Array(dedupeTags(selectedTags + [normalized]).prefix(4))
            suggestedTags.removeAll { $0.caseInsensitiveCompare(normalized) == .orderedSame }
        } else {
            selectedTags.removeAll { $0.caseInsensitiveCompare(normalized) == .orderedSame }
            if !suggestedTags.map({ $0.lowercased() }).contains(normalized.lowercased()) {
                suggestedTags = Array(dedupeTags([normalized] + suggestedTags).prefix(4))
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
        guard availableFolders.indices.contains(sender.tag) else { return }
        selectedFolderId = availableFolders[sender.tag].id
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
        pendingShare.itemDescription = notesExpanded ? trimmedNotes.nilIfEmpty : pendingShare.itemDescription
        pendingShare.folderId = selectedFolderId
        pendingShare.tags = dedupeTags(selectedTags + manualTags)
        pendingShare.needsMetadata = false

        do {
            try PendingShareStore.shared.save(pendingShare)
            PendingShareStore.shared.touchRecentFolder(id: selectedFolderId, timestamp: pendingShare.timestamp)
            updateSaveButton(isReady: false, titleOverride: "Saved")
            extensionContext?.completeRequest(returningItems: nil)
        } catch {
            previewSubtitleLabel.text = error.localizedDescription
            updateSaveButton(isReady: true)
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

private extension UIColor {
    convenience init?(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard cleaned.count == 6 || cleaned.count == 8 else { return nil }
        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else { return nil }

        let hasAlpha = cleaned.count == 8
        let red = CGFloat((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let green = CGFloat((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let blue = CGFloat((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let alpha = hasAlpha ? CGFloat(value & 0xFF) / 255 : 1

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
