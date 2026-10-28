//
//  NavigationSplitStackRouter.swift
//  NavigationSplitStack
//
//  Created by Ashton Meuser on 2026-10-23.
//

import SwiftUI

// TODO: Documentation
@MainActor @Observable public final class NavigationSplitStackRouter<Sidebar: Hashable, Detail: Hashable> {
    internal var horizontalSizeClass: UserInterfaceSizeClass?
    internal var columnVisibility = NavigationSplitViewVisibility.automatic
    public var preferredCompactColumn = NavigationSplitViewColumn.sidebar {
        didSet {
            guard horizontalSizeClass == .compact, oldValue == .detail, preferredCompactColumn == .sidebar else {
                return
            }
            // Returning to the sidebar clears all detail selection in compact context
            detailRoot = nil
            detailRest = []
        }
    }
    public var sidebar: [Sidebar] = [] {
        didSet {
            // Display the sidebar, unsetting any detail selection in compact context
            if horizontalSizeClass == .compact {
                detail = [] // This will in turn set columnVisibility = .doubleColumn
            } else {
                columnVisibility = .doubleColumn
            }
        }
    }
    internal var detailRoot: Detail?
    internal var detailRest: [Detail] = []
    public var detail: [Detail] {
        get {
            if let detailRoot {
                return [detailRoot] + detailRest
            }
            return []
        }
        set {
            detailRoot = newValue.first
            detailRest = Array(newValue.dropFirst())
            if detailRoot != nil {
                print("col vis: \(columnVisibility) preferred: \(preferredCompactColumn)")
                columnVisibility = .detailOnly
                preferredCompactColumn = .detail
            } else {
                columnVisibility = .doubleColumn
                preferredCompactColumn = .sidebar
            }
        }
    }

    public init() {}
}
