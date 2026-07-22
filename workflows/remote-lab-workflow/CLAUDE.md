# Local-first experiment workflow

> Template: edit this file to match the project, then delete this note.

Local-first rules for this project: all code changes and records happen on this
machine; every meaningful step is recorded in the mandatory experiment log.

Remote module (optional): projects that run work on a remote machine (GPU box,
dev server, cluster node) also sync up with rsync, run over ssh -tt, and fetch
results back for local analysis with Claude.

## Project configuration — remote module (edit before any remote work)

- `SERVER`: `user@gpu-box` — ssh target of the remote server / GPU box
- `REMOTE_DIR`: `/home/user/project` — absolute path on the server mirroring this project
- `RESULTS_REMOTE_DIR`: `/home/user/project/results` — where results and run logs live on the server (default: `REMOTE_DIR/results`, written as a literal path)
- `EXCLUDES`: `.git .venv venv __pycache__ data/ checkpoints/ results/` — patterns rsync must never upload (adjust to this project's large local-only dirs)

The command templates below use `<SERVER>`, `<REMOTE_DIR>`, `<RESULTS_REMOTE_DIR>`
as placeholders for these values — substitute the literal values before
executing, and never execute a template line verbatim (unsubstituted, it can
reach the wrong host). Config values are read by Claude, not shell variables —
keep them literal, no `$`. Values here are user-owned — never rewrite,
normalize, or "fix" one on your own initiative; if a value looks wrong or is
still a placeholder/missing, ask me before running any remote command.
Once I confirm a value, you may write exactly that confirmed value into this
section (show me the diff first) — the only permitted rewrite of user-owned config.

## The loop

**Session start:** read `docs/state.md` and the tail of `docs/progress.md` first (e.g. `tail -n 60` — if either file is missing, treat that state as empty; create progress.md per the log rules below). Current state lives in these files, not in memory: if the tail shows a job still running, resume polling it before starting any new edit.

1. **Edit locally** — make all code and config changes here (risk-layered — see Git strategy below).
2. **Log** — append the step to `docs/progress.md` per the rules below (self-check first).
3. **Sync up** — rsync local changes to `<SERVER>:<REMOTE_DIR>`.
4. **Run remotely** — launch the job (experiment, training, …) over `ssh -tt`.
5. **Fetch back** — rsync results and logs down to `./results/`.
6. **Analyze locally** — analyze the results here with Claude, and log the conclusions.

Steps 3–5, the two sections with `remote module` in their heading, the "Remote
module (optional)" intro paragraph, and this note itself are the **remote module** —
if this project never touches a remote server, delete all of them and renumber
the remaining steps 1–3 (edit → log → analyze).

## Git and modification strategy — risk-layered

Goal: when something breaks, roll back to a known-good version immediately.

**Baseline:** never start a change on a dirty tree. Commit the current state first, so every round of work starts from a named known-good commit. One commit per logical step; the message mirrors the progress.md entry (what + why). If the dirty tree is my in-flight edit, ask before committing and propose the message; only auto-commit changes you made yourself (after logging them).

**Low-risk** — small isolated edits, fixes, new files nothing depends on: modify in place, then commit.

**High-risk** — copy-then-refactor, never rewrite in place:

1. Commit the known-good state.
2. Copy the target (`trainer.py` → `trainer_v2.py`) and refactor the copy; the original stays untouched and runnable.
3. Switch over only after the new version passes; delete the old file once it has proven itself.

High-risk means anything whose failure surfaces late or breaks the whole run — edit this list for the project:

- rewriting a wrapper
- modifying an adapter / hook
- replacing the training loop
- root changes to the data pipeline

**When a run is worth keeping:** tag the commit it ran from (`git tag <run-ID>`), so rollback and reproduction targets are named, not hunted for.

**When something breaks:** stop, log it in `docs/progress.md` with the hypothesis, and roll back to the last known-good commit (`git reset --hard <good>` — safe because the tree is always committed; or `git revert`). Never fix forward over an untested state.

## Mandatory experiment log

Every meaningful step must be recorded in `docs/progress.md`. The log is
append-only: never rewrite, reorder, or delete past entries. A correction is a
NEW entry that supersedes the old one.

**Anti-overwrite self-check — run BEFORE appending any entry:**

1. `mkdir -p docs`; if `docs/progress.md` is missing, create it with `printf '# Progress Log\n' > docs/progress.md` (the trailing newline matters: without it the first append glues onto the header).
2. Run `wc -l docs/progress.md` and note the line count N.
3. Append with `cat >> docs/progress.md <<'EOF' ... EOF` or Edit — never a whole-file overwrite on this file. The new line count must be > N; if it is not, something overwrote content — stop and investigate before continuing.

**Meaningful step (log it):** code changes, task launches (experiment, training, build, …), config or parameter changes, analysis conclusions, failures + hypotheses — plus syncs and fetched results when using the remote module. **Not meaningful (skip):** re-reading files, trivial typo fixes.

One entry per loop iteration is the right granularity: title it by the edit, fold sync/launch/fetch into Command lines, and complete the *current* entry's Command and Result lines in place as the iteration proceeds (the only permitted in-place edit — past entries stay append-only); no separate entries for the mechanics.

**Entry template** — timestamp from `date '+%Y-%m-%d %H:%M'`, keep only lines that apply:

```
## [2026-07-21 14:03] Short title
- What:
- Why:
- Command:
- Result:
- Next:
```

Command lines hold the executed command verbatim — never a paraphrase; fill in Result after fetching, with the actual exit status / output summary.

Entries carry references, not content: run ID, result paths, key numbers — never inline full stdout or large tables; read the files when needed.

**When a phase ends (no jobs running):** `mkdir -p docs/archive`, move the log to `docs/archive/progress-<phase>.md`, start a fresh `docs/progress.md` whose first entry carries over any still-open Next/questions, and revise `docs/state.md` for the new phase — the session-start tail stays short, the archive stays grep-able.

**Working state — `docs/state.md`:** the append-only log is the audit trail; `docs/state.md` is the revisable working state — current hypotheses, best config so far, known pitfalls. Rewrite it freely when conclusions change (it is working memory, not history).

## Memory discipline

Memory (Claude's auto memory) is auxiliary context, not an authoritative source — when it disagrees with the code, `docs/progress.md`, or `docs/state.md`, the files win.

- **Volatile state goes in the files, not in memory**: current experiment status, what was tried, what's running, open questions — history appended to `docs/progress.md`, current state kept in `docs/state.md` (see the log rules).
- Memory is only for durable facts (conventions, preferences, hard-won lessons); correct or delete it when it turns out stale.
- Memory is machine-local (`~/.claude/...`) and does not travel with the repo.
- Add rules to this file only error-driven: the same mistake happened twice, or the same correction recurred across sessions — never otherwise.

## Sync & remote execution (remote module)

### Sync up — before running anything remote

```bash
rsync -avz --exclude=.git --exclude=.venv --exclude=venv --exclude=__pycache__ \
  --exclude=data/ --exclude=checkpoints/ --exclude=results/ ./ "<SERVER>:<REMOTE_DIR>/"
```

(Shows the template-default values; use the current configuration section.)

Safety rails:

- NEVER add `--delete` unless I explicitly confirm it for this sync.
- On the first sync, or after `EXCLUDES` changed, run `rsync --dry-run` first and report what would transfer.

### Run — via ssh -tt (tty allocation)

```bash
ssh -tt "<SERVER>" "cd \"<REMOTE_DIR>\" && mkdir -p \"<RESULTS_REMOTE_DIR>/logs\" && set -o pipefail && <cmd> 2>&1 | tee -a \"<RESULTS_REMOTE_DIR>/logs/<run>.log\""
```

- `mkdir -p` so the log file can be created; `set -o pipefail` so the pipeline returns the command's real exit status, not tee's.
- Logs land inside `RESULTS_REMOTE_DIR`, i.e. inside the tree fetch-back downloads.
- Before any long job, smoke-test: run a 1–2 iteration / tiny-subset variant (or the script's dry-run flag) and confirm from the first output lines that imports, paths, and memory hold — only then launch the full run. If the script has no cheap variant, add one first (`--smoke` / max_steps env) as a logged low-risk change and re-sync; never silently skip the smoke test — ask me before launching if unsure.
- Jobs that must outlive the ssh session: wrap in tmux — launch detached with `ssh "<SERVER>" "tmux new -ds <name> '<cmd>'"`, poll with `ssh "<SERVER>" "tmux capture-pane -pt <name> | tail -n 40"`, and `ssh -tt "<SERVER>" "tmux attach -t <name>"` only to watch live. Polling cadence: first check ~30s after launch (early OOM/import/path failures), then widen (≈2 min → 5–10 min) while the run stays healthy. Name the run `YYYYMMDD-HHMM-<slug>` and reuse for the tmux session, wrapper, and log file — the same ID goes in the Command lines of the entries touching this run, linking the log to the fetched results.
- Done = the tmux session has ended and the log tail shows no traceback plus the expected outputs. A vanished session with a traceback is a failure — log it, don't fetch as success.
- For detached jobs, commit a `run_<name>.sh` wrapper that opens with `cd "<REMOTE_DIR>"` and holds the mkdir/pipefail/tee scaffolding, then launch `tmux new -ds <name> 'bash <REMOTE_DIR>/run_<name>.sh'` — that is how the persistent log lands in the fetched tree.
- Always quote the remote command string and remote paths.
- `<cmd>` must be a single simple command — no pipes or `&&` (wrap multi-step work in a script), and no single quotes in the tmux variant.
- To search the remote host, use `rg` over ssh (regex, gitignore-aware) — not `grep -r`/`find`; the local Grep tool doesn't reach the server.

### Fetch back — then analyze locally

```bash
rsync -avz "<SERVER>:<RESULTS_REMOTE_DIR>/" ./results/
```

Pull results and logs down before analyzing; all analysis happens locally with Claude, never on the server. Fetch-back overwrites same-named local files under `./results` — keep analysis artifacts elsewhere (e.g. `docs/`).

## Guardrails

- Never guess paths or config values — ask when missing or ambiguous.
- Claiming done requires execution: actually run the code or tests and confirm the output — compiling ≠ done; put the key output (or its file path) in the log entry.
- Log failures and dead ends too, with the hypothesis for what to try next.
- Never silently leave a running job behind: at session end, name what is still running (host, session name, reattach command), confirm it is logged in `docs/progress.md`, and say so explicitly.
