#!/bin/bash
set -euo pipefail

# !>!>!>   \/ \/ \/  Change the username and paraview path (remove the angle brackets)
SSH_HOST="<username>@global.prd.ga.launchpad.nvidia.com"
PARAVIEW=<replaceMe>/ParaView-6.2.0-MPI-Linux-Python3.12-x86_64/bin/paraview
SSH_PORT=12986
LOCAL_PORT=22222
REMOTE_PORT=11111
CTRL_SOCK="/tmp/pv-tunnel-$$.sock"

ssh -f -N \
    -o ExitOnForwardFailure=yes \
    -M -S "$CTRL_SOCK" \
    -p "$SSH_PORT" \
    -L "${LOCAL_PORT}:localhost:${REMOTE_PORT}" \
    "$SSH_HOST"

trap 'ssh -S "$CTRL_SOCK" -O exit "$SSH_HOST" 2>/dev/null || true' EXIT

"$PARAVIEW" --url=cs://localhost:${LOCAL_PORT}

for _ in {1..20}; do
    ss -ltn "sport = :$LOCAL_PORT" | grep -q LISTEN && break
    sleep 0.5
done

