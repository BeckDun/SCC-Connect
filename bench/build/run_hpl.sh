#!/bin/bash
# Before: chmod +x run_hpl.sh
# Usage: ./run_hpl.sh [N] [NB] [P] [Q]
# Any argument you omit is read from HPL.dat in the current directory.
# Output file: hpl_N<N>_NB<NB>_<P>x<Q>_<MonDD>.out  (e.g. hpl_N312000_NB384_8x8_Sep30.out)
#
# Assumes HPL.dat has single values for N, NB, P and Q (the standard layout:
# line 6 = N, line 8 = NB, line 11 = P, line 12 = Q).

set -euo pipefail

XHPL="${XHPL:-/home/amberks123/spack-installs/linux-sapphirerapids/hpl-2.3-2tsuypsrfj4zgl7j5nwe6vitusz62yux/bin/xhpl}"   # override with: XHPL=/path/to/xhpl ./run_hpl.sh
TEMPLATE="${TEMPLATE:-$PWD/HPL.dat}"

spack load /2tsuyps

# Defaults from HPL.dat, overridden by command-line args
N="${1:-$(sed -n '6p'  "$TEMPLATE" | awk '{print $1}')}"
NB="${2:-$(sed -n '8p'  "$TEMPLATE" | awk '{print $1}')}"
P="${3:-$(sed -n '11p' "$TEMPLATE" | awk '{print $1}')}"
Q="${4:-$(sed -n '12p' "$TEMPLATE" | awk '{print $1}')}"
NP=$((P * Q))

DATE=$(date +%b%d)               # month + day, e.g. Sep30
LABEL="N${N}_NB${NB}_${P}x${Q}_${DATE}"
OUTFILE="$PWD/hpl_${LABEL}.out"

# Don't overwrite an earlier run with the same label
if [[ -e "$OUTFILE" ]]; then
    OUTFILE="$PWD/hpl_${LABEL}_$(date +%H%M).out"
fi

# Run in its own directory with a modified copy of HPL.dat
RUNDIR="$PWD/runs/$(basename "${OUTFILE%.out}")"
mkdir -p "$RUNDIR"
sed -e "6s/^[^ ]*/${N}/" \
    -e "8s/^[^ ]*/${NB}/" \
    -e "11s/^[^ ]*/${P}/" \
    -e "12s/^[^ ]*/${Q}/" \
    "$TEMPLATE" > "$RUNDIR/HPL.dat"

# One thread per rank, one rank per physical core
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

{
    echo "=== HPL run: N=$N NB=$NB PxQ=${P}x${Q} ranks=$NP date=$(date) host=$(hostname) ==="
    echo "=== xhpl: $XHPL ==="
    echo "=== load at start: $(uptime) ==="
    echo
    cd "$RUNDIR"
    mpirun -np "$NP" --map-by core --bind-to core --report-bindings \
        -x OMP_NUM_THREADS -x MKL_NUM_THREADS \
        "$XHPL"
    echo
    echo "=== finished: $(date) ==="
} 2>&1 | tee "$OUTFILE"

echo "Output saved to $OUTFILE"
