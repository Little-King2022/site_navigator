//
//  SiteGridCellView.swift
//  app_test
//

import SwiftUI

/// Icon-grid style cell (icon on top, name below), used inside `HomeBodyGridView`.
struct SiteGridCellView: View {
    let site: Site

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                SiteIconView(iconData: site.iconData, name: site.name, size: 60)
                if site.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.yellow)
                        .padding(4)
                        .background(.background, in: Circle())
                        .offset(x: 8, y: -8)
                }
            }
            Text(site.name)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
    }
}
