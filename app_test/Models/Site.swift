//
//  Site.swift
//  app_test
//

import Foundation
import SwiftData

enum OpenMode: String, CaseIterable {
    case inApp
    case external

    var label: String {
        switch self {
        case .inApp: return "应用内浏览器"
        case .external: return "系统 Safari"
        }
    }
}

@Model
final class Site {
    @Attribute(.unique) var id: UUID
    var urlString: String
    var name: String
    var isNameCustomized: Bool
    var isIconCustomized: Bool
    @Attribute(.externalStorage) var iconData: Data?
    var dateAdded: Date
    var dateLastOpened: Date?
    var isFavorite: Bool
    private var openModeRaw: String

    var openMode: OpenMode {
        get { OpenMode(rawValue: openModeRaw) ?? .inApp }
        set { openModeRaw = newValue.rawValue }
    }

    /// Best-effort host string for display (e.g. "example.com") derived from urlString.
    var host: String {
        URL(string: urlString)?.host ?? urlString
    }

    init(
        urlString: String,
        name: String,
        openMode: OpenMode = .inApp
    ) {
        self.id = UUID()
        self.urlString = urlString
        self.name = name
        self.isNameCustomized = false
        self.isIconCustomized = false
        self.iconData = nil
        self.dateAdded = .now
        self.dateLastOpened = nil
        self.isFavorite = false
        self.openModeRaw = openMode.rawValue
    }
}
