# Harness Architect

Harness Architect is a reusable AI coding harness kit for software repositories. It helps teams create the repo-local scaffolding that coding agents need to work reliably: short entry-point docs, architecture boundaries, JSONL agent protocols, executor/evaluator orchestration, quality gates, execution plans, and cleanup loops.

The project is intentionally small and portable. It can be used as:

- A standalone "skill" folder in agent runtimes that support skills.
- A set of templates and scripts you can copy into any repository.

## What It Creates

The scaffold command generates a repository harness like this:

```text
AGENTS.md
ARCHITECTURE.md
docs/
  harness/
    README.md
    agent-protocol.md
    quality-gates.md
    subagent-workflows.md
  exec-plans/
    active/
    completed/
    tech-debt-tracker.md
scripts/
  harness-check.ps1
```

The generated harness gives agents a map, not a giant manual. It separates durable knowledge from task context and makes multi-agent work explicit.

## Key Ideas

- **Orchestrator / executor / evaluator**: one main agent coordinates implementation and evaluation instead of mixing those jobs together.
- **JSONL agent protocol**: every inter-agent response is one JSON object per line, so the orchestrator can parse, validate, route, and repair handoffs.
- **Plan before code**: executor proposes an implementation plan; evaluator proposes acceptance criteria; the orchestrator approves one shared plan before edits begin.
- **Verify mechanically**: quality gates and harness checks are scripts, not vibes.
- **Harvest failures**: repeated mistakes become docs, tests, scripts, architecture invariants, or debt tracker entries.

## Quick Start

From a cloned copy of this repository (Windows/macOS/Linux):

```powershell
pwsh -File ./skills/harness-architect/scripts/harness-architect.ps1 -Command commands
pwsh -File ./skills/harness-architect/scripts/harness-architect.ps1 -Command scaffold -RepoPath <path-to-your-repo>
pwsh -File ./skills/harness-architect/scripts/harness-architect.ps1 -Command docs-check -RepoPath <path-to-your-repo>
pwsh -File ./skills/harness-architect/scripts/harness-architect.ps1 -Command audit -RepoPath <path-to-your-repo>
```

If you do not have PowerShell 7 (`pwsh`) installed on macOS/Linux, you can use the POSIX wrapper:

```bash
./skills/harness-architect/scripts/harness-architect.sh commands
./skills/harness-architect/scripts/harness-architect.sh scaffold --repo <path-to-your-repo>
./skills/harness-architect/scripts/harness-architect.sh docs-check --repo <path-to-your-repo>
./skills/harness-architect/scripts/harness-architect.sh audit --repo <path-to-your-repo>
```

## Repository Layout

```text
skills/harness-architect/        # Portable skill bundle
docs/                            # Project documentation
scripts/                         # Repository validation helpers
.github/workflows/validate.yml   # CI validation
```

## Agent Protocol

Harness Architect requires JSONL for agent-to-agent communication:

```json
{"schema_version":"harness-agent-jsonl/v1","message_type":"implementation_plan","from":"executor","to":"orchestrator","task_id":"task-001","parent_task_id":null,"phase":"plan_sync","status":"proposed","seq":1,"payload":{"summary":"Add request validation and tests.","steps":["inspect boundary","add validator","add tests","run verification"],"write_scopes":["src/api","tests/api"],"risks":["API compatibility"],"verification_commands":["npm test"]}}
```

See [docs/agent-jsonl-protocol.md](docs/agent-jsonl-protocol.md) for the full contract.

## Inspirations And Related Work

Harness Architect is inspired by the broader harness engineering movement:

- OpenAI's [Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/) argues for repo-local knowledge, short `AGENTS.md` entry points, mechanical architecture constraints, execution plans, and recurring cleanup.
- Anthropic's [Building a C compiler with a team of parallel Claudes](https://www.anthropic.com/engineering/building-c-compiler) demonstrates why long-running multi-agent systems need strong tests, parallel work isolation, clear task ownership, and feedback loops.
- The [Awesome Harness Engineering](https://www.zdoc.app/zh/ai-boost/awesome-harness-engineering) collection is a useful map of the field. Particularly relevant entries include TaskWeaver for planner/executor separation, LangGraph for typed agent graphs and checkpointing, LangChain's multi-agent architecture guidance, and GitHub's discussion of multi-agent handoffs as distributed-system interfaces.

This project is a practical synthesis of those ideas into a small, reusable skill and plugin.

## License

MIT. See [LICENSE](LICENSE).

## Acknowledgements

The design also intentionally honors the work of the harness engineering community collected by `ai-boost/awesome-harness-engineering`.
