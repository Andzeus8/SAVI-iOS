import Foundation

enum SaviFounderTrendDirection: String, Codable, CaseIterable {
    case up
    case down
    case flat
}

struct SaviFounderMetricCard: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var value: String
    var detail: String
    var trend: String
    var direction: SaviFounderTrendDirection
    var symbolName: String
    var tintHex: String
}

struct SaviFounderTimeSeriesPoint: Codable, Identifiable, Hashable {
    var id: String
    var date: Date
    var label: String
    var value: Double
    var series: String

    init(date: Date, label: String, value: Double, series: String) {
        self.id = "\(series)-\(label)"
        self.date = date
        self.label = label
        self.value = value
        self.series = series
    }
}

struct SaviFounderFunnelStep: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var count: Int
    var conversion: Double
    var detail: String
}

struct SaviFounderRankedItem: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var value: String
    var score: Double
    var symbolName: String
}

enum SaviFounderAlertLevel: String, Codable, CaseIterable {
    case good
    case watch
    case danger
    case info
}

struct SaviFounderAlertRow: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var message: String
    var level: SaviFounderAlertLevel
    var symbolName: String
}

struct SaviFounderDashboardSnapshot: Codable, Equatable {
    var generatedAt: Date
    var metricCards: [SaviFounderMetricCard]
    var growthSeries: [SaviFounderTimeSeriesPoint]
    var saveSourceSeries: [SaviFounderTimeSeriesPoint]
    var activationFunnel: [SaviFounderFunnelStep]
    var retentionRows: [SaviFounderTimeSeriesPoint]
    var searchBrain: [SaviFounderRankedItem]
    var trendingPublicLinks: [SaviFounderRankedItem]
    var socialLab: [SaviFounderRankedItem]
    var reliabilityAlerts: [SaviFounderAlertRow]
    var testFlightRoom: [SaviFounderAlertRow]
    var codexWorkshop: [SaviFounderAlertRow]
}

protocol SaviFounderDashboardProvider {
    var mode: SaviCompanionBackendMode { get }
    func loadSnapshot() async throws -> SaviFounderDashboardSnapshot
}

struct SaviFounderMockDashboardProvider: SaviFounderDashboardProvider {
    let mode: SaviCompanionBackendMode = .disabled

    func loadSnapshot() async throws -> SaviFounderDashboardSnapshot {
        Self.snapshot
    }

