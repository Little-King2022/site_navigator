//
//  HomeBodyGridView.swift
//  app_test
//

import SwiftUI

/// Grid ("宫格") display style — icon-grid layout similar to a home screen.
struct HomeBodyGridView: View {
    let sites: [Site]
    let onTap: (Site) -> Void
    let onToggleFavorite: (Site) -> Void
    let onEdit: (Site) -> Void
    let onDelete: (Site) -> Void

    private let columns = [GridItem(.adaptive(minimum: 84, maximum: 110), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(sites) { site in
                    Button {
                        onTap(site)
                    } label: {
                        SiteGridCellView(site: site)
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
