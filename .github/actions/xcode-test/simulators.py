"""Find, download, and create Xcode simulators; Python standard library only."""

import json
import platform
import plistlib
import re

from utils import command, version


# Apple's downloadable simulator index is a plist. Fetch it only when no
# installed runtime can run the requested device and OS.
CATALOG_URL = (
    "https://devimages-cdn.apple.com/downloads/xcode/simulators/"
    "index2.dvtdownloadableindex"
)
# simctl device type productFamily -> (xcodebuild -downloadPlatform argument,
# catalog platform suffix). Both values are needed to select a catalog entry.
PLATFORMS = {
    "iPhone": ("iOS", "iphoneos"),
    "iPad": ("iOS", "iphoneos"),
    "iPod touch": ("iOS", "iphoneos"),
    "Apple TV": ("tvOS", "appletvos"),
    "Apple Watch": ("watchOS", "watchos"),
    "Apple Vision": ("visionOS", "xros"),
}
# A full UUID means an exact existing device, never a name prefix or a request
# to create a replacement. Also validates the UDID returned by simctl create.
UUID = re.compile(r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}")


def inventory():
    """Read the selected Xcode's runtimes, device types, and devices from simctl."""
    return json.loads(command("xcrun", "simctl", "list", "--json", capture=True))


def matches(device, query):
    """Match a full UDID or type identifier exactly, or a case-insensitive name prefix."""
    if UUID.fullmatch(query):
        return device.get("udid") == query
    if query.startswith("com.apple.CoreSimulator.SimDeviceType."):
        return device.get("deviceTypeIdentifier", device.get("identifier")) == query
    return device["name"].casefold().startswith(query.casefold())


def matching_runtimes(data, os_prefix):
    """Return available runtimes with the literal OS prefix, newest first."""
    return sorted(
        (r for r in data["runtimes"]
         if r.get("isAvailable") and r["version"].startswith(os_prefix)),
        key=lambda r: (version(r["version"]), r["identifier"]), reverse=True,
    )


def candidate_types(data, query):
    """Find Xcode device types matching the query, including types of matching devices."""
    # Include the type of a renamed or unavailable matching device.
    identifiers = {
        d.get("deviceTypeIdentifier")
        for devices in data["devices"].values() for d in devices if matches(d, query)
    }
    return sorted(
        (d for d in data["devicetypes"] if matches(d, query) or d["identifier"] in identifiers),
        key=lambda d: (d["name"], d["identifier"]),
    )


def supports_version(device_type, os_version):
    """Check a device type's minimum and maximum supported runtime versions."""
    return (version(device_type.get("minRuntimeVersionString", "0"))
            <= version(os_version)
            <= version(device_type.get("maxRuntimeVersionString", "65535.255.255")))


def installed_choice(data, query, os_prefix, pinned=None):
    """Return (kind, device or type, runtime) for the newest usable runtime.

    Reuse an available device before creating one on that runtime. A newer
    creatable runtime wins over an older runtime with an existing device.
    A UUID cannot produce a creatable type.
    """
    types = [] if UUID.fullmatch(query) else candidate_types(data, query)
    for runtime in matching_runtimes(data, os_prefix):
        if pinned and (runtime["identifier"] != pinned["identifier"]
                       or pinned.get("buildversion") and runtime.get("buildversion") != pinned["buildversion"]):
            continue
        devices = sorted(data["devices"].get(runtime["identifier"], []),
                         key=lambda d: (d["name"], d["udid"]))
        for device in devices:
            if device.get("isAvailable") and matches(device, query):
                return "device", device, runtime
        supported = {d["identifier"] for d in runtime.get("supportedDeviceTypes", [])}
        for device_type in types:
            if device_type["identifier"] in supported and supports_version(device_type, runtime["version"]):
                return "type", device_type, runtime
    return None


def pinned_runtime(data, query, os_prefix):
    """Validate a UUID before selection and retain its runtime identity and build.

    Removed runtime records may leave device records behind. Parse the numeric
    OS portion of their runtime identifier, preserving any model suffix.
    """
    if not UUID.fullmatch(query):
        return None
    found = next(((rid, d) for rid, devices in data["devices"].items()
                  for d in devices if d["udid"] == query), None)
    if found is None:
        raise ValueError(f"No simulator has the exact UDID {query}.")
    runtime_id, device = found
    runtime = next((r for r in data["runtimes"] if r["identifier"] == runtime_id), None)
    if runtime is None:
        match = re.fullmatch(
            r"com\.apple\.CoreSimulator\.SimRuntime\.(iOS|tvOS|watchOS|visionOS|xrOS)-"
            r"([0-9]+(?:-[0-9]+){0,2})(?:-[A-Za-z][A-Za-z0-9-]*)?", runtime_id,
        )
        if not match:
            raise ValueError(f"Cannot determine the missing runtime for UDID {query}.")
        runtime = {"version": match[2].replace("-", "."), "identifier": runtime_id}
    if not runtime["version"].startswith(os_prefix):
        raise ValueError(f"UDID {query} uses OS {runtime['version']}, which does not match {os_prefix}.")
    if runtime.get("isAvailable") and not device.get("isAvailable"):
        raise ValueError(f"UDID {query} is unavailable although its runtime is installed.")
    return runtime


