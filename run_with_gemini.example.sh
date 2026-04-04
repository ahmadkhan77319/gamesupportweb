#!/usr/bin/env bash
# Copy to run_with_gemini.local.sh, paste your key, chmod +x, then run from game/:
#   ./run_with_gemini.local.sh
# run_with_gemini.local.sh is listed in .gitignore.

set -e
cd "$(dirname "$0")"
export GEMINI_API_KEY="${GEMINI_API_KEY:-PASTE_YOUR_KEY_HERE}"
exec flutter run --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" "$@"
