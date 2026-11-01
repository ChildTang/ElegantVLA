# Shared helpers for the GR00T launchers. Source this file; do not execute it.

elegantvla_resolve_repo_root() {
    candidate=$(CDPATH= cd -- "$1" && pwd)
    while [ ! -d "$candidate/elegantvla/gr00t" ] || [ ! -f "$candidate/pyproject.toml" ]; do
        if [ "$candidate" = "/" ]; then
            echo "Could not locate the ElegantVLA source tree." >&2
            return 1
        fi
        candidate=$(dirname -- "$candidate")
    done
    printf '%s\n' "$candidate"
}


# Usage: elegantvla_setup_python_env REPO_ROOT
# Optional environment variables:
#   SIMPLERENV_ROOT           external SimplerEnv checkout (default: the one bundled with Isaac-GR00T)
#   SIMPLERENV_SITE_PACKAGES  extra site-packages directory for SimplerEnv dependencies
#   ELEGANTVLA_CPU_THREADS    BLAS/OpenMP threads per process (default: 1)
elegantvla_setup_python_env() {
    repo_root=$1
    gr00t_root="$repo_root/third_party/Isaac-GR00T"
    pythonpath_prefix="$repo_root:$gr00t_root"
    simplerenv_source_root=${SIMPLERENV_ROOT:-$gr00t_root/external_dependencies/SimplerEnv}

    if [ -n "${SIMPLERENV_ROOT:-}" ] && [ ! -d "$SIMPLERENV_ROOT/simpler_env" ]; then
        echo "SIMPLERENV_ROOT must contain the simpler_env package." >&2
        return 1
    fi
    if [ -d "$simplerenv_source_root/simpler_env" ]; then
        pythonpath_prefix="$pythonpath_prefix:$simplerenv_source_root:$simplerenv_source_root/ManiSkill2_real2sim"
    fi
    if [ -n "${SIMPLERENV_SITE_PACKAGES:-}" ]; then
        if [ ! -d "$SIMPLERENV_SITE_PACKAGES" ]; then
            echo "SIMPLERENV_SITE_PACKAGES does not exist." >&2
            return 1
        fi
        pythonpath_prefix="$pythonpath_prefix:$SIMPLERENV_SITE_PACKAGES"
    fi

    export PYTHONPATH="$pythonpath_prefix${PYTHONPATH:+:$PYTHONPATH}"
    export MPLCONFIGDIR=${MPLCONFIGDIR:-${TMPDIR:-/tmp}/mplconfig_elegantvla}
    cpu_threads=${ELEGANTVLA_CPU_THREADS:-1}
    export OMP_NUM_THREADS=${OMP_NUM_THREADS:-$cpu_threads}
    export MKL_NUM_THREADS=${MKL_NUM_THREADS:-$cpu_threads}
    export OPENBLAS_NUM_THREADS=${OPENBLAS_NUM_THREADS:-$cpu_threads}
    export NUMEXPR_NUM_THREADS=${NUMEXPR_NUM_THREADS:-$cpu_threads}
    export TORCHINDUCTOR_COMPILE_THREADS=${TORCHINDUCTOR_COMPILE_THREADS:-4}
    export TOKENIZERS_PARALLELISM=${TOKENIZERS_PARALLELISM:-false}
    mkdir -p "$MPLCONFIGDIR"
    cd "$repo_root"
}
