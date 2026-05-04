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

struct SearchBar: View {
    @Binding var text: String
    var prompt = "Search SAVI"
    var showsSubmitButton = false
    var focusBinding: FocusState<Bool>.Binding?
    var submitAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(SaviType.ui(.title3, weight: .bold))
                .foregroundStyle(SaviTheme.metadataText)

            searchField

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(SaviTheme.metadataText)
                }
                .buttonStyle(SaviPressScaleButtonStyle())
                .accessibilityLabel("Clear search")
            }
            if showsSubmitButton {
                Button {
                    submitAction?()
                } label: {
                    Image(systemName: "arrow.right")
                        .font(SaviType.ui(.title3, weight: .black))
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#7C3AED"), Color(hex: "#5B2FD2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(SaviPressScaleButtonStyle(scale: 0.96))
                .accessibilityLabel("Search")
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, showsSubmitButton ? 6 : 15)
        .frame(minHeight: showsSubmitButton ? 66 : 54)
        .background(SaviTheme.inputSurface)
        .clipShape(RoundedRectangle(cornerRadius: showsSubmitButton ? 24 : SaviRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: showsSubmitButton ? 24 : SaviRadius.card, style: .continuous)
                .stroke(SaviTheme.cardStroke.opacity(0.82), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var searchField: some View {
        if let focusBinding {
            baseTextField
                .focused(focusBinding)
        } else {
            baseTextField
        }
    }

    private var baseTextField: some View {
        TextField("", text: $text, prompt: Text(prompt).foregroundColor(SaviTheme.metadataText))
            .font(SaviType.ui(.body, weight: .semibold))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .onSubmit {
                submitAction?()
            }
            .foregroundStyle(SaviTheme.text)
    }
}

struct SearchKindRail: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        ZStack(alignment: .trailing) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SaviSearchKind.visibleRail) { kind in
                        FilterChip(
                            title: kind.title,
                            systemImage: kind.symbolName,
                            active: store.typeFilter == kind.id
                        ) {
                            store.typeFilter = kind.id
                        }
                    }
                }
                .padding(.vertical, 1)
                .padding(.trailing, 28)
            }

            LinearGradient(
                colors: [SaviTheme.background.opacity(0), SaviTheme.background],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 28)
            .allowsHitTesting(false)
        }
    }
}

struct SearchExampleHintRow: View {
    let examples: [String]
    let action: (String) -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Text("Try:")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)

                    ForEach(examples, id: \.self) { example in
                        Button {
                            action(example)
                        } label: {
                            Text(example)
                                .font(SaviType.ui(.caption, weight: .bold))
                                .foregroundStyle(SaviTheme.metadataText)
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .frame(minHeight: 36)
                                .background(SaviTheme.surface.opacity(0.82))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(SaviTheme.cardStroke.opacity(0.72), lineWidth: 1)
                                )
                        }
                        .buttonStyle(SaviPressScaleButtonStyle(scale: 0.97))
                        .accessibilityLabel("Search for \(example)")
                    }
                }
                .padding(.trailing, 28)
            }

            LinearGradient(
                colors: [SaviTheme.background.opacity(0), SaviTheme.background],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 28)
            .allowsHitTesting(false)
        }
    }
}

struct SearchRefineButton: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        Button {
            store.openSearchRefine()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                Text("Refine")
                if store.refineFilterCount > 0 {
                    Text("\(store.refineFilterCount)")
                        .font(SaviType.ui(.caption2, weight: .black))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(store.refineFilterCount > 0 ? Color.black.opacity(0.12) : Color.clear)
                        .clipShape(Capsule())
                }
            }
            .font(SaviType.ui(.caption, weight: .bold))
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(store.refineFilterCount > 0 ? SaviTheme.softAccent : SaviTheme.surface)
            .foregroundStyle(store.refineFilterCount > 0 ? .black : SaviTheme.text)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(store.refineFilterCount > 0 ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(SaviPressScaleButtonStyle())
    }
}

