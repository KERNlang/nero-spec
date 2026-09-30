# Security

## Reporting a vulnerability

Report privately through [GitHub security advisories](https://github.com/KERNlang/nero-spec/security/advisories/new). Please don't open a public issue.

Include the affected script or file, a reproduction, and the impact you see. You can expect a first reply within 7 days.

## Scope

Nero Spec is markdown instructions plus bash scripts that run locally. Relevant reports include:

- `install.sh` writing, moving or deleting outside its target and backup directories
- the `spec-check*.sh` scripts executing or leaking content from spec files or repos they read
- skill instructions that lead an agent to send code to an AI vendor a preset forbids

## Supported versions

Only the latest release gets fixes.
