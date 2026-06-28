# Contributing to pgit

pgit is a small set of POSIX shell scripts. The design and mechanism are
described in the [README](README.md); this file covers how to work on the code.

## Layout

```
bin/pgit          # main executable (dispatch + passthrough)
bin/pnp           # thin wrapper for `pgit pp`
lib/pgit-*.sh     # sourced modules (core, patterns, registry, init, add, commit, pp, config)
tests/*.bats      # bats test suite
completions/      # bash, zsh, fish completions
.pgit/config.json # per-project layer definitions and pattern routing
```

The user's pattern registry lives at `~/.config/pgit/patterns/*.json`.

## Running the tests

The suite uses [bats](https://github.com/bats-core/bats-core):

```bash
bats tests/                 # if bats is on your PATH
make test                   # runs bats via nix (no local bats needed)
```

CI runs the same suite on every push and pull request (see
`.github/workflows/tests.yml`).

## Code style

- **POSIX sh, no bashisms** in the core scripts. They run under `dash` as well
  as bash; `dash -n` should pass on every file.
- **Namespace functions** with a `pgit_` prefix.
- **Errors go to stderr.**
- **Exit codes**: `0` success, `1` user error, `2` internal error.

## A note on process files

pgit is dogfooded on its own repo: this product repo holds the code and docs,
while agent-coupled files (`CLAUDE.md`, `.claude/`) live in the separate process
layer. If you use a coding agent here, its config routes to process
automatically and stays out of this repo.
