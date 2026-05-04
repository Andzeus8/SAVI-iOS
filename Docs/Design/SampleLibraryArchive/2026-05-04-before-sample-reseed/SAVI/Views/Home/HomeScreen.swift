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

struct HomeScreen: View {
    @EnvironmentObject private var store: SaviStore
    @State private var visibleRecentLimit = 40
    @State private var customizeHomePresented = false
    @State private var handledScrollToTopRequest = 0

    var body: some View {
        let allRecentItems = store.filteredItems(for: .home)
        let layoutMode = SaviHomeLayoutMode(rawValue: store.prefs.homeLayoutMode) ?? .timeline
        let folderMode = SaviHomeFolderMode(rawValue: store.prefs.homeFolderMode) ?? .fourGrid
        let recentItems = Array(allRecentItems.prefix(visibleRecentLimit))
        let visibleWidgets = store.visibleHomeWidgets
        let recentGroups = visibleWidgets.contains { $0.widgetKind == .recentSaves }
            ? SaviSavedItemDateGrouper.groups(for: recentItems)
            : []

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Color.clear
                        .frame(height: 0)
                        .id(HomeScrollTarget.top)

                    HomeHeader(saveCount: store.items.count) {
                        customizeHomePresented = true
                    }

                    HomeSearchLauncher()
                        .environmentObject(store)

                    if SaviReleaseGate.demoLibraryEnabled, store.hasSampleLibraryContent {
                        HomeSampleLibraryNotice()
                            .environmentObject(store)
                    }

                    if visibleWidgets.isEmpty {
                        HomeWidgetRecoveryCard {
                            customizeHomePresented = true
                        }
                    } else {
                        ForEach(visibleWidgets) { widget in
                            HomeWidgetHost(
                                widget: widget,
                                allRecentItems: allRecentItems,
                                recentGroups: recentGroups,
                                layoutMode: layoutMode,
                                folderMode: folderMode,
                                visibleRecentCount: recentItems.count,
                                totalRecentCount: allRecentItems.count,
                                loadMoreRecentItems: loadMoreRecentItems
                            )
                            .id(widget.id)
                            .environmentObject(store)
                        }
                    }

                    if allRecentItems.isEmpty {
                        EmptyStateView(
                            symbol: "tray.fill",
                            title: "Nothing saved yet",
                            message: "Use Add or the iOS share sheet and SAVI will start filling this space."
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, -10)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
            .onAppear {
                handleScrollToTopIfNeeded(proxy: proxy, animated: false)
            }
            .onChange(of: store.homeScrollToTopRequest) { _ in
                handleScrollToTopIfNeeded(proxy: proxy, animated: true)
            }
            .sheet(isPresented: $customizeHomePresented) {
                HomeWidgetBuilderSheet()
                    .environmentObject(store)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func loadMoreRecentItems(total: Int) {
        guard visibleRecentLimit < total else { return }
        visibleRecentLimit = min(visibleRecentLimit + 32, total)
    }

    private func handleScrollToTopIfNeeded(proxy: ScrollViewProxy, animated: Bool) {
        guard handledScrollToTopRequest != store.homeScrollToTopRequest else { return }
        handledScrollToTopRequest = store.homeScrollToTopRequest

        if animated {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                proxy.scrollTo(HomeScrollTarget.top, anchor: .top)
            }
        } else {
            proxy.scrollTo(HomeScrollTarget.top, anchor: .top)
        }
    }
}

private enum HomeScrollTarget {
    static let top = "home-scroll-top"
}

private struct HomeWidgetHost: View {
    @EnvironmentObject private var store: SaviStore
    let widget: SaviHomeWidgetConfig
    let allRecentItems: [SaviItem]
    let recentGroups: [SaviSavedItemDateGroup]
    let layoutMode: SaviHomeLayoutMode
    let folderMode: SaviHomeFolderMode
    let visibleRecentCount: Int
    let totalRecentCount: Int
    let loadMoreRecentItems: (Int) -> Void

    var body: some View {
        switch widget.widgetKind {
        case .latestSaves:
            LatestSavesWidget(items: allRecentItems, size: widget.widgetSize)
        case .folders:
            FoldersWidget(size: widget.widgetSize, folderMode: folderMode)
        case .recentSaves:
            RecentSavesWidget(
                groups: recentGroups,
                layoutMode: layoutMode,
                visibleCount: visibleRecentCount,
                totalCount: totalRecentCount,
                loadMore: loadMoreRecentItems
            )
        case .pinnedFolder:
            PinnedFolderWidget(widget: widget, items: allRecentItems)
        case .searchShortcuts:
            SearchShortcutsWidget(size: widget.widgetSize)
        case .friendActivity:
            if SaviReleaseGate.socialFeaturesEnabled {
                FriendActivityWidget(size: widget.widgetSize)
            }
        }
    }
}

private struct LatestSavesWidget: View {
    let items: [SaviItem]
    let size: SaviHomeWidgetSize

    private var visibleItems: [SaviItem] {
        Array(items.prefix(size == .large ? 3 : 2))
    }

    var body: some View {
        if !visibleItems.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Just Saved")

                if size == .compact {
                    VStack(spacing: 8) {
                        ForEach(visibleItems.prefix(2)) { item in
                            LatestSaveCompactRow(item: item)
                        }
                    }
                } else if visibleItems.count == 1, let item = visibleItems.first {
                    LatestSaveMiniCard(item: item, size: .medium)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 10
                    ) {
                        ForEach(visibleItems.prefix(2)) { item in
                            LatestSaveMiniCard(item: item, size: size)
                        }
                    }

                    if size == .large, visibleItems.count > 2, let item = visibleItems.dropFirst(2).first {
                        SaveCard(item: item)
                    }
                }
            }
        }
    }
}

