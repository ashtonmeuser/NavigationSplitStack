//
//  NavigationSplitStack.swift
//  NavigationSplitStack
//
//  Created by Ashton Meuser on 2026-10-23.
//

import SwiftUI

/// A two-column navigation view with independent sidebar and detail stacks.
///
/// Supply a ``NavigationSplitStackRouter`` and view builders for each column.
/// The sidebar builder receives `nil` for its root and a value for each pushed
/// destination. The detail builder receives the first value in the router's
/// detail path for its root and each subsequent value for a pushed destination.
/// An empty detail path displays a placeholder instead of a detail stack.
///
/// In compact layouts, selecting the first detail destination presents the detail
/// column. Returning from its root to the sidebar clears the detail path. In
/// expanded layouts, both stacks can remain visible and keep independent paths.
///
/// Keep the router in persistent storage, such as a parent view's `@State`, and
/// use one router per split-view instance. This view exposes the supplied router
/// to its descendants through SwiftUI's environment; descendants can retrieve it
/// with `@Environment(NavigationSplitStackRouter<Sidebar, Detail>.self)`.
///
/// The `Sidebar` and `Detail` types describe destinations in their respective
/// paths. The `SidebarView` and `DetailView` types are inferred from the builders.
public struct NavigationSplitStack<
    Sidebar: Hashable,
    Detail: Hashable,
    SidebarView: View,
    DetailView: View
>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let sidebarView: (Sidebar?) -> SidebarView
    private let detailView: (Detail) -> DetailView
    private let emptyText: LocalizedStringKey?
    @Bindable private var router: NavigationSplitStackRouter<Sidebar, Detail>

    /// Creates a split view driven by the supplied router.
    ///
    /// The caller manages the router's lifetime. Supplying a different router
    /// switches this view to that instance's navigation state.
    ///
    /// - Parameters:
    ///   - router: The shared navigation state for this split view.
    ///   - emptyText: The localized placeholder text for an empty detail path.
    ///     Passing `nil` uses "Make a selection".
    ///   - sidebar: Builds the sidebar root when its argument is `nil`, or a
    ///     pushed sidebar destination when its argument contains a value.
    ///   - detail: Builds a detail destination. The first path element supplies
    ///     the root; subsequent elements are pushed above it.
    public init(
        router: NavigationSplitStackRouter<Sidebar, Detail>,
        emptyText: LocalizedStringKey? = nil,
        @ViewBuilder sidebar: @escaping (Sidebar?) -> SidebarView,
        @ViewBuilder detail: @escaping (Detail) -> DetailView
    ) {
        self.router = router
        sidebarView = sidebar
        detailView = detail
        self.emptyText = emptyText
    }

    /// The split view, its navigation stacks, and the shared router environment.
    public var body: some View {
        NavigationSplitView(
            columnVisibility: $router.columnVisibility,
            preferredCompactColumn: $router.preferredCompactColumn
        ) {
            // HACK: This thin binding wrapper fixes a bug where navigtion home (empty sidebar, empty detail)
            // from a detail view fails.
            NavigationStack(
                path: Binding(
                    get: { router.sidebar },
                    set: { router.sidebar = $0 }
                )
            ) {
                sidebarView(nil)
                    .navigationDestination(for: Sidebar.self) { sidebar in
                        sidebarView(sidebar)
                            .id(sidebar)
                            #if os(macOS)
                                .toolbar {
                                    ToolbarItem(placement: .automatic) {
                                        Button(
                                            "Back",
                                            systemImage: "chevron.left"
                                        ) {
                                            router.sidebar.removeLast()
                                        }
                                    }
                                }
                            #endif
                    }
            }
            #if os(macOS)
                .navigationSplitViewColumnWidth(min: 260, ideal: 260)
                .navigationBarBackButtonHidden()
            #endif
        } detail: {
            Group {
                // This conditional must be applied outside of the navigation stack.
                // Otherwise, the navigation pop animation responds to the nil selection i.e. detail view is set to content unavailable during pop animation.
                if let detail = router.detail.first {
                    NavigationStack(path: $router.detailRest) {
                        detailView(detail)
                            .id(detail)
                            .navigationDestination(for: Detail.self) { detail in
                                detailView(detail)
                                    .id(detail)
                            }
                    }
                } else {
                    // Only visible on wide platforms e.g. iPad.
                    ContentUnavailableView {
                        Text(emptyText ?? "Make a selection")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .environment(router)  // Insert router into environment
        .onChange(of: horizontalSizeClass, initial: true) {
            router.horizontalSizeClass = horizontalSizeClass
        }
        .onChange(of: ObjectIdentifier(router)) {
            router.horizontalSizeClass = horizontalSizeClass
        }
    }
}
