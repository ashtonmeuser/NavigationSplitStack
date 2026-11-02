"""Regression cases for runtime variants and incomplete Apple catalog metadata."""

import copy
from contextlib import contextmanager
import json
from pathlib import Path
import plistlib
import subprocess
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).parents[1]))
import simulators


UDID = "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
GENERAL_BUILD = "24B8117"
MODEL_BUILD = "24B91016s"


class DownloadRegressionTests(unittest.TestCase):
    def setUp(self):
        self.fixture = json.loads((Path(__file__).parent / "fixtures/runtime-variants.json").read_text())
        self.catalog = self.fixture["catalog"]
        self.sdk = "27.2"
        self.xcode = "27.2"
        self.failure = None

    def data(self, builds=(), device=False):
        runtimes = [copy.deepcopy(r) for r in self.fixture["runtimes"] if r["buildversion"] in builds]
        devices = {}
        if device:
            runtime = next(r for r in runtimes if r["buildversion"] == MODEL_BUILD)
            devices[runtime["identifier"]] = [{
                "name": "iPhone Duo", "udid": UDID, "isAvailable": True,
                "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-Duo",
            }]
        return {"runtimes": runtimes, "devicetypes": self.fixture["devicetypes"], "devices": devices}

    def command(self, *args, **kwargs):
        if args[:2] == ("xcrun", "--sdk"):
            return self.sdk.encode()
        if args == ("xcodebuild", "-version"):
            return f"Xcode {self.xcode}\n".encode()
        if args[0] == "curl":
            return plistlib.dumps(self.catalog)
        if args[:2] == ("xcodebuild", "-downloadPlatform"):
            if self.failure:
                raise self.failure
            return None
        if args[:3] == ("xcrun", "simctl", "create"):
            return UDID.encode()
        raise AssertionError(f"Unexpected command: {args}")

    @contextmanager
    def runner(self, snapshots):
        with patch.object(simulators, "inventory", side_effect=snapshots), \
             patch.object(simulators, "command", side_effect=self.command) as command, \
             patch.object(simulators.platform, "machine", return_value="arm64"), \
             patch.object(simulators.platform, "mac_ver", return_value=("27.0", (), "")):
            yield command

    def downloads(self, command):
        return [c.args[4] for c in command.call_args_list if c.args[:2] == ("xcodebuild", "-downloadPlatform")]

    def test_model_specific_build_is_tried_after_general_build(self):
        with self.runner([self.data(), self.data([GENERAL_BUILD]), self.data([GENERAL_BUILD, MODEL_BUILD])]) as cmd:
            device, runtime = simulators.select("iPhone Duo", "27.2")
        self.assertEqual(self.downloads(cmd), [GENERAL_BUILD, MODEL_BUILD])
        self.assertEqual((device["udid"], runtime["buildversion"]), (UDID, MODEL_BUILD))
        self.assertEqual(cmd.call_args.args[-1], runtime["identifier"])

    def test_available_incompatible_build_is_not_downloaded_again(self):
        with self.runner([self.data([GENERAL_BUILD]), self.data([GENERAL_BUILD, MODEL_BUILD])]) as cmd:
            _, runtime = simulators.select("iPhone Duo", "27.2")
        self.assertEqual(self.downloads(cmd), [MODEL_BUILD])
        self.assertEqual(runtime["buildversion"], MODEL_BUILD)

    def test_removed_model_runtime_recovers_same_uuid_and_identifier(self):
        before = self.data([MODEL_BUILD], device=True)
        original_id = before["runtimes"][0]["identifier"]
        before["runtimes"] = []
        before["devices"][original_id][0]["isAvailable"] = False
        wrong = copy.deepcopy(before)
        wrong["runtimes"] = self.data([GENERAL_BUILD])["runtimes"]
        with self.runner([before, wrong, self.data([MODEL_BUILD], device=True)]) as cmd:
            device, runtime = simulators.select(UDID, "27")
        self.assertEqual((device["udid"], runtime["identifier"]), (UDID, original_id))
        self.assertEqual(self.downloads(cmd), [GENERAL_BUILD, MODEL_BUILD])
        self.assertFalse(any(c.args[:3] == ("xcrun", "simctl", "create") for c in cmd.call_args_list))

    def test_known_original_build_is_retained(self):
        before = self.data([MODEL_BUILD], device=True)
        before["runtimes"][0]["isAvailable"] = False
        with self.runner([before, self.data([MODEL_BUILD], device=True)]) as cmd:
            _, runtime = simulators.select(UDID, "")
        self.assertEqual(self.downloads(cmd), [MODEL_BUILD])
        self.assertEqual(runtime["buildversion"], MODEL_BUILD)

    def test_uuid_does_not_accept_different_build_with_same_runtime_identifier(self):
        before = self.data([MODEL_BUILD], device=True)
        before["runtimes"][0]["isAvailable"] = False
        after = self.data([MODEL_BUILD], device=True)
        after["runtimes"][0]["buildversion"] = "another-build"
        with self.runner([before, after]) as cmd, self.assertRaisesRegex(ValueError, "No usable simulator"):
            simulators.select(UDID, "")
        self.assertEqual(self.downloads(cmd), [MODEL_BUILD])
        self.assertFalse(any(c.args[:3] == ("xcrun", "simctl", "create") for c in cmd.call_args_list))

    def test_uuid_does_not_accept_different_runtime_identifier(self):
        before = self.data([MODEL_BUILD], device=True)
        before["runtimes"][0]["isAvailable"] = False
        after = self.data([MODEL_BUILD], device=True)
        old_id = after["runtimes"][0]["identifier"]
        new_id = "com.apple.CoreSimulator.SimRuntime.iOS-27-2-otherModel"
        after["runtimes"][0]["identifier"] = new_id
        after["devices"][new_id] = after["devices"].pop(old_id)
        with self.runner([before, after]), self.assertRaisesRegex(ValueError, "No usable simulator"):
            simulators.select(UDID, "")

    def test_ambiguous_and_unknown_devices_fail_before_any_external_command(self):
        before = self.data()
        before["devicetypes"] = [
            {"name": "Apple TV", "identifier": "tv", "productFamily": "Apple TV"},
            {"name": "Apple Watch", "identifier": "watch", "productFamily": "Apple Watch"},
        ]
        for query in ("Apple", "Unknown"):
            with self.subTest(query=query), self.runner([before]) as cmd, self.assertRaises(ValueError):
                simulators.select(query, "")
            cmd.assert_not_called()

    def test_ip_query_resolves_one_platform_and_stops_after_first_usable_build(self):
        with self.runner([self.data(), self.data([GENERAL_BUILD])]) as cmd:
            _, runtime = simulators.select("iP", "27.2")
        self.assertEqual(runtime["buildversion"], GENERAL_BUILD)
        self.assertEqual(self.downloads(cmd), [GENERAL_BUILD])

    def test_missing_host_requirements_cannot_bypass_sdk_ceiling(self):
        phone = next(t for t in self.fixture["devicetypes"] if t["name"] == "iPhone 15")
        candidates = simulators.download_candidates(self.catalog, [phone], "", "arm64", "15.0", "14.0", "17.0")
        self.assertTrue(candidates)
        self.assertEqual({c["simulatorVersion"]["version"] for c in candidates}, {"17.0"})
        with self.assertRaisesRegex(ValueError, "selected SDK 17.0"):
            simulators.download_candidates(self.catalog, [phone], "27", "arm64", "15.0", "14.0", "17.0")

    def test_explicit_newer_os_fails_before_downloading(self):
        self.sdk = "17.0"
        self.xcode = "15.0"
        with self.runner([self.data()]) as cmd, self.assertRaisesRegex(ValueError, "selected SDK 17.0"):
            simulators.select("iPhone 15", "27")
        self.assertEqual(self.downloads(cmd), [])

    def test_sdk_ceiling_does_not_restrict_installed_runtime_selection(self):
        self.sdk = "17.0"
        with self.runner([self.data([MODEL_BUILD])]) as cmd:
            _, runtime = simulators.select("iPhone Duo", "27.2")
        self.assertEqual(runtime["buildversion"], MODEL_BUILD)
        self.assertEqual(cmd.call_count, 1)
        self.assertEqual(cmd.call_args.args[:3], ("xcrun", "simctl", "create"))

    def test_catalog_host_architecture_exclusion_is_respected(self):
        watch = {"productFamily": "Apple Watch", "minRuntimeVersionString": "6.0"}
        args = (self.catalog, [watch], "6.2.1")
        with self.assertRaisesRegex(ValueError, "No downloadable"):
            simulators.download_candidates(*args, "arm64", "13.0", "12.0", "6.2.1")
        self.assertEqual(len(simulators.download_candidates(*args, "x86_64", "13.0", "12.0", "6.2.1")), 1)

    def test_duplicate_catalog_entries_do_not_repeat_downloads_and_exhaustion_fails(self):
        self.catalog["downloadables"] *= 2
        with self.runner([self.data(), self.data([GENERAL_BUILD]), self.data([GENERAL_BUILD])]) as cmd, \
             self.assertRaisesRegex(ValueError, "after trying eligible builds"):
            simulators.select("iPhone Duo", "27.2")
        self.assertEqual(self.downloads(cmd), [GENERAL_BUILD, MODEL_BUILD])

    def test_download_failure_stops_before_another_build(self):
        self.failure = subprocess.CalledProcessError(70, "xcodebuild")
        with self.runner([self.data()]) as cmd, self.assertRaises(subprocess.CalledProcessError) as caught:
            simulators.select("iPhone Duo", "27.2")
        self.assertEqual(caught.exception.returncode, 70)
        self.assertEqual(self.downloads(cmd), [GENERAL_BUILD])

    def test_final_beats_rc_at_same_version_but_newer_beta_remains_eligible(self):
        phone = next(t for t in self.fixture["devicetypes"] if t["name"] == "iPhone 17")
        final = next(i for i in self.catalog["downloadables"] if i["simulatorVersion"]["buildUpdate"] == GENERAL_BUILD)
        rc = dict(final, name="iOS 27.2 RC Simulator Runtime", simulatorVersion={"version": "27.2", "buildUpdate": "rc"})
        newer = dict(final, name="iOS 27.3 beta Simulator Runtime", simulatorVersion={"version": "27.3", "buildUpdate": "beta"})
        for items in ([final, rc, newer], [newer, rc, final]):
            candidates = simulators.download_candidates({"downloadables": items}, [phone], "27", "arm64", "27.3", "27.0", "27.3")
            self.assertEqual([c["simulatorVersion"]["buildUpdate"] for c in candidates], ["beta", GENERAL_BUILD, "rc"])


if __name__ == "__main__":
    unittest.main()