private struct LatestSaveMiniCard: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let item: SaviItem
    let size: SaviHomeWidgetSize

    private var cardHeight: CGFloat {
        switch size {
        case .compact: return 112
        case .medium: return 142
        case .large: return 156
        }
    }

    var body: some View {
        Button {
            store.presentItem(item)
        } label: {
            ZStack(alignment: .bottomLeading) {
                ItemThumb(item: item, large: true, enablesPressPreview: false)
                    .frame(maxWidth: .infinity)
                    .frame(height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                LinearGradient(
                    colors: [.black.opacity(0.08), .black.opacity(0.76)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 7) {
                    Text(SaviItemDisplay.rowTitle(for: item))
                        .font(SaviType.reading(.callout, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .lineSpacing(1.5)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        if let folder = store.folder(for: item.folderId) {
                            KeeperPill(folder: folder, maxWidth: 104)
                        }
                        Spacer(minLength: 4)
                        TimelineView(.periodic(from: Date(), by: 60)) { context in
                            Text(SaviText.compactRelativeSavedTime(item.savedAt, now: context.date))
                                .font(SaviItemTypography.meta)
                                .foregroundStyle(.white.opacity(0.82))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(11)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.24 : 0.58), lineWidth: 1)
            )
            .shadow(color: SaviTheme.cardShadow.opacity(colorScheme == .light ? 0.1 : 0.22), radius: 12, x: 0, y: 7)
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("Latest save, \(SaviItemDisplay.rowTitle(for: item))")
    }
}

private struct LatestSaveCompactRow: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let item: SaviItem

    var body: some View {
        Button {
            store.presentItem(item)
        } label: {
            HStack(alignment: .center, spacing: 10) {
                ItemThumb(item: item, enablesPressPreview: false)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.24 : 0.5), lineWidth: 1)
                    )
                    .saviThumbnailTypeBadge(for: item, padding: 3)

                VStack(alignment: .leading, spacing: 6) {
                    Text(SaviItemDisplay.rowTitle(for: item))
                        .font(SaviType.reading(.subheadline, weight: .bold))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 7) {
                        if let folder = store.folder(for: item.folderId) {
                            KeeperPill(folder: folder, maxWidth: 108)
                                .layoutPriority(2)
                        }

                        Text(store.primaryKindLabel(for: item))
                            .font(SaviItemTypography.meta)
                            .foregroundStyle(SaviTheme.metadataText)
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        SavedTimeCornerLabel(savedAt: item.savedAt)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(9)
            .frame(minHeight: 70, alignment: .center)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.26 : 0.46), lineWidth: 1)
            )
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("Just saved, \(SaviItemDisplay.rowTitle(for: item))")
    }

    private var rowBackground: Color {
        colorScheme == .light ? Color.white.opacity(0.58) : SaviTheme.surface.opacity(0.36)
    }
}

private struct FoldersWidget: View {
    @EnvironmentObject private var store: SaviStore
    let size: SaviHomeWidgetSize
    let folderMode: SaviHomeFolderMode

    private var folderLimit: Int {
        switch size {
        case .compact: return 4
        case .medium: return 4
        case .large: return 6
        }
    }

    var body: some View {
        FolderStrip(title: "Recent Folders", folders: store.homeFolders())
    }
}

