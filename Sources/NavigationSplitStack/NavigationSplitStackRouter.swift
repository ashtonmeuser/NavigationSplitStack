//
//  NavigationSplitStackRouter.swift
//  NavigationSplitStack
//
//  Created by Ashton Meuser on 2026-10-23.
//

import SwiftUI
import Dependencies

// TODO: Documentation
@MainActor @Observable
public final class NavigationSplitStackRouter<
    Sidebar: Hashable,
    Detail: Hashable
> {
    internal var horizontalSizeClass: UserInterfaceSizeClass?
    internal var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    internal var preferredCompactColumn = NavigationSplitViewColumn.sidebar {
        didSet {
            guard horizontalSizeClass == .compact, oldValue == .detail,
                preferredCompactColumn == .sidebar
            else {
                return
            }
            // Returning to the sidebar clears all detail selection in compact context
            if !detail.isEmpty {
                detail.removeAll()
            }
        }
    }
    /// The sidebar navigation path. Assigning it also shows the sidebar,
    /// even when the assigned path is unchanged.
    public var sidebar: [Sidebar] = [] {
        didSet {
            showSidebar()
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
            let column: NavigationSplitViewColumn =
                detail.isEmpty ? .sidebar : .detail
            if preferredCompactColumn != column {
                preferredCompactColumn = column
            }
        }
    }

    public nonisolated init() {}

    /// Shows the sidebar without changing its navigation path.
    /// Clears the detail path in compact layouts and preserves it in expanded layouts.
    public func showSidebar() {
        if horizontalSizeClass == .compact, !detail.isEmpty {
            detail.removeAll()
        }
        columnVisibility = .doubleColumn
        if preferredCompactColumn != .sidebar {
            preferredCompactColumn = .sidebar
        }
    }

    /// Hides the sidebar to focus on detail without changing either navigation path.
    /// Allows empty detail in expanded layouts, but does nothing when detail is empty in compact layouts.
    public func hideSidebar() {
        guard horizontalSizeClass != .compact || !detail.isEmpty else { return }
        columnVisibility = .detailOnly
        if !detail.isEmpty, preferredCompactColumn != .detail {
            preferredCompactColumn = .detail
        }
    }
}

extension NavigationSplitStackRouter: nonisolated DependencyKey {
    public typealias Value = NavigationSplitStackRouter<Sidebar, Detail>

    /// Live models must capture the router supplied by their navigation container.
    public nonisolated static var liveValue: Value {
        preconditionFailure("""
            NavigationSplitStackRouter dependency is only available within NavigationSplitStack sidebar and detail views.
            Alternatively, inject the router using withDependencies.
            """)
    }

    public nonisolated static var previewValue: Value { Value() }
    public nonisolated static var testValue: Value { Value() }
}
