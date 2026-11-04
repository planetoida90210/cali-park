#!/bin/zsh
# Fails when the default 1024 px app icon has an alpha channel or the wrong
# size. App Store Connect rejects such an icon at upload (ITMS-90717), even a
# fully opaque one. scripts/brand/build-icons.mjs writes it without alpha;
# the dark and tinted variants stay transparent on purpose.
set -eu
icon="${1:-cali-park/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png}"
info="$(sips -g pixelWidth -g pixelHeight -g hasAlpha "$icon")"
width="$(print -r -- "$info" | awk '/pixelWidth/ {print $2}')"
height="$(print -r -- "$info" | awk '/pixelHeight/ {print $2}')"
alpha="$(print -r -- "$info" | awk '/hasAlpha/ {print $2}')"
if [[ "$width" != 1024 || "$height" != 1024 ]]; then
  print -u2 "error: $icon is ${width}x${height}, expected 1024x1024"
  exit 1
fi
if [[ "$alpha" != no ]]; then
  print -u2 "error: $icon has an alpha channel; regenerate it with node scripts/brand/build-icons.mjs"
  exit 1
fi
print "App icon OK: $icon (1024x1024, no alpha)"