private struct RecentSavesWidget: View {
    @EnvironmentObject private var store: SaviStore
    let groups: [SaviSavedItemDateGroup]
    let layoutMode: SaviHomeLayoutMode
    let visibleCount: Int
    let totalCount: Int
    let loadMore: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SaviHomeSectionHeader(title: "Recent Saves", actionTitle: "Search") {
                store.resetFilters()
                store.setTab(.search)
            }

            LazyVStack(alignment: .leading, spacing: verticalSpacing) {
                ForEach(groups) { group in
                    switch layoutMode {
                    case .cards:
                        SavedItemDateGroupLabel(title: group.title)
                            .padding(.top, group.id == groups.first?.id ? 0 : 6)

                        ForEach(group.items) { item in
                            RecentSaveScanCard(item: item)
                        }
                    case .featured:
                        TimelineGroupLabel(title: group.title)
                            .padding(.top, group.id == groups.first?.id ? 0 : 10)

                        if let leadItem = group.items.first {
                            RecentSaveDigestCard(item: leadItem)
                        }

                        ForEach(Array(group.items.dropFirst())) { item in
                            EditorialTimelineItemRow(item: item, context: .home)
                        }
                    case .timeline:
                        SaviFluidTimelineGroup(
                            title: group.title,
                            items: group.items,
                            context: .home
                        )
                        .padding(.top, group.id == groups.first?.id ? 0 : 8)
                    }
                }

                if visibleCount < totalCount {
                    FeedPageLoader(label: "Loading more saves") {
                        loadMore(totalCount)
                    }
                    .id("home-more-\(visibleCount)-\(totalCount)")
                }
            }
        }
    }

    private var verticalSpacing: CGFloat {
        switch layoutMode {
        case .timeline: return 8
        case .cards: return 9
        case .featured: return 8
        }
    }
}

private struct RecentSaveScanCard: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let item: SaviItem

    var body: some View {
        Button {
            store.presentItem(item)
        } label: {
            HStack(alignment: .center, spacing: 10) {
                ItemThumb(item: item, enablesPressPreview: false)
                    .frame(width: 74, height: 74)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.24 : 0.52), lineWidth: 1)
                    )
                    .saviThumbnailTypeBadge(for: item)

                VStack(alignment: .leading, spacing: 6) {
                    Text(SaviItemDisplay.rowTitle(for: item))
                        .font(SaviType.reading(.subheadline, weight: .bold))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(2)
                        .lineSpacing(1.5)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(2)

                    ItemSnippetLine(item: item, context: .home)
                        .lineLimit(1)
                        .layoutPriority(1)

                    ItemTokenRow(
                        item: item,
                        folder: store.folder(for: item.folderId),
                        tags: item.tags,
                        hidesTags: true
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                SavedTimeCornerLabel(savedAt: item.savedAt)
                    .frame(width: 38, alignment: .trailing)
            }
            .padding(10)
            .frame(minHeight: 94, alignment: .center)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.25 : 0.58), lineWidth: 1)
            )
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("\(SaviItemDisplay.rowTitle(for: item)), saved \(SaviText.relativeSavedTime(item.savedAt))")
    }

    private var cardBackground: Color {
        colorScheme == .light ? Color.white.opacity(0.62) : SaviTheme.surface.opacity(0.36)
    }
}

private struct RecentSaveDigestCard: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let item: SaviItem

    var body: some View {
        Button {
            store.presentItem(item)
        } label: {
            ZStack(alignment: .bottomLeading) {
                ItemThumb(item: item, large: true, enablesPressPreview: false)
                    .frame(maxWidth: .infinity)
                    .frame(height: 154)
                    .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))

                LinearGradient(
                    colors: [.black.opacity(0.02), .black.opacity(0.78)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        ItemTypeSourceText(item: item)
                            .foregroundStyle(.white.opacity(0.80))
                        Spacer(minLength: 8)
                        TimelineView(.periodic(from: Date(), by: 60)) { context in
                            Text(SaviText.compactRelativeSavedTime(item.savedAt, now: context.date))
                                .font(SaviItemTypography.meta)
                                .foregroundStyle(.white.opacity(0.82))
                                .lineLimit(1)
                        }
                    }

                    Text(SaviItemDisplay.rowTitle(for: item))
                        .font(SaviType.reading(.title3, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)

                    if let folder = store.folder(for: item.folderId) {
                        KeeperPill(folder: folder, maxWidth: 142)
                    }
                }
                .padding(13)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.24 : 0.58), lineWidth: 1)
            )
            .shadow(
                color: SaviTheme.cardShadow.opacity(colorScheme == .light ? 0.10 : 0.20),
                radius: 12,
                x: 0,
                y: 7
            )
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("Featured recent save, \(SaviItemDisplay.rowTitle(for: item))")
    }
}

