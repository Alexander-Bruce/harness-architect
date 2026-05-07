#!/usr/bin/env sh
set -eu

ha_command="${1:-commands}"
shift || true

repo_path="."
force="0"

usage() {
  cat <<'EOF'
Harness Architect (POSIX wrapper)

Usage:
  harness-architect.sh commands
  harness-architect.sh scaffold --repo <path> [--force]
  harness-architect.sh docs-check --repo <path>
  harness-architect.sh audit --repo <path>

Notes:
  - Prefer PowerShell 7 (pwsh) when available — it produces the full harness including
    scripts/harness-check.ps1. This POSIX wrapper is a faithful fallback for macOS/Linux
    environments without pwsh.
  - pwsh equivalent:
      pwsh -File ./skills/harness-architect/scripts/harness-architect.ps1 -Command scaffold -RepoPath <repo>
EOF
}

has_pwsh() {
  command -v pwsh >/dev/null 2>&1
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --repo)
        repo_path="${2:-}"
        shift 2
        ;;
      --force)
        force="1"
        shift 1
        ;;
      *)
        echo "Unknown arg: $1" >&2
        exit 2
        ;;
    esac
  done
}

resolve_repo_root() {
  p="$1"
  if [ -d "$p" ]; then
    (cd "$p" && pwd)
  else
    (cd "$(dirname "$p")" && pwd)
  fi
}

write_file() {
  path="$1"
  content="$2"
  if [ -f "$path" ] && [ "$force" != "1" ]; then
    echo "keep existing: $path"
    return
  fi
  mkdir -p "$(dirname "$path")"
  printf "%s" "$content" >"$path"
  echo "wrote: $path"
}

# Accumulates all detected stacks and verify commands, separated by commas.
# Returns "stack1, stack2|cmd1\ncmd2" where | separates stacks from commands.
detect_stack() {
  root="$1"
  stacks=""
  cmds=""

  append() {
    label="$1"; cmd="$2"
    if [ -z "$stacks" ]; then
      stacks="$label"
      cmds="$cmd"
    else
      stacks="$stacks, $label"
      cmds="$cmds
$cmd"
    fi
  }

  if [ -f "$root/pom.xml" ]; then append "Java/Maven" "mvn test"; fi
  if [ -f "$root/build.gradle" ] || [ -f "$root/build.gradle.kts" ]; then
    if [ -f "$root/gradlew" ]; then
      append "Gradle" "./gradlew test"
    else
      append "Gradle" "gradle test"
    fi
  fi
  if [ -f "$root/package.json" ]; then append "Node/package.json" "npm test"; fi
  if [ -f "$root/pyproject.toml" ] || [ -f "$root/requirements.txt" ]; then append "Python" "pytest"; fi
  if [ -f "$root/go.mod" ]; then append "Go" "go test ./..."; fi
  if [ -f "$root/Cargo.toml" ]; then append "Rust/Cargo" "cargo test"; fi
  if [ -f "$root/Gemfile" ]; then append "Ruby" "bundle exec rspec"; fi
  if [ -f "$root/Makefile" ]; then append "Make" "make test"; fi

  if [ -z "$stacks" ]; then stacks="Unknown"; cmds="<fill project test command>"; fi

  printf "%s|%s" "$stacks" "$cmds"
}

