#!/usr/bin/env python3
"""Success rate and FLOPs speedup of GR00T ``eval_rl`` runs.

Usage::

    python -m elegantvla.gr00t.tools.speedup outputs/gr00t/google_robot/*

Each argument is an ``eval_rl`` output directory containing ``aggregate.json`` and
``decision_trace.jsonl``. Full GR00T-N1.6 inference costs 0.935 TFLOP per step;
each scheduled step costs the sum of a backbone term and an action-head term below.

The robot-level average speedup weights tasks by their number of scheduler steps.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

FULL_TFLOP_PER_STEP = 0.935

# Backbone state of the executed step (with the action head refreshed), TFLOP.
BACKBONE_TFLOP = {
    "refresh": 0.867295,  # recompute the VLM backbone
    "reuse": 0.697315,  # reuse cached features, still encode the image
    "no_image": 0.443250,  # reuse cached features, skip the image encoder
}
# Change relative to a refreshed action head, TFLOP.
ACTION_HEAD_DELTA_TFLOP = {0: 0.0, 1: -0.216627, 2: -0.324666}  # REFRESH, REUSE_MIDDLE, REUSE_ALL_BUT_FIRST

# BackboneAction -> number of following no-image steps it grants.
_NO_IMAGE_BUDGET = {0: 0, 1: 0, 2: 1, 3: 2, 4: 3}


def run_cost(trace_path: Path) -> tuple[float, int]:
    """Return (total TFLOP, number of steps) for one ``decision_trace.jsonl``."""
    total, steps = 0.0, 0
    episode, budget = None, 0
    with trace_path.open() as handle:
        for line in handle:
            row = json.loads(line)
            if row["episode"] != episode:
                episode, budget = row["episode"], 0
            backbone, action_head = int(row["backbone_action"]), int(row["action_head_action"])
            if backbone == 0:
                state, budget = "refresh", 0
            elif budget > 0:
                state, budget = "no_image", budget - 1
            else:
                state, budget = "reuse", _NO_IMAGE_BUDGET[backbone]
            total += BACKBONE_TFLOP[state] + ACTION_HEAD_DELTA_TFLOP[action_head]
            steps += 1
    return total, steps


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("run_dirs", nargs="+", type=Path)
    args = parser.parse_args()

    rows = []
    for run_dir in args.run_dirs:
        aggregate = json.loads((run_dir / "aggregate.json").read_text())
        tflop, steps = run_cost(run_dir / "decision_trace.jsonl")
        rows.append((run_dir.name, aggregate["episodes"], aggregate["success_rate"], tflop, steps))

    print(f"{'run':48s} {'episodes':>8s} {'success':>8s} {'TFLOP/step':>10s} {'speedup':>8s}")
    for name, episodes, success, tflop, steps in rows:
        per_step = tflop / steps
        print(f"{name:48s} {episodes:8d} {100 * success:7.2f}% {per_step:10.4f} {FULL_TFLOP_PER_STEP / per_step:7.2f}x")
    if len(rows) > 1:
        success = sum(r[2] for r in rows) / len(rows)
        per_step = sum(r[3] for r in rows) / sum(r[4] for r in rows)
        print(f"{'AVG (success: task mean; FLOPs: step weighted)':48s} {'':8s} {100 * success:7.2f}% "
              f"{per_step:10.4f} {FULL_TFLOP_PER_STEP / per_step:7.2f}x")


if __name__ == "__main__":
    main()
