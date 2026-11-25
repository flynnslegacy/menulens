#!/bin/zsh
# Captures the App Store edition's pages in French and English, then composes the store screenshots
# into docs/appstore/screenshots/{fr,en}. Run scripts/build-appstore.sh first.
# Takes about 2 minutes. Leave the Mac alone meanwhile: a click elsewhere closes the popover.
set -euo pipefail

ROOT="${0:A:h:h}"
APP="$ROOT/build/AppStore/Menulens.xcarchive/Products/Applications/Menulens.app"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$ROOT"

# Helper that prints Menulens's on-screen window ids.
cat > "$WORK/win.swift" <<'SWIFT'
import CoreGraphics
let list = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as! [[String: Any]]
for w in list where (w[kCGWindowOwnerName as String] as? String) == "Menulens" { print(w[kCGWindowNumber as String]!) }
SWIFT
swiftc -O "$WORK/win.swift" -o "$WORK/win" 2>/dev/null
swiftc -O "$ROOT/scripts/appstore-screenshots.swift" -o "$WORK/compose" 2>/dev/null

wait_window() {
  for i in {1..15}; do
    sleep 1
    local id=$("$WORK/win" | head -1)
    [[ -n "$id" ]] && { echo "$id"; return; }
  done
}

snap() { # output file: captures Menulens's window, retrying while it settles
  for i in {1..5}; do
    local id=$("$WORK/win" | head -1)
    [[ -n "$id" ]] && screencapture -x -o -l "$id" "$1" 2>/dev/null && return
    sleep 1
  done
  echo "Could not capture $1" >&2; return 1
}

capture() { # lang page delay
  pkill -x Menulens 2>/dev/null || true; sleep 1.5
  if [[ "$2" == main ]]; then open -n -a "$APP" --args -language "$1" --open-popover
  else open -n -a "$APP" --args -language "$1" --open-popover "$2"; fi
  wait_window > /dev/null; sleep "$3"
  snap "$WORK/cap/$1/$2.png"
}

for lang in french english; do
  mkdir -p "$WORK/cap/$lang"
  capture $lang main 2
  capture $lang battery 2
  capture $lang memory 12
  capture $lang disk 2
  capture $lang vpn 2
  pkill -x Menulens; sleep 1.5
  open -n -a "$APP" --args -language $lang; sleep 3; open -a "$APP"
  wait_window > /dev/null; sleep 1.5
  snap "$WORK/cap/$lang/settings.png"
done
pkill -x Menulens 2>/dev/null || true

# High-resolution marks and app icon, rendered by the app itself.
swift build --product Menulens > /dev/null
BIN="$(swift build --show-bin-path)/Menulens"
MENULENS_PREVIEW_SIDE=440 MENULENS_PREVIEW_CLEAR=1 "$BIN" --export-preview "$WORK/marks"
"$BIN" --export-iconset "$WORK/iconset"

mkdir -p docs/appstore/screenshots/fr docs/appstore/screenshots/en
"$WORK/compose" fr "$WORK/cap/french" "$WORK/marks" "$WORK/iconset/icon_512x512@2x.png" docs/appstore/screenshots/fr
"$WORK/compose" en "$WORK/cap/english" "$WORK/marks" "$WORK/iconset/icon_512x512@2x.png" docs/appstore/screenshots/en
echo "Screenshots in docs/appstore/screenshots"
