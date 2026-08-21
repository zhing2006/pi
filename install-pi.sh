#!/usr/bin/env bash
# Build pi from source and install it as a global command (npm link). macOS/Linux.
# Usage:
#   ./install-pi.sh                 # Full flow: install deps -> build -> npm link
#   ./install-pi.sh --skip-install  # Skip dependency install; rebuild + link only
#   ./install-pi.sh --sync           # Sync upstream/main, rebase zhing2006, and push both
#   ./install-pi.sh --sync --skip-install
set -euo pipefail

cd "$(dirname "$0")"

SKIP_INSTALL=false
SYNC=false
for arg in "$@"; do
	case "$arg" in
		--skip-install) SKIP_INSTALL=true ;;
		--sync) SYNC=true ;;
		*) echo "Unknown option: $arg" >&2; exit 1 ;;
	esac
done

sync_branches() {
	local git_status
	if ! git_status="$(git status --porcelain)"; then
		echo "Unable to read git status." >&2
		exit 1
	fi
	if [ -n "$git_status" ]; then
		echo "Cannot sync branches with uncommitted changes. Commit or remove them first." >&2
		exit 1
	fi

	git show-ref --verify --quiet refs/heads/main || {
		echo "Local branch 'main' was not found." >&2
		exit 1
	}
	git show-ref --verify --quiet refs/heads/zhing2006 || {
		echo "Local branch 'zhing2006' was not found." >&2
		exit 1
	}

	echo "==> Fetch upstream/main"
	git fetch upstream main

	echo "==> Fast-forward local main to upstream/main"
	git checkout main
	git merge --ff-only upstream/main

	echo "==> Push main to origin"
	git push origin main

	echo "==> Rebase zhing2006 onto main"
	git checkout zhing2006
	git rebase main

	echo "==> Push zhing2006 to origin (force-with-lease after rebase)"
	git push --force-with-lease origin zhing2006
}

if [ "$SYNC" = true ]; then
	sync_branches
fi

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
