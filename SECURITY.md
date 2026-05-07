# Security Policy

## Reporting

Please report security issues privately through GitHub's security advisory flow if enabled, or by opening an issue that avoids sensitive exploit details.

## Harness Safety Principles

- Do not put secrets, tokens, app keys, or production credentials in examples.
- Avoid automated tests that mutate live production systems.
- Treat tool permissions, filesystem writes, and external API calls as explicit harness boundaries.
- Prefer sandboxed or fake services for validation.
