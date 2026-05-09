import AppKit
import Charts
import Security
import SwiftUI
import UniformTypeIdentifiers

enum SaviMacSidebarSelection: Hashable, Identifiable {
    case founder
    case all
    case folder(String)
    case friends
    case settings

    var id: String {
        switch self {
        case .founder: return "founder"
        case .all: return "all"
        case .folder(let id): return "folder-\(id)"
        case .friends: return "friends"
        case .settings: return "settings"
        }
    }
}

enum SaviMacDashboardError: LocalizedError {
    case livePostHogClientNotEnabled

    var errorDescription: String? {
        "Live PostHog dashboard queries are not enabled yet."
    }
}

struct SaviMacPostHogDashboardClient: SaviFounderDashboardProvider {
    let mode: SaviCompanionBackendMode

    init(config: SaviCompanionBackendConfig = .current) {
        mode = config.analyticsMode
    }

    func loadSnapshot() async throws -> SaviFounderDashboardSnapshot {
        throw SaviMacDashboardError.livePostHogClientNotEnabled
    }

    static func storedPersonalAPIKeyStatus() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.altatecrd.savi.mac.posthog",
            kSecAttrAccount as String: "posthog-query-api-key",
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
            ? "PostHog query key is in Keychain. Live query client still stays disabled until explicitly wired."
            : "No PostHog query key in Keychain. Founder Hub is using mock data."
    }
}

@MainActor
final class SaviMacStore: ObservableObject {
    @Published var library = SaviCompanionSamples.library
    @Published var selection: SaviMacSidebarSelection? = .founder
    @Published var searchText = ""
    @Published var selectedItemID: String?
    @Published var statusMessage = "Local mock library loaded. Sync is disabled until backend config is provided."
    @Published var analyticsEvents: [SaviCompanionAnalyticsEvent] = []
    @Published var founderSnapshot = SaviFounderMockDashboardProvider.snapshot
    @Published var founderStatusMessage = "Founder Hub is running in mock mode until PostHog query credentials are stored in Mac Keychain."

    private let config = SaviCompanionBackendConfig.current
    private let socialClient: any SaviCompanionSocialClient
    private let analyticsClient: any SaviCompanionAnalyticsClient
    private let founderDashboardProvider: any SaviFounderDashboardProvider

    init() {
        socialClient = SaviCompanionServiceFactory.socialClient(config: config)
        analyticsClient = SaviCompanionServiceFactory.analyticsClient(config: config)
        founderDashboardProvider = SaviFounderMockDashboardProvider()
        track("mac_app_opened", surface: "mac", properties: ["mode": socialClient.mode.rawValue])
    }

    var visibleItems: [SaviCompanionItem] {
        library.visibleItems(folderId: selectedFolderId, query: searchText, includePrivate: true)
    }

    var selectedItem: SaviCompanionItem? {
        guard let selectedItemID else { return visibleItems.first }
        return library.items.first { $0.id == selectedItemID }
    }

    var selectedFolderId: String? {
        if case .folder(let id) = selection { return id }
        return nil
    }

    var title: String {
        switch selection {
        case .founder: return "Founder Hub"
        case .all, .none: return "All Saves"
        case .folder(let id): return library.folder(for: id)?.name ?? "Folder"
        case .friends: return "Friends Feed"
        case .settings: return "Settings"
        }
    }

    var subtitle: String {
        switch selection {
        case .founder:
            return "The playful control room for growth, TestFlight, saves, and safety."
        case .friends:
            return "Social is stubbed locally until Supabase auth and moderation are ready."
        case .settings:
            return "Backend, analytics, import, and export status."
        default:
            return "\(visibleItems.count) saves in the Mac companion preview."
        }
    }

    var socialStatusText: String {
        socialClient.statusText()
    }

    var analyticsStatusText: String {
        config.analyticsMode == .configured
            ? "PostHog config is present. Adapter is still manual-capture only."
            : "Analytics is local/no-op until PostHog host and project token are configured."
    }

    var founderDataStatusText: String {
        "\(founderStatusMessage) \(SaviMacPostHogDashboardClient.storedPersonalAPIKeyStatus())"
    }

    func select(_ item: SaviCompanionItem) {
        selectedItemID = item.id
        track("mac_item_selected", surface: "mac_library", properties: ["kind": item.kind.rawValue])
    }

