# Inspirations And Related Work

Harness Architect is a practical packaging of ideas from the harness engineering community.

## Primary Inspirations

### OpenAI: Harness Engineering

[OpenAI: Harness engineering](https://openai.com/index/harness-engineering/) describes the shift from writing code directly to designing agent-legible repositories. Key ideas adopted in Harness Architect:

- `AGENTS.md` as a short, always-loaded map — not a giant manual.
- Mechanical constraints over prompt instructions (scripts beat prose).
- Recurring cleanup loops: turn repeated failures into docs, tests, or gates.
- Short feedback cycles: the harness should tell the agent exactly what to fix.

### Anthropic: Building a C Compiler with Parallel Claudes

[Anthropic: Building a C compiler with a team of parallel Claudes](https://www.anthropic.com/engineering/building-c-compiler) demonstrates a large-scale autonomous harness (100,000-line compiler, 2,000+ sessions). Key lessons incorporated:

- **Test quality is the multiplier.** The harness's reliability is bounded by how well its verifier distinguishes correct from incorrect behavior. Near-perfect task verifiers are what make parallel agents trustworthy.
- **LLM-aware feedback.** Agents consume structured output (exit codes, file:line findings) far more reliably than raw build logs or narrative summaries. Minimize prose in harness output.
- **Parallel isolation.** Multiple agents running concurrently must own disjoint write scopes. Use separate branches or worktrees per agent; the orchestrator merges after evaluator review.
- **Role specialization.** Distinct orchestrator / executor / evaluator roles reduce ambiguity and make the task graph inspectable.
- **Git-based synchronization.** Use git as the coordination primitive between parallel agents (branches, atomic commits, merge gates) rather than ad-hoc file locking.

### Awesome Harness Engineering

[Awesome Harness Engineering](https://www.zdoc.app/zh/ai-boost/awesome-harness-engineering) curates the field and frames harness engineering around six pillars: context, tools, planning artifacts, verification loops, memory, and sandboxing. Harness Architect covers all six:

- Context → `AGENTS.md`, `ARCHITECTURE.md`
- Tools → `scripts/harness-check.*`, stack-specific verification commands
- Planning artifacts → `docs/exec-plans/` (active and completed plans)
- Verification loops → quality gates, evaluator role, repair/retry cycle
- Memory → `tech-debt-tracker.md`, harvested failure artifacts
- Sandboxing → architecture boundaries, do-not-edit paths, secret gates

## Related Projects And Patterns

These are especially relevant to Harness Architect's design:

- **TaskWeaver**: planner/executor separation and plugin-mediated domain knowledge.
- **LangGraph**: typed graph control flow, state, and checkpoints for agent loops.
- **LangChain multi-agent guidance**: topology decisions for subagents, routing, handoffs, and context isolation.
- **GitHub multi-agent workflow discussions**: multi-agent systems behave like distributed systems, so handoffs need typed schemas and boundary validation.
- **Ralph-loop style autonomous iteration**: useful as inspiration, but Harness Architect adds an orchestrator/evaluator protocol to make the loop safer and more inspectable.

## Design Takeaway

The model is not the whole system. A reliable agentic coding workflow needs an environment that is legible, constrained, observable, testable, and self-correcting. The quality of your tests and the structure of your feedback are the two highest-leverage investments.
