# AI Tasks Log

## Summary

| Created | Task | Status | Type | Subtasks | Time Spent | Blockers |
|---------|------|--------|------|----------|------------|----------|
| 23-10-2026 15:23:00 | [T4: Single-GPU Linux/bash launcher set (fast/long × cuda 0/1/2)](#task-t4-single-gpu-linux-bash-launcher-set-fastlong--cuda-012) | <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span> | <span style="background-color:#22863a;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">feat</span> | 7/12 | 1h 34m | none |
| 11-10-2026 23:36:00 | [T3: Provision second node (192.168.2.196) with wsl_migrate + long-context vLLM](#task-t3-provision-second-node-1921682196-with-wsl_migrate--long-context-vllm) | <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span> | <span style="background-color:#22863a;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">feat</span> | 1/10 | 12m | none |
| 08-10-2026 02:25:40 | [T1: Migrate HyperQwen Windows launchers to fork + re-apply FlashInfer cu13 link shim](#task-t1-migrate-hyperqwen-windows-launchers-to-fork--re-apply-flashinfer-cu13-link-shim) | <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span> | <span style="background-color:#9e6a03;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">fix</span> | 9/10 | 28m | none |

> **1 completed task(s)** — [View completed tasks](#completed-tasks)

---

## Task T4: Single-GPU Linux/bash launcher set (fast/long × cuda 0/1/2)

- **Status**: <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span>
- **Type**: <span style="background-color:#22863a;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">feat</span>
- **Created**: 23-10-2026 15:23:00
- **Last Updated**: 23-10-2026 16:57:35
- **Time Spent**: 1h 34m
- **Branch**: [`feat/ai-single-gpu-bash-launchers`](https://github.com/HectorBravo/HyperQwen_mod/tree/feat/ai-single-gpu-bash-launchers) — to be rebuilt on top of the fork's `main` (`493818e`); the 7 scripts will be restored from commit `b87c01e`
- **Commit(s)**: pending
- **Blockers**: none (3 user confirmations pending; none block the push)
- **Findings & Notes**:
  - Bash twins of the 7 `.bat` launchers already committed on `main`: master `start-single.sh` + 6 wrappers `start_single-{fast,long}-cuda{0,1,2}.sh`. Same scheme: PORT = 18000 + 10×is_long + gpu_idx (fast → 18000/18001/18002; long → 18010/18011/18012), per-run CTX/SPEC override; the `.bat` passes `type gpu` to `start-single.bat`, the `.sh` hardcodes it in the wrapper.
  - All 7: LF, no BOM, `bash -n` clean (WSL Ubuntu-26.04); misuse (bad CTX / bad GPU / no args) prints usage and exits before the real launcher runs.
  - **No key material in any committed file**: the key resolves at runtime via the existing chain (`.env` → env → gitignored `api_key.txt`). The 48-char key exists only in the user-local untracked `vllm_api_key.env.bak`; the shared 35-char key stays in `api_key.txt`. The fork's `main` does **not** track `.env` (only `.env.example`), so nothing secret rides this branch.
  - The clone was re-pointed this session: origin → `git@github.com:HectorBravo/HyperQwen_mod.git` (SSH), local `main` reset onto the fork's `main` (`493818e`). The old upstream-lineage main (`e5270a2`, 2 log-only commits) is preserved at `backup/pre-repoint-main`; the old feature branch (`b87c01e`) at `backup/old-single-gpu-branch`.
  - Pre-existing quirk (left untouched): the Summary lists T1 (in_progress, 9/10) but the file body has no `## Task T1` section (it only holds T3 → Completed(T2) → T2). Not fixed here — flagged for the owner.
  - File mechanics: pure LF, zero CRs (`.gitattributes` forces `* text=auto eol=lf`); `Measure-Object -Line` reports 190 for this file, which is the *non-blank* count (66 blanks) — the file has 255 LF lines.

### User Confirmations

**Pending (awaiting user response):**

- [ ] (23-10-2026 16:57:35) Review/merge `feat/ai-single-gpu-bash-launchers` into `main`, or leave it open for review? After merging: final log on `main` (status `done` + merge hash + final Time Spent), then fast-forward the branch (`--ff-only`) and re-push with `--force-with-lease` (if you squash/rebase-merge: skip the sync — the branch keeps the code, nothing is lost).
- [ ] (23-10-2026 16:57:35) For the launcher flow, is the venv inside the distro or on the Windows side (per node)? (Feeds T3's second-node provisioning as well.)
- [ ] (23-10-2026 16:57:35) Should the same bash launchers also be built for the second node (192.168.2.196) — coordinate with T3?

**Confirmed (user provided):**

- (23-10-2026 16:57:35) Where this work should be pushed → "the clone URL should have been `git@github.com:HectorBravo/HyperQwen_mod.git`, a direct fork of the upstream" → origin re-pointed (SSH); all pushes target the fork; none of them expose API-key material.

### Subtasks / Plan

- [x] Audit the repo / launchers / `.env` (upstream clone); map the `.bat` scheme (PORT = 18000 + 10×is_long + gpu_idx; per-run CTX/SPEC override)
- [x] Author the master `start-single.sh` (sources `.env`; per-run CTX/SPEC/PORT override; CUDA pinning; 0.0.0.0 bind; hard-fails without a key or on LAN bind)
- [x] Author the 6 wrappers `start_single-{fast,long}-cuda{0,1,2}.sh` (fast → 18000/18001/18002; long → 18010/18011/18012; bad args → usage, never launch the real thing)
- [x] Normalize line endings (LF, no BOM — CRLF was breaking `bash -n`); all 7 pass `bash -n` in WSL Ubuntu-26.04
- [x] Move `VLLM_API_KEY` out of the local `.env` → untracked `vllm_api_key.env.bak` (pointer comment left in `.env`); the shared key stays in gitignored `api_key.txt`; no key material in any file to be committed
- [x] Re-point the clone origin to the fork (SSH) and reset local `main` onto the fork's `main` (`493818e`), with backup refs
- [x] Merge the T4 entry into the fork's `ai/AI_TASKLOG.md` (this commit)
- [ ] Push the pre-push log to the fork's `main`
- [ ] Rebuild `feat/ai-single-gpu-bash-launchers` on top of the fork's `main` (restore the 7 scripts from `b87c01e` with the exec bits) and push
- [ ] Post-push log update on `main` (commit hash, time)
- [ ] After user merge: final log on `main` (status `done`, merge hash, final Time Spent)
- [ ] Fast-forward the branch onto the final log (`--ff-only`) + re-push with `--force-with-lease` (skip on squash/rebase merge)

### Full Context Notes for AI Agents

> **Purpose**: Self-contained knowledge base for resuming this task.

**Topology at this commit:**
- Repo `D:\Repos\hyperqwen`, origin = `git@github.com:HectorBravo/HyperQwen_mod.git` (SSH, re-pointed this session). Second clone of the same fork: `D:\Repos\hyperqwen_mod` (user-maintained; its `ai/AI_TASKLOG.md` == committed).
- `main` = `origin/main` = `493818e` ("update tasklog"; chain `01761f2` add bench_single.bat ← `cf21afe` update start_single.bat ← … ← `851489d` ← common base `ce9615c` with the upstream lineage).
- `backup/pre-repoint-main` = `e5270a2` (old upstream-lineage main; 2 log-only commits over `ce9615c`: `cf5a619`, `e5270a2`). `backup/old-single-gpu-branch` = `b87c01e` (the 7 `.sh` launchers, all mode 100755; the `feat/ai-single-gpu-bash-launchers` branch still points there too).
- Untracked + gitignored in the worktree: `api_key.txt` (shared 35-char key), `vllm_api_key.env.bak` (48-char key — the **only** copy in the user's area), `.env` (pointer comment only), `ai/.hq-poll2.sh`, plus `wsl_migrate/` (mod clone). **None of these may ever be committed.**

**The 7 scripts (canonical = blobs in `b87c01e`; LF, no BOM, 100755, no key material):**
- `start-single.sh` — master: sources the repo `.env`; accepts per-run `CTX`/`SPEC`/`PORT` overrides; pins one GPU; binds 0.0.0.0; hard-fails if `VLLM_API_KEY` resolves empty (chain: `.env` → env → `api_key.txt` via `resolve_api_key.sh`); then `vllm serve` with the CTX/SPEC-derived model + context + port (long: fp8 KV, 0.93 gpu-mem-util, max-num-seqs 8, etc. — exact flags = the `b87c01e` blob).
- `start_single-{fast,long}-cuda{0,1,2}.sh` — thin wrappers calling the master with the baked-in CTX/SPEC/GPU (PORT = 18000 + 10×is_long + gpu_idx).

**Remaining steps (in order):**
1. Commit this log edit on `main`: `docs(ai): [ai] add T4 (single-GPU bash launchers) to task log` → `git push origin main`. Identity: `GIT_AUTHOR_NAME=AI_bot` + `GIT_COMMITTER_NAME=AI_bot` env vars only (never set the email — the user's `git config user.email` applies); `[ai]` tag after the colon in every AI commit.
2. `git checkout -B feat/ai-single-gpu-bash-launchers main` (fresh, on top of the fork's main + log commit) → `git checkout b87c01e -- start-single.sh start_single-fast-cuda0.sh start_single-fast-cuda1.sh start_single-fast-cuda2.sh start_single-long-cuda0.sh start_single-long-cuda1.sh start_single-long-cuda2.sh` (restores content + 100755) → re-verify (`bash -n` ×7; non-leaking key scan `git grep -c -E 'sk-[A-Za-z0-9]{20,}|VLLM_API_KEY=.?[A-Za-z0-9]{30,}' <new-tip> -- '*.sh'` must print nothing; `ls-tree` shows 100755) → commit `feat(launchers): [ai] add single-GPU Linux/bash launchers (fast/long × cuda 0/1/2)` → `git push origin feat/ai-single-gpu-bash-launchers`.
3. Post-push: on `main`, update this log (tick subtasks 8–10, real hashes, Time Spent = now − 15:23:00) → dedicated `docs(ai):` commit → push.
4. **Only after the user merges the branch**: final log on `main` (status `done`, merge hash, final Time Spent) → then `git checkout feat/ai-single-gpu-bash-launchers; git merge --ff-only origin/main; git push --force-with-lease origin feat/ai-single-gpu-bash-launchers`. If the merge was **squash/rebased**, the ff is impossible — leave the branch as-is and tell the user (nothing is lost; their branch has the final log).

**Env / gotchas:**
- Windows PowerShell 5.1, no admin. Native-command stderr can surface as `RemoteException` and abort a `;` chain (especially with `2>$null`); run destructive commands one at a time. No `&&` in PS 5.1 — use `;`.
- `Get-Content | Measure-Object -Line` undercounts this file (190 ≠ 255) because blank lines count as 0 lines — use raw byte/line counts when reasoning about offsets.
- The log is pure LF (`.gitattributes`: `* text=auto eol=lf`); keep all edits LF.
- `editor`/`read_files` line numbers match here (the file has no CRs).
- T3 (second-node provisioning) is a separate in_progress task — don't touch its rows/section.

---

## Task T3: Provision second node (192.168.2.196) with wsl_migrate + long-context vLLM

- **Status**: <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span>
- **Type**: <span style="background-color:#22863a;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">feat</span>
- **Created**: 11-10-2026 23:36:00
- **Last Updated**: 11-10-2026 23:55:00
- **Time Spent**: 15m
- **Branch**: pending (User Confirmations — package may stay uncommitted)
- **Commit(s)**: pending
- **Blockers**: none (2 user confirmations pending; neither blocks recon)
- **Findings & Notes**:
  - **Goal**: use `wsl_migrate` to fully provision the **second** Windows/WSL node and serve `Qwen3.8-27B` with the **same long-context** vLLM config as the source.
  - **Source Windows** (`destr0`): `.wslconfig` = memory=80GB, swap=8GB, processors=8, firewall=false, **ip=172.18.245.101**; `netsh portproxy` maps `0.0.0.0:{18000-18002,18010-18012,18020}` + `10.20.10.18:{18000-18002,18010-18012}` → that IP. WSL 3.0.1.0 / kernel 6.18.40.1-1 / Win 10.0.26200.9550; one distro `Ubuntu-26.04` (Running, v2).
  - **Source vLLM (live)**: two `vllm serve` on `18010`/`18011`, model `Qwen3.8-27B-W4A16-AutoRound-fast`, `--max-model-len 150000 --kv-cache-dtype fp8 --mamba-ssm-cache-dtype float16 --gpu-memory-utilization 0.93 --max-num-seqs 8`, MTP-3, parsers `qwen3`/`qwen3_coder`.
  - **Source sizes**: venv ~15 GB, model ~15.4 GB, vLLM compile cache ~2.2 GB, repo `.git` ~38 MB.
  - **Target** (`destr0@192.168.2.196`, via plink + `_hostkey.txt` ed25519 `SHA256:`; host `nodo1`): **same** Win build & WSL/kernel. **`Ubuntu-26.04` already Running (v2)** → no install. **`hbravo` user exists**; `/etc/wsl.conf` already `systemd=true` + `default=hbravo`. **No D: drive → all on C:** (167.5 GB free). **ALREADY HAS** a clean repo clone `C:\repos\HyperQwen_mod` @ **`1586706`** (= source `main`) **AND** the full model `C:\test_ai\models\Qwen3.8-27B-W4A16-AutoRound-fast` (15 GB, all 7 shards + extra-tensors + MTP vocab) **AND** base `/home/hbravo`. **GPUs in WSL**: idx0 GT 1030 (2 GB), **idx1 RTX 3090 (24 GB)** → one long-context instance on idx1. **Only the venv (15 GB) is missing.** `zstd` absent (apt-get install needed); 32 cores, 23 GiB RAM.
  - **Git state**: `main` @ `1586706`; 13 `wsl_migrate/` files **staged** but uncommitted, while its README says "do not commit" → **contradiction** (see confirmations). `.env` + `_*` helpers untracked/ignored.
  - **Transport (CONFIRMED)**: plink non-interactive works for **simple cmd only** (WSL/PowerShell/`2>&1` must go through **files** via base64→`certutil -decode`; `certutil` needs a `del` first — it won't overwrite). Source has **plink + pscp + psftp** (`C:\Program Files\PuTTY\`). Target has **git, curl, certutil** (no pscp/psftp) → target can't be the SFTP client, so the **source pushes via `psftp` (SFTP — faster than pscp/SCP for multi-GB)**. Small scripts → base64→certutil bootstrap. **Long ops (tar / transfer / extract, each > 30 s) MUST run detached (WSL `systemd-run`) + poll a log**, because the harness kills a `run_commands` at 30 s and that would kill any child WSL/tar/psftp.

### User Confirmations

**Pending (awaiting user response):**

- [ ] (11-10-2026 23:55:00) `wsl_migrate/` (13 files) is **staged** but its README says "do not `git commit` this package" — commit it to the repo, or unstage and keep it local-only?
- [ ] (11-10-2026 23:55:00) Target has only **one** 3090 (+ GT 1030). Run **one** long-context instance (port 18010), or attempt a **second** (won't fit 150k on the same GPU)?

**Confirmed (user provided):**

- None yet.

### Subtasks / Plan

- [x] Windows-side recon: source `_wslcfg.ps1` + target `_tstate.ps1`
- [x] WSL-inside recon (target + source) via base64→certutil bootstrap
- [x] Confirm file-transfer path (SFTP via `psftp`; source has it — target doesn't)
- [ ] **Source** (detached, `systemd-run`): tar the 15 GB venv → `C:\hyperqwen_transfer\venv.tar`  [poll `hqtar.log`]
- [ ] **Source→target**: `psftp put` `C:\hyperqwen_transfer\venv.tar` → target `C:\hyperqwen_transfer\`  [SFTP over LAN]
- [ ] **Target** (detached, `systemd-run` via plink→`wsl -u root`): `provision --venv-tar` → extract → `/home/hbravo/hyperqwen/venv`; chown hbravo  [poll log]
- [ ] **Target**: `apt-get install -y zstd`; `~/hyperqwen/models`→`/mnt/c/test_ai/models` symlink; repo-root `venv`+`models` symlinks; set `CUDA_VISIBLE_DEVICES=1`
- [ ] **Target Windows**: write `%USERPROFILE%\.wslconfig` (static IP in 172.25.128.0/20, `firewall=false`, right-sized mem/cpu); `wsl --shutdown`+relaunch
- [ ] **Target Windows**: `netsh interface portproxy` `0.0.0.0:<port>` → target WSL IP:<port>
- [ ] **Target WSL**: start ONE long-context vLLM (`CUDA_VISIBLE_DEVICES=1 CTX=long PORT=18010`) via a C:-path launcher
- [ ] Validate: `/v1/models` + a long-context (150k) chat completion
- [ ] Update `wsl_migrate/README.md` with the real 2nd-node steps (venv-only, C:-paths, single-GPU, portproxy)
- [ ] Clean up all `_*` helpers; re-run local `verify` + `provision --dry-run`; refresh project index (Steps 2-4); commit per git rules

### Full Context Notes for AI Agents

> **Purpose**: resume T3 without other context.

**Env**: fork `D:\Repos\HyperQwen_mod` (WSL `/mnt/d/repos/HyperQwen_mod`), `main`@`1586706`, remote `git@github.com:HectorBravo/HyperQwen_mod.git`. Source WSL user `hbravo` (venv `~/hyperqwen/venv`, models `~/hyperqwen/models` or `/mnt/c/test_ai/models`). Target user `destr0`, pw `Lacaquita2$`, **no D: drive → C:** (167.5 GB free). Same OS/WSL as source.

**Long-context config (verbatim)**: model `Qwen3.8-27B-W4A16-AutoRound-fast` + `--max-model-len 150000 --kv-cache-dtype fp8 --mamba-ssm-cache-dtype float16 --gpu-memory-utilization 0.93 --max-num-seqs 8`, MTP-3, parsers `qwen3`/`qwen3_coder`. Source = 2 instances (18010/18011, one per 3090). Target = 1 3090 → **1 instance** (port 18010) unless the user insists on a second.

**Static IP / LAN exposure**: the WSL static IP is set by the **Windows** `%USERPROFILE%\.wslconfig` `ip=` line (not internal netplan). Target has none yet → create one with the target's **own** subnet IP (from `ip addr` inside WSL), `firewall=false`, and right-sized `memory=`/`processors=`. LAN reach needs `firewall=false` **and** Windows `netsh portproxy` (source has both) → target needs equivalent portproxy rules.

**File transfer (the hard part)**: prefer `pscp` (checked by `_pscpchk.ps1`); else `git clone` on target (needs the package committed → ties to the pending confirmation); else base64-over-plink (small files only). Bootstrap in `_twsl.ps1`: `echo <b64> > C:\temp\x.b64` → `certutil -decode C:\temp\x.b64 C:\temp\x.sh` → `wsl -d Ubuntu-26.04 -u root -- bash /mnt/c/temp/x.sh`.

**Refined plan (venv-only — target already has repo@1586706 + 15 GB model + hbravo user):**
- Source venv = real dir `/home/hbravo/hyperqwen/venv` (15 GB; py 3.14.4, torch 2.13.0+cu130, vllm 0.30.0). Target user is ALSO `hbravo` → extract to the SAME path `/home/hbravo/hyperqwen/venv` (the venv's absolute-path refs then match; README §venv-path-caveat satisfied). The 15 GB `-fast` model is ALREADY on the target (`/mnt/c/test_ai/models/…-fast`) → only the venv crosses the wire.
- Target long-context boot: `CUDA_VISIBLE_DEVICES=1 CTX=long PORT=18010` (target 3090 = WSL idx 1; GT1030 = idx 0). `select_model.sh`/`resolve_config.sh` auto-pick the fast model once `REPO`/`models` resolve → make repo-root `models` a symlink → `/mnt/c/test_ai/models` (mirror the source) and `venv` → `/home/hbravo/hyperqwen/venv`. The `.bat` `REPO_PATH` is D:-specific (target has no D:) → drive the target via a direct `wsl -u hbravo -- bash -c 'cd /mnt/c/repos/HyperQwen_mod && … start_qwen.sh'`, not the `.bat`s.
- **Long-op pattern (beats the 30 s harness kill):** both WSLs have systemd. Run each heavy op as a transient unit: `wsl -d Ubuntu-26.04 -u root -- systemd-run --unit=NAME -- /bin/bash /path/helper.sh` (returns in <2 s; the unit runs in its own cgroup, so a harness kill of `wsl` can't stop it). On the target, invoke via `plink … "wsl -u root -- systemd-run …"` and poll a log the helper writes (short `plink type C:\…log` / `wsl cat`).
- SFTP between the two **Windows** sides (both have C:): `psftp -hostkey SHA256:… -batch -l destr0 -pw <pw> 192.168.2.196` → `put C:\hyperqwen_transfer\venv.tar C:\hyperqwen_transfer\`. Target can't run psftp itself; the source pushes.
- Target `.wslconfig` is currently ABSENT (dynamic IP 172.25.137.190/20). Create it with `ip=` = a free addr in that subnet (e.g. 172.25.128.100), `firewall=false`, right-sized `memory=`/`processors=` (target 32 cores / 23 GiB — don't copy the source's 80 GB/8 proc), then `wsl --shutdown` + relaunch.

**Temp helpers (clean up at end)**: `_hostkey.txt`, `_tstate.ps1`, `_wslcfg.ps1`, `_twsl.ps1`+`_twsl_probe.sh`(`_twsl_out.txt`), `_pscpchk.ps1`, older `_probe.ps1`/`_probe_out.txt`/`_inspect*.sh`/`_sizes.sh`/`_dmodels.sh`.

**Gotchas**: plink = simple cmd only (WSL via files). Target has **no D: drive**. `ai/PROJECT_DESCRIPTION.md` is **stale** (`git_head 38ac264` ≠ HEAD `1586706`) → refresh Steps 2-4 before concluding. Never commit the API key, `.env`, or `.bat` launchers.

---

## Task T1: Migrate HyperQwen Windows launchers to fork + re-apply FlashInfer cu13 link shim

- **Status**: <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span>
- **Type**: <span style="background-color:#9e6a03;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">fix</span>
- **Created**: 08-10-2026 02:25:40
- **Last Updated**: 08-10-2026 02:54:08
- **Time Spent**: 28m
- **Branch**: [`fix/ai-flashinfer-cu13-link-shim`](https://github.com/HectorBravo/HyperQwen_mod/tree/fix/ai-flashinfer-cu13-link-shim)
- **Commit(s)**: [`9ec570d`](https://github.com/HectorBravo/HyperQwen_mod/commit/9ec570dd6f634fd68a4a10fdac6af35739cb0cc3) (main: task log, before code push) · [`2130381`](https://github.com/HectorBravo/HyperQwen_mod/commit/2130381e0bf077dd94df0837bb127ffaafd8c5c9) (fix/ai-flashinfer-cu13-link-shim: FlashInfer cu13 link shim in `single-user/start_qwen.sh`) · [`719ccd8`](https://github.com/HectorBravo/HyperQwen_mod/commit/719ccd837a48b498ea1f9904d4091f24f006f21b) (fix/ai-flashinfer-cu13-link-shim: gitignore launcher `.bat` — carries the `VLLM_API_KEY`, must never be committed)
- **Blockers**: none
- **Findings & Notes**:
  - The migration is a **Windows-side path repoint**, not a WSL migration. All WSL-side content stays in `/home/hbravo/hyperqwen/` (venv) and `C:/test_ai/models` (models) — untouched.
  - The old clone `D:\Repos\HyperQwen` and the fork `D:\Repos\HyperQwen_mod` are now at the **same commit** `7af097b` (the context's `10bb488` was stale). The fork's `single-user/start_qwen.sh` was byte-identical to the old clone's base, so the FlashInfer shim did **not** need re-derivation — the exact diff from the old clone's uncommitted change was applied 1:1.
  - `venv` and `models` in both repos are Windows **reparse points** (created as symlinks from WSL): `venv` → `/home/hbravo/hyperqwen/venv`, `models` → `/mnt/c/test_ai/models`. Both recreated in the fork; they resolve from WSL (drvfs) and appear as `ReparsePoint` from Windows.
  - WSL's `/mnt/d` mount is **case-insensitive**; both `/mnt/d/Repos/...` and `/mnt/d/repos/...` resolve. The bat's `REPO_PATH` was set to the lowercase spelling `/mnt/d/repos/HyperQwen_mod` to match the original casing convention.
  - The only other stale path reference anywhere in `D:\Repos` is `D:\Repos\configs\.config\lazygit\state.yml` (a lazygit UI-state file that self-updates) — intentionally left alone.
  - The cu13 FlashInfer link shims **already persist** in the WSL venv (`.../nvidia/cu13/lib64/libcudart.so` and `.../lib64/stubs/libcuda.so`), so a boot from the fork works even before the code lands; the code makes the shim idempotent and self-healing on a fresh venv.
  - The 0-byte `bench/results/cohort_Tdefault_c1.log` in the old clone is an empty placeholder — not migrated (it is gitignored).
  - **Key protection (per user instruction, 08-10-2026):** the user required that the real `VLLM_API_KEY` **never be committed**. Verified the secret value (the `sk-lm-...` string in `start-single.bat` line 44) is **absent** from every tracked file on both `main` and `fix/ai-flashinfer-cu13-link-shim` (a `git grep` for the key's unique value substring → no hits; only the *variable name* `VLLM_API_KEY` appears in tracked scripts/docs). No fragment of the key appears anywhere in this log. The `.bat` launchers were untracked, but **not** in `.gitignore`, so a stray `git add .` could commit the key. Hardened `.gitignore` to ignore `start-single.bat` and `start_single-*.bat` (commit [`719ccd8`](https://github.com/HectorBravo/HyperQwen_mod/commit/719ccd837a48b498ea1f9904d4091f24f006f21b) on the feature branch). `.env` does not exist locally; the repo's own `resolve_api_key.sh` supports `api_key.txt`/`.env` as the safe home for the key, but none of that is committed here.
  - **Tracked deliverable** = `single-user/start_qwen.sh` only (the FlashInfer cu13 link shim). The 7 `.bat` launchers and the two repo-root reparse points (`venv`, `models`) are **untracked local artifacts** (all already in `.gitignore`) — copied into the fork but **not** committed, matching how the old repo kept them.

### User Confirmations

**Pending (awaiting user response):**

- None.

**Confirmed (user provided):**

- (08-10-2026) WSL-side content stays in `/home/hbravo/hyperqwen/` → "go" (proceed with the plan as scoped; WSL side untouched).
- (08-10-2026) If `start-single.bat` is ever to be committed, first make sure the `VLLM_API_KEY` is not committed (use `.env` or other method; the key must not be committed). → Resolved: the `.bat` is **not** committed (stays a local untracked artifact); `.gitignore` hardened to ignore the launcher `.bat` files (`719ccd8`) so the key can never be swept into a commit.

### Subtasks / Plan

- [x] Re-run lost recon (path scan, WSL mount casing, cu13/FlashInfer layout, shim insertion point)
- [x] Confirm fork vs old-clone commit relationship (both at `7af097b`)
- [x] Recreate `venv` reparse point in fork → `/home/hbravo/hyperqwen/venv`
- [x] Recreate `models` reparse point in fork → `/mnt/c/test_ai/models`
- [x] Copy the 7 `.bat` launchers into the fork (1:1, checksum-verified)
- [x] Repoint `REPO_PATH` in fork `start-single.bat` → `/mnt/d/repos/HyperQwen_mod`
- [x] Apply the FlashInfer cu13 link shim to fork `single-user/start_qwen.sh` (1:1, diff-verified, `bash -n` clean)
- [x] Commit `ai/AI_TASKLOG.md` on `main` (before code push) and push `main`
- [x] Create `fix/ai-flashinfer-cu13-link-shim`, commit + push only `single-user/start_qwen.sh` (also a `.gitignore` commit `719ccd8` for the launcher `.bat`)
- [ ] Final verification: boot `single-long` (GPU2) from the fork — confirm FlashInfer JIT link succeeds, `ldd` resolves `libcudart.so.13`; boot `single-fast` to confirm unaffected

### Full Context Notes for AI Agents

> **Purpose**: Self-contained knowledge base to resume this task without other context.

**Repos & commits**
- Old clone: `D:\Repos\HyperQwen`, on `main` @ `7af097b` (`docs: PP=2 + SPEC=off re-run on 0.29/fp8 (#160) (#283)`). Working tree carries: an **uncommitted** modified `single-user/start_qwen.sh` (the FlashInfer shim) and **7 untracked `.bat` launchers**. Its `venv`/`models` are reparse points (not tracked, gitignored).
- Fork (deliverable): `D:\Repos\HyperQwen_mod`, remote `git@github.com:HectorBravo/HyperQwen_mod.git`, on `main` @ `7af097b` (== `origin/main`, 0/0). `ai/AI_TASKLOG.md` created fresh.

**The FlashInfer cu13 link shim (the ONLY file to commit)**
- File: `single-user/start_qwen.sh`. Inserted **between** the `CUDA_HOME` auto-detect block (ends `fi` at what was line 93) and the `# Backlog 6 / F13: one validated resolver` comment.
- It is a 36-line block (15 comment lines + 21 code lines) guarded by `if [ -n "${CUDA_HOME:-}" ]; then ... fi`. It creates two symlinks **idempotently** (only if missing):
  - `$CUDA_HOME/lib64/libcudart.so` → `$CUDA_HOME/lib/libcudart.so.13` (the toolkit's own versioned lib from the pip `nvidia-cuda-runtime-cu13` wheel).
  - `$CUDA_HOME/lib64/stubs/libcuda.so` → driver lib (`ldconfig -p` lookup, falling back to `/usr/lib/wsl/lib/libcuda.so.1` on WSL).
- Reason: `flashinfer/jit/cpp_ext.py:256` hardcodes `-L$CUDA_HOME/lib64 -L$CUDA_HOME/lib64/stubs -lcudart -lcuda`; the pip cu13 wheel ships only `lib/libcudart.so.13` (no `lib64/`, no driver stub), so the first FlashInfer JIT build (CTX=long fp8-KV batch_prefill / MTP verify) dies at LINK with "cannot find -lcudart"/"-lcuda". CTX=fast uses FlashAttention and never JITs FlashInfer → unaffected. A native `/usr/local/cuda` (has `lib64`+`stubs`, no `lib/libcudart.so.N`) → block is a no-op.
- Verification already done: fork file is **byte-identical** to the old clone's modified file (WSL `diff` → empty, exit 0); `bash -n` → exit 0.
- The live links already exist in the WSL venv at `/home/hbravo/hyperqwen/venv/lib/python3.14/site-packages/nvidia/cu13/lib64/{libcudart.so, stubs/libcuda.so}` (created Oct 8 00:13 in a prior session) — so the shim is a no-op on this host but self-heals a fresh venv.

**Windows-side artifacts (NOT committed)**
- 7 `.bat` files copied into the fork root: `start-single.bat` (the only path-bearing one) + 6 wrappers `start_single-{fast,long}-cuda{0,1,2}.bat` (each just `call start-single.bat <type> <gpu>` — no path).
- `start-single.bat` line 41 repointed: `set REPO_PATH=/mnt/d/repos/HyperQwen` → `/mnt/d/repos/HyperQwen_mod`. Line 45 `CUDA_HOME=/home/hbravo/hyperqwen/venv/lib/python3.14/site-packages/nvidia/cu13` is an absolute WSL path (clone-independent) → left as-is. Line 44 carries a real `VLLM_API_KEY` (untracked secret — do NOT commit; it is in the gitignored `.bat`).
- Reparse points created in fork via WSL: `ln -s /home/hbravo/hyperqwen/venv /mnt/d/Repos/HyperQwen_mod/venv` and `ln -s /mnt/c/test_ai/models /mnt/d/Repos/HyperQwen_mod/models`. Both resolve from WSL and show as `ReparsePoint` from Windows.
- `.gitignore` already lists `venv`, `models`, `api_key.txt`, `.env`, `bench/results/` (with a "local reproduction artifacts (symlinks here, so no trailing slash)" note) → none of these are committable. The 7 `.bat` launchers carry the **real** `VLLM_API_KEY` (`start-single.bat` line 44) — added `start-single.bat` and `start_single-*.bat` to `.gitignore` (commit [`719ccd8`](https://github.com/HectorBravo/HyperQwen_mod/commit/719ccd837a48b498ea1f9904d4091f24f006f21b), on the feature branch) so they can never be committed by a stray `git add .`; they remain **untracked local artifacts** on `main` until the branch merges.

**Git plan (house rules)**
- Identity: `GIT_AUTHOR_NAME=AI_bot`, `GIT_COMMITTER_NAME=AI_bot`; do NOT set author/committer email (use user's `git config user.email`); never modify `git config`.
- Tag every commit message with `[ai]` after the colon.
- Step 1: on `main`, commit ONLY `ai/AI_TASKLOG.md` (`docs(ai): ...`), push `origin main` (fast-forward, 0/0).
- Step 2: `git checkout -b fix/ai-flashinfer-cu13-link-shim` from `main`; `git add single-user/start_qwen.sh`; commit `fix(launchers): [ai] ...` (scope `launchers` matches the repo's style for `start_qwen.sh` work); push `origin fix/ai-flashinfer-cu13-link-shim`.
- Step 3: after the push, update `ai/AI_TASKLOG.md` (commit ids, status→done, time) and commit+push it to `main` again (the "after push" log commit).
- **Do NOT** `git add` the `.bat` files, `venv`, `models`, `.env`, or `api_key.txt`.

**Verification (final subtask) — how to run from the new location**
- Dry run: `wsl -d Ubuntu-26.04 -- bash -c 'cd /mnt/d/repos/HyperQwen_mod && PRINT_ARGV=1 CTX=long bash single-user/start_qwen.sh'` (the launcher's built-in `PRINT_ARGV=1` prints the resolved argv without booting).
- Real long boot on the free GPU (GPU2, 0 MiB used; GPU1 ~97% busy, GPU0 light): `CUDA_VISIBLE_DEVICES=2 VLLM_WSL2_ENABLE_PIN_MEMORY=1 CTX=long HOST=0.0.0.0 PORT=18012 VLLM_API_KEY=sk-lm-... CUDA_HOME=/home/hbravo/hyperqwen/venv/lib/python3.14/site-packages/nvidia/cu13 bash single-user/start_qwen.sh` (PORT 18000+10+2=18012 per the bat formula). Watch for the two `[start_qwen] FlashInfer link shim:` lines (or their absence = already present) and a successful model load + server up. After: confirm `ldd` on the flashinfer JIT `.so` resolves `libcudart.so.13`, then shut the server down.
- Real fast boot (unaffected check): `CUDA_VISIBLE_DEVICES=2 ... CTX=fast PORT=18002 ...` → boots with FlashAttention, no FlashInfer JIT.
- Use the API key from `start-single.bat` line 44 (do not print it in commits/logs).

**Constraints / gotchas**
- WSL distribution is `Ubuntu-26.04`. vLLM in the venv is **0.30.0** (matches the fork's target). Python 3.14.
- `D:\Repos\.ai_pathscan.ps1` is a scratch scanner created this session — delete it at the end (it lives outside the repo).
- The old clone's uncommitted `start_qwen.sh` shim is being left in place (the user's working tree; the old location keeps working since the venv links persist). Flag in the final summary so the user can `git checkout` it if they want the old clone pristine.
- PowerShell inline `$(if ...)` inside double-quoted `Write-Output` mis-parses in this environment; prefer `wsl ... diff` / `Get-FileHash` over inline PowerShell conditionals for verification.

---

## Completed Tasks

| Created | Task | Type | Subtasks | Time Spent |
|---------|------|------|----------|------------|
| 08-10-2026 03:14:30 | [T2: Commit .bat launchers + project indexer (api_key.txt key migration)](#task-t2-commit-bat-launchers--project-indexer-api_keytxt-key-migration) | <span style="background-color:#57606a;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">chore</span> | 6/6 | 12m |

---

## Task T2: Commit .bat launchers + project indexer (api_key.txt key migration)

- **Status**: <span style="background-color:#22863a;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">done</span>
- **Type**: <span style="background-color:#57606a;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">chore</span>
- **Created**: 08-10-2026 03:14:30
- **Last Updated**: 08-10-2026 03:26:00
- **Time Spent**: 12m
- **Branch**: [`chore/ai-commit-bat-launchers-and-indexer`](https://github.com/HectorBravo/HyperQwen_mod/tree/chore/ai-commit-bat-launchers-and-indexer)
- **Commit(s)**: [`569153e`](https://github.com/HectorBravo/HyperQwen_mod/commit/569153e)
- **Blockers**: none
- **Findings & Notes**:
  - The repo's `resolve_api_key.sh` already supports `api_key.txt` as the file fallback for `VLLM_API_KEY`. The `.bat` files no longer need to carry the key — `start_qwen.sh` sources `resolve_api_key.sh` which reads `api_key.txt` from the repo root.
  - Created `api_key.txt` (35 bytes, gitignored) with the real key. Removed `set VLLM_API_KEY=...` and the `VLLM_API_KEY=%VLLM_API_KEY%` env passthrough from `start-single.bat`.
  - The 6 sub-launcher `.bat` files (`start_single-*.bat`) never had the key — they just call `start-single.bat`.
  - With the key removed, all 7 `.bat` files are now safe to commit. The `.gitignore` hardening from the feature branch (`719ccd8`) is no longer needed on `main`.
  - Project indexer run: created `ai/PROJECT_DESCRIPTION.md` (full project map) and `AGENTS.md` (mandatory reading contract + security rules).
  - The feature branch `fix/ai-flashinfer-cu13-link-shim` retains the `.gitignore` hardening as a safety net if keys ever end up in `.bat` files again.

### User Confirmations

**Pending (awaiting user response):**

- [ ] (08-10-2026 03:14:30) Merge `chore/ai-commit-bat-launchers-and-indexer` into `main`, or leave it open for review?

**Confirmed (user provided):**

- (08-10-2026 03:14:30) Use `api_key.txt` to hold the key, remove from `.bat`, commit all `.bat` files → "yes, do it"

### Subtasks / Plan

- [x] Update `ai/AI_TASKLOG.md` before push
- [x] Commit task log to `main` (dedicated commit)
- [x] Create branch `chore/ai-commit-bat-launchers-and-indexer`
- [x] Add + commit `.bat` files, `ai/PROJECT_DESCRIPTION.md`, `AGENTS.md`
- [x] Push branch to origin
- [x] Update `ai/AI_TASKLOG.md` after push, commit + push to `main`

### Full Context Notes for AI Agents

> **Purpose**: Self-contained knowledge base for resuming this task.

**Repo state at T2 start:**
- Fork: `D:\Repos\HyperQwen_mod`, on `main` at `959a07b`
- Feature branch: `fix/ai-flashinfer-cu13-link-shim` at `719ccd8` (has `.gitignore` hardening + FlashInfer shim)
- Working tree on `main`: 7 untracked `.bat` files + untracked `ai/PROJECT_DESCRIPTION.md` + untracked `AGENTS.md`
- `api_key.txt` created (35 bytes), gitignored

**Key change in `start-single.bat`:**
- Removed line 44: `set VLLM_API_KEY=sk-lm-...` (the real key)
- Removed `VLLM_API_KEY=%VLLM_API_KEY%` from the WSL command on line 57
- The key is now resolved at runtime by `resolve_vllm_key()` in `resolve_api_key.sh` which reads `$REPO/api_key.txt`

**Why the .bat files can now be committed:**
- The key was the ONLY secret in them. With it removed, they are pure launcher scripts.
- The 6 sub-launchers (`start_single-*.bat`) never had the key — they just call `start-single.bat`.

**Git workflow:**
1. `ai/AI_TASKLOG.md` → commit to `main` (dedicated `docs(ai):` commit) → push
2. `git checkout -b chore/ai-commit-bat-launchers-and-indexer` from `main`
3. `git add start-single.bat start_single-fast-cuda0.bat start_single-fast-cuda1.bat start_single-fast-cuda2.bat start_single-long-cuda0.bat start_single-long-cuda1.bat start_single-long-cuda2.bat ai/PROJECT_DESCRIPTION.md AGENTS.md`
4. Commit: `chore(launchers): [ai] commit .bat launchers (key moved to api_key.txt) + project indexer`
5. Push: `git push origin chore/ai-commit-bat-launchers-and-indexer`
6. Back on `main`: update task log → commit → push

**Important: Do NOT include the `.gitignore` change from the feature branch.** The feature branch's `.gitignore` (commit `719ccd8`) adds rules to IGNORE `.bat` files. Since we're now committing them, that rule is counterproductive on `main`. The feature branch keeps it as a safety net.

**`api_key.txt` content:** The real key (35 chars, format `sk-lm-XXXX:YYYY`). Must NEVER appear in any commit, log, or message. It's already gitignored.

**`ai/PROJECT_DESCRIPTION.md`:** Full project map with all 11 sections. `git_head` set to `959a07b` (will be stale after this commit, but that's expected — the freshness check is for the NEXT session).

**`AGENTS.md`:** Managed block (PROJECT_INDEXER markers) + user-managed section with repo-specific security rules about `api_key.txt` and `.bat` files.


