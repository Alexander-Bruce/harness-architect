# Inspirations And Related Work

Harness Architect is a practical packaging of ideas from the harness engineering community.

## Primary Inspirations

- [OpenAI: Harness engineering](https://openai.com/index/harness-engineering/) describes the shift from writing code directly to designing agent-legible repositories, feedback loops, short `AGENTS.md` maps, mechanical constraints, and recurring cleanup.
- [Anthropic: Building a C compiler with a team of parallel Claudes](https://www.anthropic.com/engineering/building-c-compiler) shows the value of high-quality tests, parallel work isolation, role specialization, and harness feedback for long-running autonomous agent teams.
- [Awesome Harness Engineering](https://www.zdoc.app/zh/ai-boost/awesome-harness-engineering) curates the field and frames harness engineering around context, tools, planning artifacts, verification loops, memory, and sandboxing.

## Related Projects And Patterns

These are especially relevant to Harness Architect's design:

- **TaskWeaver**: planner/executor separation and plugin-mediated domain knowledge.
- **LangGraph**: typed graph control flow, state, and checkpoints for agent loops.
- **LangChain multi-agent guidance**: topology decisions for subagents, routing, handoffs, and context isolation.
- **GitHub multi-agent workflow discussions**: multi-agent systems behave like distributed systems, so handoffs need typed schemas and boundary validation.
- **Ralph-loop style autonomous iteration**: useful as inspiration, but Harness Architect adds an orchestrator/evaluator protocol to make the loop safer and more inspectable.

## Design Takeaway

The model is not the whole system. A reliable agentic coding workflow needs an environment that is legible, constrained, observable, testable, and self-correcting.