private struct PinnedFolderWidget: View {
    @EnvironmentObject private var store: SaviStore
    let widget: SaviHomeWidgetConfig
    let items: [SaviItem]

    private var folder: SaviFolder? {
        widget.folderId.flatMap { store.folder(for: $0) } ?? store.homeFolders(limit: 1).first
    }

    private var visibleItems: [SaviItem] {
        guard let folder else { return [] }
        let limit: Int = widget.widgetSize == .large ? 5 : widget.widgetSize == .medium ? 3 : 2
        return Array(items.filter { $0.folderId == folder.id }.prefix(limit))
    }

    var body: some View {
        if let folder {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: widget.title?.nilIfBlank ?? folder.name, actionTitle: "Open") {
                    store.openFolder(folder)
                }

                if visibleItems.isEmpty {
                    EmptyStateView(
                        symbol: folder.symbolName,
                        title: "Nothing here yet",
                        message: "New saves in \(folder.name) will show up here."
                    )
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(visibleItems) { item in
                            SaveCard(item: item)
                        }
                    }
                }
            }
        }
    }
}

private struct SearchShortcutsWidget: View {
    @EnvironmentObject private var store: SaviStore
    let size: SaviHomeWidgetSize

    private var shortcuts: [SaviSearchKind] {
        Array(SaviSearchKind.visibleRail.filter { $0.id != "all" }.prefix(size == .large ? 7 : 5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Find Fast")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                ForEach(shortcuts) { kind in
                    Button {
                        store.resetFilters()
                        store.typeFilter = kind.id
                        store.setTab(.search)
                    } label: {
                        Label(kind.title, systemImage: kind.symbolName)
                            .font(SaviType.ui(.subheadline, weight: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(SaviTheme.surfaceRaised)
                            .foregroundStyle(SaviTheme.text)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(SaviTheme.cardStroke.opacity(0.72), lineWidth: 1)
                            )
                    }
                    .buttonStyle(SaviPressScaleButtonStyle())
                }
            }
        }
    }
}

private struct FriendActivityWidget: View {
    @EnvironmentObject private var store: SaviStore
    let size: SaviHomeWidgetSize

    private var links: [SaviSharedLink] {
        Array(store.visibleFriendLinks.sorted { $0.sharedAt > $1.sharedAt }.prefix(size == .large ? 4 : 2))
    }

    var body: some View {
        if !links.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "From Friends", actionTitle: "Social") {
                    store.setTab(.profile)
                }

                LazyVStack(spacing: 12) {
                    ForEach(links) { link in
                        FriendActivityRow(link: link)
                    }
                }
            }
        }
    }
}

private struct FriendActivityRow: View {
    @EnvironmentObject private var store: SaviStore
    let link: SaviSharedLink

    private var friend: SaviFriend {
        store.friend(for: link)
    }

    private var alreadySaved: Bool {
        store.friendLinkAlreadySaved(link)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Button {
                store.openFriendLinkDetail(link)
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        FriendActivityAvatar(friend: friend)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(friend.displayName)
                                .font(SaviType.ui(.caption, weight: .black))
                                .foregroundStyle(SaviTheme.text)
                                .lineLimit(1)

                            Text("@\(link.ownerUsername)")
                                .font(.system(.caption2, design: .monospaced).weight(.black))
                                .foregroundStyle(Color(hex: "#EBCB24"))
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        TimelineView(.periodic(from: Date(), by: 60)) { context in
                            Text(SaviText.compactRelativeSavedTime(link.sharedAt, now: context.date))
                                .font(SaviItemTypography.meta)
                                .foregroundStyle(SaviTheme.metadataText)
                                .lineLimit(1)
                        }
                    }

                    HStack(alignment: .center, spacing: 12) {
                        FriendLinkThumbnail(link: link, size: 70, cornerRadius: 16)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(link.title)
                                .font(SaviType.reading(.subheadline, weight: .bold))
                                .foregroundStyle(SaviTheme.text)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)

                            if let description = link.itemDescription.nilIfBlank {
                                Text(description)
                                    .font(SaviType.reading(.caption, weight: .regular))
                                    .foregroundStyle(SaviTheme.textMuted)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.leading)
                            }

