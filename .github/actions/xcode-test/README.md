# Xcode tests

A standalone composite action with six inputs. Device and scheme are required;
OS version and project are optional. OS version is ignored for macOS.
Local ad-hoc signing is enabled by default and can be disabled.
Test parallelization follows the scheme by default and can be disabled.
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
| `os` | No | Numeric, literal version prefix. Omit or leave empty for any version. Quote this YAML value. Ignored for macOS. |
| `scheme` | Yes | Shared scheme containing the tests to run. |
| `project` | No | `.xcodeproj` path relative to the working directory. |
| `ad-hoc-signing` | No | `true` (default) adds local ad-hoc signing overrides; `false` preserves project signing settings. |
| `disableParallelization` | No | `false` (default) uses the scheme setting; `true` passes `-parallel-testing-enabled NO`. |

`iPhone` matches `iPhone 17` and `iPhone 18 Pro Max`. `iPad Pro` matches
`iPad Pro 13-inch (M5)`; use `iPad` to also match `iPad Air 11-inch (M4)`.
Identifier matching is exact, for example
`com.apple.CoreSimulator.SimDeviceType.iPhone-17`. Partial identifiers do not
match. `27` matches `27.0` and `27.2`; literal prefix semantics also mean `27.1`
matches `27.10`.

For simulators, the newest compatible installed runtime wins. With `os: '27'`,
`27.2` is selected over `27.0.1`; with `os` omitted or empty, there is no version
restriction. If the newest matching installed runtime has no matching device,
the action creates one instead of reusing a device on an older runtime. It
consults the download catalog only when no usable installed runtime matches,
then selects the newest compatible downloadable match.

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

1. Query `xcrun simctl list --json`. Find the highest numeric installed OS
   version where a matching device is available or can be created. Restrict
   versions to the `os` prefix when supplied; otherwise consider all versions.
2. Reuse a matching available device at that version, or create one with a
   supported device type. Prefer reuse at the same version. Runtime identifier,
   device name, and UDID provide deterministic tie-breaking. No download is needed.
