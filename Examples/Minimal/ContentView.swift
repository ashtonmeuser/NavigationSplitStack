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
            VStack {
                let nextSidebar = router.sidebar.count + 1

                VStack {
                    Text("Sidebar \(level ?? 0)")
                        .font(.headline)
                        .accessibilityIdentifier("sidebarTitle")
                    Text(router.fullPath)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("sidebarFullPath")
                }
                .padding(.bottom)
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
        } detail: { level in
            VStack {
                let nextDetail = level + 1
                let replacementDetail = router.detail.first == 1 ? 2 : 1
                let nextSidebar = router.sidebar.count + 1

                VStack {
                    Text("Detail \(level)")
                        .font(.headline)
                        .accessibilityIdentifier("detailTitle")
                    Text(router.fullPath)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("detailFullPath")
                }
                .padding(.bottom)
                NavigationLink(
                    "Navigate to Detail \(nextDetail)",
                    value: nextDetail
                )
                Button("Push Detail \(nextDetail)") {
                    router.detail.append(nextDetail)
                }
                .accessibilityIdentifier("detailPushNextDetail")
                Button("Replace Detail Root with Detail \(replacementDetail)") {
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

#Preview {
    ContentView()
}
