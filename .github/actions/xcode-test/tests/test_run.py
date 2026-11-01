import copy
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import subprocess
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("action", Path(__file__).parents[1] / "run.py")
action = importlib.util.module_from_spec(spec)
spec.loader.exec_module(action)
TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-17"
UDID = "11111111-2222-3333-4444-555555555555"
NEW_UDID = "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"


def runtime(v="27.2", available=True):
    return {"identifier": "com.apple.CoreSimulator.SimRuntime.iOS-" + v.replace(".", "-"),
            "version": v, "isAvailable": available,
            "supportedDeviceTypes": [{"identifier": TYPE}]}


def inventory():
    r = runtime()
    return {"runtimes": [r], "devicetypes": [
        {"name": "iPhone 17", "identifier": TYPE, "productFamily": "iPhone",
         "minRuntimeVersionString": "26.0.0", "maxRuntimeVersionString": "65535.255.255"}],
        "devices": {r["identifier"]: [
            {"name": "iPhone 17", "udid": UDID, "deviceTypeIdentifier": TYPE, "isAvailable": True}]}}


def downloadable(v="27.2", build="24B100", **kwargs):
    return {"platform": "com.apple.platform.iphoneos", "name": f"iOS {v} Simulator Runtime",
            "simulatorVersion": {"version": v, "buildUpdate": build},
            "architectures": ["arm64"], **kwargs}


class SelectionTests(unittest.TestCase):
    def test_all_three_device_selectors(self):
        for query in ("iPhone", TYPE, UDID):
            with self.subTest(query=query):
                self.assertEqual(action.existing(inventory(), query, "27")[0]["udid"], UDID)

    def test_identifiers_are_exact_and_names_are_case_sensitive_prefixes(self):
        for query in (TYPE[:-1], UDID[:-1], "Phone", "iphone", "iPad Pro"):
            with self.subTest(query=query):
                self.assertIsNone(action.existing(inventory(), query, "27"))
        self.assertFalse(action.matches({"name": "iPad Air 11-inch (M4)"}, "iPad Pro"))
        self.assertTrue(action.matches({"name": "iPad Pro 13-inch (M5)"}, "iPad Pro"))

    def test_numeric_runtime_order_and_literal_os_prefix(self):
        data = inventory()
        for v in ("27.10", "27.0", "28.0"):
            r = runtime(v)
            data["runtimes"].append(r)
            data["devices"][r["identifier"]] = copy.deepcopy(next(iter(data["devices"].values())))
        self.assertEqual(action.existing(data, "iPhone", "27")[1]["version"], "27.10")
        self.assertEqual(action.existing(data, "iPhone", "27.0")[1]["version"], "27.0")
        self.assertIsNone(action.existing(data, "iPhone", "26"))

    def test_unavailable_devices_and_runtimes_are_excluded(self):
        data = inventory()
        data["runtimes"][0]["isAvailable"] = False
        self.assertIsNone(action.existing(data, "iPhone", "27"))
        data["runtimes"][0]["isAvailable"] = True
        next(iter(data["devices"].values()))[0]["isAvailable"] = False
        self.assertIsNone(action.existing(data, "iPhone", "27"))

    def test_reuse_does_not_download_or_create(self):
        with patch.object(action, "inventory", return_value=inventory()), patch.object(action, "command") as cmd:
            self.assertEqual(action.select("iPhone", "27")[0]["udid"], UDID)
            cmd.assert_not_called()

    def test_create_from_installed_runtime_without_download(self):
        data = inventory()
        data["devices"] = {}
        with patch.object(action, "inventory", return_value=data), patch.object(action, "command", return_value=NEW_UDID.encode()) as cmd:
            self.assertEqual(action.select(TYPE, "27")[0]["udid"], NEW_UDID)
            cmd.assert_called_once_with("xcrun", "simctl", "create", "iPhone 17", TYPE,
                                        runtime()["identifier"], capture=True)

    def test_creation_requires_runtime_support_for_device_type(self):
        data = inventory()
        data["runtimes"][0]["supportedDeviceTypes"] = []
        self.assertIsNone(action.creatable(data, "iPhone", "27"))

    def test_uuid_never_creates_replacement(self):
        self.assertIsNone(action.creatable(inventory(), UDID, "27"))
        with self.assertRaisesRegex(ValueError, "exact UDID"):
            action.pinned_runtime(inventory(), NEW_UDID, "27")
        with self.assertRaisesRegex(ValueError, "does not match"):
            action.pinned_runtime(inventory(), UDID, "26")

    def test_uuid_with_removed_runtime(self):
        data = inventory()
        data["runtimes"] = []
        self.assertEqual(action.pinned_runtime(data, UDID, "27")["version"], "27.2")


