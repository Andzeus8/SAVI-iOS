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

struct SaviHomeSectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(SaviType.ui(.title3, weight: .bold))
                .foregroundStyle(SaviTheme.text)

            Spacer(minLength: 12)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(SaviType.ui(.subheadline, weight: .bold))
                        .foregroundStyle(SaviTheme.accentText.opacity(0.88))
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(SaviPressScaleButtonStyle())
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct FolderStrip: View {
    @EnvironmentObject private var store: SaviStore
    var title = "Quick Folders"
    let folders: [SaviFolder]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SaviHomeSectionHeader(title: title, actionTitle: "All") {
                store.openFoldersManagement()
            }

            GeometryReader { proxy in
                let spacing = SaviHomeFolderStripMetrics.spacing
                let visibleGutter: CGFloat = 14
                let tileWidth = max(84, floor((proxy.size.width - (spacing * 2) - visibleGutter) / 3))

                ZStack(alignment: .trailing) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing) {
                            ForEach(folders) { folder in
                                HomeFolderTile(folder: folder, width: tileWidth)
                            }
                        }
                        .padding(.trailing, 22)
                    }

                    LinearGradient(
                        colors: [SaviTheme.background.opacity(0), SaviTheme.background],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                    .allowsHitTesting(false)
                }
            }
            .frame(height: SaviHomeFolderStripMetrics.tileHeight)

            Rectangle()
                .fill(SaviTheme.cardStroke.opacity(0.42))
                .frame(height: 1)
        }
    }
}

private struct HomeFolderTile: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let folder: SaviFolder
    let width: CGFloat

    private var isLocked: Bool {
        folder.locked && !store.isProtectedKeeperUnlocked(folder)
    }

    private var displayName: String {
        SaviFolderNameFormatter.balanced(folder.name)
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
                            size: SaviHomeFolderStripMetrics.iconSize,
                            cornerRadius: SaviHomeFolderStripMetrics.iconCornerRadius,
                            font: SaviHomeFolderStripMetrics.iconFont,
                        background: style.iconBackground,
                        foreground: style.iconForeground,
                        publicBadgeStyle: folder.isPublic ? style : nil
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

                Text(displayName)
                    .font(SaviType.display(size: 17, weight: .black))
                    .foregroundStyle(style.text)
                    .shadow(color: style.titleShadow, radius: style.titleShadowRadius, x: 0, y: 1)
                    .lineLimit(2)
                    .lineSpacing(1)
                    .minimumScaleFactor(0.78)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(11)
            .frame(width: width, height: SaviHomeFolderStripMetrics.tileHeight, alignment: .leading)
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
        .accessibilityLabel("\(folder.name), \(folder.isPublic ? "Public, " : "")\(isLocked ? "Locked" : "\(store.count(in: folder)) saves")")
    }

}

private enum SaviHomeFolderStripMetrics {
    static let spacing: CGFloat = 10
    static let tileHeight: CGFloat = 104
    static let iconSize: CGFloat = 30
    static let iconCornerRadius: CGFloat = 10
    static var iconFont: Font { SaviType.ui(.caption, weight: .black) }
}

struct ItemRow: View {
    let item: SaviItem
    var context: ItemRowContext = .home
    var showsMatchReasons = false

    var body: some View {
        SaveCard(item: item, context: context, showsMatchReasons: showsMatchReasons)
    }
}

struct EditorialTimelineItemRow: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let item: SaviItem
    var context: ItemRowContext = .home
    var showsMatchReasons = false
    var showsSnippet = false

    var body: some View {
        Button {
            store.presentItem(item)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                EditorialTimelineTimeRail(savedAt: item.savedAt)

                ItemThumb(item: item, enablesPressPreview: false)
                    .frame(width: EditorialTimelineItemLayout.thumbnailSize, height: EditorialTimelineItemLayout.thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: EditorialTimelineItemLayout.thumbnailCorner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: EditorialTimelineItemLayout.thumbnailCorner, style: .continuous)
                            .stroke(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.22 : 0.48), lineWidth: 1)
                    )
                    .saviThumbnailTypeBadge(for: item)

                VStack(alignment: .leading, spacing: 7) {
                    Text(SaviItemDisplay.rowTitle(for: item))
                        .font(EditorialTimelineItemLayout.titleFont)
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(2)
                        .lineSpacing(1.8)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(2)

                    if showsSnippet {
                        ItemSnippetLine(item: item, context: context)
                            .lineLimit(1)
                            .layoutPriority(1)
                    }

                    ItemTokenRow(
                        item: item,
                        folder: store.folder(for: item.folderId),
                        tags: item.tags,
                        hidesTags: true
                    )

                    if showsMatchReasons, store.hasActiveSearchControls {
                        SearchMatchReasonLine(item: item)
                    }
                }
                .frame(minHeight: EditorialTimelineItemLayout.thumbnailSize, alignment: .leading)
            }
            .padding(.vertical, 7)
            .padding(.trailing, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("\(SaviItemDisplay.rowTitle(for: item)), saved \(SaviText.relativeSavedTime(item.savedAt))")
    }
}

struct SaviTimelineItemRow: View {
    let item: SaviItem
    var context: ItemRowContext = .home
    var showsMatchReasons = false
    var showsSnippet = false

    var body: some View {
        EditorialTimelineItemRow(
            item: item,
            context: context,
            showsMatchReasons: showsMatchReasons,
            showsSnippet: showsSnippet
        )
    }
}

struct SaviFluidTimelineGroup: View {
    let title: String
    let items: [SaviItem]
    var context: ItemRowContext = .home

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(SaviTheme.cardStroke.opacity(0.62))
                .frame(width: 1)
                .padding(.leading, SaviFluidTimelineMetrics.lineX)
                .padding(.top, 32)
                .padding(.bottom, 16)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                SaviFluidTimelineGroupLabel(title: title)

                ForEach(items) { item in
                    SaviFluidTimelineItemRow(item: item, context: context)
                }
            }
        }
    }
}