3. If no suitable installed runtime exists, resolve the version prefix against
   [Apple's simulator catalog](https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex).
   Filter by device platform, device version range, host architecture, and the
   catalog's Xcode/macOS requirements. Choose the highest version; prefer final
   releases over prereleases at that version, then the last catalog entry.
   Download and install that build using `xcodebuild -downloadPlatform
   <platform> -buildVersion <build> -architectureVariant <variant>`.
4. Query again and reuse or create a device. Run `xcrun simctl bootstatus
   <udid> -b` to boot it if needed and wait for startup to complete.
5. Run `xcodebuild test -scheme <scheme> -destination id=<udid>`, adding
   `-project` only when provided and disabling parallel testing only when
   `disableParallelization` is true.

A UUID pins the existing device and its OS version, even when `os` is omitted.
An unknown UUID or a mismatch with a supplied OS prefix fails.
If its runtime was removed, the action attempts to reinstall
that version and reuse the same UUID; it never creates a replacement UUID.

The platform is inferred from Xcode's device type metadata: iOS, tvOS, watchOS,
or visionOS. This action does not configure watch/phone pairing.
The action boots the selected simulator before testing; macOS destinations skip
this step. Existing devices and newly
installed runtimes/devices remain on the runner after the action.

Apple's catalog is an external dependency with no guaranteed public schema.
It is fetched only when a download is necessary. Xcode remains the final
authority on downloadable builds and compatibility; unavailable downloads,
unsupported device/runtime combinations, and test failures fail the action.
Installing a runtime cannot add a device type absent from the selected Xcode.

The installation command follows Apple's
[Xcode component documentation](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components).
Inputs are passed through environment variables and subprocess argument arrays,
so spaces and shell metacharacters remain literal.

## Simulator startup and parallel testing

The action waits for the selected simulator to finish booting before starting
`xcodebuild`. This also works when the simulator is already running. Boot output
is streamed to the job log, and a boot failure stops the action before testing.
No Simulator GUI or fixed sleep is needed.

`disableParallelization: 'true'` explicitly disables test parallelization,
including when it is enabled in the scheme. This matches the repository's
existing CI and avoids additional parallel test workers on a constrained runner.
The default, `'false'`, leaves the scheme setting in effect. When parallel
testing is enabled, Xcode may create simulator clones; the action only preboots
the selected device, not those later clones.

Prebooting removes simulator startup from the test-launch path, but does not
guarantee that application launches cannot time out. Tests still install and
launch the app normally.

## Signing and test results

By default, `ad-hoc-signing: 'true'` adds these build settings to the test command:

```text
CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM=
```

This selects local ad-hoc signing for simulator and macOS tests. It is not
Ad Hoc distribution to physical iOS devices. If your project requires a
particular signing identity, team, or provisioning setup, set
`ad-hoc-signing: 'false'` and configure signing in the project/runner. The action
accepts `true` or `false` strings; the manual workflow presents a checkbox.

Every test invocation passes a unique `-resultBundlePath` under `RUNNER_TEMP`
(or the system temporary directory when run locally). There is no input for
the path. The `result-bundle-path` output contains its absolute `.xcresult` path.
It is published before the test command, so it remains available when that
command fails. Failures during validation or simulator setup do not publish a
path; Xcode can also fail before it creates a bundle at the published path.

The caller controls uploading. The manual workflow uploads the bundle on
failure, skips missing bundles, and preserves hidden files inside the bundle.
Other workflows can use the same pattern:

```yaml
- uses: ./.github/actions/xcode-test
  id: tests
  with:
    device: iPhone
    scheme: Minimal
    project: Examples/Examples.xcodeproj
    ad-hoc-signing: 'true'
- uses: actions/upload-artifact@v7
  if: ${{ failure() && steps.tests.outputs.result-bundle-path != '' }}
  with:
    name: test-results
    path: ${{ steps.tests.outputs.result-bundle-path }}
    if-no-files-found: ignore
    include-hidden-files: true
```

Use distinct artifact names for multiple action invocations or matrix jobs.
Bundles remain on disk after the action; uploading is not part of the composite.

## Validation

### Manual GitHub run

This repository includes a [manual test workflow](../../workflows/test-xcode-action.yml)
with fields for all six action inputs. It uses the `xcode-27` runner and its
default Xcode selection.

GitHub requires the wrapper workflow to exist on the default branch to expose
the **Run workflow** button. Put the wrapper on the default branch and the branch
being tested; the action implementation can remain on the test branch.

1. Push the test branch with the action and wrapper workflow.
2. Open **Actions → Test Xcode action → Run workflow**.
3. Select the test branch in **Use workflow from**.
4. Enter `device`, optionally `os`, and the scheme/project. Defaults use
   `iPhone`, the newest compatible installed OS, `Minimal`, and
   `Examples/Examples.xcodeproj`. Clear `project` to test project auto-discovery.
   Leave `ad-hoc-signing` checked for local ad-hoc signing, or uncheck it to use
   the project's signing settings.
   Check `disableParallelization` to run tests serially, or leave it unchecked
   to use the scheme's setting.
5. Select **Run workflow** and inspect the **Run local Xcode action** step.

Checkout uses the selected branch, so the local action runs that branch's code.
For example, try `device: iPhone` with `os: '27'`, leave `os` empty to test
automatic selection, or use `device: macOS` to test the host destination.

See [GitHub's manual workflow documentation](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow).

### Local checks

```sh
python3 -m unittest discover -s .github/actions/xcode-test/tests -v
```

Tests cover selection, unavailable runtimes, exact identifiers, provisioning,
catalog filtering, signing overrides, parallelization, simulator boot ordering,
result outputs, and command failures without downloading
runtimes or changing the simulator inventory.
