//
//  site_navigatorApp.swift
//  site_navigator
//
//  Created by littleking on 2026/7/26.
//

import SwiftUI
import SwiftData

@main
struct site_navigatorApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: Site.self)
    }
}
