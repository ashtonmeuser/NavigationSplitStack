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
    internal var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    internal var preferredCompactColumn = NavigationSplitViewColumn.sidebar {
        didSet {
            guard horizontalSizeClass == .compact, oldValue == .detail, preferredCompactColumn == .sidebar else {
                return
            }
            // Returning to the sidebar clears all detail selection in compact context
            if !detail.isEmpty {
                detail.removeAll()
            }
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
    // The nested stack's path excludes the first element, which supplies its root view.
    internal var detailRest: [Detail] {
        get {
            Array(detail.dropFirst())
        }
        set {
            // Ignore writes from a departing stack after its root has been cleared.
            guard !detail.isEmpty else { return }
            let endIndex = detail.endIndex
            detail.replaceSubrange(1..<endIndex, with: newValue)
        }
    }
    public var detail: [Detail] = [] {
        didSet {
            // Only opening or clearing the detail stack changes column presentation.
            guard oldValue.isEmpty != detail.isEmpty else { return }

            if detail.isEmpty {
                columnVisibility = .doubleColumn
            }
            let column: NavigationSplitViewColumn = detail.isEmpty ? .sidebar : .detail
            if preferredCompactColumn != column {
                preferredCompactColumn = column
            }
        }
    }

    public init() {}
}
