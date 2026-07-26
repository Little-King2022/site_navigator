//
//  Enums.swift
//  site_navigator
//

import Foundation

enum DisplayStyle: String, CaseIterable {
    case card
    case list
    case grid

    var label: String {
        switch self {
        case .card: return "卡片"
        case .list: return "列表"
        case .grid: return "宫格"
        }
    }

    var symbolName: String {
        switch self {
        case .card: return "rectangle.grid.1x2"
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }
}

enum SortOption: String, CaseIterable {
    case dateAdded
    case name
    case dateLastOpened

    var label: String {
        switch self {
        case .dateAdded: return "添加时间"
        case .name: return "名称"
        case .dateLastOpened: return "最后打开时间"
        }
    }
}
