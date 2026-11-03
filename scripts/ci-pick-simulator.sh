#!/bin/bash
# Prints the UDID of an available iPhone simulator.
#
# Usage: scripts/ci-pick-simulator.sh [preferred iOS version, e.g. 26.5]
#
# Picks a device on the preferred iOS runtime when it is installed, otherwise
# on the newest installed iOS runtime. Within a runtime it prefers the newest
# "Pro" iPhone, then any iPhone. Details go to stderr so that stdout holds only
# the UDID.
set -euo pipefail

preferred="${1:-}"

xcrun simctl list devices available -j | python3 -I -c '
import json, re, sys

preferred = sys.argv[1]
devices = json.load(sys.stdin)["devices"]

def runtime_version(key):
    # com.apple.CoreSimulator.SimRuntime.iOS-26-5 -> (26, 5)
    match = re.search(r"\.iOS-(\d+)-(\d+)", key)
    return (int(match.group(1)), int(match.group(2))) if match else None

# One runtime version can have several keys (e.g. a device-specific build), so
# group the iPhones by version.
by_version = {}
for key, entries in devices.items():
    version = runtime_version(key)
    iphones = [d for d in entries if d.get("isAvailable", True) and d["name"].startswith("iPhone")]
    if version and iphones:
        by_version.setdefault(version, []).extend(iphones)
runtimes = sorted(by_version.items())

if not runtimes:
    sys.exit("No available iPhone simulator found")

def as_string(version):
    return "%d.%d" % version

matching = [r for r in runtimes if as_string(r[0]) == preferred]
if preferred and not matching:
    print("Preferred iOS %s not installed, using the newest runtime" % preferred, file=sys.stderr)
version, iphones = (matching or runtimes)[-1]

def rank(device):
    name = device["name"]
    numbers = [int(n) for n in re.findall(r"\d+", name)]
    return ("Pro" in name, numbers, name)

device = max(iphones, key=rank)
print("Simulator: %s, iOS %s (%s)" % (device["name"], as_string(version), device["udid"]), file=sys.stderr)
print(device["udid"])
' "$preferred"
