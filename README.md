# AI Coding Agent Skills

A personal, tool-agnostic collection of reusable skills for AI coding agents. Each skill captures guidance that can be reused across projects, so you do not have to write the same instructions again.

## Available skills

| Skill | Description |
| --- | --- |
| [Commit Workflow](skills/commit-workflow/SKILL.md) | Review Git changes and prepare Conventional Commit messages; commit and push only with explicit authorization, while preventing AI attribution and `.DS_Store` files. |
| [Unit Testing](skills/unit-testing/SKILL.md) | Language-agnostic guidance for designing, writing, reviewing and improving unit tests, including contracts, scenarios, test doubles, isolation, determinism, verification and flaky or failing tests. |
| [Multi-Agent Development](skills/multi-agent-dev/SKILL.md) | Coordinate a lead and separate coding-agent CLI processes for independent review, read-only exploration or isolated implementation, with configuration, handoff and safety guidance. |

## Repository structure

```text
.
├── .gitignore
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── LICENSE
└── skills/
    ├── commit-workflow/
    │   └── SKILL.md
    ├── multi-agent-dev/
    │   ├── SKILL.md
    │   ├── assets/
    │   │   └── agents.example.yml
    │   ├── references/
    │   │   ├── adapters.md
    │   │   ├── handoff-protocol.md
    │   │   └── prompts/
    │   │       ├── explorer.md
    │   │       ├── reviewer.md
    │   │       └── worker.md
    │   └── scripts/
    │       ├── run-agent.sh
    │       └── adapters/
    │           ├── claude.sh
    │           └── codex.sh
    └── unit-testing/
        └── SKILL.md
```

Each skill lives in its own directory and is defined by a `SKILL.md` file. The file begins with YAML metadata (`name` and `description`) followed by the instructions for the agent. Supporting assets, references, prompts and scripts live alongside it when needed. For `multi-agent-dev`, `agents.example.yml` is a proposal, not an active configuration; follow the skill's setup and permission guidance before invoking peer agents.

## Using a skill

Open the relevant `SKILL.md` and provide it to your coding agent using that agent's supported skill or instruction-loading mechanism. Support for automatic discovery and installation differs between agents; this repository does not currently include agent-specific installation configuration.

## Adding a skill

1. Create a descriptively named directory under `skills/`.
2. Add a `SKILL.md` with a short YAML `name` and `description` at the top.
3. Write focused instructions that explain when the skill applies, its scope, and how the agent should work.
4. Add the skill to the **Available skills** table above.

Keep skills focused and reusable. If guidance depends on a language, framework, or tool, state that clearly in the skill or keep it in a separate specialized skill.

## License

This repository is licensed under the MIT License. See [LICENSE](LICENSE) for details.
