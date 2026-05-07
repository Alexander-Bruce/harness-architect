---
name: harness-architect
description: Create and operate a reusable AI coding harness for any software project. Use when Codex needs to scaffold harness architecture documents, write AGENTS.md and quality gates, define JSONL communication protocols between agents, act as a main orchestrator that coordinates executor/evaluator agents and their subagents, run or define project verification commands, create execution plans, audit recurring agent failures, or convert repeated mistakes into docs, tests, scripts, and guardrails.
---

# Harness Architect

## Overview

Use this skill to turn a repository into an agent-ready development environment. A harness should inform agents with concise local knowledge, constrain risky behavior with architecture and policy boundaries, verify work with runnable checks, and correct repeated failures by promoting them into docs, tests, scripts, or plans.

This skill is project-agnostic. Detect the current repo's stack and generate harness artifacts that fit it; do not hard-code one project's names, packages, services, or business rules.

## Quick Commands

Run these from this skill directory, or use the script by absolute path.

Preferred (cross-platform) when PowerShell 7 is available:

```powershell
pwsh -File scripts/harness-architect.ps1 -Command commands
pwsh -File scripts/harness-architect.ps1 -Command scaffold -RepoPath <repo>
pwsh -File scripts/harness-architect.ps1 -Command docs-check -RepoPath <repo>
pwsh -File scripts/harness-architect.ps1 -Command audit -RepoPath <repo>
```

Fallback for macOS/Linux without `pwsh`:

```bash
./scripts/harness-architect.sh commands
./scripts/harness-architect.sh scaffold --repo <repo>
./scripts/harness-architect.sh docs-check --repo <repo>
./scripts/harness-architect.sh audit --repo <repo>
```

Common user prompts:

- "Use $harness-architect to create harness architecture docs for this project."
- "Use $harness-architect as the main agent and coordinate subagents for this task."
- "Use $harness-architect to plan, implement, test, and review this change."
- "Use $harness-architect to audit recurring agent mistakes and update the harness."

## Scaffolded Artifacts

The default scaffold creates or preserves:

- `AGENTS.md`: short agent entry point and reading order.
- `ARCHITECTURE.md`: current system map, target boundaries, invariants, risks.
- `docs/harness/README.md`: harness operating model.
- `docs/harness/agent-protocol.md`: JSONL message protocol and orchestrator/executor/evaluator contract.
- `docs/harness/quality-gates.md`: commands, hard gates, integration safety.
- `docs/harness/subagent-workflows.md`: main-agent and subagent prompt templates.
- `docs/exec-plans/README.md`: execution plan conventions.
- `docs/exec-plans/active/.gitkeep`
- `docs/exec-plans/completed/.gitkeep`
- `docs/exec-plans/tech-debt-tracker.md`: repeated failure cleanup queue.
- `scripts/harness-check.ps1`: generic document/audit/check runner.

Do not overwrite existing harness files unless the user asks or the script is run with `-Force`.

## Main-Agent Workflow

1. Locate the repo root and read existing `AGENTS.md` if present.
2. Detect stack and verification commands from repo files:
   - Maven: `pom.xml`, `mvn test`
   - Gradle: `build.gradle*`, `gradle test` or `./gradlew test`
   - Node: `package.json`, prefer `npm test` or project scripts
   - Python: `pyproject.toml`, `pytest` when configured
   - .NET: `*.sln` or `*.csproj`, `dotnet test`
3. Classify task risk:
   - Direct edit: tiny docs or local implementation with obvious tests.
   - RPI: multi-file, architecture, security, external API, data migration, async, billing, auth, or unclear behavior.
   - Plan artifact: long-running, risky, or cross-module work.
4. Use research-plan-implement:
   - Research concrete files, data flow, tests, and constraints.
   - Plan small slices, acceptance criteria, verification, and rollback.
   - Implement with narrow write sets.
   - Verify mechanically.
   - Harvest repeated mistakes into harness artifacts.

## Agent Orchestration

Only use subagents when the user explicitly asks for delegation/subagents and the environment supports them.

- Orchestrator: the main agent. Own the user goal, task graph, acceptance criteria, final integration, and final answer.
- Executor: own implementation planning and code changes. The executor may coordinate executor-side subagents for side tasks with disjoint write scopes.
- Evaluator: own acceptance criteria review, test strategy, independent review, and verification. The evaluator may coordinate evaluator-side subagents for focused review, test, security, or regression checks.
- Explorer or specialist subagents: optional leaf agents owned by executor or evaluator, not by the user directly.

Before implementation begins, require both executor and evaluator to confirm the implementation plan and acceptance criteria. The orchestrator resolves disagreements and emits the approved plan. After implementation, require evaluator review against the same acceptance criteria.

All inter-agent messages must use JSONL: one valid JSON object per line, no Markdown and no prose outside JSON. Load `references/agent-jsonl-protocol.md` and `references/subagent-templates.md` when drafting prompts. If subagents are unavailable, execute the same phases locally and say so briefly.

## Harness Design Rules

- Keep `AGENTS.md` short. Put detailed rules in focused docs.
- Prefer runnable checks over long prompt instructions.
- Define strict boundaries for secrets, generated files, external systems, migrations, and production data.
- Store long-lived plans in `docs/exec-plans/active/` and move completed plans to `completed/`.
- Add or update tests when changing behavior.
- Record current debt separately from hard gates so historical issues are visible without blocking every change.
- Convert repeated failures into one of: test, script, architecture invariant, AGENTS rule, quality gate, or debt tracker item.

## References

- Read `references/harness-model.md` for the concise harness mental model.
- Read `references/agent-jsonl-protocol.md` for the required inter-agent JSONL schema and phases.
- Read `references/subagent-templates.md` for delegation templates.
- Read `references/scaffold-guide.md` when adapting the default scaffold to a specific stack.
