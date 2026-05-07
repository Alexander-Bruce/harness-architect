# Agent JSONL Protocol

Every inter-agent message in a Harness Architect workflow is JSONL:

- One valid JSON object per line.
- No Markdown.
- No prose outside JSON.
- Each line must be independently parseable.
- Use arrays inside a field when a message needs multiple paths, findings, or commands.
- Prefer compact factual payloads over narrative.

## Roles

- `orchestrator`: the main agent. Owns the user goal, task graph, approved plan, acceptance criteria, final integration, and final report.
- `executor`: owns implementation planning and code changes. May coordinate executor-side subagents for disjoint work.
- `evaluator`: owns acceptance criteria, evaluation plan, independent review, and verification. May coordinate evaluator-side subagents for focused checks.
- `subagent`: a leaf agent owned by executor or evaluator.

## Envelope

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"task_brief","from":"orchestrator","to":"executor","task_id":"task-001","parent_task_id":null,"phase":"intake","status":"open","seq":1,"payload":{}}
```

Required fields:

- `schema_version`: always `harness-agent-jsonl/v1`
- `message_type`: protocol message type (see list below)
- `from`: sender role or id
- `to`: recipient role or id
- `task_id`: stable task id
- `parent_task_id`: parent id or `null`
- `phase`: `intake`, `plan_sync`, `execution`, `evaluation`, `repair`, or `closeout`
- `status`: `open`, `proposed`, `approved`, `blocked`, `running`, `passed`, `failed`, or `complete`
- `seq`: sender-local monotonically increasing integer
- `payload`: message-specific object

## Message Types

- `task_brief`: orchestrator sends goal, constraints, repo path, context links, and requested output.
- `implementation_plan`: executor proposes plan, write scopes, subagent split, risks, and verification commands.
- `acceptance_criteria`: evaluator states objective pass/fail criteria and evaluation plan.
- `acceptance_review`: executor or evaluator accepts, amends, or rejects the other side's plan/criteria before coding.
- `approved_plan`: orchestrator resolves plan and criteria into the version executor must implement and evaluator must judge.
- `subtask_assignment`: executor or evaluator assigns bounded work to a child subagent.
- `subtask_result`: child subagent returns findings, changed files, tests, or blockers.
- `progress`: agent reports current state without changing plan (optional heartbeat).
- `change_summary`: executor reports changed files, behavior, assumptions, and verification run.
- `evaluation_result`: evaluator reports verdict, findings, test results, and residual risk.
- `repair_request`: orchestrator asks executor to fix specific issues found by evaluator.
- `final_report`: orchestrator summarizes outcome for the user.

## Required Sequence

1. Orchestrator sends `task_brief` to executor and evaluator.
2. Executor returns `implementation_plan`.
3. Evaluator returns `acceptance_criteria` and evaluation plan.
4. Executor and evaluator return `acceptance_review` (cross-review of each other's proposal).
5. Orchestrator resolves conflicts and sends `approved_plan`.
6. Executor and evaluator dispatch `subtask_assignment` / collect `subtask_result` as needed.
7. Executor returns `change_summary`.
8. Evaluator returns `evaluation_result`.
9. Orchestrator sends `repair_request` if needed (loop back to step 7), otherwise closes with `final_report`.

## Examples

Executor implementation plan:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"implementation_plan","from":"executor","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"plan_sync","status":"proposed","seq":1,"payload":{"summary":"Add request validation and tests.","steps":["inspect controller boundary","add validator","add unit tests","run verification"],"write_scopes":["src/api","tests/api"],"subagents":[{"id":"executor-docs-001","purpose":"update docs only","write_scope":["docs/harness"]}],"risks":["API compatibility"],"verification_commands":["npm test"]}}
```

Evaluator acceptance criteria:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"acceptance_criteria","from":"evaluator","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"plan_sync","status":"proposed","seq":1,"payload":{"criteria":["invalid payload returns 400","valid payload behavior unchanged","unit tests cover both paths"],"evaluation_plan":["review diff","run npm test"],"blockers":[]}}
```

Subtask assignment (executor to subagent):

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"subtask_assignment","from":"executor","to":"executor-docs-001","task_id":"task-001","parent_task_id":null,"phase":"execution","status":"open","seq":2,"payload":{"scope":["docs/harness"],"goal":"Update agent-protocol.md to reflect new message types added in this task.","constraints":["do not touch source files","do not add secrets"]}}
```

Subagent result:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"subtask_result","from":"executor-docs-001","to":"executor","task_id":"task-001","parent_task_id":null,"phase":"execution","status":"complete","seq":1,"payload":{"changed_files":["docs/harness/agent-protocol.md"],"behavior_summary":"Added subtask_assignment and subtask_result examples.","tests_run":[],"blockers":[],"assumptions":[]}}
```

Evaluator result (fail):

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"evaluation_result","from":"evaluator","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"evaluation","status":"failed","seq":3,"payload":{"verdict":"fail","findings":[{"severity":"P1","file":"src/api/request.ts","line":42,"title":"Missing null guard","evidence":"validator throws before returning 400"}],"tests":[{"command":"npm test","status":"passed"}],"residual_risks":[]}}
```

Repair request:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"repair_request","from":"orchestrator","to":"executor","task_id":"task-001","parent_task_id":null,"phase":"repair","status":"open","seq":4,"payload":{"required_fixes":[{"finding_ref":"P1/src/api/request.ts:42","instruction":"Add null guard before validator call; ensure 400 is returned for null payload."}],"rerun_verification":true}}
```