    func open(_ item: SaviCompanionItem) {
        guard let url = item.url else {
            statusMessage = "This sample does not have a web link yet."
            return
        }
        NSWorkspace.shared.open(url)
        track("mac_link_opened", surface: "mac_detail", properties: ["domain": url.host() ?? "unknown"])
    }

    func exportLibrary() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "savi-mac-library-preview.json"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(library)
            try data.write(to: url, options: .atomic)
            statusMessage = "Exported preview library to \(url.lastPathComponent)."
            track("mac_library_exported", surface: "mac_settings", properties: ["item_count": "\(library.items.count)"])
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    func importLibrary() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            library = try decoder.decode(SaviCompanionLibrary.self, from: data)
            selectedItemID = library.items.sorted { $0.savedAt > $1.savedAt }.first?.id
            statusMessage = "Imported \(library.items.count) saves from \(url.lastPathComponent)."
            track("mac_library_imported", surface: "mac_settings", properties: ["item_count": "\(library.items.count)"])
        } catch {
            statusMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    func resetMockLibrary() {
        library = SaviCompanionSamples.library
        selection = .all
        selectedItemID = library.items.first?.id
        statusMessage = "Restored the local sample companion library."
        track("mac_library_reset", surface: "mac_settings")
    }

    func refreshFounderDashboard() {
        Task {
            do {
                founderSnapshot = try await founderDashboardProvider.loadSnapshot()
                founderStatusMessage = "Founder Hub refreshed with privacy-safe mock data."
                track("mac_founder_dashboard_refreshed", surface: "mac_founder_hub")
            } catch {
                founderStatusMessage = "Founder Hub stayed in mock mode: \(error.localizedDescription)"
            }
        }
    }

    private func track(_ name: String, surface: String, properties: [String: String] = [:]) {
        let event = SaviCompanionAnalyticsEvent(
            name: name,
            surface: surface,
            createdAt: Date(),
            properties: properties
        )
        analyticsEvents.insert(event, at: 0)
        analyticsEvents = Array(analyticsEvents.prefix(12))
        analyticsClient.capture(event)
    }
}

struct SAVIMacRootView: View {
    @StateObject private var store = SaviMacStore()

    var body: some View {
        NavigationSplitView {
            SaviMacSidebar(store: store)
                .navigationSplitViewColumnWidth(min: 230, ideal: 260)
        } content: {
            SaviMacContentView(store: store)
                .navigationSplitViewColumnWidth(min: 440, ideal: 620)
        } detail: {
            SaviMacDetailView(store: store)
        }
        .searchable(text: $store.searchText, placement: .toolbar, prompt: "Search SAVI")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.refreshFounderDashboard()
                } label: {
                    Label("Refresh Hub", systemImage: "arrow.clockwise")
                }

                Button {
                    store.importLibrary()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }

