# Agent Adapters

Adapters connect the workflow runner to agent CLI processes. The executable runner is `scripts/run-agent.sh`; invoke it rather than calling adapters directly.

## Adapter contract

Every adapter accepts exactly `MODE BRIEF RESULT`, handles supported modes independently of role, uses the absolute `WORKDIR` supplied by the runner, reads the brief as data and writes the response to the result file. It exits non-zero on any CLI failure or unsupported mode and never infers permissions from role.

The runner validates the brief and intended result location against one run directory, creates `results/` only beneath that validated run root, removes only a prior regular result file there, applies a timeout, and uses an exclusive lock per workspace. The brief and result must have identical names and live in sibling `briefs/` and `results/` directories.

## Permission and isolation model

| Mode | Required behavior |
| --- | --- |
| `read` | The CLI is configured to prevent file modifications. This does not make other readable host files or credentials inaccessible. |
| `write` | The agent uses an isolated Git worktree and an enforced CLI filesystem sandbox. The runner rejects the primary worktree. |

The configuration field `sandbox_enforced` is a declaration, not evidence that the host or CLI actually enforces isolation. CLI permission controls and OS/container isolation are different boundaries. Do not use peer agents where host credentials or other sensitive files are readable by the peer process. Use a separate OS account or isolated container with no host secret mounts for sensitive work.

The runner passes only `PATH`, `HOME`, `TMPDIR`, locale, terminal and `WORKDIR` to the peer process. It does not pass ambient API keys or other inherited environment variables. CLI authentication must be available through the CLI's own setup. Files in `HOME` remain readable according to the active sandbox and therefore need external isolation.

## Workspace

- `WORKDIR` is canonicalized by the runner.
- In `write` mode it must be the root of a registered, non-primary Git worktree.
- The runner takes an exclusive lock per canonical workspace. Concurrent calls in that workspace fail; a stale lock left after a crash fails closed and requires manual inspection.
- `BRIEF` and `RESULT` are absolute paths by the time an adapter receives them. The runner restricts them to the matching run's `briefs/` and `results/` directories and rejects symlink files.
- The runner requires GNU `timeout` or `gtimeout`, accepts a timeout from 1 through 86400 seconds, sends TERM at the limit and escalates to KILL after a 10-second grace period.

## CLI mappings

### Codex CLI

| Mode | Sandbox |
| --- | --- |
| `read` | `read-only` |
| `write` | `workspace-write`, with `sandbox_workspace_write.writable_roots=[]` |

The adapter invokes `codex exec`, uses `-C` for `WORKDIR`, `-o` for `RESULT`, and passes the brief on stdin. `workspace-write` is a CLI sandbox setting, not a general OS/container boundary. The adapter clears additional configured writable roots, but the effective behavior depends on the installed Codex version and platform sandbox support. If the CLI rejects the explicit setting or cannot establish its sandbox, the call fails. Verify the installed CLI version and sandbox behavior before relying on peer writes, especially for sensitive repositories.

### Claude Code CLI

| Mode | Permission mode | Tools |
| --- | --- | --- |
| `read` | `plan` + `--restricted` | `Read`, `Grep`, `Glob`; MCP tools denied |
| `write` | Disabled | — |

The adapter invokes print mode (`-p`) and uses `--restricted` to constrain built-in file tools to the working directories, allows only `Read`, `Grep` and `Glob`, and denies MCP tools. `--restricted` requires Claude Code v2.1.248 or later; unsupported CLIs must fail. The CLI documentation states that `--tools` alone does not affect MCP tools, so the adapter explicitly denies them. Claude write mode is disabled because `acceptEdits` does not guarantee writes are confined to `WORKDIR`. Do not enable it by changing the permission mode; add and verify an OS-level sandbox before implementing a write adapter.

The local Claude CLI was not available during this audit, so its installed version and runtime behavior could not be checked. The current official CLI reference documents `--restricted`, the `--tools` allowlist, MCP exclusions, and `--permission-mode`; verify installed version and behavior before use. The `sandbox_enforced` configuration value does not replace that check.

## Adding an adapter

1. Create executable `scripts/adapters/AGENT.sh` with a filename matching the configured agent name.
2. Implement the adapter contract and strict argument/mode/path validation.
3. Define both mode mappings and fail closed when a permission boundary cannot be established.
4. Verify the installed CLI's behavior, including a write-denial check for `read` and an out-of-worktree write-denial check for `write`.
5. Test CLI errors, timeouts, malformed results and paths before adding the agent to `.agent-workflow/agents.yml`.