struct SearchResultRow: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let item: SaviItem

    var body: some View {
        Button {
            store.presentItem(item)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ItemThumb(item: item, enablesPressPreview: false)
                    .frame(width: SearchResultRowMetrics.thumbnailSize, height: SearchResultRowMetrics.thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: SearchResultRowMetrics.thumbnailCorner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: SearchResultRowMetrics.thumbnailCorner, style: .continuous)
                            .stroke(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.22 : 0.48), lineWidth: 1)
                    )
                    .saviThumbnailTypeBadge(for: item)

                VStack(alignment: .leading, spacing: 6) {
                    Text(SaviItemDisplay.rowTitle(for: item))
                        .font(SaviType.reading(.subheadline, weight: .bold))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(2)
                        .lineSpacing(1.6)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(2)

                    ItemSnippetLine(item: item, context: .search)
                        .lineLimit(1)
                        .layoutPriority(1)

                    HStack(alignment: .center, spacing: 8) {
                        ItemTokenRow(
                            item: item,
                            folder: store.folder(for: item.folderId),
                            tags: item.tags,
                            hidesTags: true
                        )
                        .layoutPriority(1)

                        SavedTimeCornerLabel(savedAt: item.savedAt)
                            .layoutPriority(0)
                    }

                    if store.hasActiveSearchControls {
                        SearchMatchReasonLine(item: item)
                    }
                }
                .frame(minHeight: SearchResultRowMetrics.thumbnailSize, alignment: .topLeading)
            }
            .padding(.vertical, 9)
            .padding(.trailing, 4)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.42 : 0.34))
                    .frame(height: 1)
            }
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("\(SaviItemDisplay.rowTitle(for: item)), saved \(SaviText.relativeSavedTime(item.savedAt))")
    }
}

private struct SaviFluidTimelineGroupLabel: View {
    let title: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack(alignment: .leading) {
                Circle()
                    .fill(SaviTheme.chartreuse)
                    .frame(width: 10, height: 10)
                    .position(x: SaviFluidTimelineMetrics.lineX, y: 12)
                    .shadow(color: SaviTheme.chartreuse.opacity(0.24), radius: 4, x: 0, y: 1)
            }
            .frame(width: SaviFluidTimelineMetrics.railWidth, height: 24)

            Text(title)
                .font(SaviType.ui(.subheadline, weight: .bold))
                .foregroundStyle(SaviTheme.metadataText)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

private struct SaviFluidTimelineItemRow: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let item: SaviItem
    var context: ItemRowContext = .home

    private var folder: SaviFolder? {
        store.folder(for: item.folderId)
    }

    private var dotColor: Color {
        guard let folder else { return SaviTheme.chartreuse }
        return Color(hex: SaviFolderVisualStyle.preferredHex(for: folder))
    }

    var body: some View {
        Button {
            store.presentItem(item)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                SaviFluidTimelineRailMark(savedAt: item.savedAt, dotColor: dotColor)

                ItemThumb(item: item, enablesPressPreview: false)
                    .frame(width: SaviFluidTimelineMetrics.thumbnailSize, height: SaviFluidTimelineMetrics.thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: SaviFluidTimelineMetrics.thumbnailCorner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: SaviFluidTimelineMetrics.thumbnailCorner, style: .continuous)
                            .stroke(SaviTheme.cardStroke.opacity(colorScheme == .light ? 0.22 : 0.48), lineWidth: 1)
                    )
                    .saviThumbnailTypeBadge(for: item)

                VStack(alignment: .leading, spacing: 7) {
                    Text(SaviItemDisplay.rowTitle(for: item))
                        .font(SaviType.reading(.subheadline, weight: .bold))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(2)
                        .lineSpacing(1.8)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(2)

                    ItemTokenRow(
                        item: item,
                        folder: folder,
                        tags: item.tags,
                        hidesTags: true
                    )
                }
                .frame(minHeight: SaviFluidTimelineMetrics.thumbnailSize, alignment: .leading)
            }
            .padding(.vertical, 10)
            .padding(.trailing, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("\(SaviItemDisplay.rowTitle(for: item)), saved \(SaviText.relativeSavedTime(item.savedAt))")
    }
}

private struct SaviFluidTimelineRailMark: View {
    let savedAt: Double
    let dotColor: Color

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            ZStack(alignment: .leading) {
                Text(SaviText.compactRelativeSavedTime(savedAt, now: context.date))
                    .font(SaviType.ui(.caption2, weight: .bold))
                    .foregroundStyle(SaviTheme.metadataText.opacity(0.82))
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .minimumScaleFactor(0.72)
                    .frame(width: SaviFluidTimelineMetrics.timeWidth, alignment: .trailing)
                    .position(x: SaviFluidTimelineMetrics.timeWidth / 2, y: SaviFluidTimelineMetrics.thumbnailSize / 2)

                Circle()
                    .fill(dotColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(SaviTheme.background, lineWidth: 2)
                    )
                    .shadow(color: dotColor.opacity(0.22), radius: 4, x: 0, y: 1)
                    .position(x: SaviFluidTimelineMetrics.lineX, y: SaviFluidTimelineMetrics.thumbnailSize / 2)
            }
            .frame(width: SaviFluidTimelineMetrics.railWidth, height: SaviFluidTimelineMetrics.thumbnailSize)
            .accessibilityLabel("Saved \(SaviText.relativeSavedTime(savedAt, now: context.date))")
        }
    }
}

private enum SaviFluidTimelineMetrics {
    static let railWidth: CGFloat = 58
    static let timeWidth: CGFloat = 34
    static let lineX: CGFloat = 48
    static let thumbnailSize: CGFloat = 82
    static let thumbnailCorner: CGFloat = 15
}

private enum SearchResultRowMetrics {
    static let thumbnailSize: CGFloat = 76
    static let thumbnailCorner: CGFloat = 14
}

private enum EditorialTimelineItemLayout {
    static let thumbnailSize: CGFloat = 82
    static let thumbnailCorner: CGFloat = 15
    static var titleFont: Font { SaviType.reading(.subheadline, weight: .bold) }
}

