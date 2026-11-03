#!/bin/bash
# Fails when an xcodebuild log contains a warning.
#
# Usage: scripts/check-build-warnings.sh <xcodebuild log>
#
# Every line with "warning:" counts, except the "Metadata extraction skipped"
# notes from appintentsmetadataprocessor, which come from Xcode's App Intents
# tooling rather than from compiling our code. xcodebuild repeats some warnings,
# so duplicates are counted once. On GitHub Actions each warning is also
# printed as an error annotation on its file and line.
set -euo pipefail

log="${1:?usage: $0 <xcodebuild log>}"

warnings="$(grep 'warning:' "$log" | grep -v 'appintentsmetadataprocessor' | sort -u || true)"

if [[ -z "$warnings" ]]; then
    echo "No build warnings."
    exit 0
fi

count="$(printf '%s\n' "$warnings" | wc -l | tr -d ' ')"
echo "Found $count build warning(s):"
printf '%s\n' "$warnings"

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    root="${GITHUB_WORKSPACE:-$PWD}/"
    printf '%s\n' "$warnings" | while IFS= read -r line; do
        # /path/File.swift:12:5: warning: message
        if [[ "$line" =~ ^(/[^:]+):([0-9]+):([0-9]+):\ warning:\ (.*)$ ]]; then
            file="${BASH_REMATCH[1]#"$root"}"
            echo "::error file=$file,line=${BASH_REMATCH[2]},col=${BASH_REMATCH[3]},title=Build warning::${BASH_REMATCH[4]}"
        else
            echo "::error title=Build warning::$line"
        fi
    done
fi

exit 1
