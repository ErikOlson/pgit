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

## Other planned work

- Remote cross-reference: suggest a process remote name derived from the product
  remote, and a `pnp remotes` cross-check.
- `pnp sync` for coordinated push/pull of both layers.
- Go rewrite, only if shell becomes a constraint on performance or portability.