                Button {
                    store.exportLibrary()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

struct SaviMacSidebar: View {
    @ObservedObject var store: SaviMacStore

    var body: some View {
        List(selection: $store.selection) {
            Section {
                Label("Founder Hub", systemImage: "sparkles.rectangle.stack.fill")
                    .tag(SaviMacSidebarSelection.founder)
            }

            Section("Library") {
                Label("All Saves", systemImage: "tray.full.fill")
                    .tag(SaviMacSidebarSelection.all)
            }

            Section("Folders") {
                ForEach(store.library.visibleFolders) { folder in
                    Label(folder.name, systemImage: folder.symbolName)
                        .foregroundStyle(folder.isPrivate ? .purple : .primary)
                        .tag(SaviMacSidebarSelection.folder(folder.id))
                }
            }

            Section("Coming Soon") {
                Label("Friends Feed", systemImage: "person.2.fill")
                    .tag(SaviMacSidebarSelection.friends)
            }

            Section {
                Label("Settings", systemImage: "gearshape.fill")
                    .tag(SaviMacSidebarSelection.settings)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("SAVI Mac")
                    .font(.headline)
                Text("Development companion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

struct SaviMacContentView: View {
    @ObservedObject var store: SaviMacStore

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 14, alignment: .top)
    ]

    var body: some View {
        Group {
            switch store.selection {
            case .founder:
                SaviMacFounderHubView(store: store)
            case .friends:
                SaviMacFriendsPlaceholder(store: store)
            case .settings:
                SaviMacSettingsView(store: store)
            default:
                libraryGrid
            }
        }
    }

    private var libraryGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            SaviMacHeader(title: store.title, subtitle: store.subtitle)

            if store.visibleItems.isEmpty {
                SaviMacEmptyState(
                    title: "Nothing matched",
                    message: "Try a different search or choose another folder."
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(store.visibleItems) { item in
                            SaviMacItemCard(
                                item: item,
                                folder: store.library.folder(for: item.folderId),
                                isSelected: item.id == store.selectedItem?.id
                            ) {
                                store.select(item)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .padding(20)
    }
}

struct SaviMacDetailView: View {
    @ObservedObject var store: SaviMacStore

    var body: some View {
        Group {
            if case .founder = store.selection {
                SaviMacFounderDetailView(store: store)
            } else if let item = store.selectedItem {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        SaviMacPreviewPanel(item: item, folder: store.library.folder(for: item.folderId))

                        VStack(alignment: .leading, spacing: 10) {
                            Text(item.title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .fixedSize(horizontal: false, vertical: true)
                            Text(item.summary)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }

                        if let url = item.url {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Link")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(url.absoluteString)
                                    .font(.callout.monospaced())
                                    .textSelection(.enabled)
                                    .lineLimit(3)
                            }
                        }

                        SaviMacTagCloud(tags: item.tags)

                        HStack {
                            Button {
                                store.open(item)
                            } label: {
                                Label("Open Link", systemImage: "arrow.up.right.square")
                            }
                            .disabled(item.url == nil)
                            .buttonStyle(.borderedProminent)

                            if item.isPrivate {
                                Label("Private sample", systemImage: "lock.fill")
                                    .foregroundStyle(.purple)
                            } else if item.isPublic {
                                Label("Eligible public web link", systemImage: "globe")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(store.statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 10)
                    }
                    .padding(28)
                    .frame(maxWidth: 720, alignment: .leading)
                }
            } else {
                SaviMacEmptyState(
                    title: "Select a save",
                    message: "Choose a card to inspect it here."
                )
                .padding()
            }
        }
    }
}

struct SaviMacFounderHubView: View {
    @ObservedObject var store: SaviMacStore

    private let metricColumns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 14, alignment: .top)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SaviMacFounderHero(store: store)

                LazyVGrid(columns: metricColumns, spacing: 14) {
                    ForEach(store.founderSnapshot.metricCards) { metric in
                        SaviFounderMetricTile(metric: metric)
                    }
                }

                SaviMacDashboardCard(title: "Pulse", symbolName: "waveform.path.ecg", accentHex: "#D6F83A") {
                    Text("Growth and build adoption at a glance.")
                        .foregroundStyle(.secondary)
                    SaviFounderGrowthChart(points: store.founderSnapshot.growthSeries)
                    SaviFounderRetentionGrid(points: store.founderSnapshot.retentionRows)
                }

                SaviFounderDashboardPair {
                    SaviMacDashboardCard(title: "Share Sheet Rocket", symbolName: "square.and.arrow.up.fill", accentHex: "#68C6E8") {
                        Text("The path from first open to the magic moment.")
                            .foregroundStyle(.secondary)
                        SaviFounderFunnelView(steps: store.founderSnapshot.activationFunnel)
                    }
                } trailing: {
                    SaviMacDashboardCard(title: "Save Engine", symbolName: "tray.and.arrow.down.fill", accentHex: "#C7B7FF") {
                        Text("Where saves come from without collecting private content.")
                            .foregroundStyle(.secondary)
                        SaviFounderSaveSourceChart(points: store.founderSnapshot.saveSourceSeries)
                    }
                }

                SaviFounderDashboardPair {
                    SaviMacDashboardCard(title: "Search Brain", symbolName: "brain.head.profile", accentHex: "#FFB84D") {
                        Text("Safe search buckets only: zero-result rate, refine use, and result counts.")
                            .foregroundStyle(.secondary)
                        SaviFounderRankedList(items: store.founderSnapshot.searchBrain)
                    }
                } trailing: {
                    SaviMacDashboardCard(title: "Rabbit Hole Radar", symbolName: "antenna.radiowaves.left.and.right", accentHex: "#F8DA2F") {
                        Text("Public web links only. No private files, vault saves, or screenshots.")
                            .foregroundStyle(.secondary)
                        SaviFounderRankedList(items: store.founderSnapshot.trendingPublicLinks)
                    }
                }

                SaviFounderDashboardPair {
                    SaviMacDashboardCard(title: "Social Lab", symbolName: "heart.text.square.fill", accentHex: "#C7B7FF") {
                        Text("Debug-only social readiness. Release/TestFlight stays teaser-only.")
                            .foregroundStyle(.secondary)
                        SaviFounderRankedList(items: store.founderSnapshot.socialLab)
                    }
                } trailing: {
                    SaviMacDashboardCard(title: "Reliability Room", symbolName: "stethoscope", accentHex: "#FF6B6B") {
                        SaviFounderAlertList(alerts: store.founderSnapshot.reliabilityAlerts)
                    }
                }

                SaviFounderDashboardPair {
                    SaviMacDashboardCard(title: "TestFlight Room", symbolName: "airplane.departure", accentHex: "#68C6E8") {
                        SaviFounderAlertList(alerts: store.founderSnapshot.testFlightRoom)
                    }
                } trailing: {
                    SaviMacDashboardCard(title: "Codex Workshop", symbolName: "hammer.fill", accentHex: "#D6F83A") {
                        SaviFounderAlertList(alerts: store.founderSnapshot.codexWorkshop)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 1180, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#130D1F"), Color(hex: "#211431"), Color.black.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

struct SaviMacFounderHero: View {
    @ObservedObject var store: SaviMacStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Founder Hub")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                    Text("The SAVI control room: growth, saves, TestFlight, reliability, and the links people care about.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    store.refreshFounderDashboard()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 10) {
                SaviFounderModePill(title: "Mock data", symbolName: "sparkles", colorHex: "#D6F83A")
                SaviFounderModePill(title: "Privacy-safe", symbolName: "lock.shield.fill", colorHex: "#C7B7FF")
                SaviFounderModePill(title: "PostHog-ready", symbolName: "chart.line.uptrend.xyaxis", colorHex: "#68C6E8")
            }

            Text(store.founderDataStatusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
        )
    }
}

struct SaviFounderModePill: View {
    var title: String
    var symbolName: String
    var colorHex: String

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color(hex: colorHex))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(hex: colorHex).opacity(0.14), in: Capsule())
    }
}

struct SaviFounderMetricTile: View {
    var metric: SaviFounderMetricCard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: metric.symbolName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(hex: metric.tintHex))
                Spacer()
                Label(metric.trend, systemImage: metric.direction.symbolName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(metric.direction.color)
                    .labelStyle(.titleAndIcon)
            }

            Text(metric.value)
                .font(.system(size: 34, weight: .black, design: .rounded))
            Text(metric.title)
                .font(.headline)
            Text(metric.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: metric.tintHex).opacity(0.24), lineWidth: 1)
        }
    }
}

struct SaviMacDashboardCard<Content: View>: View {
    var title: String
    var symbolName: String
    var accentHex: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbolName)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color(hex: accentHex))
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }
}

