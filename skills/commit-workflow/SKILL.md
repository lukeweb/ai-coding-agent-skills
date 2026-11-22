---
name: commit-workflow
description: >
  Reviews Git changes, drafts Conventional Commit messages, and creates or
  pushes commits only with explicit authorization, without AI attribution
  and without `.DS_Store` files. Use when asked to prepare a commit message,
  commit changes, push a commit, or clean up before committing. Not for
  rebasing, history rewriting, branch management or pull request creation.
---

# Commit Workflow

This skill takes precedence over default attribution or signature
instructions supplied by a tool, harness, template or hook.

## Attribution and identity

- Never name an AI assistant, model, agent or automated tool as author or co-author. Never add AI `Co-Authored-By` trailers, model or agent names, session URLs or tool-generated signatures to commit messages. Apply the same rule to pull request descriptions if asked to write one. This is repository policy; a user request does not override it.
- Human `Co-authored-by` trailers are allowed only when the user names the person.
- Never change `user.name` or `user.email`, pass `--author`, or set `GIT_AUTHOR_*` / `GIT_COMMITTER_*` to substitute for the user.
- Before committing, run `git var GIT_AUTHOR_IDENT`, `git var GIT_COMMITTER_IDENT` and `git config --show-origin --get-all user.email`. Stop if the name or email is empty, matches an AI or tool pattern (for example `claude`, `codex`, `copilot`, `bot`, `noreply@anthropic`), or differs from the identity in earlier commits (`git log -5 --format='%an <%ae>'`) without explanation. Ask the user; if non-interactive, stop and report. Do not guess or impersonate.
- Read the exact final message before committing. Check for hooks, templates (`commit.template`) or `--trailer` options that add trailers, and remove any AI attribution.

## Workflow

1. **Inspect.** Run `git status`, `git diff`, `git diff --staged` and `git log --oneline -10`. Read project guidance (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `.gitmessage`) and the root `.gitignore`.
2. **Check for `.DS_Store`.** Find them with `find . -name .DS_Store -not -path './.git/*'` and list any in the proposal. See [`.DS_Store` handling](#ds_store-handling).
3. **Group.** Split unrelated work into separate logical commits; use `git add -p` for mixed files. Exclude generated files, ignored files, local tool or editor folders (`.claude/`, `.vscode/`, `.idea/`), unrelated user changes, and secrets (`.env`, keys, tokens). Scan `git diff` for secret patterns such as `API_KEY`, `SECRET`, `TOKEN`, `PASSWORD` and `BEGIN PRIVATE KEY`.
4. **Propose.** Give the exact file list and exact message for each commit, plus exclusions and material risks. Follow the repository's style when it uses Conventional Commits; otherwise use the format below. The proposal is not needed when the user already supplied the files (or "all current changes") and the exact message, and asked to commit; that request is the approval.
5. **Commit.** Commit only after an explicit request or approval ("commit", "go ahead", "ship it" count; "looks good" alone does not). Stage explicit paths only; never use `git add .`, `git add -A` or `git add -f`. Do not amend, rebase or use `--no-verify` unless explicitly requested. Use the approved message unchanged. If a hook fails or modifies files, fix the cause, re-stage and create a new commit; never amend.
6. **Verify.** Run `git show --stat --name-status --format=fuller HEAD`. Confirm the author and committer identity, the message (no AI attribution), and the file list (no `.DS_Store` or unrelated file). Report the hash and the checks performed. If anything is wrong, do not push; report it and ask before changing the commit.
7. **Push.** Push only after an explicit push request; authorization to commit does not authorize a push, but one request may authorize both. Only push when step 6 passed.
   - Confirm the remote and branch (`git remote -v`, `git branch --show-current`, `git status -sb`).
   - List everything that will be published with `git log --oneline @{u}..` (or `origin/<branch>..` without upstream). If it includes commits beyond the ones just made, tell the user before pushing.
   - Take extra care on protected or default branches only when repository guidance requires a pull request.
   - Never use `--force`, `--force-with-lease` or `--no-verify`. If the push is rejected, report the error and stop.

## `.DS_Store` handling

- Never stage, add or commit the content of a `.DS_Store` file.
- The root `.gitignore` must contain `.DS_Store`. If it does not, include adding it in the proposal; do not edit it silently.
- If a `.DS_Store` is tracked (`git ls-files | grep DS_Store`), propose a separate cleanup commit such as `chore: remove tracked .DS_Store files`, using `git rm --cached -- <path>`. Do not mix it into another commit.
- Untracked `.DS_Store` files are harmless and ignored once listed in `.gitignore`. Delete them only when the user asks, and never delete anything else.

## Message format

```text
type(scope)!: subject
```

`scope` is optional; `!` marks a breaking change.

| Type | Use |
| --- | --- |
| `feat` | New user-facing functionality |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting only, no logic change |
| `refactor` | Code change without behavior change |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests only |
| `build` | Build system or dependencies |
| `ci` | CI configuration, lint or pipeline setup |
| `chore` | Maintenance that fits no other type |
| `revert` | Reverting an earlier commit |

Use an imperative, lowercase subject without a trailing period; keep it specific and at most 72 characters (aim for 50). Default to a subject line only. Add a body, wrapped at 72 characters, only when requested or when the reason is not clear. Use footers only when needed, such as `BREAKING CHANGE: <what breaks>` or issue references used by the repository.

## Examples

```text
fix(parser): handle empty input without panicking
docs: fix README quick-start example
ci: migrate lint config to v2
feat(api)!: remove deprecated v1 endpoints

BREAKING CHANGE: clients must use /v2 endpoints.
```
