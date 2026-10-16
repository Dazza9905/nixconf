import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import tomlkit

spec = importlib.util.spec_from_file_location("controls", Path(__file__).with_name("controls.py"))
controls = importlib.util.module_from_spec(spec)
spec.loader.exec_module(controls)


class TouchControlsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        for name, value in {
            "SETTINGS": root / "state/settings.toml",
            "CONFIG": root / "config",
            "SCALES": root / "runtime/scales.json",
        }.items():
            self.enterContext(patch.object(controls, name, value))
        self.enterContext(patch.dict(os.environ, {"NIRI_SOCKET": "test-session"}))
        self.run = self.enterContext(patch.object(controls, "run"))

    def write_settings(self, text):
        controls.atomic_write(controls.SETTINGS, text)

    def test_bar_preserves_existing_settings_and_is_idempotent(self):
        self.write_settings('''config_version = 14
[bar]
order = ["mine"]
[bar.mine]
start = ["clock"]
end = ["tray", "battery"]
[widget.clock]
scale = 0.8
''')
        controls.install_bar()
        first = controls.SETTINGS.read_text()
        controls.install_bar()
        self.assertEqual(first, controls.SETTINGS.read_text())
        config = tomlkit.parse(first)
        self.assertEqual(config["config_version"], 14)
        self.assertEqual(config["bar"]["mine"]["start"], ["clock"])
        self.assertEqual(config["bar"]["mine"]["end"], ["touch-keyboard", "touch-mode", "tray", "battery"])
        self.assertEqual(config["widget"]["clock"]["scale"], 0.8)
        self.assertTrue(controls.SETTINGS.with_name("settings.toml.before-touch-controls").exists())

    def test_scale_round_trip_restores_fractional_scale_and_leaves_external_display(self):
        self.write_settings("")
        outputs = {
            "eDP-1": {"logical": {"scale": 1.25}},
            "DP-1": {"logical": {"scale": 1.5}},
        }
        with patch.object(controls, "niri", return_value=outputs), patch.object(controls, "set_scale") as setter:
            controls.scale()
            setter.assert_called_once_with("eDP-1", 1.562)
            self.assertTrue(controls.SCALES.exists())
            outputs["eDP-1"]["logical"]["scale"] = 1.562
            controls.scale()
            self.assertEqual(setter.call_args_list[-1].args, ("eDP-1", 1.25))
            self.assertEqual(setter.call_count, 2)
            self.assertFalse(controls.SCALES.exists())

    def test_failed_scale_change_restores_original_and_clears_recovery_file(self):
        with patch.object(controls, "niri", return_value={"eDP-1": {"logical": {"scale": 1.25}}}), \
                patch.object(controls, "set_scale", side_effect=[RuntimeError("compositor rejected scale"), None]) as setter:
            with self.assertRaisesRegex(RuntimeError, "compositor rejected"):
                controls.scale()
            self.assertEqual(setter.call_args_list[-1].args, ("eDP-1", 1.25))
            self.assertFalse(controls.SCALES.exists())


if __name__ == "__main__":
    unittest.main()
