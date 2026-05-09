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
import CloudKit
import AuthenticationServices
#if canImport(FoundationModels)
import FoundationModels
#endif

struct PublicProfileSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var deleteConfirmationPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeaderBlock(
                        eyebrow: "Friends",
                        title: "Public profile",
                        subtitle: "This is how friends find your public link previews in SAVI.",
                        titleSize: 30
                    )

                    SaviTextField(title: "Username", text: $username, prompt: "yourname")
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SaviTextField(title: "Display name", text: $displayName, prompt: "Your name")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                        TextField("Optional", text: $bio, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                            .padding(14)
                            .foregroundStyle(SaviTheme.text)
                            .saviCard(cornerRadius: 16, shadow: false)
                    }

                    PublicProfilePrivacyPanel {
                        deleteConfirmationPresented = true
                    }
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                username = store.publicProfile.username
                displayName = store.publicProfile.displayName
                bio = store.publicProfile.bio
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.updatePublicProfile(username: username, displayName: displayName, bio: bio)
                        dismiss()
                    }
                    .disabled(SaviSocialText.normalizedUsername(username).isEmpty)
                }
            }
            .confirmationDialog("Delete public profile?", isPresented: $deleteConfirmationPresented, titleVisibility: .visible) {
                Button("Delete public profile", role: .destructive) {
                    Task {
                        await store.deletePublicProfile()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This turns off link sharing, removes public Folder flags, and asks iCloud to delete your public profile and shared link previews.")
            }
        }
    }
}

