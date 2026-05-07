# Harness Model

Use this reference when designing or explaining a project harness.

## Four Jobs

- Inform: local docs tell agents what the project is, where important files live, and how to work.
- Constrain: architecture boundaries, forbidden paths, security rules, and style gates reduce unsafe degrees of freedom.
- Verify: tests, linters, build commands, audits, and screenshots give feedback outside the model's prose.
- Correct: repeated mistakes are harvested into tests, scripts, docs, and plans.

## Core Artifacts

- `AGENTS.md`: compact agent entry point.
- `ARCHITECTURE.md`: current map, target boundaries, invariants.
- `docs/harness/quality-gates.md`: commands and non-negotiable gates.
- `docs/harness/subagent-workflows.md`: main-agent/subagent roles and prompt templates.
- `docs/exec-plans/`: long-lived plans and design history.
- `scripts/harness-check.*`: mechanical checks.

## Good Harness Traits

- Project-local and checked in.
- Short where always loaded; detailed only where needed.
- Optimized for the next agent, not just the current task.
- Fails usefully: a command should tell the agent what to fix or where to look.
- Separates baseline debt from newly introduced regressions.
