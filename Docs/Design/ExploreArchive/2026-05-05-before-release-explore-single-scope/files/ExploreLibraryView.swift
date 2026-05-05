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

struct ExploreLibraryView: View {
    @EnvironmentObject private var store: SaviStore
    @Binding var seed: Int

    private var emptyTitle: String {
        switch store.exploreScope {
        case .all, .mine: return "No browseable saves yet"
        case .friends: return "No friend links yet"
        }
    }

    private var emptyMessage: String {
        switch store.exploreScope {
        case .all:
            return "Links, videos, images, and places will show up here when they are not private or paste-bin material."
        case .mine:
            return "Your public-feeling links, videos, images, and places will show here. Private, paste, and document saves stay out."
        case .friends:
            return "Friend links appear here when they come from public Folders."
        }
    }

    var body: some View {
        let snapshot = store.exploreSnapshot(seed: seed, scope: store.exploreScope)

        VStack(alignment: .leading, spacing: 12) {
            ExploreCompactHeader(snapshot: snapshot)

            ExploreScopeControl()

            if snapshot.items.isEmpty {
                EmptyStateView(
                    symbol: "sparkles",
                    title: emptyTitle,
                    message: emptyMessage
                )
            } else if let hero = snapshot.items.first {
                ExploreMosaicBoard(seed: seed, hero: hero, items: Array(snapshot.items.dropFirst()))
                    .transition(.opacity)
                    .id("\(store.exploreScope.rawValue)-\(seed)")
            }

            if !SaviReleaseGate.socialFeaturesEnabled {
                ExploreSocialTeaserCard()
            }
        }
    }
}

private struct ExploreCompactHeader: View {
    @EnvironmentObject private var store: SaviStore
    let snapshot: SaviExploreSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Explore")
                    .font(SaviType.display(size: 30, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(1)

                Text(SaviReleaseGate.socialFeaturesEnabled
                    ? "A fresh mix from you and your friends."
                    : "A fresh mix of what you saved.")
                    .font(SaviType.reading(.subheadline, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Text(snapshot.statusText)
                    .font(SaviType.ui(.caption2, weight: .bold))
                    .foregroundStyle(SaviTheme.metadataText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                if snapshot.seenCount > 0 {
                    ExploreHeaderIconButton(
                        symbolName: "arrow.counterclockwise",
                        background: SaviTheme.surfaceRaised,
                        foreground: SaviTheme.accentText,
                        accessibilityLabel: "Reset Explore history"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                            store.resetExploreHistory()
                        }
                    }
                }

                ExploreHeaderIconButton(
                    symbolName: "shuffle",
                    background: SaviTheme.chartreuse,
                    foreground: .black,
                    accessibilityLabel: "Shuffle Explore"
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                        store.shuffleExplore()
                    }
                }
            }
            .padding(.top, 5)
        }
        .padding(.bottom, 2)
    }
}

private struct ExploreHeaderIconButton: View {
    let symbolName: String
    let background: Color
    let foreground: Color
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.subheadline.weight(.black))
                .frame(width: 32, height: 32)
                .background(background)
                .foregroundStyle(foreground)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

struct ExploreScopeControl: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ExploreScope.allCases) { scope in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        store.setExploreScope(scope)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: scope.symbolName)
                            .font(.caption.weight(.black))
                        Text(scope.title)
                            .font(SaviType.ui(.caption, weight: .black))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .padding(.horizontal, 8)
                    .background(scope == store.exploreScope ? SaviTheme.chartreuse : SaviTheme.surface)
                    .foregroundStyle(scope == store.exploreScope ? Color.black : SaviTheme.text)
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(scope == store.exploreScope ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show \(scope.title) in Explore")
            }
        }
    }
}

private struct ExploreSocialTeaserCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(SaviType.ui(.subheadline, weight: .black))
                .frame(width: 38, height: 38)
                .background(SaviTheme.softAccent.opacity(0.58))
                .foregroundStyle(SaviTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text("Friends are coming")
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)

                    Text("BETA")
                        .font(SaviType.ui(.caption2, weight: .black))
                        .tracking(0.5)
                        .padding(.horizontal, 7)
                        .frame(height: 20)
                        .background(SaviTheme.chartreuse.opacity(0.78))
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }

                Text("Soon you’ll be able to follow friends and see the saves they choose to make public.")
                    .font(SaviType.reading(.caption, weight: .regular))
                    .foregroundStyle(SaviTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(13)
        .background(SaviTheme.surface.opacity(0.66))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(SaviTheme.cardStroke.opacity(0.72), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Friends are coming. Beta. Soon you'll be able to follow friends and see the saves they choose to make public.")
    }
}

struct ExploreEditorialFeed: View {
    let seed: Int
    let items: [SaviItem]

    private var lead: ExploreEditorialEntry? {
        items.first.map { ExploreEditorialEntry(index: 0, item: $0) }
    }

