"""Run with Python 3 on a Mac with Xcode 16.2+ and an installed iOS simulator."""
import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts"


def run(*args, capture=False):
    print("+", " ".join(map(str, args)), flush=True)
    return subprocess.run(list(map(str, args)), check=True, text=True,
                          stdout=subprocess.PIPE if capture else None).stdout


def simulator():
    saved = ARTIFACTS / "simulator.txt"
    if saved.exists():
        return saved.read_text().strip()
    devices = json.loads(run("xcrun", "simctl", "list", "devices", "available", "-j", capture=True))
    candidates = [
        (runtime, device) for runtime, items in devices["devices"].items()
        if ".iOS-" in runtime for device in items
        if device.get("isAvailable") and device["name"].startswith("iPhone")
    ]
    if not candidates:
        raise RuntimeError("Install an iOS simulator runtime in Xcode Settings > Components.")
    # Prefer the newest runtime without hardcoding a simulator model.
    candidates.sort(key=lambda item: tuple(int(n) for n in item[0].split(".iOS-")[-1].split("-")), reverse=True)
    device = candidates[0][1]
    udid = device["udid"]
    if device["state"] != "Booted":
        run("xcrun", "simctl", "boot", udid)
    run("xcrun", "simctl", "bootstatus", udid, "-b")
    saved.write_text(udid)
    return udid


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["test", "demo"])
    mode = parser.parse_args().mode
    if sys.platform != "darwin":
        parser.error("Xcode and the iOS Simulator require macOS.")
    ARTIFACTS.mkdir(exist_ok=True)
    udid = simulator()
    common = [
        "xcodebuild", "-project", ROOT / "NotingDown.xcodeproj",
        "-scheme", "NotingDown", "-destination", f"platform=iOS Simulator,id={udid}",
        "-derivedDataPath", ARTIFACTS / "DerivedData",
        "-parallel-testing-enabled", "NO", "CODE_SIGNING_ALLOWED=NO",
    ]
    if mode == "test":
        version = run("xcodebuild", "-version", capture=True)
        runtime = run("xcrun", "simctl", "list", "devices", "available", "-j", capture=True)
        (ARTIFACTS / "environment.txt").write_text(version + "\n" + runtime)
        run(*common, "-enableCodeCoverage", "YES",
            "-resultBundlePath", ARTIFACTS / "Tests.xcresult", "test")
        coverage = run("xcrun", "xccov", "view", "--report", "--json",
                       ARTIFACTS / "Tests.xcresult", capture=True)
        (ARTIFACTS / "coverage.json").write_text(coverage)
        return

    run("xcrun", "simctl", "status_bar", udid, "override", "--time", "9:41",
        "--dataNetwork", "wifi", "--wifiMode", "active", "--wifiBars", "3", "--batteryState", "charged", "--batteryLevel", "100")
    run("xcrun", "simctl", "ui", udid, "appearance", "light")
    recorder = subprocess.Popen(["xcrun", "simctl", "io", udid, "recordVideo",
                                 "--codec=h264", str(ARTIFACTS / "demo.mp4")])
    try:
        run(*common, "-only-testing:NotingDownUITests/NotingDownUITests/testDemoWalkthrough",
            "-resultBundlePath", ARTIFACTS / "Demo.xcresult", "test-without-building")
    finally:
        recorder.send_signal(signal.SIGINT)
        try:
            recorder.wait(timeout=20)
        except subprocess.TimeoutExpired:
            recorder.terminate()
            recorder.wait(timeout=10)
        run("xcrun", "simctl", "status_bar", udid, "clear")
    run("xcrun", "xcresulttool", "export", "attachments",
        "--path", ARTIFACTS / "Demo.xcresult", "--output-path", ARTIFACTS / "screenshots")
    if not (ARTIFACTS / "demo.mp4").is_file():
        raise RuntimeError("Simulator did not produce a demo recording.")


if __name__ == "__main__":
    main()
