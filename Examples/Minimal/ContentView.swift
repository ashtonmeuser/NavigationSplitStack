//
//  ContentView.swift
//  Minimal
//
//  Created by Ashton Meuser on 2026-10-29.
//

import NavigationSplitStack
import SwiftUI

typealias Router = NavigationSplitStackRouter<Int, Int>

extension Router {
    var fullPath: String {
        "\(sidebar.map { String($0) }.joined(separator: "→")) | \(detail.map { String($0) }.joined(separator: "→"))"
    }
}

struct ContentView: View {
    @State var router = NavigationSplitStackRouter<Int, Int>()

    var body: some View {
        NavigationSplitStack(router: router) { level in
            let title = "Sidebar \(level ?? 0)"
            let nextSidebar = router.sidebar.count + 1

            List {
                TitleChip(title: title, prefix: "sidebar")
                Section {
                    NavigationLink(
                        "Navigate to Sidebar \(nextSidebar)",
                        value: nextSidebar
                    )
                    Button("Push Sidebar \(nextSidebar)") {
                        router.sidebar.append(nextSidebar)
                    }
                    .accessibilityIdentifier("sidebarPushNextSidebar")
                    Button("Go to Detail 1") {
                        router.detail = [1]
                    }
                    .accessibilityIdentifier("sidebarGoToDetail")
                    if let detail = router.detail.last {
                        let nextDetail = detail + 1
                        Button("Push Detail \(nextDetail)") {
                            router.detail.append(nextDetail)
                        }
                        .accessibilityIdentifier("sidebarPushNextDetail")
                    }
                    if router.sidebar.count > 0 {
                        Button("Previous Sidebar") {
                            router.sidebar.removeLast()
                        }
                    }
                    if router.sidebar.count > 1 {
                        Button("Go to Root Sidebar") {
                            router.sidebar.removeAll()
                        }
                        .accessibilityIdentifier("sidebarGoToRootSidebar")
                    }
                    Button("Hide Sidebar via Router") {
                        router.hideSidebar()
                    }
                    .accessibilityIdentifier("sidebarHideSidebar")
                }
            }
        } detail: { level in
            let title = "Detail \(level)"
            let nextDetail = level + 1
            let replacementDetail = router.detail.first == 1 ? 2 : 1
            let nextSidebar = router.sidebar.count + 1

            List {
                TitleChip(title: title, prefix: "detail")
                Section {
                    NavigationLink(
                        "Navigate to Detail \(nextDetail)",
                        value: nextDetail
                    )
                    Button("Push Detail \(nextDetail)") {
                        router.detail.append(nextDetail)
                    }
                    .accessibilityIdentifier("detailPushNextDetail")
                    Button(
                        "Replace Detail Root with Detail \(replacementDetail)"
                    ) {
                        router.detail = [replacementDetail]
                    }
                    Button("Clear Detail") {
                        router.detail.removeAll()
                    }
                    Button("Show Sidebar via Router") {
                        router.showSidebar()
                    }
                    .accessibilityIdentifier("detailShowSidebar")
                    Button("Show Current Sidebar") {
                        router.sidebar = router.sidebar
                    }
                    Button("Go to Root Sidebar") {
                        router.sidebar.removeAll()
                    }
                    .accessibilityIdentifier("detailGoToRootSidebar")
                    Button("Push Sidebar \(nextSidebar)") {
                        router.sidebar.append(nextSidebar)
                    }
                    .accessibilityIdentifier("detailPushNextSidebar")
                    if router.detail.count > 1 {
                        Button("Previous Detail") {
                            router.detail.removeLast()
                        }
                    }
                    if router.detail.count > 2 {
                        Button("Root Detail") {
                            router.detail.removeLast(router.detail.count - 1)
                        }
                    }
                }
            }
        }
    }
}

struct TitleChip: View {
    // Note that router is available to NavigationSplitStack descendant views via @Environment
    @Environment(Router.self) private var router
    let title: String
    let prefix: String

    var body: some View {
        VStack(alignment: .center) {
            Text(title)
                .font(.headline)
                .accessibilityIdentifier("\(prefix)Title")
            Text(router.fullPath)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("\(prefix)FullPath")
        }
        .frame(maxWidth: .infinity)
        .navigationTitle(title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    ContentView()
}
