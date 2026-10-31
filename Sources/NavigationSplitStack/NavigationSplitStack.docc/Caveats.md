# Caveats

Understand how links interact with the two navigation paths and a known macOS issue.

## NavigationLink stays in its column

Each column has its own `NavigationStack`. A `NavigationLink` in the sidebar can
push a `Sidebar` value onto the sidebar path; a link in detail can push a
`Detail` value onto the detail path. A link cannot push into the other column.
To navigate between columns, update the appropriate path on
``NavigationSplitStackRouter``.

Use a value-based initializer, such as
`NavigationLink("Archive", value: "Archive")` or
`NavigationLink(value: destination) { label }`, and pass a value of the
destination type for that column. A `NavigationLink` that creates a destination
view directly does not update the router path.

The first detail destination is a special case. When the detail path is empty,
there is no detail `NavigationStack` to receive a link. Set the detail root with
`router.detail = [destination]`. Once it exists, value-based links in detail can
push further destinations.

## NavigationLink in a macOS sidebar List

On macOS, a `NavigationLink` inside a sidebar `List` can remain active after
popping back. Clicking that same row again then fails to reopen its destination.
This is tracked in [issue #1](https://github.com/ashtonmeuser/NavigationSplitStack/issues/1).
For affected rows, use a `Button` to update the sidebar path instead:

```swift
Button("Open Archive") {
    router.sidebar.append("Archive")
}
```
