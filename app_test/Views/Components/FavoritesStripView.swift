//
//  FavoritesStripView.swift
//  app_test
//

import SwiftUI

/// Horizontally scrolling "speed dial" strip pinned above the main body.
/// Favorited sites shown here also remain in the main list/grid/card body
/// below (favoriting marks, it doesn't move).
struct FavoritesStripView: View {
    let sites: [Site]
    let onTap: (Site) -> Void

    private let iconSize: CGFloat = 56
    private let verticalPadding: CGFloat = 8

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 16) {
                ForEach(sites) { site in
                    Button {
                        onTap(site)
                    } label: {
                        VStack(spacing: 6) {
                            SiteIconView(iconData: site.iconData, name: site.name, size: iconSize)
                            Text(site.name)
                                .font(.caption)
                                .lineLimit(1)
                                .frame(width: 72)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, verticalPadding)
        }
        // A horizontal ScrollView has no intrinsic height limit of its own —
        // without this it stretches to fill all remaining vertical space in
        // the parent VStack instead of hugging just one row of icons.
        .frame(height: iconSize + 6 + 16 + verticalPadding * 2)
    }
}
