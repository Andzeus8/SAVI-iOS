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
                        message: "Use the iOS Share button or the plus in SAVI. It saves immediately; title, preview, tags, and Folder can catch up."
                    )
                    OnboardingFeatureCard(
                        symbolName: "sparkles",
                        title: "Rediscover what you saved",
                        message: "Explore shuffles links, videos, images, places, and friend saves into a fresh scroll."
                    )
                    OnboardingFeatureCard(
                        symbolName: "folder.fill",
                        title: "Folders stay organized",
                        message: "Folders are your main categories. Drag them into the order that matters to you."
                    )
                }

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

            let text = usesLightText ? paper : ink
            let controlForeground = usesLightText ? paper : ink
            return SaviFolderVisualStyle(
                baseHex: hex,
                base: base,
                text: text,
                secondaryText: text.opacity(usesLightText ? 0.72 : 0.58),
                titleShadow: usesLightText ? Color.black.opacity(0.20) : Color.clear,
                titleShadowRadius: usesLightText ? 1 : 0,
                iconBackground: usesLightText ? paper.opacity(0.16) : paper.opacity(0.48),
                iconForeground: controlForeground.opacity(usesLightText ? 0.92 : 0.86),
                countBackground: usesLightText ? paper.opacity(0.22) : paper.opacity(0.66),
                countForeground: controlForeground,
                stroke: usesLightText ? paper.opacity(0.24) : paper.opacity(0.42),
                shadow: base.opacity(usesLightText ? 0.20 : 0.16),
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

        return SaviFolderVisualStyle(
            baseHex: hex,
            base: base,
            text: Color(hex: "#FFF9FF"),
            secondaryText: Color(hex: "#D9D0EF").opacity(0.84),
            titleShadow: Color.black.opacity(0.25),
            titleShadowRadius: 1,
            iconBackground: Color.white.opacity(0.14),
            iconForeground: Color(hex: "#FFF9FF"),
            countBackground: Color.white.opacity(0.15),
            countForeground: Color(hex: "#FFF9FF"),
            stroke: Color.white.opacity(0.12),
            shadow: Color.black.opacity(0.20),
            pillBackground: SaviTheme.subtleSurface.opacity(0.56),
            pillForeground: Color(hex: "#D9D0EF"),
            pillStroke: base.opacity(0.32),
            backgroundColors: darkBackgroundColors(baseHex: hex)
        )
    }

    static func preferredHex(for folder: SaviFolder) -> String {
        switch folder.id {
        case "f-must-see": return "#6D28D9"
        case "f-paste-bin": return "#8A7CA8"
        case "f-wtf-favorites": return "#7DD3FC"
        case "f-growth": return "#FF8A3D"
        case "f-lmao": return "#D8FF3C"
        case "f-private-vault": return "#12091F"
        case "f-travel": return "#66C7F4"
        case "f-recipes": return "#FFB36B"
        case "f-health": return "#74D99F"
        case "f-design": return "#FF8BB5"
        case "f-research": return "#5EEAD4"
        case "f-tinfoil": return "#7C3AED"
        case "f-random": return "#FFE066"
        case "f-all": return "#D8FF3C"
        default: return folder.color
        }
    }

    private static func usesLightForeground(for folder: SaviFolder, baseHex hex: String, colorScheme: ColorScheme) -> Bool {
        if colorScheme == .dark { return true }
        switch folder.id {
        case "f-must-see", "f-paste-bin", "f-growth", "f-private-vault", "f-design", "f-tinfoil":
            return true
        case "f-wtf-favorites", "f-lmao", "f-travel", "f-recipes", "f-health", "f-research", "f-random", "f-all":
            return false
        default:
            return prefersLightForeground(onHex: hex)
        }
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
        switch folderId {
        case "f-must-see":
            return [Color(hex: "#8A35FF"), Color(hex: "#7430E8")]
        case "f-paste-bin":
            return [Color(hex: "#9887B3"), Color(hex: "#81709F")]
        case "f-wtf-favorites":
            return [Color(hex: "#86D9F8"), Color(hex: "#71CFF2")]
        case "f-growth":
            return [Color(hex: "#F6843D"), Color(hex: "#E1682F")]
        case "f-lmao":
            return [Color(hex: "#DCFF3D"), Color(hex: "#CEFA32")]
        case "f-travel":
            return [Color(hex: "#78D3F7"), Color(hex: "#60C5EF")]
        case "f-recipes":
            return [Color(hex: "#FFC27D"), Color(hex: "#FFB06A")]
        case "f-health":
            return [Color(hex: "#83E2AA"), Color(hex: "#68D195")]
        case "f-design":
            return [Color(hex: "#EA6EA7"), Color(hex: "#CF4E91")]
        case "f-research":
            return [Color(hex: "#70F1DD"), Color(hex: "#55DDC9")]
        case "f-tinfoil":
            return [Color(hex: "#8B5CF6"), Color(hex: "#6D28D9")]
        case "f-random":
            return [Color(hex: "#FFE773"), Color(hex: "#FFD955")]
        case "f-all":
            return [Color(hex: "#DFFF42"), Color(hex: "#CBF42F")]
        default:
            let base = Color(hex: hex)
            return [base, base.opacity(0.86)]
        }
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
