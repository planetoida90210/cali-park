#!/bin/bash
# Builds the UI tests and runs them on a fresh simulator, the way CI does.
#
# Usage: scripts/ci-ui-tests.sh <output directory> [preferred iOS version]
#
# 1. Builds the `cali-park-ui` test plan for a generic simulator, arm64 only,
#    without an index store, while CoreSimulator starts and
#    scripts/ci-pick-simulator.sh picks a device (that alone can take a minute
#    on a fresh runner).
# 2. Boots the device once the build is done. A first boot keeps the runner's
#    three cores busy for minutes; booting during the build slowed both down
#    more than running them one after the other.
# 3. Runs the tests from the built products (the .xctestrun file), retrying a
#    failed test once, so one slow launch doesn't fail the run while a real
#    failure (two in a row) still does.
#
# Writes xcodebuild-ui.log (build and test output), simctl-boot.log (boot
# progress, seconds since the start) and UITestResults.xcresult to the output
# directory, and prints how long each phase took. On the macos-26 runner the
# build is done after about 1.5 minutes; the first boot then takes 2.5 to 7
# minutes, mostly data migration, and is what makes the job slow.
set -euo pipefail

out="${1:?usage: $0 <output directory> [iOS version]}"
os="${2:-}"
log="$out/xcodebuild-ui.log"
start=$SECONDS
phase() { echo "::notice title=UI tests::$1 after $((SECONDS - start)) s"; }

xcodebuild \
  -project cali-park.xcodeproj \
  -scheme cali-park \
  -testPlan cali-park-ui \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$out/dd" \
  ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  build-for-testing > "$log" 2>&1 &
build_pid=$!

udid="$(scripts/ci-pick-simulator.sh "$os")"
phase "Simulator picked"

if ! wait "$build_pid"; then
  tail -n 50 "$log"
  echo "::error title=UI tests::build-for-testing failed; the full log is xcodebuild-ui.log"
  exit 1
fi
phase "Built"

xcrun simctl bootstatus "$udid" -b 2>&1 | while IFS= read -r line; do
  echo "$((SECONDS - start)) s: $line"
done > "$out/simctl-boot.log"
phase "Booted"

xctestrun="$(find "$out/dd/Build/Products" -maxdepth 1 -name '*.xctestrun' | head -n 1)"
status=0
xcodebuild \
  -xctestrun "$xctestrun" \
  -destination "platform=iOS Simulator,id=$udid" \
  -resultBundlePath "$out/UITestResults.xcresult" \
  -retry-tests-on-failure -test-iterations 2 \
  test-without-building >> "$log" 2>&1 || status=$?
phase "Tested"

grep -E "^Test Case .*(passed|failed|skipped)|: error: |^\*\* TEST" "$log" || true
exit "$status"