struct SearchFacetBar: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ZStack(alignment: .trailing) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SearchFacet.allCases) { facet in
                            SearchFacetButton(
                                facet: facet,
                                value: value(for: facet),
                                active: isActive(facet)
                            ) {
                                store.openSearchFacet(facet)
                            }
                        }
                    }
                    .padding(.vertical, 1)
                    .padding(.trailing, 28)
                }

                LinearGradient(
                    colors: [SaviTheme.background.opacity(0), SaviTheme.background],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 28)
                .allowsHitTesting(false)
            }

            if store.hasActiveSearchControls {
                SearchClearAllButton {
                    store.resetFilters()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
    }

    private func value(for facet: SearchFacet) -> String {
        switch facet {
        case .type:
            return store.typeFilter == "all" ? "All" : SaviSearchKind.all.first(where: { $0.id == store.typeFilter })?.title ?? "All"
        case .keeper:
            return store.folderFilter == "f-all" ? "All" : store.folder(for: store.folderFilter)?.name ?? "All"
        case .tag:
            return store.tagFilter == "all" ? "Any" : "#\(store.tagFilter)"
        case .date:
            return store.dateFilter == SearchDateFilter.all.rawValue ? "Any" : store.dateFilterTitle(for: store.dateFilter)
        case .source:
            return store.sourceFilter == "all" ? "Any" : store.sourceOptions().first(where: { $0.key == store.sourceFilter })?.label ?? store.sourceFilter
        case .has:
            return store.hasFilter == SearchHasFilter.all.rawValue ? "Any" : store.hasFilterTitle(for: store.hasFilter)
        }
    }

    private func isActive(_ facet: SearchFacet) -> Bool {
        switch facet {
        case .type: return store.typeFilter != "all"
        case .keeper: return store.folderFilter != "f-all"
        case .tag: return store.tagFilter != "all"
        case .date: return store.dateFilter != SearchDateFilter.all.rawValue
        case .source: return store.sourceFilter != "all"
        case .has: return store.hasFilter != SearchHasFilter.all.rawValue
        }
    }
}

struct SearchClearAllButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Clear all", systemImage: "xmark.circle.fill")
                .labelStyle(.titleAndIcon)
                .font(SaviType.ui(.caption, weight: .black))
                .lineLimit(1)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .foregroundStyle(SaviTheme.accentText)
                .background(SaviTheme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(SaviTheme.cardStroke, lineWidth: 1))
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel("Clear all search filters")
    }
}

struct SearchFacetButton: View {
    let facet: SearchFacet
    let value: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: facet.symbolName)
                    .font(SaviType.ui(.caption, weight: .black))
                Text(facet.title)
                    .font(SaviType.ui(.caption, weight: .black))
                    .lineLimit(1)
                Text(value)
                    .font(SaviType.ui(.caption2, weight: .black))
                    .foregroundStyle(active ? .black.opacity(0.7) : SaviTheme.textMuted)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.black))
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(active ? SaviTheme.softAccent : SaviTheme.surface)
            .foregroundStyle(active ? .black : SaviTheme.text)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(active ? Color.clear : SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ActiveSearchFiltersRow: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !store.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ActiveFilterChip(title: "Search", systemImage: "magnifyingglass") {
                        store.query = ""
                    }
                }
                if store.typeFilter != "all" {
                    ActiveFilterChip(
                        title: store.searchKindTitle(for: store.typeFilter),
                        systemImage: "square.stack.3d.up.fill"
                    ) {
                        store.typeFilter = "all"
                    }
                }
                if store.folderFilter != "f-all" {
                    ActiveFilterChip(
                        title: store.folder(for: store.folderFilter)?.name ?? "Folder",
                        systemImage: "folder.fill"
                    ) {
                        store.folderFilter = "f-all"
                    }
                }
                if store.tagFilter != "all" {
                    ActiveFilterChip(title: "#\(store.tagFilter)", systemImage: "number") {
                        store.tagFilter = "all"
                    }
                }
                if store.sourceFilter != "all" {
                    ActiveFilterChip(
                        title: store.sourceOptions().first(where: { $0.key == store.sourceFilter })?.label ?? store.sourceFilter,
                        systemImage: SaviSearchPresentation.sourceSymbolName(for: store.sourceFilter)
                    ) {
                        store.sourceFilter = "all"
                    }
                }
                if store.dateFilter != SearchDateFilter.all.rawValue {
                    ActiveFilterChip(
                        title: store.dateFilterTitle(for: store.dateFilter),
                        systemImage: "calendar"
                    ) {
                        store.clearDateFilter()
                    }
                }
                if store.hasFilter != SearchHasFilter.all.rawValue {
                    ActiveFilterChip(
                        title: store.hasFilterTitle(for: store.hasFilter),
                        systemImage: "checklist"
                    ) {
                        store.clearHasFilter()
                    }
                }

                Button {
                    store.resetFilters()
                } label: {
                    Label("Reset", systemImage: "xmark.circle.fill")
                        .font(SaviType.ui(.caption, weight: .black))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .foregroundStyle(SaviTheme.accentText)
                        .background(SaviTheme.surface)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 1)
        }
    }
}

