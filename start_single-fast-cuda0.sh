#!/bin/bash
# Single-user, CTX=fast (SPEC=dflash2) on CUDA device 0, port 18000.
# Bash twin of the Windows start_single-fast-cuda0.bat.
# The shared auth key is what <repo>/api_key.txt holds (gitignored; the
# launcher reads it automatically) - no key is written in any script.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$DIR/start-single.sh" fast 0
