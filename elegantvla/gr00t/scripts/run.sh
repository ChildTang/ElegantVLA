#!/bin/sh
# Run one GR00T entrypoint with the ElegantVLA source tree on PYTHONPATH.
#   sh elegantvla/gr00t/scripts/run.sh eval_rl --help
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
REPO_ROOT=$(elegantvla_resolve_repo_root "$SCRIPT_DIR")
PYTHON_BIN=${PYTHON_BIN:-python3}

case "${1:-}" in
    eval_rl|train_rl|evaluate|benchmark)
        entrypoint=$1
        shift
        ;;
    *)
        echo "Usage: $0 {eval_rl|train_rl|evaluate|benchmark} [arguments]" >&2
        exit 2
        ;;
esac

elegantvla_setup_python_env "$REPO_ROOT"
exec "$PYTHON_BIN" -m "elegantvla.gr00t.entrypoints.$entrypoint" "$@"
