# AI Tasks Log

## Summary

| Created | Task | Status | Type | Subtasks | Time Spent | Blockers |
|---------|------|--------|------|----------|------------|----------|
| 08-10-2026 02:25:40 | [T1: Migrate HyperQwen Windows launchers to fork + re-apply FlashInfer cu13 link shim](#task-t1-migrate-hyperqwen-windows-launchers-to-fork--re-apply-flashinfer-cu13-link-shim) | <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span> | <span style="background-color:#9e6a03;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">fix</span> | 9/10 | 44m | none |
| 08-10-2026 03:14:30 | [T2: Commit .bat launchers + project indexer (api_key.txt key migration)](#task-t2-commit-bat-launchers--project-indexer-api_keytxt-key-migration) | <span style="background-color:#9e6a03;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span> | <span style="background-color:#57606a;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">chore</span> | 0/4 | 0m | none |

> **0 completed task(s)** — [View completed tasks](#completed-tasks)

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

## Task T2: Commit .bat launchers + project indexer (api_key.txt key migration)

- **Status**: <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span>
- **Type**: <span style="background-color:#57606a;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">chore</span>
- **Created**: 08-10-2026 03:14:30
- **Last Updated**: 08-10-2026 03:14:30
- **Time Spent**: 0m
- **Branch**: [`chore/ai-commit-bat-launchers-and-indexer`](https://github.com/HectorBravo/HyperQwen_mod/tree/chore/ai-commit-bat-launchers-and-indexer)
- **Commit(s)**: pending
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

- [ ] Update `ai/AI_TASKLOG.md` before push
- [ ] Commit task log to `main` (dedicated commit)
- [ ] Create branch `chore/ai-commit-bat-launchers-and-indexer`
- [ ] Add + commit `.bat` files, `ai/PROJECT_DESCRIPTION.md`, `AGENTS.md`
- [ ] Push branch to origin
- [ ] Update `ai/AI_TASKLOG.md` after push, commit + push to `main`

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

---

## Completed Tasks

| Created | Task | Type | Subtasks | Time Spent |
|---------|------|------|----------|------------|
