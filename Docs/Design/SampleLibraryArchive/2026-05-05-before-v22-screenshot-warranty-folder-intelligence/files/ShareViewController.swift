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

    private let folderSummaryCard = UIView()
    private let folderSummaryIconWrap = UIView()
    private let folderSummaryIconView = UIImageView()
    private let folderSummaryTitleLabel = UILabel()
    private let folderSummaryHintLabel = UILabel()
    private let folderChangeButton = UIButton(type: .system)
    private let folderQuickScrollView = UIScrollView()
    private let folderQuickRow = UIStackView()
    private let folderGridStack = UIStackView()

    private let titleField = UITextField()

    private let selectedTagScrollView = UIScrollView()
    private let selectedTagRow = UIStackView()
    private let suggestedTagScrollView = UIScrollView()
    private let suggestedTagRow = UIStackView()
    private let tagsField = UITextField()

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
    private var folderGridExpanded = false
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
    }

    private func configureView() {
        view.backgroundColor = ShareTheme.background
        registerForKeyboardNotifications()

        configureTopBar()
        configureLoadingOverlay()

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
        configureFolderSummaryCard()

        let folderSection = makeSectionCard()
        folderSection.addArrangedSubview(folderSummaryCard)
        configureHorizontalStrip(scrollView: folderQuickScrollView, row: folderQuickRow, height: 40)
        folderSection.addArrangedSubview(folderQuickScrollView)
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
        cardStack.spacing = 12
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        previewCard.addSubview(cardStack)

        NSLayoutConstraint.activate([
            cardStack.leadingAnchor.constraint(equalTo: previewCard.leadingAnchor, constant: 14),
            cardStack.trailingAnchor.constraint(equalTo: previewCard.trailingAnchor, constant: -14),
            cardStack.topAnchor.constraint(equalTo: previewCard.topAnchor, constant: 14),
            cardStack.bottomAnchor.constraint(equalTo: previewCard.bottomAnchor, constant: -14),
        ])

        let innerStack = UIStackView()
        innerStack.axis = .horizontal
        innerStack.alignment = .center
        innerStack.spacing = 14

        let mediaWrap = UIView()
        mediaWrap.translatesAutoresizingMaskIntoConstraints = false
        mediaWrap.widthAnchor.constraint(equalToConstant: 72).isActive = true
        mediaWrap.heightAnchor.constraint(equalToConstant: 72).isActive = true
        mediaWrap.layer.cornerRadius = 18
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

        detectedTitleLabel.font = .preferredFont(forTextStyle: .headline).bold()
        detectedTitleLabel.textColor = ShareTheme.muted
        detectedTitleLabel.numberOfLines = 3
        detectedTitleLabel.text = "Preparing your save..."

        previewMetaLabel.font = .preferredFont(forTextStyle: .caption1).bold()
        previewMetaLabel.textColor = ShareTheme.accentText
        previewMetaLabel.text = "Share Extension • Link"

        previewSubtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        previewSubtitleLabel.textColor = ShareTheme.muted
        previewSubtitleLabel.numberOfLines = 1
        previewSubtitleLabel.text = "Ready"

        spinner.startAnimating()

        let topRow = UIStackView(arrangedSubviews: [statusBadge, UIView(), spinner])
        topRow.axis = .horizontal
        topRow.alignment = .center

        let textStack = UIStackView(arrangedSubviews: [topRow, detectedTitleLabel, previewMetaLabel, previewSubtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        innerStack.addArrangedSubview(mediaWrap)
        innerStack.addArrangedSubview(textStack)

        configureTextField(titleField, placeholder: "Clean title (optional)")
        titleField.font = .preferredFont(forTextStyle: .body).bold()
        titleField.clearButtonMode = .always
        titleField.addTarget(self, action: #selector(titleFieldChanged), for: .editingChanged)

        configureHorizontalStrip(scrollView: selectedTagScrollView, row: selectedTagRow, height: 34)
        configureTextField(tagsField, placeholder: "Add custom tags, comma separated")
        tagsField.addTarget(self, action: #selector(tagsFieldChanged), for: .editingChanged)
        tagsField.isHidden = true

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
        cardStack.addArrangedSubview(selectedTagScrollView)
        cardStack.addArrangedSubview(tagsField)
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
        changeConfig.title = "More"
        changeConfig.image = UIImage(systemName: "ellipsis.circle")
        changeConfig.imagePlacement = .trailing
        changeConfig.imagePadding = 5
        changeConfig.baseForegroundColor = ShareTheme.accentText
        changeConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        folderChangeButton.configuration = changeConfig
        folderChangeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        folderChangeButton.addTarget(self, action: #selector(toggleFolderGrid), for: .touchUpInside)
        folderChangeButton.accessibilityLabel = "Change folder"

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
        folderGridStack.spacing = 8
        folderGridStack.translatesAutoresizingMaskIntoConstraints = false
        folderGridStack.isHidden = true
    }

    private func configureHorizontalStrip(scrollView: UIScrollView, row: UIStackView, height: CGFloat) {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delaysContentTouches = false
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
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.leftViewMode = .always
        textField.delegate = self
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
        !(touch.view is UIControl)
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
              thumbnail.hasPrefix("data:"),
              let commaIndex = thumbnail.firstIndex(of: ",")
        else { return nil }

        let encoded = String(thumbnail[thumbnail.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: encoded) else { return nil }
        return UIImage(data: data)
    }

    private func rebuildFolderButtons() {
        clearArrangedSubviews(of: folderGridStack)
        clearArrangedSubviews(of: folderQuickRow)

        availableFolders = ShareFolderSelection.presetsForDisplay()
        let presets = availableFolders
        let selectedPreset = presets.first(where: { $0.id == selectedFolderId }) ?? ShareFolderSelection.autoPreset
        let selectedIsPublic = showsPublicBadge(for: selectedPreset)
        let theme = folderTheme(for: selectedPreset)

        folderSummaryCard.backgroundColor = theme.color.withAlphaComponent(0.10)
        folderSummaryCard.layer.borderColor = theme.color.withAlphaComponent(0.40).cgColor
        folderSummaryIconWrap.backgroundColor = theme.color
        folderSummaryIconView.image = UIImage(systemName: selectedIsPublic ? "person.2.fill" : selectedPreset.symbolName)
        folderSummaryIconView.tintColor = theme.color.saviUsesLightForeground ? .white : .black
        folderSummaryTitleLabel.text = selectedPreset.name
        let hint: String
        if folderSelectionSource == .intelligence {
            hint = "AI suggested"
        } else if folderSelectionSource == .metadata {
            hint = "Metadata suggested"
        } else if folderSelectionSource == .rules {
            hint = "Rules suggested"
        } else if ShareFolderSelection.isAuto(selectedFolderId) {
            hint = "Auto-select on import"
        } else {
            hint = "You picked this"
        }
        folderSummaryHintLabel.text = selectedIsPublic ? "\(hint) • Public" : hint

        var changeConfig = folderChangeButton.configuration ?? UIButton.Configuration.plain()
        changeConfig.title = folderGridExpanded ? "Done" : "More"
        changeConfig.image = UIImage(systemName: folderGridExpanded ? "chevron.up" : "ellipsis.circle")
        folderChangeButton.configuration = changeConfig
        folderGridStack.isHidden = !folderGridExpanded

        prioritizedFolderPresets(presets).forEach { preset in
            folderQuickRow.addArrangedSubview(makeFolderQuickButton(for: preset))
        }

        folderQuickRow.addArrangedSubview(makeMoreFoldersButton())

        for index in stride(from: 0, to: presets.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .fill
            row.distribution = .fillEqually
            row.spacing = 8

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

    private func prioritizedFolderPresets(_ presets: [FolderPreset]) -> [FolderPreset] {
        var ordered: [FolderPreset] = []

        func append(_ preset: FolderPreset?) {
            guard let preset,
                  !ordered.contains(where: { $0.id == preset.id })
            else { return }
            ordered.append(preset)
        }

        let selectedPreset = presets.first(where: { $0.id == selectedFolderId })
        if let selectedPreset, !ShareFolderSelection.isAuto(selectedPreset.id) {
            append(selectedPreset)
        }

        let recentFolderIds = PendingShareStore.shared
            .loadShareSetupState()
            .recentFolders
            .sorted {
                if $0.lastUsedAt == $1.lastUsedAt {
                    return $0.useCount > $1.useCount
                }
                return $0.lastUsedAt > $1.lastUsedAt
            }
            .map(\.folderId)

        recentFolderIds.forEach { id in
            append(presets.first(where: { $0.id == id }))
        }

        append(presets.first(where: { ShareFolderSelection.isAuto($0.id) }))

        let preferredIds = [
            "f-private-vault",
            "f-life-admin",
            "f-must-see",
            "f-growth",
            "f-lmao",
            "f-wtf-favorites",
            "f-travel",
            "f-recipes",
            "f-research"
        ]
        preferredIds.forEach { id in
            append(presets.first(where: { $0.id == id }))
        }

        presets.forEach { append($0) }
        return Array(ordered.prefix(8))
    }

    private func makeFolderQuickButton(for preset: FolderPreset) -> UIButton {
        let theme = folderTheme(for: preset)
        let isSelected = preset.id == selectedFolderId
        let isPublic = showsPublicBadge(for: preset)

        var config = UIButton.Configuration.filled()
        config.title = preset.name
        config.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : isPublic ? "person.2.fill" : preset.symbolName)
        config.imagePadding = 6
        config.imagePlacement = .leading
        config.cornerStyle = .capsule
        config.baseBackgroundColor = isSelected ? theme.color.withAlphaComponent(0.22) : ShareTheme.surfaceRaised
        config.baseForegroundColor = isSelected ? selectedFolderTextColor(for: theme.color) : ShareTheme.text
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 11, bottom: 7, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = (isSelected ? theme.color.withAlphaComponent(0.46) : ShareTheme.stroke).cgColor
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.tag = availableFolders.firstIndex(where: { $0.id == preset.id }) ?? 0
        button.addTarget(self, action: #selector(quickFolderTapped(_:)), for: .touchUpInside)
        button.accessibilityLabel = isPublic ? "Save to \(preset.name), Public Folder" : "Save to \(preset.name)"
        return button
    }

    private func makeMoreFoldersButton() -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = folderGridExpanded ? "Done" : "More folders"
        config.image = UIImage(systemName: folderGridExpanded ? "chevron.up" : "ellipsis.circle")
        config.imagePadding = 6
        config.imagePlacement = .leading
        config.cornerStyle = .capsule
        config.baseBackgroundColor = ShareTheme.surfaceRaised
        config.baseForegroundColor = ShareTheme.accentText
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 11, bottom: 7, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .bold)
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = ShareTheme.stroke.cgColor
        button.heightAnchor.constraint(equalToConstant: 36).isActive = true
        button.addTarget(self, action: #selector(toggleFolderGrid), for: .touchUpInside)
        button.accessibilityLabel = folderGridExpanded ? "Hide folder picker" : "Show more folders"
        return button
    }

    private func makeFolderButton(for preset: FolderPreset) -> UIButton {
        let theme = folderTheme(for: preset)
        let isSelected = preset.id == selectedFolderId
        let isPublic = showsPublicBadge(for: preset)

        var config = UIButton.Configuration.filled()
        config.title = preset.name
        config.subtitle = isPublic ? "Public" : nil
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
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = (isSelected ? theme.color.withAlphaComponent(0.46) : ShareTheme.stroke).cgColor
        button.heightAnchor.constraint(equalToConstant: isPublic ? 56 : 50).isActive = true
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
        clearArrangedSubviews(of: selectedTagRow)
        clearArrangedSubviews(of: suggestedTagRow)

        selectedTagRow.addArrangedSubview(makeInlineHint("Smart tags"))

        let selectedValues = selectedTags.map { (value: $0, selected: true) }
        let suggestedValues = suggestedTags.map { (value: $0, selected: false) }
        let allValues = selectedValues + suggestedValues
        let visibleLimit = defaultVisibleTagLimit()
        let visibleValues = tagsExpanded ? allValues : Array(allValues.prefix(visibleLimit))

        if visibleValues.isEmpty {
            selectedTagRow.addArrangedSubview(makeInlineHint(pendingShare == nil ? "Detecting..." : "Add tags"))
        } else {
            visibleValues.forEach { tag in
                selectedTagRow.addArrangedSubview(makeTagButton(for: tag.value, selected: tag.selected))
            }
        }

        let hiddenCount = max(0, allValues.count - visibleValues.count)
        selectedTagRow.addArrangedSubview(makeTagEditorButton(hiddenCount: hiddenCount))
        tagsField.isHidden = !tagsExpanded
    }

    private func makeInlineHint(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ShareTheme.muted
        label.text = text
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    private func makeTagButton(for value: String, selected: Bool) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = selected ? value : "+ \(value)"
        if selected {
            config.image = UIImage(systemName: "xmark.circle.fill")
            config.imagePlacement = .trailing
            config.imagePadding = 6
        }
        config.cornerStyle = .capsule
        config.baseBackgroundColor = selected ? ShareTheme.accentText.withAlphaComponent(isLightAppearance ? 0.10 : 0.16) : ShareTheme.surfaceRaised
        config.baseForegroundColor = selected ? ShareTheme.accentText : ShareTheme.text
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 12, weight: .semibold)
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = selected ? ShareTheme.accentText.withAlphaComponent(0.26).cgColor : ShareTheme.stroke.cgColor
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 32).isActive = true
        button.accessibilityLabel = selected ? "Remove tag \(value)" : "Add tag \(value)"
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.toggleTag(value, forceSelection: !selected)
        }), for: .touchUpInside)
        return button
    }

    private func makeTagEditorButton(hiddenCount: Int) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = tagsExpanded ? "Done" : (hiddenCount > 0 ? "+\(hiddenCount) More" : "More")
        config.image = UIImage(systemName: tagsExpanded ? "checkmark.circle.fill" : "ellipsis.circle")
        config.imagePadding = 5
        config.cornerStyle = .capsule
        config.baseBackgroundColor = ShareTheme.surfaceRaised
        config.baseForegroundColor = ShareTheme.accentText
        config.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 12, weight: .bold)
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(toggleTagsEditor), for: .touchUpInside)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 32).isActive = true
        button.accessibilityLabel = tagsExpanded ? "Done editing tags" : "Show more tags"
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
            return ["important", "admin", "code", "document", "travel"]
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
            (["door code", "wifi", "wi-fi", "contract", "insurance", "license", "receipt", "recovery code"], ["important", "admin", "document"]),
            (["paper", "study", "research", "report"], ["research", "reference"]),
            (["invoice", "receipt", "tax", "insurance", "medical", "bank"], ["important", "document"])
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
            self.notesClearButton.isHidden = !self.notesExpanded && !hasNotes
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
        folderGridExpanded = false
        refreshSuggestedTagsForCurrentShare()
        rebuildFolderButtons()
        rebuildTagViews()
    }

    @objc private func quickFolderTapped(_ sender: UIButton) {
        guard availableFolders.indices.contains(sender.tag) else { return }
        guard pendingShare != nil else {
            previewSubtitleLabel.text = "Still loading"
            return
        }
        selectedFolderId = availableFolders[sender.tag].id
        folderSelectionSource = ShareFolderSelection.isAuto(selectedFolderId) ? .auto : .manual
        folderGridExpanded = false
        refreshSuggestedTagsForCurrentShare()
        rebuildFolderButtons()
        rebuildTagViews()
        saveTapped()
    }

    @objc private func titleFieldChanged() {
        didEditTitleManually = true
    }

    @objc private func tagsFieldChanged() {
        didEditTagsManually = true
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
        let manualTags = (tagsField.text ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

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
