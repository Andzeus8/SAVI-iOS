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

struct SocialDisabledSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HeaderBlock(
                    eyebrow: "TestFlight",
                    title: "Social is coming",
                    subtitle: "This beta focuses on private saving, folders, search, Explore, locks, and full archive backup. Friend feeds and public publishing are in progress.",
                    titleSize: 32
                )

                VStack(alignment: .leading, spacing: 10) {
                    Label("No friend feed in this build", systemImage: "person.2.slash.fill")
                    Label("No public publishing yet", systemImage: "icloud.slash.fill")
                    Label("Your saved files stay private", systemImage: "lock.shield.fill")
                }
                .font(SaviType.ui(.subheadline, weight: .black))
                .foregroundStyle(SaviTheme.text)
                .padding(14)
                .saviCard(cornerRadius: 18, shadow: false)

                Spacer()
            }
            .padding(18)
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Coming soon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

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
    @Environment(\.colorScheme) private var colorScheme
    @State private var pageIndex = 0

    private let pages = OnboardingPage.pages

    private var isLastPage: Bool {
        pageIndex == pages.count - 1
    }

    var body: some View {
        ZStack {
            SaviTheme.background
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    SaviTheme.chartreuse.opacity(colorScheme == .dark ? 0.16 : 0.28),
                    SaviTheme.background.opacity(colorScheme == .dark ? 0.82 : 0.72),
                    SaviTheme.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                TabView(selection: $pageIndex) {
                    ForEach(pages) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.34, dampingFraction: 0.86), value: pageIndex)

                OnboardingPageDots(count: pages.count, currentIndex: pageIndex)

                VStack(spacing: 10) {
                    Button {
                        if isLastPage {
                            withAnimation { store.finishOnboarding(startTour: false) }
                        } else {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                pageIndex = min(pageIndex + 1, pages.count - 1)
                            }
                        }
                    } label: {
                        Label(isLastPage ? "Start using SAVI" : "Next", systemImage: isLastPage ? "checkmark" : "arrow.right")
                            .lineLimit(1)
                            .minimumScaleFactor(0.86)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SaviPrimaryButtonStyle())

                    Button {
                        withAnimation {
                            if isLastPage {
                                store.finishOnboardingAndOpenShareSetupGuide()
                            } else {
                                store.finishOnboarding(startTour: false)
                            }
                        }
                    } label: {
                        Text(isLastPage ? "Try Share Sheet setup" : "Start using SAVI")
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SaviSecondaryButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 22)
            .onAppear {
                pageIndex = 0
            }
        }
    }
}

private struct OnboardingPage: Identifiable {
    let id: Int
    let eyebrow: String
    let title: String
    let message: String
    let symbolName: String
    let accent: Color
    let visual: OnboardingVisualKind

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            eyebrow: "Welcome to SAVI",
            title: "Save it now. Find it later.",
            message: "SAVI keeps the links, videos, screenshots, files, notes, and little finds you do not want to lose.",
            symbolName: "tray.and.arrow.down.fill",
            accent: SaviTheme.chartreuse,
            visual: .library
        ),
        OnboardingPage(
            id: 1,
            eyebrow: "One library",
            title: "One place for favorites.",
            message: "Bookmarks, recipes, recommendations, posts, PDFs, screenshots, and ideas can finally live together.",
            symbolName: "square.stack.3d.up.fill",
            accent: Color(hex: "#7EC8FF"),
            visual: .everything
        ),
        OnboardingPage(
            id: 2,
            eyebrow: "Browse and search",
            title: "Browse what you love.",
            message: "Explore turns your saved favorites into a fun mix. Later, friends can curate favorites for each other.",
            symbolName: "sparkles",
            accent: Color(hex: "#FFDA6B"),
            visual: .explore
        ),
        OnboardingPage(
            id: 3,
            eyebrow: "Save from anywhere",
            title: "Save from any app.",
            message: "Pin SAVI in the iOS Share Sheet once. Then saving from Safari, YouTube, Photos, Files, and Messages is quick.",
            symbolName: "square.and.arrow.up.fill",
            accent: SaviTheme.chartreuse,
            visual: .share
        )
    ]
}

