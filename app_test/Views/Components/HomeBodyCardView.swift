//
//  HomeBodyCardView.swift
//  app_test
//

import SwiftUI

/// Card display style — `ScrollView` + `LazyVStack` (needed for card
/// spacing/shadow that `List` can't easily produce). Uses `.contextMenu`
/// in place of `.swipeActions`, which is List-only.
struct HomeBodyCardView: View {
    let sites: [Site]
    let onTap: (Site) -> Void
    let onToggleFavorite: (Site) -> Void
    let onEdit: (Site) -> Void
    let onDelete: (Site) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sites) { site in
                    Button {
                        onTap(site)
                    } label: {
                        SiteCardView(site: site)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        SiteActionMenuItems(
                            site: site,
                            onToggleFavorite: onToggleFavorite,
                            onEdit: onEdit,
                            onDelete: onDelete
                        )
                    }
                }
            }
            .padding()
        }
    }
}