private struct EditorialTimelineTimeRail: View {
    let savedAt: Double

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            VStack(spacing: 5) {
                Text(SaviText.compactRelativeSavedTime(savedAt, now: context.date))
                    .font(SaviType.ui(.caption2, weight: .bold))
                    .foregroundStyle(SaviTheme.metadataText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 38, alignment: .trailing)

                Rectangle()
                    .fill(SaviTheme.cardStroke.opacity(0.65))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 44)
            .frame(minHeight: 96)
            .accessibilityLabel("Saved \(SaviText.relativeSavedTime(savedAt, now: context.date))")
        }
    }
}

struct SaveCard: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let item: SaviItem
    var context: ItemRowContext = .home
    var showsMatchReasons = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: SaviItemLayout.cardCorner, style: .continuous)

        HStack(alignment: .center, spacing: SaviItemLayout.rowSpacing) {
            SaveCardThumbnail(item: item)

            VStack(alignment: .leading, spacing: SaviItemLayout.rowTextSpacing) {
                Text(SaviItemDisplay.rowTitle(for: item))
                    .font(SaviItemTypography.rowTitle)
                    .lineLimit(2)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(SaviTheme.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(2)

                ItemSnippetLine(item: item, context: context)
                    .layoutPriority(1)

                Spacer(minLength: 4)

                ItemTokenRow(
                    item: item,
                    folder: store.folder(for: item.folderId),
                    tags: item.tags,
                    hidesTags: showsMatchReasons && store.hasActiveSearchControls
                )

                if showsMatchReasons, store.hasActiveSearchControls {
                    SearchMatchReasonLine(item: item)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: SaviItemLayout.rowThumbnailHeight, alignment: .topLeading)

            SaveCardActionRail(item: item)
        }
        .padding(SaviItemLayout.rowPadding)
        .frame(minHeight: SaviItemLayout.rowMinHeight, alignment: .top)
        .background(colorScheme == .light ? Color.white : SaviTheme.surface)
        .clipShape(shape)
        .overlay(shape.stroke(saveCardStroke, lineWidth: 1))
        .shadow(
            color: SaviTheme.cardShadow.opacity(colorScheme == .light ? 0.075 : 0.18),
            radius: colorScheme == .light ? 12 : 10,
            x: 0,
            y: colorScheme == .light ? 4 : 6
        )
        .contentShape(shape)
        .onTapGesture {
            store.presentItem(item)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Open") {
            store.presentItem(item)
        }
    }

    private var saveCardStroke: Color {
        colorScheme == .light
            ? SaviTheme.cardStroke.opacity(0.28)
            : SaviTheme.cardStroke.opacity(0.72)
    }
}

private struct SaveCardThumbnail: View {
    let item: SaviItem

    var body: some View {
        ItemThumb(item: item)
            .frame(width: SaviItemLayout.rowThumbnailWidth, height: SaviItemLayout.rowThumbnailHeight)
            .clipShape(RoundedRectangle(cornerRadius: SaviItemLayout.thumbnailCorner, style: .continuous))
            .saviThumbnailTypeBadge(for: item)
    }
}

private struct SaveCardActionRail: View {
    let item: SaviItem

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Spacer(minLength: 0)

            SavedTimeCornerLabel(savedAt: item.savedAt)
                .frame(width: SaviItemLayout.actionRailWidth, alignment: .trailing)
        }
        .frame(width: SaviItemLayout.actionRailWidth)
        .frame(minHeight: SaviItemLayout.rowThumbnailHeight, alignment: .top)
    }
}

enum ItemRowContext {
    case home
    case search
}

struct SaviSavedItemDateGroup: Identifiable {
    let id: String
    let title: String
    let items: [SaviItem]
}

enum SaviSavedItemDateGrouper {
    static func groups(for items: [SaviItem], now: Date = Date(), calendar: Calendar = .current) -> [SaviSavedItemDateGroup] {
        guard !items.isEmpty else { return [] }

        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? today
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeek) ?? yesterday

        let buckets: [(id: String, title: String, contains: (Date) -> Bool)] = [
            ("today", "Today", { date in date >= today }),
            ("yesterday", "Yesterday", { date in date >= yesterday && date < today }),
            ("this-week", "This week", { date in date >= thisWeek && date < yesterday }),
            ("last-week", "Last week", { date in date >= lastWeek && date < thisWeek }),
            ("older", "Older", { date in date < lastWeek })
        ]

        return buckets.compactMap { bucket in
            let groupedItems = items.filter { item in
                bucket.contains(savedDate(for: item))
            }
            guard !groupedItems.isEmpty else { return nil }
            return SaviSavedItemDateGroup(id: bucket.id, title: bucket.title, items: groupedItems)
        }
    }

    private static func savedDate(for item: SaviItem) -> Date {
        Date(timeIntervalSince1970: item.savedAt / 1000)
    }
}

struct SavedItemDateGroupLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(SaviType.reading(.caption, weight: .semibold))
            .foregroundStyle(SaviTheme.metadataText)
            .textCase(.uppercase)
            .tracking(0.7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .accessibilityAddTraits(.isHeader)
    }
}

enum SaviItemLayout {
    static let rowThumbnailWidth: CGFloat = 84
    static let rowThumbnailHeight: CGFloat = 84
    static let rowSpacing: CGFloat = 11
    static let rowTextSpacing: CGFloat = 6
    static let rowPadding: CGFloat = 9
    static let rowMinHeight: CGFloat = 106
    static let actionRailWidth: CGFloat = 38
    static let cardCorner: CGFloat = 18
    static let thumbnailCorner: CGFloat = 15
    static let pillHeight: CGFloat = 22
    static let pillIconSize: CGFloat = 12
    static let pillIconGlyphSize: CGFloat = 7
    static let detailPreviewCorner: CGFloat = 22
}