                            HStack(spacing: 6) {
                                FriendActivityToken(text: link.keeperName, isFolder: true)
                                FriendActivityToken(text: link.type.label, systemImage: link.type.symbolName)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open friend link from \(friend.displayName), \(link.title)")

            HStack(spacing: 8) {
                Text(link.source)
                    .font(SaviItemTypography.meta)
                    .foregroundStyle(SaviTheme.metadataText)
                    .lineLimit(1)

                Spacer(minLength: 8)

                FriendActivityIconButton(
                    symbol: store.isFriendLinkLiked(link) ? "heart.fill" : "heart",
                    active: store.isFriendLinkLiked(link),
                    label: store.isFriendLinkLiked(link) ? "Unlike friend link" : "Like friend link"
                ) {
                    store.toggleLikeFriendLink(link)
                }

                FriendActivityIconButton(
                    symbol: alreadySaved ? "checkmark.circle.fill" : "plus.circle.fill",
                    active: alreadySaved,
                    label: alreadySaved ? "Already saved" : "Save to my SAVI",
                    disabled: alreadySaved
                ) {
                    store.openFriendLinkSave(link)
                }
            }
        }
        .padding(12)
        .background(SaviTheme.surface.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SaviTheme.cardStroke.opacity(0.74), lineWidth: 1)
        )
        .shadow(color: SaviTheme.cardShadow.opacity(0.08), radius: 10, x: 0, y: 6)
    }
}

private struct FriendActivityAvatar: View {
    let friend: SaviFriend

    private var initials: String {
        let source = friend.displayName.nilIfBlank ?? friend.username
        let parts = source
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
        let value = String(parts).uppercased()
        return value.isEmpty ? "@" : value
    }

    var body: some View {
        Text(initials)
            .font(SaviType.ui(.caption2, weight: .black))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: friend.avatarColor),
                        Color(hex: "#7C3AED")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.34), lineWidth: 1)
            )
    }
}

private struct FriendActivityToken: View {
    let text: String
    var systemImage: String?
    var isFolder = false

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.black))
            }
            Text(text)
                .lineLimit(1)
        }
        .font(SaviType.ui(.caption2, weight: .black))
        .padding(.horizontal, 7)
        .frame(height: 22)
        .background(isFolder ? SaviTheme.softAccent : SaviTheme.subtleSurface.opacity(0.76))
        .foregroundStyle(isFolder ? SaviTheme.accentText : SaviTheme.metadataText)
        .clipShape(Capsule())
    }
}

private struct FriendActivityIconButton: View {
    let symbol: String
    let active: Bool
    let label: String
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.caption.weight(.black))
                .frame(width: 32, height: 32)
                .background(active ? SaviTheme.softAccent : SaviTheme.surfaceRaised)
                .foregroundStyle(active ? SaviTheme.accentText : SaviTheme.textMuted)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(active ? SaviTheme.accentText.opacity(0.38) : SaviTheme.cardStroke.opacity(0.86), lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.72 : 1)
        .accessibilityLabel(label)
    }
}

private struct HomeWidgetRecoveryCard: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.title2.weight(.black))
                .foregroundStyle(SaviTheme.accentText)
            Text("Build your Home")
                .font(SaviType.ui(.title3, weight: .black))
                .foregroundStyle(SaviTheme.text)
            Text(SaviReleaseGate.socialFeaturesEnabled
                ? "Add folders, latest saves, shortcuts, or friend activity back to this screen."
                : "Add folders, latest saves, or search shortcuts back to this screen.")
                .font(SaviType.ui(.subheadline, weight: .semibold))
                .foregroundStyle(SaviTheme.textMuted)
            Button(action: action) {
                Label("Add widgets", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviPrimaryButtonStyle())
        }
        .padding(16)
        .saviCard(cornerRadius: 20)
    }
}

private struct HomeFolderGrid: View {
    @EnvironmentObject private var store: SaviStore
    let title: String
    let folders: [SaviFolder]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: SaviSpacing.md) {
            SectionHeader(title: title, actionTitle: "See all") {
                store.openFoldersManagement()
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(folders) { folder in
                    HomeFolderGridTile(folder: folder)
                }
            }
        }
    }
}

