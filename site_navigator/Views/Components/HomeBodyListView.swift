//
//  HomeBodyListView.swift
//  site_navigator
//

import SwiftUI

/// List display style — a real `List` so it gets native `.swipeActions`.
struct HomeBodyListView: View {
    let sites: [Site]
    let onTap: (Site) -> Void
    let onToggleFavorite: (Site) -> Void
    let onEdit: (Site) -> Void
    let onDelete: (Site) -> Void

    var body: some View {
        List {
            ForEach(sites) { site in
                Button {
                    onTap(site)
                } label: {
                    SiteRowView(site: site)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        onDelete(site)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    Button {
                        onEdit(site)
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        onToggleFavorite(site)
                    } label: {
                        Label(site.isFavorite ? "取消收藏" : "收藏", systemImage: site.isFavorite ? "star.slash" : "star")
                    }
                    .tint(.yellow)
                }
            }
        }
        .listStyle(.plain)
    }
}
