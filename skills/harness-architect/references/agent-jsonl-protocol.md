# Agent JSONL Protocol

Use this protocol for every message between orchestrator, executor, evaluator, and their subagents.

## Transport Rule

Every agent response to its parent must be JSONL:

- One valid JSON object per line.
- No Markdown, no code fences, no prose outside JSON.
- Each line must be independently parseable.
- Use arrays inside a field when a message needs multiple paths, findings, or commands.
- Prefer compact factual payloads over narrative.

## Envelope

Required fields:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"task_brief","from":"orchestrator","to":"executor","task_id":"task-001","parent_task_id":null,"phase":"intake","status":"open","seq":1,"payload":{}}
```

Field meanings:

- `schema_version`: always `harness-agent-jsonl/v1`.
- `message_type`: one of the message types below.
- `from`: sender id or role.
- `to`: recipient id or role.
- `task_id`: stable id for this task or subtask.
- `parent_task_id`: parent id, or `null` for the root task.
- `phase`: `intake`, `plan_sync`, `execution`, `evaluation`, `repair`, or `closeout`.
- `status`: `open`, `proposed`, `approved`, `blocked`, `running`, `passed`, `failed`, or `complete`.
- `seq`: monotonically increasing integer within the sender's stream.
- `payload`: message-specific object.

## Message Types

- `task_brief`: orchestrator sends goal, constraints, repo path, context links, and requested output.
- `implementation_plan`: executor proposes plan, write scopes, subagent split, risks, and commands.
- `acceptance_criteria`: orchestrator or evaluator states objective pass/fail criteria.
- `acceptance_review`: evaluator accepts, amends, or rejects criteria/plan before coding.
- `approved_plan`: orchestrator resolves plan and criteria into the version executor must implement and evaluator must judge.
- `subtask_assignment`: executor/evaluator assigns work to a child subagent.
- `subtask_result`: child subagent returns findings, changed files, tests, or blockers.
- `progress`: agent reports current state without changing plan.
- `change_summary`: executor reports changed files, behavior, assumptions, and verification run.
- `evaluation_result`: evaluator reports verdict, findings, test results, and residual risk.
- `repair_request`: orchestrator or evaluator asks executor to fix specific issues.
- `final_report`: orchestrator summarizes outcome for the user.

## Required Phase Sequence

1. `task_brief`: orchestrator sends task to executor and evaluator.
2. `implementation_plan`: executor proposes implementation plan and optional executor-subagent split.
3. `acceptance_criteria`: evaluator proposes measurable acceptance criteria and evaluation plan.
4. `acceptance_review`: executor and evaluator confirm or challenge each other's plan/criteria.
5. `approved_plan`: orchestrator approves one plan and one acceptance standard.
6. `subtask_assignment` / `subtask_result`: executor and evaluator manage their own child agents as needed.
7. `change_summary`: executor reports implementation.
8. `evaluation_result`: evaluator judges the implementation against the approved criteria.
9. `repair_request` and another `change_summary` / `evaluation_result` loop if needed.
10. `final_report`: orchestrator closes the task.

## Minimal Examples

Executor plan:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"implementation_plan","from":"executor","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"plan_sync","status":"proposed","seq":1,"payload":{"summary":"Add request validation and tests.","steps":["inspect controller boundary","add validator","add unit tests","run verification"],"write_scopes":["src/api","tests/api"],"subagents":[{"id":"executor-docs-001","purpose":"update docs only","write_scope":["docs/harness"]}],"risks":["API compatibility"],"verification_commands":["npm test"]}}
```

Evaluator criteria:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"acceptance_criteria","from":"evaluator","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"plan_sync","status":"proposed","seq":1,"payload":{"criteria":["invalid payload returns 400","valid payload behavior unchanged","unit tests cover both paths"],"evaluation_plan":["review diff","run npm test"],"blockers":[]}}
```

Evaluation result:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"evaluation_result","from":"evaluator","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"evaluation","status":"failed","seq":3,"payload":{"verdict":"fail","findings":[{"severity":"P1","file":"src/api/request.ts","line":42,"title":"Missing null guard","evidence":"validator throws before returning 400"}],"tests":[{"command":"npm test","status":"passed"}],"residual_risks":[]}}
```
