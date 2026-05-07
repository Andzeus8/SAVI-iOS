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

struct ProfileScreen: View {
    @EnvironmentObject private var store: SaviStore
    @Binding var backupImportPresented: Bool
    @State private var activeProfileSheet: ProfileManagementSheet?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HeaderBlock(
                        eyebrow: "Settings",
                        title: "Your SAVI",
                        subtitle: SaviReleaseGate.socialFeaturesEnabled
                            ? "Your account, sharing, backups, and archive controls."
                            : "Fast saving, smart folders, search, privacy, and backups.",
                        titleSize: 36
                    )

                    if SaviReleaseGate.socialFeaturesEnabled {
                        ProfileSocialHubCard {
                            activeProfileSheet = .social
                        }
                    } else {
                        ProfileBetaNotesCard()
                    }

                    ProfileSectionLabel(
                        title: "Pilot checklist",
                        subtitle: "Try the path this beta is built around."
                    )

                    ProfileSetupChecklist(
                        openGuide: { activeProfileSheet = .guide },
                        openSearch: { store.setTab(.search) },
                        openVault: { store.openFoldersManagement() },
                        openBackup: { activeProfileSheet = .backup },
                        openFeedback: { activeProfileSheet = .feedback }
                    )

                    ProfileFeedbackCard(
                        openGuide: { activeProfileSheet = .guide }
                    )

                    ProfilePrivacyBackupGroup(
                        openVault: { store.openFoldersManagement() },
                        openBackup: { activeProfileSheet = .backup },
                        openAccount: { activeProfileSheet = .account }
                    )

                    ProfileLibraryAppearanceGroup(
                        openAppearance: { activeProfileSheet = .appearance },
                        openLibrary: { activeProfileSheet = .library }
                    )

                    StatsPanel()

                    if !SaviReleaseGate.socialFeaturesEnabled {
                        ProfileSocialComingSoonCard()
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 18)
            }
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
            .sheet(item: $activeProfileSheet) { sheet in
                ProfileDetailSheet(
                    sheet: sheet,
                    backupImportPresented: $backupImportPresented
                )
                .environmentObject(store)
                .preferredColorScheme(store.preferredColorScheme)
                .presentationDetents(sheet.presentationDetents)
                .presentationDragIndicator(.visible)
            }
        }
    }
}

enum ProfileManagementSheet: String, Identifiable {
    case social
    case account
    case backup
    case appearance
    case guide
    case library
    case feedback

    var id: String { rawValue }

    var title: String {
        switch self {
        case .social: return "Social Beta"
        case .account: return "Account & iCloud"
        case .backup: return "Backups"
        case .appearance: return "Appearance"
        case .guide: return "Guide"
        case .library: return "Library Tools"
        case .feedback: return "Help & Feedback"
        }
    }

    var presentationDetents: Set<PresentationDetent> {
        switch self {
        case .appearance, .guide, .feedback:
            return [.medium, .large]
        default:
            return [.large]
        }
    }
}

struct ProfileDetailSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    let sheet: ProfileManagementSheet
    @Binding var backupImportPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch sheet {
                    case .social:
                        if SaviReleaseGate.socialFeaturesEnabled {
                            FriendsSettingsCard()
                        } else {
                            SocialDisabledSettingsCard()
                        }
                    case .account:
                        AccountCloudSettingsCard(
                            backupImportPresented: $backupImportPresented,
                            restoreFileAction: presentBackupImport
                        )
                    case .backup:
                        BackupSettingsCard(
                            backupImportPresented: $backupImportPresented,
                            restoreFileAction: presentBackupImport
                        )
                    case .appearance:
                        AppearanceSettingsCard()
                    case .guide:
                        GuideSettingsCard()
                    case .library:
                        LibrarySettingsCard()
                    case .feedback:
                        FeedbackSettingsCard()
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle(sheet.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(store.preferredColorScheme)
    }

    private func presentBackupImport() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            backupImportPresented = true
        }
    }
}

struct ProfileSocialHubCard: View {
    @EnvironmentObject private var store: SaviStore
    let action: () -> Void