private enum OnboardingVisualKind {
    case library
    case everything
    case explore
    case search
    case share
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: page.symbolName)
                        .font(SaviType.ui(.title3, weight: .black))
                        .frame(width: 50, height: 50)
                        .background(page.accent)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(page.eyebrow.uppercased())
                            .font(SaviType.ui(.caption2, weight: .black))
                            .foregroundStyle(SaviTheme.accentText)
                        Text("SAVI")
                            .font(SaviType.ui(.headline, weight: .black))
                            .foregroundStyle(SaviTheme.textMuted)
                    }
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(page.title)
                        .font(SaviType.display(size: 39, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(page.message)
                        .font(SaviType.ui(.title3, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                OnboardingVisual(kind: page.visual, accent: page.accent)
                    .frame(height: page.visual == .share ? 300 : 282)
                    .padding(.top, 4)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(SaviTheme.surface.opacity(colorScheme == .dark ? 0.62 : 0.84))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.52), lineWidth: 1)
            )
            .shadow(color: SaviTheme.cardShadow.opacity(colorScheme == .dark ? 0.38 : 0.16), radius: 30, x: 0, y: 18)
            .padding(.vertical, 8)
        }
    }
}

private struct OnboardingVisual: View {
    let kind: OnboardingVisualKind
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            SaviTheme.surfaceRaised.opacity(0.96),
                            SaviTheme.surface.opacity(0.66)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            switch kind {
            case .library:
                VStack(spacing: 10) {
                    OnboardingMockCard(symbolName: "play.rectangle.fill", title: "YouTube travel tip", subtitle: "#travel  #later", accent: accent)
                    OnboardingMockCard(symbolName: "doc.richtext.fill", title: "Warranty PDF", subtitle: "#home  #important", accent: Color(hex: "#7EC8FF"))
                    OnboardingMockCard(symbolName: "camera.fill", title: "Recipe screenshot", subtitle: "#dinner  #family", accent: Color(hex: "#FFDA6B"))
                }
                .padding(16)
            case .everything:
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        OnboardingBubble(title: "Links", symbolName: "link", accent: accent)
                        OnboardingBubble(title: "Photos", symbolName: "photo.fill", accent: Color(hex: "#FF8AA3"))
                    }
                    HStack(spacing: 10) {
                        OnboardingBubble(title: "PDFs", symbolName: "doc.fill", accent: Color(hex: "#7EC8FF"))
                        OnboardingBubble(title: "Notes", symbolName: "text.alignleft", accent: Color(hex: "#FFDA6B"))
                    }
                    HStack(spacing: 10) {
                        OnboardingBubble(title: "Videos", symbolName: "play.fill", accent: Color(hex: "#8A5CFF"))
                        OnboardingBubble(title: "Ideas", symbolName: "sparkles", accent: SaviTheme.chartreuse)
                    }
                }
                .padding(16)
            case .search:
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 9) {
                        Image(systemName: "magnifyingglass")
                            .font(SaviType.ui(.headline, weight: .black))
                            .foregroundStyle(SaviTheme.textMuted)
                        Text("door code")
                            .font(SaviType.ui(.headline, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(SaviTheme.background.opacity(0.64))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    OnboardingMockCard(symbolName: "key.fill", title: "Airbnb door code", subtitle: "Photos · Travel", accent: accent)
                    OnboardingMockCard(symbolName: "folder.fill", title: "Travel folder", subtitle: "8 saved things", accent: Color(hex: "#7EC8FF"))
                }
                .padding(16)
            case .explore:
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        OnboardingBubble(title: "Links", symbolName: "link", accent: Color(hex: "#7EC8FF"))
                        OnboardingBubble(title: "Videos", symbolName: "play.fill", accent: accent)
                    }
                    OnboardingMockCard(symbolName: "sparkles", title: "Tonight's favorites", subtitle: "Explore · Fresh mix", accent: accent)
                    OnboardingMockCard(symbolName: "person.2.fill", title: "Friends' favorites", subtitle: "Curated by friends · Later", accent: Color(hex: "#FF8AA3"))
                }
                .padding(16)
            case .share:
                OnboardingShareScreenshotStack()
                    .padding(16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
    }
}

