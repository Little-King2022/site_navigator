//
//  EmptyStateView.swift
//  app_test
//

import SwiftUI

struct EmptyStateView: View {
    var onAdd: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("还没有站点", systemImage: "globe")
        } description: {
            Text("添加你常用的网站，方便统一管理和快速访问")
        } actions: {
            Button("添加站点", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
    }
}
