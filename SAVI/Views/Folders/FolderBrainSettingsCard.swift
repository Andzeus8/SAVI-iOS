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

struct FolderBrainSettingsCard: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        SettingsCard(title: "SAVI Brain", symbol: "brain") {
            VStack(alignment: .leading, spacing: 14) {
                if let report = store.folderAuditReport {
                    FolderAuditSummary(report: report)

                    FolderBrainStatusRow(
                        title: "Apple Intelligence",
                        value: store.appleIntelligenceStatus,
                        symbolName: store.appleIntelligenceStatus == "Available" ? "sparkles" : "bolt.slash"
                    )

                    if report.failedCount == 0 {
                        Label("All golden Folder examples pass.", systemImage: "checkmark.seal.fill")
                            .font(SaviType.ui(.subheadline, weight: .bold))
                            .foregroundStyle(SaviTheme.accentText)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Needs attention")
                                .font(SaviType.ui(.caption, weight: .black))
                                .foregroundStyle(Color.orange)
                            ForEach(Array(report.failures.prefix(4))) { result in
                                FolderAuditFailureRow(result: result)
                            }
                        }
                    }

                    if report.intelligenceFailedCount == 0 {
                        Label("AI guardrails pass.", systemImage: "shield.checkered")
                            .font(SaviType.ui(.subheadline, weight: .bold))
                            .foregroundStyle(SaviTheme.accentText)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI guardrail failures")
                                .font(SaviType.ui(.caption, weight: .black))
                                .foregroundStyle(Color.orange)
                            ForEach(Array(report.intelligenceFailures.prefix(4))) { result in
                                FolderIntelligenceFailureRow(result: result)
                            }
                        }
                    }

                    if !report.uncoveredFolderIds.isEmpty {
                        Text("Uncovered Folders need example saves: \(folderNames(for: report.uncoveredFolderIds).joined(separator: ", "))")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(SaviTheme.textMuted)
                    }
                } else {
                    Text("Run the Folder audit to check SAVI’s local sorting rules against the golden examples.")
                        .font(.footnote)
                        .foregroundStyle(SaviTheme.textMuted)
                }

                Button {
                    store.runFolderAudit()
                } label: {
                    Label("Run Folder audit", systemImage: "checklist")
                }
                .buttonStyle(SaviSecondaryButtonStyle())

                Divider()
                    .overlay(SaviTheme.cardStroke)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent auto decisions")
                        .font(SaviType.ui(.caption, weight: .black))
                        .foregroundStyle(SaviTheme.textMuted)
                    if store.folderDecisionHistory.isEmpty {
                        Text("New auto-saves will show the chosen Folder, confidence, and reason here.")
                            .font(.footnote)
                            .foregroundStyle(SaviTheme.textMuted)
                    } else {
                        ForEach(store.folderDecisionHistory.prefix(5)) { decision in
                            FolderDecisionRow(decision: decision)
                        }
                        Button {
                            store.clearFolderDecisionHistory()
                        } label: {
                            Label("Clear decision history", systemImage: "xmark.circle")
                        }
                        .buttonStyle(SaviSecondaryButtonStyle())
                    }
                }

                Divider()
                    .overlay(SaviTheme.cardStroke)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Local learning")
                            .font(SaviType.ui(.caption, weight: .black))
                            .foregroundStyle(SaviTheme.textMuted)
                        Spacer()
                        Text("\(store.folderLearningCount) rule\(store.folderLearningCount == 1 ? "" : "s")")
                            .font(SaviType.ui(.caption, weight: .heavy))
                            .foregroundStyle(SaviTheme.accentText)
                    }
                    if store.recentFolderLearningSignals.isEmpty {
                        Text("When you move an auto-saved item to a better Folder, SAVI stores safe local hints here.")
                            .font(.footnote)
                            .foregroundStyle(SaviTheme.textMuted)
                    } else {
                        ForEach(store.recentFolderLearningSignals) { signal in
                            FolderLearningRow(
                                signal: signal,
                                folderName: store.folder(for: signal.folderId)?.name ?? signal.folderId
                            )
                        }
                    }
                }
            }
        }
    }

    private func folderNames(for ids: [String]) -> [String] {
        ids.map { id in
            store.folder(for: id)?.name ??
                SAVIFolderClassifier.defaultFolderOptions.first(where: { $0.id == id })?.name ??
                id
        }
    }
}

struct FolderAuditSummary: View {
    let report: SAVIFolderAuditReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(report.passedCount)/\(report.results.count)")
                    .font(SaviType.display(size: 26, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                Text("golden examples")
                    .font(SaviType.ui(.subheadline, weight: .bold))
                    .foregroundStyle(SaviTheme.textMuted)
                Spacer()
                Text("\(Int((report.passRate * 100).rounded()))%")
                    .font(SaviType.ui(.headline, weight: .black))
                    .foregroundStyle(report.failedCount == 0 ? SaviTheme.accentText : Color.orange)
            }

            HStack(spacing: 10) {
                FolderBrainMetric(
                    title: "Coverage",
                    value: "\(report.coveredFolderIds.count)/\(report.folderOptions.count)"
                )
                FolderBrainMetric(
                    title: "Failures",
                    value: "\(report.failedCount)"
                )
                FolderBrainMetric(
                    title: "AI Guardrails",
                    value: "\(report.intelligencePassedCount)/\(report.intelligenceResults.count)"
                )
            }
        }
    }
}

