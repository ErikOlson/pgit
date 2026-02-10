#!/usr/bin/env bats

# Test pgit init creates the correct structure.

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_DIR="$(mktemp -d)"
    export XDG_CONFIG_HOME="$TEST_DIR/config"
    cd "$TEST_DIR"
    git init -q
    git commit --allow-empty -q -m "initial"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "pgit init creates .pgit directory structure" {
    run pgit init
    [ "$status" -eq 0 ]
    [ -d ".pgit" ]
    [ -d ".pgit/layers/process" ]
    [ -d ".pgit/layers/process/.git" ]
}

@test "pgit init creates config.json with default patterns" {
    pgit init
    [ -f ".pgit/config.json" ]
    run cat ".pgit/config.json"
    [[ "$output" == *'"CLAUDE.md"'* ]]
    [[ "$output" == *'".claude/"'* ]]
    [[ "$output" == *'"PLAN.md"'* ]]
    [[ "$output" == *'"TASKS.md"'* ]]
}

@test "pgit init updates product info/exclude" {
    pgit init
    [ -f ".git/info/exclude" ]
    run cat ".git/info/exclude"
    [[ "$output" == *"# pgit: process layer"* ]]
    [[ "$output" == *"CLAUDE.md"* ]]
    [[ "$output" == *".claude/"* ]]
    [[ "$output" == *".pgit/"* ]]
}

@test "pgit init preserves existing info/exclude content" {
    mkdir -p .git/info
    echo "my-custom-exclude" > .git/info/exclude
    pgit init
    run cat .git/info/exclude
    [[ "$output" == *"my-custom-exclude"* ]]
    [[ "$output" == *"CLAUDE.md"* ]]
}

@test "pgit init sets process repo worktree to project root" {
    pgit init
    run git --git-dir=".pgit/layers/process/.git" config core.worktree
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_DIR" ]
}

@test "pgit init creates .git if missing" {
    rm -rf .git
    run pgit init
    [ "$status" -eq 0 ]
    [ -d ".git" ]
    [ -d ".pgit" ]
    [[ "$output" == *"no git repo found"* ]]
}

@test "pgit init fails if already initialized" {
    pgit init
    run pgit init
    [ "$status" -ne 0 ]
    [[ "$output" == *"already initialized"* ]]
}

@test "pgit init prints summary" {
    run pgit init
    [ "$status" -eq 0 ]
    [[ "$output" == *"initialized process layer"* ]]
    [[ "$output" == *"pgit -p"* ]]
}
