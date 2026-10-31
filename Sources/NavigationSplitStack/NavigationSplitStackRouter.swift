//
//  NavigationSplitStackRouter.swift
//  NavigationSplitStack
//
//  Created by Ashton Meuser on 2026-10-23.
//

import SwiftUI

/// Observable navigation state for a sidebar stack and a detail stack.
///
/// Store a router in a parent view's `@State` and pass it to
/// ``/NavigationSplitStack/NavigationSplitStack``. Mutate ``sidebar`` and ``detail`` to navigate,
/// or call ``showSidebar()`` and ``hideSidebar()`` to request column presentation.
/// All router access is isolated to the main actor.
///
/// The paths have different roots: ``sidebar`` contains only destinations pushed
/// above the sidebar's permanent root, while ``detail`` includes its root as the
/// first element. Both paths support standard array operations, including
/// `append(_:)`, `removeLast()`, and `removeAll()`.
///
/// Use a separate router for each split-view instance. The attached view supplies
/// the current horizontal size class, which determines whether returning to the
/// sidebar clears detail. Before attachment, the size class is unknown and
/// compact-only clearing does not apply.
///
/// When restoring both paths in a compact layout, assign ``sidebar`` before
/// ``detail``. Assigning the sidebar path requests sidebar presentation and
/// clears any existing detail path in that layout.
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
            // Returning to the sidebar clears all detail selection in compact context.
            if !detail.isEmpty {
                detail.removeAll()
            }
        }
    }
    /// The destinations pushed above the sidebar's permanent root.
    ///
    /// An empty array shows the sidebar root. Assigning or mutating this path
    /// also calls ``showSidebar()``, even when the resulting path is unchanged.
    /// This lets a link to the current folder reveal the sidebar again.
    ///
    /// In compact layouts, writing this path clears ``detail``. In expanded
    /// layouts, it preserves detail and requests that both columns be visible.
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
    /// The complete detail path, including its root destination.
    ///
    /// The first element supplies the detail root. Remaining elements are pushed
    /// above it. For example, `[firstNote, relatedNote]` displays `relatedNote`
    /// above a root displaying `firstNote`. An empty array selects no detail and
    /// makes the placeholder available in expanded layouts.
    ///
    /// Changing an empty path to a nonempty path requests the detail column in
    /// compact layouts without hiding the sidebar in expanded layouts. Changing
    /// a nonempty path to an empty path requests sidebar presentation. Changes
    /// between two nonempty paths do not change the column presentation settings.
    ///
    /// The nested navigation stack writes its pushes and pops back to this array.
    /// In compact layouts, returning from the detail root to the sidebar clears
    /// the entire path. To focus on detail in an expanded layout, call
    /// ``hideSidebar()`` explicitly.
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

    /// Creates a router with empty paths and an initial preference for the sidebar.
    ///
    /// The attached ``/NavigationSplitStack/NavigationSplitStack`` supplies the layout size class.
    public nonisolated init() {}

    /// Shows the sidebar without changing its navigation path.
    ///
    /// Requests both columns in expanded layouts and the sidebar column in
    /// compact layouts. Clears ``detail`` in compact layouts and preserves it
    /// otherwise. The existing ``sidebar`` path remains intact, so this method
    /// returns to the current sidebar destination rather than popping to its root.
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
    ///
    /// Requests detail-only presentation in expanded layouts, including when
    /// ``detail`` is empty and the placeholder is displayed. In compact layouts,
    /// requests the detail column only when a detail destination exists; otherwise
    /// this method does nothing.
    ///
    /// When detail is empty, the preferred compact column remains unchanged so
    /// hiding the sidebar does not request an empty detail column on collapse.
    public func hideSidebar() {
        guard horizontalSizeClass != .compact || !detail.isEmpty else { return }
        columnVisibility = .detailOnly
        if !detail.isEmpty, preferredCompactColumn != .detail {
            preferredCompactColumn = .detail
        }
    }
}
