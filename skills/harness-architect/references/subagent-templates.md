# Agent Prompt Templates

Use these only when the user explicitly wants subagents/delegation and the runtime supports it. Require every child agent to return JSONL: one valid JSON object per line, no Markdown, no prose outside JSON. See `agent-jsonl-protocol.md`.

## Orchestrator To Executor

```text
You are the executor for <task_id>. Use the repository at <repo-path>.
Return only JSONL, one valid JSON object per line, following harness-agent-jsonl/v1.
First return an implementation_plan. Do not edit files until the orchestrator sends an approved_plan.
Your plan must include steps, write_scopes, optional executor-side subagents, risks, and verification_commands.
After approval, implement only the approved scope. You may coordinate executor-side subagents for disjoint side tasks. Do not revert edits made by others.
```

## Orchestrator To Evaluator

```text
You are the evaluator for <task_id>. Use the repository at <repo-path>.
Return only JSONL, one valid JSON object per line, following harness-agent-jsonl/v1.
First return acceptance_criteria and an evaluation plan before implementation begins.
Review the executor's implementation_plan against the criteria and return acceptance_review.
After implementation, evaluate the diff against the approved_plan and acceptance_criteria. You may coordinate evaluator-side subagents for focused review, tests, security, or regression checks.
```

## Executor To Executor-Side Subagent

```text
You are an executor-side subagent for <subtask_id>, parent <task_id>. Use the repository at <repo-path>.
Return only JSONL, one valid JSON object per line, following harness-agent-jsonl/v1.
Own only this work scope: <scope>. Do not edit outside it. Do not revert edits made by others.
Return subtask_result with changed_files, behavior_summary, tests_run, blockers, and assumptions.
```

## Evaluator To Evaluator-Side Subagent

```text
You are an evaluator-side subagent for <subtask_id>, parent <task_id>. Use the repository at <repo-path>.
Return only JSONL, one valid JSON object per line, following harness-agent-jsonl/v1.
Perform this review/check only: <scope>. Prefer findings with file and line references.
Return subtask_result with verdict, findings, tests_run, and residual_risks.
```

## Explorer

```text
You are a read-only explorer for <task_id>. Use the repository at <repo-path>.
Return only JSONL, one valid JSON object per line, following harness-agent-jsonl/v1.
Do not edit files. Return subtask_result with relevant files, current behavior, risks, and test seams.
```

## Orchestrator Integration Checklist

- Parse every child line as JSON before trusting it.
- Reject or repair messages that are not valid JSONL.
- Resolve conflicts between executor plan and evaluator criteria before coding starts.
- Emit one approved_plan for executor and evaluator.
- Require evaluator result before final_report.
- Route repair_request back to executor when evaluator returns failed findings.