private struct OnboardingMockCard: View {
    let symbolName: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbolName)
                .font(SaviType.ui(.headline, weight: .black))
                .frame(width: 42, height: 42)
                .background(accent)
                .foregroundStyle(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(subtitle)
                    .font(SaviType.ui(.caption, weight: .bold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(SaviTheme.background.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
    }
}

private struct OnboardingBubble: View {
    let title: String
    let symbolName: String
    let accent: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(SaviType.ui(.caption, weight: .black))
                .frame(width: 28, height: 28)
                .background(accent)
                .foregroundStyle(Color.black)
                .clipShape(Circle())
            Text(title)
                .font(SaviType.ui(.headline, weight: .black))
                .foregroundStyle(SaviTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity)
        .background(SaviTheme.background.opacity(0.48))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct OnboardingShareScreenshotStack: View {
    private let images = [
        "share-setup-step-share",
        "share-setup-step-more",
        "share-setup-step-favorite"
    ]

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: -max(42, proxy.size.width * 0.14)) {
                ForEach(Array(images.enumerated()), id: \.element) { index, imageName in
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width * 0.43, height: proxy.size.height * 0.92)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.62), lineWidth: 1)
                        )
                        .shadow(color: SaviTheme.cardShadow.opacity(0.18), radius: 12, x: 0, y: 8)
                        .rotationEffect(.degrees(index == 0 ? -5 : index == 2 ? 5 : 0))
                        .zIndex(index == 1 ? 2 : 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct OnboardingPageDots: View {
    let count: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? SaviTheme.chartreuse : SaviTheme.textMuted.opacity(0.26))
                    .frame(width: index == currentIndex ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.28, dampingFraction: 0.86), value: currentIndex)
            }
        }
        .accessibilityLabel("Onboarding page \(currentIndex + 1) of \(count)")
    }
}

struct SaviTabTipOverlay: View {
    let tip: SaviTabTip
    let dismissAction: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.20)
                .ignoresSafeArea()
                .onTapGesture { dismissAction() }

            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: tip.symbolName)
                        .font(SaviType.ui(.title3, weight: .black))
                        .frame(width: 46, height: 46)
                        .background(SaviTheme.chartreuse)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.eyebrow.uppercased())
                            .font(SaviType.ui(.caption2, weight: .black))
                            .foregroundStyle(SaviTheme.accentText)
                        Text(tip.title)
                            .font(SaviType.ui(.title3, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Button {
                        dismissAction()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.black))
                            .frame(width: 30, height: 30)
                            .background(SaviTheme.surfaceRaised)
                            .foregroundStyle(SaviTheme.textMuted)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss tip")
                }

                Text(tip.message)
                    .font(SaviType.ui(.callout, weight: .semibold))
                    .foregroundStyle(SaviTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    dismissAction()
                } label: {
                    Text("Got it")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaviPrimaryButtonStyle())
            }
            .padding(16)
            .background(SaviTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: SaviTheme.cardShadow.opacity(0.24), radius: 24, x: 0, y: 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 104)
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
                .font(SaviType.ui(.subheadline, weight: .black))
                .frame(width: 34, height: 34)
                .background(SaviTheme.surfaceRaised.opacity(0.82))
                .foregroundStyle(SaviTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text(message)
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(11)
        .background(SaviTheme.surfaceRaised.opacity(0.50))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
    }
}

