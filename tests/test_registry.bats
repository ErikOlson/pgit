#!/usr/bin/env bats

# Test registry structure, pgit init with registry, and pnp registry commands.

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_DIR="$(mktemp -d)"
    # Isolate registry to temp dir
    export XDG_CONFIG_HOME="$TEST_DIR/config"
    cd "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# --- Built-in patterns ---

@test "built-in patterns are installed on first use" {
    pgit pp registry list >/dev/null
    [ -f "$XDG_CONFIG_HOME/pgit/patterns/claude-code.json" ]
    [ -f "$XDG_CONFIG_HOME/pgit/patterns/agent-logs.json" ]
}

@test "registry list shows built-in pattern sets" {
    run pgit pp registry list
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude-code"* ]]
    [[ "$output" == *"agent-logs"* ]]
    [[ "$output" == *"CLAUDE.md"* ]]
    [[ "$output" == *"*.agent-log"* ]]
}

# --- pgit init consults registry ---

@test "pgit init picks up registry patterns" {
    git init -q
    git commit --allow-empty -q -m "initial"
    pgit init
    run cat .pgit/config.json
    [[ "$output" == *"CLAUDE.md"* ]]
    [[ "$output" == *".claude/"* ]]
    [[ "$output" == *"*.agent-log"* ]]
    [[ "$output" == *".pgit/"* ]]
}

@test "pgit init picks up custom registry patterns" {
    # Add a custom pattern to registry before init
    pgit pp registry add "*.prompt" custom
    git init -q
    git commit --allow-empty -q -m "initial"
    pgit init
    run cat .pgit/config.json
    [[ "$output" == *"*.prompt"* ]]
}

@test "registry patterns persist across projects" {
    # Init project A and add a custom pattern to registry
    mkdir -p projA && cd projA
    git init -q
    git commit --allow-empty -q -m "initial"
    pgit pp registry add "DESIGN.md" custom
    cd "$TEST_DIR"

    # Init project B — should have the custom pattern
    mkdir -p projB && cd projB
    git init -q
    git commit --allow-empty -q -m "initial"
    pgit init
    run cat .pgit/config.json
    [[ "$output" == *"DESIGN.md"* ]]
}

# --- pnp registry add/remove ---

@test "pnp registry add creates pattern in set" {
    run pnp registry add "*.draft" drafts
    [ "$status" -eq 0 ]
    [[ "$output" == *"added"* ]]
    [ -f "$XDG_CONFIG_HOME/pgit/patterns/drafts.json" ]
    run cat "$XDG_CONFIG_HOME/pgit/patterns/drafts.json"
    [[ "$output" == *"*.draft"* ]]
}

@test "pnp registry add to existing set" {
    pnp registry add "*.draft" drafts
    pnp registry add "*.sketch" drafts
    run cat "$XDG_CONFIG_HOME/pgit/patterns/drafts.json"
    [[ "$output" == *"*.draft"* ]]
    [[ "$output" == *"*.sketch"* ]]
}

@test "pnp registry add duplicate is idempotent" {
    pnp registry add "*.draft" drafts
    run pnp registry add "*.draft" drafts
    [[ "$output" == *"already"* ]]
}

@test "pnp registry remove removes pattern" {
    pnp registry add "*.draft" drafts
    run pnp registry remove "*.draft"
    [ "$status" -eq 0 ]
    [[ "$output" == *"removed"* ]]
    run cat "$XDG_CONFIG_HOME/pgit/patterns/drafts.json"
    [[ "$output" != *"*.draft"* ]]
}

@test "pnp registry remove nonexistent pattern fails" {
    run pnp registry remove "nonexistent"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]]
}

@test "pnp registry works without .pgit directory" {
    # No git init, no pgit init — registry should still work
    run pnp registry list
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude-code"* ]]
}

# --- init generates correct excludes from registry ---

@test "pgit init generates info/exclude from registry patterns" {
    pgit pp registry add "*.notes" custom
    git init -q
    git commit --allow-empty -q -m "initial"
    pgit init
    run cat .git/info/exclude
    [[ "$output" == *"*.notes"* ]]
    [[ "$output" == *"CLAUDE.md"* ]]
    [[ "$output" == *".pgit/"* ]]
}
