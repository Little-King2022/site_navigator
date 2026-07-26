//
//  HomeView.swift
//  app_test
//

import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    // Single source of truth for both the favorites strip and the main body —
    // already sorted newest-added-first, which is also the required default.
    @Query(sort: \Site.dateAdded, order: .reverse) private var sites: [Site]

    @AppStorage("displayStyle") private var displayStyleRaw: String = DisplayStyle.card.rawValue
    @AppStorage("sortOption") private var sortOptionRaw: String = SortOption.dateAdded.rawValue

    @State private var isPresentingAddSite = false
    @State private var siteToEdit: Site?
    @State private var safariSite: Site?
    @State private var addSiteInitialURL: String?

    @AppStorage("hasCheckedClipboardOnFirstLaunch") private var hasCheckedClipboard = false
    @State private var clipboardURLToConfirm: URL?

    private var displayStyle: DisplayStyle {
        get { DisplayStyle(rawValue: displayStyleRaw) ?? .card }
        nonmutating set { displayStyleRaw = newValue.rawValue }
    }

    private var sortOption: SortOption {
        get { SortOption(rawValue: sortOptionRaw) ?? .dateAdded }
        nonmutating set { sortOptionRaw = newValue.rawValue }
    }

    // Favorited sites are additive: they show in the top strip AND stay in
    // this main collection, sorted the same way as everything else.
    private var sortedSites: [Site] {
        switch sortOption {
        case .dateAdded:
            return sites
        case .name:
            return sites.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .dateLastOpened:
            return sites.sorted { ($0.dateLastOpened ?? .distantPast) > ($1.dateLastOpened ?? .distantPast) }
        }
    }

    private var favoriteSites: [Site] {
        sites.filter(\.isFavorite)
    }

    var body: some View {
        NavigationStack {
            Group {
                if sites.isEmpty {
                    EmptyStateView { isPresentingAddSite = true }
                } else {
                    VStack(spacing: 0) {
                        if !favoriteSites.isEmpty {
                            FavoritesStripView(sites: favoriteSites, onTap: open)
                            Divider()
                        }
                        mainContent(for: displayStyle)
                    }
                }
            }
            .navigationTitle("网站导航")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    stylePickerMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    sortPickerMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addSiteInitialURL = nil
                        isPresentingAddSite = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingAddSite) {
            AddSiteView(initialURLString: addSiteInitialURL)
        }
        .sheet(item: $siteToEdit) { site in
            EditSiteView(site: site)
        }
        .sheet(item: $safariSite) { site in
            if let url = WebsiteMetadataFetcher.normalizeURL(site.urlString) {
                SafariView(url: url)
            } else {
                Text("无效的网址")
            }
        }
        .onAppear {
            guard !hasCheckedClipboard else { return }
            hasCheckedClipboard = true
            checkClipboardForURL()
        }
        .alert(
            "检测到剪贴板中的网址",
            isPresented: Binding(
                get: { clipboardURLToConfirm != nil },
                set: { isPresented in
                    if !isPresented { clipboardURLToConfirm = nil }
                }
            )
        ) {
            Button("添加") {
                if let url = clipboardURLToConfirm {
                    addSiteInitialURL = url.absoluteString
                    isPresentingAddSite = true
                }
                clipboardURLToConfirm = nil
            }
            Button("忽略", role: .cancel) {
                clipboardURLToConfirm = nil
            }
        } message: {
            Text("\(clipboardURLToConfirm?.absoluteString ?? "")\n是否要添加为导航站点？")
        }
    }

    /// Runs once ever (gated by `hasCheckedClipboard`). `hasURLs`/`hasStrings`
    /// only check item *types* on the pasteboard and don't trigger the
    /// system "Allow Paste" prompt — only reading the actual `.url`/`.string`
    /// value below does that (standard iOS privacy behavior, unavoidable).
    private func checkClipboardForURL() {
        let pasteboard = UIPasteboard.general
        guard pasteboard.hasURLs || pasteboard.hasStrings else { return }
        if let url = pasteboard.url ?? pasteboard.string.flatMap(WebsiteMetadataFetcher.normalizeURL) {
            clipboardURLToConfirm = url
        }
    }

    @ViewBuilder
    private func mainContent(for style: DisplayStyle) -> some View {
        switch style {
        case .list:
            HomeBodyListView(
                sites: sortedSites,
                onTap: open,
                onToggleFavorite: toggleFavorite,
                onEdit: { siteToEdit = $0 },
                onDelete: delete
            )
        case .card:
            HomeBodyCardView(
                sites: sortedSites,
                onTap: open,
                onToggleFavorite: toggleFavorite,
                onEdit: { siteToEdit = $0 },
                onDelete: delete
            )
        case .grid:
            HomeBodyGridView(
                sites: sortedSites,
                onTap: open,
                onToggleFavorite: toggleFavorite,
                onEdit: { siteToEdit = $0 },
                onDelete: delete
            )
        }
    }

    private var stylePickerMenu: some View {
        Menu {
            Picker("展示风格", selection: Binding(get: { displayStyle }, set: { displayStyle = $0 })) {
                ForEach(DisplayStyle.allCases, id: \.self) { style in
                    Label(style.label, systemImage: style.symbolName).tag(style)
                }
            }
        } label: {
            Image(systemName: displayStyle.symbolName)
        }
    }

    private var sortPickerMenu: some View {
        Menu {
            Picker("排序方式", selection: Binding(get: { sortOption }, set: { sortOption = $0 })) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.label).tag(option)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }

    /// Single entry point for opening a site, shared by every display style
    /// and the favorites strip, so `dateLastOpened` always gets updated
    /// regardless of which open mode is used.
    private func open(_ site: Site) {
        site.dateLastOpened = .now
        switch site.openMode {
        case .inApp:
            safariSite = site
        case .external:
            if let url = WebsiteMetadataFetcher.normalizeURL(site.urlString) {
                openURL(url)
            }
        }
    }

    private func toggleFavorite(_ site: Site) {
        site.isFavorite.toggle()
    }

    private func delete(_ site: Site) {
        modelContext.delete(site)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Site.self, inMemory: true)
}
