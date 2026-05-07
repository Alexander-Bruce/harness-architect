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
- `scripts/harness-check.ps1`: generic document/audit/check runner (PowerShell 7).

Do not overwrite existing harness files unless the user asks or the script is run with `-Force`.

## Main-Agent Workflow

### Phase 1 — Research

Read existing `AGENTS.md` and `ARCHITECTURE.md` if present. Locate the repo root and inspect:

- Build files to detect stack (see `references/scaffold-guide.md`).
- Entry points, core modules, external systems, generated output paths.
- Existing tests and verification commands.
- Known constraints or risks already documented.

Do not edit files during Research. Return findings as a concise summary.

### Phase 2 — Plan

Classify task risk before proposing any implementation:

- **Direct edit**: tiny doc or local implementation with obvious tests and no cross-module impact.
- **RPI** (research-plan-implement): multi-file, architecture, security, external API, data migration, async, billing, auth, or unclear behavior.
- **Plan artifact**: long-running, risky, or cross-module work — write a checked-in execution plan to `docs/exec-plans/active/`.

For RPI and plan-artifact tasks, propose:

- Explicit write scope (files/modules to be changed).
- Acceptance criteria — measurable pass/fail conditions.
- Verification commands.
- Rollback approach for risky changes.

### Phase 3 — Implement

After the plan is approved (by user or evaluator):

- Keep write scope narrow. Do not touch files outside the approved scope.
- Prefer small, independently verifiable commits.
- Do not revert edits made by other agents in parallel.

### Phase 4 — Verify

Run verification mechanically after every change:

- Execute all project test commands detected in Phase 1.
- Run `harness-check.ps1 -Mode verify` (or POSIX equivalent) for doc and secret checks.
- Surface failures with file and line references, not prose summaries.
- **LLM-aware feedback**: provide structured output (exit codes, counts, file:line findings) rather than raw model-generated prose. Agents consume structured feedback more reliably than narrative.

### Phase 5 — Harvest

Convert repeated failures into permanent harness artifacts. For each recurring mistake, choose exactly one:

| Failure pattern | Preferred artifact |
|---|---|
| Agent ignores boundary | New invariant in `ARCHITECTURE.md` |
| Agent omits test for class of change | New quality gate in `quality-gates.md` |
| Agent repeats same misunderstanding | New rule in `AGENTS.md` (one line) |
| Same category of bug recurs | New regression test |
| Risk is real but not urgent | Row in `tech-debt-tracker.md` |
| Complex multi-step error-prone operation | New script in `scripts/` |

## Agent Orchestration

Only use subagents when the user explicitly asks for delegation/subagents and the environment supports them.

- **Orchestrator**: the main agent. Own the user goal, task graph, acceptance criteria, final integration, and final answer.
- **Executor**: own implementation planning and code changes. The executor may coordinate executor-side subagents for side tasks with disjoint write scopes.
- **Evaluator**: own acceptance criteria review, test strategy, independent review, and verification. The evaluator may coordinate evaluator-side subagents for focused review, test, security, or regression checks.
- **Explorer / specialist subagents**: optional leaf agents owned by executor or evaluator, not by the user directly.

**When not to use subagents**: single-file changes, tasks under ~30 minutes of model time, environments that don't natively support parallel agents. Execute the same phases locally and say so briefly.

**Parallel isolation**: when multiple executor-side subagents run concurrently, they must own disjoint write scopes. Use separate working directories or git worktrees to avoid merge conflicts. Each subagent commits to its own branch; the orchestrator merges after evaluator review.

Before implementation begins, require both executor and evaluator to confirm the implementation plan and acceptance criteria. The orchestrator resolves disagreements and emits the approved plan. After implementation, require evaluator review against the same acceptance criteria.

All inter-agent messages must use JSONL: one valid JSON object per line, no Markdown and no prose outside JSON. Load `references/agent-jsonl-protocol.md` and `references/subagent-templates.md` when drafting prompts.

## Harness Design Rules

- Keep `AGENTS.md` short. Put detailed rules in focused docs.
- Prefer runnable checks over long prompt instructions.
- Define strict boundaries for secrets, generated files, external systems, migrations, and production data.
- Store long-lived plans in `docs/exec-plans/active/` and move completed plans to `completed/`.
- Add or update tests when changing behavior.
- Record current debt separately from hard gates so historical issues are visible without blocking every change.
- Convert repeated failures into one of: test, script, architecture invariant, AGENTS rule, quality gate, or debt tracker item.
- **Test quality is the multiplier**: the reliability of the whole harness is bounded by how well the verification commands distinguish correct from incorrect behavior. Improve test coverage before scaling parallelism.
- **Structure feedback for agents, not humans**: exit codes, structured JSON findings, and file:line references are more reliable agent inputs than narrative summaries.

## References

- Read `references/harness-model.md` for the concise harness mental model.
- Read `references/agent-jsonl-protocol.md` for the required inter-agent JSONL schema and phases.
- Read `references/subagent-templates.md` for delegation templates.
- Read `references/scaffold-guide.md` when adapting the default scaffold to a specific stack.
