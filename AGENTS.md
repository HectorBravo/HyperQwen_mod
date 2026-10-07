# AGENTS.md — Rules for AI Agents

<!-- PROJECT_INDEXER:BEGIN (managed block — do not edit by hand) -->
## Mandatory Pre-flight Reading

> [!IMPORTANT]
> Before writing, refactoring, or reviewing ANY code in this repository, you
> MUST read and follow the project map. It is the source of truth for stack,
> layout, entry points, build/run/test commands, and conventions.

**Required reading (in order):**
1. `ai/PROJECT_DESCRIPTION.md` — project map (stack, layout, build, conventions)
2. Every `*.md` file under `docs/`:
   - `docs/quickstart.md`
   - `docs/install.md`
   - `docs/docker.md`
   - `docs/clients.md`
   - `docs/gotchas.md`
   - `docs/benchmarks.md`
   - `docs/quality.md`
   - `docs/long-context.md`
   - `docs/multi-gpu.md`
   - `docs/optimizations.md`
   - `docs/python-314.md`
   - `docs/spec-decode-scratch-token-units.md`
   - `docs/third-party-checkpoints.md`
   - `docs/ubuntu-3090.md`
   - `docs/vllm-0.29.md`
   - `docs/vllm-0.30.md`
   - `docs/wsl2-4090.md`
   - `docs/main-track.md`

## Documentation Freshness Rule

> [!CAUTION]
> `ai/PROJECT_DESCRIPTION.md` must stay in sync with the code.
> - **At task start:** if its `git_head` (see the `PROJECT_INDEXER` block)
>   differs from `git rev-parse HEAD`, the doc is STALE — regenerate it first
>   using the `project-indexer` skill before doing other work.
> - **At task end:** any task that adds/modifies/deletes source, build,
>   config, packaging, or dependency files MUST end by refreshing
>   `ai/PROJECT_DESCRIPTION.md` (re-run the `project-indexer` workflow,
>   Steps 2–4) and updating its `last_indexed` + `git_head`.
>
> Do not conclude a code-changing task while the project map is stale.
<!-- PROJECT_INDEXER:END -->

<!-- User-managed content below this line. The project-indexer skill never edits it. -->

## Repo-Specific Security Rules

- **Never commit** `api_key.txt`, `.env`, or any file containing real API keys.
- `.bat` launcher files that contain secrets must be gitignored.
- The `VLLM_API_KEY` is resolved at runtime by `resolve_api_key.sh` from
  the `VLLM_API_KEY` environment variable or the `api_key.txt` file in the
  repo root. Launchers (`.sh` or `.bat`) must not hardcode key values.
