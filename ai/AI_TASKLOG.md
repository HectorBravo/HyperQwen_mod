# AI Tasks Log

## Summary

| Created | Task | Status | Type | Subtasks | Time Spent | Blockers |
|---------|------|--------|------|----------|------------|----------|
| 08-10-2026 02:25:40 | [T1: Migrate HyperQwen Windows launchers to fork + re-apply FlashInfer cu13 link shim](#task-t1-migrate-hyperqwen-windows-launchers-to-fork--re-apply-flashinfer-cu13-link-shim) | <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span> | <span style="background-color:#9e6a03;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">fix</span> | 6/9 | 5m | none |

> ✅ **0 completed task(s)** — [View completed tasks](#completed-tasks)

---

## Task T1: Migrate HyperQwen Windows launchers to fork + re-apply FlashInfer cu13 link shim

- **Status**: <span style="background-color:#0969da;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">in_progress</span>
- **Type**: <span style="background-color:#9e6a03;color:#fff;padding:2px 8px;border-radius:12px;font-size:12px;">fix</span>
- **Created**: 08-10-2026 02:25:40
- **Last Updated**: 08-10-2026 02:30:00
- **Time Spent**: 5m
- **Branch**: [`fix/ai-flashinfer-cu13-link-shim`](https://github.com/HectorBravo/HyperQwen_mod/tree/fix/ai-flashinfer-cu13-link-shim)
- **Commit(s)**: pending
- **Blockers**: none
- **Findings & Notes**:
  - The migration is a **Windows-side path repoint**, not a WSL migration. All WSL-side content stays in `/home/hbravo/hyperqwen/` (venv) and `C:/test_ai/models` (models) — untouched.
  - The old clone `D:\Repos\HyperQwen` and the fork `D:\Repos\HyperQwen_mod` are now at the **same commit** `7af097b` (the context's `10bb488` was stale). The fork's `single-user/start_qwen.sh` was byte-identical to the old clone's base, so the FlashInfer shim did **not** need re-derivation — the exact diff from the old clone's uncommitted change was applied 1:1.
  - `venv` and `models` in both repos are Windows **reparse points** (created as symlinks from WSL): `venv` → `/home/hbravo/hyperqwen/venv`, `models` → `/mnt/c/test_ai/models`. Both recreated in the fork; they resolve from WSL (drvfs) and appear as `ReparsePoint` from Windows.
  - WSL's `/mnt/d` mount is **case-insensitive**; both `/mnt/d/Repos/...` and `/mnt/d/repos/...` resolve. The bat's `REPO_PATH` was set to the lowercase spelling `/mnt/d/repos/HyperQwen_mod` to match the original casing convention.
  - The only other stale path reference anywhere in `D:\Repos` is `D:\Repos\configs\.config\lazygit\state.yml` (a lazygit UI-state file that self-updates) — intentionally left alone.
  - The cu13 FlashInfer link shims **already persist** in the WSL venv (`.../nvidia/cu13/lib64/libcudart.so` and `.../lib64/stubs/libcuda.so`), so a boot from the fork works even before the code lands; the code makes the shim idempotent and self-healing on a fresh venv.
  - The 0-byte `bench/results/cohort_Tdefault_c1.log` in the old clone is an empty placeholder — not migrated (it is gitignored).
  - **Tracked deliverable** = `single-user/start_qwen.sh` only (the FlashInfer cu13 link shim). The 7 `.bat` launchers and the two repo-root reparse points (`venv`, `models`) are **untracked local artifacts** (all already in `.gitignore`) — copied into the fork but **not** committed, matching how the old repo kept them.

### User Confirmations

**Pending (awaiting user response):**

- None.

**Confirmed (user provided):**

- (08-10-2026) WSL-side content stays in `/home/hbravo/hyperqwen/` → "go" (proceed with the plan as scoped; WSL side untouched).

### Subtasks / Plan

- [x] Re-run lost recon (path scan, WSL mount casing, cu13/FlashInfer layout, shim insertion point)
- [x] Confirm fork vs old-clone commit relationship (both at `7af097b`)
- [x] Recreate `venv` reparse point in fork → `/home/hbravo/hyperqwen/venv`
- [x] Recreate `models` reparse point in fork → `/mnt/c/test_ai/models`
- [x] Copy the 7 `.bat` launchers into the fork (1:1, checksum-verified)
- [x] Repoint `REPO_PATH` in fork `start-single.bat` → `/mnt/d/repos/HyperQwen_mod`
- [x] Apply the FlashInfer cu13 link shim to fork `single-user/start_qwen.sh` (1:1, diff-verified, `bash -n` clean)
- [ ] Commit `ai/AI_TASKLOG.md` on `main` (before code push) and push `main`
- [ ] Create `fix/ai-flashinfer-cu13-link-shim`, commit + push only `single-user/start_qwen.sh`
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
- `.gitignore` already lists `venv`, `models`, `api_key.txt`, `.env`, `bench/results/` (with a "local reproduction artifacts (symlinks here, so no trailing slash)" note) → none of these are committable; the `.bat` files are simply untracked (never `git add`ed — same state as the old repo).

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
