#!/bin/sh
# Runs the test suite. With only the Command Line Tools installed (no Xcode),
# SwiftPM doesn't find the Swift Testing framework on its own, so we point it there.
set -eu
cd "$(dirname "$0")/.."

developer_dir="$(xcode-select -p)"
frameworks="$developer_dir/Library/Developer/Frameworks"
libs="$developer_dir/Library/Developer/usr/lib"

if [ -d "$frameworks/Testing.framework" ] && [ ! -d "$developer_dir/Platforms" ]; then
  exec swift test \
    -Xswiftc -F -Xswiftc "$frameworks" \
    -Xlinker -F -Xlinker "$frameworks" \
    -Xlinker -rpath -Xlinker "$frameworks" \
    -Xlinker -rpath -Xlinker "$libs" \
    "$@"
fi
exec swift test "$@"