enum SaviItemTypography {
    static var rowTitle: Font { SaviType.reading(.subheadline, weight: .bold) }
    static var rowSnippet: Font { SaviType.reading(.footnote, weight: .regular) }
    static var meta: Font { SaviType.reading(.caption2, weight: .medium) }
    static var pill: Font { SaviType.reading(.caption2, weight: .semibold) }
    static var matchReason: Font { SaviType.reading(.caption, weight: .semibold) }
    static var detailTitle: Font { SaviType.reading(.title2, weight: .bold) }
    static var detailBodyTitle: Font { SaviType.reading(.caption, weight: .bold) }
    static var detailBody: Font { SaviType.reading(.callout, weight: .regular) }
}

enum SaviItemDisplay {
    static func rowTitle(for item: SaviItem) -> String {
        let title = normalized(item.title) ?? "Saved item"
        if SaviText.isGenericFetchedTitle(title),
           let url = item.url?.nilIfBlank {
            return SaviText.fallbackTitle(for: url)
        }
        return title
    }

    static func isNoteLike(_ item: SaviItem) -> Bool {
        if item.type == .text { return true }
        if item.source.lowercased().contains("paste") { return true }
        return item.url?.nilIfBlank == nil && item.tags.contains { $0 == "note" || $0 == "text" }
    }

    static func rowSnippet(for item: SaviItem, context: ItemRowContext) -> String? {
        guard let description = normalized(item.itemDescription),
              !description.caseInsensitiveCompare(item.title).isSame
        else {
            if context == .search, item.type == .file {
                return normalized(item.assetName ?? item.assetMime ?? "")
            }
            return nil
        }

        return description
    }

    static func rowSnippetLineLimit(for item: SaviItem) -> Int {
        isNoteLike(item) ? 2 : 1
    }

    static func detailBody(for item: SaviItem) -> String? {
        guard let description = normalized(item.itemDescription),
              !description.caseInsensitiveCompare(item.title).isSame
        else { return nil }
        return description
    }

    static func detailBodyTitle(for item: SaviItem) -> String {
        isNoteLike(item) ? "Note" : "Summary"
    }

    static func detailPreviewHeight(for item: SaviItem) -> CGFloat {
        if isNoteLike(item) { return 104 }
        if item.type == .file && item.thumbnail?.nilIfBlank == nil { return 128 }
        return 170
    }

    private static func normalized(_ value: String) -> String? {
        let trimmed = value
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
    }
}

private extension ComparisonResult {
    var isSame: Bool { self == .orderedSame }
}

struct ItemSnippetLine: View {
    let item: SaviItem
    let context: ItemRowContext

    var body: some View {
        if let snippet = SaviItemDisplay.rowSnippet(for: item, context: context) {
            Text(snippet)
                .font(SaviItemTypography.rowSnippet)
                .foregroundStyle(SaviTheme.textMuted.opacity(0.88))
                .lineLimit(SaviItemDisplay.rowSnippetLineLimit(for: item))
                .lineSpacing(1.4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ItemMetaLine: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 7) {
                ItemMetaPart(
                    title: store.primaryKindLabel(for: item),
                    systemImage: item.type.symbolName
                )

                if let source = item.readableSource {
                    ItemMetaDivider()
                    Text(source)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.78)
                }
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            SavedTimeInline(savedAt: item.savedAt)
                .layoutPriority(1)
        }
        .font(SaviItemTypography.meta)
        .foregroundStyle(SaviTheme.metadataText)
        .lineLimit(1)
        .imageScale(.small)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ItemMetaPart: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
    }
}

struct ItemMetaDivider: View {
    var body: some View {
        Circle()
            .fill(SaviTheme.textMuted.opacity(0.45))
            .frame(width: 3, height: 3)
            .accessibilityHidden(true)
    }
}

struct SavedTimeInline: View {
    let savedAt: Double

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            Label(SaviText.compactRelativeSavedTime(savedAt, now: context.date), systemImage: "clock")
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel("Saved \(SaviText.relativeSavedTime(savedAt, now: context.date))")
        }
    }
}

struct SavedTimeCornerLabel: View {
    let savedAt: Double

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            Text(SaviText.compactRelativeSavedTime(savedAt, now: context.date))
                .font(SaviItemTypography.meta)
                .foregroundStyle(SaviTheme.metadataText)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel("Saved \(SaviText.relativeSavedTime(savedAt, now: context.date))")
        }
    }
}

struct ItemTokenRow: View {
    let item: SaviItem
    let folder: SaviFolder?
    let tags: [String]
    var hidesTags = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            tokenRow(showSource: true)
            tokenRow(showSource: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: SaviItemLayout.pillHeight)
        .clipped()
    }

    @ViewBuilder
    private func tokenRow(showSource: Bool) -> some View {
        HStack(spacing: 8) {
            if let folder {
                KeeperPill(folder: folder, maxWidth: 112)
                    .layoutPriority(2)
            }

            if showSource {
                ItemTypeSourceText(item: item)
                    .layoutPriority(1)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct ItemTokenCapsule: View {
    let title: String
    var systemImage: String?
    var maxWidth: CGFloat?
    var foreground: Color = SaviTheme.metadataText
    var background: Color = SaviTheme.subtleSurface.opacity(0.36)
    var stroke: Color = SaviTheme.cardStroke.opacity(0.34)
    var accent: Color?

    var body: some View {
        HStack(spacing: 4.5) {
            if let systemImage {
                tokenIcon(systemImage)
            }
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(SaviItemTypography.pill)
        .foregroundStyle(foreground)
        .padding(.horizontal, 6.5)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .frame(height: SaviItemLayout.pillHeight)
        .background(background)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(stroke, lineWidth: 1))
    }

    @ViewBuilder
    private func tokenIcon(_ systemImage: String) -> some View {
        if let accent {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                Image(systemName: systemImage)
                    .font(.system(size: SaviItemLayout.pillIconGlyphSize, weight: .black))
                    .foregroundStyle(accent.opacity(0.88))
                    .frame(width: SaviItemLayout.pillIconGlyphSize, height: SaviItemLayout.pillIconGlyphSize)
            }
            .frame(width: SaviItemLayout.pillIconSize, height: SaviItemLayout.pillIconSize)
        } else {
            ZStack {
                Circle()
                    .fill(SaviTheme.surfaceRaised.opacity(0.46))
                Image(systemName: systemImage)
                    .font(.system(size: SaviItemLayout.pillIconGlyphSize, weight: .black))
                    .foregroundStyle(foreground.opacity(0.74))
                    .frame(width: SaviItemLayout.pillIconGlyphSize, height: SaviItemLayout.pillIconGlyphSize)
            }
            .frame(width: SaviItemLayout.pillIconSize, height: SaviItemLayout.pillIconSize)
        }
    }
}

struct ItemKindBadge: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        Label(store.primaryKindLabel(for: item), systemImage: item.type.symbolName)
            .font(SaviItemTypography.pill)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(SaviTheme.subtleSurface.opacity(0.75))
            .foregroundStyle(SaviTheme.metadataText)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(SaviTheme.cardStroke.opacity(0.75), lineWidth: 1))
    }
}

