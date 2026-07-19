#!/usr/bin/env bash
# Build pi from source and install it as a global command (npm link). macOS/Linux.
# Usage:
#   ./install-pi.sh                 # Full flow: install deps -> build -> npm link
#   ./install-pi.sh --skip-install  # Skip dependency install; rebuild + link only
set -euo pipefail

cd "$(dirname "$0")"

SKIP_INSTALL=false
for arg in "$@"; do
	case "$arg" in
		--skip-install) SKIP_INSTALL=true ;;
		*) echo "Unknown option: $arg" >&2; exit 1 ;;
	esac
done

if [ "$SKIP_INSTALL" = false ]; then
	echo "==> Install dependencies (npm install --ignore-scripts)"
	npm install --ignore-scripts
fi

echo "==> Build all packages (npm run build)"
npm run build

echo "==> Register global pi command (npm link)"
(cd packages/coding-agent && npm link)

echo ""
echo "Done. Verifying version:"
"$(npm prefix -g)/bin/pi" --version