    private var publicLinkCount: Int {
        store.publicSharedLinks().count
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 13) {
                    Circle()
                        .fill(Color(hex: store.publicProfile.avatarColor))
                        .frame(width: 54, height: 54)
                        .overlay(
                            Text(store.publicProfile.normalizedUsername.prefix(1).uppercased())
                                .font(SaviType.ui(.title3, weight: .black))
                                .foregroundStyle(SaviTheme.foreground(onHex: store.publicProfile.avatarColor))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Social")
                                .font(SaviType.ui(.title2, weight: .black))
                                .foregroundStyle(SaviTheme.text)
                            SocialBetaBadge()
                        }
                        Text("Friends, public Folders, and shared links.")
                            .font(SaviType.reading(.subheadline, weight: .regular))
                            .foregroundStyle(SaviTheme.textMuted)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.black))
                        .frame(width: 36, height: 36)
                        .background(SaviTheme.surfaceRaised)
                        .foregroundStyle(SaviTheme.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                HStack(spacing: 8) {
                    ProfileMetricChip(value: "\(store.visibleFriends.count)", label: "Friends", symbol: "person.2.fill")
                    ProfileMetricChip(value: "\(publicLinkCount)", label: "Public", symbol: "link")
                    ProfileMetricChip(value: "\(store.visibleFriendLinks.count)", label: "Feed", symbol: "sparkles")
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [SaviTheme.surface, SaviTheme.softAccent.opacity(0.42)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(SaviTheme.accentText.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: SaviTheme.cardShadow.opacity(0.10), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("Open Social Beta. \(store.visibleFriends.count) friends, \(publicLinkCount) public links, \(store.visibleFriendLinks.count) feed links.")
    }
}

struct ProfileBetaNotesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(SaviType.ui(.headline, weight: .black))
                    .frame(width: 42, height: 42)
                    .background(SaviTheme.softAccent.opacity(0.72))
                    .foregroundStyle(SaviTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("SAVI Beta")
                        .font(SaviType.ui(.headline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                    Text("Save from any app, let SAVI sort it, then find it again by title, folder, tag, source, or file type.")
                        .font(SaviType.reading(.caption, weight: .regular))
                        .foregroundStyle(SaviTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ProfileBetaPill(title: "Share Sheet", symbol: "square.and.arrow.up")
                ProfileBetaPill(title: "Search", symbol: "magnifyingglass")
                ProfileBetaPill(title: "Private Vault", symbol: "lock.shield.fill")
                ProfileBetaPill(title: "Full Archive", symbol: "archivebox.fill")
            }

            HStack(spacing: 7) {
                SocialBetaBadge()
                Text("Friends' curated favorites are coming later; this beta keeps your saves private.")
                    .font(SaviType.ui(.caption, weight: .black))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(SaviTheme.metadataText)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SaviTheme.surfaceRaised.opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .saviCard(cornerRadius: 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("SAVI Beta. Save from any app, let SAVI sort it, then find it again by title, folder, tag, source, or file type. Friends' curated favorites are coming later; this beta keeps your saves private.")
    }
}

struct ProfileBetaPill: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(SaviType.ui(.caption2, weight: .black))
            Text(title)
                .font(SaviType.ui(.caption, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, minHeight: 30)
        .padding(.horizontal, 8)
        .background(SaviTheme.surfaceRaised.opacity(0.74))
        .foregroundStyle(SaviTheme.text)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(SaviTheme.cardStroke.opacity(0.74), lineWidth: 1))
    }
}

struct ProfileSocialComingSoonCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            Image(systemName: "person.2.fill")
                .font(SaviType.ui(.subheadline, weight: .black))
                .frame(width: 36, height: 36)
                .background(SaviTheme.surfaceRaised)
                .foregroundStyle(SaviTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text("Friends' favorites are next")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                    SocialBetaBadge()
                }
                Text("SAVI starts as your pocket organizer. Later, friends can curate the links, videos, places, and ideas they actually recommend.")
                    .font(SaviType.reading(.caption, weight: .regular))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(13)
        .background(SaviTheme.surface.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(SaviTheme.cardStroke.opacity(0.68), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Friends' favorites are next. Social Beta. SAVI starts as your pocket organizer. Later, friends can curate the links, videos, places, and ideas they actually recommend.")
    }
}

struct SocialDisabledSettingsCard: View {
    var body: some View {
        SettingsCard(title: "Social Beta", symbol: "person.2.slash.fill") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Friends' favorites are coming later.")
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text("For this TestFlight, SAVI is focused on saving everyday things, finding them again, folders, Private Vault, and archive backup. Friend-curated feeds, public profiles, likes, and publishing stay hidden until moderation, reporting, and terms are ready.")
                    .font(SaviType.ui(.subheadline, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ProfileSectionLabel: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(SaviType.ui(.title3, weight: .black))
                .foregroundStyle(SaviTheme.text)
            Text(subtitle)
                .font(SaviType.reading(.caption, weight: .regular))
                .foregroundStyle(SaviTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
        .accessibilityElement(children: .combine)
    }
}

struct ProfileSetupChecklist: View {
    @EnvironmentObject private var store: SaviStore
    let openGuide: () -> Void
    let openSearch: () -> Void
    let openVault: () -> Void
    let openBackup: () -> Void
    let openFeedback: () -> Void

    private var privateVaultStatus: String {
        if store.folders.first(where: { $0.id == "f-private-vault" })?.locked == true {
            return "Locked"
        }
        return "Optional"
    }

    var body: some View {
        VStack(spacing: 8) {
            ProfileSetupRow(
                title: "Pin SAVI in Share Sheet",
                subtitle: store.isShareExtensionSetupComplete
                    ? "Fast saves from Safari, YouTube, Photos, Files, and more."
                    : "The fastest way to get links, screenshots, notes, and files into SAVI.",
                symbol: store.isShareExtensionSetupComplete ? "checkmark.circle.fill" : "square.and.arrow.up",
                status: store.isShareExtensionSetupComplete ? "Working" : "Set up",
                tint: store.isShareExtensionSetupComplete ? SaviTheme.chartreuse : SaviTheme.accentText,
                iconForeground: store.isShareExtensionSetupComplete ? .black : nil,
                action: openGuide
            )

            ProfileSetupRow(
                title: "Find something again",
                subtitle: "Search the sample library by title, folder, tag, source, or file type, then try Explore.",
                symbol: "magnifyingglass",
                status: "Try",
                tint: SaviTheme.accentText,
                action: openSearch
            )

            ProfileSetupRow(
                title: "Protect Private Vault",
                subtitle: "Keep IDs, codes, receipts, banking notes, and medical saves behind Face ID.",
                symbol: "lock.shield.fill",
                status: privateVaultStatus,
                tint: SaviTheme.accentText,
                action: openVault
            )

            ProfileSetupRow(
                title: "Export a full archive",
                subtitle: "Save a portable ZIP with folders, notes, files, PDFs, images, and links.",
                symbol: "archivebox.fill",
                status: "Ready",
                tint: SaviTheme.chartreuse,
                iconForeground: .black,
                action: openBackup
            )

            ProfileSetupRow(
                title: "Send feedback",
                subtitle: "Report bugs, confusing moments, or anything that blocks the pilot.",
                symbol: "exclamationmark.bubble.fill",
                status: "Open",
                tint: SaviTheme.accentText,
                action: openFeedback
            )
        }
        .padding(10)
        .saviCard(cornerRadius: 18)
    }
}

struct ProfileSetupRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let status: String
    let tint: Color
    var iconForeground: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: symbol)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.17))
                    .foregroundStyle(iconForeground ?? tint)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(subtitle)
                        .font(SaviType.reading(.caption, weight: .regular))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Text(status)
                    .font(SaviType.ui(.caption2, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .padding(.horizontal, 8)
                    .frame(height: 26)
                    .background(SaviTheme.surfaceRaised.opacity(0.78))
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(SaviType.ui(.caption2, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted.opacity(0.82))
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SaviTheme.surface.opacity(0.58))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(SaviTheme.cardStroke.opacity(0.72), lineWidth: 1)
            )
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("\(title). \(subtitle). \(status).")
    }
}

struct ProfileFeedbackCard: View {
    let openGuide: () -> Void

    var body: some View {
        SettingsCard(title: "Help & Feedback", symbol: "exclamationmark.bubble.fill") {
            ProfileFeedbackActions(area: "Profile", openGuide: openGuide)
        }
    }
}

struct FeedbackSettingsCard: View {
    var body: some View {
        SettingsCard(title: "Help & Feedback", symbol: "exclamationmark.bubble.fill") {
            ProfileFeedbackActions(area: "Help & Feedback", openGuide: nil)
        }
    }
}

private struct ProfileFeedbackActions: View {
    @Environment(\.openURL) private var openURL
    @State private var feedbackStatus: String?
    let area: String
    var openGuide: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Send pilot bugs, confusing moments, or anything that makes saving and finding feel slower than it should.")
                .font(SaviType.ui(.subheadline, weight: .semibold))
                .foregroundStyle(SaviTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                openBugReport()
            } label: {
                Label("Report a bug", systemImage: "envelope.badge.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviPrimaryButtonStyle())

            Button {
                copyFeedbackEmail()
            } label: {
                Label("Copy \(SaviSupport.feedbackEmail)", systemImage: "doc.on.doc.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviSecondaryButtonStyle())

            if let openGuide {
                Button(action: openGuide) {
                    Label("Quick Guide", systemImage: "questionmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaviSecondaryButtonStyle())
            }

            Text("TestFlight screenshot feedback also lands in App Store Connect. Email is best when you want a direct thread.")
                .font(SaviType.ui(.caption, weight: .semibold))
                .foregroundStyle(SaviTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            if let feedbackStatus {
                Text(feedbackStatus)
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.accentText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func openBugReport() {
        guard let url = SaviSupport.bugReportURL(area: area) else {
            copyFeedbackEmail()
            return
        }

        openURL(url) { accepted in
            if accepted {
                feedbackStatus = "Opening email to \(SaviSupport.feedbackEmail)."
            } else {
                copyFeedbackEmail()
            }
        }
    }

    private func copyFeedbackEmail() {
        UIPasteboard.general.string = SaviSupport.feedbackEmail
        feedbackStatus = "Copied \(SaviSupport.feedbackEmail)."
    }
}

struct ProfilePrivacyBackupGroup: View {
    @EnvironmentObject private var store: SaviStore
    let openVault: () -> Void
    let openBackup: () -> Void
    let openAccount: () -> Void

    private var privateVaultTrailing: String {
        if store.folders.first(where: { $0.id == "f-private-vault" })?.locked == true {
            return "Locked"
        }
        return "Optional"
    }

    var body: some View {
        SettingsCard(title: "Privacy & Backup", symbol: "lock.shield.fill") {
            VStack(spacing: 8) {
                ProfileSettingsRow(
                    title: "Private Vault",
                    subtitle: "Lock sensitive saves behind Face ID or passcode.",
                    symbol: "lock.shield.fill",
                    trailing: privateVaultTrailing,
                    action: openVault
                )

                ProfileSettingsRow(
                    title: "Full Archive",
                    subtitle: "Export or restore a portable ZIP of your library.",
                    symbol: "externaldrive.fill",
                    trailing: "Ready",
                    tint: SaviTheme.chartreuse,
                    action: openBackup
                )

                ProfileSettingsRow(
                    title: "Account & iCloud",
                    subtitle: store.isAppleAccountLinked
                        ? store.cloudKitStatus
                        : (SaviReleaseGate.socialFeaturesEnabled ? "Sign in for friends and iCloud." : "Optional private backup status."),
                    symbol: "person.crop.circle.badge.checkmark",
                    trailing: store.isAppleAccountLinked ? "Linked" : (SaviReleaseGate.socialFeaturesEnabled ? "Set up" : "Check"),
                    action: openAccount
                )
            }
        }
    }
}

struct ProfileLibraryAppearanceGroup: View {
    let openAppearance: () -> Void
    let openLibrary: () -> Void

    var body: some View {
        SettingsCard(title: "Library & Appearance", symbol: "slider.horizontal.3") {
            VStack(spacing: 8) {
                ProfileSettingsRow(
                    title: "Appearance",
                    subtitle: "Theme and display.",
                    symbol: "moon.stars.fill",
                    action: openAppearance
                )

                ProfileSettingsRow(
                    title: "Library tools",
                    subtitle: "Sample saves and device cleanup.",
                    symbol: "archivebox.fill",
                    tint: .red,
                    action: openLibrary
                )
            }
        }
    }
}

struct ProfileMetricChip: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(SaviType.ui(.caption2, weight: .black))
            Text(value)
                .font(SaviType.ui(.caption, weight: .black))
            Text(label)
                .font(SaviType.ui(.caption2, weight: .bold))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.78)
        .padding(.horizontal, 9)
        .frame(maxWidth: .infinity, minHeight: 34)
        .background(SaviTheme.surfaceRaised.opacity(0.76))
        .foregroundStyle(SaviTheme.text)
        .clipShape(Capsule())
            .overlay(Capsule().stroke(SaviTheme.cardStroke.opacity(0.82), lineWidth: 1))
    }
}

struct SocialBetaBadge: View {
    var body: some View {
        Text("BETA")
            .font(SaviType.ui(.caption2, weight: .black))
            .tracking(0.6)
            .padding(.horizontal, 7)
            .frame(height: 22)
            .background(SaviTheme.chartreuse)
            .foregroundStyle(.black)
            .clipShape(Capsule())
            .accessibilityLabel("Beta")
    }
}

struct ProfileShortcutGrid: View {
    let openFolders: () -> Void
    let openBackups: () -> Void
    let openAppearance: () -> Void
    let openGuide: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ProfileShortcutTile(
                title: "Full Archive",
                subtitle: "Export or restore everything.",
                symbol: "externaldrive.fill",
                tint: SaviTheme.chartreuse,
                iconForeground: .black,
                action: openBackups
            )

            ProfileShortcutTile(
                title: "Private Vault",
                subtitle: "Lock sensitive saves.",
                symbol: "lock.shield.fill",
                tint: SaviTheme.accentText,
                action: openFolders
            )

            ProfileShortcutTile(
                title: "Appearance",
                subtitle: "Theme and display.",
                symbol: "moon.stars.fill",
                tint: SaviTheme.accentText,
                action: openAppearance
            )

            ProfileShortcutTile(
                title: "Quick Guide",
                subtitle: "Tour and Share Sheet setup.",
                symbol: "questionmark.circle.fill",
                tint: SaviTheme.accentText,
                action: openGuide
            )
        }
    }
}

struct ProfileShortcutTile: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    var iconForeground: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: symbol)
                    .font(SaviType.ui(.headline, weight: .black))
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.18))
                    .foregroundStyle(iconForeground ?? tint)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(SaviType.ui(.headline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                    Text(subtitle)
                        .font(SaviType.reading(.caption, weight: .regular))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
            .saviCard(cornerRadius: 18)
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

struct ProfileSettingsGroup: View {
    @EnvironmentObject private var store: SaviStore
    let openAccount: () -> Void
    let openLibrary: () -> Void

    var body: some View {
        SettingsCard(title: "Account & Library", symbol: "slider.horizontal.3") {
            VStack(spacing: 8) {
                ProfileSettingsRow(
                    title: "Account & iCloud",
                    subtitle: store.isAppleAccountLinked
                        ? store.cloudKitStatus
                        : (SaviReleaseGate.socialFeaturesEnabled ? "Sign in for friends and iCloud." : "Optional private backup status."),
                    symbol: "person.crop.circle.badge.checkmark",
                    trailing: store.isAppleAccountLinked ? "Linked" : (SaviReleaseGate.socialFeaturesEnabled ? "Set up" : "Check"),
                    action: openAccount
                )

                ProfileSettingsRow(
                    title: "Library tools",
                    subtitle: "Sample saves and device cleanup.",
                    symbol: "archivebox.fill",
                    tint: .red,
                    action: openLibrary
                )
            }
        }
    }
}

struct ProfileSettingsRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    var trailing: String?
    var tint: Color = SaviTheme.accentText
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.14))
                    .foregroundStyle(tint)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(SaviType.reading(.caption, weight: .regular))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                if let trailing {
                    Text(trailing)
                        .font(SaviType.ui(.caption2, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(SaviTheme.textMuted)
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SaviTheme.surface.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(SaviTheme.cardStroke.opacity(0.8), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

struct AccountCloudSettingsCard: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    @Binding var backupImportPresented: Bool
    var restoreFileAction: (() -> Void)?

    var body: some View {
        SettingsCard(title: "Account & iCloud", symbol: "person.crop.circle.badge.checkmark") {
            VStack(alignment: .leading, spacing: 14) {
                accountStatus

                iCloudStatus

                HStack(spacing: 10) {
                    Button {
                        Task {
                            await store.refreshAppleAccountStatus()
                            await store.refreshCloudKitStatus()
                        }
                    } label: {
                        Label("Check status", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(SaviSecondaryButtonStyle())

                    Button {
                        if let restoreFileAction {
                            restoreFileAction()
                        } else {
                            backupImportPresented = true
                        }
                    } label: {
                        Label("Restore archive", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(SaviSecondaryButtonStyle())
                }

                Text(SaviReleaseGate.socialFeaturesEnabled
                    ? "SAVI stays usable without an account. Apple ID is only needed for public friend sharing and iCloud-backed features; full archives can be exported to Files or iCloud Drive anytime."
                    : "SAVI stays usable without an account. This beta keeps Social off; full archives can be exported to Files or iCloud Drive anytime.")
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var accountStatus: some View {
        if !SaviReleaseGate.socialFeaturesEnabled {
            AccountCloudPanel {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(SaviType.ui(.title3, weight: .black))
                        .frame(width: 42, height: 42)
                        .background(SaviTheme.surfaceRaised)
                        .foregroundStyle(SaviTheme.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("No account required")
                            .font(SaviType.ui(.subheadline, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                        Text("Social Beta is off")
                            .font(SaviType.ui(.caption, weight: .black))
                            .foregroundStyle(SaviTheme.accentText)
                        Text("Use SAVI locally and export a full archive for backup. iCloud backup is paused for this beta.")
                            .font(SaviType.ui(.caption2, weight: .semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        } else if store.isAppleAccountLinked {
            AccountCloudPanel {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "apple.logo")
                        .font(SaviType.ui(.title3, weight: .black))
                        .frame(width: 42, height: 42)
                        .background(SaviTheme.surfaceRaised)
                        .foregroundStyle(SaviTheme.text)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.appleAccountDisplayName)
                            .font(SaviType.ui(.subheadline, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text(store.appleAccountStatus)
                            .font(SaviType.ui(.caption, weight: .black))
                            .foregroundStyle(SaviTheme.accentText)
                        Text(store.appleAccountDetail)
                            .font(SaviType.ui(.caption2, weight: .semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Button {
                        store.unlinkAppleAccount()
                    } label: {
                        Text("Unlink")
                            .font(SaviType.ui(.caption, weight: .black))
                            .padding(.horizontal, 12)
                            .frame(minHeight: 38)
                            .background(SaviTheme.surfaceRaised)
                            .foregroundStyle(SaviTheme.text)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Unlink Apple ID")
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                SignInWithAppleButton(.signIn, onRequest: store.configureAppleSignIn, onCompletion: store.handleAppleSignInResult)
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityLabel("Sign in with Apple")

                Text("This links SAVI to your Apple ID for public sharing identity. Apple only returns your email/name the first time you approve it.")
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var iCloudStatus: some View {
        AccountCloudPanel {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: store.cloudKitStatus == "iCloud ready" ? "icloud.fill" : "icloud.slash.fill")
                    .font(SaviType.ui(.title3, weight: .black))
                    .frame(width: 42, height: 42)
                    .background(SaviTheme.surfaceRaised)
                    .foregroundStyle(store.cloudKitStatus == "iCloud ready" ? SaviTheme.accentText : SaviTheme.textMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(store.cloudKitStatus)
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                    Text(SaviReleaseGate.socialFeaturesEnabled
                        ? "CloudKit is used for friends and public link previews. Full local files stay private unless you export a backup to Files or iCloud Drive."
                        : "iCloud backup is paused for this beta while production CloudKit signing is verified. Use full archive export instead.")
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct AccountCloudPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(SaviTheme.surfaceRaised.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
    }
}

struct BackupSettingsCard: View {
    @EnvironmentObject private var store: SaviStore
    @Binding var backupImportPresented: Bool
    @State private var archiveOptionsPresented = false
    var restoreFileAction: (() -> Void)?

    var body: some View {
        SettingsCard(title: "Backup", symbol: "externaldrive.fill") {
            VStack(alignment: .leading, spacing: 10) {
                if SaviReleaseGate.cloudKitFeaturesEnabled {
                    Button {
                        Task { await store.backupToICloud() }
                    } label: {
                        Label(store.isCloudBackupRunning ? "Working..." : "Back up to iCloud", systemImage: "icloud.and.arrow.up.fill")
                    }
                    .buttonStyle(SaviPrimaryButtonStyle())
                    .disabled(store.isCloudBackupRunning)

                    Button {
                        Task { await store.restoreFromICloudBackup() }
                    } label: {
                        Label("Restore iCloud", systemImage: "icloud.and.arrow.down.fill")
                    }
                    .buttonStyle(SaviSecondaryButtonStyle())
                    .disabled(store.isCloudBackupRunning)

                    Divider()
                        .overlay(SaviTheme.cardStroke)
                        .padding(.vertical, 2)
                } else {
                    Text("For this TestFlight beta, full archive export is the supported backup path. iCloud backup will return after production CloudKit is verified.")
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        archiveOptionsPresented = true
                    } label: {
                        Label("Export full archive", systemImage: "archivebox.fill")
                    }
                    .buttonStyle(SaviPrimaryButtonStyle())

                    Text("Includes links, notes, PDFs, images, files, folders, tags, private vault items, and a readable offline index. Keep the exported ZIP somewhere safe.")
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    if let restoreFileAction {
                        restoreFileAction()
                    } else {
                        backupImportPresented = true
                    }
                } label: {
                    Label("Restore archive", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SaviSecondaryButtonStyle())

                Button {
                    store.buildBackupDocument()
                } label: {
                    Label("Export compact JSON backup", systemImage: "doc.text")
                }
                .buttonStyle(SaviSecondaryButtonStyle())

                if let message = store.cloudBackupMessage {
                    Text(message)
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.accentText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("Restoring a file shows a preview first, then replaces the current library only after you confirm. Compact JSON stays available for older SAVI backups.")
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                if let migration = store.migrationMessage {
                    Text(migration)
                        .font(.footnote)
                        .foregroundStyle(SaviTheme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .sheet(isPresented: $archiveOptionsPresented) {
            ArchiveExportOptionsSheet()
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .fileExporter(
            isPresented: $store.isExportingBackup,
            document: store.backupDocument ?? SaviBackupDocument(data: Data()),
            contentType: .json,
            defaultFilename: store.backupExportFilename
        ) { result in
            if case .failure = result {
                store.toast = "Backup export was cancelled."
            }
        }
    }
}

private struct ArchiveExportOptionsSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFolderIds = Set<String>()

    private var folders: [SaviFolder] {
        store.orderedFoldersForDisplay()
    }

    private var selectedCount: Int {
        selectedFolderIds.count
    }

    private var selectedItemCount: Int {
        store.items.filter { selectedFolderIds.contains($0.folderId) }.count
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Export archive")
                        .font(SaviType.display(size: 30, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                    Text("Export everything, or choose only the folders you want in the ZIP.")
                        .font(SaviType.reading(.subheadline, weight: .regular))
                        .foregroundStyle(SaviTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("After SAVI prepares the ZIP, iOS opens the share sheet so you can AirDrop, message, or Save to Files.")
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)

                HStack(spacing: 10) {
                    Button {
                        exportAll()
                    } label: {
                        Label(store.isPreparingArchiveExport ? "Preparing..." : "All folders", systemImage: store.isPreparingArchiveExport ? "hourglass" : "archivebox.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SaviPrimaryButtonStyle())
                    .disabled(store.isPreparingArchiveExport)

                    Button {
                        toggleAll()
                    } label: {
                        Label(selectedCount == folders.count ? "Clear" : "Select all", systemImage: "checklist")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SaviSecondaryButtonStyle())
                }
                .padding(.horizontal, 18)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(folders) { folder in
                            ArchiveFolderOptionRow(
                                folder: folder,
                                count: store.count(in: folder),
                                isSelected: selectedFolderIds.contains(folder.id)
                            ) {
                                toggle(folder)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 4)
                }

                VStack(spacing: 10) {
                    Button {
                        exportSelected()
                    } label: {
                        Label(
                            store.isPreparingArchiveExport ? "Preparing..." : selectedCount == 0 ? "Choose folders to export" : "Export \(selectedCount) folder\(selectedCount == 1 ? "" : "s")",
                            systemImage: store.isPreparingArchiveExport ? "hourglass" : "square.and.arrow.down"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SaviPrimaryButtonStyle())
                    .disabled(selectedCount == 0 || store.isPreparingArchiveExport)

                    Text(selectedCount == 0 ? "Selected folder archives include only those folders, their saves, and attached files." : "\(selectedItemCount) save\(selectedItemCount == 1 ? "" : "s") will be included. Restoring this archive later still replaces the current library after confirmation.")
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if selectedFolderIds.isEmpty {
                    selectedFolderIds = Set(folders.map(\.id))
                }
            }
        }
    }

    private func toggle(_ folder: SaviFolder) {
        if selectedFolderIds.contains(folder.id) {
            selectedFolderIds.remove(folder.id)
        } else {
            selectedFolderIds.insert(folder.id)
        }
    }

    private func toggleAll() {
        if selectedFolderIds.count == folders.count {
            selectedFolderIds.removeAll()
        } else {
            selectedFolderIds = Set(folders.map(\.id))
        }
    }

    private func exportAll() {
        dismiss()
        Task { await store.prepareFullArchiveForSharing() }
    }

    private func exportSelected() {
        let ids = selectedFolderIds
        dismiss()
        Task { await store.prepareFullArchiveForSharing(folderIds: ids) }
    }
}

private struct ArchiveFolderOptionRow: View {
    let folder: SaviFolder
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: folder.locked ? "lock.fill" : folder.symbolName)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: folder.color).opacity(0.18))
                    .foregroundStyle(SaviTheme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(folder.name)
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(1)
                    Text(folder.locked ? "Locked folder · \(count) saves" : "\(count) saves")
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.black))
                    .foregroundStyle(isSelected ? SaviTheme.chartreuse : SaviTheme.textMuted)
            }
            .padding(11)
            .background(SaviTheme.surface.opacity(isSelected ? 0.92 : 0.56))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? SaviTheme.chartreuse.opacity(0.42) : SaviTheme.cardStroke.opacity(0.72), lineWidth: 1)
            )
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("\(folder.name), \(count) saves, \(isSelected ? "selected" : "not selected")")
    }
}

struct AppearanceSettingsCard: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        SettingsCard(title: "Appearance", symbol: "moon.stars.fill") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose the display style that feels best on this phone.")
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    ThemeButton(title: "System", active: store.prefs.themeMode == "system") {
                        store.setTheme("system")
                    }
                    ThemeButton(title: "Dark", active: store.prefs.themeMode == "dark") {
                        store.setTheme("dark")
                    }
                    ThemeButton(title: "Light", active: store.prefs.themeMode == "light") {
                        store.setTheme("light")
                    }
                }
            }
        }
    }
}

struct GuideSettingsCard: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        SettingsCard(title: "Guide", symbol: "questionmark.circle.fill") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Replay the quick tour for saving, searching, browsing, Folders, privacy, and backup.")
                    .font(SaviType.ui(.subheadline, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Image(systemName: store.isShareExtensionSetupComplete ? "checkmark.circle.fill" : "square.and.arrow.up")
                        .font(SaviType.ui(.headline, weight: .black))
                        .frame(width: 38, height: 38)
                        .background(SaviTheme.surfaceRaised)
                        .foregroundStyle(store.isShareExtensionSetupComplete ? SaviTheme.chartreuse : SaviTheme.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Share Sheet")
                            .font(SaviType.ui(.subheadline, weight: .black))
                            .foregroundStyle(SaviTheme.text)
                        Text(store.shareSetupStatusText)
                            .font(SaviType.ui(.caption, weight: .semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                    }

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(SaviTheme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    store.startCoachTour()
                } label: {
                    Label("Replay quick tour", systemImage: "sparkles")
                }
                .buttonStyle(SaviSecondaryButtonStyle())

                Button {
                    store.openShareSetupGuide()
                } label: {
                    Label("Share Sheet setup", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SaviSecondaryButtonStyle())
            }
        }
    }
}

struct LibrarySettingsCard: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        SettingsCard(title: "Library", symbol: "archivebox.fill") {
            VStack(alignment: .leading, spacing: 10) {
                Text(SaviReleaseGate.demoLibraryEnabled
                    ? "Sample saves help new testers explore SAVI. You can clear them without touching personal saves."
                    : "Manage local device data. Export a full archive before destructive cleanup.")
                    .font(SaviType.ui(.subheadline, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                if SaviReleaseGate.demoLibraryEnabled {
                    if store.hasSampleLibraryContent {
                        Button {
                            store.clearDemoContent()
                        } label: {
                            Label("Clear \(store.sampleItemCount) sample saves", systemImage: "sparkles")
                        }
                        .buttonStyle(SaviSecondaryButtonStyle())
                    } else {
                        Button {
                            store.restoreSeeds()
                        } label: {
                            Label("Load sample library", systemImage: "sparkles")
                        }
                        .buttonStyle(SaviSecondaryButtonStyle())
                    }
                }

                Button(role: .destructive) {
                    store.clearEverything()
                } label: {
                    Label("Delete everything on this device", systemImage: "trash.fill")
                }
                .buttonStyle(SaviDangerButtonStyle())
            }
        }
    }
}

struct FriendsSettingsCard: View {
    @EnvironmentObject private var store: SaviStore
    @State private var friendUsername = ""
    @State private var publicProfilePresented = false
    @State private var webPreview: WebPreviewURL?
    @State private var friendToShow: SaviFriend?
    @State private var linkToSave: SaviSharedLink?

    var body: some View {
        SettingsCard(title: "Social", symbol: "person.2.fill") {
            VStack(alignment: .leading, spacing: 14) {
                socialIntro

                socialFeedSection

                friendsListSection

                FriendSettingsPanel {
                    addFriendControls
                }

                FriendSettingsPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        publicProfileSummary
                        Divider().overlay(SaviTheme.cardStroke)
                        sharingToggle
                    }
                }

                BlockedFriendsPanel()

                syncControls
            }
        }
        .sheet(isPresented: $publicProfilePresented) {
            PublicProfileSheet()
                .environmentObject(store)
        }
        .sheet(item: $webPreview) { preview in
            SafariLinkPreview(url: preview.url)
                .ignoresSafeArea()
        }
        .sheet(item: $friendToShow) { friend in
            FriendProfileSheet(friend: friend)
                .environmentObject(store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $linkToSave) { link in
            FriendLinkSaveSheet(link: link)
                .environmentObject(store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var publicLinkCount: Int {
        store.publicSharedLinks().count
    }

    private var socialIntro: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Friend feed")
                        .font(SaviType.ui(.headline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                    SocialBetaBadge()
                }
                Text("Links your friends chose to publish. Tap a card to open it, or save it to your own SAVI.")
                    .font(SaviType.reading(.caption, weight: .regular))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button {
                Task { await store.syncSocialLinks() }
            } label: {
                Image(systemName: store.isSocialSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.caption.weight(.black))
                    .frame(width: 38, height: 38)
                    .background(SaviTheme.surfaceRaised)
                    .foregroundStyle(SaviTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(SaviPressScaleButtonStyle())
            .disabled(store.isSocialSyncing)
            .accessibilityLabel(store.isSocialSyncing ? "Syncing social feed" : "Sync social feed")
        }
    }

    @ViewBuilder
    private var socialFeedSection: some View {
        if store.visibleFriendLinks.isEmpty {
            FriendSettingsPanel {
                VStack(alignment: .leading, spacing: 8) {
                    Label("No friend links yet", systemImage: "person.2.slash")
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                    Text("Add a friend or sync again when someone shares public Folder links.")
                        .font(SaviType.reading(.caption, weight: .regular))
                        .foregroundStyle(SaviTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Latest")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                    Spacer()
                    Text("\(store.visibleFriendLinks.count)")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                }

                ForEach(store.visibleFriendLinks.prefix(12)) { link in
                    FriendLinkRow(
                        link: link,
                        previewAction: previewLink,
                        saveAction: { linkToSave = $0 }
                    )
                }
            }
        }
    }

    private var publicProfileSummary: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(hex: store.publicProfile.avatarColor))
                .frame(width: 46, height: 46)
                .overlay(
                    Text(store.publicProfile.normalizedUsername.prefix(1).uppercased())
                        .font(SaviType.ui(.headline, weight: .black))
                        .foregroundStyle(SaviTheme.foreground(onHex: store.publicProfile.avatarColor))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(store.publicProfile.displayName.nilIfBlank ?? "SAVI profile")
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                Text("@\(store.publicProfile.normalizedUsername)")
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.accentText)
                Text(store.cloudKitStatus)
                    .font(SaviType.ui(.caption2, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                publicProfilePresented = true
            } label: {
                Label("Edit", systemImage: "pencil")
                    .font(SaviType.ui(.caption, weight: .black))
                    .padding(.horizontal, 12)
                    .frame(minHeight: 38)
                    .background(SaviTheme.surfaceRaised)
                    .foregroundStyle(SaviTheme.accentText)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit public profile")
        }
    }

    private var sharingToggle: some View {
        Toggle(isOn: Binding(
            get: { store.publicProfile.isLinkSharingEnabled },
            set: { store.setLinkSharingEnabled($0) }
        )) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Publish public Folder links")
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text("Apple ID required. Only link previews from public Folders sync. Files, PDFs, images, notes, and locked Folders stay local.")
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(.switch)
        .tint(SaviTheme.chartreuse)
    }

    private var addFriendControls: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Find friends")
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)

            HStack(spacing: 8) {
                TextField("@username", text: $friendUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(SaviType.ui(.subheadline, weight: .bold))
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(SaviTheme.surface)
                    .foregroundStyle(SaviTheme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(SaviTheme.cardStroke, lineWidth: 1)
                    )

                Button {
                    store.addFriend(username: friendUsername)
                    friendUsername = ""
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.black))
                        .frame(width: 44, height: 44)
                        .background(SaviTheme.chartreuse)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add friend")
            }

            Text("Add a SAVI username to see their public link previews in Friends and Explore.")
                .font(SaviType.ui(.caption, weight: .semibold))
                .foregroundStyle(SaviTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var friendsListSection: some View {
        if store.visibleFriends.isEmpty {
            FriendSettingsPanel {
                Label("No friends added yet", systemImage: "person.crop.circle.badge.plus")
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
            }
        } else {
            FriendSettingsPanel {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Friends")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)

                    VStack(spacing: 8) {
                        ForEach(store.visibleFriends) { friend in
                            FriendRow(
                                friend: friend,
                                openAction: { friendToShow = $0 }
                            )
                        }
                    }
                }
            }
        }
    }

    private var syncControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                store.loadSampleFriend()
            } label: {
                Label("Add test friend Ava", systemImage: "person.crop.circle.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviSecondaryButtonStyle())

            if let message = store.socialSyncMessage {
                Text(message)
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
            }
        }
    }

    @ViewBuilder
    private var likedFriendLinksSection: some View {
        if !store.likedFriendLinks.isEmpty {
            Divider().overlay(SaviTheme.cardStroke)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Liked friend links")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                    Spacer()
                    Label("\(store.likedFriendLinks.count)", systemImage: "heart.fill")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.accentText)
                }

                ForEach(store.likedFriendLinks.prefix(3)) { link in
                    FriendLinkRow(
                        link: link,
                        previewAction: previewLink,
                        saveAction: { linkToSave = $0 }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var recentFriendLinksSection: some View {
        if !store.visibleFriendLinks.isEmpty {
            Divider().overlay(SaviTheme.cardStroke)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text("Recent friend links")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                    Spacer()
                    Text("\(store.visibleFriendLinks.count)")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                }

                ForEach(store.visibleFriendLinks.prefix(4)) { link in
                    FriendLinkRow(
                        link: link,
                        previewAction: previewLink,
                        saveAction: { linkToSave = $0 }
                    )
                }
            }
        }
    }

    private func previewLink(_ link: SaviSharedLink) {
        guard let url = store.url(forFriendLink: link) else { return }
        webPreview = WebPreviewURL(url: url)
    }
}

struct FriendSettingsPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SaviTheme.surface.opacity(0.64))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
    }
}

struct BlockedFriendsPanel: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        if store.blockedFriendUsernames.isEmpty {
            EmptyView()
        } else {
            FriendSettingsPanel {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Blocked")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)

                    ForEach(store.blockedFriendUsernames, id: \.self) { username in
                        BlockedFriendRow(username: username)
                    }
                }
            }
        }
    }
}

struct BlockedFriendRow: View {
    @EnvironmentObject private var store: SaviStore
    let username: String

    var body: some View {
        HStack(spacing: 8) {
            Label("@\(username)", systemImage: "hand.raised.fill")
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.text)
            Spacer()
            Button("Unblock") {
                store.unblockFriend(username: username)
            }
            .font(SaviType.ui(.caption, weight: .black))
            .foregroundStyle(SaviTheme.accentText)
        }
    }
}

struct SocialMetricRow: View {
    let friends: Int
    let publicLinks: Int
    let liked: Int

    var body: some View {
        HStack(spacing: 8) {
            SocialMetricPill(value: "\(friends)", label: "Friends", symbol: "person.2.fill")
            SocialMetricPill(value: "\(publicLinks)", label: "Public", symbol: "link")
            SocialMetricPill(value: "\(liked)", label: "Liked", symbol: "heart.fill")
        }
    }
}

struct SocialMetricPill: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(SaviType.ui(.caption2, weight: .black))
                Text(value)
                    .font(SaviType.ui(.headline, weight: .black))
            }
            .foregroundStyle(SaviTheme.text)

            Text(label)
                .font(SaviType.ui(.caption2, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(SaviTheme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct FriendRow: View {
    @EnvironmentObject private var store: SaviStore
    let friend: SaviFriend
    var openAction: ((SaviFriend) -> Void)?

    private var linkCount: Int {
        store.friendLinks(for: friend).count
    }

    private var keeperCount: Int {
        store.friendKeeperSummaries(for: friend).count
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: friend.avatarColor))
                .frame(width: 30, height: 30)
                .overlay(
                    Text(friend.username.prefix(1).uppercased())
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.foreground(onHex: friend.avatarColor))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(friend.username)")
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text("\(keeperCount) public Folder\(keeperCount == 1 ? "" : "s") · \(linkCount) link\(linkCount == 1 ? "" : "s")")
                    .font(SaviType.ui(.caption2, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
            }
            Spacer()
            Button {
                openFriend()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .frame(width: 44, height: 44)
                    .background(SaviTheme.surface)
                    .foregroundStyle(SaviTheme.textMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open @\(friend.username) profile")
            FriendActionsMenu(friend: friend)
        }
        .padding(10)
        .background(SaviTheme.surface.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            openFriend()
        }
    }

    private func openFriend() {
        if let openAction {
            openAction(friend)
        } else {
            store.openFriendProfile(friend)
        }
    }
}

struct FriendActionsMenu: View {
    @EnvironmentObject private var store: SaviStore
    let friend: SaviFriend

    var body: some View {
        Menu {
            Button {
                store.reportFriend(friend)
            } label: {
                Label("Report profile", systemImage: "flag.fill")
            }

            Button(role: .destructive) {
                store.blockFriend(friend)
            } label: {
                Label("Block @\(friend.username)", systemImage: "hand.raised.fill")
            }

            Button(role: .destructive) {
                store.removeFriend(friend)
            } label: {
                Label("Remove friend", systemImage: "person.badge.minus")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.caption.weight(.black))
                .frame(width: 44, height: 44)
                .background(SaviTheme.surface)
                .foregroundStyle(SaviTheme.textMuted)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .accessibilityLabel("Friend actions for @\(friend.username)")
    }
}

struct FriendLinkRow: View {
    @EnvironmentObject private var store: SaviStore
    let link: SaviSharedLink
    var previewAction: ((SaviSharedLink) -> Void)?
    var saveAction: ((SaviSharedLink) -> Void)?

    private var alreadySaved: Bool {
        store.friendLinkAlreadySaved(link)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                previewLink()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    FriendLinkThumbnail(link: link, size: 72, cornerRadius: 16)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(link.title)
                            .font(SaviType.reading(.headline, weight: .semibold))
                            .foregroundStyle(SaviTheme.text)
                            .lineLimit(2)
                            .minimumScaleFactor(0.88)
                            .multilineTextAlignment(.leading)

                        FriendLinkMetaLine(link: link)

                        if let description = link.itemDescription.nilIfBlank {
                            Text(description)
                                .font(SaviType.reading(.caption, weight: .regular))
                                .foregroundStyle(SaviTheme.textMuted)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open \(link.title)")

            HStack(spacing: 8) {
                Text(link.keeperName)
                    .font(SaviType.ui(.caption2, weight: .black))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(SaviTheme.subtleSurface.opacity(0.72))
                    .foregroundStyle(SaviTheme.accentText)
                    .clipShape(Capsule())

                Spacer(minLength: 8)

                FriendFeedActionIcon(
                    symbol: store.isFriendLinkLiked(link) ? "heart.fill" : "heart",
                    active: store.isFriendLinkLiked(link),
                    label: store.isFriendLinkLiked(link) ? "Unlike friend link" : "Like friend link"
                ) {
                    store.toggleLikeFriendLink(link)
                }

                FriendFeedActionIcon(
                    symbol: alreadySaved ? "checkmark.circle.fill" : "plus.circle.fill",
                    active: alreadySaved,
                    label: alreadySaved ? "Already saved" : "Save to my SAVI",
                    disabled: alreadySaved
                ) {
                    saveLink()
                }

                Menu {
                    Button {
                        previewLink()
                    } label: {
                        Label("Open link", systemImage: "safari.fill")
                    }

                    Button(role: .destructive) {
                        store.reportFriendLink(link)
                    } label: {
                        Label("Report link", systemImage: "flag.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption.weight(.black))
                        .frame(width: 36, height: 36)
                        .background(SaviTheme.surfaceRaised)
                        .foregroundStyle(SaviTheme.textMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .accessibilityLabel("More actions for friend link")
            }
        }
        .padding(12)
        .background(SaviTheme.surface.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SaviTheme.cardStroke.opacity(0.82), lineWidth: 1)
        )
    }

    private func previewLink() {
        if let previewAction {
            previewAction(link)
        } else {
            store.previewFriendLink(link)
        }
    }

    private func saveLink() {
        if let saveAction {
            saveAction(link)
        } else {
            store.openFriendLinkSave(link)
        }
    }
}

struct FriendLinkMetaLine: View {
    let link: SaviSharedLink

    var body: some View {
        ViewThatFits(in: .horizontal) {
            fullLine
            compactLine
        }
        .font(SaviType.ui(.caption2, weight: .black))
        .foregroundStyle(SaviTheme.textMuted)
        .lineLimit(1)
        .minimumScaleFactor(0.78)
    }

    private var fullLine: some View {
        HStack(spacing: 5) {
            FriendUsernameBadge(username: link.ownerUsername)
            Label(link.type.label, systemImage: link.type.symbolName)
            Text(link.source)
            SavedAgoText(savedAt: link.sharedAt, prefix: "Posted")
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var compactLine: some View {
        HStack(spacing: 5) {
            FriendUsernameBadge(username: link.ownerUsername)
            Label(link.type.label, systemImage: link.type.symbolName)
            SavedAgoText(savedAt: link.sharedAt)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct FriendUsernameBadge: View {
    let username: String

    var body: some View {
        Text("@\(username)")
            .font(.system(.caption2, design: .monospaced).weight(.black))
            .lineLimit(1)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(Color(hex: "#FFE45E").opacity(0.24))
            .foregroundStyle(SaviTheme.text)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: "#FFE45E").opacity(0.46), lineWidth: 1)
            )
    }
}

struct FriendCompactActionButton: View {
    let title: String
    let symbol: String
    let tint: Color
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(SaviType.ui(.caption, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(SaviTheme.surfaceRaised)
                .foregroundStyle(tint)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(SaviTheme.cardStroke, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.72 : 1)
    }
}

struct FriendCompactIconButton: View {
    let symbol: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline.weight(.bold))
                .frame(width: 44, height: 44)
                .background(SaviTheme.surfaceRaised)
                .foregroundStyle(active ? SaviTheme.accentText : SaviTheme.textMuted)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(active ? SaviTheme.accentText.opacity(0.5) : SaviTheme.cardStroke, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct FriendFeedActionIcon: View {
    let symbol: String
    let active: Bool
    let label: String
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.black))
                .frame(width: 36, height: 36)
                .background(active ? SaviTheme.softAccent : SaviTheme.surfaceRaised)
                .foregroundStyle(active ? .black : SaviTheme.textMuted)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(active ? SaviTheme.accentText.opacity(0.34) : SaviTheme.cardStroke, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.74 : 1)
        .accessibilityLabel(label)
    }
}

struct FriendProfileSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    let friend: SaviFriend
    @State private var selectedKeeperId: String?
    @State private var webPreview: WebPreviewURL?
    @State private var linkToSave: SaviSharedLink?
    @State private var blockConfirmationPresented = false

    private var links: [SaviSharedLink] {
        store.friendLinks(for: friend, keeperId: selectedKeeperId)
    }

    private var allLinks: [SaviSharedLink] {
        store.friendLinks(for: friend)
    }

    private var folders: [SaviFriendKeeperSummary] {
        store.friendKeeperSummaries(for: friend)
    }

    private var likedCount: Int {
        allLinks.filter { store.isFriendLinkLiked($0) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    profileHeader
                    statsRow
                    FriendProfileSafetyActions(friend: friend) {
                        blockConfirmationPresented = true
                    }

                    if folders.isEmpty {
                        EmptyStateView(
                            symbol: "person.2.slash",
                            title: "No public links yet",
                            message: "@\(friend.username) has not shared public Folder links with you yet."
                        )
                    } else {
                        publicFoldersSection
                        publicLinksSection
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("@\(friend.username)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $webPreview) { preview in
                SafariLinkPreview(url: preview.url)
                    .ignoresSafeArea()
            }
            .sheet(item: $linkToSave) { link in
                FriendLinkSaveSheet(link: link)
                    .environmentObject(store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog("Block @\(friend.username)?", isPresented: $blockConfirmationPresented, titleVisibility: .visible) {
                Button("Block @\(friend.username)", role: .destructive) {
                    store.blockFriend(friend)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Their public links will be hidden from Friends and Explore.")
            }
        }
    }

    private var profileHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(Color(hex: friend.avatarColor))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(friend.username.prefix(1).uppercased())
                        .font(SaviType.ui(.title2, weight: .black))
                        .foregroundStyle(SaviTheme.foreground(onHex: friend.avatarColor))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(friend.displayName.nilIfBlank ?? "@\(friend.username)")
                    .font(SaviType.display(size: 30, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("@\(friend.username)")
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.accentText)
                Text("Public links from Folders they chose to share. Files, PDFs, images, and private notes stay out of this feed.")
                    .font(SaviType.ui(.caption, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .saviCard(cornerRadius: 20)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            FriendProfileMetric(value: "\(allLinks.count)", label: "Links")
            FriendProfileMetric(value: "\(folders.count)", label: "Folders")
            FriendProfileMetric(value: "\(likedCount)", label: "Liked")
        }
    }

    private var publicFoldersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Public Folders")
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Spacer()
                Button {
                    selectedKeeperId = nil
                } label: {
                    Text("All")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(selectedKeeperId == nil ? .black : SaviTheme.accentText)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(selectedKeeperId == nil ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(folders) { keeper in
                    FriendKeeperCard(
                        keeper: keeper,
                        active: selectedKeeperId == keeper.id
                    ) {
                        selectedKeeperId = selectedKeeperId == keeper.id ? nil : keeper.id
                    }
                }
            }
        }
    }

    private var publicLinksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(selectedKeeperId.flatMap { id in folders.first(where: { $0.id == id })?.name } ?? "Shared Links")
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Spacer()
                Text("\(links.count)")
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
            }

            LazyVStack(spacing: 10) {
                ForEach(links) { link in
                    FriendProfileLinkCard(
                        link: link,
                        openAction: {
                            if let url = store.url(forFriendLink: link) {
                                webPreview = WebPreviewURL(url: url)
                            }
                        },
                        saveAction: {
                            linkToSave = link
                        },
                        reportAction: {
                            store.reportFriendLink(link)
                        }
                    )
                }
            }
        }
    }
}

struct FriendProfileMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(SaviType.display(size: 25, weight: .black))
                .foregroundStyle(SaviTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
            Text(label)
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(SaviTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
    }
}

struct FriendProfileSafetyActions: View {
    @EnvironmentObject private var store: SaviStore
    let friend: SaviFriend
    let blockAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button {
                store.reportFriend(friend)
            } label: {
                Label("Report", systemImage: "flag.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviSecondaryButtonStyle())

            Button(role: .destructive, action: blockAction) {
                Label("Block", systemImage: "hand.raised.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviSecondaryButtonStyle())
        }
    }
}

struct FriendKeeperCard: View {
    let keeper: SaviFriendKeeperSummary
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "folder.fill")
                        .font(.headline.weight(.black))
                        .frame(width: 34, height: 34)
                        .background(active ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                        .foregroundStyle(active ? .black : SaviTheme.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    Spacer()
                    if active {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SaviTheme.accentText)
                    }
                }

                Text(keeper.name)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(keeper.count) link\(keeper.count == 1 ? "" : "s")")
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .padding(12)
            .background(active ? SaviTheme.surfaceRaised : SaviTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(active ? SaviTheme.chartreuse.opacity(0.75) : SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FriendProfileLinkCard: View {
    @EnvironmentObject private var store: SaviStore
    let link: SaviSharedLink
    let openAction: () -> Void
    let saveAction: () -> Void
    let reportAction: () -> Void

    private var alreadySaved: Bool {
        store.friendLinkAlreadySaved(link)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: openAction) {
                HStack(alignment: .top, spacing: 12) {
                    FriendLinkThumbnail(link: link, size: 72, cornerRadius: 15)

                    VStack(alignment: .leading, spacing: 6) {
                        FriendLinkMetaLine(link: link)

                        Text(link.title)
                            .font(SaviType.reading(.headline, weight: .semibold))
                            .foregroundStyle(SaviTheme.text)
                            .lineLimit(2)
                            .minimumScaleFactor(0.88)
                            .multilineTextAlignment(.leading)

                        if let description = link.itemDescription.nilIfBlank {
                            Text(description)
                                .font(SaviType.ui(.caption, weight: .semibold))
                                .foregroundStyle(SaviTheme.textMuted)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        Text(link.keeperName)
                            .font(SaviType.ui(.caption2, weight: .black))
                            .foregroundStyle(SaviTheme.accentText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()
                .overlay(SaviTheme.cardStroke)

            HStack(spacing: 8) {
                Button(action: openAction) {
                    Label("Open", systemImage: "safari.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FriendActionButtonStyle(tint: SaviTheme.text))

                Button(action: saveAction) {
                    Label(alreadySaved ? "Saved" : "Add", systemImage: alreadySaved ? "checkmark.circle.fill" : "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FriendActionButtonStyle(tint: SaviTheme.accentText))
                .disabled(alreadySaved)

                Button {
                    store.toggleLikeFriendLink(link)
                } label: {
                    Image(systemName: store.isFriendLinkLiked(link) ? "heart.fill" : "heart")
                        .font(.headline.weight(.bold))
                }
                .buttonStyle(FriendIconButtonStyle(active: store.isFriendLinkLiked(link)))
                .accessibilityLabel(store.isFriendLinkLiked(link) ? "Unlike link" : "Like link")

                Button(action: reportAction) {
                    Image(systemName: "flag")
                        .font(.headline.weight(.bold))
                }
                .buttonStyle(FriendIconButtonStyle(active: false))
                .accessibilityLabel("Report link")
            }
        }
        .padding(12)
        .background(SaviTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
    }
}

struct FriendLinkThumbnail: View {
    let link: SaviSharedLink
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let thumbnail = link.thumbnail,
               thumbnail.hasPrefix("http"),
               let url = URL(string: thumbnail) {
                SaviCachedRemoteImage(url: url) {
                    fallback
                }
            } else if let thumbnail = link.thumbnail,
                      let image = SaviImageCache.image(fromDataURL: thumbnail) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var fallback: some View {
        Image(systemName: link.type.symbolName)
            .font(.headline.weight(.black))
            .foregroundStyle(SaviTheme.accentText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SaviTheme.surfaceRaised)
    }
}

struct FriendActionButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaviType.ui(.caption, weight: .black))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
            .background(SaviTheme.surfaceRaised.opacity(configuration.isPressed ? 0.65 : 1))
            .foregroundStyle(tint)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
    }
}

struct FriendIconButtonStyle: ButtonStyle {
    let active: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(active ? SaviTheme.accentText : SaviTheme.textMuted)
            .frame(width: 44, height: 44)
            .background(SaviTheme.surfaceRaised.opacity(configuration.isPressed ? 0.65 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(active ? SaviTheme.accentText.opacity(0.5) : SaviTheme.cardStroke, lineWidth: 1)
            )
    }
}

struct FriendLinkDetailSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    let link: SaviSharedLink
    @State private var webPreview: WebPreviewURL?
    @State private var linkToSave: SaviSharedLink?
    @State private var friendToShow: SaviFriend?

    private var friend: SaviFriend {
        store.friend(for: link)
    }

    private var alreadySaved: Bool {
        store.friendLinkAlreadySaved(link)
    }

    private var liked: Bool {
        store.isFriendLinkLiked(link)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    friendHeader
                    FriendLinkDetailArtwork(link: link)
                    storyContent
                    primaryActions
                    secondaryActions
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Friend Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            store.reportFriendLink(link)
                        } label: {
                            Label("Report link", systemImage: "flag")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More friend link actions")
                }
            }
            .sheet(item: $webPreview) { preview in
                SafariLinkPreview(url: preview.url)
                    .ignoresSafeArea()
            }
            .sheet(item: $linkToSave) { link in
                FriendLinkSaveSheet(link: link)
                    .environmentObject(store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $friendToShow) { friend in
                FriendProfileSheet(friend: friend)
                    .environmentObject(store)
            }
        }
    }

    private var friendHeader: some View {
        Button {
            friendToShow = friend
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: friend.avatarColor))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(friend.username.prefix(1).uppercased())
                            .font(SaviType.ui(.headline, weight: .black))
                            .foregroundStyle(SaviTheme.foreground(onHex: friend.avatarColor))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(friend.displayName.nilIfBlank ?? "@\(friend.username)")
                            .font(SaviType.ui(.title3, weight: .black))
                            .foregroundStyle(Color(hex: "#FFE45E"))
                            .lineLimit(1)
                            .padding(.horizontal, 9)
                            .frame(height: 30)
                            .background(Color.black.opacity(0.82))
                            .clipShape(Capsule())
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.black))
                            .foregroundStyle(SaviTheme.textMuted)
                    }

                    HStack(spacing: 6) {
                        Text("@\(friend.username)")
                        ExploreDot()
                        SavedAgoText(savedAt: link.sharedAt, prefix: "posted")
                    }
                    .font(SaviType.ui(.caption, weight: .bold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(SaviTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("View \(friend.displayName.nilIfBlank ?? friend.username)'s profile")
    }

    private var storyContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            FriendLinkMetaLine(link: link)

            Text(link.title)
                .font(SaviType.reading(.title2, weight: .bold))
                .foregroundStyle(SaviTheme.text)
                .lineLimit(4)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)

            if let description = link.itemDescription.nilIfBlank {
                Text(description)
                    .font(SaviType.reading(.body, weight: .regular))
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(5)
                    .lineSpacing(3)
            }

            HStack(spacing: 8) {
                Text(link.keeperName)
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.accentText)
                    .padding(.horizontal, 9)
                    .frame(height: 28)
                    .background(SaviTheme.surfaceRaised)
                    .clipShape(Capsule())
            }
            .lineLimit(1)
        }
        .padding(14)
        .background(SaviTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
    }

    private var primaryActions: some View {
        VStack(spacing: 10) {
            Button {
                if let url = store.url(forFriendLink: link) {
                    webPreview = WebPreviewURL(url: url)
                }
            } label: {
                Label("Open Link", systemImage: "safari.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviPrimaryButtonStyle())

            Button {
                linkToSave = link
            } label: {
                Label(alreadySaved ? "Already in SAVI" : "Add to My SAVI", systemImage: alreadySaved ? "checkmark.circle.fill" : "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviSecondaryButtonStyle())
            .disabled(alreadySaved)
            .opacity(alreadySaved ? 0.62 : 1)
        }
    }

    private var secondaryActions: some View {
        HStack(spacing: 10) {
            Button {
                store.toggleLikeFriendLink(link)
            } label: {
                Label(liked ? "Liked" : "Like", systemImage: liked ? "heart.fill" : "heart")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviSecondaryButtonStyle())

            Button {
                friendToShow = friend
            } label: {
                Label("View \(friend.displayName.nilIfBlank ?? "@\(friend.username)")", systemImage: "person.crop.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviSecondaryButtonStyle())
        }
    }
}

struct FriendLinkDetailArtwork: View {
    let link: SaviSharedLink

    var body: some View {
        Group {
            if let thumbnail = link.thumbnail,
               thumbnail.hasPrefix("http"),
               let url = URL(string: thumbnail) {
                SaviCachedRemoteImage(url: url) {
                    fallback
                }
            } else if let thumbnail = link.thumbnail,
                      let image = SaviImageCache.image(fromDataURL: thumbnail) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                fallback
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 212)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topLeading) {
            HStack(spacing: 6) {
                Image(systemName: link.type.symbolName)
                    .accessibilityHidden(true)
                Text(link.type.label)
            }
            .font(SaviType.ui(.caption, weight: .black))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Color.black.opacity(0.48))
            .clipShape(Capsule())
            .padding(12)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SaviTheme.surfaceRaised,
                    SaviTheme.softAccent.opacity(0.36)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: link.type.symbolName)
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(SaviTheme.accentText)
        }
    }
}

struct FriendLinkSaveSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    let link: SaviSharedLink
    @State private var selectedFolderId = ""

    private var suggestedFolder: SaviFolder? {
        store.suggestedFolderForFriendLink(link)
    }

    private var alreadySaved: Bool {
        store.friendLinkAlreadySaved(link)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HeaderBlock(
                        eyebrow: "@\(link.ownerUsername)",
                        title: "Add to SAVI",
                        subtitle: "Save a copy of this link into your own library. Likes stay separate.",
                        titleSize: 30
                    )

                    linkPreview

                    if let suggestedFolder {
                        suggestedFolderPanel(suggestedFolder)
                    }

                    FolderPicker(selectedFolderId: $selectedFolderId)

                    Text("Auto uses SAVI's folder brain. Pick a Folder when you want this friend link to land somewhere specific.")
                        .font(SaviType.ui(.footnote, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)

                    Button {
                        saveAndDismiss()
                    } label: {
                        Label(alreadySaved ? "Already saved" : "Add to My SAVI", systemImage: alreadySaved ? "checkmark.circle.fill" : "plus.circle.fill")
                    }
                    .buttonStyle(SaviPrimaryButtonStyle())
                    .disabled(alreadySaved)
                    .opacity(alreadySaved ? 0.55 : 1)
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Add Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(alreadySaved ? "Saved" : "Add") {
                        saveAndDismiss()
                    }
                    .disabled(alreadySaved)
                }
            }
        }
    }

    private func saveAndDismiss() {
        if store.saveFriendLinkToLibrary(link, folderId: selectedFolderId) {
            dismiss()
        }
    }

    private var linkPreview: some View {
        HStack(alignment: .top, spacing: 13) {
            FriendLinkThumbnail(link: link, size: 82, cornerRadius: 18)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    FriendLinkMetaLine(link: link)
                }

                Text(link.title)
                    .font(SaviType.reading(.headline, weight: .semibold))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                if let description = link.itemDescription.nilIfBlank {
                    Text(description)
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(3)
                }
            }
        }
        .padding(13)
        .saviCard(cornerRadius: 18)
    }

    private func suggestedFolderPanel(_ folder: SaviFolder) -> some View {
        Button {
            selectedFolderId = folder.id
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "sparkles")
                    .font(SaviType.ui(.headline, weight: .black))
                    .frame(width: 38, height: 38)
                    .background(SaviTheme.chartreuse)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedFolderId == folder.id ? "Using \(folder.name)" : "Auto suggests \(folder.name)")
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Text("Tap to lock in this Folder, or leave Auto on.")
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: selectedFolderId == folder.id ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.headline.weight(.black))
                    .foregroundStyle(SaviTheme.accentText)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SaviTheme.surfaceRaised.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selectedFolderId == folder.id ? SaviTheme.chartreuse.opacity(0.74) : SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
