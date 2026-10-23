#!/bin/bash
# start-single.sh — single-user Qwen3.8-257B server on one pinned CUDA device.
#
# Bash twin of the Windows start-single.bat from the sibling checkout
# (../hyperqwen_mod); the six start_single-*.sh scripts next to this one
# mirror the start_single-*.bat set, one per (context, device) pair.
#
#   usage:  start-single.sh <fast|long> <0|1|2>
#
#   fast  ->  CTX=fast  (64k context, bf16 KV)     SPEC=dflash2
#   long  ->  CTX=long  (~150k context, fp8 KV;   SPEC=mtp
#             int8 via PTH_FA on the 3090s when the package is in the venv)
#
#   ports:  fast 18000/18001/18002   long 18010/18011/18012
#           (18000 + 10*is_long + device)
#
# The key: this script contains none and prints none. The server's auth key is
# what <repo>/api_key.txt holds (gitignored; read automatically by
# resolve_vllm_key in resolve_api_key.sh) - the single "common" key, since
# clients fall back to the same file. A VLLM_API_KEY already exported in the
# environment wins over the file, per the launcher's documented precedence.
#
# .env: when it sits next to this script it is sourced first (everything
# exported) to carry the shared settings the docker flow uses - BIND,
# PREFIX_CACHE, INT8_ACT, PREFILL_ATTN, VLLM_WSL2_ENABLE_PIN_MEMORY, ... It
# deliberately holds no key any more (see the comment inside it). The variables
# this script sets afterwards (CTX, SPEC, PORT, CUDA_VISIBLE_DEVICES, HOST,
# BIND) always win over .env.
#
# CUDA_VISIBLE_DEVICES here is a CUDA *index*, not a UUID. CUDA numbers the
# cards fastest-first, so on a mixed 3090/4070 box the index can disagree with
# nvidia-smi's order: `nvidia-smi -L` shows names/UUIDs, and exporting
# CUDA_DEVICE_ORDER=PCI_BUS_ID before running makes the indices match
# nvidia-smi. That is also why this family has three device variants - start
# one and see which card it grabs.
#
# CUDA_HOME is deliberately not pinned: start_qwen.sh auto-detects the CUDA
# toolchain inside the venv (the .bat's explicit CUDA_HOME pin existed only
# because its WSL venv had a system nvcc that was too old).

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TYPE=${1:-}
GPU=${2:-}
case "$TYPE" in
  fast|long) ;;
  *) echo "usage: start-single.sh <fast|long> <0|1|2>" >&2; exit 1 ;;
esac
case "$GPU" in
  0|1|2) ;;
  *) echo "error: device number must be 0, 1 or 2 (got '$GPU')" >&2; exit 1 ;;
esac

# --- 1. shared settings ---------------------------------------------------------
# Source the .env when present (CR-stripped: the repo forces LF via
# .gitattributes, so this is belt and braces) with everything exported.
if [ -f "$DIR/.env" ]; then
  set -a
  . <(sed 's/\r$//' "$DIR/.env")
  set +a
else
  echo "start-single: no .env next to the scripts - using launcher defaults." >&2
fi

# --- 2. per-server identity (wins over .env and the environment) ----------------
if [ "$TYPE" = fast ]; then
  CTX=fast        # 64k context, bf16 KV
  SPEC=dflash2    # the start-single.bat pairing
  PORT=$((18000 + GPU))
else
  CTX=long        # ~150k context, fp8 KV (PTH_FA=1 int8 on sm86 when installed)
  SPEC=mtp
  PORT=$((18000 + 10 + GPU))
fi
# Optional, fast arm only: a 16-token verification block (15 + 1) for
# quote/paraphrase-heavy workloads - the .bat had it commented out as well.
#   DFLASH_TOKENS=15
CUDA_VISIBLE_DEVICES=$GPU     # index pin; overrides the .env UUID pin
HOST=0.0.0.0                  # explicit bind; the launcher's resolve_bind_host honors it
BIND=0.0.0.0                  # .env/compose-side twin of the same bind

# --- 3. key guard -----------------------------------------------------------------
# No key anywhere and a network bind = open server: refuse (the launcher would
# only warn; the .bat family refused).
if [ -z "${VLLM_API_KEY:-}" ] && [ ! -s "$DIR/api_key.txt" ]; then
  echo "start-single: no API key found (neither VLLM_API_KEY nor $DIR/api_key.txt);" >&2
  echo "  with the 0.0.0.0 bind that would be an open server. Create the key file:" >&2
  echo "  openssl rand -hex 24 > $DIR/api_key.txt" >&2
  exit 1
fi
if [ -n "${VLLM_API_KEY:-}" ]; then
  KEY_SRC="VLLM_API_KEY from the environment"
else
  KEY_SRC="api_key.txt (repo root)"
fi

# --- 4. banner + handover ----------------------------------------------------------
export CTX SPEC PORT CUDA_VISIBLE_DEVICES HOST BIND
[ -n "${VLLM_API_KEY:-}" ] && export VLLM_API_KEY

echo "============================================"
echo " Qwen3.8-257B single-user server"
echo "   CUDA device : $GPU   (an index - check with nvidia-smi -L)"
echo "   CTX / SPEC  : $CTX / $SPEC"
echo "   port        : $PORT   (bind $HOST)"
echo "   key         : $KEY_SRC"
echo "============================================"
echo "Starting... (~90s to ready; Ctrl-C stops the server)"
echo

# The venv launcher does the model selection, the KV/attention backend and the
# vllm serve itself; it lives next to this script in the same checkout.
exec bash "$DIR/single-user/start_qwen.sh"
