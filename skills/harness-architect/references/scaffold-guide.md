# Scaffold Guide

Use this when adapting generic harness docs to a specific project.

## Detect The Stack

Look for the following markers (in order of specificity). A repo may have multiple stacks — detect all of them.

| Marker | Stack | Default test command |
|---|---|---|
| `pom.xml` | Java / Maven | `mvn test` |
| `build.gradle`, `build.gradle.kts`, `gradlew` | Java / Kotlin / Gradle | `./gradlew test` or `gradle test` |
| `package.json` | Node / React / Vue / Next / etc. | `npm test` |
| `pyproject.toml`, `requirements.txt` | Python | `pytest` |
| `*.sln`, `*.csproj` | .NET | `dotnet test` |
| `Cargo.toml` | Rust | `cargo test` |
| `go.mod` | Go | `go test ./...` |
| `Gemfile` | Ruby | `bundle exec rspec` |
| `Makefile` | Make-based | `make test` |
| `Dockerfile` / `docker-compose.yml` | Docker / container | `docker compose run --rm test` |

If multiple stacks are detected, list all of them and include all their test commands in `quality-gates.md`.

## Fill The Project Map

Add only facts discovered from the repo (do not invent):

- Entry points (main files, server startup, CLI entrypoints)
- Core modules / packages
- Runtime services (databases, message queues, cache)
- External systems (third-party APIs, webhooks, OAuth providers)
- Generated / build output paths (must not be edited by agents)
- Test commands and coverage thresholds
- Deployment scripts and environment targets
- Existing design docs, issue trackers, or ADRs

## Boundaries To Define

- **Do-not-edit paths**: build output, generated code, IDE metadata, vendored dependencies, lock files (unless the task is a dependency update).
- **Security**: secrets, credentials, auth tokens, production data, encryption keys.
- **External systems**: live endpoints, paid APIs, irreversible operations (sends, charges, migrations).
- **Architecture**: allowed dependency directions and ownership (e.g., "no direct DB calls from the HTTP layer").
- **Verification**: required tests, screenshots, API response checks, static analysis thresholds.

## Monorepo Considerations

For repos with multiple independent sub-projects:

- Generate one shared `AGENTS.md` and `ARCHITECTURE.md` at the root.
- Generate per-package `docs/harness/quality-gates.md` if test commands differ significantly.
- Treat each package as a separate write scope when running parallel agents.
- The orchestrator must enforce that executor subagents own disjoint package directories.

## Make Debt Visible

Use `tech-debt-tracker.md` for existing issues that should not block every task but must not be silently expanded. Distinguish:

- **Baseline debt**: pre-existing warnings, known gaps, deferred work — visible but not blocking.
- **New regressions**: introduced by a current task — must be fixed before that task closes.
