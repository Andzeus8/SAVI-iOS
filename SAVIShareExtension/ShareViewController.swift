import UIKit

final class ShareViewController: UIViewController, UITextFieldDelegate {
    private let topBar = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let loadingOverlay = UIView()
    private let loadingCard = UIView()
    private let loadingTitleLabel = UILabel()
    private let loadingBodyLabel = UILabel()
    private let loadingProgressTrack = UIView()
    private let loadingProgressFill = UIView()

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

    private var pendingShare: PendingShare?
    private var availableFolders: [FolderPreset] = ShareItemExtractor.folderPresets()
    private var selectedFolderId = "f-must-see"
    private var selectedTags: [String] = []
    private var suggestedTags: [String] = []
    private var notesExpanded = false
    private var loadingProgressWidthConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        Task { await loadSharedItem() }
    }

    private func configureView() {
        view.backgroundColor = UIColor(red: 0.967, green: 0.973, blue: 0.988, alpha: 1)

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

        let folderSection = makeSectionCard(emphasized: true)
        folderSection.addArrangedSubview(makeSectionLabel("Folder"))
        folderSection.addArrangedSubview(makeHintLabel("Auto-picked for you. Change it only if SAVI guessed wrong."))
        folderSection.addArrangedSubview(folderSummaryCard)
        configureFolderGrid()
        folderSection.addArrangedSubview(folderGridStack)

        let tagsSection = makeSectionCard()
        tagsSection.addArrangedSubview(makeSectionLabel("Tags"))
        tagsSection.addArrangedSubview(makeHintLabel("A few smart tags make this easy to find later. Keep the strongest ones."))
        tagsSection.addArrangedSubview(makeSubsectionLabel("Selected"))
        tagsSection.addArrangedSubview(makeInlineHint("Tap any selected tag to remove it."))
        configureHorizontalStrip(scrollView: selectedTagScrollView, row: selectedTagRow, height: 42)
        tagsSection.addArrangedSubview(selectedTagScrollView)
        tagsSection.addArrangedSubview(makeSubsectionLabel("Suggestions"))
        configureHorizontalStrip(scrollView: suggestedTagScrollView, row: suggestedTagRow, height: 42)
        tagsSection.addArrangedSubview(suggestedTagScrollView)
        configureTextField(tagsField, placeholder: "Add extra tags, comma separated")
        tagsSection.addArrangedSubview(tagsField)

        [previewCard, folderSection, tagsSection].forEach { contentStack.addArrangedSubview($0) }

        setNotesExpanded(false, animated: false)
        if let firstFolder = availableFolders.first?.id, !firstFolder.isEmpty {
            selectedFolderId = firstFolder
        }
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

    private func configureLoadingOverlay() {
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
        loadingOverlay.isHidden = true
        loadingOverlay.alpha = 0
        view.addSubview(loadingOverlay)

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialLight))
        blur.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(blur)

        loadingCard.translatesAutoresizingMaskIntoConstraints = false
        loadingCard.backgroundColor = .systemBackground
        loadingCard.layer.cornerRadius = 28
        loadingCard.layer.shadowColor = UIColor.black.cgColor
        loadingCard.layer.shadowOpacity = 0.08
        loadingCard.layer.shadowRadius = 24
        loadingCard.layer.shadowOffset = CGSize(width: 0, height: 12)
        loadingOverlay.addSubview(loadingCard)

        let orb = UIView()
        orb.translatesAutoresizingMaskIntoConstraints = false
        orb.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.12)
        orb.layer.cornerRadius = 34
        loadingCard.addSubview(orb)

        let orbIcon = UIImageView(image: UIImage(systemName: "sparkles"))
        orbIcon.translatesAutoresizingMaskIntoConstraints = false
        orbIcon.tintColor = .systemIndigo
        orbIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        orb.addSubview(orbIcon)

        loadingTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingTitleLabel.font = .preferredFont(forTextStyle: .title3).bold()
        loadingTitleLabel.textAlignment = .center
        loadingTitleLabel.numberOfLines = 2
        loadingTitleLabel.text = "SAVI is getting this ready"
        loadingCard.addSubview(loadingTitleLabel)

        loadingBodyLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingBodyLabel.font = .preferredFont(forTextStyle: .body)
        loadingBodyLabel.textColor = .secondaryLabel
        loadingBodyLabel.textAlignment = .center
        loadingBodyLabel.numberOfLines = 3
        loadingBodyLabel.text = "Pulling the title, preview image, best folder, and useful tags so you can save fast."
        loadingCard.addSubview(loadingBodyLabel)

        loadingProgressTrack.translatesAutoresizingMaskIntoConstraints = false
        loadingProgressTrack.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.12)
        loadingProgressTrack.layer.cornerRadius = 7
        loadingProgressTrack.layer.masksToBounds = true
        loadingCard.addSubview(loadingProgressTrack)

        loadingProgressFill.translatesAutoresizingMaskIntoConstraints = false
        loadingProgressFill.backgroundColor = .systemIndigo
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

            loadingProgressTrack.leadingAnchor.constraint(equalTo: loadingCard.leadingAnchor, constant: 24),
            loadingProgressTrack.trailingAnchor.constraint(equalTo: loadingCard.trailingAnchor, constant: -24),
            loadingProgressTrack.topAnchor.constraint(equalTo: loadingBodyLabel.bottomAnchor, constant: 20),
            loadingProgressTrack.heightAnchor.constraint(equalToConstant: 14),
            loadingProgressTrack.bottomAnchor.constraint(equalTo: loadingCard.bottomAnchor, constant: -24),

            loadingProgressFill.leadingAnchor.constraint(equalTo: loadingProgressTrack.leadingAnchor),
            loadingProgressFill.topAnchor.constraint(equalTo: loadingProgressTrack.topAnchor),
            loadingProgressFill.bottomAnchor.constraint(equalTo: loadingProgressTrack.bottomAnchor),
        ])
    }

    private func configurePreviewCard() {
        previewCard.backgroundColor = .systemBackground
        previewCard.layer.cornerRadius = 22
        previewCard.layer.shadowColor = UIColor.black.cgColor
        previewCard.layer.shadowOpacity = 0.07
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

        detectedTitleLabel.font = .preferredFont(forTextStyle: .caption1).bold()
        detectedTitleLabel.textColor = .secondaryLabel
        detectedTitleLabel.numberOfLines = 2
        detectedTitleLabel.text = "Preparing your save…"

        previewMetaLabel.font = .preferredFont(forTextStyle: .caption1)
        previewMetaLabel.textColor = .systemIndigo
        previewMetaLabel.text = "Share Extension • Link"

        previewSubtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        previewSubtitleLabel.textColor = .secondaryLabel
        previewSubtitleLabel.numberOfLines = 2
        previewSubtitleLabel.text = "Pulling the title, a clean preview, the best folder, and useful tags."

        spinner.startAnimating()

        let topRow = UIStackView(arrangedSubviews: [statusBadge, UIView(), spinner])
        topRow.axis = .horizontal
        topRow.alignment = .center

        let textStack = UIStackView(arrangedSubviews: [topRow, detectedTitleLabel, previewMetaLabel, previewSubtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        innerStack.addArrangedSubview(mediaWrap)
        innerStack.addArrangedSubview(textStack)

        configureTextField(titleField, placeholder: "Add a clear title")
        titleField.font = .preferredFont(forTextStyle: .body).bold()
        titleField.clearButtonMode = .always

        configureNotesToggle()
        notesTextView.font = .preferredFont(forTextStyle: .body)
        notesTextView.textColor = .label
        notesTextView.backgroundColor = UIColor.secondarySystemBackground
        notesTextView.layer.cornerRadius = 16
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = UIColor.separator.withAlphaComponent(0.45).cgColor
        notesTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        notesTextView.heightAnchor.constraint(equalToConstant: 94).isActive = true

        cardStack.addArrangedSubview(innerStack)
        cardStack.addArrangedSubview(titleField)
        cardStack.addArrangedSubview(notesToggleButton)
        cardStack.addArrangedSubview(notesTextView)
    }

    private func configureFolderSummaryCard() {
        folderSummaryCard.backgroundColor = .secondarySystemBackground
        folderSummaryCard.layer.cornerRadius = 20
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

        folderSummaryTitleLabel.font = .preferredFont(forTextStyle: .title3).bold()
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
        folderGridStack.spacing = 8
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
                pendingShare = share
                setLoadingOverlay(
                    visible: true,
                    title: "SAVI is getting this ready",
                    body: "Pulling the title, preview image, best folder, and useful tags so you can save fast."
                )
                applyShare(share, animated: false)
                statusBadge.text = "Auto-filling"
                previewSubtitleLabel.text = "Pulling the title, a clean preview, the best folder, and useful tags."
                updateSaveButton(isReady: false)
            }

            let enriched = await ShareItemExtractor.enrich(share)
            await MainActor.run {
                pendingShare = enriched
                applyShare(enriched, animated: true)
                spinner.stopAnimating()
                let needsReview = needsManualReview(enriched)
                statusBadge.text = needsReview ? "Check title" : "Ready"
                previewSubtitleLabel.text = needsReview
                    ? "We pulled what we could. Fix the title here if needed, add a quick note, then save."
                    : "Looks good. Save now or tweak anything right here."
                setNotesExpanded(needsReview, animated: true)
                setLoadingOverlay(visible: false, title: nil, body: nil)
                updateSaveButton(isReady: true)
            }
        } catch {
            await MainActor.run {
                detectedTitleLabel.text = "Couldn’t read this share"
                previewSubtitleLabel.text = "We couldn't pull metadata here. Add a title, optional note, and save it anyway."
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

    private func applyShare(_ share: PendingShare, animated: Bool) {
        let summary = share.itemDescription ?? share.text ?? previewText(for: share)
        detectedTitleLabel.text = share.title
        previewMetaLabel.text = "\(share.sourceApp) • \(share.type.capitalized)"
        previewSubtitleLabel.text = summary
        titleField.text = share.title
        notesTextView.text = summary

        selectedFolderId = share.folderId ?? selectedFolderId
        selectedTags = Array(prioritizedDisplayTags(for: share).prefix(3))
        suggestedTags = Array(
            suggestionTags(for: share)
                .filter { !selectedTags.map { $0.lowercased() }.contains($0.lowercased()) }
                .prefix(6)
        )

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
        let selectedPreset = presets.first(where: { $0.id == selectedFolderId }) ?? FolderPreset(id: "f-must-see", name: "Must See", symbolName: "bookmark.fill", colorHex: "#F7C948")
        let theme = folderTheme(for: selectedPreset)

        folderSummaryCard.backgroundColor = theme.color.withAlphaComponent(0.10)
        folderSummaryCard.layer.borderColor = theme.color.withAlphaComponent(0.22).cgColor
        folderSummaryIconWrap.backgroundColor = theme.color
        folderSummaryIconView.image = UIImage(systemName: selectedPreset.symbolName)
        folderSummaryTitleLabel.text = selectedPreset.name
        if pendingShare?.folderId == selectedFolderId {
            folderSummaryHintLabel.text = "Auto-picked and ready."
        } else {
            folderSummaryHintLabel.text = "Changed for this save."
        }

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

    private func makeFolderButton(for preset: FolderPreset) -> UIButton {
        let theme = folderTheme(for: preset)
        let isSelected = preset.id == selectedFolderId

        var config = UIButton.Configuration.filled()
        config.title = preset.name
        config.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : preset.symbolName)
        config.imagePadding = 8
        config.imagePlacement = .leading
        config.cornerStyle = .large
        config.baseBackgroundColor = isSelected ? theme.color.withAlphaComponent(0.18) : .white
        config.baseForegroundColor = isSelected ? theme.color : .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        config.titleAlignment = .leading
        config.subtitle = nil
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 1
        button.layer.borderColor = (isSelected ? theme.color.withAlphaComponent(0.28) : UIColor.separator.withAlphaComponent(0.22)).cgColor
        button.heightAnchor.constraint(equalToConstant: 54).isActive = true
        button.tag = availableFolders.firstIndex(where: { $0.id == preset.id }) ?? 0
        button.addTarget(self, action: #selector(folderTapped(_:)), for: .touchUpInside)
        return button
    }

    private func prioritizedDisplayTags(for share: PendingShare) -> [String] {
        let raw = dedupeTags(share.tags ?? [])
        return classifyTagPool(raw, share: share).strong
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
            "cnn", "bbc", "reuters", "new-york-times", "news"
        ])
        let banned = Set([
            "camera", "camera-phone", "phone-camera", "sharing", "shared", "open-app",
            "app", "photo", "photos", "mobile", "smartphone", "watch", "save"
        ])
        let preferredTopicTags = Set([
            "parasite", "worms", "health", "travel", "food", "science", "design",
            "conspiracy", "productivity", "funny", "research", "recipe"
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

        return (
            strong: Array(dedupeTags(orderedStrong).prefix(3)),
            platform: Array(dedupeTags(platformMatches).prefix(2)),
            salvageable: Array(dedupeTags(salvageable).prefix(4))
        )
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

        if visible {
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
        if selected {
            config.image = UIImage(systemName: "xmark.circle.fill")
            config.imagePlacement = .trailing
            config.imagePadding = 6
        }
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
        let raw = dedupeTags(share.tags ?? [])
        let classified = classifyTagPool(raw, share: share)

        var tags = classified.strong
        tags.append(contentsOf: classified.platform)
        tags.append(contentsOf: classified.salvageable)

        let base = [share.title, share.itemDescription, share.url, share.sourceApp]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

        for token in ["ai", "claude", "chatgpt", "news", "reddit", "instagram", "youtube", "recipe", "travel", "design", "research", "career", "productivity", "maps", "place", "health", "science", "conspiracy", "parasite", "worms"] where base.contains(token) {
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

        do {
            try PendingShareStore.shared.save(pendingShare)
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
