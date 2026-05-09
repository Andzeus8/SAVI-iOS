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

// MARK: - Root UI

struct NativeSaviRootView: View {
    @EnvironmentObject private var store: SaviStore
    @State private var backupImportPresented = false

    var body: some View {
        ZStack(alignment: .bottom) {
            SaviTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                selectedScreen
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                if store.prefs.onboarded {
                    bottomBar
                }
            }
                .sheet(item: $store.presentedSheet) { sheet in
                    switch sheet {
                    case .save:
                        SaveSheet()
                            .environmentObject(store)
                            .preferredColorScheme(store.preferredColorScheme)
                    case .folderEditor(let folder):
                        FolderEditorSheet(folder: folder)
                            .environmentObject(store)
                            .preferredColorScheme(store.preferredColorScheme)
                    case .publicProfile:
                        PublicProfileSheet()
                            .environmentObject(store)
                            .preferredColorScheme(store.preferredColorScheme)
                    case .friendProfile(let friend):
                        FriendProfileSheet(friend: friend)
                            .environmentObject(store)
                            .preferredColorScheme(store.preferredColorScheme)
                    case .friendLinkDetail(let link):
                        FriendLinkDetailSheet(link: link)
                            .environmentObject(store)
                            .preferredColorScheme(store.preferredColorScheme)
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                    case .friendLinkSave(let link):
                        FriendLinkSaveSheet(link: link)
                            .environmentObject(store)
                            .preferredColorScheme(store.preferredColorScheme)
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                    }
                }
                .sheet(item: $store.presentedItem) { item in
                    ItemDetailSheet(item: item)
                        .environmentObject(store)
                        .preferredColorScheme(store.preferredColorScheme)
                }
                .sheet(item: $store.editingItem) { item in
                    ItemEditorSheet(item: item)
                        .environmentObject(store)
                        .preferredColorScheme(store.preferredColorScheme)
                }
                .sheet(item: Binding<AssetPreviewURL?>(
                    get: { store.quickLookAssetURL.map { AssetPreviewURL(url: $0) } },
                    set: { store.quickLookAssetURL = $0?.url }
                )) { preview in
                    QuickLookPreview(url: preview.url)
                        .preferredColorScheme(store.preferredColorScheme)
                }
                .sheet(item: Binding<WebPreviewURL?>(
                    get: { store.webPreviewURL.map { WebPreviewURL(url: $0) } },
                    set: { store.webPreviewURL = $0?.url }
                )) { preview in
                    SafariLinkPreview(url: preview.url)
                        .ignoresSafeArea()
                        .preferredColorScheme(store.preferredColorScheme)
                }
                .sheet(isPresented: $store.isSearchRefinePresented) {
                    SearchRefineSheet()
                        .environmentObject(store)
                        .preferredColorScheme(store.preferredColorScheme)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
                .sheet(item: $store.activeSearchFacet) { facet in
                    SearchFacetSheet(facet: facet)
                        .environmentObject(store)
                        .preferredColorScheme(store.preferredColorScheme)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
                .fileImporter(isPresented: $backupImportPresented, allowedContentTypes: [.json, .saviArchiveZip, .saviArchivePackage]) { result in
                    if case .success(let url) = result {
                        Task { await store.previewBackupImport(from: url) }
                    }
                }
                .alert(
                    "Replace your SAVI library?",
                    isPresented: Binding(
                        get: { store.pendingBackupPreview != nil },
                        set: { isPresented in
                            if !isPresented {
                                store.cancelPendingBackupImport()
                            }
                        }
                    )
                ) {
                    Button("Replace current library", role: .destructive) {
                        Task { await store.restorePendingBackupImport() }
                    }
                    Button("Cancel", role: .cancel) {
                        store.cancelPendingBackupImport()
                    }
                } message: {
                    Text(store.pendingBackupPreview?.restoreMessage ?? "This backup will replace the current SAVI library on this device.")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task {
                        await store.refreshForegroundWork()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    Task {
                        await store.refreshForegroundWork()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    store.lockProtectedFolders()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    store.lockProtectedFolders()
                }

            if !store.prefs.onboarded {
                OnboardingView()
                    .environmentObject(store)
                    .transition(.opacity)
                    .zIndex(2)
            }

            if store.prefs.onboarded, let step = store.activeCoachStep {
                SaviCoachOverlay(
                    step: step,
                    currentIndex: (SaviCoachStep.allCases.firstIndex(of: step) ?? 0) + 1,
                    totalCount: SaviCoachStep.allCases.count,
                    nextAction: { store.advanceCoachTour() },
                    skipAction: { store.completeCoachTour() }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .zIndex(3)
            }

            if let toast = store.toast {
                ToastView(message: toast)
                    .padding(.bottom, store.prefs.onboarded ? 104 : 72)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            if store.toast == toast {
                                withAnimation { store.toast = nil }
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var selectedScreen: some View {
        switch store.selectedTab {
        case .home:
            HomeScreen()
        case .search:
            SearchScreen()
        case .explore:
            ExploreScreen()
        case .folders:
            FoldersScreen()
        case .profile:
            ProfileScreen(backupImportPresented: $backupImportPresented)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(SaviTheme.cardStroke)
                .frame(height: 1)
            SaviBottomBar()
                .environmentObject(store)
                .padding(.horizontal, 10)
                .padding(.top, 7)
                .padding(.bottom, 6)
        }
        .background(SaviTheme.surfaceRaised.ignoresSafeArea(edges: .bottom))
    }
}

struct SaviBottomBar: View {
    @EnvironmentObject private var store: SaviStore

    var body: some View {
        HStack(spacing: 6) {
            SaviBottomTab(tab: .home, title: "Home", symbolName: "house.fill")
            SaviBottomTab(tab: .search, title: "Search", symbolName: "magnifyingglass")

            Button {
                store.openAddSheet()
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.black))
                    .frame(width: 52, height: 52)
                    .background(SaviTheme.chartreuse)
                    .foregroundStyle(.black)
                    .clipShape(Circle())
                    .shadow(color: SaviTheme.chartreuse.opacity(0.24), radius: 12, x: 0, y: 5)
                    .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(SaviPressScaleButtonStyle(scale: 0.92))
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Add save")

            SaviBottomTab(tab: .explore, title: "Explore", symbolName: "sparkles")
            SaviBottomTab(tab: .profile, title: "Profile", symbolName: "person.crop.circle.fill")
        }
    }
}

struct SaviBottomTab: View {
    @EnvironmentObject private var store: SaviStore
    let tab: SaviTab
    let title: String
    let symbolName: String

    private var isSelected: Bool {
        store.selectedTab == tab
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                store.handleBottomTabTap(tab)
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: symbolName)
                    .font(.system(size: 18, weight: .bold))
                Text(title)
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .foregroundStyle(isSelected ? .black : SaviTheme.text)
            .background(isSelected ? SaviTheme.softAccent : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: SaviRadius.bottomTab, style: .continuous))
        }
        .buttonStyle(SaviPressScaleButtonStyle())
        .accessibilityLabel(title)
    }
}