private struct OnboardingPreviewStrip: View {
    private let chips: [(String, String, Color)] = [
        ("Share", "square.and.arrow.up.fill", SaviTheme.chartreuse),
        ("Search", "magnifyingglass", Color(hex: "#6D7CFF")),
        ("Folders", "folder.fill", Color(hex: "#8A5CFF"))
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(chips, id: \.0) { chip in
                HStack(spacing: 6) {
                    Circle()
                        .fill(chip.2)
                        .frame(width: 9, height: 9)
                    Image(systemName: chip.1)
                        .font(SaviType.ui(.caption2, weight: .black))
                    Text(chip.0)
                        .font(SaviType.ui(.caption2, weight: .black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .foregroundStyle(SaviTheme.text)
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(SaviTheme.surfaceRaised.opacity(0.56))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(SaviTheme.cardStroke, lineWidth: 1)
                )
            }
        }
    }
}

private struct ShareSetupAnimatedDemo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = 0

    private let phaseLabels = [
        "Link",
        "Share",
        "More",
        "Pin SAVI"
    ]

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            SaviTheme.surfaceRaised.opacity(0.92),
                            SaviTheme.surface.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 10) {
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color.red.opacity(0.65)).frame(width: 8, height: 8)
                        Circle().fill(Color.yellow.opacity(0.75)).frame(width: 8, height: 8)
                        Circle().fill(Color.green.opacity(0.70)).frame(width: 8, height: 8)
                    }
                    Spacer()
                    Text("Safari")
                        .font(SaviType.ui(.caption2, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(SaviType.ui(.caption2, weight: .bold))
                        .foregroundStyle(SaviTheme.textMuted)
                }

                VStack(alignment: .leading, spacing: 7) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(SaviTheme.text.opacity(0.18))
                        .frame(width: 122, height: 12)
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(SaviTheme.textMuted.opacity(0.16))
                        .frame(height: 9)
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(SaviTheme.textMuted.opacity(0.13))
                        .frame(width: 182, height: 9)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(SaviTheme.background.opacity(0.34))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack {
                    ShareSetupDemoToolbarButton(symbolName: "chevron.left")
                    ShareSetupDemoToolbarButton(symbolName: "chevron.right")
                    Spacer()
                    ShareSetupDemoToolbarButton(symbolName: "square.and.arrow.up", active: phase >= 1)
                    Spacer()
                    ShareSetupDemoToolbarButton(symbolName: "book")
                    ShareSetupDemoToolbarButton(symbolName: "square.on.square")
                }
                .padding(.top, 2)
            }
            .padding(15)

            ShareSetupDemoSheet(phase: phase)
                .padding(.horizontal, 14)
                .offset(y: phase >= 1 ? 78 : 130)
                .opacity(phase >= 1 ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.86), value: phase)

            if !SaviPerformancePolicy.current.usesStaticShareSetupDemo {
                VStack {
                    HStack {
                        ForEach(Array(phaseLabels.enumerated()), id: \.offset) { index, label in
                            Text(label)
                                .font(SaviType.ui(.caption2, weight: .black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                                .foregroundStyle(index == phase ? Color.black : SaviTheme.textMuted)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(index == phase ? SaviTheme.chartreuse : SaviTheme.surfaceRaised.opacity(0.72))
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
                .padding(10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
        .task {
            guard !SaviPerformancePolicy.current.usesStaticShareSetupDemo else {
                phase = 3
                return
            }
            guard !reduceMotion else {
                phase = 3
                return
            }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_250_000_000)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                        phase = (phase + 1) % phaseLabels.count
                    }
                }
            }
        }
    }
}

private struct ShareSetupDemoToolbarButton: View {
    let symbolName: String
    var active = false

    var body: some View {
        Image(systemName: symbolName)
            .font(SaviType.ui(.caption, weight: .black))
            .frame(width: 32, height: 32)
            .background(active ? SaviTheme.chartreuse : SaviTheme.surfaceRaised.opacity(0.82))
            .foregroundStyle(active ? Color.black : SaviTheme.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

private struct ShareSetupDemoSheet: View {
    let phase: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Capsule()
                    .fill(SaviTheme.textMuted.opacity(0.28))
                    .frame(width: 42, height: 5)
                Spacer()
                Text(phase >= 3 ? "Favorites" : "Share")
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
            }

            HStack(spacing: 8) {
                ShareSetupDemoAppPill(title: "Messages", symbolName: "message.fill")
                ShareSetupDemoAppPill(title: "Mail", symbolName: "envelope.fill")
                ShareSetupDemoAppPill(title: phase >= 3 ? "SAVI" : "More", symbolName: phase >= 3 ? "sparkles" : "ellipsis", active: phase >= 2)
            }

            if phase >= 2 {
                HStack(spacing: 8) {
                    Image(systemName: phase >= 3 ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(phase >= 3 ? SaviTheme.chartreuse : SaviTheme.accentText)
                    Text(phase >= 3 ? "SAVI is near the front" : "Add SAVI to Favorites")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                    Spacer(minLength: 0)
                    Image(systemName: "line.3.horizontal")
                        .font(SaviType.ui(.caption2, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                }
                .padding(9)
                .background(SaviTheme.surfaceRaised.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .background(SaviTheme.surface.opacity(0.80), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
        .shadow(color: SaviTheme.cardShadow.opacity(0.22), radius: 18, x: 0, y: 10)
    }
}

private struct ShareSetupDemoAppPill: View {
    let title: String
    let symbolName: String
    var active = false

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: symbolName)
                .font(SaviType.ui(.caption, weight: .black))
                .frame(width: 34, height: 34)
                .background(active ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                .foregroundStyle(active ? Color.black : SaviTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(title)
                .font(SaviType.ui(.caption2, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .foregroundStyle(SaviTheme.text)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ShareSetupGuideSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @State private var practiceShareFile: ShareSetupPracticeShareFile?

    private let steps: [ShareSetupGuideStep] = [
        ShareSetupGuideStep(
            imageName: "share-setup-step-share",
            title: "Tap Share",
            message: "Tap the Share button on anything you want to keep."
        ),
        ShareSetupGuideStep(
            imageName: "share-setup-step-more",
            title: "Tap More",
            message: "If SAVI is hidden, open More at the end of the app row."
        ),
        ShareSetupGuideStep(
            imageName: "share-setup-step-favorite",
            title: "Add SAVI to Favorites",
            message: "Favorite SAVI and drag it near the front."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SHARE SHEET SETUP")
                            .font(SaviType.ui(.caption2, weight: .black))
                            .foregroundStyle(SaviTheme.accentText)
                            .textCase(.uppercase)
                        Text("Save from anywhere")
                            .font(SaviType.display(size: 34, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Try one example now. Then pin SAVI so every app can save this fast.")
                            .font(SaviType.ui(.subheadline, weight: .semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ShareSetupPracticeCard {
                        if let url = store.makeShareSetupPracticeShareURL() {
                            practiceShareFile = ShareSetupPracticeShareFile(url: url)
                        }
                    }

                    ShareSetupStatusCard()

                    Text("Pin SAVI once")
                        .font(SaviType.display(size: 24, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                        .padding(.top, 2)

                    VStack(spacing: 12) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            ShareSetupGuideStepCard(index: index + 1, step: step)
                        }
                    }

                    Text("iOS does not let SAVI turn this on automatically. Once you save through the extension, SAVI will know setup worked and stop reminding you.")
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(item: $practiceShareFile) { file in
            SaviActivityView(activityItems: [file.url]) { completed in
                if completed {
                    store.toast = "If you chose SAVI, check Home in a second."
                }
            }
        }
    }
}

private struct ShareSetupPracticeShareFile: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSetupPracticeCard: View {
    @EnvironmentObject private var store: SaviStore
    let shareAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topTrailing) {
                Image("share-setup-practice-savi-first-card")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 324)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                SaviTheme.chartreuse.opacity(0.22),
                                SaviTheme.surfaceRaised.opacity(0.74)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 26, style: .continuous)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.68), lineWidth: 1)
                    )
                    .accessibilityHidden(true)

                Button(action: shareAction) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(SaviType.ui(.headline, weight: .black))
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial, in: Circle())
                        .background(Color.black.opacity(0.10), in: Circle())
                        .foregroundStyle(SaviTheme.text)
                        .overlay(Circle().stroke(Color.white.opacity(0.62), lineWidth: 1))
                        .shadow(color: SaviTheme.cardShadow.opacity(0.18), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .padding(14)
                .accessibilityLabel("Open iOS Share Sheet")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("TRY A SAVE")
                    .font(SaviType.ui(.caption2, weight: .black))
                    .foregroundStyle(SaviTheme.accentText)
                    .textCase(.uppercase)
                Text("SAVI's first card")
                    .font(SaviType.display(size: 27, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text("Open the real iOS Share Sheet with this card, or save it directly so you can see how previews, folders, and search feel.")
                    .font(SaviType.ui(.subheadline, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                ShareSetupPracticePill(title: "SAVI", color: SaviTheme.chartreuse)
                ShareSetupPracticePill(title: "Image", color: Color(hex: "#7EC8FF"))
                ShareSetupPracticePill(title: "Getting Started", color: Color(hex: "#FFB978"))
            }

            if store.hasShareSetupPracticeSave {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SaviTheme.chartreuse)
                    Text("Saved to Your Folders")
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SaviTheme.surfaceRaised.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    store.openShareSetupPracticeSave()
                } label: {
                    Label("View it in SAVI", systemImage: "eye.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaviPrimaryButtonStyle())

                Button(action: shareAction) {
                    Label("Share this card", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaviSecondaryButtonStyle())
            } else {
                Button(action: shareAction) {
                    Label("Share this card", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaviPrimaryButtonStyle())

                Button {
                    store.addShareSetupPracticeSave()
                } label: {
                    Label("Save directly to SAVI", systemImage: "tray.and.arrow.down.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaviSecondaryButtonStyle())
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .background(SaviTheme.surface.opacity(0.82), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
        .shadow(color: SaviTheme.cardShadow.opacity(0.18), radius: 20, x: 0, y: 12)
    }
}

private struct ShareSetupPracticePill: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(SaviType.ui(.caption, weight: .black))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .foregroundStyle(Color.black.opacity(0.82))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.82), in: Capsule())
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
    var title: String
    var message: String
}

private struct ShareSetupGuideStepCard: View {
    let index: Int
    let step: ShareSetupGuideStep

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(step.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 102, height: 142)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.64), lineWidth: 1)
                )
                .shadow(color: SaviTheme.cardShadow.opacity(0.12), radius: 8, x: 0, y: 5)

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
                        Text("One minute: turn on saving from anywhere")
                            .font(SaviType.display(size: 25, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                        Text("You have not saved through the iOS Share Sheet yet. Pin SAVI once and every link, screenshot, PDF, and video can land here fast.")
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
        if SaviPerformancePolicy.current.isLegacy { return colorScheme == .dark ? 0.04 : 0.055 }
        return colorScheme == .dark ? 0.07 : 0.10
    }

    static func cardRadius(_ colorScheme: ColorScheme) -> CGFloat {
        if SaviPerformancePolicy.current.isLegacy { return colorScheme == .dark ? 4 : 6 }
        return colorScheme == .dark ? 12 : 16
    }

    static func cardY(_ colorScheme: ColorScheme) -> CGFloat {
        if SaviPerformancePolicy.current.isLegacy { return colorScheme == .dark ? 2 : 3 }
        return colorScheme == .dark ? 5 : 7
    }

    static func folderRadius(_ colorScheme: ColorScheme) -> CGFloat {
        if SaviPerformancePolicy.current.isLegacy { return colorScheme == .dark ? 2 : 4 }
        return colorScheme == .dark ? 7 : 12
    }

    static func folderY(_ colorScheme: ColorScheme) -> CGFloat {
        if SaviPerformancePolicy.current.isLegacy { return colorScheme == .dark ? 1 : 2 }
        return colorScheme == .dark ? 3 : 6
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
    static let surface = adaptive(dark: "#211833", light: "#FFFFFF")
    static let surfaceRaised = adaptive(dark: "#302649", light: "#ECE5F4")
    static let subtleSurface = adaptive(dark: "#2A203F", light: "#F0EAF7")
    static let inputSurface = adaptive(dark: "#261C3B", light: "#FFFFFF")
    static let text = adaptive(dark: "#F5F0FF", light: "#160F22")
    static let textMuted = adaptive(dark: "#CBC0EA", light: "#51475E")
    static let metadataText = adaptive(dark: "#BEB1DD", light: "#766986")
    static let chartreuse = adaptive(dark: "#D8FF3C", light: "#9BD80F")
    static let softAccent = adaptive(dark: "#D8FF3C", light: "#DDF6A1")
    static let accentText = adaptive(dark: "#D8FF3C", light: "#4F246F")
    static let cardStroke = adaptive(dark: "#4A3A67", light: "#C9BDD8")
    static let folderCardStroke = adaptive(dark: "#5A4778", light: "#BDA9CF")
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
            case "f-life-admin", "f-paste-bin", "f-wtf-favorites", "f-growth", "f-lmao", "f-travel", "f-recipes", "f-health", "f-design", "f-research", "f-random", "f-all":
                return false
            default:
                break
            }
        }

        return prefersLightForeground(onHex: hex)
    }

    private static func defaultDisplayHex(for folderId: String) -> String? {
        switch folderId {
        case "f-life-admin": return "#FFD15C"
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
        case "f-life-admin": return ["#FFD15C"]
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
            case "f-life-admin":
                return lightFolderPair("#FFD66A", "#FFC84E", amount: 0.76)
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
            blendedFolderColor(hex: hex, with: "#12091F", amount: 0.62),
            blendedFolderColor(hex: hex, with: "#12091F", amount: 0.40)
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

    var body: some View {
        ZStack {
            style.backgroundGradient

            if folder.usesImageBackground,
               let imageDataURL = folder.image?.nilIfBlank {
                SaviCachedDataURLImage(dataURL: imageDataURL) {
                    EmptyView()
                }
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
    static let titleSize: CGFloat = 16
    static let titleBlockHeight: CGFloat = 39
    static let iconSize: CGFloat = 28
    static let iconCornerRadius: CGFloat = 9
    static var iconFont: Font { SaviType.ui(.caption2, weight: .black) }
}

enum SaviFolderNameFormatter {
    static func balanced(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        switch trimmed {
        case "AI & Work", "Health":
            return trimmed
        case "Health Hacks":
            return "Health\nHacks"
        case "Life Admin":
            return "Life\nAdmin"
        case "Watch / Read Later":
            return "Watch /\nRead Later"
        case "Memes & Laughs":
            return "Memes &\nLaughs"
        case "Memes & LOLs":
            return "Memes &\nLOLs"
        case "Places & Trips":
            return "Places &\nTrips"
        case "Recipes & Food":
            return "Recipes &\nFood"
        case "Notes & Clips":
            return "Notes &\nClips"
        case "Private Vault":
            return "Private\nVault"
        case "Research & PDFs":
            return "Research &\nPDFs"
        case "Design Inspo":
            return "Design\nInspo"
        case "Science Finds":
            return "Science\nFinds"
        case "Rabbit Holes":
            return "Rabbit\nHoles"
        case "Everything Else":
            return "Everything\nElse"
        default:
            break
        }
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

struct SaviFolderTitleText: View {
    let name: String
    let style: SaviFolderVisualStyle
    var size: CGFloat = SaviFolderTileMetrics.titleSize

    var body: some View {
        Text(SaviFolderNameFormatter.balanced(name))
            .font(SaviType.display(size: size, weight: .heavy))
            .foregroundStyle(style.text)
            .shadow(color: style.titleShadow, radius: style.titleShadowRadius, x: 0, y: 1)
            .lineLimit(2)
            .lineSpacing(1.4)
            .minimumScaleFactor(0.86)
            .allowsTightening(true)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: SaviFolderTileMetrics.titleBlockHeight, alignment: .bottomLeading)
            .accessibilityLabel(name)
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
            .overlay(shape.stroke(SaviTheme.cardStroke.opacity(colorScheme == .dark ? 0.7 : 0.78), lineWidth: 1))
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
