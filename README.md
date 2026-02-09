# pgit  
# An AP&P (Advanced Processes & Products) Git Multiplexer  

**A git multiplexer for separating agentic process from public product.**

Keep your Claude Code files, agent configs, and AI workflow out of your source repo — without losing version control.

*Roll for initiative on your agentic development workflow.*

---

# 📕 P&P Basic Edition

*You encounter a project directory. What do you do?*

## Install

```bash
# TODO: installation instructions
```

## Start

```bash
pgit init
```

Done. You now have separate version control for your process files and your product files.

## Use

Use `pgit` exactly like `git`:

```bash
pgit add .
pgit commit -m "add login page"
pgit push
```

This works on your **product repo** — your source code, the thing you ship.

To work with your **process files** (agent configs, `CLAUDE.md`, skills), add `-p`:

```bash
pgit -p commit -m "update agent instructions"
pgit -p push
```

No `-p` → product. `-p` → process. **That's the whole game.**

## See Both

```bash
pnp
```

Shows status of both layers at a glance.

## What Happens Automatically

pgit knows these files are process, out of the box:

```
CLAUDE.md    .claude/    AGENTS.md    PLAN.md    TASKS.md
```

Everything else is product. Your product repo has zero trace of the process layer — anyone who clones it sees a normal project.

## No pgit? No Problem

In directories without `pgit init`, pgit passes straight through to git. Safe to alias:

```bash
alias git=pgit
```

---

# 📘 Advanced P&P

*You've cleared the first dungeon. Time for better equipment.*

## Smart Routing

When you `pgit add .`, files route to the correct repo automatically. Product files stage in the product repo. Process files stage in the process repo. You don't think about it.

## Committing

`pgit commit` commits the product repo. If process has staged changes, you get a nudge:

```
[main a1b2c3d] add login page
 3 files changed, 47 insertions(+)
⚡ process layer has staged changes — pgit -p commit or pnp commit
```

To commit both at once:

```bash
pnp commit                   # prompts for a process message
pnp commit -m "end of day"   # same message for both
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
├── CLAUDE.md         ← process repo (private, versioned)
├── .claude/          ← process repo
│   ├── agents/
│   └── skills/
├── PLAN.md           ← process repo
└── .pgit/            ← pgit metadata + process repo storage
```

## Pattern Customization

Defaults not quite right? Patterns support inclusion and exclusion:

```
.claude/                   # process (include the directory)
!.claude/settings.json     # product (exclude — this ships with the app)
```

More specific patterns override less specific ones. Exclusions (`!`) override inclusions.

## Finding Stray Process Files

```bash
pnp discover
```

Scans for files that look like process artifacts but aren't tracked by either repo. Useful after experimenting with new agent workflows.

## The Registry

Every time you route a new file to process, pgit offers to remember the pattern:

```
pgit -p add my-agent-notes.md
# pgit: "my-agent-notes.md" isn't in your registry.
# Add pattern to registry for future projects? [y/N]
```

Your registry lives at `~/.config/pgit/patterns/` and grows over time. Future `pgit init` picks up your patterns automatically. No project starts from zero.

```bash
pnp registry list        # see your patterns
pnp registry add         # add one manually
```

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
pnp discover                    # find untracked process artifacts
pnp registry                    # manage patterns
```

---

# 📗 Process Master's Guide

*You don't just play the game. You design the world.*

## The Shift

Software engineering is undergoing a fundamental transition. With coding agents, the *process* of building software — agent instructions, orchestration strategies, skill definitions, prompt engineering — has become **executable configuration**. It's source code for the development process itself.

This creates a new artifact category with fundamentally different properties:

| | Product | Process |
|---|---------|---------|
| **Nature** | The application you ship | The methodology that built it |
| **Audience** | Users, collaborators, public | You, your team |
| **Lifecycle** | Follows releases | Follows your evolving workflow |
| **Sensitivity** | Open by default | Private by default |
| **Analogy** | The player handout | The Process Master's campaign notes |

These concerns have different audiences, different access controls, different lifecycles, and different sensitivity. They need separate version control.

## The Mechanism

pgit uses git's native `GIT_DIR` / `GIT_WORK_TREE` separation. Both repos share the same working directory, but each only sees its own files.

The product repo's `.git/info/exclude` is automatically maintained to hide process files. This mechanism is **local to your clone** — never committed, never pushed. The product repo's history, config, and `.gitignore` contain zero references to pgit.

```
.pgit/
  config.json                     # layer definitions, pattern routing
  layers/
    process/
      .git/                       # the process repo
