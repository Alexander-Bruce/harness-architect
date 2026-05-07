# Contributing

Thanks for helping improve Harness Architect.

## Development Flow

1. Keep changes project-agnostic.
2. Update the skill and Claude plugin copy together when behavior changes.
3. Update docs when changing the agent protocol, scaffolded files, or quality gates.
4. Run validation:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-repo.ps1
```

## Commit Style

Use concise imperative commit messages, for example:

```text
Add JSONL evaluator protocol examples
```

## Review Focus

- Does this improve agent reliability?
- Is the protocol parseable and mechanically checkable?
- Does the scaffold remain useful across different stacks?
- Did we avoid adding project-specific assumptions?
