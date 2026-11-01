#!/usr/bin/env bash
# Copy the ElegantVLA GR00T hooks (elegantvla/gr00t/integration/) into the pinned
# Isaac-GR00T submodule. Pass --check to only validate the destination.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_DIR="$ROOT_DIR/third_party/Isaac-GR00T"
EXPECTED_REVISION=ead52833afbbf4243f8cd5e7664f48a94de03b19
INTEGRATION_DIR="$ROOT_DIR/elegantvla/gr00t/integration"

if (( $# > 1 )) || [[ "${1:-}" != "" && "${1:-}" != "--check" ]]; then
    echo "Usage: $0 [--check]" >&2
    exit 2
fi
if [[ ! -e "$UPSTREAM_DIR/.git" || ! -f "$UPSTREAM_DIR/pyproject.toml" ]]; then
    echo "Initialize the submodule first: git submodule update --init --recursive" >&2
    exit 1
fi

upstream_git() {
    git -c safe.directory="$UPSTREAM_DIR" -C "$UPSTREAM_DIR" "$@"
}

if [[ "$(upstream_git rev-parse HEAD)" != "$EXPECTED_REVISION" ]]; then
    echo "Isaac-GR00T must be at revision $EXPECTED_REVISION." >&2
    exit 1
fi

# Check every destination before copying anything.
while IFS= read -r -d '' source; do
    relative="${source#"$INTEGRATION_DIR/"}"
    destination="$UPSTREAM_DIR/$relative"
    if [[ -L "$destination" ]]; then
        echo "Integration destination is a symlink: $destination" >&2
        exit 1
    fi
    if [[ -f "$destination" ]] && cmp -s "$source" "$destination"; then
        continue
    fi
    if upstream_git ls-files --error-unmatch -- "$relative" >/dev/null 2>&1; then
        if ! upstream_git diff --quiet HEAD -- "$relative"; then
            echo "Integration destination has local edits: $destination" >&2
            exit 1
        fi
    elif [[ -e "$destination" ]]; then
        echo "Integration destination already exists: $destination" >&2
        exit 1
    fi
done < <(find "$INTEGRATION_DIR" -type f -not -name '*.pyc' -print0)

if [[ "${1:-}" == "--check" ]]; then
    echo "GR00T integration check passed."
    exit 0
fi

cp -a "$INTEGRATION_DIR/." "$UPSTREAM_DIR/"
echo "ElegantVLA GR00T integration installed."
echo "In the GR00T Python environment, run: python -m pip install -e $ROOT_DIR"
