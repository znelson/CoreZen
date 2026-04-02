#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIRS=("CoreZen" "CoreZenTests")

if ! command -v clang-format &>/dev/null; then
	echo "error: clang-format not found"
	echo "  Install with: brew install clang-format"
	exit 1
fi

files=()
for dir in "${SOURCE_DIRS[@]}"; do
	target="$REPO_ROOT/$dir"
	[ -d "$target" ] || continue
	while IFS= read -r -d '' f; do
		files+=("$f")
	done < <(find "$target" -name '*.m' -o -name '*.h' -print0 2>/dev/null || true)
done

if [ ${#files[@]} -eq 0 ]; then
	echo "No source files found."
	exit 0
fi

check_only=false
for arg in "$@"; do
	case "$arg" in
		--check) check_only=true ;;
		*)
			echo "usage: $(basename "$0") [--check]"
			echo "  --check   Report violations without modifying files (exit 1 if any found)"
			exit 1
			;;
	esac
done

if $check_only; then
	echo "Checking formatting of ${#files[@]} files..."
	if ! clang-format --dry-run --Werror "${files[@]}"; then
		echo ""
		echo "Formatting violations found. Run Scripts/format.sh to fix."
		exit 1
	fi
	echo "All files formatted correctly."
else
	echo "Formatting ${#files[@]} files..."
	clang-format -i "${files[@]}"
	echo "Done."
fi
