//
//  app_testApp.swift
//  app_test
//
//  Created by littleking on 2026/7/26.
//

import SwiftUI
import SwiftData

@main
struct app_testApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: Site.self)
    }
}