struct ItemSourcePin: View {
    let item: SaviItem

    private var presentation: ItemSourcePinPresentation {
        ItemSourcePinPresentation.make(for: item)
    }

    var body: some View {
        ItemTokenCapsule(
            title: presentation.title,
            systemImage: presentation.symbolName,
            maxWidth: 82,
            foreground: SaviTheme.metadataText.opacity(0.90),
            background: SaviTheme.subtleSurface.opacity(0.26),
            stroke: SaviTheme.cardStroke.opacity(0.22),
            accent: presentation.accent
        )
        .accessibilityLabel(presentation.title)
    }
}

struct ItemSourcePinPresentation {
    let title: String
    let symbolName: String
    let accent: Color

    static func make(for item: SaviItem) -> ItemSourcePinPresentation {
        let haystack = [
            item.source,
            item.url ?? "",
            item.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()

        if haystack.contains("youtube") || haystack.contains("youtu.be") {
            return .init(title: "YouTube", symbolName: "play.fill", accent: Color(hex: "#FF0033"))
        }
        if haystack.contains("maps.apple") || haystack.contains("apple maps") {
            return .init(title: "Apple Maps", symbolName: "mappin.and.ellipse", accent: Color(hex: "#007AFF"))
        }
        if haystack.contains("google.com/maps") || haystack.contains("goo.gl/maps") || haystack.contains("google maps") {
            return .init(title: "Google Maps", symbolName: "mappin.and.ellipse", accent: Color(hex: "#34A853"))
        }
        if haystack.contains("maps") || item.type == .place {
            return .init(title: "Map", symbolName: "mappin.and.ellipse", accent: Color(hex: "#34A853"))
        }
        if haystack.contains("tiktok") || haystack.contains("vm.tiktok") {
            return .init(title: "TikTok", symbolName: "music.note", accent: Color(hex: "#FF0050"))
        }
        if haystack.contains("instagram") {
            return .init(title: "Instagram", symbolName: "camera.fill", accent: Color(hex: "#DD2A7B"))
        }
        if haystack.contains("twitter.com") || haystack.contains("x.com") || haystack.contains("twitter") {
            return .init(title: "X", symbolName: "xmark", accent: Color(hex: "#111111"))
        }
        if haystack.contains("spotify") {
            return .init(title: "Spotify", symbolName: "music.note", accent: Color(hex: "#1DB954"))
        }
        if let brand = SaviSourceBrand.brand(for: item) {
            let accent = brand.backgroundColors.first.map { Color(hex: $0) } ?? SaviTheme.accentText
            return .init(title: brand.name, symbolName: brand.symbolName ?? "link", accent: accent)
        }
        if item.type == .file {
            return .init(title: "File", symbolName: "doc.fill", accent: SaviTheme.accentText)
        }
        if item.type == .image {
            return .init(title: "Image", symbolName: "photo.fill", accent: Color(hex: "#0EA5E9"))
        }
        if item.type == .video {
            return .init(title: "Video", symbolName: "play.rectangle.fill", accent: Color(hex: "#FF5A5F"))
        }
        if item.type == .article {
            return .init(title: "Article", symbolName: "newspaper.fill", accent: Color(hex: "#6D28D9"))
        }
        if item.type == .text {
            return .init(title: "Note", symbolName: "text.alignleft", accent: Color(hex: "#8A7CA8"))
        }
        if let source = item.readableSource?.nilIfBlank,
           source.caseInsensitiveCompare("device") == .orderedSame ||
            source.caseInsensitiveCompare("clipboard") == .orderedSame {
            return .init(title: source.capitalized, symbolName: source.lowercased() == "device" ? "iphone" : "doc.on.clipboard.fill", accent: SaviTheme.accentText)
        }
        return .init(title: item.type.label, symbolName: item.type.symbolName, accent: SaviTheme.accentText)
    }
}

struct ItemSourceInline: View {
    let source: String

    var body: some View {
        Label(source, systemImage: SaviSearchPresentation.sourceSymbolName(for: source.lowercased()))
            .font(SaviItemTypography.pill)
            .foregroundStyle(SaviTheme.textMuted)
            .lineLimit(1)
            .truncationMode(.tail)
            .minimumScaleFactor(0.75)
    }
}

struct KeeperPill: View {
    @Environment(\.colorScheme) private var colorScheme
    let folder: SaviFolder
    var maxWidth: CGFloat = 146

    var body: some View {
        let style = SaviFolderVisualStyle.make(for: folder, colorScheme: colorScheme)
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(style.base.opacity(colorScheme == .light ? 0.78 : 0.70))
                .frame(width: 4, height: 12)
                .accessibilityHidden(true)

            Text(folder.name)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(SaviType.reading(.caption2, weight: .semibold))
        .foregroundStyle(SaviTheme.metadataText.opacity(colorScheme == .light ? 0.90 : 0.86))
        .padding(.leading, 6)
        .padding(.trailing, 7)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .frame(height: SaviItemLayout.pillHeight)
        .background(SaviTheme.subtleSurface.opacity(colorScheme == .light ? 0.46 : 0.24))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(style.base.opacity(colorScheme == .light ? 0.18 : 0.22), lineWidth: 1)
        )
        .accessibilityLabel(folder.name)
    }
}

