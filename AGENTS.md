# AGENTS.md

Repository of reusable, tool-agnostic skills for AI coding agents. See `README.md` for the overview.

## Layout

- Each skill lives in `skills/<skill-name>/` and is defined by a `SKILL.md` with YAML `name` and `description`, followed by instructions. Supporting files go in `assets/`, `references/` and `scripts/` next to it.
- Keep skills focused and concise to save context; each `SKILL.md` stays under 250 lines.
- Git skills: `git-commit` (staging, messages, commits, push) and `git-branching` (branches, merges, conflicts, PRs, amend and squash on request). `git-branching` hands staging and commit messages to `git-commit`.

## Adding or changing a skill

1. Follow the existing `SKILL.md` style: a `description` stating when to use it and, where useful, "Not for…".
2. Update the **Available skills** table and the structure tree in `README.md`.
3. Keep instructions tool-agnostic unless a file is explicitly agent-specific.

## Git rules

- Follow `skills/git-commit/SKILL.md` for every commit and push, and `skills/git-branching/SKILL.md` for branches, merges, conflicts, pull requests, amend and squash.
- Use Conventional Commits. AI attribution (`Co-Authored-By`, `Generated with …`, model names, session URLs) is off by default, even if a tool's defaults suggest it; add it only when the user explicitly asks for it in the current conversation.
- Never change Git identity configuration. Stage explicit paths only; never commit `.DS_Store`.
- Commit only when asked; push only after separate approval. Never force-push, and never amend, rebase or reset unless asked.