def device_platform(types):
    """Resolve one supported download platform before making network requests."""
    if not types:
        raise ValueError("No matching device type exists in the selected Xcode.")
    platforms = {PLATFORMS[d["productFamily"]] for d in types if d.get("productFamily") in PLATFORMS}
    if len(platforms) != 1:
        raise ValueError("Device must identify one supported simulator platform.")
    return platforms.pop()


def download_candidates(catalog, types, os_prefix, architecture, xcode_version, host_version,
                        sdk_version, pinned=None):
    """Rank eligible builds; only simctl can confirm model support after install.

    Catalog entries often omit host requirements. Bound downloads by the
    selected platform SDK instead of treating those omissions as permission to
    install arbitrarily newer OS versions. Keep distinct builds at each version
    because a model-specific runtime may share a version with a general runtime.
    """
    platform_name, platform_id = device_platform(types)
    candidates = []
    for item in catalog["downloadables"]:
        sim = item.get("simulatorVersion", {})
        os_version = sim.get("version", "")
        requirements = item.get("hostRequirements", {})
        if (item.get("platform") != "com.apple.platform." + platform_id
                or not os_version or not sim.get("buildUpdate")
                or not os_version.startswith(os_prefix)
                or version(os_version) > version(sdk_version)
                or architecture not in item.get("architectures", ["arm64", "x86_64"])
                or architecture in requirements.get("excludedHostArchitectures", [])
                or not any(supports_version(d, os_version) for d in types)):
            continue
        if pinned and (version(os_version) != version(pinned["version"])
                       or pinned.get("buildversion") and sim["buildUpdate"] != pinned["buildversion"]):
            continue
        if any(version(current) < version(requirements.get(low, "0"))
               or version(current) > version(requirements.get(high, "65535"))
               for current, low, high in [
                   (xcode_version, "minXcodeVersion", "maxXcodeVersion"),
                   (host_version, "minHostVersion", "maxHostVersion"),
               ]):
            continue
        candidates.append(item)
    # Prefer final releases at the same version, then later catalog entries.
    candidates.sort(key=lambda d: (version(d["simulatorVersion"]["version"]),
                                   not re.search(r"beta|candidate|\bRC\b", d["name"], re.I)))
    builds = {}
    for item in reversed(candidates):
        builds.setdefault(item["simulatorVersion"]["buildUpdate"], item)
    if not builds:
        raise ValueError(f"No downloadable {platform_name} runtime matches OS {os_prefix!r}, "
                         f"the device/host, and selected SDK {sdk_version}. Select a newer Xcode if needed.")
    return list(builds.values())


def download_choice(data, query, os_prefix, pinned=None):
    """Try eligible builds until the refreshed inventory contains a usable choice.

    Skip already available builds: installed_choice has already rejected them.
    Failed download commands stop immediately; only successful installations
    with no usable match advance to another build. Each build is tried once.
    """
    types = candidate_types(data, query)
    platform_name, platform_id = device_platform(types)
    sdk_version = command("xcrun", "--sdk", platform_id, "--show-sdk-version", capture=True).decode().strip()
    xcode = command("xcodebuild", "-version", capture=True).decode()
    xcode_match = re.search(r"^Xcode ([0-9.]+)", xcode, re.M)
    if not xcode_match:
        raise ValueError("Cannot determine the selected Xcode version.")
    catalog = plistlib.loads(command("curl", "--fail", "--silent", "--show-error", "--location",
                                    "--retry", "3", "--max-time", "120", CATALOG_URL, capture=True))
    items = download_candidates(catalog, types, os_prefix, platform.machine(),
                                xcode_match[1], platform.mac_ver()[0], sdk_version, pinned)
    available_builds = {r.get("buildversion") for r in data["runtimes"] if r.get("isAvailable")}
    for item in items:
        build = item["simulatorVersion"]["buildUpdate"]
        if build in available_builds:
            continue
        print(f"Installing {item['name']} (build {build})", flush=True)
        command("xcodebuild", "-downloadPlatform", platform_name, "-buildVersion", build,
                "-architectureVariant", "arm64" if platform.machine() == "arm64" else "universal")
        data = inventory()
        choice = installed_choice(data, query, os_prefix, pinned)
        if choice:
            return choice
        available_builds.update(r.get("buildversion") for r in data["runtimes"] if r.get("isAvailable"))
        print(f"Build {build} provided no usable match; checking remaining eligible builds.", flush=True)
    raise ValueError(f"No usable simulator matches {query!r} and OS {os_prefix!r} after trying eligible builds. "
                     "Check the selected Xcode, host OS, and device support.")


def select(query, os_prefix):
    """Validate UUID identity, resolve a destination, then reuse or create it."""
    data = inventory()
    pinned = pinned_runtime(data, query, os_prefix)
    choice = installed_choice(data, query, os_prefix, pinned)
    if not choice:
        choice = download_choice(data, query, os_prefix, pinned)
    kind, device, runtime = choice
    if kind == "type":
        udid = command("xcrun", "simctl", "create", device["name"], device["identifier"],
                       runtime["identifier"], capture=True).decode().strip()
        if not UUID.fullmatch(udid):
            raise ValueError(f"simctl create returned an invalid UDID: {udid!r}")
        device = {"name": device["name"], "udid": udid}
    return device, runtime