struct ItemTypeSourceText: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                Text(store.primaryKindLabel(for: item))
                if let source = item.readableSource?.nilIfBlank,
                   !source.caseInsensitiveCompare(store.primaryKindLabel(for: item)).isSame {
                    ItemMetaDivider()
                    Text(source)
                }
            }

            Text(store.primaryKindLabel(for: item))
        }
        .font(SaviItemTypography.meta)
        .foregroundStyle(SaviTheme.metadataText)
        .lineLimit(1)
        .truncationMode(.tail)
        .minimumScaleFactor(0.78)
    }
}

struct SavedTimePill: View {
    let savedAt: Double

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            Text(SaviText.compactRelativeSavedTime(savedAt, now: context.date))
                .font(SaviItemTypography.pill)
                .foregroundStyle(SaviTheme.metadataText)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(SaviTheme.surface)
                .clipShape(Capsule())
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel("Saved \(SaviText.relativeSavedTime(savedAt, now: context.date))")
        }
    }
}

struct ItemTagPreview: View {
    let tags: [String]

    var body: some View {
        ForEach(displayTags.prefix(1), id: \.self) { tag in
            ItemTokenCapsule(
                title: "#\(tag)",
                maxWidth: 86,
                foreground: SaviTheme.textMuted.opacity(0.70),
                background: SaviTheme.subtleSurface.opacity(0.24),
                stroke: SaviTheme.cardStroke.opacity(0.18)
            )
        }

        if displayTags.count > 1 {
            ItemTokenCapsule(
                title: "+\(displayTags.count - 1)",
                foreground: SaviTheme.textMuted.opacity(0.66),
                background: SaviTheme.subtleSurface.opacity(0.20),
                stroke: SaviTheme.cardStroke.opacity(0.16)
            )
        }
    }

    private var displayTags: [String] {
        let generic: Set<String> = [
            "link", "article", "video", "image", "file", "post", "web", "save",
            "pdf", "document", "doc", "docs", "place", "map", "maps", "location",
            "twitter", "x", "youtube", "instagram", "tiktok", "reddit", "facebook",
            "device", "clipboard", "text", "note"
        ]
        return tags.filter { tag in
            !generic.contains(tag.lowercased())
        }
    }
}

struct SearchMatchReasonLine: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    var body: some View {
        let reasons = store.matchReasons(for: item)
        if !reasons.isEmpty {
            Text("Matched by: \(reasons.joined(separator: " · "))")
                .font(SaviType.ui(.caption2, weight: .semibold))
                .foregroundStyle(SaviTheme.metadataText.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

struct ItemPreview: View {
    let item: SaviItem

    var body: some View {
        ItemThumb(item: item, large: true, enablesPressPreview: false)
            .frame(maxWidth: .infinity)
            .frame(height: SaviItemDisplay.detailPreviewHeight(for: item))
            .clipShape(RoundedRectangle(cornerRadius: SaviItemLayout.detailPreviewCorner, style: .continuous))
    }
}

struct ItemThumb: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem
    var large = false
    var enablesPressPreview = true

    var body: some View {
        if enablesPressPreview {
            thumbnailBody
                .highPriorityGesture(pressPreviewGesture)
                .accessibilityAction(named: "Preview") {
                    store.previewItemContent(item)
                }
        } else {
            thumbnailBody
        }
    }

    private var thumbnailBody: some View {
        ZStack {
            LinearGradient(
                colors: SaviSourceBrand.brand(for: item)?.backgroundColors.map { Color(hex: $0) } ??
                    [Color(hex: item.color ?? "#2D2151"), Color(hex: "#141120")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            thumbnailContent
        }
        .contentShape(Rectangle())
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: large ? 24 : 16, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var pressPreviewGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.42)
            .onEnded { _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                store.previewItemContent(item)
            }
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let thumbnail = item.thumbnail?.nilIfBlank,
           thumbnail.hasPrefix("http"),
           let url = URL(string: thumbnail) {
            SaviCachedRemoteImage(url: url) {
                fallback
            }
        } else if let thumbnail = item.thumbnail?.nilIfBlank,
                  let image = SaviImageCache.image(fromDataURL: thumbnail) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let thumbnail = item.thumbnail?.nilIfBlank,
                  SaviText.isSVGDataURL(thumbnail) {
            SaviSVGDataThumbnail(dataURL: thumbnail)
        } else {
            fallback
        }
    }

    @ViewBuilder
    private var fallback: some View {
        TimelineView(.periodic(from: Date(), by: 30)) { context in
            if let brand = SaviSourceBrand.brand(for: item),
               store.shouldShowBrandFallback(for: item, now: context.date) {
                SaviBrandFallbackThumb(brand: brand, large: large)
            } else if store.shouldShowThumbnailPending(for: item, now: context.date) {
                SaviThumbnailPendingThumb(
                    message: store.thumbnailPendingMessage(for: item),
                    large: large
                )
            } else {
                VStack(spacing: large ? 12 : 4) {
                    Image(systemName: item.type.symbolName)
                        .font(large ? .system(size: 46, weight: .bold) : .title3.weight(.bold))
                        .foregroundStyle(SaviTheme.chartreuse)
                    if large {
                        Text(item.readableSource ?? item.type.label)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
        }
    }
}

extension View {
    func saviThumbnailTypeBadge(for item: SaviItem, padding: CGFloat = 4) -> some View {
        overlay(alignment: .bottomLeading) {
            ItemThumbMiniBadge(item: item)
                .padding(padding)
        }
    }
}

struct ItemThumbMiniBadge: View {
    let item: SaviItem

    private var presentation: ItemThumbMiniBadgePresentation { .make(for: item) }

    private var hasResolvedThumbnail: Bool {
        item.thumbnail?.nilIfBlank != nil
    }

    var body: some View {
        if hasResolvedThumbnail {
            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.48))
                presentation.mark
            }
            .frame(width: presentation.width, height: 20)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.48), lineWidth: 1))
            .shadow(color: .black.opacity(0.18), radius: 3, x: 0, y: 1)
            .accessibilityHidden(true)
        }
    }
}

