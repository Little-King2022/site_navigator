//
//  SiteActionMenuItems.swift
//  site_navigator
//

import SwiftUI

/// Shared long-press context-menu content (favorite/edit/delete) for the
/// card and grid display styles, which can't use `.swipeActions` since
/// that's List-only. Keeps the three actions consistent across styles
/// without implementing them twice.
struct SiteActionMenuItems: View {
    let site: Site
    let onToggleFavorite: (Site) -> Void
    let onEdit: (Site) -> Void
    let onDelete: (Site) -> Void

    var body: some View {
        Button {
            onToggleFavorite(site)
        } label: {
            Label(site.isFavorite ? "取消收藏" : "收藏", systemImage: site.isFavorite ? "star.slash" : "star")
        }
        Button {
            onEdit(site)
        } label: {
            Label("编辑", systemImage: "pencil")
        }
        Button(role: .destructive) {
            onDelete(site)
        } label: {
            Label("删除", systemImage: "trash")
        }
    }
}
