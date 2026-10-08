# Company policy

One file per company instead of a fork: in the repo (`.spec` `policy: .nero-spec/policy.md`) or, until it is shared, on one machine (`policy_paths`). Set up with `/spec init` step 2e. Frontmatter is flat `key: value` with whole-line `#` comments.

| Key | Meaning |
|---|---|
| `format` | Required: `nero-spec-policy/v1` |
| `ticket.regex`, `ticket.prefixes`, `ticket.fallback`, `branch.pattern` | Owned by the policy; replace preset and `.spec` values |
| `pr.title` | Title template: `<n>` digits, `<a\|b>` one of, other `<x>` any text, e.g. `<feat\|fix>(ORG-<n>): <Summary>` |
| `pr.regex` | Optional exact ERE when the lint has rules a template can't say (case, scopes); wins over `pr.title` |
| `headers`, `sections` | Required header fields; sections required from READY TO BUILD on |
| `words.deny` | Words a spec must never contain (internal tool names, codenames) |
| `addons.require`, `addons.deny` | `.spec` cannot drop a required addon or enable a denied one |
| `agon.max`, `agon_engines`, `critic` | Ceilings: `off`\|`ask`\|`restricted`\|`full`; allowed engines; `subagent`\|`agon`\|`any` for the refine critic |
| `rules` | Repo-relative rules-of-record files |
| `skills`, `skills.path` | Repo skills per step (`build=ui-dev\|api-dev`); folders holding `<skill>/SKILL.md`, default `.agents/skills`, `.claude/skills`, `.ai/skills` |

```markdown
---
format: nero-spec-policy/v1
ticket.regex: ORG-\d+
branch.pattern: {TICKET}_{slug}
pr.title: <feat|fix|docs>: <Summary> #ORG-<n>
headers: Ticket, Confidence
sections: Release Notes
agon.max: off
critic: subagent
rules: docs/coding-guidelines.md, AGENTS.md
skills: build=ui-dev|api-dev, tests=ui-test|api-test, review=code-review
---

## Constitution

- Every spec belongs to an ORG ticket. Never invent a key.
```

- **Safety:** repo policy = repo-relative `.md` in the git root, no symlinks, no `..`; machine policy = absolute `.md`. Unknown or duplicate keys, a missing `format` or bad values → `spec-check.sh` exits 2. A symlinked `SKILL.md` or a skill folder outside the repo never counts.
- **Checks:** `POLICY-CONFLICT` (`.spec` loosens the policy; `agon: full` plus a policy engine list counts), `POLICY-HEADER`, `POLICY-SECTION`, `POLICY-TICKET` (whole key), `POLICY-WORD`, `POLICY-RULES`, `POLICY-SKILL`. Pointer specs get only `POLICY-WORD`.
- **PR title:** `spec-check.sh --spec <spec> --pr-title "<title>"` → exit 0 `PR-TITLE ok`, 1 mismatch, 2 no policy or no title format. A title that names a ticket must name the spec's ticket; formats without a ticket only need to match.