    private var sections: [ExploreEditorialSection] {
        let entries = items.dropFirst().enumerated().map { offset, item in
            ExploreEditorialEntry(index: offset + 1, item: item)
        }
        let patternSets: [[ExploreEditorialSectionKind]] = [
            [.pair, .headlines, .feature, .pair],
            [.feature, .pair, .headlines, .pair],
            [.pair, .feature, .headlines, .pair]
        ]
        let pattern = patternSets[abs(seed) % patternSets.count]
        var result: [ExploreEditorialSection] = []
        var cursor = 0
        var sectionIndex = 0

        while cursor < entries.count {
            let preferred = pattern[sectionIndex % pattern.count]
            let remaining = entries.count - cursor
            let kind = ExploreEditorialSectionKind.bestFit(preferred: preferred, remaining: remaining)
            let nextCursor = min(cursor + kind.itemCount, entries.count)
            result.append(
                ExploreEditorialSection(
                    index: sectionIndex,
                    kind: kind,
                    entries: Array(entries[cursor..<nextCursor])
                )
            )
            cursor = nextCursor
            sectionIndex += 1
        }

        return result
    }

    var body: some View {
        LazyVStack(spacing: 16) {
            if let lead {
                ExploreLeadStoryCard(entry: lead)
            }

            ForEach(sections) { section in
                switch section.kind {
                case .pair:
                    ExploreStoryPairSection(section: section)
                case .headlines:
                    ExploreHeadlineCluster(section: section)
                case .feature:
                    if let entry = section.entries.first {
                        ExploreFeatureStoryCard(entry: entry)
                    }
                }
            }
        }
    }
}

private struct ExploreEditorialEntry: Identifiable {
    let index: Int
    let item: SaviItem

    var id: String {
        "\(index)-\(item.id)"
    }
}

private struct ExploreEditorialSection: Identifiable {
    let index: Int
    let kind: ExploreEditorialSectionKind
    let entries: [ExploreEditorialEntry]

    var id: String {
        "\(index)-\(kind.rawValue)-\(entries.map(\.id).joined(separator: "-"))"
    }
}

private enum ExploreEditorialSectionKind: String {
    case pair
    case headlines
    case feature

    var itemCount: Int {
        switch self {
        case .pair: return 2
        case .headlines: return 3
        case .feature: return 1
        }
    }

    static func bestFit(preferred: ExploreEditorialSectionKind, remaining: Int) -> ExploreEditorialSectionKind {
        if remaining <= 1 { return .feature }
        if remaining == 2 { return preferred == .headlines ? .pair : preferred }
        return preferred
    }
}

private struct ExploreLeadStoryCard: View {
    @EnvironmentObject private var store: SaviStore
    let entry: ExploreEditorialEntry

    private var item: SaviItem {
        entry.item
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ExploreStoryImage(item: item, height: item.exploreHasMeaningfulArt ? 190 : 118, large: true)
                .overlay(alignment: .topLeading) {
                    ExploreStoryTypeBadge(item: item)
                        .padding(12)
                }
                .overlay(alignment: .topTrailing) {
                    ExploreFriendQuickActions(item: item, compact: false)
                        .padding(12)
                }

            VStack(alignment: .leading, spacing: 10) {
                ExploreStoryByline(item: item, prominence: .large)

                Text(item.title)
                    .font(SaviType.reading(.title3, weight: .bold))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(3)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)

                if let snippet = item.itemDescription.nilIfBlank {
                    Text(snippet)
                        .font(SaviType.reading(.subheadline, weight: .regular))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(2)
                        .lineSpacing(2)
                }

                ExploreTagLine(item: item)
            }
            .padding(14)
        }
        .background(SaviTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
        .modifier(ExploreShuffleTapTarget(item: item))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let username = store.friendUsername(forExploreItem: item) {
            return "\(item.title), shared by \(username)."
        }
        return item.title
    }
}

private struct ExploreFeatureStoryCard: View {
    let entry: ExploreEditorialEntry

    private var item: SaviItem {
        entry.item
    }

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            ExploreStoryImage(item: item, height: 116, large: false)
                .frame(width: 124)
                .overlay(alignment: .topLeading) {
                    ExploreStoryTypeBadge(item: item, compact: true)
                        .padding(8)
                }

