---
name: git-branching
description: |
  Guides Git branching strategy, branch naming, merging, merge conflicts and pull requests, and amends or squashes
  commits when the user asks. Use when creating, switching, merging or deleting branches, resolving conflicts,
  opening or merging a PR, or asked to amend the last commit or squash commits before a push.
  Not for: staging files and writing commit messages; use git-commit.
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(git branch --show-current), Bash(git remote -v)
---

# Git Branching

Only read-only git commands are pre-approved above. Everything else goes through the normal permission prompts.
Staging and commit messages always go through the `git-commit` skill.

## Safety

- Start with `git status`, the current branch and `git remote -v`.
- Ask before: switching branches with uncommitted changes, pulling, merging, rebasing, pushing, opening a PR,
  merging a PR, and deleting a local or remote branch. Never discard or stash the user's changes silently.
- Never force-push. If an approved rewrite (amend or squash) touched commits that are already pushed, stop and give
  the user the `git push --force-with-lease` command to run.
- Delete branches with `git branch -d`, and stop if Git refuses. Use `-D` only after the user confirms the work is
  merged; for example, a squash-merged PR, which `-d` doesn't recognize.

## Detect, don't assume

- **Remote and default branch:** `git remote`, then `git symbolic-ref --short refs/remotes/<remote>/HEAD`. If
  there is no remote, say so and skip the fetch, pull and push steps.
- **Strategy:** check CONTRIBUTING.md or README first, then existing practice (branches, history; committing
  straight to the default branch is a valid choice). Ask only if neither tells you.
- **Rough heuristic**, not a rule: releases several times a day → Trunk-Based; weekly → GitHub Flow; monthly or
  versioned releases → GitFlow.

## Branch naming

Format `<type>/<short-description>`, lowercase, words separated by hyphens.

Types: `feature/`, `fix/`, `refactor/`, `docs/`, `test/`, `chore/`; with GitFlow, also `hotfix/` and `release/`.
Examples: `feature/oauth-login`, `fix/null-pointer-in-payment`, `release/v1.2.0`.

## Start a branch

```bash
git fetch <remote>
git switch <default>
git pull --ff-only
git switch -c feature/short-description
```

If the user wants a baseline check, run the project's own test command (from README, Makefile or CI, e.g.
`go test ./...`).

## GitHub Flow

1. Commit on the branch with `git-commit`.
2. After approval, push: `git push -u <remote> <branch>`.
3. After approval, open a PR: `gh pr create --draft` unless told otherwise. Use a Conventional Commits style
   title, a body saying what changed and why, and no AI attribution.
4. Merge only when the user asks. Afterwards, with approval, delete the branch.

## Merge strategy

| Strategy                     | When to use                           |
| ---------------------------- | ------------------------------------- |
| **Merge commit** (`--no-ff`) | Long-lived features, GitFlow releases |
| **Squash merge**             | Feature branches, clean history       |
| **Rebase + fast-forward**    | Trunk-Based, short-lived branches     |

Rebasing rewrites the branch's commits, so use it only when the user asks.

## Merge conflicts

1. After approval: `git fetch <remote>`, then `git merge <remote>/<default>`, or rebase if the user chose that.
2. Resolve each conflict by understanding both sides. Never take `--ours` or `--theirs` wholesale; ask when the
   intent is unclear.
3. Confirm nothing is left with `git diff --name-only --diff-filter=U`, then run the project's tests.
4. Stage the resolved paths explicitly, then, after approval, finish with `git merge --continue` (or
   `git rebase --continue`). Keep Git's default merge message; Conventional Commits doesn't apply to merge commits.
5. To back out, use `git merge --abort` or `git rebase --abort`.

## Amend and squash on request

- **Amend:** when the user asks to amend changes into the last commit, do it. Stage the explicit paths and run
  `git commit --amend --no-edit`, or use the new message if one was given. If the commit is already pushed, see Safety.
- **Squash before push:** when the user asks, do it.
  1. Check that `@{upstream}` exists, and show `git log --oneline @{upstream}..HEAD` as the commits to squash.
     If there is no upstream, ask which commits or base to use.
  2. Run `git reset --soft <base>`, then make one commit through `git-commit`, with the message shown first.
  3. `git rebase -i` is interactive and unavailable.

## Recording the choice

If the strategy was chosen with the user, offer to note it in CONTRIBUTING.md: the strategy, the branch naming
format and the merge strategy. Write it only if the user agrees.
