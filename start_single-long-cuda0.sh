#!/bin/bash
# Single-user, CTX=long (SPEC=mtp) on CUDA device 0, port 18010.
# Bash twin of the Windows start_single-long-cuda0.bat.
# The shared auth key is what <repo>/api_key.txt holds (gitignored; the
# launcher reads it automatically) - no key is written in any script.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$DIR/start-single.sh" long 0
