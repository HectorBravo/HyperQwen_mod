# Native launchers on WSL2 — the venv playbook

Short, practical notes for running the `start_single-*` launchers (the native
path, **no Docker**) from a WSL distro. Assumes WSL + the distro already exist
and NVIDIA's GPU support in WSL works (`nvidia-smi` inside WSL succeeds).

This is what it took to get this box (WSL2, Ubuntu 26.04, mixed RTX 3090/4070)
serving vLLM **0.33** natively. The upstream `docs/install.md` is the full
reference; this file records the repo-specific parts and the two extra steps
that are easy to miss (and must be repeated on every version bump or new box).

## What the launchers need

The `.bat`/`.sh` launchers (`start_single-{fast,long}-cuda{0,1,2}` →
`start-single.{bat,sh}` → `single-user/start_qwen.sh`) run
`venv/bin/vllm serve` directly. They expect, **in the repo root**:

| Path | What it is |
|---|---|
| `venv/` | symlink → `$HOME/hyperqwen/venv` (the Python env; see below) |
| `models/` | symlink → `/mnt/c/ai_models` (checkpoints, shared with the target box) |
| `.env` | copy of `.env.example` + your `VLLM_API_KEY`, `PORT`, GPU pin (see below) |
| `api_key.txt` | optional; holds the same key. Without any key the launcher binds `127.0.0.1` only |

Ports: `fast` → 18000/18001/18002, `long` → 18010/18011/18012
(`18000 + 10·is_long + gpu_index`). `cuda2` is the RTX 4070 here — it OOMs; use
`cuda0`/`cuda1`.

## The venv (one-time, per machine)

```bash
# 1. apt prerequisites (Ubuntu 26.04 = Python 3.14)
sudo apt-get install -y python3.14-venv python3.14-dev build-essential git

# 2. fresh venv + the pinned stack (pins must match docker/requirements.txt; docs/install.md)
python3 -m venv ~/hyperqwen/venv
~/hyperqwen/venv/bin/pip install --upgrade pip
~/hyperqwen/venv/bin/pip install vllm==0.33.0 huggingface_hub hf_transfer ninja \
  --extra-index-url https://flashinfer.ai/whl/ flashinfer-cubin==0.7.2.post1 pandas \
  nvidia-cuda-nvcc==13.0.88 nvidia-cuda-crt==13.0.88 nvidia-cuda-cccl==13.0.85 nvidia-nvvm==13.0.88
```

> On a vLLM version bump, take the new pins from `docs/install.md` /
> `docker/requirements.txt` (the `vllm==`, `flashinfer-cubin==` and the four
> `nvidia-*` nvcc pins all move together). **Build a new venv; never upgrade in
> place** (docs/install.md, "Upgrading from an earlier pin").

## The two extra steps docs/install.md does not mention  ← important

### A. cu13 link shims (FlashInfer JIT dies without them)

`start_qwen.sh` points `CUDA_HOME` at the venv's nvcc
(`venv/lib/python3.*/site-packages/nvidia/cu13`). FlashInfer's JIT links with
`-L$CUDA_HOME/lib64 -L$CUDA_HOME/lib64/stubs -lcudart -lcuda`, but pip's CUDA 13
packages ship the libs under `lib/` (not `lib64/`) and without dev symlinks →
`ld: cannot find -lcudart / -lcuda; collect2: ld returned 1 exit status` on the
first fp8-KV boot (`CTX=long`). Fix once per venv:

```bash
CU=$(~/hyperqwen/venv/bin/python -c 'import os,nvidia.cu13 as c; print(c.__path__[0])' 2>/dev/null || \
    echo ~/hyperqwen/venv/lib/python3.14/site-packages/nvidia/cu13)
ln -sf libcudart.so.13 "$CU/lib/libcudart.so"
mkdir -p "$CU/lib/stubs"
ln -sf /usr/lib/wsl/lib/libcuda.so.1 "$CU/lib/stubs/libcuda.so"   # WSL driver stub
ln -sfn lib "$CU/lib64"                                            # FlashInfer wants lib64
```

(If a failed boot left a half-built kernel behind, `rm -rf ~/.cache/flashinfer`
before the next start.)

### B. Repo patches + xgrammar (must be re-run after every venv rebuild)

```bash
cd /path/to/HyperQwen_mod
SP=$(~/hyperqwen/venv/bin/python -c 'import vllm, os; print(os.path.dirname(vllm.__file__))' 2>/dev/null | tail -n1)
bash patches/apply.sh "$SP"        # refuses --fuzz 0 mismatches; rerun is a no-op when already applied
bash xgrammar/install.sh           # bounded-string fix for Qwen tool calls (needs build-essential)

# sanity gate — must end with "verify: OK (0 failures)"
bash verify.sh --no-server
```

## `.env` essentials (repo root, gitignored)

```bash
VLLM_API_KEY=<your key>            # required for the 0.0.0.0 bind the launchers use
CUDA_DEVICE_ORDER=PCI_BUS_ID       # makes CUDA index == nvidia-smi index on mixed-card boxes
# Do NOT put CUDA_VISIBLE_DEVICES in .env: the native launchers source .env and would
# inherit it, hiding the other cards (each start_single-* launcher pins its own GPU).
# It is only needed for Docker runs — pass it inline there instead.
# PORT=18031                       # only if 18020 is taken (Windows iphlpsvc can leak it)
```

The launcher's own `CTX`/`SPEC`/`PORT`/GPU overrides win over `.env`, so the
`.env` GPU pin only steers defaults, never breaks a specific launcher.

## Launching

```bat
start_single-long-cuda0.bat        :: CTX=long SPEC=mtp, 3090 #1, port 18010
```

First boot after a fresh venv (or a cleared `~/.cache/vllm`) is slower — torch
compile + CUDA-graph capture + one-time FlashInfer JIT. Ctrl-C stops the server.

## Gotchas we hit (and their fixes)

| Symptom | Cause → Fix |
|---|---|
| `ld: cannot find -lcudart / -lcuda` on first `CTX=long` boot | step A above (lib64/dev-symlink shims) |
| Server lands on the 4070 and OOMs at load | CUDA numbers fastest-first → `CUDA_DEVICE_ORDER=PCI_BUS_ID` (in `.env` is fine — it's index-order only, not a pin); each launcher pins its own GPU via `CUDA_VISIBLE_DEVICES` |
| Launcher dies instantly with a stale `CUDA_HOME` | don't pin `CUDA_HOME` in the `.bat`; `start_qwen.sh` auto-detects the venv's nvcc (fixed in commit `189634b`) |
| Port 18020 bound by `svchost` (iphlpsvc) before WSL starts | Windows leak; only a host reboot clears it → use `PORT=18031` until then |
| WSL distro vanishes mid-operation (long builds) | don't run heavy steps from an ephemeral session — nohup/setsid them, or keep any window open |

## New-box checklist (what actually differs per machine)

1. `apt-get install python3.14-venv python3.14-dev build-essential git`
2. venv + pinned pip line (pins from this version's docs/install.md)
3. **cu13 shims** (step A — the one people forget; nothing else warns you)
4. `patches/apply.sh` + `xgrammar/install.sh` + `verify.sh --no-server`
5. repo symlinks (`venv`, `models`) + `.env` / `api_key.txt`
6. launch, expect a slow first boot

Everything else in the repo is portable as-is.
