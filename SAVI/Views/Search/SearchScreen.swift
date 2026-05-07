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

struct SearchScreen: View {
    @EnvironmentObject private var store: SaviStore
    @State private var draftQuery = ""
    @State private var queryDebounceTask: Task<Void, Never>?
    @State private var visibleResultLimit = SearchScreen.initialVisibleResultLimit
    @State private var handledSearchFocusRequest = 0
    @FocusState private var searchFieldFocused: Bool

    private static var initialVisibleResultLimit: Int {
        SaviPerformancePolicy.current.searchInitialResultLimit
    }

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
                        showsSubmitButton: false,
                        compact: true,
                        focusBinding: $searchFieldFocused
                    ) {
                        store.query = draftQuery
                    }
                        .id("search-bar")

                    SearchKindRail()

                    SearchControlRow(hasLiveSearch: hasLiveSearch)

                    if hasLiveSearch {
                        ActiveSearchFiltersRow()
                    }

                    SearchResultsHeading(title: hasLiveSearch ? "Results" : "Recently saved", resultCount: results.count)
                        .padding(.top, hasLiveSearch ? 2 : 4)

                    LazyVStack(alignment: .leading, spacing: 10) {
                        if hasLiveSearch {
                            ForEach(visibleResults) { item in
                                SearchResultRow(
                                    item: item,
                                    keyboardIsActive: searchFieldFocused,
                                    dismissKeyboard: dismissSearchKeyboard
                                )
                            }
                        } else {
                            ForEach(recentGroups) { group in
                                SaviFluidTimelineGroup(
                                    title: group.title,
                                    items: group.items,
                                    context: .search,
                                    keyboardIsActive: searchFieldFocused,
                                    dismissKeyboard: dismissSearchKeyboard
                                )
                                .padding(.top, group.id == recentGroups.first?.id ? 0 : 8)
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
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(SaviTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Search") {
                        dismissSearchKeyboard()
                    }
                    .font(SaviType.ui(.callout, weight: .bold))

                    Spacer()

                    Button("Done") {
                        dismissSearchKeyboard()
                    }
                    .font(SaviType.ui(.callout, weight: .bold))
                }
            }
            .onAppear {
                draftQuery = store.query
                focusSearchFieldIfNeeded()
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
            .onChange(of: store.documentSubtypeFilter) { _ in resetVisibleSearchResults() }
            .onChange(of: store.folderFilter) { _ in resetVisibleSearchResults() }
            .onChange(of: store.tagFilter) { _ in resetVisibleSearchResults() }
            .onChange(of: store.sourceFilter) { _ in resetVisibleSearchResults() }
            .onChange(of: store.dateFilter) { _ in resetVisibleSearchResults() }
            .onChange(of: store.customSearchStartDate) { _ in resetVisibleSearchResults() }
            .onChange(of: store.customSearchEndDate) { _ in resetVisibleSearchResults() }
            .onChange(of: store.hasFilter) { _ in resetVisibleSearchResults() }
            .onChange(of: store.searchFocusRequest) { _ in focusSearchFieldIfNeeded() }
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
        visibleResultLimit = min(visibleResultLimit + SaviPerformancePolicy.current.searchResultPageSize, total)
    }

    private func resetVisibleSearchResults() {
        visibleResultLimit = SearchScreen.initialVisibleResultLimit
    }

    private func commitSearchValue() {
        queryDebounceTask?.cancel()
        if store.query != draftQuery {
            store.query = draftQuery
        }
    }

    private func dismissSearchKeyboard() {
        commitSearchValue()
        searchFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

    private func focusSearchFieldIfNeeded() {
        guard handledSearchFocusRequest != store.searchFocusRequest else { return }
        handledSearchFocusRequest = store.searchFocusRequest
        guard store.searchFocusRequest > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            searchFieldFocused = true
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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Find the thing.")
                    .font(SaviType.display(size: 27, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text("That link, screenshot, note, or rabbit hole you swore you saved.")
                    .font(SaviType.ui(.subheadline, weight: .semibold))
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }

            Spacer(minLength: 10)

            PillBadge(
                title: "\(resultCount) saves",
                systemImage: "tray.full.fill",
                foreground: SaviTheme.metadataText,
                background: SaviTheme.subtleSurface.opacity(0.62),
                stroke: SaviTheme.cardStroke.opacity(0.66),
                height: 25
            )
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel("\(resultCount) searchable saves")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SearchResultsHeading: View {
    var title = "Results"
    let resultCount: Int

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(SaviType.ui(.title3, weight: .black))
                .foregroundStyle(SaviTheme.text)

            Spacer(minLength: 10)

            Text(resultCountText)
                .font(SaviType.ui(.caption, weight: .bold))
                .foregroundStyle(SaviTheme.textMuted)
                .lineLimit(1)
        }
        .accessibilityLabel("\(title), \(resultCount) result\(resultCount == 1 ? "" : "s")")
    }

    private var resultCountText: String {
        "\(resultCount) \(title == "Recently saved" ? "saved" : "result\(resultCount == 1 ? "" : "s")")"
    }
}