private struct HomeFolderGridTile: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let folder: SaviFolder

    private var isLocked: Bool {
        folder.locked && !store.isProtectedKeeperUnlocked(folder)
    }

    var body: some View {
        let style = SaviFolderVisualStyle.make(for: folder, colorScheme: colorScheme)
        Button {
            store.openFolder(folder)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                        FolderIconBadge(
                            symbolName: folder.symbolName,
                            color: style.baseHex,
                            imageDataURL: folder.usesImageBackground ? nil : folder.image,
                            size: SaviFolderTileMetrics.iconSize,
                            cornerRadius: SaviFolderTileMetrics.iconCornerRadius,
                            font: SaviFolderTileMetrics.iconFont,
                            background: style.iconBackground,
                            foreground: style.iconForeground,
                            publicBadgeStyle: SaviReleaseGate.socialFeaturesEnabled && folder.isPublic ? style : nil
                        )

                    Spacer(minLength: 0)

                    if folder.locked {
                        Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(style.countForeground)
                            .frame(width: 22, height: 22)
                            .background(style.countBackground)
                            .clipShape(Circle())
                    }
                }

                Spacer(minLength: 0)

                SaviFolderTitleText(name: folder.name, style: style)
            }
            .padding(11)
            .frame(maxWidth: .infinity, minHeight: SaviFolderTileMetrics.tileHeight, maxHeight: SaviFolderTileMetrics.tileHeight, alignment: .leading)
            .background(FolderTileBackground(folder: folder, style: style))
            .clipShape(RoundedRectangle(cornerRadius: SaviRadius.folder, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SaviRadius.folder, style: .continuous)
                    .stroke(style.stroke, lineWidth: colorScheme == .light ? 1.15 : 1)
            )
            .shadow(
                color: style.shadow,
                radius: SaviShadow.folderRadius(colorScheme),
                x: 0,
                y: SaviShadow.folderY(colorScheme)
            )
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("\(folder.name), \(SaviReleaseGate.socialFeaturesEnabled && folder.isPublic ? "Public, " : "")\(isLocked ? "Locked" : "\(store.count(in: folder)) saves")")
    }
}

private struct TimelineGroupLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 7, weight: .black))
                    .foregroundStyle(SaviTheme.metadataText.opacity(0.55))
                Circle()
                    .fill(SaviTheme.chartreuse.opacity(0.72))
                    .frame(width: 8, height: 8)
            }
            .frame(width: 44, alignment: .trailing)

            Text(title.uppercased())
                .font(SaviType.ui(.caption2, weight: .black))
                .foregroundStyle(SaviTheme.metadataText)
                .tracking(0.8)

            Spacer()
        }
        .accessibilityAddTraits(.isHeader)
    }
}

private struct FeaturedSaveCard: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let item: SaviItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Most Recent Save")

            Button {
                store.presentItem(item)
            } label: {
                ZStack(alignment: .bottomLeading) {
                    ItemThumb(item: item, large: true, enablesPressPreview: false)
                        .frame(maxWidth: .infinity)
                        .frame(height: 178)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    LinearGradient(
                        colors: [.black.opacity(0), .black.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(SaviItemDisplay.rowTitle(for: item))
                            .font(SaviType.reading(.title3, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .lineSpacing(2)

                        HStack(spacing: 8) {
                            if let folder = store.folder(for: item.folderId) {
                                KeeperPill(folder: folder, maxWidth: 132)
                            }
                            Text(store.primaryKindLabel(for: item))
                                .font(SaviItemTypography.meta)
                                .foregroundStyle(.white.opacity(0.78))
                                .lineLimit(1)
                            Spacer()
                            TimelineView(.periodic(from: Date(), by: 60)) { context in
                                Text(SaviText.compactRelativeSavedTime(item.savedAt, now: context.date))
                                    .font(SaviItemTypography.meta)
                                    .foregroundStyle(.white.opacity(0.78))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.76)
                            }
                        }
                    }
                    .padding(14)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.24 : 0.58), lineWidth: 1)
                )
                .shadow(
                    color: SaviTheme.cardShadow.opacity(colorScheme == .light ? 0.12 : 0.24),
                    radius: 14,
                    x: 0,
                    y: 8
                )
            }
            .buttonStyle(SaviPressScaleButtonStyle())
            .accessibilityLabel("Most recent save, \(SaviItemDisplay.rowTitle(for: item))")
        }
    }
}

private struct HomeHeader: View {
    let saveCount: Int
    var customizeAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 12) {
                Text("SAVI")
                    .font(SaviType.display(size: 27, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 10)

                HStack(spacing: 8) {
                    PillBadge(
                        title: "\(saveCount) saves",
                        systemImage: "tray.full.fill",
                        foreground: SaviTheme.metadataText,
                        background: SaviTheme.subtleSurface.opacity(0.62),
                        stroke: SaviTheme.cardStroke.opacity(0.66),
                        height: 25
                    )
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityLabel("\(saveCount) saves")

                    if let customizeAction {
                        Button(action: customizeAction) {
                            Image(systemName: "slider.horizontal.3")
                                .font(SaviType.ui(.caption, weight: .bold))
                                .frame(width: 30, height: 30)
                                .foregroundStyle(SaviTheme.accentText.opacity(0.82))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(SaviPressScaleButtonStyle())
                        .accessibilityLabel("Customize Home widgets")
                    }
                }
            }

            Text("Save anything. Find it instantly.")
                .font(SaviType.ui(.subheadline, weight: .semibold))
                .foregroundStyle(SaviTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 0)
    }
}