agents_md() {
  stack="$1"
  verify_first="$2"
  cat <<EOF
# Agent Guide

This file is the short entry point for agents working in this repository. Keep durable detail in focused docs and scripts.

## Read First

- [ARCHITECTURE.md](ARCHITECTURE.md): system map, target boundaries, invariants, risks.
- [docs/harness/README.md](docs/harness/README.md): harness operating model.
- [docs/harness/agent-protocol.md](docs/harness/agent-protocol.md): JSONL communication protocol for orchestrator, executor, evaluator, and subagents.
- [docs/harness/quality-gates.md](docs/harness/quality-gates.md): verification and hard gates.
- [docs/harness/subagent-workflows.md](docs/harness/subagent-workflows.md): orchestration templates.
- [docs/exec-plans/tech-debt-tracker.md](docs/exec-plans/tech-debt-tracker.md): recurring failure cleanup queue.

## Project Stack

- Detected: $stack

## Working Rules

- When using multiple agents, all inter-agent responses must be JSONL: one valid JSON object per line, no prose outside JSON.
- Do not add new hard-coded secrets, credentials, access codes, tokens, or production URLs.
- Prefer small write scopes; avoid broad refactors unless explicitly requested.
- Add or update tests when changing behavior.

## Verification

- Project test: \`$verify_first\`
- Quick audit: \`sh scripts/harness-check.sh audit\` (or \`pwsh -File scripts/harness-check.ps1 -Mode audit\`)
- Full verify: \`pwsh -File scripts/harness-check.ps1 -Mode verify\`
EOF
}

architecture_md() {
  stack="$1"
  cat <<EOF
# Architecture

## Purpose

This repository uses a harness so coding agents can work reliably: short entry points, explicit boundaries, mechanical checks, and a feedback loop that turns repeated failures into docs/tests/scripts.

## Stack

- Detected: $stack

## Current System Map

- Entry points: TODO
- Core modules: TODO
- Data stores: TODO
- External systems: TODO
- Background jobs/queues: TODO
- Deployment/runtime: TODO

\`\`\`mermaid
flowchart LR
    User["User or external caller"] --> Entry["Entry points"]
    Entry --> Core["Core application"]
    Core --> Data["Data/storage"]
    Core --> External["External systems"]
\`\`\`

## Target Boundaries

- UI/API boundary: validate external input and shape responses.
- Domain/application boundary: own business rules and workflows.
- Infrastructure boundary: wrap databases, files, HTTP clients, SDKs, queues, and other side effects.
- Configuration boundary: keep secrets and environment-specific values outside source code.
- Test boundary: isolate live external systems behind fakes/mocks unless an integration run is explicitly requested.

## Invariants

- No new hard-coded secrets, credentials, tokens, or production endpoint values.
- No live production mutations from automated tests.
- No broad refactors inside unrelated tasks.
- Generated/build output is not source of truth.
- Every behavior change needs a known verification path.
EOF
}

harness_readme() {
  cat <<'EOF'
# Repository Harness

This folder defines how agents should work in this repo.

## Model

- Inform with concise local docs.
- Constrain with architecture boundaries and hard gates.
- Verify with runnable commands.
- Correct by turning repeated failures into tests, scripts, docs, or plans.

## Roles

- Orchestrator: owns task graph, acceptance criteria, final integration.
- Executor: proposes implementation plan, makes code changes, may use executor-side subagents for disjoint tasks.
- Evaluator: proposes acceptance criteria and independently verifies, may use evaluator-side subagents for focused review.

## Contract

- Executor and evaluator must agree on a single plan + acceptance criteria before edits begin.
- Inter-agent communication is JSONL only: one valid JSON object per line.
EOF
}

agent_protocol_md() {
  cat <<'EOF'
# Agent JSONL Protocol

All agent-to-agent messages MUST be JSONL: one JSON object per line. No prose outside JSON.

## Required Fields

- schema_version: "harness-agent-jsonl/v1"
- message_type: one of the types listed below
- from / to: role ids (orchestrator, executor, evaluator, or subagent id)
- task_id, parent_task_id (null for root)
- phase: intake | plan_sync | execution | evaluation | repair | closeout
- status: open | proposed | approved | blocked | running | passed | failed | complete
- seq: monotonically increasing integer within sender stream
- payload: message-specific object

## Message Types

- task_brief, implementation_plan, acceptance_criteria, acceptance_review, approved_plan
- subtask_assignment, subtask_result, progress
- change_summary, evaluation_result, repair_request, final_report

## Required Phase Sequence

1. task_brief → executor and evaluator
2. implementation_plan ← executor
3. acceptance_criteria ← evaluator
4. acceptance_review ← executor and evaluator (cross-review)
5. approved_plan → executor and evaluator
6. subtask_assignment / subtask_result (as needed, within executor or evaluator)
7. change_summary ← executor
8. evaluation_result ← evaluator
9. repair_request → executor (loop back to 7 if failed)
10. final_report → user

## Example

{"schema_version":"harness-agent-jsonl/v1","message_type":"implementation_plan","from":"executor","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"plan_sync","status":"proposed","seq":1,"payload":{"summary":"Add request validation and tests.","steps":["inspect boundary","add validator","add tests","run verification"],"write_scopes":["src/"],"risks":["API compatibility"],"verification_commands":["<fill>"]}}
EOF
}

quality_gates_md() {
  verify="$1"
  cat <<EOF
# Quality Gates

## Standard Verification

- Project tests: \`$verify\`
- Harness audit: \`sh scripts/harness-check.sh audit\` (POSIX) or \`pwsh -File scripts/harness-check.ps1 -Mode audit\`
- Full verify: \`pwsh -File scripts/harness-check.ps1 -Mode verify\`

## Hard Gates For New Work

- No new hard-coded secrets, credentials, tokens, or production endpoint values.
- No automated tests that mutate live production systems.
- No unrelated generated/build/IDE metadata changes.
- No broad refactors hidden inside feature or bug tasks.
- Behavior changes must have tests or an explicit verification note.
- Security, auth, billing, migration, async, external API, and data-loss risks require RPI and usually an execution plan.

## Baseline Debt

Existing warnings belong in \`docs/exec-plans/tech-debt-tracker.md\`. New work should not expand baseline debt.
EOF
}

subagent_workflows_md() {
  cat <<'EOF'
# Subagent Workflows

Use subagents only when the runtime supports them and the user asked for delegation.
All child-agent output must be JSONL: one valid JSON object per line.

## Orchestrator

- Own the user goal, task graph, acceptance criteria, approved plan, final integration, and final answer.
- Send task_brief to executor and evaluator.
- Require implementation_plan and acceptance_criteria before coding starts.
- Resolve disagreements and emit approved_plan.
- Route repair_request back to executor if evaluator fails the change.
- Emit final_report only after evaluator returns evaluation_result.

## Executor

- Own implementation planning and code changes.
- Return implementation_plan before editing files.
- Coordinate executor-side subagents for disjoint side tasks when useful.
- Return change_summary with changed files, behavior, tests run, assumptions, and blockers.

## Evaluator

- Own acceptance criteria, evaluation plan, independent review, and test verification.
- Return acceptance_criteria before implementation starts.
- Review executor plan and return acceptance_review.
- Coordinate evaluator-side subagents for focused review, test, security, or regression checks.
- Return evaluation_result with verdict, findings, tests, and residual risk.

## Suggested Delegation

- Executor-side: implement in a contained module, write unit tests (disjoint write scopes).
- Evaluator-side: review diffs, run verification, write acceptance checklists.

## Protocol Reference

See docs/harness/agent-protocol.md.
EOF
}

exec_plans_readme() {
  cat <<'EOF'
# Execution Plans

Use this directory for durable plans that should survive context windows.

- active/: plans currently being executed.
- completed/: completed plans and design history.
- tech-debt-tracker.md: recurring cleanup queue.

Small tasks can use an ephemeral conversation plan. Risky or long-running tasks should have a checked-in plan.
EOF
}

tech_debt_md() {
  cat <<'EOF'
# Technical Debt Tracker

Add items when repeated failures or known risks should be made visible but cannot be fixed immediately.

| Priority | Area | Finding | Preferred constraint | Status |
| --- | --- | --- | --- | --- |
| P0 | Harness | Initial scaffold needs project-specific refinement. | Fill project map, commands, boundaries, and known risks after codebase research. | Open |
EOF
}

# Basic POSIX audit: checks required harness files and scans for secret-like patterns.
posix_audit() {
  root="$1"
  issues=0

  for p in \
    "AGENTS.md" \
    "ARCHITECTURE.md" \
    "docs/harness/README.md" \
    "docs/harness/agent-protocol.md" \
    "docs/harness/quality-gates.md" \
    "docs/harness/subagent-workflows.md" \
    "docs/exec-plans/tech-debt-tracker.md"
  do
    if [ ! -f "$root/$p" ]; then
      echo "Missing harness file: $p" >&2
      issues=$((issues + 1))
    fi
  done

  # Scan source files for secret-like patterns (best-effort, no external deps).
  if command -v grep >/dev/null 2>&1; then
    found=$(find "$root" \
      \( -path "*/.git" -o -path "*/node_modules" -o -path "*/target" \
         -o -path "*/dist" -o -path "*/build" -o -path "*/.venv" \) -prune \
      -o -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" \
                    -o -name "*.java" -o -name "*.go" -o -name "*.rs" \
                    -o -name "*.yml" -o -name "*.yaml" -o -name "*.env" \) -print \
      | xargs grep -lE '(?i)(api[_-]?key|secret|password|token)\s*[:=]\s*\S{8,}' 2>/dev/null || true)
    if [ -n "$found" ]; then
      echo "Warning: possible secret-like values in:"
      echo "$found"
    fi
  fi

  if [ "$issues" -gt 0 ]; then
    echo ""
    echo "Audit failed: $issues issue(s) found." >&2
    exit 1
  fi
  echo "Harness audit passed (POSIX mode; install pwsh for full check)."
}

run_pwsh() {
  force_flag=""
  if [ "$force" = "1" ]; then force_flag="-Force"; fi
  pwsh -File ./skills/harness-architect/scripts/harness-architect.ps1 \
    -Command "$ha_command" -RepoPath "$repo_path" $force_flag
}

case "$ha_command" in
  commands)
    usage
    exit 0
    ;;
  scaffold|docs-check|audit)
    parse_args "$@"
    ;;
  *)
    echo "Unknown command: $ha_command" >&2
    usage
    exit 2
    ;;
esac

if has_pwsh; then
  run_pwsh
  exit $?
fi

root="$(resolve_repo_root "$repo_path")"
stack_info="$(detect_stack "$root")"
stack="${stack_info%%|*}"
all_cmds="${stack_info#*|}"
verify_first="$(printf "%s" "$all_cmds" | head -n1)"

case "$ha_command" in
  scaffold)
    write_file "$root/AGENTS.md" "$(agents_md "$stack" "$verify_first")"
    write_file "$root/ARCHITECTURE.md" "$(architecture_md "$stack")"
    write_file "$root/docs/harness/README.md" "$(harness_readme)"
    write_file "$root/docs/harness/agent-protocol.md" "$(agent_protocol_md)"
    write_file "$root/docs/harness/quality-gates.md" "$(quality_gates_md "$verify_first")"
    write_file "$root/docs/harness/subagent-workflows.md" "$(subagent_workflows_md)"
    write_file "$root/docs/exec-plans/README.md" "$(exec_plans_readme)"
    write_file "$root/docs/exec-plans/tech-debt-tracker.md" "$(tech_debt_md)"
    write_file "$root/docs/exec-plans/active/.gitkeep" ""
    write_file "$root/docs/exec-plans/completed/.gitkeep" ""
    echo "NOTE: scripts/harness-check.ps1 not generated (no pwsh). Install PowerShell 7 and rerun scaffold for full harness tooling."
    ;;
  docs-check)
    for p in \
      "AGENTS.md" \
      "ARCHITECTURE.md" \
      "docs/harness/README.md" \
      "docs/harness/agent-protocol.md" \
      "docs/harness/quality-gates.md" \
      "docs/harness/subagent-workflows.md" \
      "docs/exec-plans/tech-debt-tracker.md"
    do
      if [ ! -f "$root/$p" ]; then
        echo "Missing harness file: $p" >&2
        exit 1
      fi
    done
    echo "All required harness files exist."
    ;;
  audit)
    posix_audit "$root"
    ;;
esac
