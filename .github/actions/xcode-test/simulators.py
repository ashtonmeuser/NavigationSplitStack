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


def installed_choice(data, query, os_prefix):
    """Return (kind, device or type, runtime) for the newest usable runtime.

    Reuse an available device before creating one on that runtime. A newer
    creatable runtime wins over an older runtime with an existing device.
    A UUID cannot produce a creatable type.
    """
    types = [] if UUID.fullmatch(query) else candidate_types(data, query)
    for runtime in matching_runtimes(data, os_prefix):
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
    """Recover a UUID's original runtime for reinstall, or reject a bad UUID.

    The device can remain in simctl's inventory after its runtime record is
    removed, so derive the version from the runtime identifier when needed.
    """
    if not UUID.fullmatch(query):
        return None
    runtime_id = next((rid for rid, devices in data["devices"].items()
                       if any(d["udid"] == query for d in devices)), None)
    if runtime_id is None:
        raise ValueError(f"No simulator has the exact UDID {query}.")
    runtime = next((r for r in data["runtimes"] if r["identifier"] == runtime_id), None)
    if runtime is None:
        # Removed runtimes may leave devices behind but no runtime record.
        match = re.fullmatch(r"com\.apple\.CoreSimulator\.SimRuntime\.(iOS|tvOS|watchOS|visionOS|xrOS)-([0-9]+(?:-[0-9]+){0,2})", runtime_id)
        if not match:
            raise ValueError(f"Cannot determine the missing runtime for UDID {query}.")
        runtime = {"version": match[2].replace("-", "."), "identifier": runtime_id}
    if not runtime["version"].startswith(os_prefix):
        raise ValueError(f"UDID {query} uses OS {runtime['version']}, which does not match {os_prefix}.")
    if runtime.get("isAvailable"):
        raise ValueError(f"UDID {query} is unavailable although its runtime is installed.")
    return runtime


def download_candidate(catalog, types, os_prefix, architecture, xcode_version, host_version, pinned=None):
    """Choose the newest compatible catalog runtime for one device platform.

    Filter by literal OS prefix, architecture, device type version range, and
    catalog host requirements. A pinned UUID permits only its original OS.
    """
    platforms = {PLATFORMS[d["productFamily"]] for d in types if d.get("productFamily") in PLATFORMS}
    if len(platforms) != 1:
        raise ValueError("Device must identify one supported simulator platform.")
    platform_name, platform_id = platforms.pop()
    candidates = []
    for item in catalog["downloadables"]:
        sim = item.get("simulatorVersion", {})
        os_version = sim.get("version", "")
        if (item.get("platform") != "com.apple.platform." + platform_id
                or not os_version
                or not os_version.startswith(os_prefix)
                or architecture not in item.get("architectures", ["arm64", "x86_64"])
                or not any(supports_version(d, os_version) for d in types)):
            continue
        if pinned and version(os_version) != version(pinned["version"]):
            continue
        requirements = item.get("hostRequirements", {})
        if any(version(current) < version(requirements.get(low, "0"))
               or version(current) > version(requirements.get(high, "65535"))
               for current, low, high in [
                   (xcode_version, "minXcodeVersion", "maxXcodeVersion"),
                   (host_version, "minHostVersion", "maxHostVersion"),
               ]):
            continue
        candidates.append(item)
    if not candidates:
        raise ValueError(f"No downloadable {platform_name} runtime matches OS {os_prefix} and this device/host.")
    # Prefer final releases at the same OS version, then newer catalog entries.
    candidates.sort(key=lambda d: (version(d["simulatorVersion"]["version"]),
                                   not re.search(r"beta|candidate", d["name"], re.I)))
    return platform_name, candidates[-1]


def select(query, os_prefix):
    """Reuse or create a simulator, downloading a runtime only when required.

    Return (device, runtime) for run.py. Re-query simctl after installation
    because the download can add a runtime and devices to the inventory.
    """
    data = inventory()
    choice = installed_choice(data, query, os_prefix)
    if choice and choice[0] == "device":
        return choice[1:]
    pinned = pinned_runtime(data, query, os_prefix)
    if not choice:
        types = candidate_types(data, query)
        if not types:
            raise ValueError(f"No device or device type matches {query!r} in the selected Xcode.")
        catalog = plistlib.loads(command("curl", "--fail", "--silent", "--show-error", "--location",
                                        "--retry", "3", "--max-time", "120", CATALOG_URL, capture=True))
        xcode = command("xcodebuild", "-version", capture=True).decode()
        xcode_version = re.search(r"^Xcode ([0-9.]+)", xcode, re.M)[1]
        platform_name, item = download_candidate(
            catalog, types, os_prefix, platform.machine(), xcode_version, platform.mac_ver()[0], pinned,
        )
        print(f"Installing {item['name']}", flush=True)
        # Resolve the prefix first; -buildVersion itself is not a prefix matcher.
        command("xcodebuild", "-downloadPlatform", platform_name,
                "-buildVersion", item["simulatorVersion"]["buildUpdate"],
                "-architectureVariant", "arm64" if platform.machine() == "arm64" else "universal")
        data = inventory()
        choice = installed_choice(data, query, os_prefix)
        if choice and choice[0] == "device":
            return choice[1:]
    if not choice:
        raise ValueError(f"No usable simulator matches {query!r} and OS {os_prefix} after installation.")
    _, device_type, runtime = choice
    udid = command("xcrun", "simctl", "create", device_type["name"], device_type["identifier"],
                   runtime["identifier"], capture=True).decode().strip()
    if not UUID.fullmatch(udid):
        raise ValueError(f"simctl create returned an invalid UDID: {udid!r}")
    return {"name": device_type["name"], "udid": udid}, runtime