struct SaviFounderDashboardPair<Leading: View, Trailing: View>: View {
    var leading: Leading
    var trailing: Trailing

    init(
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 14) {
                leading
                trailing
            }

            VStack(alignment: .leading, spacing: 14) {
                leading
                trailing
            }
        }
    }
}

struct SaviFounderGrowthChart: View {
    var points: [SaviFounderTimeSeriesPoint]

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Day", point.date),
                y: .value("Users", point.value),
                series: .value("Series", point.series)
            )
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Day", point.date),
                y: .value("Users", point.value)
            )
            .symbolSize(18)
        }
        .chartForegroundStyleScale(["DAU": Color(hex: "#D6F83A"), "WAU": Color(hex: "#C7B7FF")])
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 220)
    }
}

struct SaviFounderSaveSourceChart: View {
    var points: [SaviFounderTimeSeriesPoint]

    var body: some View {
        Chart(points) { point in
            BarMark(
                x: .value("Source", point.label),
                y: .value("Saves", point.value)
            )
            .foregroundStyle(Color(hex: "#C7B7FF").gradient)
            .cornerRadius(7)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 220)
    }
}

struct SaviFounderFunnelView: View {
    var steps: [SaviFounderFunnelStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(steps) { step in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(step.title)
                            .font(.callout.weight(.semibold))
                        Spacer()
                        Text(step.detail)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.10))
                            Capsule()
                                .fill(Color(hex: "#68C6E8").gradient)
                                .frame(width: max(8, proxy.size.width * step.conversion))
                        }
                    }
                    .frame(height: 10)

                    Text("\(step.count) testers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct SaviFounderRetentionGrid: View {
    var points: [SaviFounderTimeSeriesPoint]

    private var seriesNames: [String] {
        Array(Set(points.map(\.series))).sorted()
    }

    private var labels: [String] {
        Array(Set(points.map(\.label))).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Cohort")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 96, alignment: .leading)
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(seriesNames, id: \.self) { series in
                HStack(spacing: 8) {
                    Text(series)
                        .font(.caption.weight(.semibold))
                        .frame(width: 96, alignment: .leading)
                    ForEach(labels, id: \.self) { label in
                        let value = points.first { $0.series == series && $0.label == label }?.value ?? 0
                        Text("\(Int(value))%")
                            .font(.caption.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(retentionColor(value), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
        }
    }

    private func retentionColor(_ value: Double) -> Color {
        switch value {
        case 70...: return Color(hex: "#D6F83A").opacity(0.55)
        case 45...: return Color(hex: "#C7B7FF").opacity(0.45)
        case 25...: return Color(hex: "#FFB84D").opacity(0.35)
        default: return Color.white.opacity(0.10)
        }
    }
}

struct SaviFounderRankedList: View {
    var items: [SaviFounderRankedItem]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 12) {
                    Text("#\(index + 1)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color(hex: "#F8DA2F"))
                        .frame(width: 34)

                    Image(systemName: item.symbolName)
                        .foregroundStyle(Color(hex: "#F8DA2F"))
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(item.value)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.10), in: Capsule())
                }
            }
        }
    }
}