private struct ItemThumbMiniBadgePresentation {
    let width: CGFloat
    let symbolName: String?
    let text: String?

    var mark: some View {
        Group {
            if let symbolName {
                Image(systemName: symbolName)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
            } else if let text {
                Text(text)
                    .font(.system(size: text.count > 2 ? 7 : 9, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
            }
        }
    }

    static func make(for item: SaviItem) -> ItemThumbMiniBadgePresentation {
        if isPDF(item) {
            return .init(
                width: 28,
                symbolName: nil,
                text: "PDF"
            )
        }

        if let brand = SaviSourceBrand.brand(for: item) {
            let width: CGFloat = brand.symbolName == nil && brand.mark.count > 1 ? 24 : 20
            return .init(
                width: width,
                symbolName: brand.symbolName,
                text: brand.symbolName == nil ? brand.mark : nil
            )
        }

        let fallback = fallbackPresentation(for: item)
        return .init(
            width: 20,
            symbolName: fallback,
            text: nil
        )
    }

    private static func fallbackPresentation(for item: SaviItem) -> String {
        let haystack = normalizedFields(for: item)

        if haystack.contains("audio") || haystack.contains(".mp3") || haystack.contains(".wav") || haystack.contains(".m4a") {
            return "waveform"
        }
        if haystack.contains("screenshot") {
            return "iphone.gen3"
        }
        if haystack.contains("docx") || haystack.contains("word") {
            return "doc.text.fill"
        }
        if haystack.contains("ppt") || haystack.contains("keynote") {
            return "rectangle.on.rectangle.angled"
        }
        if haystack.contains("xls") || haystack.contains("spreadsheet") || haystack.contains("csv") {
            return "tablecells.fill"
        }

        switch item.type {
        case .article:
            return "newspaper.fill"
        case .video:
            return "play.fill"
        case .image:
            return "photo.fill"
        case .file:
            return "doc.fill"
        case .text:
            return "text.alignleft"
        case .place:
            return "mappin.and.ellipse"
        case .link:
            return "link"
        }
    }

    private static func isPDF(_ item: SaviItem) -> Bool {
        let haystack = normalizedFields(for: item)
        return haystack.contains("application/pdf") ||
            haystack.contains(".pdf") ||
            haystack.contains(" pdf ") ||
            haystack.hasSuffix(" pdf")
    }

    private static func normalizedFields(for item: SaviItem) -> String {
        [
            item.type.rawValue,
            item.assetMime ?? "",
            item.assetName ?? "",
            item.url ?? "",
            item.source,
            item.tags.joined(separator: " ")
        ]
        .joined(separator: " ")
        .lowercased()
    }
}

struct SaviThumbnailPendingThumb: View {
    let message: String
    var large = false

    var body: some View {
        VStack(spacing: large ? 10 : 5) {
            ProgressView()
                .tint(SaviTheme.chartreuse)
                .scaleEffect(large ? 1.1 : 0.82)
            if large {
                Text(message)
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
            }
        }
        .padding(large ? 18 : 8)
        .accessibilityLabel(message)
    }
}

struct SaviBrandFallbackThumb: View {
    let brand: SaviSourceBrand
    var large = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: brand.backgroundColors.map { Color(hex: $0) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: large ? 8 : 5) {
                brandMark
            }
            .padding(large ? 18 : 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: large ? 24 : 16, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .accessibilityLabel("\(brand.name) thumbnail")
    }

    @ViewBuilder
    private var brandMark: some View {
        if let symbolName = brand.symbolName {
            Image(systemName: symbolName)
                .font(large ? .system(size: 38, weight: .black) : .system(size: 26, weight: .black))
                .foregroundStyle(brand.foregroundColor)
                .opacity(large ? 0.68 : 1)
        } else {
            Text(brand.mark)
                .font(.system(size: large ? brand.largeMarkSize * 0.78 : brand.markSize, weight: .black, design: .rounded))
                .foregroundStyle(brand.foregroundColor)
                .opacity(large ? 0.68 : 1)
                .minimumScaleFactor(0.55)
                .lineLimit(1)
        }
    }
}

struct SaviSourceBrand {
    let name: String
    let mark: String
    let symbolName: String?
    let backgroundColors: [String]
    let foregroundColor: Color
    var markSize: CGFloat = 24
    var largeMarkSize: CGFloat = 50

    static func brand(for item: SaviItem) -> SaviSourceBrand? {
        let haystack = [
            item.source,
            item.url ?? "",
            item.tags.joined(separator: " ")
        ].joined(separator: " ").lowercased()

        if haystack.contains("youtube") || haystack.contains("youtu.be") {
            return .init(name: "YouTube", mark: "", symbolName: "play.fill", backgroundColors: ["#FF0033", "#8B000E"], foregroundColor: .white)
        }
        if haystack.contains("tiktok") || haystack.contains("vm.tiktok") {
            return .init(name: "TikTok", mark: "♪", symbolName: nil, backgroundColors: ["#111111", "#00F2EA", "#FF0050"], foregroundColor: .white, markSize: 30, largeMarkSize: 58)
        }
        if haystack.contains("instagram") {
            return .init(name: "Instagram", mark: "", symbolName: "camera.fill", backgroundColors: ["#F58529", "#DD2A7B", "#8134AF", "#515BD4"], foregroundColor: .white)
        }
        if haystack.contains("twitter.com") || haystack.contains("x.com") || haystack.contains(" x ") || haystack.contains("twitter") {
            return .init(name: "X", mark: "X", symbolName: nil, backgroundColors: ["#000000", "#1C1C1E"], foregroundColor: .white, markSize: 25, largeMarkSize: 52)
        }
        if haystack.contains("facebook") || haystack.contains("fb.watch") {
            return .init(name: "Facebook", mark: "f", symbolName: nil, backgroundColors: ["#1877F2", "#0B4FB3"], foregroundColor: .white, markSize: 30, largeMarkSize: 60)
        }
        if haystack.contains("threads.net") || haystack.contains("threads.com") || haystack.contains("threads") {
            return .init(name: "Threads", mark: "@", symbolName: nil, backgroundColors: ["#000000", "#2B2B2F"], foregroundColor: .white, markSize: 28, largeMarkSize: 56)
        }
        if haystack.contains("reddit") || haystack.contains("redd.it") {
            return .init(name: "Reddit", mark: "r/", symbolName: nil, backgroundColors: ["#FF4500", "#8F2500"], foregroundColor: .white, markSize: 22, largeMarkSize: 46)
        }
        if haystack.contains("spotify") {
            return .init(name: "Spotify", mark: "", symbolName: "music.note", backgroundColors: ["#1DB954", "#093B1F"], foregroundColor: .black)
        }
        if haystack.contains("pinterest") || haystack.contains("pin.it") {
            return .init(name: "Pinterest", mark: "P", symbolName: nil, backgroundColors: ["#E60023", "#7A0012"], foregroundColor: .white, markSize: 27, largeMarkSize: 58)
        }
        if haystack.contains("linkedin") {
            return .init(name: "LinkedIn", mark: "in", symbolName: nil, backgroundColors: ["#0A66C2", "#073D73"], foregroundColor: .white, markSize: 23, largeMarkSize: 48)
        }
        if haystack.contains("vimeo") {
            return .init(name: "Vimeo", mark: "v", symbolName: nil, backgroundColors: ["#1AB7EA", "#0A5C79"], foregroundColor: .white, markSize: 29, largeMarkSize: 58)
        }
        if haystack.contains("soundcloud") {
            return .init(name: "SoundCloud", mark: "", symbolName: "waveform", backgroundColors: ["#FF7700", "#8F3A00"], foregroundColor: .white)
        }
        if haystack.contains("bluesky") || haystack.contains("bsky.app") {
            return .init(name: "Bluesky", mark: "B", symbolName: nil, backgroundColors: ["#1185FE", "#62C6FF"], foregroundColor: .white, markSize: 27, largeMarkSize: 56)
        }
        if haystack.contains("maps") || haystack.contains("google.com/maps") || haystack.contains("maps.apple") {
            return .init(name: "Maps", mark: "", symbolName: "mappin.and.ellipse", backgroundColors: ["#34A853", "#0F6B3B"], foregroundColor: .white)
        }
        return nil
    }
}

struct SaviSVGDataThumbnail: UIViewRepresentable {
    let dataURL: String

    func makeCoordinator() -> Coordinator {
        Coordinator(dataURL: dataURL)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        load(dataURL, into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard context.coordinator.dataURL != dataURL else { return }
        context.coordinator.dataURL = dataURL
        load(dataURL, into: uiView)
    }

    private func load(_ dataURL: String, into webView: WKWebView) {
        let escaped = dataURL
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
        let html = """
        <!doctype html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width,initial-scale=1">
            <style>
              html, body { margin:0; width:100%; height:100%; overflow:hidden; background:transparent; }
              img { width:100%; height:100%; object-fit:cover; display:block; }
            </style>
          </head>
          <body><img src="\(escaped)" /></body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    final class Coordinator {
        var dataURL: String

        init(dataURL: String) {
            self.dataURL = dataURL
        }
    }
}

struct FolderCard: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let folder: SaviFolder
    var isReordering = false
    var isDragged = false

    private var isLocked: Bool {
        folder.locked && !store.isProtectedKeeperUnlocked(folder)
    }

    var body: some View {
        let style = SaviFolderVisualStyle.make(for: folder, colorScheme: colorScheme)
        Button {
            if !isReordering {
                store.openFolder(folder)
            }
        } label: {
            HStack(spacing: 12) {
                FolderIconBadge(
                    symbolName: folder.symbolName,
                    color: style.baseHex,
                    imageDataURL: folder.usesImageBackground ? nil : folder.image,
                    size: 42,
                    cornerRadius: 13,
                    font: SaviType.ui(.body, weight: .black),
                    background: style.iconBackground,
                    foreground: style.iconForeground,
                    publicBadgeStyle: folder.isPublic ? style : nil
                )
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(folder.name)
                            .font(SaviType.display(size: 20, weight: .black))
                            .foregroundStyle(style.text)
                            .shadow(color: style.titleShadow, radius: style.titleShadowRadius, x: 0, y: 1)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        if folder.locked {
                            Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                                .font(.caption.weight(.black))
                                .foregroundStyle(style.countForeground)
                        }
                    }
                    if isLocked {
                        FolderCountLabel(
                            text: "Locked",
                            style: style
                        )
                    }
                }
                Spacer()
                if isReordering {
                    Image(systemName: "line.3.horizontal")
                        .font(.subheadline.weight(.black))
                        .frame(width: 36, height: 36)
                        .background(SaviTheme.softAccent)
                        .foregroundStyle(.black)
                        .clipShape(Circle())
                } else if !folder.system {
                    Button {
                        store.openFolderEditor(folder)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption.weight(.black))
                            .frame(width: 32, height: 32)
                            .background(style.countBackground.opacity(0.88))
                            .foregroundStyle(style.countForeground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(SaviPressScaleButtonStyle())
                }
            }
            .padding(14)
            .background(FolderTileBackground(folder: folder, style: style))
            .clipShape(RoundedRectangle(cornerRadius: SaviRadius.folder, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SaviRadius.folder, style: .continuous)
                    .stroke(style.stroke, lineWidth: colorScheme == .light ? 1.15 : 1)
            )
            .shadow(color: style.shadow, radius: SaviShadow.folderRadius(colorScheme), x: 0, y: SaviShadow.folderY(colorScheme))
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("\(folder.name), \(folder.isPublic ? "Public, " : "")\(isLocked ? "Locked" : "\(store.count(in: folder)) saves")")
        .scaleEffect(isDragged ? 1.02 : 1)
        .opacity(isDragged ? 0.68 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isDragged)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isReordering)
    }
}