    static var snapshot: SaviFounderDashboardSnapshot {
        let now = Date()
        let days = (0..<14).map { offset in
            Calendar.current.date(byAdding: .day, value: offset - 13, to: now) ?? now
        }

        return SaviFounderDashboardSnapshot(
            generatedAt: now,
            metricCards: [
                SaviFounderMetricCard(id: "dau", title: "DAU", value: "42", detail: "Mock active testers today", trend: "+18%", direction: .up, symbolName: "person.3.fill", tintHex: "#D6F83A"),
                SaviFounderMetricCard(id: "saves", title: "Saves/User", value: "6.8", detail: "Median beta library momentum", trend: "+1.4", direction: .up, symbolName: "tray.and.arrow.down.fill", tintHex: "#C7B7FF"),
                SaviFounderMetricCard(id: "share", title: "Share Sheet", value: "71%", detail: "Opened after onboarding", trend: "+9%", direction: .up, symbolName: "square.and.arrow.up.fill", tintHex: "#68C6E8"),
                SaviFounderMetricCard(id: "metadata", title: "Metadata", value: "93%", detail: "Successful previews", trend: "-2%", direction: .down, symbolName: "wand.and.stars", tintHex: "#FFB84D")
            ],
            growthSeries: days.enumerated().flatMap { index, date in
                [
                    SaviFounderTimeSeriesPoint(date: date, label: "D\(index + 1)", value: Double(18 + index * 2 + (index % 3) * 4), series: "DAU"),
                    SaviFounderTimeSeriesPoint(date: date, label: "D\(index + 1)", value: Double(32 + index * 4 + (index % 4) * 3), series: "WAU")
                ]
            },
            saveSourceSeries: [
                SaviFounderTimeSeriesPoint(date: now, label: "Share Sheet", value: 58, series: "Saves"),
                SaviFounderTimeSeriesPoint(date: now, label: "Manual", value: 17, series: "Saves"),
                SaviFounderTimeSeriesPoint(date: now, label: "Photos", value: 14, series: "Saves"),
                SaviFounderTimeSeriesPoint(date: now, label: "Files", value: 8, series: "Saves"),
                SaviFounderTimeSeriesPoint(date: now, label: "Voice", value: 3, series: "Saves")
            ],
            activationFunnel: [
                SaviFounderFunnelStep(id: "open", title: "App opened", count: 120, conversion: 1.0, detail: "Start"),
                SaviFounderFunnelStep(id: "onboarding", title: "Onboarding done", count: 96, conversion: 0.80, detail: "80%"),
                SaviFounderFunnelStep(id: "share-setup", title: "Share Sheet setup", count: 78, conversion: 0.65, detail: "65%"),
                SaviFounderFunnelStep(id: "first-save", title: "First save", count: 63, conversion: 0.53, detail: "53%"),
                SaviFounderFunnelStep(id: "search", title: "First search", count: 41, conversion: 0.34, detail: "34%")
            ],
            retentionRows: [
                SaviFounderTimeSeriesPoint(date: now, label: "D1", value: 62, series: "New testers"),
                SaviFounderTimeSeriesPoint(date: now, label: "D7", value: 39, series: "New testers"),
                SaviFounderTimeSeriesPoint(date: now, label: "D30", value: 18, series: "New testers"),
                SaviFounderTimeSeriesPoint(date: now, label: "D1", value: 74, series: "Share users"),
                SaviFounderTimeSeriesPoint(date: now, label: "D7", value: 51, series: "Share users"),
                SaviFounderTimeSeriesPoint(date: now, label: "D30", value: 27, series: "Share users"),
                SaviFounderTimeSeriesPoint(date: now, label: "D1", value: 81, series: "3+ saves"),
                SaviFounderTimeSeriesPoint(date: now, label: "D7", value: 58, series: "3+ saves"),
                SaviFounderTimeSeriesPoint(date: now, label: "D30", value: 35, series: "3+ saves")
            ],
            searchBrain: [
                SaviFounderRankedItem(id: "zero", title: "Zero-result searches", subtitle: "Bucketed only, no raw query text", value: "7%", score: 0.18, symbolName: "magnifyingglass"),
                SaviFounderRankedItem(id: "refine", title: "Refine opened", subtitle: "Filter intent and count generation", value: "31%", score: 0.54, symbolName: "slider.horizontal.3"),
                SaviFounderRankedItem(id: "screenshots", title: "Screenshot filter", subtitle: "Most common shortcut", value: "#1", score: 0.82, symbolName: "photo.on.rectangle.angled")
            ],
            trendingPublicLinks: [
                SaviFounderRankedItem(id: "agents", title: "Building Effective AI Agents", subtitle: "anthropic.com", value: "18 saves", score: 0.95, symbolName: "sparkles"),
                SaviFounderRankedItem(id: "cpr", title: "Hands-only CPR", subtitle: "redcross.org", value: "14 saves", score: 0.78, symbolName: "heart.text.square.fill"),
                SaviFounderRankedItem(id: "webb", title: "James Webb Space Telescope", subtitle: "nasa.gov", value: "12 saves", score: 0.66, symbolName: "moon.stars.fill"),
                SaviFounderRankedItem(id: "numa", title: "Numa Numa", subtitle: "youtube.com", value: "9 saves", score: 0.52, symbolName: "play.rectangle.fill")
            ],
            socialLab: [
                SaviFounderRankedItem(id: "public", title: "Public link publishing", subtitle: "Web links only, no private files", value: "Stub", score: 0.2, symbolName: "globe"),
                SaviFounderRankedItem(id: "hearts", title: "Heart reactions", subtitle: "One-tap signal for public links", value: "Ready", score: 0.4, symbolName: "heart.fill"),
                SaviFounderRankedItem(id: "moderation", title: "Reports and blocks", subtitle: "Required before external social", value: "Planned", score: 0.3, symbolName: "hand.raised.fill")
            ],
            reliabilityAlerts: [
                SaviFounderAlertRow(id: "iphone11", title: "iPhone 11 watch", message: "Legacy devices remain the scroll/performance canary.", level: .watch, symbolName: "iphone"),
                SaviFounderAlertRow(id: "cloudkit", title: "CloudKit gated", message: "Release launch path avoids CloudKit container traps.", level: .good, symbolName: "icloud.slash.fill"),
                SaviFounderAlertRow(id: "metadata", title: "Metadata failures", message: "Watch YouTube/Instagram previews after share-extension hotfixes.", level: .info, symbolName: "photo.on.rectangle.angled")
            ],
            testFlightRoom: [
                SaviFounderAlertRow(id: "candidate", title: "SAVI 1.0 (33)", message: "Latest tracked candidate in the shared work log.", level: .good, symbolName: "checkmark.seal.fill"),
                SaviFounderAlertRow(id: "testers", title: "Internal testers", message: "Accepted and pending testers should stay tracked in SAVI_ACTIVE_WORK_LOG.", level: .info, symbolName: "person.2.badge.gearshape.fill"),
                SaviFounderAlertRow(id: "ios17", title: "iOS 17 canary", message: "Keep iPhone 11/iOS 17 performance in the release checklist.", level: .watch, symbolName: "exclamationmark.triangle.fill")
            ],
            codexWorkshop: [
                SaviFounderAlertRow(id: "skills", title: "Security and QA skills", message: "Threat-model, best-practices, Sentry, Playwright, screenshot, and GitHub skills are installed after Codex restart.", level: .good, symbolName: "hammer.fill"),
                SaviFounderAlertRow(id: "worklog", title: "Shared work log", message: "Parallel chats should read/write SAVI_ACTIVE_WORK_LOG before app edits.", level: .good, symbolName: "list.clipboard.fill"),
                SaviFounderAlertRow(id: "secrets", title: "No secrets in app", message: "Personal PostHog query keys belong in Mac Keychain later, never in iOS or repo files.", level: .good, symbolName: "key.fill")
            ]
        )
    }
}
