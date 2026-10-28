//
//  ContentView.swift
//  Example
//
//  Created by Ashton Meuser on 2026-10-23.
//

import SwiftUI
import NavigationSplitStack

typealias Router = NavigationSplitStackRouter<Taxon, Species>

struct ContentView: View {
    @State var router = Router()
//    @State var sel: Taxon?

    var body: some View {
        NavigationSplitStack(router) { taxon in
            Group {
                if let species = taxon?.species, !species.isEmpty {
//                    List(selection: $router.detail) {
//                    List {
//                        ForEach(species) { species in
//                            NavigationLink(species.id, value: species)
//                            Button(species.id) {
                            Button("test") {
//                                router.detail = [species]
                                router.preferredCompactColumn = .detail
                            }
//                        }
//                    }
                } else {
//                    List(selection: $sel) {
                    List {
                        ForEach(taxon?.children ?? Taxon.roots) { taxon in
                            NavigationLink(taxon.id, value: taxon)
                        }
                    }
                }
            }
            .navigationTitle(taxon?.id ?? "Taxons")
        } detail: { species in
            Text("hello")
//            DetailView(species: species)
        }
        .environment(router)
        .listStyle(.insetGrouped)
    }
}

struct DetailView: View {
    var species: Species
    @Environment(Router.self) var router

    var body: some View {
        let markdown = Taxon.roots.last!.path(to: species.id)?
            .map { "**\($0.id)**" }
            .joined(separator: " → ")
        let path = try! AttributedString(markdown: markdown ?? "**unknown**")

        return VStack {
            if let emoji = species.emoji {
                Text(emoji)
                    .font(.default.scaled(by: 8))
            }
            Text(species.id)
                .font(.title.bold())
            Text("The taxonomy of the **\(species.id)** is \(path).")
                .padding(.top)
        }
    }
}

struct ToolbarView: ToolbarContent {
    @Environment(Router.self) var router

    var body: some ToolbarContent {
        ToolbarItem {
            Menu {
                Button("Print router") {
                    print("Sidebar: \(router.sidebar, default: "None")\nDetail: \(router.detail, default: "None")")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}




struct SplitStacksDemo: View {
    enum SidebarRoute: Hashable {
        case level(Int)
    }

    enum DetailRoute: Hashable {
        case level(Int)
    }

    @State private var sidebarPath: [SidebarRoute] = []
    @State private var detailPath: [DetailRoute] = []

    @State private var compactColumn:
        NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(
            preferredCompactColumn: $compactColumn
        ) {
            NavigationStack(path: $sidebarPath) {
                List {
                    NavigationLink(
                        "Navigate within sidebar",
                        value: SidebarRoute.level(1)
                    )

                    Button("Open detail") {
                        detailPath = [.level(1)]
                        compactColumn = .detail
                    }
                }
                .navigationTitle("Sidebar")
                .navigationDestination(for: SidebarRoute.self) { route in
                    switch route {
                    case .level(let depth):
                        List {
                            NavigationLink(
                                "Next sidebar level",
                                value: SidebarRoute.level(depth + 1)
                            )
                        }
                        .navigationTitle("Sidebar \(depth)")
                    }
                }
            }
        } detail: {
            NavigationStack(path: $detailPath) {
                List {
                    NavigationLink(
                        "Navigate within detail",
                        value: DetailRoute.level(1)
                    )
                }
                .navigationTitle("Detail")
                .navigationDestination(for: DetailRoute.self) { route in
                    switch route {
                    case .level(let depth):
                        List {
                            NavigationLink(
                                "Next detail level",
                                value: DetailRoute.level(depth + 1)
                            )
                        }
                        .navigationTitle("Detail \(depth)")
                    }
                }
            }
        }
    }
}




struct ContentView2: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var router = NavigationSplitStackRouter<Int8, Int16>()

    var body: some View {
        NavigationSplitStack(router) { level in
            VStack {
                Text("Sidebar \(level ?? 0)")
                NavigationLink("Go to level \((level ?? 0) + 1)", value: (level ?? 0) + 1)
                Button("Show detail") {
                    router.preferredCompactColumn = .detail
                }
            }
        } detail: { level in
            VStack {
                Text("Detail \(level)")
                NavigationLink("Go to level \(level + 1)", value: level + 1)
                Button("Show sidebar") {
                    if horizontalSizeClass == .compact {
                        router.detail = []
                    }
                    router.preferredCompactColumn = .sidebar
                }
            }
        }
    }
}


struct ContentView3: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar
    @State private var sidebarPath: [Int8] = []
    @State private var detailPath: [Int16] = []

    var body: some View {
        NavigationSplitView(
            preferredCompactColumn: $compactColumn
        ) {
            NavigationStack(path: $sidebarPath) {
                VStack {
                    Text("Sidebar 0")
                    NavigationLink("Go to level 1", value: Int8(1))
                    Button("Show detail") {
                        compactColumn = .detail
                    }
                }
                .navigationDestination(for: Int8.self) { level in
                    VStack {
                        Text("Sidebar \(level)")
                        NavigationLink("Go to level \(level + 1)", value: level + 1)
                        Button("Show detail") {
                            compactColumn = .detail
                        }
                    }
                }
            }
        } detail: {
            NavigationStack(path: $detailPath) {
                VStack {
                    Text("Detail 0")
                    NavigationLink("Go to level 1", value: Int16(1))
                    Button("Show sidebar") {
                        if horizontalSizeClass == .compact {
                            detailPath.removeAll()
                        }
                        compactColumn = .sidebar
                    }
                }
                .navigationDestination(for: Int16.self) { level in
                    Text("Detail 1")
                    NavigationLink("Go to level \(level + 1)", value: level + 1)
                    Button("Show sidebar") {
                        if horizontalSizeClass == .compact {
                            detailPath.removeAll()
                        }
                        compactColumn = .sidebar
                    }
                }
            }
        }
    }
}
