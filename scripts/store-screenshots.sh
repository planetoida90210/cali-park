#!/bin/bash
# Takes the App Store screenshots and frames them.
#
# Usage: scripts/store-screenshots.sh [--udid <simulator UDID>] [--no-frame]
#
# 1. Boots the simulator (default: "iPhone 17 Pro Max" on iOS 26.5, a 6.9"
#    display at 1320 x 2868; override with --udid, or STORE_SHOTS_DEVICE and
#    STORE_SHOTS_OS) and sets a clean status bar: 9:41, a full battery
#    without the charging bolt, full signal.
# 2. Runs the StoreScreenshotTour UI test on the `storeTour` seed, which the
#    normal test runs skip.
# 3. Exports its screenshots from the result bundle into
#    docs/release/screenshots/raw/ at native resolution (01-home.png, ...).
# 4. Frames them with scripts/frame-store-screenshots.swift into
#    docs/release/screenshots/framed/, unless --no-frame is given.
#
# The status bar override is cleared at the end. Needs the iOS 26.5 simulator
# runtime, and network access for the Parks map tiles. The weekly ring shows
# 0/3 on a Monday, 1/3 on a Tuesday and 2/3 from Wednesday on, so take the
# shots from Wednesday to Sunday.
set -euo pipefail

cd "$(dirname "$0")/.."

device_name="${STORE_SHOTS_DEVICE:-iPhone 17 Pro Max}"
os_version="${STORE_SHOTS_OS:-26.5}"
udid=""
frame=1

while [ $# -gt 0 ]; do
    case "$1" in
        --udid) udid="$2"; shift 2 ;;
        --no-frame) frame=0; shift ;;
        -h|--help) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 64 ;;
    esac
done

if [ -z "$udid" ]; then
    udid="$(xcrun simctl list devices available -j | python3 -I -c '
import json, sys
name, version = sys.argv[1], sys.argv[2]
key_suffix = ".iOS-" + version.replace(".", "-")
for key, devices in json.load(sys.stdin)["devices"].items():
    if key.endswith(key_suffix):
        for device in devices:
            if device["name"] == name:
                print(device["udid"])
                sys.exit(0)
sys.exit("No available %s simulator on iOS %s" % (name, version))
' "$device_name" "$os_version")"
fi
echo "Simulator: $device_name, iOS $os_version ($udid)"

work="$(mktemp -d "${TMPDIR:-/tmp}/store-shots.XXXXXX")"
raw_dir="docs/release/screenshots/raw"

clear_status_bar() {
    xcrun simctl status_bar "$udid" clear >/dev/null 2>&1 || true
}
trap clear_status_bar EXIT

# Boot and wait; an already booted device is fine.
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null

xcrun simctl status_bar "$udid" override \
    --time 9:41 \
    --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --operatorName "" \
    --batteryState discharging --batteryLevel 100

echo "Running the screenshot tour (log: $work/xcodebuild.log)"
set +e
TEST_RUNNER_CALIPARK_STORE_SHOTS=1 xcodebuild \
    -project cali-park.xcodeproj \
    -scheme cali-park \
    -destination "platform=iOS Simulator,id=$udid" \
    -derivedDataPath "${STORE_SHOTS_DERIVED_DATA:-$work/dd}" \
    -resultBundlePath "$work/StoreShots.xcresult" \
    -only-testing:cali-parkUITests/StoreScreenshotTour \
    test > "$work/xcodebuild.log" 2>&1
status=$?
set -e
if [ $status -ne 0 ]; then
    tail -40 "$work/xcodebuild.log" >&2
    echo "The screenshot tour failed; result bundle: $work/StoreShots.xcresult" >&2
    exit $status
fi

xcrun xcresulttool export attachments \
    --path "$work/StoreShots.xcresult" \
    --output-path "$work/attachments" >/dev/null

# The manifest maps each exported file to the attachment's name ("01-home").
mkdir -p "$raw_dir"
rm -f "$raw_dir"/*.png
python3 -I - "$work/attachments" "$raw_dir" <<'PY'
import json, os, re, shutil, sys
source, target = sys.argv[1], sys.argv[2]
count = 0
with open(os.path.join(source, "manifest.json")) as f:
    manifest = json.load(f)
for test in manifest:
    for attachment in test.get("attachments", []):
        # "01-home_0_<UUID>.png": the name we gave, then Xcode's suffix.
        human = attachment.get("suggestedHumanReadableName", "")
        match = re.match(r"(\d\d-[a-z0-9-]+)", human)
        if not match:
            continue
        shutil.copyfile(os.path.join(source, attachment["exportedFileName"]),
                        os.path.join(target, match.group(1) + ".png"))
        count += 1
if count == 0:
    sys.exit("No screenshots in the result bundle")
print("Exported %d screenshots into %s" % (count, target))
PY

if [ $frame -eq 1 ]; then
    xcrun swift scripts/frame-store-screenshots.swift
fi
rm -rf "$work"
