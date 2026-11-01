#!/bin/sh
# Evaluate the released Google Robot scheduler on the 6 SimplerEnv Google tasks
# (200 episodes each) and print success rate / FLOPs speedup.
#
# Required:
#   MODEL_PATH       GR00T-N1.6-fractal checkpoint directory
# Optional:
#   CHECKPOINT       scheduler checkpoint (default: checkpoints/gr00t/google_robot/ppo_schedule.zip)
#   OUTPUT_ROOT      output directory (default: outputs/gr00t/google_robot)
#   EPISODES         episodes per task (default: 200)
#   TASKS            space-separated subset of task names (default: all 6)
#   PYTHON_BIN       python interpreter (default: python3)
# GPU selection follows CUDA_VISIBLE_DEVICES. Tasks run sequentially.
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
REPO_ROOT=$(elegantvla_resolve_repo_root "$SCRIPT_DIR")

: "${MODEL_PATH:?set MODEL_PATH to the GR00T-N1.6-fractal checkpoint directory}"
CHECKPOINT=${CHECKPOINT:-$REPO_ROOT/checkpoints/gr00t/google_robot/ppo_schedule.zip}
OUTPUT_ROOT=${OUTPUT_ROOT:-$REPO_ROOT/outputs/gr00t/google_robot}
EPISODES=${EPISODES:-200}
TASKS=${TASKS:-"google_robot_close_drawer google_robot_move_near google_robot_open_drawer google_robot_pick_coke_can google_robot_pick_object google_robot_place_in_closed_drawer"}
PYTHON_BIN=${PYTHON_BIN:-python3}

[ -f "$CHECKPOINT" ] || { echo "Scheduler checkpoint not found: $CHECKPOINT" >&2; exit 1; }

elegantvla_setup_python_env "$REPO_ROOT"
mkdir -p "$OUTPUT_ROOT"

run_dirs=""
for task in $TASKS; do
    out="$OUTPUT_ROOT/$task"
    if [ -f "$out/aggregate.json" ]; then
        echo "[skip] $task already finished"
    else
        echo "[run] $task"
        "$PYTHON_BIN" -m elegantvla.gr00t.entrypoints.eval_rl \
            --checkpoint-path "$CHECKPOINT" \
            --model-path "$MODEL_PATH" \
            --env-name "simpler_env_google/$task" \
            --episodes "$EPISODES" \
            --reward-mode stage1 \
            --output-dir "$out"
    fi
    run_dirs="$run_dirs $out"
done

# shellcheck disable=SC2086
"$PYTHON_BIN" -m elegantvla.gr00t.tools.speedup $run_dirs
