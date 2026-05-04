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

struct FolderIconBadge: View {
    let symbolName: String
    let color: String
    let imageDataURL: String?
    var size: CGFloat = 42
    var cornerRadius: CGFloat = 14
    var font: Font = SaviType.ui(.title3, weight: .bold)
    var background: Color?
    var foreground: Color?
    var publicBadgeStyle: SaviFolderVisualStyle?

    private var customImage: UIImage? {
        guard let imageDataURL = imageDataURL?.nilIfBlank else { return nil }
        return SaviText.imageFromDataURL(imageDataURL)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(background ?? Color(hex: color))

            if let customImage {
                Image(uiImage: customImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
            } else {
                Image(systemName: symbolName)
                    .font(font)
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(foreground ?? SaviTheme.foreground(onHex: color))
                    .frame(width: size * 0.58, height: size * 0.58)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(alignment: .bottomTrailing) {
            if let publicBadgeStyle {
                PublicFolderBadge(style: publicBadgeStyle)
                    .scaleEffect(size < 40 ? 0.88 : 0.96)
                    .offset(x: size < 40 ? 6 : 7, y: size < 40 ? 6 : 7)
                    .accessibilityHidden(true)
            }
        }
    }
}

struct FolderIconView: View {
    let folder: SaviFolder
    var size: CGFloat = 42
    var cornerRadius: CGFloat = 14
    var font: Font = SaviType.ui(.title3, weight: .bold)

    var body: some View {
        FolderIconBadge(
            symbolName: folder.symbolName,
            color: folder.color,
            imageDataURL: folder.image,
            size: size,
            cornerRadius: cornerRadius,
            font: font
        )
    }
}

struct HeaderBlock: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var titleSize: CGFloat = 42

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(SaviType.ui(.caption, weight: .heavy))
                .foregroundStyle(SaviTheme.accentText)
            Text(title)
                .font(SaviType.display(size: titleSize, weight: .black))
                .foregroundStyle(SaviTheme.text)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
            Text(subtitle)
                .font(SaviType.ui(.callout, weight: .regular))
                .foregroundStyle(SaviTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(SaviType.ui(.title3, weight: .bold))
                .foregroundStyle(SaviTheme.text)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(SaviType.ui(.subheadline, weight: .bold))
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 36)
                        .background(SaviTheme.subtleSurface)
                        .foregroundStyle(SaviTheme.accentText)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(SaviTheme.cardStroke.opacity(0.78), lineWidth: 1))
                }
                .buttonStyle(SaviPressScaleButtonStyle())
            }
        }
    }
}

struct FolderLibraryView: View {
    @EnvironmentObject private var store: SaviStore
    @State private var isReordering = false
    @State private var draggedFolderId: String?
    let viewMode: SaviFolderViewMode

    private var sortedFolders: [SaviFolder] {
        store.orderedFoldersForDisplay()
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: SaviFolderTileMetrics.gridSpacing),
            count: 3
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(sortedFolders.count) folders")
                        .font(SaviType.ui(.caption, weight: .bold))
                        .foregroundStyle(SaviTheme.accentText)
                    Text("Drag to reorder")
                        .font(SaviType.ui(.caption, weight: .semibold))
                        .foregroundStyle(SaviTheme.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 7) {
                    FolderViewModePicker(selectedMode: viewMode)

                    Button {
                        toggleReordering()
                    } label: {
                        Image(systemName: isReordering ? "checkmark" : "arrow.up.arrow.down")
                            .font(.subheadline.weight(.black))
                            .frame(width: 36, height: 36)
                            .background(isReordering ? SaviTheme.softAccent : Color.clear)
                            .foregroundStyle(isReordering ? .black : SaviTheme.accentText)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(SaviPressScaleButtonStyle())
                    .accessibilityLabel(isReordering ? "Done rearranging Folders" : "Rearrange Folders")
                }
                .padding(4)
                .background(SaviTheme.subtleSurface)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(SaviTheme.cardStroke.opacity(0.78), lineWidth: 1)
                )

                Button {
                    store.openFolderEditor(nil)
                } label: {
                    Label("New folder", systemImage: "folder.badge.plus")
                        .font(SaviType.ui(.caption2, weight: .black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .padding(.horizontal, 10)
                        .frame(height: 44)
                        .background(SaviTheme.chartreuse)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(SaviPressScaleButtonStyle())
                .accessibilityLabel("New Folder")
            }

            if isReordering {
                HStack(spacing: 8) {
                    Image(systemName: "hand.point.up.left.fill")
                    Text("Drag Folders into the order you want.")
                    Spacer()
                }
                .font(SaviType.ui(.caption, weight: .black))
                .foregroundStyle(SaviTheme.accentText)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .saviCard(cornerRadius: 14, shadow: false)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if viewMode == .grid {
                LazyVGrid(columns: columns, spacing: SaviFolderTileMetrics.gridSpacing) {
                    ForEach(sortedFolders) { folder in
                        FolderGridTile(
                            folder: folder,
                            isReordering: isReordering,
                            isDragged: draggedFolderId == folder.id
                        )
                        .onDrag {
                            dragProvider(for: folder)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: FolderReorderDropDelegate(
                                targetFolder: folder,
                                store: store,
                                draggedFolderId: $draggedFolderId,
                                isReordering: $isReordering
                            )
                        )
                    }
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sortedFolders) { folder in
                        FolderCard(
                            folder: folder,
                            isReordering: isReordering,
                            isDragged: draggedFolderId == folder.id
                        )
                        .onDrag {
                            dragProvider(for: folder)
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: FolderReorderDropDelegate(
                                targetFolder: folder,
                                store: store,
                                draggedFolderId: $draggedFolderId,
                                isReordering: $isReordering
                            )
                        )
                    }
                }
            }
        }
    }