            VStack(alignment: .leading, spacing: 8) {
                ExploreStoryByline(item: item, prominence: .standard)

                Text(item.title)
                    .font(SaviType.reading(.headline, weight: .bold))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(3)
                    .lineSpacing(1.5)
                    .multilineTextAlignment(.leading)

                if let snippet = item.itemDescription.nilIfBlank {
                    Text(snippet)
                        .font(SaviType.reading(.caption, weight: .regular))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(2)
                }

                HStack(alignment: .center) {
                    ExploreTagLine(item: item)
                    Spacer(minLength: 0)
                    ExploreFriendQuickActions(item: item, compact: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(SaviTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
        .modifier(ExploreShuffleTapTarget(item: item))
    }
}

private struct ExploreStoryPairSection: View {
    let section: ExploreEditorialSection

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(section.entries) { entry in
                ExploreStoryTileCard(entry: entry)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct ExploreStoryTileCard: View {
    let entry: ExploreEditorialEntry

    private var item: SaviItem {
        entry.item
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ExploreStoryImage(item: item, height: item.exploreHasMeaningfulArt ? 126 : 76, large: false)
                .overlay(alignment: .topLeading) {
                    ExploreStoryTypeBadge(item: item, compact: true)
                        .padding(8)
                }
                .overlay(alignment: .topTrailing) {
                    ExploreFriendQuickActions(item: item, compact: true)
                        .padding(8)
                }

            VStack(alignment: .leading, spacing: 8) {
                ExploreStoryByline(item: item, prominence: .compact)

                Text(item.title)
                    .font(SaviType.reading(.subheadline, weight: .bold))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(3)
                    .lineSpacing(1.5)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 58, alignment: .topLeading)
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(SaviTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
        .modifier(ExploreShuffleTapTarget(item: item))
    }
}

private struct ExploreHeadlineCluster: View {
    let section: ExploreEditorialSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "newspaper.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(SaviTheme.accentText)
                Text("Worth a look")
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 2)

            ForEach(section.entries) { entry in
                ExploreHeadlineRow(entry: entry)
                if entry.id != section.entries.last?.id {
                    Divider()
                        .overlay(SaviTheme.cardStroke)
                        .padding(.leading, 84)
                }
            }
        }
        .background(SaviTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SaviTheme.cardStroke, lineWidth: 1)
        )
    }
}

private struct ExploreHeadlineRow: View {
    let entry: ExploreEditorialEntry

    private var item: SaviItem {
        entry.item
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            ExploreStoryImage(item: item, height: 60, large: false)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 5) {
                ExploreStoryByline(item: item, prominence: .compact)

                Text(item.title)
                    .font(SaviType.reading(.subheadline, weight: .bold))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(2)
                    .lineSpacing(1)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ExploreFriendQuickActions(item: item, compact: true)
        }
        .padding(12)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .modifier(ExploreShuffleTapTarget(item: item))
    }
}

private struct ExploreStoryImage: View {
    let item: SaviItem
    let height: CGFloat
    var large = false

    var body: some View {
        ItemThumb(item: item, large: large, enablesPressPreview: false)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .background(SaviTheme.surfaceRaised)
    }
}

private struct ExploreStoryTypeBadge: View {
    let item: SaviItem
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: item.type.symbolName)
                .accessibilityHidden(true)
            Text(item.type.label)
                .lineLimit(1)
        }
        .font(SaviType.ui(compact ? .caption2 : .caption, weight: .black))
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? 7 : 9)
        .frame(height: compact ? 24 : 28)
        .background(Color.black.opacity(0.48))
        .clipShape(Capsule())
    }
}

private enum ExploreBylineProminence {
    case large
    case standard
    case compact
}

