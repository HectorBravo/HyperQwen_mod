<!-- PROJECT_INDEXER:BEGIN
project: HyperQwen
last_indexed: 2026-08-10 03:20:00
git_head: 38ac264701cfc76264f77507722921c3efea30c9
repo_url: https://github.com/HectorBravo/HyperQwen_mod
PROJECT_INDEXER:END -->

# HyperQwen — Project Map for AI Agents

## 1. Overview

**HyperQwen** serves the Qwen3.8-27B (27B parameter) LLM on a single 24 GB consumer GPU
(RTX 3090 / RTX 4090) using a patched vLLM 0.30.0 stack. It provides two serving modes:

- **Single-user** (low-latency): ~127 tok/s single-stream, 64k context (fast) or 150k (long)
- **Batch** (throughput): ~1,000+ tok/s aggregate at 64 concurrent requests, 150k context

The repo is a **patch series against a pinned vLLM** plus a model-preparation pipeline
(requantized heads, calibrated draft vocabulary, speculative decoding with MTP).
It also supports KVarN 4/2-bit KV cache for 240k+ context.

## 2. Technology Stack

| Layer | Technology |
|-------|-----------|
| Language | Python 3.14 (venv), Bash scripts |
| Inference engine | vLLM 0.30.0 (patched via `patches/`) |
| GPU runtime | CUDA 13 (in-venv `nvidia/cu13`), FlashInfer, Triton |
| Model | Qwen3.8-27B W4A16-AutoRound (int4 weights) |
| Speculation | MTP (multi-token prediction) head, DFlash2 |
| KV cache | bf16 (fast), fp8 (long), KVarN 4/2-bit (huge) |
| Serving | OpenAI-compatible HTTP API (`/v1/chat/completions`) |
| Container | Docker + docker-compose (single / batch profiles) |
| Windows | `.bat` launchers calling WSL2 (Ubuntu-26.04) |

## 3. Directory Map

```
HyperQwen_mod/
├── AGENTS.md                    # AI agent enforcement contract
├── README.md                    # Main project README (overview, quick start, roadmap)
├── Makefile                     # Docker compose shortcuts (up-single, up-batch, keygen, doctor…)
├── Dockerfile                   # Multi-stage build (venv + patches + model prepare)
├── docker-compose.yml           # Single/batch service definitions
├── .env.example                 # Template for .env (Docker Compose config)
├── .gitignore                   # Ignores: venv, models, api_key.txt, .env, .bat launchers
├── resolve_api_key.sh           # Shared key resolver (VLLM_API_KEY > api_key.txt)
├── resolve_config.sh            # Config validator (CTX/SPEC/KV/EXTRA_ARGS)
├── launcher_common.sh           # Shared launcher functions (resolve_bind_host, qwen_exec)
├── verify.sh                    # Install + runtime verification script
├── api_key.txt                  # LOCAL ONLY (gitignored): VLLM API key for native launchers
├── start-single.bat             # Windows launcher: single-user (parameterized fast/long, GPU)
├── start_single-*.bat           # Windows launchers: per-GPU per-CTX shortcuts (7 files)
│
├── single-user/
│   ├── start_qwen.sh            # Main single-user launcher (MTP speculation, CTX=fast/long/huge)
│   ├── qwen-server.sh           # Systemd-style server wrapper
│   ├── alternative.sh           # Alternate boot (DFlash2 profile, .env-driven)
│   ├── select_model.sh          # Model path resolution (fast variant vs base)
│   └── README.md
│
├── batch/
│   ├── start_qwen.sh            # Batch-mode launcher (throughput, W4A8 Marlin)
│   └── README.md
│
├── bench/
│   ├── run_benchmarks.sh        # Benchmark orchestration
│   ├── api_smoke.py             # API smoke test
│   ├── test_no_key_bind.sh      # Key/bind-host logic test
│   ├── warmup.sh               # Server warmup
│   ├── conc_ladder.py, concurrent_collapse.py, …  # Performance/quality scripts
│   ├── demo/                    # Benchmark demo video build
│   └── README.md
│
├── prepare/                     # One-time model preparation (requantization)
│   └── README.md
│
├── drafter/                     # Draft vocabulary / int4 drafter construction
│   └── README.md
│
├── kvarn/                       # KVarN 4/2-bit KV cache port
│   ├── install.sh
│   └── README.md
│
├── patches/                     # vLLM patches (applied in order by patches/apply.sh)
│   ├── apply.sh
│   ├── check_vllm_series.sh
│   ├── spec-decode-attn.patch
│   ├── marlin-int8-layer-select.patch
│   └── …
│
├── scripts/
│   ├── hq-doctor.sh             # Read-only diagnostic (config + GPU + port + /health)
│   ├── port-drift.sh
│   └── port-triage.sh
│
├── docker/
│   ├── entrypoint.sh            # Container entrypoint
│   └── prepare.sh
│
├── docs/                        # 18 detailed documentation files
│   ├── quickstart.md, install.md, docker.md, clients.md, gotchas.md
│   ├── optimizations.md, benchmarks.md, quality.md, long-context.md
│   ├── multi-gpu.md, wsl2-4090.md, ubuntu-3090.md, python-314.md
│   ├── vllm-0.29.md, vllm-0.30.md, third-party-checkpoints.md
│   ├── spec-decode-scratch-token-units.md, main-track.md
│   └── reproductions/
│
└── ai/
    ├── PROJECT_DESCRIPTION.md   # THIS FILE (agent-optimized project map)
    └── AI_TASKLOG.md            # AI task progress log
```

