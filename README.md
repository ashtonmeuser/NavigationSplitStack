# NavigationSplitStack

`NavigationSplitStack` is a SwiftUI view with independent, arbitrarily deep navigation stacks in the sidebar and detail columns of a `NavigationSplitView`. It coordinates the columns when they collapse on a compact screen, while letting you route with paths much like `NavigationStack`.

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
