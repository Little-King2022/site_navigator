//
//  SiteIconView.swift
//  site_navigator
//

import SwiftUI
import UIKit

/// Renders a site's fetched/custom icon, or — when `iconData` can't be
/// decoded (fetch failed, still fetching, etc.) — a stable colored-circle
/// placeholder derived from the site's name. Shared by every row/card/cell
/// so icon rendering isn't reimplemented per display style.
struct SiteIconView: View {
    let iconData: Data?
    let name: String
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let iconData, let uiImage = UIImage(data: iconData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(size * 0.16)
                    .background(.background)
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            placeholderColor
            Text(initial)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.first.map { String($0).uppercased() } ?? "?"
    }

    private var placeholderColor: Color {
        let palette: [Color] = [.red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown]
        let hash = abs(name.hashValue)
        return palette[hash % palette.count]
    }
}