struct ActiveFilterChip: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.caption2.weight(.black))
            }
            .font(SaviType.ui(.caption, weight: .black))
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(SaviTheme.surfaceRaised)
            .foregroundStyle(SaviTheme.text)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(SaviTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SearchRefineSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    @State private var tagSearch = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    SearchRefineSection(title: "Type") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.searchKindOptions(includeEmpty: true), id: \.kind.id) { option in
                                    Chip(
                                        title: option.kind.id == "all" ? "All" : option.kind.title,
                                        systemImage: option.kind.symbolName,
                                        count: option.count,
                                        active: store.typeFilter == option.kind.id
                                    ) {
                                        store.typeFilter = option.kind.id
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }

                    SearchRefineSection(title: "Folders") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Chip(
                                    title: "All Folders",
                                    systemImage: "square.grid.2x2.fill",
                                    count: store.folder(for: "f-all").map { store.count(in: $0) },
                                    active: store.folderFilter == "f-all"
                                ) {
                                    store.folderFilter = "f-all"
                                }

                                Chip(title: "Manage", systemImage: "slider.horizontal.3", active: false) {
                                    store.openFoldersManagement()
                                    dismiss()
                                }

                                ForEach(store.orderedFoldersForDisplay()) { folder in
                                    let locked = folder.locked && !store.isProtectedKeeperUnlocked(folder)
                                    Chip(
                                        title: folder.name,
                                        systemImage: folder.isPublic ? "person.2.fill" : locked ? "lock.fill" : folder.symbolName,
                                        count: locked ? nil : store.count(in: folder),
                                        active: store.folderFilter == folder.id
                                    ) {
                                        store.selectFolderFilter(folder)
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }

                    SearchRefineSection(title: "Date") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SearchDateFilter.allCases) { option in
                                    Chip(title: option.title, systemImage: option.symbolName, active: store.dateFilter == option.rawValue) {
                                        store.dateFilter = option.rawValue
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }

                    SearchRefineSection(title: "Has") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SearchHasFilter.allCases) { option in
                                    Chip(title: option.title, systemImage: option.symbolName, active: store.hasFilter == option.rawValue) {
                                        store.hasFilter = option.rawValue
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }

                    SearchRefineSection(title: "Source") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Chip(title: "Any source", systemImage: "square.and.arrow.down", active: store.sourceFilter == "all") {
                                    store.sourceFilter = "all"
                                }

                                ForEach(store.sourceOptions(), id: \.key) { source in
                                    Chip(
                                        title: source.label,
                                        systemImage: SaviSearchPresentation.sourceSymbolName(for: source.key),
                                        count: source.count,
                                        active: store.sourceFilter == source.key
                                    ) {
                                        store.sourceFilter = source.key
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }

                    SearchRefineSection(title: "Tags") {
                        SearchBar(text: $tagSearch, prompt: "Search tags")

                        let tags = filteredTags()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Chip(title: "Any tag", systemImage: "number", active: store.tagFilter == "all") {
                                    store.tagFilter = "all"
                                }

                                ForEach(tags, id: \.key) { tag in
                                    Chip(title: tag.label, count: tag.count, active: store.tagFilter == tag.key) {
                                        store.tagFilter = tag.key
                                    }
                                }
                            }
                            .padding(.vertical, 1)
                        }

                        if tags.isEmpty {
                            Text("No contextual tags for this result set.")
                                .font(SaviType.ui(.caption, weight: .semibold))
                                .foregroundStyle(SaviTheme.textMuted)
                        }
                    }
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle("Refine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if store.refineFilterCount > 0 {
                        Button("Clear") {
                            store.clearRefineFilters()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func filteredTags() -> [(key: String, label: String, count: Int)] {
        let options = store.contextualTagOptions(limit: 80)
        let trimmed = tagSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return options }
        let normalized = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        return options.filter { tag in
            tag.key.contains(normalized) || tag.label.lowercased().contains(normalized)
        }
    }
}

struct SearchRefineSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
            content
        }
        .padding(12)
        .background(SaviTheme.surface.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SaviTheme.cardStroke.opacity(0.54), lineWidth: 1)
        )
    }
}