struct PublicProfilePrivacyPanel: View {
    let deleteAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Public Folders publish link metadata only after Apple ID is linked. Files, PDFs, images, notes, local thumbnails, locked Folders, and Private Vault never publish. Friends can report or block public profiles and links.")
                .font(SaviType.ui(.footnote, weight: .semibold))
                .foregroundStyle(SaviTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
                .background(SaviTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button(role: .destructive, action: deleteAction) {
                Label("Delete public profile", systemImage: "trash.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviSecondaryButtonStyle())
        }
    }
}

struct TagFlow: View {
    let tags: [String]

    var body: some View {
        if !displayTags.isEmpty {
            ViewThatFits(in: .horizontal) {
                tagRow(Array(displayTags.prefix(4)))
                tagRow(Array(displayTags.prefix(2)))
                tagRow(Array(displayTags.prefix(1)))
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var displayTags: [String] {
        let generic: Set<String> = [
            "link", "article", "video", "image", "file", "post", "web", "save",
            "twitter", "x", "youtube", "instagram", "tiktok", "reddit", "facebook",
            "device", "clipboard", "text", "note", "friend"
        ]
        let useful = tags.filter { !generic.contains($0.lowercased()) }
        let source = useful.isEmpty ? tags : useful
        return Array(source.prefix(6))
    }

    @ViewBuilder
    private func tagRow(_ visibleTags: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(visibleTags, id: \.self) { tag in
                tagChip("#\(tag)")
            }

            let remaining = max(0, tags.count - visibleTags.count)
            if remaining > 0 {
                tagChip("+\(remaining)", muted: true)
                    .accessibilityLabel("\(remaining) more tags")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tagChip(_ title: String, muted: Bool = false) -> some View {
        Text(title)
            .font(SaviType.ui(.caption2, weight: .black))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(muted ? SaviTheme.surfaceRaised.opacity(0.72) : SaviTheme.surface.opacity(0.72))
            .foregroundStyle(muted ? SaviTheme.textMuted.opacity(0.82) : SaviTheme.textMuted)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(SaviTheme.cardStroke.opacity(0.8), lineWidth: 1))
    }
}

struct StatsPanel: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        HStack(spacing: 10) {
            StatCell(value: "\(store.items.count)", label: "Saves")
            StatCell(value: "\(store.folders.count - 1)", label: "Folders")
            StatCell(value: "\(store.assets.count)", label: "Files")
        }
    }
}

struct StatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(SaviType.display(size: 28, weight: .black))
                .foregroundStyle(SaviTheme.text)
            Text(label)
                .font(SaviType.ui(.caption, weight: .heavy))
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .saviCard(cornerRadius: 16)
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let symbol: String
    let content: Content

    init(title: String, symbol: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbol = symbol
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.accentText)
                    .frame(width: 34, height: 34)
                    .background(SaviTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(title)
                    .font(SaviType.ui(.title3, weight: .black))
                    .foregroundStyle(SaviTheme.text)
            }
            content
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .saviCard(cornerRadius: 18)
    }
}

struct ThemeButton: View {
    let title: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SaviType.ui(.subheadline, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .padding(.horizontal, 10)
                .background(active ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                .foregroundStyle(active ? .black : SaviTheme.text)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(active ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(SaviType.display(size: 38, weight: .black))
                .foregroundStyle(SaviTheme.accentText)
            Text(title)
                .font(SaviType.ui(.headline, weight: .black))
                .foregroundStyle(SaviTheme.text)
            Text(message)
                .font(SaviType.ui(.subheadline))
                .multilineTextAlignment(.center)
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(26)
        .saviCard(cornerRadius: 18)
    }
}

struct SaviCoachOverlay: View {
    let step: SaviCoachStep
    let currentIndex: Int
    let totalCount: Int
    let nextAction: () -> Void
    let skipAction: () -> Void

    private var isLastStep: Bool {
        currentIndex == totalCount
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.34)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: step.symbolName)
                        .font(SaviType.ui(.title3, weight: .black))
                        .frame(width: 46, height: 46)
                        .background(SaviTheme.chartreuse)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(step.eyebrow.uppercased()) · \(currentIndex)/\(totalCount)")
                            .font(SaviType.ui(.caption, weight: .heavy))
                            .foregroundStyle(SaviTheme.accentText)
                        Text(step.title)
                            .font(SaviType.ui(.title3, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Button {
                        skipAction()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.black))
                            .frame(width: 30, height: 30)
                            .background(SaviTheme.surfaceRaised)
                            .foregroundStyle(SaviTheme.textMuted)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Skip tour")
                }

                Text(step.message)
                    .font(SaviType.ui(.callout, weight: .semibold))
                    .foregroundStyle(SaviTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Label(step.targetHint, systemImage: step.hintSymbolName)
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(SaviTheme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                HStack(spacing: 10) {
                    Button {
                        skipAction()
                    } label: {
                        Text("Skip")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SaviSecondaryButtonStyle())

                    Button {
                        nextAction()
                    } label: {
                        Label(isLastStep ? "Done" : "Next", systemImage: isLastStep ? "checkmark" : "arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SaviPrimaryButtonStyle())
                }
            }
            .padding(16)
            .background(SaviTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: SaviTheme.cardShadow.opacity(0.28), radius: 26, x: 0, y: 14)
            .padding(.horizontal, 16)
            .padding(.bottom, 104)
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        ZStack {
            SaviTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                Text("SAVI")
                    .font(SaviType.display(size: 52, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text("Save anything. Find it instantly.")
                    .font(SaviType.ui(.title, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Links, videos, files, notes, screenshots, and more.")
                    .font(SaviType.ui(.callout, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    OnboardingFeatureCard(
                        symbolName: "square.and.arrow.down",
                        title: "Save from anywhere",
                        message: "Use the iOS Share button to send links, photos, PDFs, and videos right into SAVI."
                    )
                    OnboardingFeatureCard(
                        symbolName: "sparkles",
                        title: "Rediscover what you saved",
                        message: "Explore mixes your links, places, videos, and friends' saves into a fresh scroll."
                    )
                    OnboardingFeatureCard(
                        symbolName: "folder.fill",
                        title: "Folders stay organized",
                        message: "Folders are your main categories. Drag them into the order that matters to you."
                    )
                }

                Button {
                    store.openShareSetupGuide()
                } label: {
                    Label("Set up the Share Sheet", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SaviSecondaryButtonStyle())

                Spacer()
                Button {
                    withAnimation { store.finishOnboarding() }
                } label: {
                    Text("Start quick tour")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaviPrimaryButtonStyle())
            }
            .padding(24)
        }
    }
}

struct OnboardingFeatureCard: View {
    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(SaviType.ui(.headline, weight: .black))
                .frame(width: 38, height: 38)
                .background(SaviTheme.surfaceRaised)
                .foregroundStyle(SaviTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text(message)
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(13)
        .saviCard(cornerRadius: 17, shadow: false)
    }
}

struct ShareSetupGuideSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss

    private let steps: [ShareSetupGuideStep] = [
        ShareSetupGuideStep(
            imageName: "share-guide-step-1",
            symbolName: "square.and.arrow.up",
            title: "Tap Share",
            message: "Open Safari, Photos, Files, YouTube, or almost any app, then tap the iOS Share button."
        ),
        ShareSetupGuideStep(
            imageName: "share-guide-step-2",
            symbolName: "ellipsis.circle",
            title: "Find SAVI",
            message: "If SAVI is not in the app row, scroll over and tap More."
        ),
        ShareSetupGuideStep(
            imageName: "share-guide-step-3",
            symbolName: "star.fill",
            title: "Add SAVI to Favorites",
            message: "Tap Edit, add SAVI to Favorites, and move it near the front for one-tap saving."
        ),
        ShareSetupGuideStep(
            imageName: "share-guide-step-4",
            symbolName: "checkmark.circle.fill",
            title: "Save and go",
            message: "Pick SAVI, choose a recent Folder if needed, and it saves immediately. Details can finish later."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeaderBlock(
                        eyebrow: "Share Sheet",
                        title: "Save from anywhere",
                        subtitle: "Pin SAVI in the iOS Share Sheet so links, videos, files, and screenshots land here fast.",
                        titleSize: 34
                    )

                    ShareSetupStatusCard()

                    VStack(spacing: 12) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            ShareSetupGuideStepCard(index: index + 1, step: step)
                        }
                    }

                    Text("iOS does not let SAVI pin itself or check the Share Sheet Favorites list directly. Once you save through the extension, SAVI will know setup worked and stop reminding you.")
                        .font(SaviType.ui(.footnote, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Share Sheet Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ShareSetupStatusCard: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: store.isShareExtensionSetupComplete ? "checkmark.circle.fill" : "square.and.arrow.up")
                .font(SaviType.ui(.title3, weight: .black))
                .frame(width: 46, height: 46)
                .background(store.isShareExtensionSetupComplete ? SaviTheme.chartreuse.opacity(0.24) : SaviTheme.surfaceRaised)
                .foregroundStyle(store.isShareExtensionSetupComplete ? Color.black : SaviTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(store.isShareExtensionSetupComplete ? "Share Sheet is working" : "Not used yet")
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text(store.shareSetupStatusText)
                    .font(SaviType.ui(.subheadline, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .saviCard(cornerRadius: 18, shadow: false)
    }
}

private struct ShareSetupGuideStep: Equatable {
    var imageName: String
    var symbolName: String
    var title: String
    var message: String
}

private struct ShareSetupGuideStepCard: View {
    let index: Int
    let step: ShareSetupGuideStep

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ShareSetupPreviewFrame(step: step)
                .frame(width: 92, height: 128)

            VStack(alignment: .leading, spacing: 7) {
                Text("Step \(index)")
                    .font(SaviType.ui(.caption2, weight: .black))
                    .foregroundStyle(SaviTheme.accentText)
                    .textCase(.uppercase)
                Text(step.title)
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text(step.message)
                    .font(SaviType.ui(.subheadline, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .saviCard(cornerRadius: 18, shadow: false)
    }
}

private struct ShareSetupPreviewFrame: View {
    let step: ShareSetupGuideStep

    var body: some View {
        ZStack {
            if let image = UIImage(named: step.imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SaviTheme.surfaceRaised)
                VStack(spacing: 10) {
                    Image(systemName: step.symbolName)
                        .font(SaviType.ui(.title2, weight: .black))
                        .foregroundStyle(SaviTheme.accentText)
                    Text(step.title)
                        .font(SaviType.ui(.caption2, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                        .multilineTextAlignment(.center)
                }
                .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
    }
}

struct ShareSetupReminderOverlay: View {
    @EnvironmentObject private var store: SaviStore

    private var showsDontRemind: Bool {
        store.prefs.shareSetupReminderCount >= 3
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()
                .onTapGesture { store.snoozeShareSetupReminder() }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(SaviType.ui(.title2, weight: .black))
                        .frame(width: 50, height: 50)
                        .background(SaviTheme.chartreuse)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Save from anywhere")
                            .font(SaviType.display(size: 25, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                        Text("You have not saved through the iOS Share Sheet yet. Pin SAVI there and your links, videos, files, and screenshots can land here in one tap.")
                            .font(SaviType.ui(.subheadline, weight: .semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Button {
                    store.openShareSetupGuide()
                } label: {
                    Label("Show me how", systemImage: "sparkles")
                }
                .buttonStyle(SaviPrimaryButtonStyle())

                Button {
                    store.snoozeShareSetupReminder()
                } label: {
                    Text("Remind me later")
                }
                .buttonStyle(SaviSecondaryButtonStyle())

                if showsDontRemind {
                    Button {
                        store.disableShareSetupReminders()
                    } label: {
                        Text("Don’t remind me again")
                            .font(SaviType.ui(.subheadline, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .foregroundStyle(SaviTheme.textMuted)
                }
            }
            .padding(18)
            .background(SaviTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: SaviTheme.cardShadow.opacity(0.25), radius: 26, x: 0, y: 14)
            .padding(.horizontal, 18)
            .padding(.bottom, 104)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(SaviType.ui(.subheadline, weight: .bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 14)
            .padding(.horizontal, 18)
    }
}

struct SaviPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaviType.ui(.headline, weight: .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(SaviTheme.chartreuse.opacity(configuration.isPressed ? 0.75 : 1))
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SaviSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaviType.ui(.headline, weight: .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(SaviTheme.surfaceRaised.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(SaviTheme.text)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
    }
}

struct SaviDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaviType.ui(.headline, weight: .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.red.opacity(configuration.isPressed ? 0.22 : 0.16))
            .foregroundStyle(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
    }
}

struct SaviType {
    static func display(size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func ui(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    static func reading(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default).weight(weight)
    }
}

enum SaviSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum SaviRadius {
    static let control: CGFloat = 14
    static let card: CGFloat = 18
    static let thumbnail: CGFloat = 14
    static let folder: CGFloat = 18
    static let bottomTab: CGFloat = 14
}

enum SaviShadow {
    static func cardOpacity(_ colorScheme: ColorScheme) -> Double {
        colorScheme == .dark ? 0.07 : 0.10
    }

    static func cardRadius(_ colorScheme: ColorScheme) -> CGFloat {
        colorScheme == .dark ? 12 : 16
    }

    static func cardY(_ colorScheme: ColorScheme) -> CGFloat {
        colorScheme == .dark ? 5 : 7
    }

    static func folderRadius(_ colorScheme: ColorScheme) -> CGFloat {
        colorScheme == .dark ? 7 : 12
    }

    static func folderY(_ colorScheme: ColorScheme) -> CGFloat {
        colorScheme == .dark ? 3 : 6
    }
}

struct SaviPressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

struct PillBadge: View {
    let title: String
    var systemImage: String?
    var foreground: Color = SaviTheme.textMuted
    var background: Color = SaviTheme.subtleSurface
    var stroke: Color = SaviTheme.cardStroke
    var height: CGFloat = 28

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(SaviType.ui(.caption2, weight: .black))
                    .accessibilityHidden(true)
            }
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .font(SaviType.ui(.caption, weight: .bold))
        .foregroundStyle(foreground)
        .padding(.horizontal, 10)
        .frame(height: height)
        .background(background)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(stroke.opacity(0.82), lineWidth: 1))
    }
}

struct FilterChip: View {
    let title: String
    var systemImage: String?
    var count: Int?
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(SaviType.ui(.caption, weight: .black))
                        .accessibilityHidden(true)
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                if let count {
                    Text("\(count)")
                        .font(SaviType.ui(.caption2, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(active ? Color.black.opacity(0.10) : SaviTheme.surfaceRaised)
                        .clipShape(Capsule())
                }
            }
            .font(SaviType.ui(.caption, weight: .bold))
            .padding(.horizontal, 12)
            .frame(minHeight: 38)
            .background(active ? SaviTheme.softAccent : SaviTheme.surface)
            .foregroundStyle(active ? .black : SaviTheme.text)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(active ? Color.clear : SaviTheme.cardStroke.opacity(0.86), lineWidth: 1))
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel(title)
    }
}

extension View {
    @ViewBuilder
    func saviRoundedFontDesign() -> some View {
        if #available(iOS 16.1, *) {
            self.fontDesign(.rounded)
        } else {
            self
        }
    }
}

struct SaviTheme {
    static let background = adaptive(dark: "#100B1C", light: "#F6F2FA")
    static let surface = adaptive(dark: "#1C1530", light: "#FFFFFF")
    static let surfaceRaised = adaptive(dark: "#2A2144", light: "#ECE5F4")
    static let subtleSurface = adaptive(dark: "#231A3A", light: "#F0EAF7")
    static let inputSurface = adaptive(dark: "#211735", light: "#FFFFFF")
    static let text = adaptive(dark: "#F5F0FF", light: "#160F22")
    static let textMuted = adaptive(dark: "#B7A9D6", light: "#51475E")
    static let metadataText = adaptive(dark: "#A99BCC", light: "#766986")
    static let chartreuse = adaptive(dark: "#D8FF3C", light: "#9BD80F")
    static let softAccent = adaptive(dark: "#D8FF3C", light: "#DDF6A1")
    static let accentText = adaptive(dark: "#D8FF3C", light: "#4F246F")
    static let cardStroke = adaptive(dark: "#2F244C", light: "#C9BDD8")
    static let folderCardStroke = adaptive(dark: "#40315F", light: "#BDA9CF")
    static let cardShadow = adaptive(dark: "#000000", light: "#5E4A73")

    private static func adaptive(dark: String, light: String) -> Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    static func foreground(onHex hex: String) -> Color {
        Color(UIColor(hex: hex).saviUsesLightForeground ? UIColor.white : UIColor.black)
    }
}

struct SaviFolderVisualStyle {
    let baseHex: String
    let base: Color
    let text: Color
    let secondaryText: Color
    let titleShadow: Color
    let titleShadowRadius: CGFloat
    let iconBackground: Color
    let iconForeground: Color
    let countBackground: Color
    let countForeground: Color
    let stroke: Color
    let shadow: Color
    let pillBackground: Color
    let pillForeground: Color
    let pillStroke: Color
    let backgroundColors: [Color]

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func make(for folder: SaviFolder, colorScheme: ColorScheme) -> SaviFolderVisualStyle {
        let hex = preferredHex(for: folder)
        let base = Color(hex: hex)
        let usesLightText = usesLightForeground(for: folder, baseHex: hex, colorScheme: colorScheme)
        let usesImageBackground = folder.usesImageBackground && folder.image?.nilIfBlank != nil
        let ink = Color(hex: "#342448")
        let paper = Color(hex: "#FFF9FF")

        if colorScheme == .light {
            if folder.id == "f-private-vault" {
                return SaviFolderVisualStyle(
                    baseHex: hex,
                    base: base,
                    text: Color(hex: "#F7F2FF"),
                    secondaryText: Color(hex: "#D7C9F4").opacity(0.78),
                    titleShadow: Color.black.opacity(0.24),
                    titleShadowRadius: 1,
                    iconBackground: Color.white.opacity(0.13),
                    iconForeground: Color(hex: "#D8FF3C"),
                    countBackground: Color.white.opacity(0.16),
                    countForeground: Color(hex: "#F7F2FF"),
                    stroke: Color(hex: "#5E45A1").opacity(0.52),
                    shadow: Color(hex: "#12091F").opacity(0.22),
                    pillBackground: Color(hex: "#2C1F45"),
                    pillForeground: Color(hex: "#F7F2FF"),
                    pillStroke: Color(hex: "#D8FF3C").opacity(0.30),
                    backgroundColors: [Color(hex: "#130A21"), Color(hex: "#31214D")]
                )
            }

            if usesImageBackground {
                return SaviFolderVisualStyle(
                    baseHex: hex,
                    base: base,
                    text: paper,
                    secondaryText: paper.opacity(0.76),
                    titleShadow: Color.black.opacity(0.34),
                    titleShadowRadius: 2,
                    iconBackground: Color.black.opacity(0.18),
                    iconForeground: paper.opacity(0.90),
                    countBackground: Color.black.opacity(0.18),
                    countForeground: paper,
                    stroke: Color.white.opacity(0.22),
                    shadow: Color(hex: "#5E4A73").opacity(0.14),
                    pillBackground: Color.black.opacity(0.20),
                    pillForeground: paper,
                    pillStroke: Color.white.opacity(0.20),
                    backgroundColors: lightBackgroundColors(for: folder.id, baseHex: hex)
                )
            }

            let text = usesLightText ? paper : ink
            let controlForeground = usesLightText ? paper : ink
            return SaviFolderVisualStyle(
                baseHex: hex,
                base: base,
                text: text,
                secondaryText: text.opacity(usesLightText ? 0.72 : 0.58),
                titleShadow: usesLightText ? Color.black.opacity(0.20) : Color.clear,
                titleShadowRadius: usesLightText ? 1 : 0,
                iconBackground: usesLightText ? paper.opacity(0.12) : paper.opacity(0.28),
                iconForeground: controlForeground.opacity(usesLightText ? 0.72 : 0.58),
                countBackground: usesLightText ? paper.opacity(0.22) : paper.opacity(0.66),
                countForeground: controlForeground,
                stroke: usesLightText ? paper.opacity(0.20) : paper.opacity(0.28),
                shadow: base.opacity(usesLightText ? 0.14 : 0.10),
                pillBackground: SaviTheme.subtleSurface.opacity(0.42),
                pillForeground: SaviTheme.metadataText,
                pillStroke: SaviTheme.cardStroke.opacity(0.40),
                backgroundColors: lightBackgroundColors(for: folder.id, baseHex: hex)
            )
        }

        if folder.id == "f-private-vault" {
            return SaviFolderVisualStyle(
                baseHex: hex,
                base: base,
                text: Color(hex: "#FFF9FF"),
                secondaryText: Color(hex: "#DED4F8").opacity(0.88),
                titleShadow: Color.black.opacity(0.28),
                titleShadowRadius: 1,
                iconBackground: Color.white.opacity(0.16),
                iconForeground: Color(hex: "#D8FF3C"),
                countBackground: Color.white.opacity(0.16),
                countForeground: Color(hex: "#FFF9FF"),
                stroke: Color.white.opacity(0.14),
                shadow: Color.black.opacity(0.24),
                pillBackground: Color(hex: "#2C1F45"),
                pillForeground: Color(hex: "#FFF9FF"),
                pillStroke: Color(hex: "#D8FF3C").opacity(0.28),
                backgroundColors: [Color(hex: "#2A1745"), Color(hex: "#12091F")]
            )
        }

        if usesImageBackground {
            return SaviFolderVisualStyle(
                baseHex: hex,
                base: base,
                text: Color(hex: "#FFF9FF"),
                secondaryText: Color(hex: "#E8DFFC").opacity(0.82),
                titleShadow: Color.black.opacity(0.42),
                titleShadowRadius: 2,
                iconBackground: Color.black.opacity(0.24),
                iconForeground: Color(hex: "#FFF9FF").opacity(0.92),
                countBackground: Color.black.opacity(0.24),
                countForeground: Color(hex: "#FFF9FF"),
                stroke: Color.white.opacity(0.16),
                shadow: Color.black.opacity(0.18),
                pillBackground: Color.black.opacity(0.26),
                pillForeground: Color(hex: "#FFF9FF"),
                pillStroke: Color.white.opacity(0.18),
                backgroundColors: darkBackgroundColors(baseHex: hex)
            )
        }

        return SaviFolderVisualStyle(
            baseHex: hex,
            base: base,
            text: Color(hex: "#FFF9FF"),
            secondaryText: Color(hex: "#D9D0EF").opacity(0.84),
            titleShadow: Color.black.opacity(0.25),
            titleShadowRadius: 1,
            iconBackground: Color.white.opacity(0.11),
            iconForeground: Color(hex: "#FFF9FF").opacity(0.86),
            countBackground: Color.white.opacity(0.15),
            countForeground: Color(hex: "#FFF9FF"),
            stroke: Color.white.opacity(0.10),
            shadow: Color.black.opacity(0.16),
            pillBackground: SaviTheme.subtleSurface.opacity(0.56),
            pillForeground: Color(hex: "#D9D0EF"),
            pillStroke: base.opacity(0.32),
            backgroundColors: darkBackgroundColors(baseHex: hex)
        )
    }

    static func preferredHex(for folder: SaviFolder) -> String {
        let savedHex = folder.color.nilIfBlank

        if let savedHex,
           legacyStoredDefaultHexes(for: folder.id).contains(where: { savedHex.caseInsensitiveCompare($0) == .orderedSame }),
           let displayHex = defaultDisplayHex(for: folder.id) {
            return displayHex
        }

        return savedHex ?? defaultDisplayHex(for: folder.id) ?? "#C4B5FD"
    }

    private static func usesLightForeground(for folder: SaviFolder, baseHex hex: String, colorScheme: ColorScheme) -> Bool {
        if colorScheme == .dark { return true }

        if isDefaultDisplayColor(folderId: folder.id, hex: hex) {
            switch folder.id {
            case "f-must-see", "f-private-vault", "f-tinfoil":
                return true
            case "f-paste-bin", "f-wtf-favorites", "f-growth", "f-lmao", "f-travel", "f-recipes", "f-health", "f-design", "f-research", "f-random", "f-all":
                return false
            default:
                break
            }
        }

        return prefersLightForeground(onHex: hex)
    }

    private static func defaultDisplayHex(for folderId: String) -> String? {
        switch folderId {
        case "f-must-see": return "#7A35E8"
        case "f-paste-bin": return "#9286A8"
        case "f-wtf-favorites": return "#73CDED"
        case "f-growth": return "#F47A3B"
        case "f-lmao": return "#D6F83A"
        case "f-private-vault": return "#171026"
        case "f-travel": return "#68C6E8"
        case "f-recipes": return "#FFB978"
        case "f-health": return "#70D59B"
        case "f-design": return "#DE5B98"
        case "f-research": return "#5ADDCB"
        case "f-tinfoil": return "#7B3FE4"
        case "f-random": return "#FFE16A"
        case "f-all": return "#D6F83A"
        default: return nil
        }
    }

    private static func legacyStoredDefaultHexes(for folderId: String) -> [String] {
        switch folderId {
        case "f-must-see": return ["#6D28D9", "#4C1D95"]
        case "f-paste-bin": return ["#8A7CA8"]
        case "f-wtf-favorites": return ["#7DD3FC", "#C4B5FD"]
        case "f-growth": return ["#FF8A3D", "#9F7AEA", "#A78BFA"]
        case "f-lmao": return ["#D8FF3C", "#FFE066"]
        case "f-private-vault": return ["#12091F", "#0A0614"]
        case "f-travel": return ["#66C7F4", "#B8D4F5"]
        case "f-recipes": return ["#FFB36B", "#F4C6A5"]
        case "f-health": return ["#74D99F", "#C4E8D4"]
        case "f-design": return ["#FF8BB5", "#E8DCF5"]
        case "f-research": return ["#5EEAD4", "#DDD1F3"]
        case "f-tinfoil": return ["#7C3AED", "#6D28D9"]
        case "f-random": return ["#FFE066"]
        case "f-all": return ["#D8FF3C"]
        default: return []
        }
    }

    private static func isDefaultDisplayColor(folderId: String, hex: String) -> Bool {
        guard let defaultHex = defaultDisplayHex(for: folderId) else { return false }
        return defaultHex.caseInsensitiveCompare(hex) == .orderedSame
    }

    private static func prefersLightForeground(onHex hex: String) -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard UIColor(hex: hex).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return UIColor(hex: hex).saviUsesLightForeground
        }

        func linearized(_ component: CGFloat) -> CGFloat {
            component <= 0.03928
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }

        let luminance = 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
        let whiteContrast = (1.05) / (luminance + 0.05)
        let blackContrast = (luminance + 0.05) / 0.05
        return whiteContrast > blackContrast
    }

    private static func lightBackgroundColors(for folderId: String, baseHex hex: String) -> [Color] {
        if isDefaultDisplayColor(folderId: folderId, hex: hex) {
            switch folderId {
            case "f-must-see":
                return lightFolderPair("#803DE8", "#7132DA", amount: 0.84)
            case "f-paste-bin":
                return lightFolderPair("#A095B0", "#897E9D", amount: 0.80)
            case "f-wtf-favorites":
                return lightFolderPair("#7BD0EE", "#64C3E5", amount: 0.84)
            case "f-growth":
                return lightFolderPair("#F47A3B", "#E66931", amount: 0.84)
            case "f-lmao":
                return lightFolderPair("#D8FA42", "#CFF338", amount: 0.76)
            case "f-travel":
                return lightFolderPair("#75CAE9", "#60BFE2", amount: 0.82)
            case "f-recipes":
                return lightFolderPair("#FFC181", "#FFB06D", amount: 0.80)
            case "f-health":
                return lightFolderPair("#7BDD9F", "#64D092", amount: 0.80)
            case "f-design":
                return lightFolderPair("#E56AA1", "#D6508E", amount: 0.82)
            case "f-research":
                return lightFolderPair("#65E2D0", "#4FD2C0", amount: 0.80)
            case "f-tinfoil":
                return lightFolderPair("#8650E9", "#7138D9", amount: 0.84)
            case "f-random":
                return lightFolderPair("#FFE677", "#FFD95E", amount: 0.74)
            case "f-all":
                return lightFolderPair("#D8FA42", "#CFF338", amount: 0.76)
            default:
                break
            }
        }

        return lightFolderPair(hex, hex, amount: 0.86)
    }

    private static func darkBackgroundColors(baseHex hex: String) -> [Color] {
        [
            blendedFolderColor(hex: hex, with: "#12091F", amount: 0.52),
            blendedFolderColor(hex: hex, with: "#12091F", amount: 0.30)
        ]
    }

    private static func blendedFolderColor(hex: String, with backgroundHex: String, amount: CGFloat) -> Color {
        var baseRed: CGFloat = 0
        var baseGreen: CGFloat = 0
        var baseBlue: CGFloat = 0
        var baseAlpha: CGFloat = 0
        var backgroundRed: CGFloat = 0
        var backgroundGreen: CGFloat = 0
        var backgroundBlue: CGFloat = 0
        var backgroundAlpha: CGFloat = 0

        guard
            UIColor(hex: hex).getRed(&baseRed, green: &baseGreen, blue: &baseBlue, alpha: &baseAlpha),
            UIColor(hex: backgroundHex).getRed(&backgroundRed, green: &backgroundGreen, blue: &backgroundBlue, alpha: &backgroundAlpha)
        else {
            return Color(hex: hex)
        }

        let clampedAmount = min(max(amount, 0), 1)
        return Color(UIColor(
            red: backgroundRed + (baseRed - backgroundRed) * clampedAmount,
            green: backgroundGreen + (baseGreen - backgroundGreen) * clampedAmount,
            blue: backgroundBlue + (baseBlue - backgroundBlue) * clampedAmount,
            alpha: 1
        ))
    }

    private static func lightFolderPair(_ firstHex: String, _ secondHex: String, amount: CGFloat) -> [Color] {
        [
            blendedFolderColor(hex: firstHex, with: "#F8F2FC", amount: amount),
            blendedFolderColor(hex: secondHex, with: "#F3ECF9", amount: min(max(amount - 0.02, 0), 1))
        ]
    }
}

struct FolderTileBackground: View {
    let folder: SaviFolder
    let style: SaviFolderVisualStyle

    private var customImage: UIImage? {
        guard folder.usesImageBackground,
              let imageDataURL = folder.image?.nilIfBlank
        else { return nil }
        return SaviText.imageFromDataURL(imageDataURL)
    }

    var body: some View {
        ZStack {
            style.backgroundGradient

            if let customImage {
                Image(uiImage: customImage)
                    .resizable()
                    .scaledToFill()
                    .overlay(imageReadabilityOverlay)
            }
        }
        .clipped()
    }

    private var imageReadabilityOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.48)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    style.base.opacity(0.10),
                    Color.black.opacity(0.18)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }
}

enum SaviFolderTileMetrics {
    static let gridSpacing: CGFloat = 10
    static let tileHeight: CGFloat = 104
    static let padding: CGFloat = 11
    static let titleSize: CGFloat = 17
    static let iconSize: CGFloat = 30
    static let iconCornerRadius: CGFloat = 10
    static var iconFont: Font { SaviType.ui(.caption, weight: .black) }
}

enum SaviFolderNameFormatter {
    static func balanced(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains(" / ") {
            return trimmed.replacingOccurrences(of: " / ", with: " /\n")
        }
        if trimmed.contains(" & ") {
            return trimmed.replacingOccurrences(of: " & ", with: " &\n")
        }
        guard trimmed.count > 13 else { return trimmed }

        let words = trimmed.split(separator: " ").map(String.init)
        guard words.count > 1 else { return trimmed }

        let target = trimmed.count / 2
        var bestIndex = 1
        var bestDistance = Int.max

        for index in 1..<words.count {
            let firstLineLength = words[..<index].joined(separator: " ").count
            let distance = abs(firstLineLength - target)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }

        return words[..<bestIndex].joined(separator: " ") + "\n" + words[bestIndex...].joined(separator: " ")
    }
}

struct FolderCountLabel: View {
    let text: String
    let style: SaviFolderVisualStyle

    var body: some View {
        Text(text)
            .font(SaviType.reading(.caption2, weight: .regular))
            .foregroundStyle(style.secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .accessibilityLabel(text)
    }
}

struct PublicFolderBadge: View {
    let style: SaviFolderVisualStyle?
    var showsText = false

    init(style: SaviFolderVisualStyle? = nil, showsText: Bool = false) {
        self.style = style
        self.showsText = showsText
    }

    var body: some View {
        HStack(spacing: showsText ? 4 : 0) {
            Image(systemName: "person.2.fill")
                .font(.system(size: showsText ? 10 : 9, weight: .black))
            if showsText {
                Text("Public")
                    .font(SaviType.ui(.caption2, weight: .black))
            }
        }
        .lineLimit(1)
        .padding(.horizontal, showsText ? 7 : 0)
        .frame(width: showsText ? nil : 22, height: 22)
        .background(style?.countBackground.opacity(0.92) ?? SaviTheme.softAccent.opacity(0.72))
        .foregroundStyle(style?.countForeground ?? SaviTheme.accentText)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(style?.stroke.opacity(0.62) ?? SaviTheme.cardStroke.opacity(0.72), lineWidth: 1)
        )
        .accessibilityLabel("Public Folder")
    }
}

struct SaviCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat
    let shadow: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(SaviTheme.surface)
            .clipShape(shape)
            .overlay(shape.stroke(SaviTheme.cardStroke.opacity(colorScheme == .dark ? 0.92 : 0.78), lineWidth: 1))
            .shadow(
                color: shadow ? SaviTheme.cardShadow.opacity(SaviShadow.cardOpacity(colorScheme)) : Color.clear,
                radius: shadow ? SaviShadow.cardRadius(colorScheme) : 0,
                x: 0,
                y: shadow ? SaviShadow.cardY(colorScheme) : 0
            )
    }
}

extension View {
    func saviCard(cornerRadius: CGFloat = 18, shadow: Bool = true) -> some View {
        modifier(SaviCardModifier(cornerRadius: cornerRadius, shadow: shadow))
    }
}

// MARK: - Legacy Migration Host