private struct HomeSearchLauncher: View {
    @EnvironmentObject private var store: SaviStore

    private let quickFilters: [HomeSearchQuickFilter] = [
        .init(title: "All", symbolName: "tray.full.fill", typeFilter: "all", isPrimary: true),
        .init(title: "Links", symbolName: "link", typeFilter: "link"),
        .init(title: "Docs", symbolName: "doc.on.doc.fill", typeFilter: "docs"),
        .init(title: "Images", symbolName: "photo.fill", typeFilter: "image"),
        .init(title: "Videos", symbolName: "play.rectangle.fill", typeFilter: "video")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                Button {
                    store.startHomeSearch()
                } label: {
                    HStack(spacing: 11) {
                        Image(systemName: "magnifyingglass")
                            .font(SaviType.ui(.title3, weight: .bold))
                            .foregroundStyle(SaviTheme.metadataText)

                        Text("Search titles, folders, tags, PDFs...")
                            .font(SaviType.ui(.subheadline, weight: .semibold))
                            .foregroundStyle(SaviTheme.metadataText)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(SaviPressScaleButtonStyle(scale: 0.985))
                .accessibilityLabel("Search SAVI")

                Button {
                    store.startHomeRefine()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.accentText)
                        .frame(width: 38, height: 38)
                        .background(SaviTheme.subtleSurface.opacity(0.74))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(SaviTheme.cardStroke.opacity(0.55), lineWidth: 1)
                        )
                }
                .buttonStyle(SaviPressScaleButtonStyle(scale: 0.96))
                .accessibilityLabel("Open search filters")
            }
            .padding(.leading, 15)
            .padding(.trailing, 6)
            .frame(minHeight: 48)
            .background(SaviTheme.inputSurface.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(SaviTheme.cardStroke.opacity(0.72), lineWidth: 1)
            )

            ZStack(alignment: .trailing) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickFilters) { filter in
                            HomeSearchQuickChip(filter: filter) {
                                store.startHomeSearch(typeFilter: filter.typeFilter)
                            }
                        }

                        HomeSearchMoreChip {
                            store.startHomeRefine()
                        }
                    }
                    .padding(.trailing, 24)
                }

                LinearGradient(
                    colors: [SaviTheme.background.opacity(0), SaviTheme.background],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 24)
                .allowsHitTesting(false)
            }
        }
    }
}

private struct HomeSampleLibraryNotice: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "sparkles")
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.accentText)
                .frame(width: 26, height: 26)
                .background(SaviTheme.chartreuse.opacity(colorScheme == .light ? 0.18 : 0.26))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text("Sample saves are included so you can explore SAVI.")
                .font(SaviType.ui(.caption, weight: .semibold))
                .foregroundStyle(SaviTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 6)

            Button("Clear") {
                store.clearDemoContent()
            }
            .font(SaviType.ui(.caption, weight: .black))
            .foregroundStyle(SaviTheme.accentText)
            .buttonStyle(.plain)
            .accessibilityLabel("Clear sample saves")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(SaviTheme.subtleSurface.opacity(colorScheme == .light ? 0.58 : 0.34))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.42 : 0.62), lineWidth: 1)
        )
    }
}

private struct HomeSearchQuickFilter: Identifiable {
    let title: String
    let symbolName: String
    let typeFilter: String
    var isPrimary = false

    var id: String { typeFilter }
}

private struct HomeSearchQuickChip: View {
    let filter: HomeSearchQuickFilter
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.symbolName)
                    .font(SaviType.ui(.caption, weight: .black))
                    .accessibilityHidden(true)
                Text(filter.title)
                    .lineLimit(1)
            }
            .font(SaviType.ui(.caption, weight: .bold))
            .foregroundStyle(filter.isPrimary ? .black : SaviTheme.text)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(filter.isPrimary ? SaviTheme.softAccent : SaviTheme.surface.opacity(0.82))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(filter.isPrimary ? Color.clear : SaviTheme.cardStroke.opacity(0.72), lineWidth: 1)
            )
        }
        .buttonStyle(SaviPressScaleButtonStyle(scale: 0.97))
        .accessibilityLabel("Search \(filter.title)")
    }
}

private struct HomeSearchMoreChip: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("More")
                Image(systemName: "chevron.down")
                    .font(SaviType.ui(.caption2, weight: .black))
                    .accessibilityHidden(true)
            }
            .font(SaviType.ui(.caption, weight: .bold))
            .foregroundStyle(SaviTheme.text)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(SaviTheme.surface.opacity(0.82))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(SaviTheme.cardStroke.opacity(0.72), lineWidth: 1))
        }
        .buttonStyle(SaviPressScaleButtonStyle(scale: 0.97))
        .accessibilityLabel("More search filters")
    }
}

