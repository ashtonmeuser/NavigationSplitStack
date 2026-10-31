# ``NavigationSplitStack``

Give the sidebar and detail columns of a SwiftUI split view their own navigation paths.

## Overview

Use `NavigationSplitStack` to support arbitrarily deep navigation within two columns of a `NavigationSplitView`.
A notes app, for example, might push through nested folders in its sidebar while
opening a note and following links to other notes in detail.

SwiftUI's `NavigationSplitView` adapts the columns to the available space, and
`NavigationStack` manages a path of pushed destinations. `NavigationSplitStack`
combines them: it gives each column a stack and coordinates which column is
shown in a compact layout.

Similar to `NavigationSplitView` (which this view wraps), the two columns are collapsed into a single stack
in narrow contexts i.e. iPhone.

A ``NavigationSplitStackRouter`` holds the two navigation paths and can be used to interact with the `NavigationSplitStack`.

```swift
import SwiftUI
import NavigationSplitStack

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

The router stores `Hashable` destination values, such as folder and note IDs.
The sidebar closure receives `nil` for its permanent root and a folder value
for a pushed destination. The detail closure receives a note value for every
detail destination. When no note is selected, the split view shows the
placeholder on wide screens.

### Route with paths

If you already use `NavigationStack(path:)`, the router follows the same model:
change an array of destination values to navigate. `NavigationLink(value:)`
also pushes a value onto the stack of the column containing the link.

```swift
router.sidebar.append("Archive")  // Push a folder in the sidebar.
router.sidebar.removeLast()       // Pop back one folder.
router.sidebar.removeAll()        // Return to the sidebar root.

router.detail = [1]               // Open note 1 as the detail root.
router.detail.append(2)           // Push note 2 above note 1.
router.detail.removeLast()        // Return to note 1.
router.detail.removeAll()         // Clear the detail selection.
```

There is one difference between the paths: `sidebar` contains only values
*above* its permanent root, so `[]` shows that root. `detail` includes its root
as the first value, so `[]` means no detail is selected. Assign a new array to
either path to replace that column's navigation history.

Setting `sidebar` reveals the sidebar, including when you assign its current
value. On a compact screen this also clears the detail path. Setting a
previously empty `detail` path presents detail on a compact screen; on a wide
screen both columns can remain visible.

### Show or hide the sidebar

Call ``/NavigationSplitStack/NavigationSplitStackRouter/showSidebar()`` to
return to the current sidebar destination without changing its path. Call
``/NavigationSplitStack/NavigationSplitStackRouter/hideSidebar()`` to focus on
detail in a wide layout.
On a compact screen, showing the sidebar clears the detail selection, just as
returning from the detail root does. Hiding the sidebar with no detail selected
can show the placeholder in a wide layout.

Keep one router per split view in persistent view state, such as `@State` in
the parent. Descendant views can access that router through SwiftUI's
environment when they need to navigate programmatically.

## Topics

### Guides

- <doc:Caveats>

### Creating a split navigation interface

- ``/NavigationSplitStack/NavigationSplitStack``

### Managing navigation state

- ``/NavigationSplitStack/NavigationSplitStackRouter``
- ``/NavigationSplitStack/NavigationSplitStackRouter/sidebar``
- ``/NavigationSplitStack/NavigationSplitStackRouter/detail``

### Controlling column presentation

- ``/NavigationSplitStack/NavigationSplitStackRouter/showSidebar()``
- ``/NavigationSplitStack/NavigationSplitStackRouter/hideSidebar()``