private struct ExploreStoryByline: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem
    var prominence: ExploreBylineProminence = .standard
    private let friendYellow = Color(hex: "#FFE45E")

    var body: some View {
        if let link = store.friendLink(forExploreItem: item) {
            friendByline(link)
        } else {
            ownByline
        }
    }

    private func friendByline(_ link: SaviSharedLink) -> some View {
        let friend = store.friend(for: link)
        return HStack(spacing: prominence == .compact ? 6 : 8) {
            Circle()
                .fill(Color(hex: friend.avatarColor))
                .frame(width: avatarSize, height: avatarSize)
                .overlay(
                    Text(friend.username.prefix(1).uppercased())
                        .font(SaviType.ui(prominence == .large ? .caption : .caption2, weight: .black))
                        .foregroundStyle(SaviTheme.foreground(onHex: friend.avatarColor))
                )

            Text(friend.displayName.nilIfBlank ?? "@\(friend.username)")
                .font(SaviType.ui(nameFont, weight: .black))
                .foregroundStyle(friendYellow)
                .lineLimit(1)

            Text("posted")
                .font(SaviType.ui(.caption2, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)

            SavedAgoText(savedAt: link.sharedAt)
                .font(SaviType.ui(.caption2, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.horizontal, prominence == .compact ? 7 : 9)
        .frame(height: prominence == .compact ? 27 : 32)
        .background(Color.black.opacity(0.78))
        .clipShape(Capsule())
    }

    private var ownByline: some View {
        HStack(spacing: 6) {
            Label(item.type.label, systemImage: item.type.symbolName)
                .lineLimit(1)
            ExploreDot()
            Text(store.sourceLabel(forExploreItem: item))
                .lineLimit(1)
                .truncationMode(.tail)
            ExploreDot()
            SavedAgoText(savedAt: item.savedAt)
        }
        .font(SaviType.ui(prominence == .compact ? .caption2 : .caption, weight: .bold))
        .foregroundStyle(SaviTheme.textMuted)
        .lineLimit(1)
    }

    private var avatarSize: CGFloat {
        switch prominence {
        case .large: return 24
        case .standard: return 22
        case .compact: return 18
        }
    }

    private var nameFont: Font.TextStyle {
        switch prominence {
        case .large: return .subheadline
        case .standard: return .caption
        case .compact: return .caption2
        }
    }
}

struct ExploreMosaicBoard: View {
    let seed: Int
    let hero: SaviItem
    let items: [SaviItem]
    private let spacing: CGFloat = 12

    private var indexedItems: [IndexedExploreItem] {
        items.enumerated().map { offset, item in
            let index = offset + 1
            return IndexedExploreItem(
                index: index,
                item: item,
                variant: ExploreShuffleVariant.variant(for: index, item: item)
            )
        }
    }

    private var mosaicSections: [ExploreMosaicSection] {
        var sections: [ExploreMosaicSection] = []
        var cursor = 0
        var sectionIndex = 0
        let patterns: [[ExploreMosaicSectionKind]] = [
            [.feature, .wide, .offsetPair, .spotlightPair, .featureReversed],
            [.offsetPair, .featureReversed, .wide, .feature, .spotlightPair],
            [.wide, .feature, .offsetPair, .featureReversed, .spotlightPair]
        ]
        let pattern = patterns[abs(seed) % patterns.count]

        while cursor < indexedItems.count {
            let remaining = indexedItems.count - cursor
            let preferredKind = pattern[sectionIndex % pattern.count]
            let kind = ExploreMosaicSectionKind.bestFit(preferred: preferredKind, remaining: remaining)
            let nextCursor = min(cursor + kind.itemCount, indexedItems.count)
            sections.append(
                ExploreMosaicSection(
                    index: sectionIndex,
                    kind: kind,
                    entries: Array(indexedItems[cursor..<nextCursor])
                )
            )
            cursor = nextCursor
            sectionIndex += 1
        }

        return sections
    }

    var body: some View {
        LazyVStack(spacing: spacing) {
            ExploreMosaicGeometryRow(height: ExploreShuffleVariant.hero.height) { width in
                ExploreShuffleCard(item: hero, variant: .hero, index: 0, width: width)
            }

            ForEach(mosaicSections) { section in
                ExploreMosaicGeometryRow(height: section.height(spacing: spacing)) { width in
                    ExploreMosaicSectionView(
                        section: section,
                        spacing: spacing,
                        width: width
                    )
                }
            }
        }
    }
}

private struct ExploreMosaicGeometryRow<Content: View>: View {
    let height: CGFloat
    let content: (CGFloat) -> Content

    var body: some View {
        GeometryReader { proxy in
            let rowWidth = max(0, proxy.size.width)
            content(rowWidth)
                .frame(width: rowWidth, height: height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }
}

private struct ExploreMosaicSection: Identifiable {
    let index: Int
    let kind: ExploreMosaicSectionKind
    let entries: [IndexedExploreItem]

    var id: String {
        "\(index)-\(kind.rawValue)-\(entries.map(\.id).joined(separator: "-"))"
    }

    func height(spacing: CGFloat) -> CGFloat {
        switch kind {
        case .feature, .featureReversed:
            return ExploreShuffleVariant.tall.height
        case .wide:
            return ExploreShuffleVariant.wide.height
        case .offsetPair:
            return ExploreShuffleVariant.square.height
        case .spotlightPair:
            return ExploreShuffleVariant.spotlight.height
        }
    }
}

private enum ExploreMosaicSectionKind: String {
    case feature
    case featureReversed
    case wide
    case offsetPair
    case spotlightPair

    var itemCount: Int {
        switch self {
        case .feature, .featureReversed:
            return 3
        case .wide:
            return 1
        case .offsetPair, .spotlightPair:
            return 2
        }
    }

    static func bestFit(preferred: ExploreMosaicSectionKind, remaining: Int) -> ExploreMosaicSectionKind {
        if remaining <= 1 { return .wide }
        if remaining == 2 { return preferred.itemCount == 2 ? preferred : .offsetPair }
        return preferred
    }
}

private struct ExploreMosaicSectionView: View {
    let section: ExploreMosaicSection
    let spacing: CGFloat
    let width: CGFloat

    private var columnWidth: CGFloat {
        max(0, (width - spacing) / 2)
    }

    var body: some View {
        Group {
            switch section.kind {
            case .feature:
                featureRow(reversed: false)
            case .featureReversed:
                featureRow(reversed: true)
            case .wide:
                wideRow
            case .offsetPair:
                offsetPairRow
            case .spotlightPair:
                spotlightPairRow
            }
        }
        .frame(width: width, height: section.height(spacing: spacing), alignment: .topLeading)
    }

    @ViewBuilder
    private func featureRow(reversed: Bool) -> some View {
        if section.entries.count >= 3 {
            let lead = section.entries[0]
            let firstSmall = section.entries[1]
            let secondSmall = section.entries[2]

            HStack(alignment: .top, spacing: spacing) {
                if reversed {
                    smallStack(firstSmall, secondSmall)
                    tallCard(lead)
                } else {
                    tallCard(lead)
                    smallStack(firstSmall, secondSmall)
                }
            }
            .frame(width: width, alignment: .leading)
        } else if section.entries.count == 2 {
            offsetPairRow
        } else {
            wideRow
        }
    }

    private func tallCard(_ entry: IndexedExploreItem) -> some View {
        ExploreShuffleCard(
            item: entry.item,
            variant: entry.tallVariant,
            index: entry.index,
            width: columnWidth
        )
    }

    private func smallStack(_ first: IndexedExploreItem, _ second: IndexedExploreItem) -> some View {
        VStack(spacing: spacing) {
            smallCard(first)
            smallCard(second)
        }
        .frame(width: columnWidth)
    }

    private func smallCard(_ entry: IndexedExploreItem) -> some View {
        ExploreShuffleCard(
            item: entry.item,
            variant: entry.smallVariant,
            index: entry.index,
            width: columnWidth
        )
    }

    @ViewBuilder
    private var wideRow: some View {
        if let entry = section.entries.first {
            ExploreShuffleCard(
                item: entry.item,
                variant: entry.wideVariant,
                index: entry.index,
                width: width
            )
        }
    }

    @ViewBuilder
    private var offsetPairRow: some View {
        if section.entries.count >= 2 {
            let first = section.entries[0]
            let second = section.entries[1]
            let leadWidth = asymmetricWidth(leadingShare: section.index.isMultiple(of: 2) ? 0.61 : 0.45)
            let trailWidth = max(0, width - spacing - leadWidth)

            HStack(alignment: .top, spacing: spacing) {
                ExploreShuffleCard(
                    item: first.item,
                    variant: section.index.isMultiple(of: 2) ? first.squareVariant : first.textVariant,
                    index: first.index,
                    width: leadWidth
                )

                ExploreShuffleCard(
                    item: second.item,
                    variant: section.index.isMultiple(of: 2) ? second.textVariant : second.squareVariant,
                    index: second.index,
                    width: trailWidth
                )
            }
            .frame(width: width, alignment: .leading)
        } else {
            wideRow
        }
    }

    @ViewBuilder
    private var spotlightPairRow: some View {
        if section.entries.count >= 2 {
            let first = section.entries[0]
            let second = section.entries[1]
            let leadWidth = asymmetricWidth(leadingShare: section.index.isMultiple(of: 2) ? 0.42 : 0.58)
            let trailWidth = max(0, width - spacing - leadWidth)

            HStack(alignment: .top, spacing: spacing) {
                ExploreShuffleCard(
                    item: first.item,
                    variant: first.spotlightVariant,
                    index: first.index,
                    width: leadWidth
                )

                ExploreShuffleCard(
                    item: second.item,
                    variant: second.spotlightVariant,
                    index: second.index,
                    width: trailWidth
                )
            }
            .frame(width: width, alignment: .leading)
        } else {
            wideRow
        }
    }

    private func asymmetricWidth(leadingShare: CGFloat) -> CGFloat {
        let minimumColumnWidth: CGFloat = 150
        return max(
            minimumColumnWidth,
            min(width - spacing - minimumColumnWidth, (width - spacing) * leadingShare)
        )
    }

}

private struct IndexedExploreItem: Identifiable {
    let index: Int
    let item: SaviItem
    let variant: ExploreShuffleVariant

    var id: String { "\(index)-\(item.id)-\(variant.id)" }

    var smallVariant: ExploreShuffleVariant {
        item.exploreHasMeaningfulArt ? .compact : .text
    }

    var squareVariant: ExploreShuffleVariant {
        item.exploreHasMeaningfulArt ? .square : .text
    }

    var spotlightVariant: ExploreShuffleVariant {
        item.exploreHasMeaningfulArt ? .spotlight : .text
    }

    var textVariant: ExploreShuffleVariant {
        .text
    }

    var tallVariant: ExploreShuffleVariant {
        .tall
    }

    var wideVariant: ExploreShuffleVariant {
        item.exploreHasMeaningfulArt ? .wide : .textWide
    }
}

enum ExploreShuffleVariant {
    case hero
    case tall
    case wide
    case square
    case spotlight
    case compact
    case text
    case textWide

    var id: String {
        switch self {
        case .hero: return "hero"
        case .tall: return "tall"
        case .wide: return "wide"
        case .square: return "square"
        case .spotlight: return "spotlight"
        case .compact: return "compact"
        case .text: return "text"
        case .textWide: return "text-wide"
        }
    }

    var height: CGFloat {
        switch self {
        case .hero: return 216
        case .tall: return 278
        case .wide: return 178
        case .square: return 170
        case .spotlight: return 152
        case .compact: return 136
        case .text: return 154
        case .textWide: return 168
        }
    }

    var titleLimit: Int {
        switch self {
        case .hero: return 3
        case .tall: return 4
        case .wide: return 2
        case .square: return 3
        case .spotlight: return 2
        case .compact: return 2
        case .text: return 3
        case .textWide: return 3
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .hero: return 18
        default: return 14
        }
    }

    var usesArtwork: Bool {
        switch self {
        case .text, .textWide: return false
        default: return true
        }
    }

    var isCompactTile: Bool {
        switch self {
        case .hero, .tall, .wide, .textWide:
            return false
        case .square, .spotlight, .compact, .text:
            return true
        }
    }

    static func variant(for index: Int, item: SaviItem) -> ExploreShuffleVariant {
        let hasMeaningfulArt = item.exploreHasMeaningfulArt
        if !hasMeaningfulArt || index.isMultiple(of: 7) { return .text }
        switch index % 6 {
        case 0: return .tall
        case 1: return .square
        case 2: return .compact
        case 3: return .tall
        case 4: return .square
        default: return .compact
        }
    }
}

private extension SaviItem {
    var exploreHasMeaningfulArt: Bool {
        thumbnail?.nilIfBlank != nil || type == .image || type == .video || type == .place
    }
}

struct ExploreShuffleCard: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem
    let variant: ExploreShuffleVariant
    let index: Int
    var width: CGFloat?

    private var snippet: String? {
        item.itemDescription.nilIfBlank ?? item.url?.nilIfBlank
    }

    private var usesArtworkPresentation: Bool {
        guard variant.usesArtwork else { return false }
        return item.thumbnail?.nilIfBlank != nil ||
            item.type == .image ||
            item.type == .video ||
            item.type == .place
    }

    var body: some View {
        constrainedCardBody
            .clipShape(RoundedRectangle(cornerRadius: variant.cornerRadius, style: .continuous))
            .overlay(cardStroke)
            .overlay(alignment: usesArtworkPresentation ? .topTrailing : .bottomTrailing) {
                ExploreFriendQuickActions(item: item, compact: variant.isCompactTile)
                    .padding(friendActionPadding)
            }
            .modifier(ExploreShuffleTapTarget(item: item))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var constrainedCardBody: some View {
        if let width {
            cardBody
                .frame(width: width, height: variant.height)
        } else {
            cardBody
                .frame(maxWidth: .infinity)
                .frame(height: variant.height)
        }
    }

    @ViewBuilder
    private var cardBody: some View {
        if usesArtworkPresentation {
            artworkOverlayCard
        } else {
            textCard
        }
    }

    private var artworkOverlayCard: some View {
        ZStack(alignment: .bottomLeading) {
            ItemThumb(item: item, large: variant == .hero || variant == .tall, enablesPressPreview: false)
                .frame(width: width, height: variant.height)
                .clipped()

            ExploreImageScrim()
                .frame(width: width, height: variant.height)

            VStack(alignment: .leading, spacing: variant == .compact ? 6 : 8) {
                ExploreShuffleMetaLine(item: item, compact: variant.isCompactTile, onImage: true)
                    .padding(.horizontal, variant.isCompactTile ? 6 : 8)
                    .frame(minHeight: variant.isCompactTile ? 22 : 24)
                    .background(Color.black.opacity(0.22))
                    .clipShape(Capsule())
                    .padding(.trailing, topActionReserve)

                Text(item.title)
                    .font(titleFont)
                    .foregroundStyle(.white)
                    .lineLimit(variant.titleLimit)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black.opacity(0.34), radius: 5, y: 2)

                if variant == .hero, let snippet {
                    Text(snippet)
                        .font(SaviType.reading(.subheadline, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                if variant == .hero || variant == .tall {
                    ExploreTagLine(item: item, onImage: true)
                }
            }
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.bottom, contentBottomPadding)
            .frame(width: width, height: variant.height, alignment: .bottomLeading)
        }
        .frame(width: width, height: variant.height)
    }

    private var mediaTileCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                ItemThumb(item: item, large: false, enablesPressPreview: false)
                    .frame(maxWidth: .infinity)
                    .frame(height: mediaTileImageHeight)
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.34)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )

                HStack(spacing: 5) {
                    Image(systemName: item.type.symbolName)
                        .accessibilityHidden(true)
                    Text(item.type.label)
                        .lineLimit(1)
                }
                .font(SaviType.ui(.caption2, weight: .black))
                .foregroundStyle(.white.opacity(0.86))
                .padding(.horizontal, 8)
                .frame(height: 23)
                .background(Color.black.opacity(0.30))
                .clipShape(Capsule())
                .padding(9)
            }
            .frame(maxWidth: .infinity)
            .frame(height: mediaTileImageHeight)
            .clipped()

            VStack(alignment: .leading, spacing: 7) {
                ExploreShuffleMetaLine(item: item, compact: true)

                Text(item.title)
                    .font(SaviType.reading(.subheadline, weight: .bold))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.leading)
                    .layoutPriority(2)

                ExploreTagLine(item: item)
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(SaviTheme.surface)
    }

    private var textCard: some View {
        ZStack(alignment: .topLeading) {
            SaviTheme.surface

            VStack(alignment: .leading, spacing: 9) {
                ExploreShuffleMetaLine(item: item, compact: true)
                    .padding(.trailing, bottomActionReserve)

                Text(item.title)
                    .font(SaviType.reading(.subheadline, weight: .bold))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(variant.titleLimit)
                    .minimumScaleFactor(0.84)
                    .multilineTextAlignment(.leading)
                    .layoutPriority(2)

                if showsSnippetInTextCard, let snippet {
                    Text(snippet)
                        .font(SaviType.reading(.caption, weight: .regular))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(variant == .square ? 1 : 2)
                        .multilineTextAlignment(.leading)
                }

                if variant == .hero || variant == .tall {
                    ExploreTagLine(item: item)
                }
            }
            .padding(13)
            .padding(.bottom, bottomActionReserve)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: variant.cornerRadius, style: .continuous)
            .stroke(
                usesArtworkPresentation ? Color.white.opacity(0.13) : SaviTheme.cardStroke,
                lineWidth: 1
            )
    }

    private var titleFont: Font {
        switch variant {
        case .hero:
            return SaviType.reading(.title2, weight: .bold)
        case .tall:
            return SaviType.reading(.headline, weight: .bold)
        case .wide:
            return SaviType.reading(.headline, weight: .bold)
        case .square:
            return SaviType.reading(.subheadline, weight: .bold)
        case .spotlight:
            return SaviType.reading(.callout, weight: .bold)
        case .compact:
            return SaviType.reading(.callout, weight: .bold)
        case .text:
            return SaviType.reading(.subheadline, weight: .bold)
        case .textWide:
            return SaviType.reading(.headline, weight: .bold)
        }
    }

    private var contentHorizontalPadding: CGFloat {
        switch variant {
        case .hero: return 16
        case .tall: return 14
        case .wide: return 14
        case .textWide: return 14
        case .square, .spotlight, .compact, .text: return 11
        }
    }

    private var contentBottomPadding: CGFloat {
        switch variant {
        case .hero: return 16
        case .tall: return 14
        case .wide: return 13
        case .textWide: return 13
        case .square, .spotlight, .compact, .text: return 11
        }
    }

    private var mediaTileImageHeight: CGFloat {
        switch variant {
        case .compact: return 74
        case .square, .spotlight: return 90
        default: return 90
        }
    }

    private var showsSnippetInTextCard: Bool {
        switch variant {
        case .hero, .tall, .wide, .square, .text, .textWide:
            return true
        case .spotlight, .compact:
            return false
        }
    }

    private var hasFriendActions: Bool {
        store.friendLink(forExploreItem: item) != nil
    }

    private var topActionReserve: CGFloat {
        hasFriendActions ? (variant.isCompactTile ? 72 : 94) : 0
    }

    private var bottomActionReserve: CGFloat {
        hasFriendActions && !usesArtworkPresentation ? (variant.isCompactTile ? 38 : 46) : 0
    }

    private var friendActionPadding: EdgeInsets {
        if usesArtworkPresentation {
            let inset: CGFloat = variant == .hero ? 12 : 8
            return EdgeInsets(top: inset, leading: 0, bottom: 0, trailing: inset)
        }
        return EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 10)
    }

    private var accessibilityLabel: String {
        if let username = store.friendUsername(forExploreItem: item) {
            return "\(item.title), shared by \(username). Double tap to like, tap to add to SAVI."
        }
        return "\(item.title). Tap to open."
    }
}

