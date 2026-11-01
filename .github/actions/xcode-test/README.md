# Xcode tests

A standalone composite action with four inputs. Device and scheme are required;
OS version is required for simulators and ignored for macOS. Project is optional.
Copy this directory into another repository, or put its contents at the root of
a dedicated action repository. It needs macOS, a selected and initialized Xcode,
Python 3, and curl. It uses only Python's standard library.

```yaml
steps:
  - uses: actions/checkout@v7
  - uses: ./.github/actions/xcode-test
    with:
      device: iPhone
      os: '27'
      scheme: Minimal
      project: Examples/Examples.xcodeproj
```

In a dedicated action repository, callers can use `owner/repository@ref` instead.
Select the desired Xcode before invoking the action, using `DEVELOPER_DIR` or
`xcode-select`. Run from the directory containing the project or Swift package;
omitting `project` leaves project/workspace discovery to `xcodebuild`.

| Input | Required | Meaning |
| --- | --- | --- |
| `device` | Yes | Case-sensitive simulator name prefix, exact `udid`/`deviceTypeIdentifier`, or case-insensitive `mac`/`macos`. |
| `os` | Simulators only | Numeric, literal version prefix. Quote this YAML value. Ignored for macOS. |
| `scheme` | Yes | Shared scheme containing the tests to run. |
| `project` | No | `.xcodeproj` path relative to the working directory. |

`iPhone` matches `iPhone 17` and `iPhone 18 Pro Max`. `iPad Pro` matches
`iPad Pro 13-inch (M5)`; use `iPad` to also match `iPad Air 11-inch (M4)`.
Identifier matching is exact, for example
`com.apple.CoreSimulator.SimDeviceType.iPhone-17`. Partial identifiers do not
match. `27` matches `27.0` and `27.2`; literal prefix semantics also mean `27.1`
matches `27.10`.

Use `device: mac` or `device: macos` (any capitalization) to run on the runner's
current OS with `-destination platform=macOS`. The action skips all simulator
discovery and downloads, and ignores `os` entirely, including an omitted or
nonnumeric value. Only these exact aliases select macOS; names such as
`MacBook Pro` or `macos-simulator` do not.

```yaml
- uses: ./.github/actions/xcode-test
  with:
    device: macOS
    scheme: Minimal
    project: Examples/Examples.xcodeproj
```

## Selection and installation

For simulator destinations:

1. Query `xcrun simctl list --json`. Reuse an available device whose name or
   identifier matches and whose available runtime version starts with `os`.
   Prefer the highest numeric OS version, then sort by runtime identifier,
   device name, and UDID for reproducible selection.
2. If there is no matching device, create one from a matching installed runtime
   and a supported device type. This does not download anything.
3. If no suitable installed runtime exists, resolve the version prefix against
   [Apple's simulator catalog](https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex).
   Filter by device platform, device version range, host architecture, and the
   catalog's Xcode/macOS requirements. Choose the highest version; prefer final
   releases over prereleases at that version, then the last catalog entry.
   Download and install that build using `xcodebuild -downloadPlatform
   <platform> -buildVersion <build> -architectureVariant <variant>`.
4. Query again, reuse or create a device, and run `xcodebuild test -scheme
   <scheme> -destination id=<udid>`, adding `-project` only when provided.

A UUID pins the existing device and its OS version. An unknown UUID or an OS
mismatch fails. If its runtime was removed, the action attempts to reinstall
that version and reuse the same UUID; it never creates a replacement UUID.

The platform is inferred from Xcode's device type metadata: iOS, tvOS, watchOS,
or visionOS. This action does not configure watch/phone pairing.
Xcode handles booting the test destination. Existing devices and newly
installed runtimes/devices remain on the runner after the action.

Apple's catalog is an external dependency with no guaranteed public schema.
It is fetched only when a download is necessary. Xcode remains the final
authority on downloadable builds and compatibility; unavailable downloads,
unsupported device/runtime combinations, and test failures fail the action.
Installing a runtime cannot add a device type absent from the selected Xcode.
The action does not change signing or other project build settings.

The installation command follows Apple's
[Xcode component documentation](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components).
Inputs are passed through environment variables and subprocess argument arrays,
so spaces and shell metacharacters remain literal.

## Validation

```sh
python3 -m unittest discover -s .github/actions/xcode-test/tests -v
```

Tests cover selection, unavailable runtimes, exact identifiers, provisioning,
catalog filtering, argument handling, and command failures without downloading
runtimes or changing the simulator inventory.
