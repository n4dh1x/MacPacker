#!/usr/bin/env bash
# A command-line build emits .stringsdata; the Xcode IDE normally performs
# this final sync itself. Let Apple's tool own catalog keys and metadata.
set -euo pipefail

derived_data=${1:?usage: sync-localizations.sh /path/to/DerivedData}
stringsdata=()
while IFS= read -r -d '' file; do
    stringsdata+=("$file")
done < <(find "$derived_data/Build/Intermediates.noindex" -type f \
    \( -path '*/MacPacker.build/Objects-normal/arm64/*' \
    -o -path '*/FinderExtension.build/Objects-normal/arm64/*' \) \
    -name '*.stringsdata' -print0)

if [ "${#stringsdata[@]}" -eq 0 ]; then
    echo "No app localization data found; build the universal app first." >&2
    exit 1
fi

# The Finder extension shares the app's catalog. Include both targets so
# their existing keys stay active; use one architecture to avoid duplicates.
for catalog in MacPacker/Localizable.xcstrings MacPacker/LeanBytes.xcstrings; do
    xcrun xcstringstool sync "$catalog" --stringsdata "${stringsdata[@]}"
done
