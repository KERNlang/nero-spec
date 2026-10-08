# Addon: jira-ticket

Every spec belongs to a tracker ticket. Hook: core step 1, before anything else.

## When to use

- Tracker-driven work (Jira or any `KEY-123` style tracker) where every change has a ticket.

## Config (`.spec` or preset)

| Key | Meaning |
|---|---|
| `ticket.regex` | Extracts the key from the branch. Jira default `[A-Z][A-Z0-9]+-\d+` |
| `ticket.prefixes` | Known project keys to offer, comma-separated; empty = ask for the full key |
| `ticket.fallback` | Placeholder key when no ticket exists yet (e.g. `ABC-XXXX`); empty = never invent one |
| `branch.pattern` | e.g. `feat/{TICKET}-{slug}`, `{type}/{TICKET}_{slug}` |
| `specs.path` | Must contain `{TICKET}`, e.g. `.agents/specs/{TICKET}-{slug}/spec.md` |

## Steps

1. `git branch --show-current`, match `ticket.regex` (anchor on `branch.pattern` when set). Hit → use the key as-is.
2. Miss (main, no key) → ask. Offer `ticket.prefixes` plus "Other"; empty list → ask for the full key.
3. Still none → `ticket.fallback` if set: mark it **provisional** in the header and remind the user to rename the spec folder once the real ticket exists.
4. No fallback → **never invent a key**. Draft in scratchpad and say so.
5. New branch → fill `branch.pattern` (`{type}` = feat|fix|chore|refactor|docs, `{slug}` = short kebab-case). Never rename an existing branch unasked.
6. PR title → fill the policy `pr.title` with this key; check it with `spec-check.sh --spec <spec> --pr-title "<title>"` (core step 9).

## What it adds to the spec

- Header line: `**Ticket:** KEY-123` (append `(provisional)` for a fallback key).
- Spec folder named after the key via `specs.path`, e.g. `.agents/specs/KEY-123-short-name/spec.md`.
- Ticket context (description, linked tickets, comments) feeds core step 1; list its gaps.

## Anti-patterns

- Guessing a prefix from the repo name.
- Inventing a key when `ticket.fallback` is empty.
- Renaming or recreating the user's branch to fit the pattern.
- A provisional key left in place after the real ticket exists.
