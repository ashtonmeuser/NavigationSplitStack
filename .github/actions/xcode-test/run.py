"""Validate action inputs and run Xcode tests on macOS or a selected simulator.

simulators.py resolves, installs, and creates simulator destinations. This file
handles the test command and the result bundle output shared by both platforms.
"""

import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

from simulators import select
from utils import command


def prepare_result_bundle():
    """Reserve a unique bundle path and publish it before xcodebuild can fail."""
    # Create only the parent: xcodebuild requires the bundle path not to exist.
    directory = tempfile.mkdtemp(prefix="xcode-test-", dir=os.environ.get("RUNNER_TEMP") or None)
    path = str(Path(directory).resolve() / "Tests.xcresult")
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
            output.write(f"result-bundle-path={path}\n")
    print(f"Result bundle: {path}", flush=True)
    return path


def source_packages_path():
    """Use the same Swift package checkout path as action.yml's cache step."""
    return str(Path(os.environ.get("RUNNER_TEMP") or tempfile.gettempdir()).resolve()
               / "xcode-test-source-packages")


def main():
    """Validate inputs, select and boot the destination, then run xcodebuild test."""
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
    ad_hoc_signing = os.environ.get("TEST_AD_HOC_SIGNING", "true").strip().lower()
    if ad_hoc_signing not in ("true", "false"):
        raise ValueError("ad-hoc-signing must be true or false.")
    disable_parallelization = os.environ.get("TEST_DISABLE_PARALLELIZATION", "false").strip().lower()
    if disable_parallelization not in ("true", "false"):
        raise ValueError("disableParallelization must be true or false.")
    if is_mac:
        # macOS tests use the runner's OS; TEST_OS has no effect here.
        destination = "platform=macOS"
        print("Testing on the runner's current macOS", flush=True)
    else:
        device, runtime = select(query, os_prefix)
        destination = f"id={device['udid']}"
        print(f"Testing on {device['name']} / {runtime['version']} / {device['udid']}", flush=True)
        # Boots if needed and waits for startup/data migration to finish.
        # Works for both existing booted devices and newly created simulators.
        command("xcrun", "simctl", "bootstatus", device["udid"], "-b")
    args = ["xcodebuild", "test", "-scheme", scheme, "-destination", destination]
    if project:
        args.extend(["-project", project])
    args.extend(["-clonedSourcePackagesDirPath", source_packages_path()])
    if disable_parallelization == "true":
        # Otherwise xcodebuild uses the scheme's parallel testing setting.
        args.extend(["-parallel-testing-enabled", "NO"])
    args.extend(["-resultBundlePath", prepare_result_bundle()])
    if ad_hoc_signing == "true":
        args.extend(["CODE_SIGN_STYLE=Manual", "CODE_SIGN_IDENTITY=-", "DEVELOPMENT_TEAM="])
    command(*args)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
    except (ValueError, OSError, KeyError) as error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)
