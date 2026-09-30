# Addon: issue-link

Optional link to the issue or PR a spec belongs to. Hook: core step 1.

## When to use

- Team work where issues or PRs exist sometimes, but are not required.

## Steps

- Look for a reference, in order: the user's request, the branch name (`#123`, `issue-123`, `gh-123`), an open PR for the branch if the remote is known.
- Found → add it. Not found → proceed without asking. Never block a spec on it.
- Multiple → list all; the first is the primary.

## What it adds to the spec

- Header line: `**Issue:** <url or #123>`; `**PR:** <url>` when a PR exists. Omit both when none.
- Relevant discussion from the issue feeds core step 1; list its gaps.

## Anti-patterns

- Asking for an issue number the user does not have.
- Inventing a number or URL.
- Treating the issue as a ticket key for `specs.path` — the slug stays the identity.