class DownloadTests(unittest.TestCase):
    def choose(self, items, **kwargs):
        return action.download_candidate({"downloadables": items}, inventory()["devicetypes"],
                                         "27", "arm64", "27.1", "27.0", **kwargs)[1]

    def test_catalog_prefix_resolution_prefers_latest_version_and_final_release(self):
        final = downloadable("27.2")
        beta = downloadable("27.2", name="iOS 27.2 beta Simulator Runtime")
        self.assertEqual(self.choose([downloadable("27.0"), final, beta]), final)

    def test_catalog_filters_platform_architecture_host_and_device_compatibility(self):
        good = downloadable("27.0")
        self.assertEqual(self.choose([
            good, downloadable(platform="com.apple.platform.watchos"),
            downloadable(architectures=["x86_64"]),
            downloadable(hostRequirements={"minXcodeVersion": "27.2"}),
            downloadable(hostRequirements={"maxXcodeVersion": "27.0"}),
            downloadable(hostRequirements={"minHostVersion": "28.0"}),
        ]), good)
        self.assertFalse(action.supports_version(inventory()["devicetypes"][0], "18.0"))

    def test_no_catalog_match_fails(self):
        with self.assertRaisesRegex(ValueError, "No downloadable"):
            self.choose([downloadable("26.5")])

    def test_pinned_runtime_cannot_upgrade(self):
        self.assertEqual(self.choose([downloadable("27.0"), downloadable("27.2")],
                                     pinned=runtime("27.0"))["simulatorVersion"]["version"], "27.0")

    def test_download_requeries_inventory_and_runs_exact_build(self):
        before = inventory()
        before["runtimes"] = []
        before["devices"] = {}
        def command(*args, **kwargs):
            if args[0] == "curl":
                return plistlib.dumps({"downloadables": [downloadable()]})
            if args == ("xcodebuild", "-version"):
                return b"Xcode 27.1\nBuild version 18B1\n"
        with patch.object(action, "inventory", side_effect=[before, inventory()]), \
             patch.object(action, "command", side_effect=command) as cmd, \
             patch.object(action.platform, "machine", return_value="arm64"), \
             patch.object(action.platform, "mac_ver", return_value=("27.0", (), "")):
            self.assertEqual(action.select("iPhone", "27")[0]["udid"], UDID)
            cmd.assert_any_call("xcodebuild", "-downloadPlatform", "iOS", "-buildVersion", "24B100",
                                "-architectureVariant", "arm64")

    def test_failed_download_stops_without_creation(self):
        before = inventory()
        before["runtimes"] = []
        before["devices"] = {}
        with patch.object(action, "inventory", return_value=before), \
             patch.object(action, "command", side_effect=[
                 plistlib.dumps({"downloadables": [downloadable()]}), b"Xcode 27.1\n",
                 subprocess.CalledProcessError(70, "xcodebuild")]), \
             patch.object(action.platform, "machine", return_value="arm64"), \
             patch.object(action.platform, "mac_ver", return_value=("27.0", (), "")):
            with self.assertRaises(subprocess.CalledProcessError):
                action.select("iPhone", "27")


class CommandTests(unittest.TestCase):
    def test_mac_aliases_ignore_os_and_skip_simulator_selection(self):
        for query in ("mac", "MAC", "Mac", "macos", "MACOS", "macOS"):
            for os_version in (None, "", "26", "ignored"):
                for project in ("", "App.xcodeproj"):
                    with self.subTest(query=query, os=os_version, project=project), \
                         patch.dict(os.environ, {"TEST_DEVICE": query, "TEST_SCHEME": "App", "TEST_PROJECT": project}, clear=True), \
                         patch.object(action.sys, "platform", "darwin"), \
                         patch.object(action.os.path, "isdir", return_value=True), \
                         patch.object(action, "select") as select, \
                         patch.object(action, "command") as cmd, \
                         patch("builtins.print"):
                        if os_version is not None:
                            os.environ["TEST_OS"] = os_version
                        action.main()
                        select.assert_not_called()
                        expected = ["xcodebuild", "test", "-scheme", "App", "-destination", "platform=macOS"]
                        if project:
                            expected += ["-project", project]
                        cmd.assert_called_once_with(*expected)

    def test_mac_prefix_is_not_an_alias(self):
        for query in ("MacBook Pro", "macos-simulator", "machine"):
            with self.subTest(query=query), \
                 patch.dict(os.environ, {"TEST_DEVICE": query, "TEST_OS": "27", "TEST_SCHEME": "App", "TEST_PROJECT": ""}), \
                 patch.object(action.sys, "platform", "darwin"), \
                 patch.object(action, "select", side_effect=ValueError("No simulator")) as select, \
                 patch.object(action, "command") as cmd:
                with self.assertRaisesRegex(ValueError, "No simulator"):
                    action.main()
                select.assert_called_once_with(query, "27")
                cmd.assert_not_called()

    def test_simulators_still_require_numeric_os(self):
        for os_version in ("", "ignored"):
            with self.subTest(os=os_version), \
                 patch.dict(os.environ, {"TEST_DEVICE": "iPhone", "TEST_OS": os_version, "TEST_SCHEME": "App"}), \
                 patch.object(action.sys, "platform", "darwin"), \
                 patch.object(action, "command") as cmd:
                with self.assertRaisesRegex(ValueError, "os is required for simulators"):
                    action.main()
                cmd.assert_not_called()

    def test_optional_project_and_literal_scheme_arguments(self):
        for project in ("", "Folder with spaces/App.xcodeproj"):
            with self.subTest(project=project), \
                 patch.dict(os.environ, {"TEST_DEVICE": "iPhone", "TEST_OS": "27", "TEST_SCHEME": "App $(false)", "TEST_PROJECT": project}), \
                 patch.object(action.sys, "platform", "darwin"), \
                 patch.object(action.os.path, "isdir", return_value=True), \
                 patch.object(action, "select", return_value=({"name": "iPhone 17", "udid": UDID}, runtime())), \
                 patch.object(action, "command") as cmd:
                action.main()
                expected = ["xcodebuild", "test", "-scheme", "App $(false)", "-destination", f"id={UDID}"]
                if project:
                    expected += ["-project", project]
                cmd.assert_called_once_with(*expected)

    def test_xcodebuild_failure_is_not_swallowed(self):
        with patch.object(action.subprocess, "run", side_effect=subprocess.CalledProcessError(65, "xcodebuild")):
            with self.assertRaises(subprocess.CalledProcessError) as error:
                action.command("xcodebuild", "test")
            self.assertEqual(error.exception.returncode, 65)


if __name__ == "__main__":
    unittest.main()