private struct ExploreImageScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color.black.opacity(0.00), location: 0.0),
                .init(color: Color.black.opacity(0.18), location: 0.42),
                .init(color: Color.black.opacity(0.52), location: 0.74),
                .init(color: Color.black.opacity(0.82), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct ExploreShuffleMetaLine: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem
    let compact: Bool
    var onImage = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            fullLine
            shortLine
        }
        .font(SaviType.ui(compact ? .caption2 : .caption, weight: .bold))
        .foregroundStyle(onImage ? Color.white.opacity(0.86) : SaviTheme.textMuted)
        .lineLimit(1)
        .minimumScaleFactor(0.78)
    }

    private var fullLine: some View {
        HStack(spacing: compact ? 5 : 6) {
            if compact {
                Image(systemName: item.type.symbolName)
                    .accessibilityHidden(true)
                if let username = store.friendUsername(forExploreItem: item) {
                    ExploreFriendBadge(username: username, compact: true)
                } else {
                    Text(item.type.label)
                        .lineLimit(1)
                }
            } else {
                Label(item.type.label, systemImage: item.type.symbolName)
                    .lineLimit(1)
                if let username = store.friendUsername(forExploreItem: item) {
                    ExploreFriendBadge(username: username)
                }
                ExploreDot(onImage: onImage)
                Text(store.sourceLabel(forExploreItem: item))
                    .lineLimit(1)
                    .truncationMode(.tail)
                ExploreDot(onImage: onImage)
                SavedAgoText(savedAt: item.savedAt)
                if store.isExploreSeen(item) {
                    ExploreDot(onImage: onImage)
                    Text("Seen")
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var shortLine: some View {
        HStack(spacing: 5) {
            Image(systemName: item.type.symbolName)
                .accessibilityHidden(true)

            if let username = store.friendUsername(forExploreItem: item) {
                ExploreFriendBadge(username: username, compact: true)
            } else {
                Text(item.type.label)
                    .lineLimit(1)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct ExploreShuffleTapTarget: ViewModifier {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem

    func body(content: Content) -> some View {
        content
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.42)
                    .onEnded { _ in
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        store.previewExploreCard(item)
                    }
            )
            .gesture(
                TapGesture(count: 2)
                    .exclusively(before: TapGesture())
                    .onEnded { value in
                        switch value {
                        case .first:
                            if store.toggleLikeForExploreItem(item) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } else {
                                store.openExploreCard(item)
                            }
                        case .second:
                            store.openExploreCard(item)
                        }
                    }
            )
    }
}

struct ExploreFriendQuickActions: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem
    var compact = false

    private var link: SaviSharedLink? {
        store.friendLink(forExploreItem: item)
    }

    var body: some View {
        if let link {
            let liked = store.isFriendLinkLiked(link)
            let alreadySaved = store.friendLinkAlreadySaved(link)
            HStack(spacing: compact ? 6 : 7) {
                Button {
                    store.toggleLikeFriendLink(link)
                } label: {
                    Image(systemName: liked ? "heart.fill" : "heart")
                }
                .buttonStyle(ExploreOverlayIconButtonStyle(active: liked, size: compact ? 32 : 40))
                .accessibilityLabel(liked ? "Unlike friend link" : "Like friend link")

                Button {
                    store.openFriendLinkSave(link)
                } label: {
                    Image(systemName: alreadySaved ? "checkmark.circle.fill" : "plus.circle.fill")
                }
                .buttonStyle(ExploreOverlayIconButtonStyle(active: alreadySaved, size: compact ? 32 : 40))
                .disabled(alreadySaved)
                .accessibilityLabel(alreadySaved ? "Friend link already saved" : "Save friend link to SAVI")
            }
        }
    }
}

struct ExploreOverlayIconButtonStyle: ButtonStyle {
    let active: Bool
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SaviType.ui(size < 40 ? .caption : .subheadline, weight: .black))
            .frame(width: size, height: size)
            .background(Color.black.opacity(configuration.isPressed ? 0.68 : 0.46))
            .foregroundStyle(active ? SaviTheme.chartreuse : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(active ? SaviTheme.chartreuse.opacity(0.45) : Color.white.opacity(0.18), lineWidth: 1)
            )
    }
}

struct ExploreDot: View {
    var onImage = false

    var body: some View {
        Circle()
            .fill((onImage ? Color.white.opacity(0.58) : SaviTheme.textMuted.opacity(0.55)))
            .frame(width: 3, height: 3)
            .accessibilityHidden(true)
    }
}

struct ExploreFriendBadge: View {
    let username: String
    var compact = false
    private let friendYellow = Color(hex: "#FFE45E")

    var body: some View {
        Text(username)
            .font(.system(.caption2, design: .monospaced).weight(.black))
            .lineLimit(1)
            .padding(.horizontal, compact ? 5 : 6)
            .padding(.vertical, compact ? 2 : 3)
            .background(Color.black.opacity(0.34))
            .foregroundStyle(friendYellow)
            .overlay(
                Capsule()
                    .stroke(friendYellow.opacity(0.36), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

struct SavedAgoText: View {
    let savedAt: Double
    var prefix: String?

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            Text(displayText(at: context.date))
                .lineLimit(1)
                .accessibilityLabel("Saved \(SaviText.relativeSavedTime(savedAt, now: context.date))")
        }
    }

    private func displayText(at date: Date) -> String {
        let value = SaviText.relativeSavedTime(savedAt, now: date)
        return prefix.map { "\($0) \(value)" } ?? value
    }
}

struct SavedAgoLabel: View {
    let savedAt: Double
    var prefix: String?

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 60)) { context in
            Label(displayText(at: context.date), systemImage: "clock")
                .lineLimit(1)
                .accessibilityLabel("Saved \(SaviText.relativeSavedTime(savedAt, now: context.date))")
        }
    }

    private func displayText(at date: Date) -> String {
        let value = SaviText.relativeSavedTime(savedAt, now: date)
        return prefix.map { "\($0) \(value)" } ?? value
    }
}