struct SearchFacetSheet: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.dismiss) private var dismiss
    let facet: SearchFacet
    @State private var tagSearch = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    content
                }
                .padding(18)
            }
            .background(SaviTheme.background.ignoresSafeArea())
            .navigationTitle(facet.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.activeSearchFacet = nil
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch facet {
        case .type:
            ForEach(store.searchKindOptions(includeEmpty: true), id: \.kind.id) { option in
                SearchFacetOptionRow(
                    title: option.kind.title,
                    subtitle: option.kind.id == "all" ? "All searchable saves" : nil,
                    systemImage: option.kind.symbolName,
                    count: option.count,
                    active: store.typeFilter == option.kind.id
                ) {
                    store.typeFilter = option.kind.id
                    store.activeSearchFacet = nil
                    dismiss()
                }
            }
        case .keeper:
            SearchFacetOptionRow(
                title: "All Folders",
                subtitle: "Search every unlocked save",
                systemImage: "square.grid.2x2.fill",
                count: store.folder(for: "f-all").map { store.count(in: $0) },
                active: store.folderFilter == "f-all"
            ) {
                store.folderFilter = "f-all"
                store.activeSearchFacet = nil
                dismiss()
            }

            Button {
                store.openFoldersManagement()
                dismiss()
            } label: {
                Label("Manage Folders", systemImage: "slider.horizontal.3")
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SaviSecondaryButtonStyle())
            .padding(.bottom, 4)

            ForEach(store.orderedFoldersForDisplay()) { folder in
                let locked = folder.locked && !store.isProtectedKeeperUnlocked(folder)
                SearchFacetOptionRow(
                    title: folder.name,
                    subtitle: locked ? "Locked" : "\(folder.isPublic ? "Public · " : "")\(store.count(in: folder)) saves",
                    systemImage: folder.isPublic ? "person.2.fill" : locked ? "lock.fill" : folder.symbolName,
                    count: nil,
                    active: store.folderFilter == folder.id
                ) {
                    store.selectFolderFilter(folder)
                }
            }
        case .tag:
            SearchBar(text: $tagSearch, prompt: "Search tags")
                .padding(.bottom, 2)

            SearchFacetOptionRow(
                title: "Any tag",
                subtitle: "Do not filter by tag",
                systemImage: "number",
                count: nil,
                active: store.tagFilter == "all"
            ) {
                store.tagFilter = "all"
                store.activeSearchFacet = nil
                dismiss()
            }

            let tags = filteredTags()
            if tags.isEmpty {
                EmptyStateView(
                    symbol: "number",
                    title: "No tags",
                    message: "Tags from saved items will appear here."
                )
            } else {
                ForEach(tags, id: \.key) { tag in
                    SearchFacetOptionRow(
                        title: tag.label,
                        subtitle: nil,
                        systemImage: "number",
                        count: tag.count,
                        active: store.tagFilter == tag.key
                    ) {
                        store.tagFilter = tag.key
                        store.activeSearchFacet = nil
                        dismiss()
                    }
                }
            }
        case .date:
            ForEach(SearchDateFilter.allCases) { option in
                SearchFacetOptionRow(
                    title: option.title,
                    subtitle: option == .all ? "Search across every saved date" : nil,
                    systemImage: option.symbolName,
                    count: nil,
                    active: store.dateFilter == option.rawValue
                ) {
                    store.dateFilter = option.rawValue
                    store.activeSearchFacet = nil
                    dismiss()
                }
            }
        case .source:
            SearchFacetOptionRow(
                title: "Any source",
                subtitle: "Search across every source",
                systemImage: "square.and.arrow.down",
                count: nil,
                active: store.sourceFilter == "all"
            ) {
                store.sourceFilter = "all"
                store.activeSearchFacet = nil
                dismiss()
            }

            ForEach(store.sourceOptions(), id: \.key) { source in
                SearchFacetOptionRow(
                    title: source.label,
                    subtitle: nil,
                    systemImage: SaviSearchPresentation.sourceSymbolName(for: source.key),
                    count: source.count,
                    active: store.sourceFilter == source.key
                ) {
                    store.sourceFilter = source.key
                    store.activeSearchFacet = nil
                    dismiss()
                }
            }
        case .has:
            ForEach(SearchHasFilter.allCases) { option in
                SearchFacetOptionRow(
                    title: option.title,
                    subtitle: option == .all ? "No attachment/content filter" : nil,
                    systemImage: option.symbolName,
                    count: nil,
                    active: store.hasFilter == option.rawValue
                ) {
                    store.hasFilter = option.rawValue
                    store.activeSearchFacet = nil
                    dismiss()
                }
            }
        }
    }

    private func filteredTags() -> [(key: String, label: String, count: Int)] {
        let options = store.tagOptions(limit: 80)
        let trimmed = tagSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return options }
        let normalized = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        return options.filter { tag in
            tag.key.contains(normalized) || tag.label.lowercased().contains(normalized)
        }
    }
}

