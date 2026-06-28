# pgit Roadmap

What works today is documented in the [README](README.md). This file tracks
designed-but-unbuilt features so the intent is recorded without the README
claiming things the code does not yet do.

Status: early development. The core (init, routing, passthrough, adopt,
registry, auto-commit) is implemented and tested. The items below are planned.

## Promotion prompt

When `pgit -p add <file>` stages a file that matches no registry pattern, offer
to add a pattern to the central registry, so the routing rule is reused by
future `pgit init` runs. This closes the "progressive codification" loop:
use, recognize, promote, reuse.

Status: not implemented. Low priority until more dogfooding clarifies the
ergonomics of when to prompt versus when to stay quiet.

## `pnp discover`

Scan the working directory for files that look like process artifacts but are
tracked by neither layer, cross-reference them against the registry, and suggest
classifications. Useful after experimenting with new agent workflows, and more
useful once several projects share a registry.

Status: not implemented (`pnp` currently supports overview, `commit`,
`registry`, and `remotes`).

## Multiple custom layers

The config schema (`default_layer`, named `layers` with `git_dir` and
`patterns`) already anticipates more than two layers. The plan is an init form
that registers additional named layers, each with its own repo, remote, and
history:

```
pgit init --layer docs --patterns "docs/" "API.md"
```

Possible uses: documentation on a separate publication lifecycle, infrastructure
config owned by a different team, sensitive files with different access
controls.

Status: not implemented. `pgit init` currently creates the process layer only;
`--layer` / `--patterns` flags are not yet parsed.

## `pgit adopt --rewrite`

`pgit adopt` separates process from product going forward, but earlier commits
in the product repo still contain the process files. `--rewrite` would use
`git-filter-repo` to scrub those files from product history for projects that
need a fully clean past.

Status: not implemented, and intentionally cautious. Rewriting shared history is
a one-way door, so this needs careful design and clear warnings before it ships.

## Local files that belong to no layer

pgit's routing is binary: every file goes to product or to process. Dogfooding
surfaced a third case, a file that should be ignored by *both* layers. The
example is `.claude/settings.local.json`, Claude Code's per-machine settings,
which belongs in neither the public product repo nor the shared process repo.
Left alone it matches `.claude/` and shows up untracked in process, where a
broad add could stage it.

The good news: this already works through a plain `.gitignore`. Both layers
share one working tree, and a working-tree `.gitignore` takes precedence over
the generated `info/exclude`, so a single product-tracked `.gitignore` entry
hides the file from both repos. Note that manual edits to the process
`info/exclude` do not survive (`pgit_sync_excludes` regenerates it), so
`.gitignore` is the durable place for these rules.

What's left is ergonomics, not capability: a possible `pnp ignore <path>` helper
that adds the entry, and seeding Claude's known local files on `init`. Until
then, add the path to `.gitignore` by hand.

## Boundary-guard hook

pgit keeps process files out of the product repo with git's exclude mechanism,
which covers the normal path but can be bypassed (for example `git add -f`). A
`pre-commit` hook on the product repo could enforce the boundary mechanically:
read the process patterns from `.pgit/config.json` and reject any commit that
stages a path matching them, with a message pointing the user at `pgit -p`.

This turns "the product repo is sacred" into an enforced invariant rather than a
convention. Candidate delivery: an opt-in installer (`pgit hooks install`, or a
prompt during `pgit init`). The hook lives in `.git/hooks` (local, never
committed), so it stays compatible with the rule that the product repo carries
zero pgit traces.

## Other planned work

- Remote cross-reference: suggest a process remote name derived from the product
  remote, and a `pnp remotes` cross-check.
- `pnp sync` for coordinated push/pull of both layers.
- Go rewrite, only if shell becomes a constraint on performance or portability.
