#!/bin/sh
# Train the Google Robot scheduler with PPO over the 6 Google tasks (round-robin,
# 12 episodes per update).
#
#   Stage 1  imitation reward that follows the threshold teacher policy;
#            1,200 episodes in two runs of 600 (the second resumes from the first).
#   Stage 2  resumes from Stage 1 and adds a conservativeness penalty whenever the
#            scheduler computes more than the teacher; 1,200 episodes.
#
# Required:
#   MODEL_PATH         GR00T-N1.6-fractal checkpoint directory
# Optional:
#   STAGE              1, 2, or all (default: all)
#   SAVE_ROOT          output directory (default: outputs/gr00t/rl_train/google_robot)
#   STAGE1_CHECKPOINT  Stage 1 checkpoint to start Stage 2 from
#                      (default: $SAVE_ROOT/stage1/phase2/ppo_schedule.zip)
#   PYTHON_BIN         python interpreter (default: python3)
#   Extra arguments are forwarded to every run (e.g. --use-wandb).
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
REPO_ROOT=$(elegantvla_resolve_repo_root "$SCRIPT_DIR")

: "${MODEL_PATH:?set MODEL_PATH to the GR00T-N1.6-fractal checkpoint directory}"
STAGE=${STAGE:-all}
SAVE_ROOT=${SAVE_ROOT:-$REPO_ROOT/outputs/gr00t/rl_train/google_robot}
STAGE1_CHECKPOINT=${STAGE1_CHECKPOINT:-$SAVE_ROOT/stage1/phase2/ppo_schedule.zip}
PYTHON_BIN=${PYTHON_BIN:-python3}

case "$STAGE" in
    1|2|all) ;;
    *) echo "STAGE must be 1, 2, or all (got: $STAGE)" >&2; exit 2 ;;
esac

elegantvla_setup_python_env "$REPO_ROOT"

train() {
    "$PYTHON_BIN" -m elegantvla.gr00t.entrypoints.train_rl \
        --model-path "$MODEL_PATH" \
        --task-group google_all \
        --schedule-mode episode \
        --episodes-per-update 12 \
        --seed 0 \
        "$@"
}

if [ "$STAGE" != 2 ]; then
    if [ ! -f "$SAVE_ROOT/stage1/phase1/ppo_schedule.zip" ]; then
        train --reward-mode stage1 --total-episodes 600 \
            --save-dir "$SAVE_ROOT/stage1/phase1" "$@"
    fi
    if [ ! -f "$SAVE_ROOT/stage1/phase2/ppo_schedule.zip" ]; then
        train --reward-mode stage1 --total-episodes 600 \
            --resume-checkpoint "$SAVE_ROOT/stage1/phase1/ppo_schedule.zip" \
            --save-dir "$SAVE_ROOT/stage1/phase2" "$@"
    fi
    echo "Stage 1 checkpoint: $SAVE_ROOT/stage1/phase2/ppo_schedule.zip"
fi

if [ "$STAGE" != 1 ]; then
    if [ ! -f "$STAGE1_CHECKPOINT" ]; then
        echo "Stage 1 checkpoint not found: $STAGE1_CHECKPOINT (run STAGE=1 first or set STAGE1_CHECKPOINT)" >&2
        exit 1
    fi
    train --reward-mode stage2 --total-episodes 1200 \
        --stage2-efficiency-penalty-mode step \
        --stage2-backbone-conservative-penalty 0.05 \
        --stage2-action-head-conservative-penalty 0.025 \
        --resume-checkpoint "$STAGE1_CHECKPOINT" \
        --save-dir "$SAVE_ROOT/stage2" "$@"
    echo "Stage 2 checkpoint: $SAVE_ROOT/stage2/ppo_schedule.zip"
fi
