# Agent JSONL Protocol

Every inter-agent message in a Harness Architect workflow is JSONL:

- One valid JSON object per line.
- No Markdown.
- No prose outside JSON.
- Each line must be independently parseable.

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
- `message_type`: protocol message type
- `from`: sender role or id
- `to`: recipient role or id
- `task_id`: stable task id
- `parent_task_id`: parent id or `null`
- `phase`: `intake`, `plan_sync`, `execution`, `evaluation`, `repair`, or `closeout`
- `status`: `open`, `proposed`, `approved`, `blocked`, `running`, `passed`, `failed`, or `complete`
- `seq`: sender-local monotonically increasing integer
- `payload`: message-specific object

## Required Sequence

1. Orchestrator sends `task_brief` to executor and evaluator.
2. Executor returns `implementation_plan`.
3. Evaluator returns `acceptance_criteria`.
4. Executor and evaluator return `acceptance_review`.
5. Orchestrator sends `approved_plan`.
6. Executor implements and returns `change_summary`.
7. Evaluator returns `evaluation_result`.
8. Orchestrator sends `repair_request` when needed, otherwise closes with `final_report`.

## Example Evaluator Result

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"evaluation_result","from":"evaluator","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"evaluation","status":"failed","seq":3,"payload":{"verdict":"fail","findings":[{"severity":"P1","file":"src/api/request.ts","line":42,"title":"Missing null guard","evidence":"validator throws before returning 400"}],"tests":[{"command":"npm test","status":"passed"}],"residual_risks":[]}}
```