```

For passthrough commands, pgit is: check routing, set `GIT_DIR`, `exec git`. The overhead is a single `stat` call. That's why `alias git=pgit` works — it's invisible when you don't need it.

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
        ".claude/",
        "PLAN.md",
        "TASKS.md"
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

The registry isn't configured top-down. It's built from practice through a cycle:

1. **Use** — work normally, creating files as needed
2. **Recognize** — `pnp discover` surfaces process artifacts you haven't tracked
3. **Promote** — pgit offers to add new patterns to your central registry
4. **Reuse** — future `pgit init` picks up those patterns automatically

Your registry becomes a spellbook built from spells you've actually cast, not ones copied from a textbook. We call this **progressive codification** — the transformation of tacit practice into reusable configuration.

This is the same philosophy behind [cperm](https://github.com/TODO), a composable permissions manager for Claude Code that uses the same use → recognize → promote → reuse loop for agent permission patterns.

## Multiple Layers

Process/product is the flagship campaign, but pgit's core is a general-purpose multiplexer supporting arbitrary named layers:

```bash
pgit init --layer docs --patterns "docs/" "API.md"
pgit init --layer infra --patterns "terraform/" "Dockerfile"
```

Each layer gets its own git repo, its own remote, its own history. The routing table handles the rest. Possible applications: documentation with a separate publication lifecycle, infrastructure config owned by a different team, sensitive files requiring different access controls.

## History Rewriting

`pgit adopt` creates clean separation going forward, but old commits retain process files. For projects that need a fully clean history:

```bash
pgit adopt --rewrite
```

This uses `git-filter-repo` to scrub process files from the product repo's history. Use with caution — rewriting shared history is a dark art, and this is a one-way door. pgit will warn accordingly.

## Design Principles

**pgit wraps git.** Superset, not alternative. Zero overhead outside P&P directories.

**Product repo is sacred.** Zero pollution. No metadata, no patterns, no traces. A clone is a clean project.

**Process is opt-in, product is default.** Unmatched files always route to product. Source code is never accidentally hidden.

**Progressive codification.** The registry is built from practice, not theory.

**Multiplexer at the core.** N repos, one directory, path-based routing. P&P is the flagship, not the limit.

**Just enough opinion.** Sensible defaults for the agentic era, but nothing that boxes you in. As flexible as possible, as opinionated as necessary.

## Prior Art

Tools like [vcsh](https://github.com/RichiH/vcsh) and [git-multi](https://github.com/grahamc/git-multi) use the same underlying git mechanism for managing dotfiles in `$HOME`. pgit is different:

1. **Full git wrapper** — your daily driver, not a side tool
2. **Built for project directories**, not home directories
3. **Opinionated defaults** for the agentic development era
4. **A learning registry** that gets smarter across projects

## Why Now

Every developer using a coding agent is generating process artifacts. Today these are committed alongside product code — or not version-controlled at all. As agentic development becomes standard, the process layer will represent significant intellectual property: engineering methodology encoded as configuration.

pgit provides clean P&P separation before the entanglement becomes permanent.

*Don't split the party. Split the repos.*

## Status

Early development. The architecture is defined, the mechanism is proven. Contributions welcome.

## License

MIT
