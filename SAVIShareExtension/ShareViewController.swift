import UIKit

private enum ShareReleaseGate {
#if DEBUG
    static let socialFeaturesEnabled = true
    static let hostAppDisplayName = "SAVI Test"
#else
    static let socialFeaturesEnabled = false
    static let hostAppDisplayName = "SAVI"
#endif
}

private enum ShareTheme {
    static let background = adaptive(dark: "#100B1C", light: "#FBF8FF")
    static let surface = adaptive(dark: "#1C1530", light: "#FFFFFF")
    static let surfaceRaised = adaptive(dark: "#2A2144", light: "#F1EBF8")
    static let text = adaptive(dark: "#F5F0FF", light: "#160F22")
    static let muted = adaptive(dark: "#B7A9D6", light: "#5D526C")
    static let accent = adaptive(dark: "#D8FF3C", light: "#A6DB16")
    static let accentText = adaptive(dark: "#D8FF3C", light: "#563082")
    static let accentSoft = adaptive(dark: "#A78BFA", light: "#6B46C1")
    static let stroke = adaptive(dark: "#2F244C", light: "#D8CEE6")
    static let shadow = adaptive(dark: "#000000", light: "#5E4A73")

    private static func adaptive(dark: String, light: String) -> UIColor {
        UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light) ?? .systemBackground
        }
    }
}

private enum ShareFolderSelection {
    static let autoId = "__savi_auto_folder__"
    static let autoPreset = FolderPreset(
        id: autoId,
        name: "Auto",
        symbolName: "sparkles",
        colorHex: "#B8EF18"
    )

    static func isAuto(_ id: String) -> Bool {
        id == autoId || id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func presetsForDisplay() -> [FolderPreset] {
        [autoPreset] + ShareItemExtractor.folderPresets()
    }
}

private enum ShareFolderSelectionSource {
    case auto
    case rules
    case metadata
    case intelligence
    case manual

    static func fromPendingValue(_ value: String?, fallback: ShareFolderSelectionSource) -> ShareFolderSelectionSource {
        switch value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "manual":
            return .manual
        case "apple-intelligence":
            return .intelligence
        case "metadata":
            return .metadata
        case "rules":
            return .rules
        case "auto":
            return .auto
        default:
            return fallback
        }
    }

    var pendingValue: String {
        switch self {
        case .auto:
            return "auto"
        case .rules:
            return "rules"
        case .metadata:
            return "metadata"
        case .intelligence:
            return "apple-intelligence"
        case .manual:
            return "manual"
        }
    }
}

private final class ExpandedHitButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extraWidth = max(0, 44 - bounds.width) / 2
        let extraHeight = max(0, 44 - bounds.height) / 2
        return bounds.insetBy(dx: -extraWidth, dy: -extraHeight).contains(point)
    }
}

final class ShareViewController: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate, UITextViewDelegate {
    private let topBar = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let loadingOverlay = UIView()
    private let loadingCard = UIView()
    private let loadingTitleLabel = UILabel()
    private let loadingBodyLabel = UILabel()
    private let loadingProgressTrack = UIView()
    private let loadingProgressFill = UIView()
    private let loadingSaveNowButton = UIButton(type: .system)

    private let previewCard = UIView()
    private let previewImageView = UIImageView()
    private let previewIconView = UIImageView()
    private let statusBadge = UILabel()
    private let detectedTitleLabel = UILabel()
    private let previewMetaLabel = UILabel()
    private let previewSubtitleLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let editTitleButton = UIButton(type: .system)

    private let folderSummaryCard = UIView()
    private let folderSummaryIconWrap = UIView()
    private let folderSummaryIconView = UIImageView()
    private let folderSummaryTitleLabel = UILabel()
    private let folderSummaryHintLabel = UILabel()
    private let folderChangeButton = UIButton(type: .system)
    private let folderGridStack = UIStackView()

    private let titleField = UITextField()
    private var titleEditorExpanded = false

    private let tagWrapStack = UIStackView()
    private let tagInputRow = UIStackView()
    private let tagsField = UITextField()
    private let addTagButton = UIButton(type: .system)

    private let notesToggleButton = UIButton(type: .system)
    private let notesClearButton = UIButton(type: .system)
    private let notesPreviewLabel = UILabel()
    private let notesTextView = UITextView()

    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    private var pendingShare: PendingShare?
    private var availableFolders: [FolderPreset] = ShareFolderSelection.presetsForDisplay()
    private var selectedFolderId = ShareFolderSelection.autoId
    private var folderSelectionSource: ShareFolderSelectionSource = .auto
    private var didEditTitleManually = false
    private var didEditNotesManually = false
    private var didEditTagsManually = false
    private var selectedTags: [String] = []
    private var suggestedTags: [String] = []
    private var tagsExpanded = false
    private var folderGridExpanded = true
    private var lastTagWrapWidth: CGFloat = 0
    private var notesExpanded = false
    private var notesHeightConstraint: NSLayoutConstraint?
    private var keyboardObserverTokens: [NSObjectProtocol] = []
    private var loadingProgressWidthConstraint: NSLayoutConstraint?
    private var enrichmentTask: Task<Void, Never>?
    private var didFinishSaving = false

    private var isLightAppearance: Bool {
        traitCollection.userInterfaceStyle != .dark
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .unspecified
        configureView()
        enrichmentTask = Task { await loadSharedItem() }
    }

    deinit {
        enrichmentTask?.cancel()
        keyboardObserverTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        refreshResolvedLayerColors()
        rebuildFolderButtons()
        rebuildTagViews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let tagWidth = effectiveTagWrapWidth()
        guard abs(tagWidth - lastTagWrapWidth) > 1 else { return }
        lastTagWrapWidth = tagWidth
        rebuildTagViews()
    }

