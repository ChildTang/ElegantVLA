# GR00T backend

| Directory | Contents |
|---|---|
| `core/` | Model adapter, action-head cache, policy wrapper, scheduler policies and the RL environment |
| `entrypoints/` | `eval_rl.py`, `train_rl.py`, `evaluate.py` (threshold policy), `benchmark.py` |
| `tools/` | `speedup.py`: success rate and FLOPs speedup of `eval_rl` output directories |
| `scripts/` | `eval_google_robot.sh`, `train_google_robot.sh`, generic `run.sh` |
| `integration/` | Files copied into Isaac-GR00T: model hooks, fused kernels, CUDA Graph wrappers, SimplerEnv wrapper, and 16 upstream files kept at their N1.6 release versions (see the top-level README) |
| `tests/` | GPU regression tests for the middle cache, DiT K/V cache, kernels and RL action caps |

`core/adapter.py` handles model inputs, backbone recomputation and action-head
calls. `core/action_head.py` contains the compiled action-head refresh and
residual-reuse path. `core/wrapper.py` controls execution and cache lifetime.
Schedule types, the threshold policy, the RL policy wrapper and `SkipController`
live in `elegantvla.scheduling`; `core/rule_policy.py`, `core/rl_policy.py` and
`core/types.py` re-export them.

## Schedule actions

Each step the scheduler picks a backbone action and an action-head action.

| Backbone | Meaning |
|---|---|
| `REFRESH` (0) | Recompute the VLM backbone |
| `REUSE` (1) | Reuse cached middle layers, recompute first/last layers |
| `REUSE_THEN_NO_IMAGE_{1,2,3}` (2–4) | Reuse now, then skip the image encoder for the next 1–3 steps |

| Action head | Meaning |
|---|---|
| `REFRESH` (0) | Full DiT denoising |
| `REUSE_MIDDLE` (1) | Reuse the middle denoising residual |
| `REUSE_ALL_BUT_FIRST` (2) | Reuse everything after the first denoising step |

`decision_trace.jsonl` records `backbone_action` and `action_head_action` per step;
`tools/speedup.py` turns them into FLOPs.

## Evaluation output

`eval_rl` writes to `--output-dir`:

- `aggregate.json`: success rate, schedule ratios, latency summary
- `episodes.jsonl`: one line per episode
- `decision_trace.jsonl`: one line per scheduler step

Episodes are seeded from `--seed` (default 0), so runs are comparable episode by
episode, although GPU nondeterminism still changes individual rollouts.

## Optional GPU runtime

The integration includes model-specific kernels and graph wrappers. The reported
FLOPs speedups do not depend on them.

| Environment variable | Effect | Default |
|---|---|---|
| `GROOT_REALTIME_EAGLE` | Realtime defaults: static Qwen attention, boundary graphs and the Action DiT graph | `0` |
| `GROOT_TRITON_EAGLE_KERNELS` | Install Triton kernels; with realtime defaults, also fuse gate/up, QKV and SigLIP FC2/residual | off |
| `GROOT_CUDA_GRAPH_QWEN_BOUNDARIES` | Capture first/last Qwen layers and the refresh suffix | on with realtime defaults |
| `GROOT_CUDA_GRAPH_EAGLE` | Capture the whole Qwen decoder (alternative to boundary graphs) | `0` |
| `GROOT_CUDA_GRAPH_VISION` | Capture the fixed-shape SigLIP encoder | `0` |
| `GROOT_CUDA_GRAPH_ACTION_DIT` | Capture the Action DiT forward | on with realtime defaults |

Use boundary graphs rather than the whole-decoder graph together with
first/last-layer recomputation. Triton needs a compatible compiler environment.

## Training reward knobs

`train_rl` reads a few optional reward-shaping overrides from the environment
(`ELEGANTVLA_RL_*`, see `core/env.py`). The released checkpoint uses the defaults.
