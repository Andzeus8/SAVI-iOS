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

struct SearchScreen: View {
    @EnvironmentObject private var store: SaviStore
    @State private var draftQuery = ""
    @State private var queryDebounceTask: Task<Void, Never>?
    @State private var visibleResultLimit = 40

    var body: some View {
        let results = store.filteredItems()
        let visibleResults = Array(results.prefix(visibleResultLimit))
        let trimmedDraftQuery = draftQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasLiveSearch = store.hasActiveSearchControls || !trimmedDraftQuery.isEmpty
        let recentGroups = hasLiveSearch ? [] : SaviSavedItemDateGrouper.groups(for: visibleResults)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    SearchHeaderBlock(resultCount: store.items.count)

                    SearchBar(
                        text: $draftQuery,
                        prompt: "Search titles, folders, tags, PDFs...",
                        showsSubmitButton: false
                    ) {
                        store.query = draftQuery
                    }
                        .id("search-bar")

                    SearchKindRail()

                    HStack(spacing: 10) {
                        SearchRefineButton()

                        Spacer(minLength: 8)

                        if store.hasActiveSearchControls {
                            SearchClearAllButton {
                                store.resetFilters()
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                    }

                    if hasLiveSearch {
                        ActiveSearchFiltersRow()
                    }

                    SearchResultsHeading(resultCount: results.count)

                    LazyVStack(alignment: .leading, spacing: 10) {
                        if hasLiveSearch {
                            ForEach(visibleResults) { item in
                                SaviTimelineItemRow(
                                    item: item,
                                    context: .search,
                                    showsMatchReasons: true,
                                    showsSnippet: true
                                )
                            }
                        } else {
                            ForEach(recentGroups) { group in
                                SavedItemDateGroupLabel(title: group.title)
                                    .padding(.top, group.id == recentGroups.first?.id ? 0 : 6)

                                ForEach(group.items) { item in
                                    SaviTimelineItemRow(item: item, context: .search)
                                }
                            }
                        }

                        if visibleResults.count < results.count {
                            FeedPageLoader(label: "Loading more matches") {
                                loadMoreSearchResults(total: results.count)
                            }
                            .id("search-more-\(visibleResultLimit)-\(results.count)")
                        }
                    }

                    if results.isEmpty {
                        EmptyStateView(
                            symbol: "magnifyingglass",
                            title: "Nothing found",
                            message: "Try a different word or filter."
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .background(SaviTheme.background.ignoresSafeArea())
            .onAppear {
                draftQuery = store.query
            }
            .onChange(of: draftQuery) { value in
                scheduleQueryCommit(value)
            }
            .onChange(of: store.query) { value in
                resetVisibleSearchResults()
                guard value != draftQuery,
                      value.isEmpty || draftQuery.isEmpty
                else { return }
                draftQuery = value
            }
            .onChange(of: store.typeFilter) { _ in resetVisibleSearchResults() }
            .onChange(of: store.folderFilter) { _ in resetVisibleSearchResults() }
            .onChange(of: store.tagFilter) { _ in resetVisibleSearchResults() }
            .onChange(of: store.sourceFilter) { _ in resetVisibleSearchResults() }
            .onChange(of: store.dateFilter) { _ in resetVisibleSearchResults() }
            .onChange(of: store.hasFilter) { _ in resetVisibleSearchResults() }
            .onDisappear {
                queryDebounceTask?.cancel()
                if store.query != draftQuery {
                    store.query = draftQuery
                }
            }
        }
    }

    private func loadMoreSearchResults(total: Int) {
        guard visibleResultLimit < total else { return }
        visibleResultLimit = min(visibleResultLimit + 32, total)
    }

    private func resetVisibleSearchResults() {
        visibleResultLimit = 40
    }

    private func scheduleQueryCommit(_ value: String) {
        queryDebounceTask?.cancel()

        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if store.query != value {
                store.query = value
            }
            return
        }

        queryDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if store.query != value {
                    store.query = value
                }
            }
        }
    }

}

struct FeedPageLoader: View {
    let label: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
                .tint(SaviTheme.accentText)
            Text(label)
                .font(SaviType.ui(.caption, weight: .bold))
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .onAppear(perform: action)
    }
}

struct SearchHeaderBlock: View {
    let resultCount: Int

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Find it fast")
                    .font(SaviType.display(size: 34, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text("Find anything, fast.")
                    .font(SaviType.ui(.subheadline, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
            }

            Spacer(minLength: 10)

            PillBadge(
                title: "\(resultCount) saves",
                systemImage: "tray.full.fill",
                foreground: SaviTheme.metadataText,
                background: SaviTheme.subtleSurface,
                stroke: SaviTheme.cardStroke
            )
                .accessibilityLabel("\(resultCount) searchable saves")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SearchResultsHeading: View {
    @EnvironmentObject private var store: SaviStore
    let resultCount: Int

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Results")
                .font(SaviType.ui(.title3, weight: .black))
                .foregroundStyle(SaviTheme.text)

            Spacer(minLength: 10)

            HStack(spacing: 8) {
                Text("\(resultCount) result\(resultCount == 1 ? "" : "s")")
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
            }
        }
    }
}