struct SaviFounderAlertList: View {
    var alerts: [SaviFounderAlertRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(alerts) { alert in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: alert.symbolName)
                        .font(.headline)
                        .foregroundStyle(alert.level.color)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alert.title)
                            .font(.callout.weight(.semibold))
                        Text(alert.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Text(alert.level.title)
                        .font(.caption2.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(alert.level.color)
                }
            }
        }
    }
}

struct SaviMacFounderDetailView: View {
    @ObservedObject var store: SaviMacStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SaviMacPreviewPanel(
                    item: SaviCompanionItem(
                        id: "founder-hub",
                        title: "Founder Hub",
                        summary: "SAVI's internal Mac dashboard for growth, reliability, TestFlight, and privacy-safe public-link trends.",
                        url: nil,
                        source: "SAVI Mac",
                        kind: .note,
                        folderId: "ai-work",
                        tags: ["founder", "dashboard", "privacy-safe", "posthog-ready"],
                        savedAt: store.founderSnapshot.generatedAt,
                        isPrivate: true,
                        isPublic: false
                    ),
                    folder: SaviCompanionFolder(id: "founder", name: "Founder Hub", colorHex: "#D6F83A", symbolName: "sparkles", isPrivate: true, order: -1)
                )

                Text("Founder Hub")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                Text("This dashboard is intentionally Mac-only and internal. It can become the place you check beta health before investor calls, without leaking private user saves into analytics.")
                    .foregroundStyle(.secondary)

                SaviMacTagCloud(tags: ["mock-data", "keychain-later", "no-private-content", "codex-ready"])

                SaviMacSettingsCard(title: "Live Data Path", symbolName: "key.fill") {
                    Text(store.founderDataStatusText)
                        .foregroundStyle(.secondary)
                    Text("When PostHog is ready, store a query-scoped personal API key in Mac Keychain and keep it out of the repo and iOS app.")
                        .foregroundStyle(.secondary)
                }

                SaviMacSettingsCard(title: "Privacy Guardrail", symbolName: "lock.shield.fill") {
                    Text("Display public domains, public URLs, event buckets, device tiers, and failure categories. Never display private notes, vault files, screenshots, raw searches, or clipboard contents.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(28)
            .frame(maxWidth: 720, alignment: .leading)
        }
    }
}

