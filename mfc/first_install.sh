#!/bin/bash
set -euo pipefail

# Create the env if it doesn't exist, add specs, then concretize and install
make_env() {
    local name=$1; shift
    if ! spack env list | grep -w "$name" > /dev/null; then
        spack env create "$name"
    fi
    spack -e "$name" add "$@"
    spack -e "$name" concretize -f
    spack -e "$name" install
}

# GPU Dependencies
make_env gpu nvhpc@25.9 "openmpi@5.0.10+cuda %nvhpc@25.9"

# CPU Dependencies
# Double check there's no overlap with another group!
make_env cpu gcc@13.3.0 "openmpi@5.0.10 %gcc@13.3.0"