## 4. Entry Points

| Mode | Entry Point | Description |
|------|------------|-------------|
| Docker single-user | `docker compose --profile single up -d` | Containerized, `.env`-driven |
| Docker batch | `docker compose --profile batch up -d` | Containerized, high-throughput |
| Native single-user | `bash single-user/start_qwen.sh` | Venv-based, env-var driven |
| Native batch | `bash batch/start_qwen.sh` | Venv-based, env-var driven |
| Windows (single-user) | `start-single.bat <fast\|long> <0\|1\|2>` | Calls WSL2 → `start_qwen.sh` |
| Windows (per-GPU) | `start_single-{fast,long}-cuda{0,1,2}.bat` | Pre-configured WSL2 launchers |
| Systemd | `single-user/qwen-server.sh` | Production server wrapper |


## 5. Build / Run / Test Commands

`ash
# --- Docker (canonical) ---
make up-single          # single-user mode (pulls image, prepares model, serves)
make up-batch           # batch mode
make down               # stop
make logs               # follow logs
make ps                 # container state
make doctor             # read-only diagnostic
make keygen             # generate VLLM_API_KEY into .env
make verify             # full verification in container
make verify-install     # install-only checks (no GPU)

# --- Native (venv) ---
# Prerequisites: venv/ with vLLM 0.30.0 + patches applied, model in models/
bash single-user/start_qwen.sh          # single-user (CTX=fast default)
CTX=long bash single-user/start_qwen.sh # 150k context, fp8 KV
CTX=huge bash single-user/start_qwen.sh # 240k context, KVarN
bash batch/start_qwen.sh                # batch mode
bash verify.sh                          # verify install + runtime
bash verify.sh --install                # install checks only

# --- Dry run (no GPU needed) ---
PRINT_ARGV=1 bash single-user/start_qwen.sh   # print argv, exit 0
PRINT_ARGV=1 bash batch/start_qwen.sh

# --- Windows (WSL2) ---
start-single.bat long 2        # CTX=long, GPU=2, port=18012
start-single.bat fast 0        # CTX=fast, GPU=0, port=18000

# --- Benchmarks ---
venv/bin/python bench/api_smoke.py
bash bench/run_benchmarks.sh
bash bench/test_no_key_bind.sh
`

## 6. Architecture and Key Flows

### Boot sequence (single-user/start_qwen.sh)

1. Resolve REPO (parent of script dir), cd into it
2. Set CUDA_HOME if system nvcc is < 13 (FlashInfer JIT needs CUDA 13)
3. Source resolve_config.sh, resolve_effective_config single (validates CTX/SPEC/KV)
4. Source launcher_common.sh, resolve_bind_host (HOST or auto: key means 0.0.0.0, no key means 127.0.0.1)
5. Source resolve_api_key.sh, resolve_vllm_key (VLLM_API_KEY env takes precedence over api_key.txt)
6. Source select_model.sh, pick model dir (fast variant if exists, else base)
7. qwen_exec venv/bin/vllm serve with --host --port --gpu-memory-utilization etc.

### Key resolution (resolve_api_key.sh)

Precedence: VLLM_API_KEY env, then api_key.txt file, then no key.
- resolve_vllm_key(): server side. Exports VLLM_API_KEY from file if env is empty.
- resolve_client_key(): client side. Exports OPENAI_API_KEY (env > VLLM_API_KEY > file > EMPTY).

### Bind host logic (launcher_common.sh)

