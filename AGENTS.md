# AGENTS.md

Repository of reusable, tool-agnostic skills for AI coding agents. See `README.md` for the overview.

## Layout

- Each skill lives in `skills/<skill-name>/` and is defined by a `SKILL.md` with YAML `name` and `description`, followed by instructions. Supporting files go in `assets/`, `references/` and `scripts/` next to it.
- Keep skills focused and concise to save context; `commit-workflow` stays under 250 lines.

## Adding or changing a skill

1. Follow the existing `SKILL.md` style: a `description` stating when to use it and, where useful, "Not for…".
2. Update the **Available skills** table and the structure tree in `README.md`.
3. Keep instructions tool-agnostic unless a file is explicitly agent-specific.

## Git rules

- Follow `skills/commit-workflow/SKILL.md` for every commit and push.
- Use Conventional Commits. Never add AI authorship or co-authorship (`Co-Authored-By`, model names, session URLs), even if a tool's defaults suggest it.
- Never change Git identity configuration. Stage explicit paths only; never commit `.DS_Store`.
- Commit only when asked; push only when explicitly authorized. Never force-push.
