# Scaffold Guide

Use this when adapting generic harness docs to a specific project.

## Detect The Stack

Look for:

- `pom.xml`: Java/Maven
- `build.gradle`, `settings.gradle`, `gradlew`: Java/Kotlin/Gradle
- `package.json`: Node/React/Vue/Next/etc.
- `pyproject.toml`, `requirements.txt`: Python
- `*.sln`, `*.csproj`: .NET
- `Cargo.toml`: Rust
- `go.mod`: Go

## Fill The Project Map

Add only facts discovered from the repo:

- Entry points
- Core modules/packages
- Runtime services
- External systems
- Generated/build output paths
- Test commands
- Deployment scripts
- Existing design docs or issue trackers

## Boundaries To Define

- Do-not-edit paths: build output, generated code, IDE metadata, vendored dependencies.
- Security: secrets, credentials, auth, production data.
- External systems: live endpoints, paid APIs, migrations, irreversible operations.
- Architecture: allowed dependency directions and ownership.
- Verification: required tests, screenshots, API checks, static analysis.

## Make Debt Visible

Use `tech-debt-tracker.md` for existing issues that should not block every task but must not be silently expanded.