struct ExploreTagLine: View {
    @EnvironmentObject private var store: SaviStore
    let item: SaviItem
    var onImage = false

    private var visibleTags: [String] {
        let username = store.friendUsername(forExploreItem: item)?
            .replacingOccurrences(of: "@", with: "")
            .lowercased()
        let keeperTag = friendKeeperTag
        let mutedTags: Set<String> = [
            "friend", "friends", "link", "links", "article", "articles", "video", "videos",
            "image", "images", "post", "posts", "reel", "reels"
        ]

        return item.tags.filter { tag in
            let normalized = tag.lowercased()
            guard !mutedTags.contains(normalized) else { return false }
            if let username, normalized == username { return false }
            if let keeperTag, normalized == keeperTag { return false }
            return true
        }
        .prefix(2)
        .map { $0 }
    }

    private var friendKeeperTag: String? {
        guard store.isFriendExploreItem(item),
              let rawKeeper = item.tags.dropFirst(2).first
        else { return nil }
        return rawKeeper.lowercased()
    }

    var body: some View {
        if !visibleTags.isEmpty {
            ViewThatFits(in: .horizontal) {
                tagRow(visibleTags)
                tagRow(Array(visibleTags.prefix(1)))
            }
            .lineLimit(1)
        }
    }

    private func tagRow(_ tags: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(SaviType.ui(.caption2, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 7)
                    .frame(maxWidth: 112)
                    .frame(height: 22)
                    .background(onImage ? Color.black.opacity(0.24) : SaviTheme.surfaceRaised.opacity(0.78))
                    .foregroundStyle(onImage ? Color.white.opacity(0.84) : SaviTheme.textMuted)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(onImage ? Color.white.opacity(0.14) : SaviTheme.cardStroke, lineWidth: 1)
                    )
            }
        }
    }
}
