//
//  SiteRowView.swift
//  app_test
//

import SwiftUI

/// List-style row: icon + name + host, used inside `HomeBodyListView`.
struct SiteRowView: View {
    let site: Site

    var body: some View {
        HStack(spacing: 12) {
            SiteIconView(iconData: site.iconData, name: site.name, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(site.name)
                    .font(.body)
                    .lineLimit(1)
                Text(site.host)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if site.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
    }
}
