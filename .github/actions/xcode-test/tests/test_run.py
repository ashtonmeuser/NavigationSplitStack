import copy
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest
from unittest.mock import call, patch


spec = importlib.util.spec_from_file_location("action", Path(__file__).parents[1] / "run.py")
action = importlib.util.module_from_spec(spec)
spec.loader.exec_module(action)
TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-17"
UDID = "11111111-2222-3333-4444-555555555555"
NEW_UDID = "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
RESULT_PATH = "/tmp/xcode-test-example/Tests.xcresult"
SIGNING_ARGS = ["CODE_SIGN_STYLE=Manual", "CODE_SIGN_IDENTITY=-", "DEVELOPMENT_TEAM="]
TEST_ARGS = ["-resultBundlePath", RESULT_PATH, *SIGNING_ARGS]


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

    def test_identifiers_are_exact_and_names_are_case_insensitive_prefixes(self):
        for query in (TYPE[:-1], TYPE.lower(), UDID[:-1], "Phone", "iPad Pro"):
            with self.subTest(query=query):
                self.assertIsNone(action.existing(inventory(), query, "27"))
        for query in ("iphone", "IPHONE 17", "iPhOnE"):
            with self.subTest(query=query):
                self.assertEqual(action.existing(inventory(), query, "27")[0]["udid"], UDID)
                self.assertEqual(action.creatable(inventory(), query, "27")[0]["identifier"], TYPE)
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

    def test_newest_existing_device_with_empty_or_partial_os(self):
        data = inventory()
        older = runtime("27.0.1")
        newer = runtime("28.0")
        data["runtimes"].extend([older, newer])
        for r in (older, newer):
            data["devices"][r["identifier"]] = copy.deepcopy(data["devices"][runtime()["identifier"]])
        for os_prefix, expected in (("", "28.0"), ("27", "27.2"), ("27.0", "27.0.1")):
            with self.subTest(os=os_prefix), patch.object(action, "inventory", return_value=data), \
                 patch.object(action, "command") as cmd:
                self.assertEqual(action.select("iPhone", os_prefix)[1]["version"], expected)
                cmd.assert_not_called()

    def test_newer_runtime_beats_existing_device_on_older_runtime(self):
        data = inventory()
        older = runtime("27.0.1")
        data["runtimes"].append(older)
        data["devices"][older["identifier"]] = data["devices"].pop(runtime()["identifier"])
        for os_prefix in ("", "27"):
            for query in ("iPhone", TYPE):
                with self.subTest(os=os_prefix, query=query), \
                     patch.object(action, "inventory", return_value=data), \
                     patch.object(action, "command", return_value=NEW_UDID.encode()) as cmd:
                    device, selected = action.select(query, os_prefix)
                    self.assertEqual((device["udid"], selected["version"]), (NEW_UDID, "27.2"))
                    cmd.assert_called_once_with("xcrun", "simctl", "create", "iPhone 17", TYPE,
                                                runtime()["identifier"], capture=True)

    def test_latest_runtime_must_support_the_requested_device(self):
        data = inventory()
        incompatible = runtime("28.0")
        incompatible["supportedDeviceTypes"] = []
        data["runtimes"].extend([incompatible, runtime("29.0", available=False)])
        with patch.object(action, "inventory", return_value=data), patch.object(action, "command") as cmd:
            self.assertEqual(action.select(TYPE, "")[1]["version"], "27.2")
            cmd.assert_not_called()

    def test_uuid_with_empty_os_keeps_original_runtime(self):
        data = inventory()
        data["runtimes"].append(runtime("28.0"))
        with patch.object(action, "inventory", return_value=data), patch.object(action, "command") as cmd:
            self.assertEqual(action.select(UDID, "")[1]["version"], "27.2")
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

    def test_empty_os_downloads_newest_compatible_version(self):
        before = inventory()
        before["runtimes"] = []
        before["devices"] = {}
        catalog = {"downloadables": [downloadable("27.0.1", "24A1"), downloadable("27.2"),
                                     downloadable("28.0", hostRequirements={"minXcodeVersion": "28.0"})]}
        with patch.object(action, "inventory", side_effect=[before, inventory()]), \
             patch.object(action, "command", side_effect=[plistlib.dumps(catalog), b"Xcode 27.1\n", None]) as cmd, \
             patch.object(action.platform, "machine", return_value="arm64"), \
             patch.object(action.platform, "mac_ver", return_value=("27.0", (), "")):
            self.assertEqual(action.select("iPhone", "")[1]["version"], "27.2")
            cmd.assert_any_call("xcodebuild", "-downloadPlatform", "iOS", "-buildVersion", "24B100",
                                "-architectureVariant", "arm64")

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
    def setUp(self):
        results = patch.object(action, "prepare_result_bundle", return_value=RESULT_PATH)
        results.start()
        self.addCleanup(results.stop)
        environment = patch.dict(os.environ, {"TEST_AD_HOC_SIGNING": "true", "TEST_DISABLE_PARALLELIZATION": "false"})
        environment.start()
        self.addCleanup(environment.stop)

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
                        expected += TEST_ARGS
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

    def test_simulators_accept_omitted_or_empty_os(self):
        for os_version in (None, ""):
            with self.subTest(os=os_version), \
                 patch.dict(os.environ, {"TEST_DEVICE": "iPhone", "TEST_SCHEME": "App"}, clear=True), \
                 patch.object(action.sys, "platform", "darwin"), \
                 patch.object(action, "select", return_value=({"name": "iPhone 17", "udid": UDID}, runtime())) as select, \
                 patch.object(action, "command") as cmd:
                if os_version is not None:
                    os.environ["TEST_OS"] = os_version
                action.main()
                select.assert_called_once_with("iPhone", "")
                self.assertEqual(cmd.call_args_list, [
                    call("xcrun", "simctl", "bootstatus", UDID, "-b"),
                    call("xcodebuild", "test", "-scheme", "App", "-destination", f"id={UDID}", *TEST_ARGS),
                ])

    def test_simulators_reject_invalid_nonempty_os(self):
        for os_version in ("ignored", "27.x", " "):
            with self.subTest(os=os_version), \
                 patch.dict(os.environ, {"TEST_DEVICE": "iPhone", "TEST_OS": os_version, "TEST_SCHEME": "App"}), \
                 patch.object(action.sys, "platform", "darwin"), \
                 patch.object(action, "command") as cmd:
                with self.assertRaisesRegex(ValueError, "os must be empty or a numeric version prefix"):
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
                expected += TEST_ARGS
                self.assertEqual(cmd.call_args_list, [
                    call("xcrun", "simctl", "bootstatus", UDID, "-b"), call(*expected),
                ])

    def test_parallel_testing_toggle_and_boot_order(self):
        for query in ("mac", "iPhone"):
            for enabled, value in ((None, False), ("false", False), ("true", True), ("TRUE", True)):
                for state in ("Shutdown", "Booted"):
                    with self.subTest(query=query, parallel=enabled, state=state), \
                         patch.dict(os.environ, {"TEST_DEVICE": query, "TEST_SCHEME": "App"}, clear=True), \
                         patch.object(action.sys, "platform", "darwin"), \
                         patch.object(action, "select", return_value=({"name": "iPhone 17", "udid": UDID, "state": state}, runtime())), \
                         patch.object(action, "command") as cmd, patch("builtins.print"):
                        if enabled is not None:
                            os.environ["TEST_DISABLE_PARALLELIZATION"] = enabled
                        action.main()
                        args = cmd.call_args.args
                        self.assertEqual("-parallel-testing-enabled" in args, value)
                        if value:
                            self.assertEqual(args[args.index("-parallel-testing-enabled") + 1], "NO")
                        if query == "mac":
                            self.assertEqual(cmd.call_count, 1)
                        else:
                            self.assertEqual(cmd.call_count, 2)
                            self.assertEqual(cmd.call_args_list[0], call("xcrun", "simctl", "bootstatus", UDID, "-b"))
                        self.assertEqual(args[:2], ("xcodebuild", "test"))

    def test_invalid_parallel_toggle_fails_before_provisioning(self):
        for value in ("", "yes", "0"):
            with self.subTest(value=value), \
                 patch.dict(os.environ, {"TEST_DEVICE": "iPhone", "TEST_SCHEME": "App", "TEST_DISABLE_PARALLELIZATION": value}, clear=True), \
                 patch.object(action.sys, "platform", "darwin"), \
                 patch.object(action, "select") as select, patch.object(action, "command") as cmd:
                with self.assertRaisesRegex(ValueError, "disableParallelization must be true or false"):
                    action.main()
                select.assert_not_called()
                cmd.assert_not_called()

    def test_boot_failure_stops_before_xcodebuild(self):
        with patch.dict(os.environ, {"TEST_DEVICE": "iPhone", "TEST_SCHEME": "App"}, clear=True), \
             patch.object(action.sys, "platform", "darwin"), \
             patch.object(action, "select", return_value=({"name": "iPhone 17", "udid": UDID}, runtime())), \
             patch.object(action, "prepare_result_bundle") as results, \
             patch.object(action, "command", side_effect=subprocess.CalledProcessError(149, "simctl")) as cmd:
            with self.assertRaises(subprocess.CalledProcessError) as error:
                action.main()
            self.assertEqual(error.exception.returncode, 149)
            cmd.assert_called_once_with("xcrun", "simctl", "bootstatus", UDID, "-b")
            results.assert_not_called()

    def test_ad_hoc_signing_can_be_disabled_on_mac_and_simulators(self):
        for query in ("mac", "iPhone"):
            for enabled in ("true", "false", "FALSE"):
                with self.subTest(query=query, signing=enabled), \
                     patch.dict(os.environ, {"TEST_DEVICE": query, "TEST_SCHEME": "App", "TEST_AD_HOC_SIGNING": enabled}, clear=True), \
                     patch.object(action.sys, "platform", "darwin"), \
                     patch.object(action, "select", return_value=({"name": "iPhone 17", "udid": UDID}, runtime())), \
                     patch.object(action, "command") as cmd:
                    action.main()
                    args = cmd.call_args.args
                    for setting in SIGNING_ARGS:
                        self.assertEqual(setting in args, enabled == "true")
                    self.assertIn("-resultBundlePath", args)

    def test_invalid_signing_toggle_fails_before_provisioning(self):
        with patch.dict(os.environ, {"TEST_DEVICE": "iPhone", "TEST_SCHEME": "App", "TEST_AD_HOC_SIGNING": "yes"}, clear=True), \
             patch.object(action.sys, "platform", "darwin"), \
             patch.object(action, "select") as select, patch.object(action, "command") as cmd:
            with self.assertRaisesRegex(ValueError, "ad-hoc-signing must be true or false"):
                action.main()
            select.assert_not_called()
            cmd.assert_not_called()

    def test_xcodebuild_failure_is_not_swallowed(self):
        with patch.object(action.subprocess, "run", side_effect=subprocess.CalledProcessError(65, "xcodebuild")):
            with self.assertRaises(subprocess.CalledProcessError) as error:
                action.command("xcodebuild", "test")
            self.assertEqual(error.exception.returncode, 65)


