"""Test on macOS or a provisioned simulator; Python standard library only."""

import json
import os
import platform
import plistlib
import re
import shlex
import subprocess
import sys


CATALOG_URL = (
    "https://devimages-cdn.apple.com/downloads/xcode/simulators/"
    "index2.dvtdownloadableindex"
)
PLATFORMS = {
    "iPhone": ("iOS", "iphoneos"),
    "iPad": ("iOS", "iphoneos"),
    "iPod touch": ("iOS", "iphoneos"),
    "Apple TV": ("tvOS", "appletvos"),
    "Apple Watch": ("watchOS", "watchos"),
    "Apple Vision": ("visionOS", "xros"),
}
UUID = re.compile(r"[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}")


def command(*args, capture=False):
    print("+ " + shlex.join(args), flush=True)
    result = subprocess.run(args, check=True, stdout=subprocess.PIPE if capture else None)
    return result.stdout if capture else None


def inventory():
    return json.loads(command("xcrun", "simctl", "list", "--json", capture=True))


def version(value):
    parts = tuple(int(n) for n in value.split("."))
    return (parts + (0, 0, 0))[:3]


def matches(device, query):
    if UUID.fullmatch(query):
        return device.get("udid") == query
    if query.startswith("com.apple.CoreSimulator.SimDeviceType."):
        return device.get("deviceTypeIdentifier", device.get("identifier")) == query
    return device["name"].startswith(query)


def matching_runtimes(data, os_prefix):
    return sorted(
        (r for r in data["runtimes"]
         if r.get("isAvailable") and r["version"].startswith(os_prefix)),
        key=lambda r: (version(r["version"]), r["identifier"]), reverse=True,
    )


def existing(data, query, os_prefix):
    for runtime in matching_runtimes(data, os_prefix):
        devices = sorted(data["devices"].get(runtime["identifier"], []),
                         key=lambda d: (d["name"], d["udid"]))
        for device in devices:
            if device.get("isAvailable") and matches(device, query):
                return device, runtime
    return None


def candidate_types(data, query):
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
    return (version(device_type.get("minRuntimeVersionString", "0"))
            <= version(os_version)
            <= version(device_type.get("maxRuntimeVersionString", "65535.255.255")))


def creatable(data, query, os_prefix):
    if UUID.fullmatch(query):
        return None
    types = candidate_types(data, query)
    for runtime in matching_runtimes(data, os_prefix):
        supported = {d["identifier"] for d in runtime.get("supportedDeviceTypes", [])}
        for device_type in types:
            if device_type["identifier"] in supported and supports_version(device_type, runtime["version"]):
                return device_type, runtime
    return None


def installed_choice(data, query, os_prefix):
    """Choose the newest usable runtime, creating a device only when necessary."""
    selected = existing(data, query, os_prefix)
    creation = creatable(data, query, os_prefix)
    if selected and creation and version(creation[1]["version"]) > version(selected[1]["version"]):
        selected = None
    return selected, creation


def pinned_runtime(data, query, os_prefix):
    """A UUID must retain its original runtime as well as its identity."""
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
    data = inventory()
    selected, creation = installed_choice(data, query, os_prefix)
    if selected:
        return selected
    pinned = pinned_runtime(data, query, os_prefix)
    if not creation:
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
        selected, creation = installed_choice(data, query, os_prefix)
        if selected:
            return selected
    if not creation:
        raise ValueError(f"No usable simulator matches {query!r} and OS {os_prefix} after installation.")
    device_type, runtime = creation
    udid = command("xcrun", "simctl", "create", device_type["name"], device_type["identifier"],
                   runtime["identifier"], capture=True).decode().strip()
    if not UUID.fullmatch(udid):
        raise ValueError(f"simctl create returned an invalid UDID: {udid!r}")
    return {"name": device_type["name"], "udid": udid}, runtime


def main():
    if sys.platform != "darwin":
        raise ValueError("This action requires a macOS runner with Xcode selected.")
    query, os_prefix, scheme = (os.environ.get(key, "") for key in ("TEST_DEVICE", "TEST_OS", "TEST_SCHEME"))
    if not all(value.strip() for value in (query, scheme)):
        raise ValueError("device and scheme are required.")
    is_mac = query.lower() in ("mac", "macos")
    if not is_mac and os_prefix and not re.fullmatch(r"[0-9]+(?:\.[0-9]+){0,2}", os_prefix):
        raise ValueError("os must be empty or a numeric version prefix, such as 27 or 27.2.")
    project = os.environ.get("TEST_PROJECT", "")
    if project and (not project.endswith(".xcodeproj") or not os.path.isdir(project)):
        raise ValueError(f"Project does not exist or is not an .xcodeproj directory: {project!r}")
    if is_mac:
        destination = "platform=macOS"
        print("Testing on the runner's current macOS", flush=True)
    else:
        device, runtime = select(query, os_prefix)
        destination = f"id={device['udid']}"
        print(f"Testing on {device['name']} / {runtime['version']} / {device['udid']}", flush=True)
    args = ["xcodebuild", "test", "-scheme", scheme, "-destination", destination]
    if project:
        args.extend(["-project", project])
    command(*args)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
    except (ValueError, OSError, KeyError) as error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)
