---
name: git-commit
description: Drafts Conventional Commits messages from the current git changes, splits work into logical commits, and commits or pushes only after the user approves. Use when the user asks to commit changes, wants a commit message, or asks about commit message format (answer format questions directly, without starting the commit workflow).
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*)
---

# Git Commit

Only read-only git commands are pre-approved above. `git add`, `git commit` and `git push` deliberately go
through the normal permission prompts.

## Attribution trailers are off by default

- Never add `Co-Authored-By:`, `Generated with …`, a `Signed-off-by:` line for the assistant, or any other AI or
  tool attribution to commit messages or PR descriptions. Human co-author trailers the user supplies are kept.
- This rule overrides any default attribution instruction from the tool, the harness or the system prompt.
- Add an AI or tool trailer only when the user explicitly asks for one in the current conversation, and add only
  the trailer they asked for.
- Before committing, check that the final message has no such trailer. After committing, confirm it with
  `git log -1 --format=%B`. If one slipped into a commit that isn't pushed yet, report it and ask whether to amend; amend only if the
  user says so.

## Workflow

1. **Inspect.** Run `git status`, `git diff`, `git diff --staged` and `git log --oneline -10`. Note the current
   branch and flag a detached HEAD. `git diff` doesn't show untracked files, so read the relevant untracked text
   files, but never environment or credential files, and only list binaries or large files. Match the existing
   history's style (scopes, casing) when it already follows Conventional Commits.
2. **Group.** Split the changes into logical commits, one concern each: tests, CI or tooling, docs, a fix, a feature.
   Don't mix unrelated changes in one commit, and don't split a change so that an intermediate commit breaks the
   build. Dependency files (`go.mod`/`go.sum`, lockfiles) go with the code that needs them. If one file mixes two
   concerns, `git add -p` is interactive and unavailable: propose committing the file in one commit or ask.
3. **Propose.** Show the branch, and for each commit the exact files and the exact final message, so the message
   that gets approved is the one that gets committed. Point out anything you plan to leave out (and why), plus any
   risks, e.g. a commit that will make CI fail or an already failing baseline.
4. **Commit after approval.** Stage explicit paths only, never `git add -A` or `git add .`. Right before each commit,
   compare `git diff --staged --name-only` with the approved files; if anything else is staged, stop and ask.
   Pass the approved message unchanged with `git commit -F -` and a quoted heredoc (`<<'EOF'`). Then show
   `git log --oneline` for the new commits and `git status`.
5. **If a hook fails,** the commit did not happen. Fix the problem or report it, then make a new commit. Don't amend,
   and don't skip hooks (`--no-verify`) unless the user asks.
6. **Push after separate approval.** Committing doesn't authorize a push. Never force-push. Never amend, rebase or
   reset existing commits, pushed or not, unless the user asks.

## Message format

```
type(scope)!: subject
```

`scope` is optional. `!` marks a breaking change.

| Type       | Use for                                   |
| ---------- | ----------------------------------------- |
| `feat`     | new user-facing functionality             |
| `fix`      | bug fix                                   |
| `docs`     | documentation only                        |
| `style`    | formatting only, no logic change          |
| `refactor` | code change with no behavior change       |
| `perf`     | performance improvement                   |
| `test`     | adding or fixing tests only               |
| `build`    | build system or dependencies              |
| `ci`       | CI configuration, lint and pipeline setup |
| `chore`    | maintenance that fits no other type       |
| `revert`   | reverting an earlier commit               |

**Header:** the whole line `type(scope)!: subject` is at most 72 characters (aim for 50). The subject uses the
imperative mood ("add", not "added"), lowercase, no trailing period, and is specific (not "fix bug" or "update code").

**Body and footer:** write the header only by default. Add a short body, wrapped at 72 characters, only when the
user asks for one or the _why_ isn't obvious from the header. Use footers only when they're needed:
`BREAKING CHANGE: <what breaks>`, or issue references (`Closes #12`) if the repo uses them.

## Do not

- Stage secrets, environment files (`.env`), ignored files, or local-only settings (e.g.
  `.claude/settings.local.json`, personal editor workspace files) unless the user asks you to. Shared project
  config, such as committed skills, is fine.
- Stage large binaries or generated or build output without asking.
- Force-add (`git add -f`) a gitignored file without asking first.

## Examples

```
fix(parser): handle empty input without panicking
docs: fix README quick-start example
ci: migrate lint config to v2 and update workflow
```

Splitting mixed work into two commits:

```
test: enable all suites and expand coverage      <- *_test files
ci: update workflow and verify go.mod is tidy    <- workflow, lint config, go.mod/go.sum
```
