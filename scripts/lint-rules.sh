#!/bin/bash
# Counts violations of the clearest rules in .cursor/rules/project-rules.mdc.
#
# Usage:
#   scripts/lint-rules.sh                          report only, always exits 0
#   scripts/lint-rules.sh --baseline FILE          exit 1 if any rule has more hits than FILE allows
#   scripts/lint-rules.sh --strict                 exit 1 on any hit
#   scripts/lint-rules.sh --write-baseline FILE    write the current counts to FILE
#
# The baseline is a ratchet: existing violations are tolerated, new ones fail.
# When you fix violations, lower the counts with --write-baseline so they
# cannot come back. Lines that start with // are ignored.
#
# On GitHub Actions every hit is printed as a warning annotation and the counts
# go to the job summary. GitHub shows only the first 10 warning annotations per
# step; the full list is in the log.
set -euo pipefail

cd "$(dirname "$0")/.."

mode="report"
baseline=""
case "${1:-}" in
    "") ;;
    --strict) mode="strict" ;;
    --baseline) mode="baseline"; baseline="${2:?--baseline needs a file}" ;;
    --write-baseline) mode="write"; baseline="${2:?--write-baseline needs a file}" ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

paths=(cali-park cali-parkTests cali-parkUITests)

# id|extended regex|what to do instead
rules=(
    'foregroundColor|\.foregroundColor\(|Use foregroundStyle() instead of foregroundColor().'
    'cornerRadius|\.cornerRadius\(|Use clipShape(.rect(cornerRadius:)) instead of cornerRadius().'
    'onTapGesture|\.onTapGesture|Use a Button instead of onTapGesture(), unless you need the tap location or count.'
    'onChangeOneParameter|\.onChange\(of:[^{]*\{[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]+in([^A-Za-z0-9_]|$)|Use the two-parameter or zero-parameter onChange().'
    'tabItem|\.tabItem[[:space:]]*\{|Use the Tab API instead of tabItem().'
    'ObservableObject|ObservableObject|Use @Observable instead of ObservableObject.'
    'fontSystemSize|\.font\(\.system\(size:|Use a Dynamic Type text style instead of a fixed font size.'
    'NavigationView|NavigationView[[:space:]]*\{|Use NavigationStack instead of NavigationView.'
    'taskSleepNanoseconds|Task\.sleep\(nanoseconds:|Use Task.sleep(for: .seconds(...)).'
    'stringFormat|String\(format:|Use FormatStyle (format: .number...) instead of String(format:).'
    'DispatchQueue|DispatchQueue\.|Use Swift concurrency instead of DispatchQueue.'
    'forEachArrayEnumerated|ForEach\(Array\([^)]*\.enumerated\(\)|Drop the Array initializer: ForEach(x.enumerated(), id: ...).'
    'documentsDirectoryLookup|\.urls\(for:[[:space:]]*\.documentDirectory|Use URL.documentsDirectory.'
    'UIGraphicsImageRenderer|UIGraphicsImageRenderer|Use ImageRenderer for SwiftUI views.'
)

baseline_count() {
    # Prints the allowed count for rule $1, or 0 when the rule is not listed.
    awk -v id="$1" '$1 == id { print $2; found = 1 } END { if (!found) print 0 }' "$baseline"
}

on_github=false
[[ "${GITHUB_ACTIONS:-}" == "true" ]] && on_github=true

total=0
failed=0
summary="| Rule | Count | Allowed | |"$'\n'"|---|---:|---:|---|"$'\n'
new_baseline=""

for rule in "${rules[@]}"; do
    id="${rule%%|*}"
    rest="${rule#*|}"
    message="${rest##*|}"
    pattern="${rest%|*}"

    hits="$(grep -rnE --include='*.swift' -- "$pattern" "${paths[@]}" \
        | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' || true)"
    count=0
    [[ -n "$hits" ]] && count="$(printf '%s\n' "$hits" | wc -l | tr -d ' ')"
    total=$((total + count))
    new_baseline+="$id $count"$'\n'

    allowed="-"
    status=""
    case "$mode" in
        strict) allowed=0 ;;
        baseline) allowed="$(baseline_count "$id")" ;;
    esac
    if [[ "$allowed" != "-" && "$count" -gt "$allowed" ]]; then
        status="over by $((count - allowed))"
        failed=1
    fi

    printf '%-26s %4d' "$id" "$count"
    [[ "$allowed" != "-" ]] && printf '  (allowed %d)' "$allowed"
    [[ -n "$status" ]] && printf '  FAIL: %s' "$status"
    printf '\n'
    summary+="| \`$id\` | $count | $allowed | $status |"$'\n'

    if [[ -n "$hits" ]]; then
        level="warning"
        [[ -n "$status" ]] && level="error"
        while IFS= read -r hit; do
            file="${hit%%:*}"
            after_file="${hit#*:}"
            line="${after_file%%:*}"
            if $on_github; then
                echo "::$level file=$file,line=$line,title=$id::$message"
            else
                echo "    $file:$line"
            fi
        done <<< "$hits"
    fi
done

echo "Total: $total"

if [[ "$mode" == "write" ]]; then
    printf '%s' "$new_baseline" > "$baseline"
    echo "Wrote $baseline"
fi

if $on_github && [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
        echo "### Project rules (\`scripts/lint-rules.sh\`)"
        echo
        printf '%s' "$summary"
        echo
        echo "Total: $total"
    } >> "$GITHUB_STEP_SUMMARY"
fi

exit "$failed"
