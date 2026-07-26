//
//  SiteCardView.swift
//  site_navigator
//

import SwiftUI

/// Card-style cell used inside `HomeBodyCardView`.
struct SiteCardView: View {
    let site: Site

    var body: some View {
        HStack(spacing: 14) {
            SiteIconView(iconData: site.iconData, name: site.name, size: 44)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(site.name)
                        .font(.headline)
                        .lineLimit(1)
                    if site.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }
                Text(site.host)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(lastOpenedLabel)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
    }

    private var lastOpenedLabel: String {
        guard let date = site.dateLastOpened else { return "尚未打开" }
        return "最后打开：" + date.formatted(.relative(presentation: .named))
    }
}
