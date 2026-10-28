//
//  NavigationSplitStack.swift
//  NavigationSplitStack
//
//  Created by Ashton Meuser on 2026-10-23.
//

import SwiftUI

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

    public var body: some View {
        NavigationSplitView(
            columnVisibility: $router.columnVisibility,
            preferredCompactColumn: $router.preferredCompactColumn
        ) {
            NavigationStack(path: $router.sidebar) {
                sidebarView(nil)
                    .navigationDestination(for: Sidebar.self) {
                        sidebarView($0)
                    }
            }
            #if os(macOS)
                .navigationSplitViewColumnWidth(min: 260, ideal: 260)
                .navigationBarBackButtonHidden()
            #endif
        } detail: {
            Group {
                // This conditional must be applied outside of the navigation stack
                // Otherwise, the navigation pop animation responds to the nil selection i.e. detail view is set to content unavailable during pop animation
                if let detail = router.detail.first {
                    NavigationStack(path: $router.detailRest) {
                        detailView(detail)
                            .navigationDestination(for: Detail.self) {
                                detailView($0)
                            }
                    }
                } else {
                    // Only visible on wide platforms e.g. iPad
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
