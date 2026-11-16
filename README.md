# AI Coding Agent Skills

A personal, tool-agnostic collection of reusable skills for AI coding agents. Each skill captures guidance that can be reused across projects, so you do not have to write the same instructions again.

## Available skills

| Skill | Description |
| --- | --- |
| [Unit Testing](skills/unit-testing/SKILL.md) | Design, write, review, and improve reliable, maintainable unit tests. |

## Repository structure

```text
.
├── README.md
├── LICENSE
└── skills/
    └── unit-testing/
        └── SKILL.md
```

Each skill lives in its own directory and is defined by a `SKILL.md` file. The file begins with YAML metadata (`name` and `description`) followed by the instructions for the agent.

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