struct SaviMacItemCard: View {
    var item: SaviCompanionItem
    var folder: SaviCompanionFolder?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(hex: folder?.colorHex ?? "#D6F83A"), Color.black.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 128)

                    Image(systemName: item.kind.symbolName)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(16)
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(item.kind.title)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if item.isPrivate {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.purple)
                        }
                    }

                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)

                    Text(item.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct SaviMacPreviewPanel: View {
    var item: SaviCompanionItem
    var folder: SaviCompanionFolder?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: folder?.colorHex ?? "#D6F83A"), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 240)

            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: item.kind.symbolName)
                    .font(.system(size: 48, weight: .semibold))
                Text(folder?.name ?? "SAVI")
                    .font(.title3.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(24)
        }
    }
}

struct SaviMacSettingsView: View {
    @ObservedObject var store: SaviMacStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SaviMacHeader(title: store.title, subtitle: store.subtitle)

                SaviMacSettingsCard(title: "Sync", symbolName: "arrow.triangle.2.circlepath") {
                    Text(store.socialStatusText)
                        .foregroundStyle(.secondary)
                    Text("Private files, screenshots, and vault content are not synced in this Mac v1.")
                        .foregroundStyle(.secondary)
                }

                SaviMacSettingsCard(title: "Analytics", symbolName: "chart.line.uptrend.xyaxis") {
                    Text(store.analyticsStatusText)
                        .foregroundStyle(.secondary)
                    Text("Manual event allowlist only. No session replay, no autocapture, no private content.")
                        .foregroundStyle(.secondary)
                }

                SaviMacSettingsCard(title: "Local Preview Library", symbolName: "archivebox.fill") {
                    Text(store.statusMessage)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("Import JSON") { store.importLibrary() }
                        Button("Export JSON") { store.exportLibrary() }
                        Button("Restore Samples") { store.resetMockLibrary() }
                    }
                }

                SaviMacSettingsCard(title: "Recent Debug Events", symbolName: "list.bullet.rectangle") {
                    if store.analyticsEvents.isEmpty {
                        Text("No local events yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.analyticsEvents) { event in
                            HStack {
                                Text(event.name)
                                    .font(.callout.weight(.medium))
                                Spacer()
                                Text(event.surface)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct SaviMacFriendsPlaceholder: View {
    @ObservedObject var store: SaviMacStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SaviMacHeader(title: store.title, subtitle: store.subtitle)

            SaviMacSettingsCard(title: "Friends are coming", symbolName: "person.2.fill") {
                Text("The Mac app is ready to host the friends feed once Supabase auth, moderation, reports, and blocks are wired.")
                    .foregroundStyle(.secondary)
                Text("For now, Release/TestFlight social stays hidden and this Mac target remains a development companion.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SaviMacSettingsCard<Content: View>: View {
    var title: String
    var symbolName: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbolName)
                .font(.headline)
            content
                .font(.callout)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SaviMacHeader: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(subtitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SaviMacTagCloud: View {
    var tags: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.08), in: Capsule())
            }
        }
    }
}

struct SaviMacEmptyState: View {
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.bold))
            Text(message)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 360
        var point = CGPoint.zero
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if point.x > 0, point.x + size.width > maxWidth {
                point.x = 0
                point.y += lineHeight + spacing
                lineHeight = 0
            }
            point.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: maxWidth, height: point.y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var point = CGPoint(x: bounds.minX, y: bounds.minY)
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if point.x > bounds.minX, point.x + size.width > bounds.maxX {
                point.x = bounds.minX
                point.y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: point, proposal: ProposedViewSize(size))
            point.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

extension Color {
    init(hex: String) {
        let normalized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: normalized).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double

        if normalized.count == 6 {
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
        } else {
            red = 0.84
            green = 0.97
            blue = 0.23
        }

        self.init(red: red, green: green, blue: blue)
    }
}

extension SaviFounderTrendDirection {
    var symbolName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: return Color(hex: "#D6F83A")
        case .down: return Color(hex: "#FFB84D")
        case .flat: return .secondary
        }
    }
}

extension SaviFounderAlertLevel {
    var title: String {
        switch self {
        case .good: return "Good"
        case .watch: return "Watch"
        case .danger: return "Risk"
        case .info: return "Info"
        }
    }

    var color: Color {
        switch self {
        case .good: return Color(hex: "#D6F83A")
        case .watch: return Color(hex: "#FFB84D")
        case .danger: return Color(hex: "#FF6B6B")
        case .info: return Color(hex: "#68C6E8")
        }
    }
}
