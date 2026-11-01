# Destination selection and testing

These charts describe [run.py](run.py) and [simulators.py](simulators.py).
The optional Swift package cache steps in [action.yml](action.yml) run before
`run.py` and do not change simulator selection. Any failed external command
stops the action; these error edges are omitted from the charts for readability.

| Term | Meaning in this action |
| --- | --- |
| Runtime | A simulator OS installation, such as iOS 27.2. It is usable when `simctl` reports `isAvailable: true`. |
| Device type | A hardware model known to the selected Xcode, such as iPhone 17. Types can exist without installed runtimes or created devices. |
| Device | A created simulator instance with a UDID, associated with one runtime. It must also report `isAvailable: true` to be reused. |

## Overall flow

`installed_choice` returns an existing device, a type that can be created on a
specific runtime, or no match. The same selection procedure runs before and
after a download. A UUID query can only return its existing device or no match;
it never produces a replacement device.

```mermaid
flowchart TD
    A["Validate runner and inputs"] --> B{"device is exactly mac or macos<br/>ignoring case?"}
    B -- Yes --> M["Use destination platform=macOS<br/>Ignore OS input"]
    B -- No --> I["Query simctl inventory"]
    I --> S[["Run installed_choice<br/>See runtime selection below"]]
    S --> R{"Selection result?"}
    R -- Device --> U["Reuse selected device"]
    R -- Type --> C["Create selected type on selected runtime<br/>Validate returned UDID"]
    R -- None --> DL[["Resolve and install a runtime<br/>See download flow below"]]
    DL --> RI["Query simctl inventory again"]
    RI --> S2[["Run the same installed_choice"]]
    S2 --> R2{"Selection result?"}
    R2 -- Device --> U
    R2 -- Type --> C
    R2 -- None --> E["Fail: no usable simulator after installation"]
    U --> DEST["Use destination id=UDID"]
    C --> DEST
    DEST --> BOOT["Boot device and wait for startup<br/>simctl bootstatus UDID -b"]
    BOOT --> OUTPUT["Reserve unique result bundle path<br/>Publish result-bundle-path output"]
    M --> OUTPUT
    OUTPUT --> TEST["Run xcodebuild test<br/>Apply project, signing, and parallelization inputs"]
```

Input validation rejects an unsupported host, empty device or scheme, invalid
simulator OS prefix, invalid project path, and invalid signing/parallelization
toggles. A failed device creation, invalid returned UDID, or boot failure stops
before the result bundle path is published. The path is published before
testing, but Xcode may fail before creating the bundle.

## Installed runtime selection

The loop examines only installed, available runtimes matching the literal OS
prefix. An empty prefix permits all versions. Numeric ordering puts 27.10 above
27.2. When there are no eligible runtimes, the loop immediately returns no match.

```mermaid
flowchart TD
    A["Filter installed runtimes by availability and OS prefix<br/>Sort by numeric version, newest first"] --> B{"Any unexamined runtimes left?"}
    B -- No --> NONE["Return no match"]
    B -- Yes --> NEXT["Take the next runtime"]
    NEXT --> D{"Available matching device<br/>on this runtime?"}
    D -- Yes --> DEVICE["Return device and runtime"]
    D -- No --> UUID{"Query is a full UUID?"}
    UUID -- Yes --> B
    UUID -- No --> TYPE{"Matching Xcode device type supported<br/>by this runtime and its version?"}
    TYPE -- Yes --> CREATE["Return type and runtime for creation"]
    TYPE -- No --> B
```

An existing device wins over creation on the same runtime. A creatable type on
a newer runtime wins over an existing device on an older runtime. This rule also
applies after downloading; the action does not search all runtimes for existing
devices first.

Device names match by case-insensitive prefix; full UDIDs and device type
identifiers match exactly. Candidate types include types whose names or
identifiers match, plus the types of matching renamed or unavailable devices.
Devices are ordered by name then UDID, and types by name then identifier.
Runtime identifiers break ties between equal numeric versions, in descending
order. Creation requires both membership in the runtime's `supportedDeviceTypes`
and an OS version within the type's minimum/maximum range.

## Download flow

This path runs only when installed runtime selection returns no match. The
catalog supplies OS runtimes; device types must already be known to the selected
Xcode. Fetching the catalog and reading the Xcode version happen before the
platform ambiguity check in the current implementation.

```mermaid
flowchart TD
    A{"Query is a full UUID?"} -- No --> TYPES["Find candidate device types in Xcode"]
    A -- Yes --> KNOWN{"Exact UDID exists in inventory?"}
    KNOWN -- No --> E1["Fail: unknown UDID"]
    KNOWN -- Yes --> VERSION{"Original runtime version known<br/>or recoverable from its identifier?"}
    VERSION -- No --> E2["Fail: cannot determine original runtime"]
    VERSION -- Yes --> PREFIX{"Original OS matches requested prefix?"}
    PREFIX -- No --> E3["Fail: UUID and OS disagree"]
    PREFIX -- Yes --> AVAILABLE{"Original runtime is available?"}
    AVAILABLE -- Yes --> E4["Fail: device unavailable despite usable runtime"]
    AVAILABLE -- No --> PIN["Pin download to original OS version"]
    PIN --> TYPES
    TYPES --> FOUND{"Any candidate types?"}
    FOUND -- No --> E5["Fail: no matching type in selected Xcode"]
    FOUND -- Yes --> FETCH["Fetch Apple catalog from CATALOG_URL<br/>Read selected Xcode version"]
    FETCH --> PLATFORM{"Exactly one recognized platform<br/>among candidate types via PLATFORMS?"}
    PLATFORM -- No --> E6["Fail: unsupported or ambiguous platform"]
    PLATFORM -- Yes --> FILTER["Filter catalog by platform, OS prefix, architecture,<br/>device version ranges, Xcode and macOS requirements<br/>Honor pinned OS version for UUIDs"]
    FILTER --> MATCH{"Any compatible catalog entries?"}
    MATCH -- No --> E7["Fail: no compatible downloadable runtime"]
    MATCH -- Yes --> PICK["Choose highest numeric OS version<br/>Prefer final release at that version<br/>Then prefer last catalog entry"]
    PICK --> DOWNLOAD["Install exact build with xcodebuild -downloadPlatform<br/>Use arm64 variant on arm64, otherwise universal"]
    DOWNLOAD --> RETURN["Return to overall flow to re-query inventory"]
```

The catalog compatibility check requires the OS version to fit at least one
candidate type's version range. Runtime support for a particular type is checked
against `simctl` again after installation. A successful download therefore does
not guarantee a usable destination; the action fails if the second selection
still finds none. It does not retry with another catalog entry.

`PLATFORMS` maps each recognized `productFamily` to the download command's
platform name and the catalog platform suffix. It is only consulted on the
download path. Unknown product families contribute no platform; zero or multiple
distinct recognized platforms cause an error.

| Query with no installed devices or runtimes | Result, assuming Xcode knows the listed types |
| --- | --- |
| `iP` | iPad, iPhone, and iPod touch all map to `("iOS", "iphoneos")`. The action can download a compatible iOS runtime, then reuse or create a matching device. Creation chooses the first supported type in name order. |
| `Apple` | Apple TV, Apple Watch, and Apple Vision map to different platforms. The action fetches the catalog, then fails on platform ambiguity without downloading a runtime. |

An ambiguous query may still succeed using installed runtimes, because the
single-platform requirement is enforced only when selecting a download.
