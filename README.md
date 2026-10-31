# NavigationSplitStack

[![](https://img.shields.io/badge/documentation-gray?logo=swift&logoColor=white)](https://swiftpackageindex.com/ashtonmeuser/NavigationSplitStack/main/documentation/NavigationSplitStack)
[![CI](https://github.com/ashtonmeuser/NavigationSplitStack/actions/workflows/tests.yml/badge.svg)](https://github.com/ashtonmeuser/NavigationSplitStack/actions/workflows/tests.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fashtonmeuser%2FNavigationSplitStack%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ashtonmeuser/NavigationSplitStack)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fashtonmeuser%2FNavigationSplitStack%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ashtonmeuser/NavigationSplitStack)

Independent navigation stacks in the columns of a SwiftUI split view.

## Overview

`NavigationSplitStack` is a SwiftUI view with independent, arbitrarily deep navigation stacks in the sidebar and detail columns of a `NavigationSplitView`. It coordinates the columns when they collapse on a compact screen, while letting you route with paths much like `NavigationStack`. The independent navigation paths are managed via a router.

## Requirements

- iOS 26 or macOS 26
- Swift 6.4

## Installation

Add `https://github.com/ashtonmeuser/NavigationSplitStack` as a package dependency in Xcode, then add the `NavigationSplitStack` product to your app target.

## Usage

Keep a router in your view's state and provide views for sidebar and detail destinations:

```swift
import NavigationSplitStack
import SwiftUI

struct NotesView: View {
    @State private var router = NavigationSplitStackRouter<String, Int>()

    var body: some View {
        NavigationSplitStack(router: router, emptyText: "Select a note") { folder in
            VStack {
                Text(folder ?? "Folders")
                NavigationLink("Archive", value: "Archive")
                Button("Open note 1") {
                    router.detail = [1]
                }
            }
        } detail: { note in
            VStack {
                Text("Note \(note)")
                NavigationLink("Next note", value: note + 1)
            }
        }
    }
}
```

The sidebar has a permanent root, passed to the sidebar closure as `nil`. `router.sidebar` contains destinations pushed above that root. The first value in `router.detail` is the detail root; later values are pushed above it. An empty detail path shows the placeholder on wide screens.

Change either path to navigate programmatically:

```swift
router.sidebar.append("Archive") // Push a sidebar destination.
router.detail = [1]              // Select the detail root.
router.detail.append(2)          // Push another detail destination.
router.detail.removeAll()        // Clear the detail selection.
router.showSidebar()             // Reveal the current sidebar destination.
router.hideSidebar()             // Focus on detail in a wide layout.
```

See the [DocC guide](Sources/NavigationSplitStack/NavigationSplitStack.docc/NavigationSplitStack.md) for more on routing and column presentation.
Explore the [example apps](Examples/) for working implementations.

## Caveats

- `NavigationLink` pushes only within the column containing it: a sidebar link pushes a sidebar destination, and a detail link pushes a detail destination. Change the router path to navigate between columns.
- Use a value-based `NavigationLink`, such as `NavigationLink("Archive", value: "Archive")`, with the destination type for that column. A link that constructs its destination view directly does not update the router path.
- The first detail destination must be set with `router.detail = [destination]`. The detail `NavigationStack` is absent while `router.detail` is empty, so a sidebar link cannot open the detail root.
- On macOS, a sidebar `NavigationLink` inside a `List` can remain active after navigating back, preventing the same row from opening again. See [issue #1](https://github.com/ashtonmeuser/NavigationSplitStack/issues/1). Use a `Button` that updates `router.sidebar` for affected rows.