    private func toggleReordering() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            if isReordering {
                store.finishFolderReordering()
                draggedFolderId = nil
                isReordering = false
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isReordering = true
            }
        }
    }

    private func dragProvider(for folder: SaviFolder) -> NSItemProvider {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            isReordering = true
            draggedFolderId = folder.id
        }
        return NSItemProvider(object: folder.id as NSString)
    }
}

private struct FolderReorderDropDelegate: DropDelegate {
    let targetFolder: SaviFolder
    let store: SaviStore
    @Binding var draggedFolderId: String?
    @Binding var isReordering: Bool

    func dropEntered(info: DropInfo) {
        guard let draggedFolderId, draggedFolderId != targetFolder.id else { return }
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                store.reorderFolder(draggedId: draggedFolderId, over: targetFolder.id)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.86)) {
                store.finishFolderReordering()
                draggedFolderId = nil
                isReordering = false
            }
        }
        return true
    }
}

struct FolderViewModePicker: View {
    @EnvironmentObject private var store: SaviStore
    let selectedMode: SaviFolderViewMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(SaviFolderViewMode.allCases) { mode in
                Button {
                    store.setFolderViewMode(mode)
                } label: {
                    Image(systemName: mode.symbolName)
                        .font(.caption.weight(.black))
                        .frame(width: 30, height: 30)
                        .background(selectedMode == mode ? SaviTheme.softAccent : Color.clear)
                        .foregroundStyle(selectedMode == mode ? .black : SaviTheme.textMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(SaviPressScaleButtonStyle())
                .accessibilityLabel("\(mode.title) view")
            }
        }
    }
}

struct FolderGridTile: View {
    @EnvironmentObject private var store: SaviStore
    @Environment(\.colorScheme) private var colorScheme
    let folder: SaviFolder
    var isReordering = false
    var isDragged = false

    private var isLocked: Bool {
        folder.locked && !store.isProtectedKeeperUnlocked(folder)
    }

    private var displayName: String {
        SaviFolderNameFormatter.balanced(folder.name)
    }

    var body: some View {
        let style = SaviFolderVisualStyle.make(for: folder, colorScheme: colorScheme)
        ZStack(alignment: .topTrailing) {
            Button {
                if !isReordering {
                    store.openFolder(folder)
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 6) {
                        FolderIconBadge(
                            symbolName: folder.symbolName,
                            color: style.baseHex,
                            imageDataURL: folder.image,
                            size: SaviFolderTileMetrics.iconSize,
                            cornerRadius: SaviFolderTileMetrics.iconCornerRadius,
                            font: SaviFolderTileMetrics.iconFont,
                            background: style.iconBackground,
                            foreground: style.iconForeground,
                            publicBadgeStyle: folder.isPublic ? style : nil
                        )
                        Spacer()
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(SaviType.display(size: SaviFolderTileMetrics.titleSize, weight: .black))
                            .foregroundStyle(style.text)
                            .shadow(color: style.titleShadow, radius: style.titleShadowRadius, x: 0, y: 1)
                            .lineLimit(2)
                            .lineSpacing(1)
                            .minimumScaleFactor(0.78)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        if isLocked {
                            FolderCountLabel(
                                text: "Locked",
                                style: style
                            )
                        }
                    }
                }
                .padding(SaviFolderTileMetrics.padding)
                .frame(
                    maxWidth: .infinity,
                    minHeight: SaviFolderTileMetrics.tileHeight,
                    maxHeight: SaviFolderTileMetrics.tileHeight,
                    alignment: .leading
                )
                .background(style.backgroundGradient)
                .clipShape(RoundedRectangle(cornerRadius: SaviRadius.folder, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: SaviRadius.folder, style: .continuous)
                        .stroke(style.stroke, lineWidth: colorScheme == .light ? 1.15 : 1)
                )
                .shadow(color: style.shadow, radius: SaviShadow.folderRadius(colorScheme), x: 0, y: SaviShadow.folderY(colorScheme))
            }
            .buttonStyle(SaviPressScaleButtonStyle())
            .accessibilityLabel("\(folder.name), \(folder.isPublic ? "Public, " : "")\(isLocked ? "Locked" : "\(store.count(in: folder)) saves")")

            if isReordering {
                Image(systemName: "line.3.horizontal")
                    .font(.caption.weight(.black))
                    .frame(width: 24, height: 24)
                    .background(SaviTheme.chartreuse)
                    .foregroundStyle(.black)
                    .clipShape(Circle())
                    .padding(6)
                    .accessibilityHidden(true)
            } else if !folder.system {
                Button {
                    store.openFolderEditor(folder)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption2.weight(.black))
                        .frame(width: 24, height: 24)
                        .background(style.countBackground.opacity(0.88))
                        .foregroundStyle(style.countForeground)
                        .clipShape(Circle())
                }
                .buttonStyle(SaviPressScaleButtonStyle())
                .padding(6)
                .accessibilityLabel("Edit \(folder.name)")
            }
        }
        .scaleEffect(isDragged ? 1.04 : 1)
        .opacity(isDragged ? 0.68 : 1)
        .rotationEffect(.degrees(isReordering && !isDragged ? (folder.order.isMultiple(of: 2) ? -0.7 : 0.7) : 0))
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isDragged)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isReordering)
    }
}
