# Agent Guide

This repository packages a reusable AI coding harness skill and templates/scripts for any repo.

## Read First

- [README.md](README.md): project overview and usage.
- [docs/agent-jsonl-protocol.md](docs/agent-jsonl-protocol.md): orchestrator/executor/evaluator JSONL contract.
- [docs/inspirations.md](docs/inspirations.md): design inspirations and related work.
- [skills/harness-architect/SKILL.md](skills/harness-architect/SKILL.md): portable skill instructions.

## Rules

- Keep the skill project-agnostic. Do not bake in one repository, company, or business domain.
- All multi-agent examples must use JSONL: one valid JSON object per line.
- Preserve portability across Windows/macOS/Linux; prefer `pwsh` in examples, with POSIX fallback scripts where needed.
- Run `pwsh -File scripts/validate-repo.ps1` before committing.
- Do not add secrets, credentials, or machine-specific paths except in examples clearly marked as placeholders.