class ResultBundleTests(unittest.TestCase):
    def test_unique_output_paths_do_not_precreate_bundles(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "output"
            output.write_text("existing=value\n")
            with patch.dict(os.environ, {"RUNNER_TEMP": directory, "GITHUB_OUTPUT": str(output)}):
                first = Path(action.prepare_result_bundle())
                second = Path(action.prepare_result_bundle())
            self.assertNotEqual(first, second)
            for path in (first, second):
                self.assertTrue(path.is_absolute())
                self.assertEqual(path.parent.parent, Path(directory).resolve())
                self.assertTrue(path.parent.is_dir())
                self.assertFalse(path.exists())
                self.assertEqual(path.suffix, ".xcresult")
            self.assertEqual(output.read_text(), f"existing=value\nresult-bundle-path={first}\nresult-bundle-path={second}\n")

    def test_output_is_published_before_failed_test_command(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "output"
            def fail(*args):
                bundle = args[args.index("-resultBundlePath") + 1]
                self.assertEqual(output.read_text(), f"result-bundle-path={bundle}\n")
                Path(bundle).mkdir()
                raise subprocess.CalledProcessError(65, args)
            with patch.dict(os.environ, {"TEST_DEVICE": "macOS", "TEST_SCHEME": "App", "RUNNER_TEMP": directory, "GITHUB_OUTPUT": str(output)}, clear=True), \
                 patch.object(action.sys, "platform", "darwin"), \
                 patch.object(action, "command", side_effect=fail):
                with self.assertRaises(subprocess.CalledProcessError) as error:
                    action.main()
            self.assertEqual(error.exception.returncode, 65)
            bundle = output.read_text().strip().split("=", 1)[1]
            self.assertTrue(Path(bundle).is_dir())


if __name__ == "__main__":
    unittest.main()
