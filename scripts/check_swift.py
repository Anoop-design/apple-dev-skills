#!/usr/bin/env python3
"""Typecheck representative probes with the locally selected Xcode 27+ SDK."""

import argparse
import platform
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--metal", action="store_true", help="Also compile shader probes (requires Metal Toolchain)")
    args = parser.parse_args()
    if platform.system() != "Darwin":
        parser.error("These checks require macOS and a full Xcode installation.")
    try:
        version = subprocess.check_output(
            ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"], text=True).strip()
        if int(version.split(".")[0]) < 27:
            parser.error(f"Select Xcode with an iOS 27+ SDK; found {version}.")
        subprocess.run(["xcodebuild", "-version"], check=True)
        subprocess.run(["xcrun", "swiftc", "--version"], check=True)
        with tempfile.TemporaryDirectory(prefix="apple-dev-skills-check-") as temporary:
            cache = str(Path(temporary) / "modules")
            for probe in sorted((ROOT / "tests/swift").glob("*.swift")):
                minimum = {"AIAndWidgets.swift": "26.0", "Camera.swift": "17.0", "UI.swift": "15.0"}.get(probe.name, "27.0")
                print(f"Typechecking {probe.name} (iOS {minimum} deployment, SDK {version})", flush=True)
                subprocess.run([
                    "xcrun", "--sdk", "iphonesimulator", "swiftc", "-typecheck",
                    "-swift-version", "6", "-warnings-as-errors", "-target",
                    f"arm64-apple-ios{minimum}-simulator", "-module-cache-path", cache,
                    str(probe)], check=True)
            if args.metal:
                for probe in sorted((ROOT / "tests/swift").glob("*.metal")):
                    print(f"Compiling {probe.name}", flush=True)
                    subprocess.run([
                        "xcrun", "--sdk", "iphonesimulator", "metal", "-c", str(probe),
                        "-o", str(Path(temporary) / (probe.stem + ".air"))], check=True)
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"Check failed: {error}", file=sys.stderr)
        return 1
    print("PASS: representative probes checked; no app or device runtime tests were performed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