- Explicit HOST env: use it (warn if no key and HOST is not loopback)
- No HOST + key present: bind 0.0.0.0
- No HOST + no key + in container: bind 0.0.0.0 (warn)
- No HOST + no key + native: bind 127.0.0.1 (safe default)

### Windows .bat launcher flow

start-single.bat <type> <gpu> calculates PORT = 18000 + (10 if long) + gpu, sets CTX/KV_TYPE, then calls wsl to run start_qwen.sh. The key is read from api_key.txt by resolve_vllm_key inside start_qwen.sh, not hardcoded in the .bat.
## 7. Configuration and Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| CTX | fast | Context profile: fast (64k/bf16), long (150k/fp8), huge (240k/KVarN) |
| SPEC | mtp | Speculation: mtp, dflash2, or empty (none) |
| KV | (auto) | KV cache dtype override |
| HOST | (auto) | Bind address override |
| PORT | 18020 | Server port |
| VLLM_API_KEY | (api_key.txt) | API key for auth |
| CUDA_HOME | (auto-detect) | CUDA toolkit path |
| GPU_UTIL | 0.93 (WSL2) / 0.95 (native) | GPU memory utilization |
| VLLM_WSL2_ENABLE_PIN_MEMORY | 1 (WSL2) | WSL2 pin-memory workaround |
| PRINT_ARGV | 0 | 1 = dry run (print argv, exit) |
| MAX_SEQS | 8 | Max concurrent sequences |
| INT8_ACT / INT8_LAYERS | (empty) | W4A8 Marlin activation quantization |
| SSE_KEEP_ALIVE | 30 | SSE keep-alive interval (seconds) |
| VLLM_OFFLOAD_KEEP_SHM | 0 | Skip stale /dev/shm cleanup |
| FLASHINFER_DISABLE_VERSION_CHECK | 1 | Bypass FlashInfer version check |
| EXTRA_ARGS | (empty) | Additional vLLM CLI arguments |
| MODEL | (auto-select) | Override model path |

## 8. Dependencies

| Type | Name | Location |
|------|------|----------|
| System (native) | Python 3.14, CUDA 13 toolkit (in venv), NVIDIA driver | WSL2 / native Linux |
| System (Docker) | Docker, NVIDIA Container Toolkit | Host |
| Manifest | vLLM 0.30.0, flashinfer-python, torch, triton, compressed_tensors | venv/ (not committed) |
| Pinned | patches/ (applied to vLLM source) | patches/apply.sh |
| Data | Qwen3.8-27B-W4A16-AutoRound (+ fast variant) | models/ (gitignored, ~20 GB) |
| Local | api_key.txt | repo root (gitignored) |
| Local | venv (symlink or real) | repo root (gitignored) |
| Local | .env | repo root (gitignored, Docker Compose) |
## 9. Conventions and Gotchas

- Branching: AI agents use <type>/ai-<description> branches. Never push to main directly.
- Git identity: GIT_AUTHOR_NAME=AI_bot, email from user git config.
- Commit messages: <type>(<scope>): [ai] <description> - the [ai] tag is mandatory.
- Secrets: api_key.txt and .env must never be committed. The .gitignore protects them.
- .bat launchers: Local Windows artifacts calling WSL2. Must NOT contain the API key (use api_key.txt instead). On main they are committable; on the feature branch they are gitignored.
- vLLM pinning: Patches are written against vLLM 0.30.0. Do not upgrade without re-testing.
- CUDA_HOME: On WSL2 the in-venv CUDA 13 at venv/lib/python3.14/site-packages/nvidia/cu13 is correct. The FlashInfer cu13 link shim creates symlinks for libcudart.so and stubs/libcuda.so if missing.
- One GPU per mode: A single GPU runs either single-user OR batch, not both.
- First boot: 2-15 min (model download + requantization + torch.compile + CUDA graphs).

## 10. Recent Changes (this session)

- FlashInfer cu13 link shim added to single-user/start_qwen.sh (feature branch fix/ai-flashinfer-cu13-link-shim, commit 2130381).
- .gitignore hardened to ignore launcher .bat files (feature branch, commit 719ccd8).
- api_key.txt created locally with the real key (gitignored).
- start-single.bat and start_single-*.bat cleaned: key removed, now relies on api_key.txt via resolve_api_key.sh.
- ai/PROJECT_DESCRIPTION.md and AGENTS.md created (this indexing).

## 11. Change Log (last few refreshes)
- 2026-08-10 - Initial project map. Added api_key.txt-based key flow, Windows .bat launcher documentation, FlashInfer cu13 shim context.