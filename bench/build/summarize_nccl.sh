#!/usr/bin/env bash
# summarize.sh - Summarize nccl-tests logs into a results table.
#
# Usage:
#   ./summarize.sh                       # logs in ~/nccl/results
#   PEAK=450 ./summarize.sh              # also compute % of theoretical peak (GB/s)
#   R=/path/to/logs PEAK=450 ./summarize.sh
#
# Only OUT-OF-PLACE columns are used. Columns are counted from the end of each
# row so the script works whether or not the log has a "redop" column:
#   ... | out-of-place: time algbw busbw #wrong | in-place: time algbw busbw #wrong
#         NF-7          NF-6  NF-5  NF-4          NF-3       NF-2  NF-1  NF

set -euo pipefail

R="${R:-$HOME/nccl/results}"
PEAK="${PEAK:-}"
COLLS="all_reduce all_gather reduce_scatter broadcast"

cd "$R"

echo "Log directory: $R"
echo

# ---------- Latency: 8-byte out-of-place time, across the 3 repeats ----------
echo "LATENCY (smallest non-zero message, out-of-place, time in us)"
printf "%-16s %10s %10s %10s   %s\n" "collective" "min" "mean" "max" "runs"
for c in $COLLS; do
  vals=""
  for f in ${c}_latency_*.log; do
    [ -f "$f" ] || continue
    v=$(awk '/^[[:space:]]*[0-9]/ && $1>0 {print $(NF-7); exit}' "$f")
    sz=$(awk '/^[[:space:]]*[0-9]/ && $1>0 {print $1; exit}' "$f")
    [ -n "$v" ] && vals="$vals $v"
  done
  if [ -z "$vals" ]; then
    printf "%-16s %s\n" "$c" "no data"
    continue
  fi
  echo "$vals" | awk -v c="$c" -v sz="$sz" '{
    n=NF; min=$1; max=$1; s=0
    for(i=1;i<=NF;i++){ s+=$i; if($i<min)min=$i; if($i>max)max=$i }
    runs=""; for(i=1;i<=NF;i++) runs=runs $i (i<NF?", ":"")
    printf "%-16s %10.2f %10.2f %10.2f   %s (at %s B)\n", c, min, s/n, max, runs, sz
  }'
done
echo

# ---------- Bandwidth: peak out-of-place busbw in the large-message run ----------
echo "BANDWIDTH (out-of-place busbw, GB/s, from *_bw.log)"
if [ -n "$PEAK" ]; then
  printf "%-16s %12s %14s %12s %12s\n" "collective" "peak busbw" "at size (B)" "algbw there" "% of peak"
else
  printf "%-16s %12s %14s %12s\n" "collective" "peak busbw" "at size (B)" "algbw there"
fi
for c in $COLLS; do
  f="${c}_bw.log"
  [ -f "$f" ] || { printf "%-16s %s\n" "$c" "missing $f"; continue; }
  awk -v c="$c" -v peak="$PEAK" '
    /^[[:space:]]*[0-9]/ {
      bw=$(NF-5); if (bw+0 > best+0) { best=bw; size=$1; alg=$(NF-6) }
    }
    END {
      if (best=="") { printf "%-16s no data\n", c; exit }
      if (peak!="") printf "%-16s %12.2f %14d %12.2f %11.1f%%\n", c, best, size, alg, 100*best/peak
      else          printf "%-16s %12.2f %14d %12.2f\n", c, best, size, alg
    }' "$f"
done
echo

# ---------- Correctness: #wrong in the -c 1 runs ----------
echo "CORRECTNESS (from *_check.log and smoke.log)"
printf "%-16s %12s %s\n" "log" "sum #wrong" "footer"
for f in smoke.log *_check.log; do
  [ -f "$f" ] || continue
  awk -v f="$f" '
    /^[[:space:]]*[0-9]/ { w += $(NF-4) + $NF; rows++ }
    /Out of bounds/      { foot=$0 }
    END { sub(/^# */, "", foot); printf "%-16s %12d %s (rows: %d)\n", f, w, foot, rows }
  ' "$f"
done
echo

# ---------- Which NCCL / transport was used ----------
echo "NCCL VERSION lines:"
grep -h -m1 -i "nccl version" smoke.log 2>/dev/null || echo "  (not found in smoke.log; rerun with NCCL_DEBUG=INFO)"
echo
echo "Transport hints in smoke.log (look for P2P / NVL, not SHM or NET):"
grep -h -iE "via P2P|NVL|via SHM|via NET|P2P/" smoke.log 2>/dev/null | head -n 8 || true
echo
echo "NOTE: in the sweep logs, the footer 'Avg bus bandwidth' averages ALL sizes"
echo "      (including tiny ones) and is NOT the bandwidth you should report."