struct HomeWidgetBuilderSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @State private var addWidgetPresented = false
    @State private var editMode: EditMode = .active

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.prefs.homeWidgets) { widget in
                        HomeWidgetBuilderRow(widget: widget)
                            .environmentObject(store)
                    }
                    .onMove { source, destination in
                        store.moveHomeWidget(from: source, to: destination)
                    }
                } header: {
                    Text("Home widgets")
                } footer: {
                    Text("Drag to reorder. Hidden widgets stay saved here so you can bring them back later.")
                }

                Section {
                    Button {
                        addWidgetPresented = true
                    } label: {
                        Label("Add Widget", systemImage: "plus.circle.fill")
                    }

                    Button {
                        store.resetHomeWidgets()
                    } label: {
                        Label("Reset Home", systemImage: "arrow.clockwise")
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Customize Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $addWidgetPresented) {
                AddHomeWidgetSheet()
                    .environmentObject(store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

private struct HomeWidgetBuilderRow: View {
    @EnvironmentObject private var store: SaviStore
    let widget: SaviHomeWidgetConfig

    private var kind: SaviHomeWidgetKind {
        widget.widgetKind
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 12) {
                Image(systemName: kind.symbolName)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(SaviTheme.accentText)
                    .frame(width: 34, height: 34)
                    .background(SaviTheme.subtleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(displayTitle)
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                    Text(widget.widgetSize.title)
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { !widget.isHidden },
                    set: { store.setHomeWidgetHidden(widget, hidden: !$0) }
                ))
                .labelsHidden()
                .tint(SaviTheme.chartreuse)
            }

            Picker("Size", selection: Binding(
                get: { widget.widgetSize },
                set: { store.setHomeWidgetSize(widget, size: $0) }
            )) {
                ForEach(SaviHomeWidgetSize.allCases) { size in
                    Text(size.title).tag(size)
                }
            }
            .pickerStyle(.segmented)

            if kind == .pinnedFolder {
                Picker("Folder", selection: Binding(
                    get: { widget.folderId ?? store.homeFolders(limit: 1).first?.id ?? "" },
                    set: { store.setHomeWidgetPinnedFolder(widget, folderId: $0) }
                )) {
                    ForEach(store.orderedFoldersForDisplay()) { folder in
                        Text(folder.name).tag(folder.id)
                    }
                }
            }

            Button(role: .destructive) {
                store.deleteHomeWidget(widget)
            } label: {
                Label("Remove", systemImage: "trash")
                    .font(SaviType.ui(.caption, weight: .black))
            }
        }
        .padding(.vertical, 5)
    }

    private var displayTitle: String {
        if kind == .pinnedFolder, let folderId = widget.folderId, let folder = store.folder(for: folderId) {
            return folder.name
        }
        return widget.title?.nilIfBlank ?? kind.title
    }
}

private struct AddHomeWidgetSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @State private var kind: SaviHomeWidgetKind = .latestSaves
    @State private var size: SaviHomeWidgetSize = .compact
    @State private var folderId: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Widget") {
                    Picker("Type", selection: $kind) {
                        ForEach(SaviHomeWidgetKind.allCases) { option in
                            Label(option.title, systemImage: option.symbolName)
                                .tag(option)
                        }
                    }

                    Picker("Size", selection: $size) {
                        ForEach(SaviHomeWidgetSize.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    if kind == .pinnedFolder {
                        Picker("Folder", selection: Binding(
                            get: { selectedFolderId },
                            set: { folderId = $0 }
                        )) {
                            ForEach(store.orderedFoldersForDisplay()) { folder in
                                Text(folder.name).tag(folder.id)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        store.addHomeWidget(
                            kind: kind,
                            size: size,
                            folderId: kind == .pinnedFolder ? selectedFolderId : nil,
                            title: kind == .pinnedFolder ? store.folder(for: selectedFolderId)?.name : nil
                        )
                        dismiss()
                    } label: {
                        Label("Add to Home", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Add Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if folderId.isEmpty {
                    folderId = store.homeFolders(limit: 1).first?.id ?? ""
                }
                size = kind.defaultSize
            }
            .onChange(of: kind) { newKind in
                size = newKind.defaultSize
            }
        }
    }

    private var selectedFolderId: String {
        folderId.nilIfBlank ?? store.homeFolders(limit: 1).first?.id ?? ""
    }
}
