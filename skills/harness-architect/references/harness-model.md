# Harness Model

Use this reference when designing or explaining a project harness.

## Four Jobs

- **Inform**: local docs tell agents what the project is, where important files live, and how to work.
- **Constrain**: architecture boundaries, forbidden paths, security rules, and style gates reduce unsafe degrees of freedom.
- **Verify**: tests, linters, build commands, audits, and screenshots give feedback outside the model's prose.
- **Correct**: repeated mistakes are harvested into tests, scripts, docs, and plans.

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

## Key Principles from Practice

### Test Quality Is the Multiplier

The reliability of the whole harness is bounded by how well the verification commands distinguish correct from incorrect behavior. A harness with perfect docs but weak tests will produce agents that pass all checks but ship broken behavior. Invest in test quality before scaling parallelism or agent count.

Concretely: aim for a verifier that is nearly always correct — false positives waste compute on unnecessary repairs, and false negatives allow regressions through. When running multiple agents in parallel, each agent's work is only as trustworthy as the evaluator's ability to catch errors.

### LLM-Aware Feedback

Structure harness output for agent consumption, not human reading:

- Exit codes signal pass/fail without prose parsing.
- Structured findings (`file:line:severity:message`) are consumed more reliably than narrative paragraphs.
- Keep raw output short; surface only what the agent needs to act on.
- Verbose build logs should be written to a file and referenced by path, not streamed inline.

### Parallel Isolation

When multiple agents work concurrently, they must own disjoint write scopes. Use separate working directories, git branches, or worktrees per agent. Conflicts at merge time are expensive — prevent them by enforcing scope boundaries before execution begins, not after.

The orchestrator is responsible for verifying that no two parallel agents claim overlapping write scopes in their `implementation_plan` before emitting `approved_plan`.

### Harvest Failures Deliberately

A one-time fix helps one task. A harvested fix helps every future agent. After each task, ask: what would have prevented this mistake? Then choose the lightest artifact that closes the gap — a one-line rule in `AGENTS.md`, a new assertion in a test, a script that validates the invariant, or a row in `tech-debt-tracker.md`.
