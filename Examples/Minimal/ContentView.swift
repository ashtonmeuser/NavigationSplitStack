//
//  ContentView.swift
//  Minimal
//
//  Created by Ashton Meuser on 2026-10-29.
//

import SwiftUI
import NavigationSplitStack

typealias Router = NavigationSplitStackRouter<Int, Int>

struct ContentView: View {
    @State var router = NavigationSplitStackRouter<Int, Int>()

    var body: some View {
        NavigationSplitStack(router: router) { level in
            VStack {
                let nextSidebar = router.sidebar.count + 1

                Text("Sidebar \(level ?? 0)")
                    .font(.headline)
                NavigationLink("Go to Sidebar \(nextSidebar)", value: nextSidebar)
                Button("Go to Detail 1") {
                    router.detail = [1]
                }
                if router.sidebar.count > 0 {
                    Button("Previous Sidebar") {
                        router.sidebar.removeLast()
                    }
                }
                if router.sidebar.count > 1 {
                    Button("Root Sidebar") {
                        router.sidebar.removeAll()
                    }
                }
                Button("Hide Sidebar") {
                    router.hideSidebar()
                }
            }
        } detail: { level in
            VStack {
                let nextDetail = level + 1
                let nextSidebar = router.sidebar.count + 1

                Text("Detail \(level)")
                    .font(.headline)
                NavigationLink("Go to Detail \(nextDetail)", value: nextDetail)
                Button("Show Sidebar") {
                    router.showSidebar()
                }
                Button("Go to Root Sidebar") {
                    router.sidebar.removeAll()
                }
                Button("Go to Sidebar \(nextSidebar)") {
                    router.sidebar.append(nextSidebar)
                }
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
