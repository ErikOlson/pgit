# pgit

[![tests](https://github.com/erikolson/pgit/actions/workflows/tests.yml/badge.svg)](https://github.com/erikolson/pgit/actions/workflows/tests.yml)

**A git multiplexer that keeps agentic process files out of your product repo.**

Keep your Claude Code files, agent configs, and AI workflow under version control without committing them to the source you ship. Use `pgit` as a drop-in for `git`.

## What it does

pgit runs two git repos over one working directory. Your **product** files (the source you ship) live in a normal `.git` repo. Your **process** files (`CLAUDE.md`, `.claude/`, agent configs) live in a separate private repo under `.pgit/`. It uses git's native `GIT_DIR` / `GIT_WORK_TREE` separation, so each repo sees only its own files and a clone of your product repo has zero trace of the process layer.

Use `pgit` exactly like `git`. No flag targets product, `-p` targets process.

## Status

Early development. The core is implemented and tested (74 passing tests): `init`, automatic routing, product and process passthrough, `adopt`, the pattern registry, and `pp.auto-commit`. Planned work is tracked in [ROADMAP.md](ROADMAP.md).

## Install

pgit is a set of POSIX shell scripts. Pick whichever install fits your setup.

**Add the repo to your PATH** (simplest):

```bash
git clone https://github.com/erikolson/pgit
export PATH="$PWD/pgit/bin:$PATH"   # add this to your shell rc to persist
```

Keep the clone in place: `pgit` finds its libraries relative to the script.

**Nix** (flake):

```bash
nix profile install github:erikolson/pgit
```

**make install** (under `/usr/local` by default):

```bash
cd pgit
sudo make install                          # or: make install PREFIX="$HOME/.local"
make install-completions                   # optional: shell completions
```

## Quickstart

```bash
pgit init                               # set up the process layer
pgit add .                              # stages each file to the right repo
pgit commit -m "add login page"         # commits the product repo
pgit -p commit -m "update agent docs"   # commits the process repo
pnp                                     # status of both layers at a glance
```

No `-p` means product. `-p` means process. **That's the whole game.**

The defaults route these to process out of the box, everything else is product:

```
CLAUDE.md    .claude/    AGENTS.md    *.agent-log
```

The defaults are deliberately narrow: only files that are genuinely coupled to a specific agent. Design docs, plans, and notes default to product (visible), and you move them into process by choice when you want them private.

---

*The rest of this README is the long version. Roll for initiative.*

# 📕 P&P Basic Edition

*You encounter a project directory. What do you do?*

## See Both

```bash
pnp
```

Shows status of both layers at a glance: branch, clean or dirty, last commit, and how far each is ahead of or behind its remote.

## What Happens Automatically

When you `pgit add .`, files route to the correct repo automatically. Product files stage in the product repo, process files stage in the process repo. Your product repo has zero trace of the process layer. Anyone who clones it sees a normal project.

## No pgit? No Problem

In directories without `pgit init`, pgit passes straight through to git. Safe to alias:

```bash
alias git=pgit
```

It's invisible when you don't need it.

---

# 📘 Advanced P&P

*You've cleared the first dungeon. Time for better equipment.*

## Smart Routing

When you `pgit add .`, the process patterns decide where each file lands. Product files stage in the product repo, process files stage in the process repo. You don't think about it.

## Committing

`pgit commit` commits the product repo. If process has staged changes, you get a nudge:

```
[main a1b2c3d] add login page
 3 files changed, 47 insertions(+)
pgit: process layer has staged changes. Run 'pgit -p commit' or 'pnp commit'.
```

To commit both at once:

```bash
pnp commit                   # commits product, then process with a sync message
pnp commit -m "end of day"   # uses your message for both
```

Want every commit to auto-include process? Set it and forget it:

```bash
pgit config pp.auto-commit true
```

## Your Project With P&P

```
your-project/
├── src/              ← product repo (public, shared)
├── tests/            ← product repo
├── README.md         ← product repo
├── ARCHITECTURE.md   ← product repo (design is public)
├── CLAUDE.md         ← process repo (private, versioned)
├── .claude/          ← process repo
│   ├── commands/
│   └── skills/
└── .pgit/            ← pgit metadata + process repo storage
```

## Pattern Customization

Defaults not quite right? Patterns support inclusion and exclusion:

```
.claude/                   # process (include the directory)
!.claude/settings.json     # product (exclude, this ships with the app)
```

More specific patterns override less specific ones. Exclusions (`!`) override inclusions. Patterns live in `.pgit/config.json`.

## The Registry

Your registry lives at `~/.config/pgit/patterns/` as a set of JSON pattern files. It ships with built-in sets for Claude Code and agent logs, and `pgit init` consults it to pre-populate a new project's patterns. No project starts from zero.

```bash
pnp registry list                  # see your patterns
pnp registry add <pattern> [set]   # add a pattern (default set: custom)
pnp registry remove <pattern>      # remove a pattern
```

The registry grows as you add patterns you find yourself reusing. Automating that discovery loop is on the [roadmap](ROADMAP.md).

## Adopting P&P on an Existing Project

Already committing process files to your product repo?

```bash
pgit adopt
```

Scans your directory, sets up the process repo, and removes process files from product tracking (without deleting them from disk). Clean separation going forward.

## Quick Reference

```bash
# Product (daily git workflow)
pgit add .                      # auto-routes files to correct repo
pgit commit -m "message"        # product repo
pgit push                       # product repo
pgit log                        # product repo

# Process (add -p)
pgit -p status                  # process repo
pgit -p commit -m "message"     # process repo
pgit -p push                    # process repo → private remote

# P&P (the multiplexer)
pnp                             # overview of both layers
pnp commit                      # commit both
pnp registry                    # manage patterns
pnp remotes                     # show both remotes side by side
```

---

# 📗 Process Master's Guide

*You don't just play the game. You design the world.*

## The Shift

Software engineering is undergoing a fundamental transition. With coding agents, the *process* of building software (agent instructions, orchestration strategies, skill definitions, prompt engineering) has become **executable configuration**. It's source code for the development process itself.

This creates a new artifact category with fundamentally different properties:

| | Product | Process |
|---|---------|---------|
| **Nature** | The application you ship | The methodology that built it |
| **Audience** | Users, collaborators, public | You, your team |
| **Lifecycle** | Follows releases | Follows your evolving workflow |
| **Sensitivity** | Open by default | Private by default |
| **Analogy** | The player handout | The Process Master's campaign notes |

These concerns have different audiences, different access controls, different lifecycles, and different sensitivity. They need separate version control.

## Platform Harness and Agent Harness

The cleanest way to see the split: your product is the **platform harness** and your process is the **agent harness**.

The platform harness is every capability that any tool or contributor can use: the build, the test runner, the linter, the scripts, the documented contracts. It is agent-agnostic and it belongs in the product repo, in the open.

The agent harness is the brand-specific binding that drives those capabilities: the `CLAUDE.md`, the `.claude/` commands and skills, the hooks that know how and when to invoke them. It is coupled to a particular agent and it belongs in the process repo, private.

The decoupling is the point. A `make test` target lives in product; a `.claude/commands/test.md` that runs it and acts on the output lives in process. Swap one agent for another and the platform harness never moves. Only the agent harness changes. pgit keeps that seam clean and gives each side its own history.

You can see this split live: this project's own process layer is published, for demonstration, at [pgit-process](https://github.com/erikolson/pgit-process). It holds the `CLAUDE.md` and `.claude/` files that never appear in this repo.

## The Mechanism

pgit uses git's native `GIT_DIR` / `GIT_WORK_TREE` separation. Both repos share the same working directory, but each only sees its own files.

The product repo's `.git/info/exclude` is automatically maintained to hide process files. This mechanism is **local to your clone**, never committed, never pushed. The product repo's history, config, and `.gitignore` contain zero references to pgit.

```
.pgit/
  config.json                     # layer definitions, pattern routing
  layers/
    process/
      .git/                       # the process repo
```

For passthrough commands, pgit is: check routing, set `GIT_DIR`, `exec git`. The overhead is a single `stat` call. That's why `alias git=pgit` works. It's invisible when you don't need it.

## The Three-Tier Command Model

pgit's interface has three distinct modes:

| Tier | Syntax | Targets | Use |
|------|--------|---------|-----|
| Product passthrough | `pgit <cmd>` | `.git/` | Daily development (99% of commands) |
| Process passthrough | `pgit -p <cmd>` | `.pgit/.../process/.git/` | Managing agent configs |
| P&P multiplexer | `pnp <cmd>` | Both / meta | Orchestrating the layers themselves |

Every git command works in tiers 1 and 2. Tier 3 has pgit-specific commands only.

## Routing Architecture

pgit maintains a routing table mapping file patterns to layers:

```json
{
  "default_layer": "product",
  "layers": {
    "product": {
      "git_dir": ".git"
    },
    "process": {
      "git_dir": ".pgit/layers/process/.git",
      "patterns": [
        "CLAUDE.md",
        "AGENTS.md",
        ".claude/"
      ]
    }
  }
}
```

Routing rules:
1. Check file against all layer patterns, most specific match wins
2. Exclusion patterns (`!`) override inclusions
3. Unmatched files → default layer (product)
4. `.pgit/` itself → process layer (it's metadata about how you work)

## Progressive Codification

The registry isn't meant to be configured top-down. It's built from practice:

1. **Use**: work normally, creating files as needed
2. **Promote**: add patterns you find yourself reusing (`pnp registry add`)
3. **Reuse**: future `pgit init` picks up those patterns automatically

Your registry becomes a spellbook built from spells you've actually cast, not ones copied from a textbook. Today the promote step is manual; surfacing untracked process artifacts and prompting to promote them automatically is on the [roadmap](ROADMAP.md). We call the end state **progressive codification**, the transformation of tacit practice into reusable configuration.

This is the same philosophy behind [cperm](https://github.com/erikolson/cperm), a composable permissions manager for Claude Code that uses the same use → promote → reuse loop for agent permission patterns.

## Design Principles

**pgit wraps git.** Superset, not alternative. Zero overhead outside P&P directories.

**Product repo is sacred.** Zero pollution. No metadata, no patterns, no traces. A clone is a clean project.

**Process is opt-in, product is default.** Unmatched files always route to product. Source code is never accidentally hidden.

**Progressive codification.** The registry is built from practice, not theory.

**Multiplexer at the core.** The config schema describes named layers and path-based routing. P&P is the flagship configuration, and support for additional custom layers is on the [roadmap](ROADMAP.md).

**Just enough opinion.** Sensible defaults for the agentic era, but nothing that boxes you in. As flexible as possible, as opinionated as necessary.

## Prior Art

Tools like [vcsh](https://github.com/RichiH/vcsh) and [git-multi](https://github.com/grahamc/git-multi) use the same underlying git mechanism for managing dotfiles in `$HOME`. pgit is different:

1. **Full git wrapper**, your daily driver, not a side tool
2. **Built for project directories**, not home directories
3. **Opinionated defaults** for the agentic development era
4. **A learning registry** that carries patterns across projects

## Why Now

Every developer using a coding agent is generating process artifacts. Today these are committed alongside product code, or not version-controlled at all. As agentic development becomes standard, the process layer will represent significant intellectual property: engineering methodology encoded as configuration.

pgit provides clean P&P separation before the entanglement becomes permanent.

*Don't split the party. Split the repos.*

## License

MIT
