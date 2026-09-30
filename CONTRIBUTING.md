# Contributing

Issues and pull requests are welcome.

## Before you open a PR

- Run the script tests you touched, e.g. `bash skill/scripts/test-spec-check.sh`. Every `skill/scripts/test-*.sh` runs standalone except `test-spec-check-stacks.sh`, which `test-spec-check.sh` sources.
- Run `shellcheck` on any shell script you changed.
- Keep specs and addons short. The skill aims for about 180 lines per spec, and every line an agent loads costs context.

## Adding an addon

One markdown file in `skill/addons/` plus one row in the addon table. See "Add an addon" in [docs/REFERENCE.md](docs/REFERENCE.md#add-an-addon).

## Bugs

Include the agent you used (Claude, Codex, agy, …), the `.spec` preset, and the smallest spec or command that shows the problem.

## License

Contributions are licensed under [MIT](LICENSE).
