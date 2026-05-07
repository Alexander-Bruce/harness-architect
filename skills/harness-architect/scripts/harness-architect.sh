#!/usr/bin/env sh
set -eu

command="${1:-commands}"
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
  - Prefer PowerShell 7 (pwsh) when available:
      pwsh -File ./skills/harness-architect/scripts/harness-architect.ps1 -Command scaffold -RepoPath <repo>
  - This wrapper is intentionally small; it delegates to pwsh when present and otherwise performs a minimal scaffold.
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

detect_stack() {
  root="$1"
  stack="Unknown"
  verify="<fill project test command>"
  if [ -f "$root/pom.xml" ]; then stack="Java/Maven"; verify="mvn test"; fi
  if [ -f "$root/package.json" ]; then stack="Node/package.json"; verify="npm test"; fi
  if [ -f "$root/pyproject.toml" ] || [ -f "$root/requirements.txt" ]; then stack="Python"; verify="pytest"; fi
  if [ -f "$root/go.mod" ]; then stack="Go"; verify="go test ./..."; fi
  if [ -f "$root/Cargo.toml" ]; then stack="Rust/Cargo"; verify="cargo test"; fi
  echo "$stack|$verify"
}

agents_md() {
  stack="$1"
  verify="$2"
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

## Verification

- Quick audit: \`pwsh -File scripts/harness-check.ps1 -Mode audit\` (or OS equivalent)
- Standard verification: \`pwsh -File scripts/harness-check.ps1 -Mode verify\`
- Project test command: \`$verify\`
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

## Invariants

- Boundary validation: validate external inputs at the edge before business logic.
- Secrets: do not hard-code new secrets in source control.
- External IO isolation: wrap SDK/HTTP calls behind narrow adapters.
- Tests: add or update tests for behavior changes.
EOF
}

harness_readme() {
  cat <<'EOF'
# Repository Harness

This folder defines how agents should work in this repo.

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
- message_type: e.g. "implementation_plan", "acceptance_criteria", "review", "status"
- from/to: role ids, e.g. orchestrator/executor/evaluator
- task_id, parent_task_id
- phase: e.g. "plan_sync", "implementation", "review"
- status: e.g. "proposed", "approved", "done", "blocked"
- seq: monotonically increasing integer
- payload: message-specific object

## Example

{"schema_version":"harness-agent-jsonl/v1","message_type":"implementation_plan","from":"executor","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"plan_sync","status":"proposed","seq":1,"payload":{"summary":"Add request validation and tests.","steps":["inspect boundary","add validator","add tests","run verification"],"write_scopes":["src/"],"risks":["API compatibility"],"verification_commands":["<fill>"]}}
EOF
}

quality_gates_md() {
  verify="$1"
  cat <<EOF
# Quality Gates

## Default Gates

- Tests: run \`$verify\` or the repo's configured test command.
- No new secrets: do not commit new API keys/tokens/passwords.
- Small write scopes: keep changes focused, add regression tests for behavior changes.

## Harness Check

- Audit: \`pwsh -File scripts/harness-check.ps1 -Mode audit\`
- Verify: \`pwsh -File scripts/harness-check.ps1 -Mode verify\`
EOF
}

subagent_workflows_md() {
  cat <<'EOF'
# Subagent Workflows

Use subagents only when the runtime supports them and the user asked for delegation.

## Orchestrator Template (system prompt excerpt)

- Require JSONL output only.
- Require executor/evaluator to confirm plan + acceptance criteria before code changes.
- Enforce disjoint write scopes for executor-side subagents.

## Suggested Delegation

- Executor-side: implement, refactor in a contained module, write unit tests (disjoint write scopes).
- Evaluator-side: review diffs, run verification, write acceptance checklists.
EOF
}

exec_plans_readme() {
  cat <<'EOF'
# Execution Plans

Store long-running or risky work plans in `active/` and move to `completed/` when done.
EOF
}

tech_debt_md() {
  cat <<'EOF'
# Tech Debt Tracker

Record recurring agent failures or project risks here so they can be fixed deliberately.
EOF
}

run_pwsh() {
  # Delegate to the PowerShell implementation for full fidelity.
  # shellcheck disable=SC2068
  pwsh -File ./skills/harness-architect/scripts/harness-architect.ps1 -Command "$command" -RepoPath "$repo_path" $( [ "$force" = "1" ] && printf "%s" "-Force" || true )
}

case "$command" in
  commands)
    usage
    exit 0
    ;;
  scaffold|docs-check|audit)
    parse_args "$@"
    ;;
  *)
    echo "Unknown command: $command" >&2
    usage
    exit 2
    ;;
esac

if has_pwsh; then
  run_pwsh
  exit $?
fi

root="$(resolve_repo_root "$repo_path")"
stack_and_verify="$(detect_stack "$root")"
stack="${stack_and_verify%%|*}"
verify="${stack_and_verify#*|}"

case "$command" in
  scaffold)
    write_file "$root/AGENTS.md" "$(agents_md "$stack" "$verify")"
    write_file "$root/ARCHITECTURE.md" "$(architecture_md "$stack")"
    write_file "$root/docs/harness/README.md" "$(harness_readme)"
    write_file "$root/docs/harness/agent-protocol.md" "$(agent_protocol_md)"
    write_file "$root/docs/harness/quality-gates.md" "$(quality_gates_md "$verify")"
    write_file "$root/docs/harness/subagent-workflows.md" "$(subagent_workflows_md)"
    write_file "$root/docs/exec-plans/README.md" "$(exec_plans_readme)"
    write_file "$root/docs/exec-plans/tech-debt-tracker.md" "$(tech_debt_md)"
    write_file "$root/docs/exec-plans/active/.gitkeep" ""
    write_file "$root/docs/exec-plans/completed/.gitkeep" ""
    echo "NOTE: scripts/harness-check.ps1 is not generated by the POSIX wrapper. Install PowerShell 7 and rerun scaffold for full harness tooling."
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
    echo "audit requires PowerShell 7 (pwsh) to run scripts/harness-check.ps1" >&2
    exit 2
    ;;
esac