    private func configureView() {
        view.backgroundColor = ShareTheme.background
        registerForKeyboardNotifications()

        configureTopBar()
        configureLoadingOverlay()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
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
        configureFolderSummaryCard()

        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardTapped))
        dismissKeyboardTap.cancelsTouchesInView = false
        dismissKeyboardTap.delegate = self
        view.addGestureRecognizer(dismissKeyboardTap)

        let folderSection = makeSectionCard()
        folderSection.addArrangedSubview(folderSummaryCard)
        configureFolderGrid()
        folderSection.addArrangedSubview(folderGridStack)

        [previewCard, folderSection].forEach { contentStack.addArrangedSubview($0) }

        setNotesExpanded(false, animated: false)
        rebuildFolderButtons()
        rebuildTagViews()
        updateSaveButton(isReady: false)
    }

    private func configureTopBar() {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = ShareTheme.background.withAlphaComponent(0.86)
        view.addSubview(topBar)

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(blur)

        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = ShareTheme.stroke.withAlphaComponent(0.8)
        topBar.addSubview(divider)

        let controls = UIStackView()
        controls.axis = .horizontal
        controls.alignment = .center
        controls.spacing = 12
        controls.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(controls)

        var cancelConfig = UIButton.Configuration.plain()
        cancelConfig.title = "Cancel"
        cancelConfig.baseForegroundColor = ShareTheme.muted
        cancelButton.configuration = cancelConfig
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 1

        let sheetTitle = UILabel()
        sheetTitle.font = .preferredFont(forTextStyle: .headline).bold()
        sheetTitle.textColor = ShareTheme.text
        sheetTitle.text = "Save to SAVI"

        let sheetSubtitle = UILabel()
        sheetSubtitle.font = .preferredFont(forTextStyle: .caption1)
        sheetSubtitle.textColor = ShareTheme.muted
        sheetSubtitle.text = "Fast save"

        titleStack.addArrangedSubview(sheetTitle)
        titleStack.addArrangedSubview(sheetSubtitle)

        var saveConfig = UIButton.Configuration.filled()
        saveConfig.title = "Save now"
        saveConfig.cornerStyle = .capsule
        saveConfig.baseBackgroundColor = ShareTheme.accent
        saveConfig.baseForegroundColor = .black
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

    private func configureLoadingOverlay() {
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.backgroundColor = ShareTheme.background.withAlphaComponent(0.94)
        loadingOverlay.isHidden = true
        loadingOverlay.alpha = 0
        view.addSubview(loadingOverlay)

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(blur)

        loadingCard.translatesAutoresizingMaskIntoConstraints = false
        loadingCard.backgroundColor = ShareTheme.surface
        loadingCard.layer.cornerRadius = 28
        loadingCard.layer.shadowColor = ShareTheme.shadow.cgColor
        loadingCard.layer.shadowOpacity = isLightAppearance ? 0.09 : 0.24
        loadingCard.layer.shadowRadius = 24
        loadingCard.layer.shadowOffset = CGSize(width: 0, height: 12)
        loadingOverlay.addSubview(loadingCard)

        let orb = UIView()
        orb.translatesAutoresizingMaskIntoConstraints = false
        orb.backgroundColor = ShareTheme.accentText.withAlphaComponent(isLightAppearance ? 0.10 : 0.16)
        orb.layer.cornerRadius = 34
        loadingCard.addSubview(orb)

        let orbIcon = UIImageView(image: UIImage(systemName: "sparkles"))
        orbIcon.translatesAutoresizingMaskIntoConstraints = false
        orbIcon.tintColor = ShareTheme.accentText
        orbIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        orb.addSubview(orbIcon)

        loadingTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingTitleLabel.font = .preferredFont(forTextStyle: .title3).bold()
        loadingTitleLabel.textColor = ShareTheme.text
        loadingTitleLabel.textAlignment = .center
        loadingTitleLabel.numberOfLines = 2
        loadingTitleLabel.text = "SAVI is getting this ready"
        loadingCard.addSubview(loadingTitleLabel)

        loadingBodyLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingBodyLabel.font = .preferredFont(forTextStyle: .body)
        loadingBodyLabel.textColor = ShareTheme.muted
        loadingBodyLabel.textAlignment = .center
        loadingBodyLabel.numberOfLines = 3
        loadingBodyLabel.text = "Getting this ready. Save still works instantly."
        loadingCard.addSubview(loadingBodyLabel)

        var loadingSaveConfig = UIButton.Configuration.filled()
        loadingSaveConfig.title = "Save now"
        loadingSaveConfig.cornerStyle = .capsule
        loadingSaveConfig.baseBackgroundColor = ShareTheme.accent
        loadingSaveConfig.baseForegroundColor = .black
        loadingSaveConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        loadingSaveNowButton.configuration = loadingSaveConfig
        loadingSaveNowButton.translatesAutoresizingMaskIntoConstraints = false
        loadingSaveNowButton.isHidden = true
        loadingSaveNowButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        loadingCard.addSubview(loadingSaveNowButton)

        loadingProgressTrack.translatesAutoresizingMaskIntoConstraints = false
        loadingProgressTrack.backgroundColor = ShareTheme.surfaceRaised
        loadingProgressTrack.layer.cornerRadius = 7
        loadingProgressTrack.layer.masksToBounds = true
        loadingCard.addSubview(loadingProgressTrack)

        loadingProgressFill.translatesAutoresizingMaskIntoConstraints = false
        loadingProgressFill.backgroundColor = ShareTheme.accent
        loadingProgressFill.layer.cornerRadius = 7
        loadingProgressTrack.addSubview(loadingProgressFill)
        loadingProgressWidthConstraint = loadingProgressFill.widthAnchor.constraint(equalToConstant: 0)
        loadingProgressWidthConstraint?.isActive = true

        NSLayoutConstraint.activate([
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            blur.leadingAnchor.constraint(equalTo: loadingOverlay.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: loadingOverlay.trailingAnchor),
            blur.topAnchor.constraint(equalTo: loadingOverlay.topAnchor),
            blur.bottomAnchor.constraint(equalTo: loadingOverlay.bottomAnchor),

            loadingCard.leadingAnchor.constraint(equalTo: loadingOverlay.leadingAnchor, constant: 28),
            loadingCard.trailingAnchor.constraint(equalTo: loadingOverlay.trailingAnchor, constant: -28),
            loadingCard.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor),

            orb.topAnchor.constraint(equalTo: loadingCard.topAnchor, constant: 28),
            orb.centerXAnchor.constraint(equalTo: loadingCard.centerXAnchor),
            orb.widthAnchor.constraint(equalToConstant: 68),
            orb.heightAnchor.constraint(equalToConstant: 68),

            orbIcon.centerXAnchor.constraint(equalTo: orb.centerXAnchor),
            orbIcon.centerYAnchor.constraint(equalTo: orb.centerYAnchor),

            loadingTitleLabel.leadingAnchor.constraint(equalTo: loadingCard.leadingAnchor, constant: 24),
            loadingTitleLabel.trailingAnchor.constraint(equalTo: loadingCard.trailingAnchor, constant: -24),
            loadingTitleLabel.topAnchor.constraint(equalTo: orb.bottomAnchor, constant: 18),

            loadingBodyLabel.leadingAnchor.constraint(equalTo: loadingCard.leadingAnchor, constant: 24),
            loadingBodyLabel.trailingAnchor.constraint(equalTo: loadingCard.trailingAnchor, constant: -24),
            loadingBodyLabel.topAnchor.constraint(equalTo: loadingTitleLabel.bottomAnchor, constant: 10),

            loadingSaveNowButton.centerXAnchor.constraint(equalTo: loadingCard.centerXAnchor),
            loadingSaveNowButton.topAnchor.constraint(equalTo: loadingBodyLabel.bottomAnchor, constant: 16),

            loadingProgressTrack.leadingAnchor.constraint(equalTo: loadingCard.leadingAnchor, constant: 24),
            loadingProgressTrack.trailingAnchor.constraint(equalTo: loadingCard.trailingAnchor, constant: -24),
            loadingProgressTrack.topAnchor.constraint(equalTo: loadingSaveNowButton.bottomAnchor, constant: 20),
            loadingProgressTrack.heightAnchor.constraint(equalToConstant: 14),
            loadingProgressTrack.bottomAnchor.constraint(equalTo: loadingCard.bottomAnchor, constant: -24),

            loadingProgressFill.leadingAnchor.constraint(equalTo: loadingProgressTrack.leadingAnchor),
            loadingProgressFill.topAnchor.constraint(equalTo: loadingProgressTrack.topAnchor),
            loadingProgressFill.bottomAnchor.constraint(equalTo: loadingProgressTrack.bottomAnchor),
        ])
    }

    private func configurePreviewCard() {
        previewCard.backgroundColor = ShareTheme.surface
        previewCard.layer.cornerRadius = 22
        previewCard.layer.shadowColor = ShareTheme.shadow.cgColor
        previewCard.layer.shadowOpacity = isLightAppearance ? 0.08 : 0.22
        previewCard.layer.shadowRadius = 18
        previewCard.layer.shadowOffset = CGSize(width: 0, height: 8)

        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 10
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        previewCard.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardStack.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 12),
            cardStack.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -12),
            cardStack.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 12),
            cardStack.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: -12),
        ])

        let innerStack = UIStackView()
        innerStack.axis = .horizontal
        innerStack.alignment = .center
        innerStack.spacing = 14

        let mediaWrap = UIView()
        mediaWrap.translatesAutoresizingMaskIntoConstraints = false
        mediaWrap.widthAnchor.constraint(equalToConstant: 58).isActive = true
        mediaWrap.heightAnchor.constraint(equalToConstant: 58).isActive = true
        mediaWrap.layer.cornerRadius = 16
        mediaWrap.layer.masksToBounds = true
        mediaWrap.backgroundColor = ShareTheme.accentText.withAlphaComponent(isLightAppearance ? 0.10 : 0.16)

        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.isHidden = true

        previewIconView.translatesAutoresizingMaskIntoConstraints = false
        previewIconView.tintColor = ShareTheme.accentText
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
        statusBadge.textColor = .black
        statusBadge.backgroundColor = ShareTheme.accent
        statusBadge.layer.cornerRadius = 999
        statusBadge.layer.masksToBounds = true
        statusBadge.textAlignment = .center
        statusBadge.text = "Fast save"
        statusBadge.heightAnchor.constraint(equalToConstant: 24).isActive = true
        statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 92).isActive = true
        statusBadge.isHidden = true

        detectedTitleLabel.font = .preferredFont(forTextStyle: .headline).bold()
        detectedTitleLabel.textColor = ShareTheme.text
        detectedTitleLabel.numberOfLines = 2
        detectedTitleLabel.text = "Preparing your save..."

        previewMetaLabel.font = .preferredFont(forTextStyle: .caption1).bold()
        previewMetaLabel.textColor = ShareTheme.accentText
        previewMetaLabel.text = "Share Extension • Link"

        previewSubtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        previewSubtitleLabel.textColor = ShareTheme.muted
        previewSubtitleLabel.numberOfLines = 1
        previewSubtitleLabel.text = "Ready"

        spinner.startAnimating()

        var editConfig = UIButton.Configuration.plain()
        editConfig.title = "Edit title"
        editConfig.image = UIImage(systemName: "pencil")
        editConfig.imagePadding = 4
        editConfig.baseForegroundColor = ShareTheme.accentText
        editConfig.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8)
        editConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 12, weight: .bold)
            return outgoing
        }
        editTitleButton.configuration = editConfig
        editTitleButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        editTitleButton.addTarget(self, action: #selector(toggleTitleEditor), for: .touchUpInside)

        let topRow = UIStackView(arrangedSubviews: [previewMetaLabel, UIView(), spinner])
        topRow.axis = .horizontal
        topRow.alignment = .center

        let titleRow = UIStackView(arrangedSubviews: [detectedTitleLabel, editTitleButton])
        titleRow.axis = .horizontal
        titleRow.alignment = .firstBaseline
        titleRow.spacing = 8

        let textStack = UIStackView(arrangedSubviews: [topRow, titleRow, previewSubtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        innerStack.addArrangedSubview(mediaWrap)
        innerStack.addArrangedSubview(textStack)

        configureTextField(titleField, placeholder: "Edit title")
        titleField.font = .preferredFont(forTextStyle: .subheadline).bold()
        titleField.clearButtonMode = .always
        titleField.returnKeyType = .done
        titleField.inputAccessoryView = makeKeyboardAccessoryToolbar()
        titleField.addTarget(self, action: #selector(titleFieldChanged), for: .editingChanged)
        titleField.isHidden = true

        configureTagWrapStack()
        configureTextField(tagsField, placeholder: "Add a tag...")
        tagsField.leftView = makeTagPrefixView()
        tagsField.leftViewMode = .always
        tagsField.autocapitalizationType = .none
        tagsField.autocorrectionType = .no
        tagsField.returnKeyType = .send
        tagsField.enablesReturnKeyAutomatically = true
        tagsField.inputAccessoryView = makeTagKeyboardAccessoryToolbar()
        tagsField.addTarget(self, action: #selector(tagsFieldChanged), for: .editingChanged)
        configureTagInputRow()

        configureNotesToggle()
        let notesActionsRow = UIStackView(arrangedSubviews: [notesToggleButton, UIView(), notesClearButton])
        notesActionsRow.axis = .horizontal
        notesActionsRow.alignment = .center
        notesTextView.font = .preferredFont(forTextStyle: .body)
        notesTextView.textColor = ShareTheme.text
        notesTextView.backgroundColor = ShareTheme.surfaceRaised
        notesTextView.layer.cornerRadius = 16
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = ShareTheme.stroke.cgColor
        notesTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        notesTextView.tintColor = ShareTheme.accentText
        notesTextView.delegate = self
        notesTextView.inputAccessoryView = makeKeyboardAccessoryToolbar()
        notesTextView.isScrollEnabled = true
        notesTextView.textContainer.lineFragmentPadding = 4
        notesHeightConstraint = notesTextView.heightAnchor.constraint(equalToConstant: 132)
        notesHeightConstraint?.isActive = true

        notesPreviewLabel.font = .preferredFont(forTextStyle: .footnote)
        notesPreviewLabel.textColor = ShareTheme.muted
        notesPreviewLabel.numberOfLines = 3
        notesPreviewLabel.isHidden = true

        cardStack.addArrangedSubview(innerStack)
        cardStack.addArrangedSubview(titleField)
        cardStack.addArrangedSubview(tagWrapStack)
        cardStack.addArrangedSubview(tagInputRow)
        cardStack.addArrangedSubview(notesActionsRow)
        cardStack.addArrangedSubview(notesPreviewLabel)
        cardStack.addArrangedSubview(notesTextView)
    }

    private func configureFolderSummaryCard() {
        folderSummaryCard.backgroundColor = ShareTheme.surfaceRaised
        folderSummaryCard.layer.cornerRadius = 20
        folderSummaryCard.layer.borderWidth = 1
        folderSummaryCard.layer.borderColor = ShareTheme.stroke.cgColor
        folderSummaryCard.isUserInteractionEnabled = true
        let folderTapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleFolderGrid))
        folderTapGesture.delegate = self
        folderSummaryCard.addGestureRecognizer(folderTapGesture)

        let iconHolder = UIView()
        iconHolder.translatesAutoresizingMaskIntoConstraints = false
        iconHolder.widthAnchor.constraint(equalToConstant: 46).isActive = true
        iconHolder.heightAnchor.constraint(equalToConstant: 46).isActive = true
        iconHolder.addSubview(folderSummaryIconWrap)

        folderSummaryIconWrap.translatesAutoresizingMaskIntoConstraints = false
        folderSummaryIconWrap.layer.cornerRadius = 14
        folderSummaryIconWrap.layer.masksToBounds = true

        folderSummaryIconView.translatesAutoresizingMaskIntoConstraints = false
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
        folderSummaryTitleLabel.textColor = ShareTheme.text
        folderSummaryTitleLabel.numberOfLines = 2

        folderSummaryHintLabel.font = .preferredFont(forTextStyle: .footnote)
        folderSummaryHintLabel.textColor = ShareTheme.muted
        folderSummaryHintLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [folderSummaryTitleLabel, folderSummaryHintLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        var changeConfig = UIButton.Configuration.plain()
        changeConfig.title = "All"
        changeConfig.image = UIImage(systemName: "chevron.up")
        changeConfig.imagePlacement = .trailing
        changeConfig.imagePadding = 5
        changeConfig.baseForegroundColor = ShareTheme.accentText
        changeConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        folderChangeButton.configuration = changeConfig
        folderChangeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        folderChangeButton.addTarget(self, action: #selector(toggleFolderGrid), for: .touchUpInside)
        folderChangeButton.accessibilityLabel = "Show folder choices"

        let row = UIStackView(arrangedSubviews: [iconHolder, textStack, folderChangeButton])
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
        folderGridStack.isHidden = !folderGridExpanded
    }

    private func configureTagWrapStack() {
        tagWrapStack.axis = .vertical
        tagWrapStack.spacing = 6
        tagWrapStack.alignment = .fill
        tagWrapStack.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureTagInputRow() {
        tagInputRow.axis = .horizontal
        tagInputRow.alignment = .center
        tagInputRow.spacing = 8
        tagInputRow.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "plus")
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 9, bottom: 9, trailing: 9)
        addTagButton.configuration = config
        addTagButton.accessibilityLabel = "Add tag"
        addTagButton.addTarget(self, action: #selector(addTagButtonTapped), for: .touchUpInside)
        addTagButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        addTagButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        addTagButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        updateAddTagButtonState()

        tagInputRow.addArrangedSubview(tagsField)
        tagInputRow.addArrangedSubview(addTagButton)
    }

    private func configureTextField(_ textField: UITextField, placeholder: String) {
        textField.borderStyle = .none
        textField.backgroundColor = ShareTheme.surfaceRaised
        textField.layer.cornerRadius = 14
        textField.layer.borderWidth = 1
        textField.layer.borderColor = ShareTheme.stroke.cgColor
        textField.textColor = ShareTheme.text
        textField.tintColor = ShareTheme.accentText
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: ShareTheme.muted.withAlphaComponent(0.72)]
        )
        textField.clearButtonMode = .whileEditing
        textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.leftViewMode = .always
        textField.delegate = self
    }

    private func makeTagPrefixView() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 1))
        let label = UILabel(frame: CGRect(x: 12, y: 0, width: 18, height: 1))
        label.text = "#"
        label.font = .systemFont(ofSize: 16, weight: .black)
        label.textColor = ShareTheme.accentText
        label.textAlignment = .center
        label.autoresizingMask = [.flexibleHeight]
        container.addSubview(label)
        return container
    }

    private func makeKeyboardAccessoryToolbar(doneTitle: String = "Done") -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: doneTitle, style: .done, target: self, action: #selector(keyboardDoneTapped))
        ]
        return toolbar
    }

    private func makeTagKeyboardAccessoryToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Add tag", style: .plain, target: self, action: #selector(tagToolbarAddTapped)),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(keyboardDoneTapped))
        ]
        return toolbar
    }

    private func updateAddTagButtonState() {
        let hasText = normalizedManualTags(from: tagsField.text ?? "").isEmpty == false
        addTagButton.isEnabled = hasText
        var config = addTagButton.configuration ?? UIButton.Configuration.filled()
        config.baseBackgroundColor = hasText ? ShareTheme.accent : ShareTheme.surfaceRaised
        config.baseForegroundColor = hasText ? .black : ShareTheme.muted
        addTagButton.configuration = config
    }

    private func configureNotesToggle() {
        var config = UIButton.Configuration.plain()
        config.contentInsets = .zero
        config.baseForegroundColor = ShareTheme.muted
        notesToggleButton.configuration = config
        notesToggleButton.contentHorizontalAlignment = .leading
        notesToggleButton.addTarget(self, action: #selector(toggleNotes), for: .touchUpInside)
        notesToggleButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true

        var clearConfig = UIButton.Configuration.plain()
        clearConfig.title = "Clear"
        clearConfig.image = UIImage(systemName: "xmark.circle.fill")
        clearConfig.imagePadding = 5
        clearConfig.baseForegroundColor = ShareTheme.muted
        clearConfig.contentInsets = .zero
        notesClearButton.configuration = clearConfig
        notesClearButton.contentHorizontalAlignment = .trailing
        notesClearButton.addTarget(self, action: #selector(clearNotesTapped), for: .touchUpInside)
        notesClearButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
    }

    private func makeSectionCard(emphasized: Bool = false) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 9
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        stack.backgroundColor = ShareTheme.surface
        stack.layer.cornerRadius = 20
        stack.layer.shadowColor = ShareTheme.shadow.cgColor
        stack.layer.shadowOpacity = isLightAppearance ? (emphasized ? 0.08 : 0.05) : (emphasized ? 0.22 : 0.16)
        stack.layer.shadowRadius = emphasized ? 18 : 12
        stack.layer.shadowOffset = CGSize(width: 0, height: emphasized ? 8 : 5)
        if emphasized {
            stack.layer.borderWidth = 1
            stack.layer.borderColor = ShareTheme.stroke.cgColor
        }
        return stack
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline).bold()
        label.textColor = ShareTheme.text
        label.text = text
        return label
    }

    private func makeSubsectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ShareTheme.muted
        label.text = text
        return label
    }

    private func makeHintLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = ShareTheme.muted
        label.numberOfLines = 0
        label.text = text
        return label
    }

    private func registerForKeyboardNotifications() {
        guard keyboardObserverTokens.isEmpty else { return }
        let center = NotificationCenter.default
        keyboardObserverTokens = [
            center.addObserver(
                forName: UIResponder.keyboardWillChangeFrameNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.keyboardWillChangeFrame(notification)
            },
            center.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.keyboardWillHide(notification)
            },
        ]
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard !(touch.view is UIControl) else { return false }
        if let touchedView = touch.view,
           touchedView.isDescendant(of: notesTextView) || touchedView.isDescendant(of: titleField) || touchedView.isDescendant(of: tagsField) {
            return false
        }
        return true
    }

    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let convertedFrame = view.convert(endFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - convertedFrame.minY)
        let bottomInset = overlap + 18
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        if notesTextView.isFirstResponder {
            scrollNotesIntoView()
        } else if tagsField.isFirstResponder {
            scrollTagInputIntoView()
        }
    }

    private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    private func scrollNotesIntoView() {
        view.layoutIfNeeded()
        let noteRect = scrollView.convert(notesTextView.bounds, from: notesTextView)
            .insetBy(dx: 0, dy: -28)
        scrollView.scrollRectToVisible(noteRect, animated: true)
    }

    private func scrollTagInputIntoView() {
        view.layoutIfNeeded()
        let tagRect = scrollView.convert(tagInputRow.bounds, from: tagInputRow)
            .insetBy(dx: 0, dy: -24)
        scrollView.scrollRectToVisible(tagRect, animated: true)
    }

    private func loadSharedItem() async {
        do {
            let share = try await ShareItemExtractor.extract(from: extensionContext)
            await MainActor.run {
                pendingShare = share
                applyShare(share, animated: false)
                spinner.stopAnimating()
                statusBadge.text = "Ready to save"
                previewSubtitleLabel.text = "Ready"
                setLoadingOverlay(visible: false, title: nil, body: nil)
                updateSaveButton(isReady: true, titleOverride: "Save now")
            }

            let enriched = await ShareItemExtractor.enrich(share)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard !didFinishSaving else { return }
                pendingShare = enriched
                applyShare(enriched, animated: true)
                spinner.stopAnimating()
                let needsReview = needsManualReview(enriched)
                statusBadge.text = needsReview ? "Check title" : "Ready"
                previewSubtitleLabel.text = needsReview ? "Check title" : "Metadata updated"
                setNotesExpanded(notesTextView.isFirstResponder || didEditNotesManually, animated: true)
                setLoadingOverlay(visible: false, title: nil, body: nil)
                updateSaveButton(isReady: true)
            }

            var intelligenceInput = enriched
            intelligenceInput.folderId = nil
            let intelligenceResult = await ShareItemExtractor.improveWithAppleIntelligence(intelligenceInput)
            guard !Task.isCancelled else { return }
            var refined = enriched
            refined.title = intelligenceResult.title
            refined.tags = intelligenceResult.tags
            if let folderId = intelligenceResult.folderId?.trimmingCharacters(in: .whitespacesAndNewlines),
               !folderId.isEmpty {
                refined.folderId = folderId
                refined.folderSource = intelligenceResult.folderSource ?? "apple-intelligence"
                refined.folderConfidence = intelligenceResult.folderConfidence
                refined.folderReason = intelligenceResult.folderReason
            }
            await MainActor.run {
                guard !didFinishSaving else { return }
                pendingShare = refined
                let hasIntelligenceFolder = refined.folderSource == "apple-intelligence" &&
                    refined.folderId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                let usedAppleIntelligence = hasIntelligenceFolder ||
                    refined.title != enriched.title ||
                    (refined.tags ?? []) != (enriched.tags ?? [])
                applyShare(refined, animated: true, trustFolderSuggestion: hasIntelligenceFolder)
                spinner.stopAnimating()
                let needsReview = needsManualReview(refined)
                statusBadge.text = needsReview ? "Check title" : "Ready"
                previewSubtitleLabel.text = needsReview ? "Check title" : (usedAppleIntelligence ? "Smart details ready" : "Ready")
                setNotesExpanded(notesTextView.isFirstResponder || didEditNotesManually, animated: true)
                setLoadingOverlay(visible: false, title: nil, body: nil)
                updateSaveButton(isReady: true)
            }
        } catch {
            await MainActor.run {
                detectedTitleLabel.text = "Couldn’t read this share"
                previewSubtitleLabel.text = "Add title"
                previewMetaLabel.text = "Share Extension"
                previewIconView.image = UIImage(systemName: "exclamationmark.triangle.fill")
                spinner.stopAnimating()
                statusBadge.text = "Add title"
                titleField.text = pendingShare?.title ?? ""
                setNotesExpanded(true, animated: true)
                setLoadingOverlay(visible: false, title: nil, body: nil)
                updateSaveButton(isReady: true)
            }
        }
    }

    private func applyShare(_ share: PendingShare, animated: Bool, trustFolderSuggestion: Bool = false) {
        let summary = share.itemDescription ?? share.text ?? previewText(for: share)
        detectedTitleLabel.text = share.title
        previewMetaLabel.text = "\(share.sourceApp) • \(share.type.capitalized)"
        previewSubtitleLabel.text = compactPreviewStatus(for: share)
        if !didEditTitleManually {
            titleField.text = share.title
        }
        updateTitleEditorPresentation(animated: false)
        if !didEditNotesManually {
            notesTextView.text = summary
        }
        updateNotesPresentation(animated: false)

        if folderSelectionSource != .manual {
            if let folderId = share.folderId?.trimmingCharacters(in: .whitespacesAndNewlines),
               !folderId.isEmpty {
                selectedFolderId = folderId
                let fallbackSource: ShareFolderSelectionSource = trustFolderSuggestion ? .intelligence : (animated ? .metadata : .rules)
                folderSelectionSource = ShareFolderSelectionSource.fromPendingValue(share.folderSource, fallback: fallbackSource)
            } else {
                selectedFolderId = ShareFolderSelection.autoId
                folderSelectionSource = .auto
            }
        }
        if !didEditTagsManually {
            selectedTags = defaultSelectedTags(for: share)
            suggestedTags = Array(
                suggestionTags(for: share)
                    .filter { !selectedTags.map { $0.lowercased() }.contains($0.lowercased()) }
                    .prefix(10)
            )
        } else {
            refreshSuggestedTagsForCurrentShare()
        }

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
              thumbnail.utf8.count <= 7_500_000,
              let commaIndex = thumbnail.prefix(160).firstIndex(of: ",")
        else { return nil }

        let header = String(thumbnail[..<commaIndex]).lowercased()
        guard header.hasPrefix("data:image/"),
              !header.hasPrefix("data:image/svg+xml")
        else { return nil }

        let encoded = String(thumbnail[thumbnail.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: encoded) else { return nil }
        return UIImage(data: data)
    }

    private func rebuildFolderButtons() {
        clearArrangedSubviews(of: folderGridStack)

        availableFolders = ShareFolderSelection.presetsForDisplay()
        let presets = availableFolders
        let selectedPreset = presets.first(where: { $0.id == selectedFolderId }) ?? ShareFolderSelection.autoPreset
        let selectedIsPublic = showsPublicBadge(for: selectedPreset)
        let theme = folderTheme(for: selectedPreset)

        folderSummaryCard.backgroundColor = theme.color.withAlphaComponent(0.10)
        folderSummaryCard.layer.borderColor = theme.color.withAlphaComponent(0.40).cgColor
        folderSummaryIconWrap.backgroundColor = theme.color
        let isSmartSelection = folderSelectionSource != .manual
        folderSummaryIconView.image = UIImage(systemName: isSmartSelection ? "brain.head.profile" : selectedIsPublic ? "person.2.fill" : selectedPreset.symbolName)
        folderSummaryIconView.tintColor = theme.color.saviUsesLightForeground ? .white : .black
        folderSummaryTitleLabel.text = selectedPreset.name
        let hint: String
        if folderSelectionSource == .intelligence {
            hint = "Suggested Folder · SAVI Brain"
        } else if folderSelectionSource == .metadata {
            hint = "Suggested Folder · \(friendlyFolderReason(pendingShare?.folderReason) ?? "SAVI Brain")"
        } else if folderSelectionSource == .rules {
            hint = "Suggested Folder · \(friendlyFolderReason(pendingShare?.folderReason) ?? "SAVI Brain")"
        } else if ShareFolderSelection.isAuto(selectedFolderId) {
            hint = "Smart Selection · chooses when you save"
        } else {
            hint = "You picked this"
        }
        folderSummaryHintLabel.text = selectedIsPublic ? "\(hint) • Public" : hint

        var changeConfig = folderChangeButton.configuration ?? UIButton.Configuration.plain()
        changeConfig.title = folderGridExpanded ? "All" : "Show"
        changeConfig.image = UIImage(systemName: folderGridExpanded ? "chevron.up" : "square.grid.2x2")
        folderChangeButton.configuration = changeConfig
        folderChangeButton.accessibilityLabel = folderGridExpanded ? "Hide folder choices" : "Show folder choices"
        folderGridStack.isHidden = !folderGridExpanded

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

    private func friendlyFolderReason(_ reason: String?) -> String? {
        switch reason?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "life-admin-guardrail":
            return "codes, warranty, or docs"
        case "private-guardrail":
            return "private document"
        case "place-guardrail":
            return "map or place"
        case "paste-guardrail":
            return "copied note"
        case .some(let value) where value.hasPrefix("profile-f-life-admin"):
            return "life admin"
        case .some(let value) where value.hasPrefix("profile-f-recipes"):
            return "recipe or food"
        case .some(let value) where value.hasPrefix("profile-f-health"):
            return "health"
        case .some(let value) where value.hasPrefix("profile-f-growth"):
            return "AI or work"
        case .some(let value) where value.hasPrefix("profile-f-lmao"):
            return "meme or funny"
        case .some(let value) where value.hasPrefix("profile-f-travel"):
            return "place or trip"
        case .some(let value) where value.hasPrefix("profile-f-research"):
            return "research"
        case .some(let value) where value.hasPrefix("profile-f-tinfoil"):
            return "rabbit hole"
        case .some(let value) where value.hasPrefix("profile-f-must-see"):
            return "watch or read"
        case .some(let value) where value.hasPrefix("custom-folder"):
            return "folder name match"
        case .some(let value) where value.hasPrefix("learned"):
            return "learned from you"
        default:
            return nil
        }
    }

    private func folderTileSubtitle(for preset: FolderPreset, isSelected: Bool, isPublic: Bool) -> String? {
        let isSmartSelection = isSelected && folderSelectionSource != .manual
        if ShareFolderSelection.isAuto(preset.id) {
            return isSelected ? "Smart picker" : nil
        }
        if isSmartSelection && isPublic {
            return "Smart pick • Public"
        }
        if isSmartSelection {
            return "Smart pick"
        }
        return isPublic ? "Public" : nil
    }

    private func makeFolderButton(for preset: FolderPreset) -> UIButton {
        let theme = folderTheme(for: preset)
        let isSelected = preset.id == selectedFolderId
        let isPublic = showsPublicBadge(for: preset)
        let subtitle = folderTileSubtitle(for: preset, isSelected: isSelected, isPublic: isPublic)

        var config = UIButton.Configuration.filled()
        config.title = preset.name
        config.subtitle = subtitle
        config.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : isPublic ? "person.2.fill" : preset.symbolName)
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.cornerStyle = .large
        config.baseBackgroundColor = isSelected ? theme.color.withAlphaComponent(0.22) : ShareTheme.surfaceRaised
        config.baseForegroundColor = isSelected ? selectedFolderTextColor(for: theme.color) : ShareTheme.text
        config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 12, bottom: 9, trailing: 12)
        config.titleAlignment = .leading
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }
        config.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 11, weight: .bold)
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = (isSelected ? theme.color.withAlphaComponent(0.46) : ShareTheme.stroke).cgColor
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: subtitle == nil ? 54 : 62).isActive = true
        button.tag = availableFolders.firstIndex(where: { $0.id == preset.id }) ?? 0
        button.addTarget(self, action: #selector(folderTapped(_:)), for: .touchUpInside)
        button.accessibilityLabel = isPublic ? "\(preset.name), Public Folder" : preset.name
        return button
    }

    private func showsPublicBadge(for preset: FolderPreset) -> Bool {
        ShareReleaseGate.socialFeaturesEnabled && preset.isPublic
    }

    private func prioritizedDisplayTags(for share: PendingShare) -> [String] {
        let raw = dedupeTags(share.tags ?? [])
        return classifyTagPool(raw, share: share).strong
    }

    private func defaultSelectedTags(for share: PendingShare) -> [String] {
        var tags: [String] = []
        if let platformTag = platformDisplayTag(for: share) {
            tags.append(platformTag)
        }
        if let typeTag = primaryTypeTag(for: share) {
            tags.append(typeTag)
        }
        if tags.isEmpty, let sourceTag = sourceDisplayTag(for: share) {
            tags.append(sourceTag)
        }
        return Array(dedupeTags(tags).prefix(3))
    }

    private func classifyTagPool(_ raw: [String], share: PendingShare) -> (strong: [String], platform: [String], salvageable: [String]) {
        let generic = Set([
            share.type.lowercased(),
            "link",
            "article",
            "video",
            "image",
            "file",
            "place",
            "text",
            "share-extension",
            "share",
            "sharing",
            "safari",
            "photos",
            "files"
        ].map { $0.lowercased() })
        let platform = Set([
            "youtube", "instagram", "reddit", "tiktok", "spotify", "pinterest",
            "cnn", "bbc", "reuters", "new-york-times", "news", "x", "twitter",
            "google-maps", "apple-maps", "safari", "photos", "files", "facebook",
            "threads", "bluesky", "linkedin", "vimeo", "soundcloud"
        ])
        let banned = Set([
            "camera", "camera-phone", "phone-camera", "sharing", "shared", "open-app",
            "app", "photo", "photos", "mobile", "smartphone", "watch", "save"
        ])
        let preferredTopicTags = Set([
            "parasite", "worms", "health", "travel", "food", "science", "design",
            "conspiracy", "productivity", "funny", "research", "recipe", "meme",
            "watch later", "read later", "important", "reference", "tutorial",
            "music", "review", "news", "try this", "inspiration", "maps", "pdf"
        ])

        let haystack = [share.title, share.itemDescription, share.text]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        var strong: [(String, Int)] = []
        var platformMatches: [String] = []
        var salvageable: [String] = []

        for tag in raw {
            let lower = tag.lowercased()
            if banned.contains(lower) || generic.contains(lower) {
                continue
            }
            if platform.contains(lower) {
                platformMatches.append(tag)
                continue
            }

            let plain = lower.replacingOccurrences(of: "-", with: " ")
            var score = 0
            if preferredTopicTags.contains(lower) { score += 6 }
            if haystack.contains(plain) { score += 4 }
            let title = share.title.lowercased()
            if title.contains(plain) { score += 4 }
            if lower.count >= 6 { score += 1 }

            if score >= 5 {
                strong.append((tag, score))
            } else if lower.count >= 4 {
                salvageable.append(tag)
            }
        }

        let orderedStrong = strong
            .sorted {
                if $0.1 == $1.1 {
                    return $0.0.localizedCaseInsensitiveCompare($1.0) == .orderedAscending
                }
                return $0.1 > $1.1
            }
            .map(\.0)

        var platformResults = Array(dedupeTags(platformMatches).prefix(2))
        if let sourceTag = normalizedSourceTag(for: share),
           !platformResults.map({ $0.lowercased() }).contains(sourceTag.lowercased()) {
            platformResults.insert(sourceTag, at: 0)
        }

        return (
            strong: Array(dedupeTags(orderedStrong).prefix(3)),
            platform: Array(dedupeTags(platformResults).prefix(2)),
            salvageable: Array(dedupeTags(salvageable).prefix(4))
        )
    }

    private func normalizedSourceTag(for share: PendingShare) -> String? {
        if let platform = platformDisplayTag(for: share) {
            return platform
                .lowercased()
                .replacingOccurrences(of: "&", with: "and")
                .replacingOccurrences(of: " ", with: "-")
        }
        let cleaned = share.sourceApp
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: " ", with: "-")
        return cleaned.isEmpty || cleaned == "share-extension" ? nil : cleaned
    }

    private func platformDisplayTag(for share: PendingShare) -> String? {
        let joined = [share.url, share.sourceApp, share.mimeType, share.fileName]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

        let mappings: [(needles: [String], label: String)] = [
            (["youtube.com", "youtu.be", "youtube"], "YouTube"),
            (["tiktok.com", "tiktok"], "TikTok"),
            (["instagram.com", "instagram"], "Instagram"),
            (["x.com", "twitter.com", "twitter"], "X"),
            (["maps.google", "google.com/maps", "maps.apple", "apple maps", "google maps"], "Maps"),
            (["reddit.com", "reddit"], "Reddit"),
            (["pinterest.com", "pinterest"], "Pinterest"),
            (["spotify.com", "spotify"], "Spotify"),
            (["facebook.com", "fb.com", "facebook"], "Facebook"),
            (["photos", "image/"], "Photos"),
            (["files", "application/pdf"], "Files"),
        ]

        return mappings.first { mapping in
            mapping.needles.contains { joined.contains($0) }
        }?.label
    }

    private func primaryTypeTag(for share: PendingShare) -> String? {
        let joined = [share.type, share.url, share.mimeType, share.fileName, share.sourceApp]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        if joined.contains("youtube") || joined.contains("youtu.be") || joined.contains("tiktok") ||
            joined.contains("vimeo") || joined.contains("video/") || share.type.caseInsensitiveCompare("video") == .orderedSame {
            return "video"
        }
        if joined.contains("audio/") ||
            joined.range(of: #"\.(m4a|mp3|wav|caf|aac)(\?|$|\s)"#, options: .regularExpression) != nil {
            return "audio"
        }
        if share.type.caseInsensitiveCompare("pdf") == .orderedSame ||
            joined.contains("application/pdf") ||
            joined.range(of: #"\.pdf(\?|$|\s)"#, options: .regularExpression) != nil {
            return "PDF"
        }
        if share.type.caseInsensitiveCompare("image") == .orderedSame ||
            joined.contains("image/") ||
            joined.contains("photos") {
            return "image"
        }
        if share.type.caseInsensitiveCompare("place") == .orderedSame ||
            joined.contains("maps.google") ||
            joined.contains("maps.apple") ||
            joined.contains("google.com/maps") {
            return "place"
        }
        if share.type.caseInsensitiveCompare("text") == .orderedSame {
            return "note"
        }
        if share.type.caseInsensitiveCompare("file") == .orderedSame {
            return "file"
        }
        return nil
    }

    private func sourceDisplayTag(for share: PendingShare) -> String? {
        let cleaned = share.sourceApp.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty || cleaned.caseInsensitiveCompare("Share Extension") == .orderedSame ? nil : cleaned
    }

    private func compactPreviewStatus(for share: PendingShare) -> String {
        if let fileName = share.fileName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !fileName.isEmpty {
            return fileName
        }
        if platformDisplayTag(for: share) != nil {
            return "Ready"
        }
        if let urlString = share.url,
           let host = URL(string: urlString)?.host?.replacingOccurrences(of: "www.", with: ""),
           !host.isEmpty {
            return host
        }
        return "Ready"
    }

    private func needsManualReview(_ share: PendingShare) -> Bool {
        let title = share.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = title.lowercased()
        let genericTitles = [
            "shared item",
            "youtube video",
            "shared text"
        ]
        if genericTitles.contains(lower) { return true }
        if title.hasPrefix("http://") || title.hasPrefix("https://") { return true }
        if lower.hasSuffix(" save") { return true }
        if title.count < 12 { return true }
        return false
    }

    private func setLoadingOverlay(visible: Bool, title: String?, body: String?) {
        if let title, !title.isEmpty {
            loadingTitleLabel.text = title
        }
        if let body, !body.isEmpty {
            loadingBodyLabel.text = body
        }
        loadingSaveNowButton.isHidden = !visible

        if visible {
            view.bringSubviewToFront(loadingOverlay)
            loadingOverlay.isHidden = false
            loadingOverlay.alpha = 1
            loadingProgressFill.layer.removeAllAnimations()
            loadingProgressWidthConstraint?.constant = 0
            view.layoutIfNeeded()
            let targetWidth = max(120, view.bounds.width - 150)
            UIView.animate(withDuration: 0.95, delay: 0, options: [.curveEaseInOut, .repeat, .autoreverse]) {
                self.loadingProgressWidthConstraint?.constant = targetWidth
                self.view.layoutIfNeeded()
            }
        } else {
            loadingProgressFill.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.22, animations: {
                self.loadingOverlay.alpha = 0
            }, completion: { _ in
                self.loadingOverlay.isHidden = true
            })
        }
    }

    private func rebuildTagViews() {
        clearArrangedSubviews(of: tagWrapStack)

        tagWrapStack.addArrangedSubview(makeInlineHint("Smart tags"))

        let selectedValues = selectedTags.map { (value: $0, selected: true) }
        let selectedLower = Set(selectedTags.map { $0.lowercased() })
        let suggestedValues = suggestedTags
            .filter { !selectedLower.contains($0.lowercased()) }
            .map { (value: $0, selected: false) }
        let visibleLimit = defaultVisibleTagLimit()
        let visibleSuggestionLimit = max(0, visibleLimit - selectedValues.count)
        let visibleSuggestedValues = tagsExpanded ? suggestedValues : Array(suggestedValues.prefix(visibleSuggestionLimit))
        let visibleValues = selectedValues + visibleSuggestedValues
        let allValues = selectedValues + suggestedValues

        if visibleValues.isEmpty {
            tagWrapStack.addArrangedSubview(makeInlineHint(pendingShare == nil ? "Detecting tags..." : "Add tags"))
        } else {
            let chipViews = visibleValues.map { tag in
                makeTagButton(for: tag.value, selected: tag.selected)
            }
            addWrappedTagViews(chipViews + [makeTagEditorButton(hiddenCount: max(0, allValues.count - visibleValues.count))])
        }

        if visibleValues.isEmpty {
            tagWrapStack.addArrangedSubview(makeTagEditorButton(hiddenCount: max(0, allValues.count)))
        }
    }

    private func addWrappedTagViews(_ views: [UIView]) {
        let maxWidth = effectiveTagWrapWidth()
        var row = makeTagRow()
        var currentWidth: CGFloat = 0

        func finishRowIfNeeded() {
            guard !row.arrangedSubviews.isEmpty else { return }
            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            row.addArrangedSubview(spacer)
            tagWrapStack.addArrangedSubview(row)
            row = makeTagRow()
            currentWidth = 0
        }

        for view in views {
            view.widthAnchor.constraint(lessThanOrEqualToConstant: min(maxWidth, 132)).isActive = true
            let measuredSize = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            let measuredWidth = min(ceil(measuredSize.width), maxWidth, 132)
            let spacing = row.arrangedSubviews.isEmpty ? 0 : row.spacing
            if currentWidth + spacing + measuredWidth > maxWidth, !row.arrangedSubviews.isEmpty {
                finishRowIfNeeded()
            }
            row.addArrangedSubview(view)
            currentWidth += (row.arrangedSubviews.count == 1 ? 0 : row.spacing) + measuredWidth
        }

        finishRowIfNeeded()
    }

    private func makeTagRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .fill
        row.spacing = 7
        return row
    }

    private func effectiveTagWrapWidth() -> CGFloat {
        let measuredWidth: CGFloat
        if tagWrapStack.bounds.width > 10 {
            measuredWidth = tagWrapStack.bounds.width
        } else if previewCard.bounds.width > 10 {
            measuredWidth = previewCard.bounds.width - 28
        } else if contentStack.bounds.width > 10 {
            measuredWidth = contentStack.bounds.width - 28
        } else {
            measuredWidth = view.bounds.width - 64
        }
        return max(180, floor(measuredWidth))
    }

    private func makeInlineHint(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .black)
        label.textColor = ShareTheme.accentText
        label.text = text.uppercased()
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    private func makeTagButton(for value: String, selected: Bool) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = "#\(value)"
        if selected {
            config.image = UIImage(systemName: "xmark.circle.fill")
            config.imagePlacement = .trailing
            config.imagePadding = 4
        }
        config.cornerStyle = .capsule
        config.baseBackgroundColor = selected ? ShareTheme.accentText.withAlphaComponent(isLightAppearance ? 0.10 : 0.16) : ShareTheme.surfaceRaised
        config.baseForegroundColor = selected ? ShareTheme.accentText : ShareTheme.text
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 9, bottom: 4, trailing: selected ? 7 : 9)
        config.titleLineBreakMode = .byTruncatingTail
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 12, weight: .bold)
            return outgoing
        }

        let button = ExpandedHitButton(type: .system)
        button.configuration = config
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.allowsDefaultTighteningForTruncation = true
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.78
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = selected ? ShareTheme.accentText.withAlphaComponent(0.26).cgColor : ShareTheme.stroke.cgColor
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        button.accessibilityLabel = selected ? "Remove tag \(value)" : "Add tag \(value)"
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.toggleTag(value, forceSelection: !selected)
        }), for: .touchUpInside)
        return button
    }

    private func makeTagEditorButton(hiddenCount: Int) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = tagsExpanded ? "Done" : "More"
        config.image = UIImage(systemName: tagsExpanded ? "checkmark.circle.fill" : "ellipsis.circle")
        config.imagePadding = 4
        config.cornerStyle = .capsule
        config.baseBackgroundColor = ShareTheme.surfaceRaised
        config.baseForegroundColor = ShareTheme.accentText
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 9, bottom: 4, trailing: 9)
        config.titleLineBreakMode = .byTruncatingTail
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 12, weight: .bold)
            return outgoing
        }

        let button = ExpandedHitButton(type: .system)
        button.configuration = config
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.78
        button.addTarget(self, action: #selector(toggleTagsEditor), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        if tagsExpanded {
            button.accessibilityLabel = "Done editing tags"
        } else if hiddenCount > 0 {
            button.accessibilityLabel = "Show \(hiddenCount) more tag suggestions"
        } else {
            button.accessibilityLabel = "Add custom tags"
        }
        return button
    }

    @objc private func toggleTagsEditor() {
        tagsExpanded.toggle()
        rebuildTagViews()
        UIView.animate(withDuration: 0.18) {
            self.view.layoutIfNeeded()
        }
    }

    private func suggestionTags(for share: PendingShare) -> [String] {
        let raw = dedupeTags(share.tags ?? [])
        let classified = classifyTagPool(raw, share: share)

        var tags = classified.strong
        tags.append(contentsOf: folderSuggestionTags(for: selectedFolderId, share: share))
        tags.append(contentsOf: intentSuggestionTags(for: share))
        tags.append(contentsOf: classified.platform)
        tags.append(contentsOf: classified.salvageable)
        if let sourceTag = normalizedSourceTag(for: share), !sourceTag.isEmpty {
            tags.append(sourceTag)
        }

        let base = [share.title, share.itemDescription, share.url, share.sourceApp]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

        for token in ["ai", "claude", "chatgpt", "news", "reddit", "instagram", "youtube", "recipe", "travel", "design", "research", "career", "productivity", "maps", "place", "health", "science", "conspiracy", "parasite", "worms"] where base.contains(token) {
            tags.append(token)
        }

        tags.append(contentsOf: commonFallbackTags(for: share))
        return Array(dedupeTags(tags).prefix(14))
    }

    private func defaultVisibleTagLimit() -> Int {
        let width = view.bounds.width
        if width > 430 { return 6 }
        if width >= 390 { return 5 }
        return 4
    }

    private func folderSuggestionTags(for folderId: String, share: PendingShare) -> [String] {
        switch folderId {
        case "f-life-admin":
            return ["important", "admin", "code", "warranty", "document"]
        case "f-must-see":
            return isVideoLike(share) ? ["watch later", "funny", "music", "tutorial", "review"] : ["read later", "reference", "important"]
        case "f-growth":
            return ["ai", "tutorial", "productivity", "prompt"]
        case "f-lmao":
            return ["funny", "meme", "wild"]
        case "f-wtf-favorites":
            return ["science", "space", "research"]
        case "f-travel":
            return ["place", "travel", "maps"]
        case "f-recipes":
            return ["recipe", "food", "try this"]
        case "f-research":
            return ["research", "reference", "paper"]
        case "f-health":
            return ["health", "wellness", "reference"]
        case "f-design":
            return ["design", "inspiration", "idea"]
        case "f-tinfoil":
            return ["conspiracy", "wild", "research"]
        case "f-private-vault":
            return ["important", "private", "document"]
        case "f-paste-bin":
            return ["note", "reference", "clipboard"]
        default:
            return []
        }
    }

    private func intentSuggestionTags(for share: PendingShare) -> [String] {
        let haystack = [share.title, share.itemDescription, share.text, share.url, share.sourceApp, share.fileName]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        var tags: [String] = []

        if isVideoLike(share) {
            tags.append(contentsOf: ["watch later", "funny", "music", "tutorial", "review", "news"])
        }
        if isPDFLike(share) || share.type.caseInsensitiveCompare("file") == .orderedSame {
            tags.append(contentsOf: ["document", "important", "reference"])
        }
        if share.type.caseInsensitiveCompare("article") == .orderedSame || share.url?.isEmpty == false {
            tags.append(contentsOf: ["read later", "reference", "important"])
        }
        if share.type.caseInsensitiveCompare("image") == .orderedSame || haystack.contains("screenshot") || haystack.contains("screen shot") {
            tags.append(contentsOf: ["screenshot", "meme", "inspiration", "reference"])
        }
        if share.type.caseInsensitiveCompare("place") == .orderedSame || haystack.contains("maps") {
            tags.append(contentsOf: ["place", "travel", "maps"])
        }

        let mappings: [(needles: [String], tags: [String])] = [
            (["joke", "funny", "comedy", "meme", "lol", "rickroll"], ["funny", "meme"]),
            (["song", "music", "album", "lyrics", "spotify", "soundcloud"], ["music"]),
            (["how to", "tutorial", "guide", "setup", "course"], ["tutorial", "try this"]),
            (["recipe", "cook", "dinner", "restaurant", "food"], ["recipe", "food"]),
            (["buy", "shopping", "amazon", "deal"], ["shopping"]),
            (["trip", "travel", "hotel", "flight", "map"], ["travel", "maps"]),
            (["door code", "wifi", "wi-fi", "contract", "insurance", "license", "receipt", "recovery code", "warranty", "serial number", "model number", "booking confirmation", "confirmation number"], ["important", "admin", "document"]),
            (["paper", "study", "research", "report"], ["research", "reference"]),
            (["invoice", "receipt", "tax", "insurance", "medical", "bank"], ["important", "document"]),
            (["voice note", "voice memo", "audio", "m4a", "mp3"], ["audio", "voice-note"])
        ]
        for mapping in mappings where mapping.needles.contains(where: { haystack.contains($0) }) {
            tags.append(contentsOf: mapping.tags)
        }

        return dedupeTags(tags)
    }

    private func commonFallbackTags(for share: PendingShare) -> [String] {
        if isVideoLike(share) {
            return ["watch later", "funny", "tutorial", "music", "review", "news"]
        }
        if isAudioLike(share) {
            return ["audio", "voice-note", "important", "reference"]
        }
        if isPDFLike(share) {
            return ["PDF", "document", "important", "reference"]
        }
        if share.type.caseInsensitiveCompare("image") == .orderedSame {
            return ["image", "screenshot", "meme", "inspiration"]
        }
        return ["read later", "important", "reference", "try this"]
    }

    private func isVideoLike(_ share: PendingShare) -> Bool {
        let joined = [share.type, share.url, share.mimeType, share.fileName, share.sourceApp]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        return share.type.caseInsensitiveCompare("video") == .orderedSame ||
            joined.contains("youtube") ||
            joined.contains("youtu.be") ||
            joined.contains("tiktok") ||
            joined.contains("vimeo") ||
            joined.contains("fb.watch") ||
            joined.contains("video/")
    }

    private func isAudioLike(_ share: PendingShare) -> Bool {
        let joined = [share.type, share.url, share.mimeType, share.fileName, share.sourceApp]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        return joined.contains("audio/") ||
            joined.range(of: #"\.(m4a|mp3|wav|caf|aac)(\?|$|\s)"#, options: .regularExpression) != nil ||
            joined.contains("voice memo")
    }

    private func isPDFLike(_ share: PendingShare) -> Bool {
        let joined = [share.type, share.url, share.mimeType, share.fileName]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        return share.type.caseInsensitiveCompare("pdf") == .orderedSame ||
            joined.contains("application/pdf") ||
            joined.range(of: #"\.pdf(\?|$|\s)"#, options: .regularExpression) != nil
    }

    private func refreshSuggestedTagsForCurrentShare() {
        guard let share = pendingShare else { return }
        let selectedLower = Set(selectedTags.map { $0.lowercased() })
        let next = suggestionTags(for: share)
            .filter { !selectedLower.contains($0.lowercased()) }
        suggestedTags = Array(dedupeTags(next + suggestedTags).prefix(10))
    }

    private func folderTheme(for preset: FolderPreset) -> (color: UIColor, glow: UIColor) {
        if let colorHex = preset.colorHex, let parsed = UIColor(hex: colorHex) {
            return (parsed, parsed.withAlphaComponent(0.18))
        }

        switch preset.id {
        case "f-life-admin":
            return (.systemYellow, UIColor.systemYellow.withAlphaComponent(0.18))
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
        case "f-random":
            return (.systemGray, UIColor.systemGray.withAlphaComponent(0.18))
        default:
            return (.systemBrown, UIColor.systemBrown.withAlphaComponent(0.18))
        }
    }

    private func selectedFolderTextColor(for color: UIColor) -> UIColor {
        if !isLightAppearance {
            return color
        }
        return color.saviIsVeryLight ? ShareTheme.text : color
    }

    private func refreshResolvedLayerColors() {
        view.backgroundColor = ShareTheme.background
        topBar.backgroundColor = ShareTheme.background.withAlphaComponent(0.86)
        loadingOverlay.backgroundColor = ShareTheme.background.withAlphaComponent(0.94)
        loadingCard.backgroundColor = ShareTheme.surface
        loadingCard.layer.shadowColor = ShareTheme.shadow.cgColor
        loadingCard.layer.shadowOpacity = isLightAppearance ? 0.09 : 0.24
        previewCard.backgroundColor = ShareTheme.surface
        previewCard.layer.shadowColor = ShareTheme.shadow.cgColor
        previewCard.layer.shadowOpacity = isLightAppearance ? 0.08 : 0.22
        notesTextView.textColor = ShareTheme.text
        notesTextView.backgroundColor = ShareTheme.surfaceRaised
        notesTextView.layer.borderColor = ShareTheme.stroke.cgColor
        notesPreviewLabel.textColor = ShareTheme.muted
    }

    private func updateSaveButton(isReady: Bool, titleOverride: String? = nil) {
        var config = saveButton.configuration ?? UIButton.Configuration.filled()
        config.title = titleOverride ?? (isReady ? "Save now" : "Preparing")
        config.baseBackgroundColor = isReady ? ShareTheme.accent : ShareTheme.surfaceRaised
        config.baseForegroundColor = isReady ? .black : ShareTheme.muted
        saveButton.configuration = config
        saveButton.isEnabled = isReady
        loadingSaveNowButton.isEnabled = isReady
    }

    @objc private func toggleTitleEditor() {
        titleEditorExpanded.toggle()
        updateTitleEditorPresentation(animated: true)
        if titleEditorExpanded {
            titleField.becomeFirstResponder()
            titleField.selectAll(nil)
        } else {
            titleField.resignFirstResponder()
        }
    }

    private func updateTitleEditorPresentation(animated: Bool) {
        let titleText = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !titleText.isEmpty {
            detectedTitleLabel.text = titleText
        } else if let pendingTitle = pendingShare?.title.trimmingCharacters(in: .whitespacesAndNewlines), !pendingTitle.isEmpty {
            detectedTitleLabel.text = pendingTitle
        }

        var config = editTitleButton.configuration ?? UIButton.Configuration.plain()
        config.title = titleEditorExpanded ? "Done" : "Edit title"
        config.image = UIImage(systemName: titleEditorExpanded ? "checkmark.circle.fill" : "pencil")
        editTitleButton.configuration = config

        let changes = {
            self.titleField.isHidden = !self.titleEditorExpanded
            self.titleField.alpha = self.titleEditorExpanded ? 1 : 0
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.18, animations: changes)
        } else {
            changes()
        }
    }

    @objc private func toggleNotes() {
        let shouldExpand = !notesExpanded
        if shouldExpand {
            setNotesExpanded(true, animated: true)
            notesTextView.becomeFirstResponder()
            scrollNotesIntoView()
        } else {
            notesTextView.resignFirstResponder()
            setNotesExpanded(false, animated: true)
        }
    }

    @objc private func clearNotesTapped() {
        notesTextView.text = ""
        didEditNotesManually = true
        updateNotesPresentation(animated: true)
    }

    private func setNotesExpanded(_ expanded: Bool, animated: Bool) {
        notesExpanded = expanded
        updateNotesPresentation(animated: animated)
    }

    private func updateNotesPresentation(animated: Bool) {
        let trimmedNotes = notesTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasNotes = !trimmedNotes.isEmpty
        notesPreviewLabel.text = hasNotes ? trimmedNotes : ""

        applyNotesToggleConfiguration(hasNotes: hasNotes)

        let changes = {
            self.notesTextView.isHidden = !self.notesExpanded
            self.notesTextView.alpha = self.notesExpanded ? 1 : 0
            self.notesPreviewLabel.isHidden = self.notesExpanded || !hasNotes
            self.notesPreviewLabel.alpha = (!self.notesExpanded && hasNotes) ? 1 : 0
            self.notesClearButton.isHidden = !self.notesExpanded || !hasNotes
            self.notesClearButton.isEnabled = hasNotes
            self.notesClearButton.alpha = hasNotes ? 1 : 0.42
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.18, animations: changes)
        } else {
            changes()
        }
    }

    private func applyNotesToggleConfiguration(hasNotes: Bool) {
        var config = UIButton.Configuration.plain()
        config.title = notesExpanded ? "Done" : (hasNotes ? "Edit note" : "Add note")
        config.image = UIImage(systemName: notesExpanded ? "checkmark.circle.fill" : (hasNotes ? "pencil.circle" : "plus.circle"))
        config.imagePadding = 6
        config.baseForegroundColor = ShareTheme.muted
        config.contentInsets = .zero
        notesToggleButton.configuration = config
    }

    private func updateNotesClearButton() {
        updateNotesPresentation(animated: false)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        guard textView === notesTextView else { return }
        if !notesExpanded {
            setNotesExpanded(true, animated: true)
        }
        scrollNotesIntoView()
    }

    func textViewDidChange(_ textView: UITextView) {
        guard textView === notesTextView else { return }
        didEditNotesManually = true
        updateNotesPresentation(animated: false)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField === tagsField else { return }
        if !tagsExpanded {
            tagsExpanded = true
            rebuildTagViews()
        }
        scrollTagInputIntoView()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === tagsField {
            commitTagInput(dismissKeyboard: false)
            return false
        }
        if textField === titleField {
            titleEditorExpanded = false
            updateTitleEditorPresentation(animated: true)
            textField.resignFirstResponder()
            return false
        }
        textField.resignFirstResponder()
        return false
    }

    private func toggleTag(_ value: String, forceSelection: Bool? = nil) {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        didEditTagsManually = true

        let shouldSelect = forceSelection ?? !selectedTags.map { $0.lowercased() }.contains(normalized.lowercased())
        if shouldSelect {
            selectedTags = Array(dedupeTags(selectedTags + [normalized]).prefix(6))
            suggestedTags.removeAll { $0.caseInsensitiveCompare(normalized) == .orderedSame }
        } else {
            selectedTags.removeAll { $0.caseInsensitiveCompare(normalized) == .orderedSame }
            if !suggestedTags.map({ $0.lowercased() }).contains(normalized.lowercased()) {
                suggestedTags = Array(dedupeTags([normalized] + suggestedTags).prefix(10))
            }
        }

        rebuildTagViews()
    }

    private func commitTagInput(dismissKeyboard: Bool) {
        let manualTags = normalizedManualTags(from: tagsField.text ?? "")
        guard !manualTags.isEmpty else {
            if dismissKeyboard {
                tagsField.resignFirstResponder()
            }
            updateAddTagButtonState()
            return
        }

        didEditTagsManually = true
        selectedTags = Array(dedupeTags(selectedTags + manualTags).prefix(6))
        suggestedTags.removeAll { suggestion in
            manualTags.contains { $0.caseInsensitiveCompare(suggestion) == .orderedSame }
        }
        tagsField.text = ""
        updateAddTagButtonState()
        rebuildTagViews()
        if dismissKeyboard {
            tagsField.resignFirstResponder()
        } else {
            tagsField.becomeFirstResponder()
        }
    }

    private func normalizedManualTags(from value: String) -> [String] {
        value
            .split(whereSeparator: { $0 == "," || $0 == "\n" || $0 == "\r" })
            .compactMap { normalizedManualTag(String($0)) }
    }

    private func normalizedManualTag(_ value: String) -> String? {
        var cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        while cleaned.hasPrefix("#") {
            cleaned.removeFirst()
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        cleaned = cleaned
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.nilIfEmpty
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
        folderSelectionSource = ShareFolderSelection.isAuto(selectedFolderId) ? .auto : .manual
        refreshSuggestedTagsForCurrentShare()
        rebuildFolderButtons()
        rebuildTagViews()
    }

    @objc private func titleFieldChanged() {
        didEditTitleManually = true
        updateTitleEditorPresentation(animated: false)
    }

    @objc private func tagsFieldChanged() {
        didEditTagsManually = true
        updateAddTagButtonState()
    }

    @objc private func addTagButtonTapped() {
        commitTagInput(dismissKeyboard: false)
    }

    @objc private func tagToolbarAddTapped() {
        commitTagInput(dismissKeyboard: false)
    }

    @objc private func dismissKeyboardTapped() {
        view.endEditing(true)
    }

    @objc private func keyboardDoneTapped() {
        if tagsField.isFirstResponder {
            commitTagInput(dismissKeyboard: true)
        } else if titleField.isFirstResponder {
            titleEditorExpanded = false
            updateTitleEditorPresentation(animated: true)
            titleField.resignFirstResponder()
        } else {
            view.endEditing(true)
        }
    }

    @objc private func toggleFolderGrid() {
        folderGridExpanded.toggle()
        rebuildFolderButtons()
        UIView.animate(withDuration: 0.18) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func cancelTapped() {
        extensionContext?.cancelRequest(withError: NSError(domain: "SAVIShareExtension", code: 0))
    }

    @objc private func saveTapped() {
        guard var pendingShare else { return }
        didFinishSaving = true
        enrichmentTask?.cancel()
        setLoadingOverlay(visible: false, title: nil, body: nil)

        let trimmedTitle = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notesTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let manualTags = normalizedManualTags(from: tagsField.text ?? "")

        pendingShare.title = trimmedTitle.nilIfEmpty ?? pendingShare.title
        if didEditNotesManually || !trimmedNotes.isEmpty {
            pendingShare.itemDescription = trimmedNotes.nilIfEmpty
        }
        pendingShare.folderId = ShareFolderSelection.isAuto(selectedFolderId) ? nil : selectedFolderId
        pendingShare.folderSource = folderSelectionSource.pendingValue
        if folderSelectionSource == .manual {
            pendingShare.folderConfidence = nil
            pendingShare.folderReason = "manual"
        }
        pendingShare.tags = dedupeTags(selectedTags + manualTags)

        do {
            let startedAt = Date()
            let fileURL = try PendingShareStore.shared.save(pendingShare)
            PendingShareStore.shared.recordShareExtensionSave(folderId: pendingShare.folderId)
            NSLog("[SAVIShareExtension] saved pending share %@ in %.3fs at %@", pendingShare.id, Date().timeIntervalSince(startedAt), fileURL.path)
            updateSaveButton(isReady: false, titleOverride: "Saved")
            extensionContext?.completeRequest(returningItems: nil)
        } catch {
            if let pendingError = error as? PendingShareStoreError,
               case .missingAppGroupContainer = pendingError {
                saveViaDeepLinkFallback(pendingShare)
                return
            }

            NSLog("[SAVIShareExtension] failed to save pending share: %@", error.localizedDescription)
            previewSubtitleLabel.text = error.localizedDescription
            updateSaveButton(isReady: true)
        }
    }

    private func saveViaDeepLinkFallback(_ pendingShare: PendingShare) {
        if SAVIPasteboardShare.save(pendingShare) {
            previewSubtitleLabel.text = "Saved for \(ShareReleaseGate.hostAppDisplayName). Opening the app to finish."
            updateSaveButton(isReady: false, titleOverride: "Saved")

            let completion = ShareFallbackCompletion()
            let finishExtension: () -> Void = { [weak self] in
                DispatchQueue.main.async {
                    guard let self, !completion.didComplete else { return }
                    completion.didComplete = true
                    self.extensionContext?.completeRequest(returningItems: nil)
                }
            }

            if let url = SAVIPasteboardShare.makeHandoffURL() {
                extensionContext?.open(url, completionHandler: { [weak self] success in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        if success {
                            NSLog("[SAVIShareExtension] opened SAVI pasteboard handoff for %@", pendingShare.id)
                        } else {
                            NSLog("[SAVIShareExtension] SAVI pasteboard handoff saved but app open failed for %@", pendingShare.id)
                            self.previewSubtitleLabel.text = "Saved. Open \(ShareReleaseGate.hostAppDisplayName) to finish importing."
                        }
                        finishExtension()
                    }
                })
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    finishExtension()
                }
            } else {
                finishExtension()
            }
            return
        }

        guard SAVIDeepLinkShare.supportsFallback(pendingShare),
              let url = SAVIDeepLinkShare.makeURL(from: pendingShare)
        else {
            didFinishSaving = false
            previewSubtitleLabel.text = "This test build can save links and text. Files need the App Group production build."
            updateSaveButton(isReady: true)
            return
        }

        previewSubtitleLabel.text = "Opening SAVI to finish this save."
        updateSaveButton(isReady: false, titleOverride: "Opening SAVI")
        extensionContext?.open(url, completionHandler: { [weak self] success in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    NSLog("[SAVIShareExtension] opened SAVI deep link fallback for %@", pendingShare.id)
                    self.updateSaveButton(isReady: false, titleOverride: "Saved")
                    self.extensionContext?.completeRequest(returningItems: nil)
                } else {
                    NSLog("[SAVIShareExtension] failed to open SAVI deep link fallback for %@", pendingShare.id)
                    self.didFinishSaving = false
                    self.previewSubtitleLabel.text = "Could not open SAVI. Open the test app once, then try Save now again."
                    self.updateSaveButton(isReady: true)
                }
            }
        })
    }
}

private final class ShareFallbackCompletion {
    var didComplete = false
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

    var saviIsVeryLight: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return false }
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue > 0.70
    }

    var saviUsesLightForeground: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return true }
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue < 0.52
    }
}