struct FolderBrainMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(SaviType.ui(.caption2, weight: .black))
                .foregroundStyle(SaviTheme.textMuted)
            Text(value)
                .font(SaviType.ui(.headline, weight: .black))
                .foregroundStyle(SaviTheme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FolderBrainStatusRow: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.caption.weight(.black))
                .foregroundStyle(SaviTheme.accentText)
                .frame(width: 24, height: 24)
                .background(SaviTheme.surfaceRaised)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.textMuted)
                Text(value)
                    .font(SaviType.ui(.subheadline, weight: .black))
                    .foregroundStyle(SaviTheme.text)
            }
            Spacer(minLength: 8)
        }
        .accessibilityElement(children: .combine)
    }
}

struct FolderAuditFailureRow: View {
    let result: SAVIFolderAuditResult

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(result.testCase.name)
                .font(SaviType.ui(.subheadline, weight: .black))
                .foregroundStyle(SaviTheme.text)
            Text("Expected \(result.testCase.expectedFolderId), got \(result.classification.folderId) · \(result.classification.confidence) · \(result.classification.reason)")
                .font(.caption)
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FolderIntelligenceFailureRow: View {
    let result: SAVIIntelligenceAuditResult

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(result.testCase.name)
                .font(SaviType.ui(.subheadline, weight: .black))
                .foregroundStyle(SaviTheme.text)
            Text("Expected \(result.testCase.expectedAccepted ? "accept" : "veto"), got \(result.acceptance.accepted ? "accept" : "veto") · local \(result.localClassification.folderId) · AI \(result.testCase.suggestedFolderId)")
                .font(.caption)
                .foregroundStyle(SaviTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FolderDecisionRow: View {
    let decision: SAVIFolderDecisionRecord

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbolName)
                .font(.caption.weight(.black))
                .foregroundStyle(symbolColor)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(decision.statusLabel)
                        .font(SaviType.ui(.caption2, weight: .black))
                        .foregroundStyle(statusForeground)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(statusBackground)
                        .clipShape(Capsule())
                    Text(decision.title)
                        .font(SaviType.ui(.subheadline, weight: .black))
                        .foregroundStyle(SaviTheme.text)
                        .lineLimit(1)
                }
                Text(detailText)
                    .font(.caption)
                    .foregroundStyle(SaviTheme.textMuted)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(decision.confidence)")
                    .font(SaviType.ui(.caption, weight: .black))
                    .foregroundStyle(SaviTheme.text)
                    .accessibilityLabel("Confidence \(decision.confidence)")
                Text(SaviText.relativeSavedTime(decision.createdAt))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(SaviTheme.textMuted)
            }
        }
    }

    private var detailText: String {
        var parts = ["→ \(decision.folderName)"]
        if let aiFolderName = decision.aiFolderName, aiFolderName != decision.folderName {
            parts.append("AI suggested \(aiFolderName)")
        }
        if let vetoReason = decision.vetoReason?.nilIfBlank {
            parts.append(vetoReason)
        } else if let aiReason = decision.aiReason?.nilIfBlank {
            parts.append(aiReason)
        } else {
            parts.append(decision.reason)
        }
        parts.append(decision.context)
        return parts.joined(separator: " · ")
    }

    private var symbolName: String {
        switch decision.outcomeKind {
        case .accepted: return "sparkles"
        case .vetoed: return "hand.raised.fill"
        case .timedOut: return "clock.badge.exclamationmark"
        case .unavailable, .failed: return "bolt.slash"
        case .skipped: return "minus.circle"
        case nil:
            switch decision.sourceKind {
            case .manual: return "hand.point.up.left.fill"
            case .learning: return "brain.head.profile"
            case .guardrail: return "shield.checkered"
            case .metadata: return "text.magnifyingglass"
            default: return "arrow.triangle.branch"
            }
        }
    }

    private var symbolColor: Color {
        switch decision.outcomeKind {
        case .accepted: return SaviTheme.accentText
        case .vetoed: return Color.orange
        case .timedOut, .unavailable, .failed: return SaviTheme.textMuted
        default: return SaviTheme.accentText
        }
    }

    private var statusForeground: Color {
        switch decision.outcomeKind {
        case .accepted: return SaviTheme.accentText
        case .vetoed: return Color.orange
        case .timedOut, .unavailable, .failed: return SaviTheme.textMuted
        default: return SaviTheme.text
        }
    }

    private var statusBackground: Color {
        switch decision.outcomeKind {
        case .accepted: return SaviTheme.chartreuse.opacity(0.18)
        case .vetoed: return Color.orange.opacity(0.16)
        default: return SaviTheme.surfaceRaised
        }
    }
}

struct FolderLearningRow: View {
    let signal: SAVIFolderLearningSignal
    let folderName: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(signal.phrase)
                .font(SaviType.ui(.subheadline, weight: .black))
                .foregroundStyle(SaviTheme.text)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text("\(folderName) · \(signal.uses)x")
                .font(.caption.weight(.semibold))
                .foregroundStyle(SaviTheme.textMuted)
                .lineLimit(1)
        }
    }
}

// MARK: - Sheets
