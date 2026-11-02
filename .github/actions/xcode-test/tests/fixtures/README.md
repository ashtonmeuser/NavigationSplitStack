# Simulator regression fixtures

`runtime-variants.json` contains selected fields from Apple's simulator catalog
and `xcrun simctl list --json`, inspected on November 1, 2026. Local paths and
device instances are omitted; runtime support lists are reduced to the included
device types. Tests construct their own device UUIDs and mock all commands.

The two iOS 27.2 builds reproduce a real distinction: `24B8117` supports general
iPhone/iPad models, while `24B91016s` supports iPhone Duo and has runtime identifier
`com.apple.CoreSimulator.SimRuntime.iOS-27-2-iPhone19-4`. Their catalog entries do
not declare which device models they support or provide Xcode/macOS bounds.
The watchOS 6.2.1 entry exercises `excludedHostArchitectures`, and the iOS 17.0
entry allows a regression check using an older selected SDK.

Catalog source: [Apple's simulator index](https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex).