struct SearchFacetOptionRow: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    var count: Int?
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .frame(width: 36, height: 36)
                    .background(active ? SaviTheme.chartreuse : SaviTheme.surfaceRaised)
                    .foregroundStyle(active ? .black : SaviTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(1)
                    if let subtitle {
                        Text(subtitle)
                            .font(SaviType.ui(.caption, weight: .semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let count {
                    Text("\(count)")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(active ? .black : SaviTheme.textMuted)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(active ? SaviTheme.chartreuse.opacity(0.7) : SaviTheme.surfaceRaised)
                        .clipShape(Capsule())
                }
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .font(SaviType.ui(.headline, weight: .black))
                        .foregroundStyle(SaviTheme.accentText)
                }
            }
            .padding(12)
            .saviCard(cornerRadius: 16, shadow: false)
        }
        .buttonStyle(.plain)
    }
}

enum SaviSearchPresentation {
    static func sourceSymbolName(for key: String) -> String {
        if key.contains("youtube") { return "play.rectangle.fill" }
        if key.contains("instagram") { return "camera.fill" }
        if key.contains("tiktok") { return "music.note" }
        if key == "x" || key.contains("twitter") { return "bubble.left.fill" }
        if key.contains("reddit") { return "bubble.left.and.bubble.right.fill" }
        if key.contains("facebook") { return "person.2.fill" }
        if key.contains("threads") { return "at" }
        if key.contains("linkedin") { return "briefcase.fill" }
        if key.contains("spotify") { return "music.quarternote.3" }
        if key.contains("soundcloud") { return "waveform" }
        if key.contains("vimeo") { return "video.fill" }
        if key.contains("pinterest") { return "pin.fill" }
        if key.contains("bluesky") || key.contains("bsky") { return "cloud.fill" }
        if key.contains("maps") { return "map.fill" }
        if key.contains("device") { return "iphone" }
        if key.contains("paste") { return "clipboard.fill" }
        return "link"
    }
}

struct SearchFilterSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
                .textCase(.uppercase)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    content
                }
                .padding(.vertical, 1)
            }
        }
    }
}

struct Chip: View {
    let title: String
    var systemImage: String?
    var count: Int?
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.black))
                }
                Text(title)
                    .lineLimit(1)
                if let count {
                    Text("\(count)")
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(active ? Color.black.opacity(0.12) : SaviTheme.surfaceRaised)
                        .clipShape(Capsule())
                }
            }
            .font(SaviType.ui(.caption, weight: .bold))
            .padding(.horizontal, 12)
            .frame(minHeight: 38)
            .background(active ? SaviTheme.softAccent : SaviTheme.surface)
            .foregroundStyle(active ? .black : SaviTheme.text)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(active ? Color.clear : SaviTheme.cardStroke.opacity(0.86), lineWidth: 1)
            )
        }
        .buttonStyle(SaviPressScaleButtonStyle())
    }
}

struct FolderPicker: View {
    @EnvironmentObject private var store: SaviStore
    @Binding var selectedFolderId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Folder")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SaviTheme.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Chip(title: "Auto", active: selectedFolderId.isEmpty) {
                        selectedFolderId = ""
                    }
                    ForEach(store.folders.filter { $0.id != "f-all" }) { folder in
                        Chip(title: folder.name, systemImage: folder.isPublic ? "person.2.fill" : folder.locked ? "lock.fill" : nil, active: selectedFolderId == folder.id) {
                            selectedFolderId = folder.id
                        }
                    }
                }
            }
        }
    }
}

struct SaviTextField: View {
    let title: String
    @Binding var text: String
    let prompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SaviTheme.textMuted)
            TextField(prompt, text: $text)
                .padding(14)
                .foregroundStyle(SaviTheme.text)
                .saviCard(cornerRadius: 16, shadow: false)
        }
    }
}
